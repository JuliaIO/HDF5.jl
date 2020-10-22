module HDF5

using Base: unsafe_convert, StringVector
using Requires: @require

import Base:
    close, convert, eltype, lastindex, flush, getindex, ==,
    isempty, isvalid, length, ndims, parent, read,
    setindex!, show, size, sizeof, write, isopen, iterate, eachindex, axes

import Libdl
import Mmap

# needed for filter(f, tuple) in julia 1.3
using Compat

export
    ## types
    # Attribute, File, Group, Dataset, Datatype, Opaque
    # Dataspace, Object, Properties, VLen, ChunkStorage, Reference
    # functions
    a_create, a_delete, a_open, a_read, a_write, attrs,
    d_create, d_create_external, d_open, d_read, d_write,
    dataspace, datatype, file, filename,
    g_create, g_open, get_access_properties, get_create_properties,
    get_chunk, get_datasets,
    h5open, h5read, h5rewrite, h5writeattr, h5readattr, h5write,
    iscontiguous, ishdf5, ismmappable, name,
    o_copy, o_delete, o_open, p_create,
    readmmap, @read, @write, root, set_dims!, t_create, t_commit

const depsfile = joinpath(dirname(@__DIR__), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
          "and restart Julia.")
end

include("datafile.jl")

# Core API ccall wrappers
include("api_types.jl")
include("api.jl")
include("api_helpers.jl")

# High-level reference handler
struct Reference
    r::hobj_ref_t
end
Reference() = Reference(HOBJ_REF_T_NULL) # NULL reference to compare to
Base.cconvert(::Type{Ptr{T}}, ref::Reference) where {T<:Union{Reference,hobj_ref_t,Cvoid}} = Ref(ref)

# Single character types
# These are needed to safely handle VLEN objects
abstract type CharType <: AbstractString end

struct ASCIIChar <: CharType
    c::UInt8
end
length(c::ASCIIChar) = 1

struct UTF8Char <: CharType
    c::UInt8
end
length(c::UTF8Char) = 1

chartype(::Type{String}) = ASCIIChar
stringtype(::Type{ASCIIChar}) = String
stringtype(::Type{UTF8Char}) = String

cset(::Type{<:AbstractString}) = H5T_CSET_UTF8
cset(::Type{UTF8Char}) = H5T_CSET_UTF8
cset(::Type{ASCIIChar}) = H5T_CSET_ASCII

## Conversion between Julia types and HDF5 atomic types
hdf5_type_id(::Type{Bool})      = H5T_NATIVE_B8
hdf5_type_id(::Type{Int8})      = H5T_NATIVE_INT8
hdf5_type_id(::Type{UInt8})     = H5T_NATIVE_UINT8
hdf5_type_id(::Type{Int16})     = H5T_NATIVE_INT16
hdf5_type_id(::Type{UInt16})    = H5T_NATIVE_UINT16
hdf5_type_id(::Type{Int32})     = H5T_NATIVE_INT32
hdf5_type_id(::Type{UInt32})    = H5T_NATIVE_UINT32
hdf5_type_id(::Type{Int64})     = H5T_NATIVE_INT64
hdf5_type_id(::Type{UInt64})    = H5T_NATIVE_UINT64
hdf5_type_id(::Type{Float32})   = H5T_NATIVE_FLOAT
hdf5_type_id(::Type{Float64})   = H5T_NATIVE_DOUBLE
hdf5_type_id(::Type{Reference}) = H5T_STD_REF_OBJ

hdf5_type_id(::Type{<:AbstractString}) = H5T_C_S1

const BitsType = Union{Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64}
const ScalarType = Union{BitsType,Reference}

# It's not safe to use particular id codes because these can change, so we use characteristics of the type.
function _hdf5_type_map(class_id, is_signed, native_size)
    if class_id == H5T_INTEGER
        if is_signed == H5T_SGN_2
            return native_size === Csize_t(1) ? Int8 :
                   native_size === Csize_t(2) ? Int16 :
                   native_size === Csize_t(4) ? Int32 :
                   native_size === Csize_t(8) ? Int64 :
                   throw(KeyError(class_id, is_signed, native_size))
        else
            return native_size === Csize_t(1) ? UInt8 :
                   native_size === Csize_t(2) ? UInt16 :
                   native_size === Csize_t(4) ? UInt32 :
                   native_size === Csize_t(8) ? UInt64 :
                   throw(KeyError(class_id, is_signed, native_size))
        end
    else
        return native_size === Csize_t(4) ? Float32 :
               native_size === Csize_t(8) ? Float64 :
               throw(KeyError(class_id, is_signed, native_size))
    end
end

# global configuration for complex support
const COMPLEX_SUPPORT = Ref(true)
const COMPLEX_FIELD_NAMES = Ref(("r", "i"))
enable_complex_support() = COMPLEX_SUPPORT[] = true
disable_complex_support() = COMPLEX_SUPPORT[] = false
set_complex_field_names(real::AbstractString, imag::AbstractString) =  COMPLEX_FIELD_NAMES[] = ((real, imag))

## HDF5 uses a plain integer to refer to each file, group, or
## dataset. These are wrapped into special types in order to allow
## method dispatch.

# Note re finalizers: we use them to ensure that objects passed back
# to the user will eventually be cleaned up properly. However, since
# finalizers don't run on a predictable schedule, we also call close
# directly on function exit. (This avoids certain problems, like those
# that occur when passing a freshly-created file to some other
# application).

# This defines an "unformatted" HDF5 data file. Formatted files are defined in separate modules.
mutable struct File <: DataFile
    id::hid_t
    filename::String

    function File(id, filename, toclose::Bool=true)
        f = new(id, filename)
        if toclose
            finalizer(close, f)
        end
        f
    end
end
convert(::Type{hid_t}, f::File) = f.id
function show(io::IO, fid::File)
    if isvalid(fid)
        print(io, "HDF5 data file: ", fid.filename)
    else
        print(io, "HDF5 data file (closed): ", fid.filename)
    end
end


mutable struct Group <: DataFile
    id::hid_t
    file::File         # the parent file

    function Group(id, file)
        g = new(id, file)
        finalizer(close, g)
        g
    end
end
convert(::Type{hid_t}, g::Group) = g.id
function show(io::IO, g::Group)
    if isvalid(g)
        print(io, "HDF5 group: ", name(g), " (file: ", g.file.filename, ")")
    else
        print(io, "HDF5 group (invalid)")
    end
end

mutable struct Properties
    id::hid_t
    class::hid_t
    function Properties(id, class::hid_t = H5P_DEFAULT)
        p = new(id, class)
        finalizer(close, p) #Essential, otherwise we get a memory leak, since closing file with CLOSE_STRONG is not doing it for us
        p
    end
end
Properties() = Properties(H5P_DEFAULT)
convert(::Type{hid_t}, p::Properties) = p.id

mutable struct Dataset
    id::hid_t
    file::File
    xfer::Properties

    function Dataset(id, file, xfer = DEFAULT_PROPERTIES)
        dset = new(id, file, xfer)
        finalizer(close, dset)
        dset
    end
end
convert(::Type{hid_t}, dset::Dataset) = dset.id
function show(io::IO, dset::Dataset)
    if isvalid(dset)
        print(io, "HDF5 dataset: ", name(dset), " (file: ", dset.file.filename, " xfer_mode: ", dset.xfer.id, ")")
    else
        print(io, "HDF5 dataset (invalid)")
    end
end

mutable struct Datatype
    id::hid_t
    toclose::Bool
    file::File

    function Datatype(id, toclose::Bool=true)
        nt = new(id, toclose)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
    function Datatype(id, file::File, toclose::Bool=true)
        nt = new(id, toclose, file)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
end
convert(::Type{hid_t}, dtype::Datatype) = dtype.id
hash(dtype::Datatype, h::UInt) = (dtype.id % UInt + h) ^ (0xadaf9b66bc962084 % UInt)
==(dt1::Datatype, dt2::Datatype) = h5t_equal(dt1, dt2) > 0
function show(io::IO, dtype::Datatype)
    print(io, "HDF5 datatype: ")
    if isvalid(dtype)
        print(io, h5lt_dtype_to_text(dtype.id))
    else
        # Note that h5i_is_valid returns `false` on the built-in datatypes (e.g.
        # H5T_NATIVE_INT), apparently because they have refcounts of 0 yet are always
        # valid. Just temporarily turn off error printing and try the call to probe if
        # dtype is valid since H5LTdtype_to_text special-cases all of the built-in types
        # internally.
        old_func, old_client_data = h5e_get_auto(H5E_DEFAULT)
        h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)
        local text
        try
            text = h5lt_dtype_to_text(dtype.id)
        catch
            text = "(invalid)"
        finally
            h5e_set_auto(H5E_DEFAULT, old_func, old_client_data)
        end
        print(io, text)
    end
end

# Define an H5O Object type
const Object = Union{Group,Dataset,Datatype}

mutable struct Dataspace
    id::hid_t

    function Dataspace(id)
        dspace = new(id)
        finalizer(close, dspace)
        dspace
    end
end
convert(::Type{hid_t}, dspace::Dataspace) = dspace.id

mutable struct Attribute
    id::hid_t
    file::File

    function Attribute(id, file)
        dset = new(id, file)
        finalizer(close, dset)
        dset
    end
end
convert(::Type{hid_t}, attr::Attribute) = attr.id
show(io::IO, attr::Attribute) = isvalid(attr) ? print(io, "HDF5 attribute: ", name(attr)) : print(io, "HDF5 attribute (invalid)")

struct Attributes
    parent::Union{File,Group,Dataset}
end
attrs(p::Union{File,Group,Dataset}) = Attributes(p)

# Methods for reference types
function Reference(parent::Union{File,Group,Dataset}, name::AbstractString)
    ref = Ref{hobj_ref_t}()
    h5r_create(ref, checkvalid(parent), name, H5R_OBJECT, -1)
    return Reference(ref[])
end
==(a::Reference, b::Reference) = a.r == b.r
hash(x::Reference, h::UInt) = hash(x.r, h)

# Opaque types
struct Opaque
    data
    tag::String
end

# An empty array type
struct EmptyArray{T} <: AbstractArray{T,0} end
# Required AbstractArray interface
Base.size(::EmptyArray) = ()
Base.IndexStyle(::Type{<:EmptyArray}) = IndexLinear()
Base.getindex(::EmptyArray, ::Int) = error("cannot index an `EmptyArray`")
Base.setindex!(::EmptyArray, v, ::Int) = error("cannot assign to an `EmptyArray`")
# Optional interface
Base.similar(::EmptyArray{T}) where {T} = EmptyArray{T}()
Base.similar(::EmptyArray, ::Type{S}) where {S} = EmptyArray{S}()
Base.similar(::EmptyArray, ::Type{S}, dims::Dims) where {S} = Array{S}(undef, dims)
# Override behavior for 0-dimensional Array
Base.length(::EmptyArray) = 0
# Required to avoid indexing during printing
Base.show(io::IO, E::EmptyArray) = print(io, typeof(E), "()")
Base.show(io::IO, ::MIME"text/plain", E::EmptyArray) = show(io, E)
# FIXME: Concatenation doesn't work for this type (it's treated as a length-1 array like
# Base's 0-dimensional arrays), so just forceably abort.
Base.cat_size(::EmptyArray) = error("concatenation of HDF5.EmptyArray is unsupported")
Base.cat_size(::EmptyArray, d) = error("concatenation of HDF5.EmptyArray is unsupported")

# Stub types to encode fixed-size arrays for H5T_ARRAY
struct FixedArray{T,D,L}
    data::NTuple{L,T}
end
size(::Type{FixedArray{T,D,L}}) where {T,D,L} = D
size(x::T) where {T<:FixedArray} = size(T)
eltype(::Type{FixedArray{T,D,L}}) where {T,D,L} = T
eltype(x::T) where {T<:FixedArray} = eltype(T)

struct FixedString{N,PAD}
    data::NTuple{N,UInt8}
end
length(::Type{FixedString{N,PAD}}) where {N,PAD} = N
length(x::T) where {T<:FixedString} = length(T)
pad(::Type{FixedString{N,PAD}}) where {N, PAD} = PAD
pad(x::T) where {T<:FixedString} = pad(T)

struct VariableArray{T}
    len::Csize_t
    p::Ptr{Cvoid}
end
eltype(::Type{VariableArray{T}}) where T = T

# VLEN objects
struct VLen{T}
    data
end
VLen(strs::Array{S}) where {S<:String} = VLen{chartype(S)}(strs)
VLen(A::Array{Array{T}}) where {T<:ScalarType} = VLen{T}(A)
VLen(A::Array{Array{T,N}}) where {T<:ScalarType,N} = VLen{T}(A)

t2p(::Type{T}) where {T<:ScalarType} = Ptr{T}
t2p(::Type{C}) where {C<:CharType} = Ptr{UInt8}
function vlenpack(v::VLen{T}) where {T<:Union{ScalarType,CharType}}
    len = length(v.data)
    Tp = t2p(T)  # Ptr{UInt8} or Ptr{T}
    h = Vector{hvl_t}(undef,len)
    for i = 1:len
        h[i] = hvl_t(convert(Csize_t, length(v.data[i])), convert(Ptr{Cvoid}, unsafe_convert(Tp, v.data[i])))
    end
    h
end

# Blosc compression:
include("blosc_filter.jl")

# heuristic chunk layout (return empty array to disable chunking)
function heuristic_chunk(T, shape)
    Ts = sizeof(T)
    sz = prod(shape)
    sz == 0 && return Int[] # never return a zero-size chunk
    chunk = [shape...]
    nd = length(chunk)
    # simplification of ugly heuristic target chunk size from PyTables/h5py:
    target = min(1500000, max(12000, floor(Int, 300*cbrt(Ts*sz))))
    Ts > target && return ones(chunk)
    # divide last non-unit dimension by 2 until we get <= target
    # (since Julia default to column-major, favor contiguous first dimension)
    while Ts*prod(chunk) > target
        i = nd
        while chunk[i] == 1
            i -= 1
        end
        chunk[i] >>= 1
    end
    return chunk
end
heuristic_chunk(T, ::Tuple{}) = Int[]
heuristic_chunk(A::AbstractArray{T}) where {T} = heuristic_chunk(T, size(A))
heuristic_chunk(x) = Int[]
# (strings are saved as scalars, and hence cannot be chunked)

### High-level interface ###
# Open or create an HDF5 file
function h5open(filename::AbstractString, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool,
        cpl::Properties=DEFAULT_PROPERTIES, apl::Properties=DEFAULT_PROPERTIES; swmr=false)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end
    close_apl = false
    if apl.id == H5P_DEFAULT
        apl = p_create(H5P_FILE_ACCESS)
        close_apl = true
        # With garbage collection, the other modes don't make sense
        apl[:fclose_degree] = H5F_CLOSE_STRONG
    end
    if cr && (tr || !isfile(filename))
        flag = swmr ? H5F_ACC_TRUNC|H5F_ACC_SWMR_WRITE : H5F_ACC_TRUNC
        fid = h5f_create(filename, flag, cpl, apl)
    else
        if !h5f_is_hdf5(filename)
            error("This does not appear to be an HDF5 file")
        end
        if wr
            flag = swmr ? H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE : H5F_ACC_RDWR
        else
            flag = swmr ? H5F_ACC_RDONLY|H5F_ACC_SWMR_READ : H5F_ACC_RDONLY
        end
        fid = h5f_open(filename, flag, apl)
    end
    if close_apl
        # Close properties manually to avoid errors when the file is
        # closed before the properties are gc'ed
        close(apl)
    end
    File(fid, filename)
end

"""
    h5open(filename::AbstractString, mode::AbstractString="r"; swmr=false, pv...)

Open or create an HDF5 file where `mode` is one of:
 - "r"  read only
 - "r+" read and write
 - "cw" read and write, create file if not existing, do not truncate
 - "w"  read and write, create a new file (destroys any existing contents)

Pass `swmr=true` to enable (Single Writer Multiple Reader) SWMR write access for "w" and
"r+", or SWMR read access for "r".
"""
function h5open(filename::AbstractString, mode::AbstractString="r"; swmr=false, pv...)
    fapl = p_create(H5P_FILE_ACCESS; pv...) # file access property list
    # With garbage collection, the other modes don't make sense
    # (Set this first, so that the user-passed properties can overwrite this.)
    fapl[:fclose_degree] = H5F_CLOSE_STRONG
    fcpl = p_create(H5P_FILE_CREATE; pv...) # file create property list
    modes =
        mode == "r"  ? (true,  false, false, false, false) :
        mode == "r+" ? (true,  true,  false, false, true ) :
        mode == "cw" ? (false, true,  true,  false, true ) :
        mode == "w"  ? (false, true,  true,  true,  false) :
        # mode == "w+" ? (true,  true,  true,  true,  false) :
        # mode == "a"  ? (true,  true,  true,  true,  true ) :
        error("invalid open mode: ", mode)
    h5open(filename, modes..., fcpl, fapl; swmr=swmr)
end

"""
    function h5open(f::Function, args...; swmr=false, pv...)

Apply the function f to the result of `h5open(args...;kwargs...)` and close the resulting
`HDF5.File` upon completion. For example with a `do` block:


    h5open("foo.h5","w") do h5
        h5["foo"]=[1,2,3]
    end

"""
function h5open(f::Function, args...; swmr=false, pv...)
    fid = h5open(args...; swmr=swmr, pv...)
    try
        f(fid)
    finally
        close(fid)
    end
end

function h5rewrite(f::Function, filename::AbstractString, args...)
    tmppath,tmpio = mktemp(dirname(filename))
    close(tmpio)

    try
        val = h5open(f, tmppath, "w", args...)
        Base.Filesystem.rename(tmppath, filename)
        return val
    catch
        Base.Filesystem.unlink(tmppath)
        rethrow()
    end
end

function h5write(filename, name::AbstractString, data; pv...)
    fid = h5open(filename, "cw"; pv...)
    try
        write(fid, name, data)
    finally
        close(fid)
    end
end

function h5read(filename, name::AbstractString; pv...)
    local dat
    fid = h5open(filename, "r"; pv...)
    try
        obj = getindex(fid, name; pv...)
        dat = read(obj)
    finally
        close(fid)
    end
    dat
end

function h5read(filename, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    local dat
    fid = h5open(filename, "r"; pv...)
    try
        obj = getindex(fid, name_type_pair[1]; pv...)
        dat = read(obj, name_type_pair[2])
    finally
        close(fid)
    end
    dat
end

function h5read(filename, name::AbstractString, indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}}; pv...)
    local dat
    fid = h5open(filename, "r"; pv...)
    try
        dset = getindex(fid, name; pv...)
        dat = dset[indices...]
    finally
        close(fid)
    end
    dat
end

function h5writeattr(filename, name::AbstractString, data::Dict)
    fid = h5open(filename, "r+")
    try
        for x in keys(data)
            attrs(fid[name])[x] = data[x]
        end
    finally
        close(fid)
    end
end

function h5readattr(filename, name::AbstractString)
    local dat
    fid = h5open(filename,"r")
    try
        a = attrs(fid[name])
        dat = Dict(x => read(a[x]) for x in keys(a))
    finally
        close(fid)
    end
    dat
end

# Ensure that objects haven't been closed
isvalid(obj::Union{File,Properties,Datatype,Dataspace}) = obj.id != -1 && h5i_is_valid(obj.id)
isvalid(obj::Union{Group,Dataset,Attribute}) = obj.id != -1 && obj.file.id != -1 && h5i_is_valid(obj.id)
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Close functions

# Close functions that should try calling close regardless
function close(obj::File)
    if obj.id != -1
        h5f_close(obj.id)
        obj.id = -1
    end
    nothing
end

"""
    isopen(obj::HDF5.File)

Returns `true` if `obj` has not been closed, `false` if it has been closed.
"""
isopen(obj::File) = obj.id != -1

for (h5type, h5func) in
    ((:(Union{Group, Dataset}), :h5o_close),
     (:Attribute, :h5a_close))
    # Close functions that should first check that the file is still open. The common case is a
    # file that has been closed with CLOSE_STRONG but there are still finalizers that have not run
    # for the datasets, etc, in the file.
    @eval begin
        function close(obj::$h5type)
            if obj.id != -1
                if obj.file.id != -1 && isvalid(obj)
                    $h5func(obj.id)
                end
                obj.id = -1
            end
            nothing
        end
    end
end

function close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            h5o_close(obj.id)
        end
        obj.id = -1
    end
    nothing
end

function close(obj::Dataspace)
    if obj.id != -1
        if isvalid(obj)
            h5s_close(obj.id)
        end
        obj.id = -1
    end
    nothing
end

function close(obj::Properties)
    if obj.id != -1
        if isvalid(obj)
            h5p_close(obj.id)
        end
        obj.id = -1
    end
    nothing
end

"""
    ishdf5(name::AbstractString)

Returns `true` if `name` is a path to a valid hdf5 file, `false` otherwise.
"""
ishdf5(name::AbstractString) = h5f_is_hdf5(name)

# Extract the file
file(f::File) = f
file(o::Union{Object,Attribute}) = o.file
fd(obj::Object) = h5i_get_file_id(checkvalid(obj).id)

# Flush buffers
flush(f::Union{Object,Attribute,Datatype,File}, scope = H5F_SCOPE_GLOBAL) = h5f_flush(checkvalid(f).id, scope)

# Open objects
g_open(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Group(h5g_open(checkvalid(parent), name, apl), file(parent))
d_open(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES, xpl::Properties=DEFAULT_PROPERTIES) = Dataset(h5d_open(checkvalid(parent), name, apl), file(parent), xpl)
t_open(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Datatype(h5t_open(checkvalid(parent), name, apl), file(parent))
a_open(parent::Union{File,Object}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Attribute(h5a_open(checkvalid(parent), name, apl), file(parent))
# Object (group, named datatype, or dataset) open
function h5object(obj_id::hid_t, parent)
    obj_type = h5i_get_type(obj_id)
    obj_type == H5I_GROUP ? Group(obj_id, file(parent)) :
    obj_type == H5I_DATATYPE ? Datatype(obj_id, file(parent)) :
    obj_type == H5I_DATASET ? Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
o_open(parent, path::AbstractString) = h5object(h5o_open(checkvalid(parent).id, path), parent)
function gettype(parent, path::AbstractString)
    obj_id = h5o_open(checkvalid(parent), path)
    obj_type = h5i_get_type(obj_id)
    h5o_close(obj_id)
    return obj_type
end
# Get the root group
root(h5file::File) = g_open(h5file, "/")
root(obj::Union{Group,Dataset}) = g_open(file(obj), "/")
# getindex syntax: obj2 = obj1[path]
getindex(dset::Dataset, name::AbstractString) = a_open(dset, name)
getindex(x::Attributes, name::AbstractString) = a_open(x.parent, name)

function getindex(parent::Union{File,Group}, path::AbstractString; pv...)
    objtype = gettype(parent, path)
    if objtype == H5I_DATASET
        dapl = p_create(H5P_DATASET_ACCESS; pv...)
        dxpl = p_create(H5P_DATASET_XFER; pv...)
        return d_open(parent, path, dapl, dxpl)
    elseif objtype == H5I_GROUP
        gapl = p_create(H5P_GROUP_ACCESS; pv...)
        return g_open(parent, path, gapl)
    else#if objtype == H5I_DATATYPE # only remaining choice
        tapl = p_create(H5P_DATATYPE_ACCESS; pv...)
        return t_open(parent, path, tapl)
    end
end

# Path manipulation
function split1(path::AbstractString)
    ind = findfirst('/', path)
    isnothing(ind) && return path, nothing
    if ind == 1 # matches root group
        return "/", path[2:end]
    else
        indm1, indp1 = prevind(path, ind), nextind(path, ind)
        return path[1:indm1], path[indp1:end] # better to use begin:indm1, but only available on v1.5
    end
end

function g_create(parent::Union{File,Group}, path::AbstractString,
                  lcpl::Properties=_link_properties(path),
                  dcpl::Properties=DEFAULT_PROPERTIES)
    Group(h5g_create(checkvalid(parent), path, lcpl, dcpl), file(parent))
end
function g_create(f::Function, parent::Union{File,Group}, args...)
    g = g_create(parent, args...)
    try
        f(g)
    finally
        close(g)
    end
end

function d_create(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace,
                  lcpl::Properties, dcpl::Properties,
                  dapl::Properties, dxpl::Properties)
    Dataset(h5d_create(checkvalid(parent), path, dtype, dspace, lcpl, dcpl, dapl), file(parent), dxpl)
end

# Setting dset creation properties with name/value pairs
function d_create(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace; pv...)
    dcpl = isempty(pv) ? DEFAULT_PROPERTIES : p_create(H5P_DATASET_CREATE; pv...)
    dxpl = isempty(pv) ? DEFAULT_PROPERTIES : p_create(H5P_DATASET_XFER; pv...)
    dapl = isempty(pv) ? DEFAULT_PROPERTIES : p_create(H5P_DATASET_ACCESS; pv...)
    Dataset(h5d_create(checkvalid(parent), path, dtype, dspace, _link_properties(path), dcpl, dapl), file(parent), dxpl)
end
d_create(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Dims; pv...) = d_create(checkvalid(parent), path, dtype, dataspace(dspace_dims); pv...)
d_create(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Tuple{Dims,Dims}; pv...) = d_create(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
d_create(parent::Union{File,Group}, path::AbstractString, dtype::Type, dspace_dims; pv...) = d_create(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
t_create(class_id, sz) = Datatype(h5t_create(class_id, sz))
function t_commit(parent::Union{File,Group}, path::AbstractString, dtype::Datatype,
                  lcpl::Properties=p_create(H5P_LINK_CREATE), tcpl::Properties=DEFAULT_PROPERTIES, tapl::Properties=DEFAULT_PROPERTIES)
    h5p_set_char_encoding(lcpl, cset(typeof(path)))
    h5t_commit(checkvalid(parent), path, dtype, lcpl, tcpl, tapl)
    dtype.file = file(parent)
    return dtype
end

a_create(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace) = Attribute(h5a_create(checkvalid(parent), name, dtype, dspace), file(parent))

function _prop_get(p::Properties, name::Symbol)
    class = p.class

    if class == H5P_FILE_CREATE
        return name === :userblock   ? h5p_get_userblock(p) :
               name === :track_times ? h5p_get_obj_track_times(p) : # H5P_OBJECT_CREATE
               error("unknown file create property ", name)
    end

    if class == H5P_FILE_ACCESS
        return name === :alignment     ? h5p_get_alignment(p) :
               name === :driver        ? h5p_get_driver(p) :
               name === :driver_info   ? h5p_get_driver_info(p) :
               name === :fapl_mpio     ? h5p_get_fapl_mpio(p) :
               name === :fclose_degree ? h5p_get_fclose_degree(p) :
               name === :libver_bounds ? h5p_get_libver_bounds(p) :
               error("unknown file access property ", name)
    end

    if class == H5P_GROUP_CREATE
        return name === :local_heap_size_hint ? h5p_get_local_heap_size_hint(p) :
               name === :track_times ? h5p_get_obj_track_times(p) : # H5P_OBJECT_CREATE
               error("unknown group create property ", name)
    end

    if class == H5P_LINK_CREATE
        return name === :char_encoding ? h5p_get_char_encoding(p) :
               name === :create_intermediate_group ? h5p_get_create_intermediate_group(p) :
               error("unknown link create property ", name)
    end

    if class == H5P_DATASET_CREATE
        return name === :alloc_time  ? h5p_get_alloc_time(p) :
               name === :chunk       ? get_chunk(p) :
               #name === :external    ? h5p_get_external(p) :
               name === :layout      ? h5p_get_layout(p) :
               name === :track_times ? h5p_get_obj_track_times(p) : # H5P_OBJECT_CREATE
               error("unknown dataset create property ", name)
    end

    if class == H5P_DATASET_XFER
        return name === :dxpl_mpio  ? h5p_get_dxpl_mpio(p) :
               error("unknown dataset transfer property ", name)
    end

    if class == H5P_ATTRIBUTE_CREATE
        return name === :char_encoding ? h5p_get_char_encoding(p) :
               error("unknown attribute create property ", name)
    end

    error("unknown property class ", class)
end

function _prop_set!(p::Properties, name::Symbol, val, check::Bool = true)
    class = p.class

    if class == H5P_FILE_CREATE
        return name === :userblock   ? h5p_set_userblock(p, val...) :
               name === :track_times ? h5p_set_obj_track_times(p, val...) : # H5P_OBJECT_CREATE
               check ? error("unknown file create property ", name) : nothing
    end

    if class == H5P_FILE_ACCESS
        return name === :alignment     ? h5p_set_alignment(p, val...) :
               name === :fapl_mpio     ? h5p_set_fapl_mpio(p, val...) :
               name === :fclose_degree ? h5p_set_fclose_degree(p, val...) :
               name === :libver_bounds ? h5p_set_libver_bounds(p, val...) :
               check ? error("unknown file access property ", name) : nothing
    end

    if class == H5P_GROUP_CREATE
        return name === :local_heap_size_hint ? h5p_set_local_heap_size_hint(p, val...) :
               name === :track_times          ? h5p_set_obj_track_times(p, val...) : # H5P_OBJECT_CREATE
               check ? error("unknown group create property ", name) : nothing
    end

    if class == H5P_LINK_CREATE
        return name === :char_encoding ? h5p_set_char_encoding(p, val...) :
               name === :create_intermediate_group ? h5p_set_create_intermediate_group(p, val...) :
               check ? error("unknown link create property ", name) : nothing
    end

    if class == H5P_DATASET_CREATE
        return name === :alloc_time  ? h5p_set_alloc_time(p, val...) :
               name === :blosc       ? h5p_set_blosc(p, val...) :
               name === :chunk       ? set_chunk(p, val...) :
               name === :compress    ? h5p_set_deflate(p, val...) :
               name === :deflate     ? h5p_set_deflate(p, val...) :
               name === :external    ? h5p_set_external(p, val...) :
               name === :layout      ? h5p_set_layout(p, val...) :
               name === :shuffle     ? h5p_set_shuffle(p, val...) :
               name === :track_times ? h5p_set_obj_track_times(p, val...) : # H5P_OBJECT_CREATE
               check ? error("unknown dataset create property ", name) : nothing
    end

    if class == H5P_DATASET_XFER
        return name === :dxpl_mpio  ? h5p_set_dxpl_mpio(p, val...) :
               check ? error("unknown dataset transfer property ", name) : nothing
    end

    if class == H5P_ATTRIBUTE_CREATE
        return name === :char_encoding ? h5p_set_char_encoding(p, val...) :
               check ? error("unknown attribute create property ", name) : nothing
    end

    return check ? error("unknown property class ", class) : nothing
end

function p_create(class; pv...)
    p = Properties(h5p_create(class), class)
    for (k, v) in pairs(pv)
        _prop_set!(p, k, v, false)
    end
    return p
end

# Delete objects
a_delete(parent::Union{File,Object}, path::AbstractString) = h5a_delete(checkvalid(parent), path)
o_delete(parent::Union{File,Group}, path::AbstractString, lapl::Properties=DEFAULT_PROPERTIES) = h5l_delete(checkvalid(parent), path, lapl)
o_delete(obj::Object) = o_delete(parent(obj), ascii(split(name(obj),"/")[end])) # FIXME: remove ascii?

# Copy objects
o_copy(src_parent::Union{File,Group}, src_path::AbstractString, dst_parent::Union{File,Group}, dst_path::AbstractString) = h5o_copy(checkvalid(src_parent), src_path, checkvalid(dst_parent), dst_path, H5P_DEFAULT, _link_properties(dst_path))
o_copy(src_obj::Object, dst_parent::Union{File,Group}, dst_path::AbstractString) = h5o_copy(checkvalid(src_obj), ".", checkvalid(dst_parent), dst_path, H5P_DEFAULT, _link_properties(dst_path))

# Assign syntax: obj[path] = value
# Creates a dataset unless obj is a dataset, in which case it creates an attribute
setindex!(dset::Dataset, val, name::AbstractString) = a_write(dset, name, val)
setindex!(x::Attributes, val, name::AbstractString) = a_write(x.parent, name, val)
# Getting and setting properties: p[:chunk] = dims, p[:compress] = 6
getindex(p::Properties, name::Symbol) = _prop_get(checkvalid(p), name)
function setindex!(p::Properties, val, name::Symbol)
    _prop_set!(checkvalid(p), name, val, true)
    return p
end
# Create a dataset with properties: obj[path, prop = val, ...] = val
function setindex!(parent::Union{File,Group}, val, path::AbstractString; pv...)
    need_chunks = any(k in keys(chunked_props) for k in keys(pv))
    have_chunks = any(k == :chunk for k in keys(pv))

    chunk = need_chunks ? heuristic_chunk(val) : Int[]

    # ignore chunked_props (== compression) for empty datasets (issue #246):
    discard_chunks = need_chunks && isempty(chunk)
    if discard_chunks
        pv = pairs(Base.structdiff((; pv...), chunked_props))
    else
        if need_chunks && !have_chunks
            pv = pairs((; chunk = chunk, pv...))
        end
    end
    write(parent, path, val; pv...)
end

# Check existence
function Base.haskey(parent::Union{File,Group}, path::AbstractString, lapl::Properties=Properties())
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !h5l_exists(parent, first, lapl)
        return false
    end
    exists = true
    if !isnothing(rest) && !isempty(rest)
        obj = parent[first]
        exists = haskey(obj, rest, lapl)
        close(obj)
    end
    return exists
end
Base.haskey(attr::Attributes, path::AbstractString) = h5a_exists(checkvalid(attr.parent).id, path)
Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) = h5a_exists(checkvalid(dset).id, path)

# Querying items in the file
info(obj::Union{Group,File}) = h5g_get_info(checkvalid(obj).id)
objinfo(obj::Union{File,Object}) = h5o_get_info(checkvalid(obj).id)

length(obj::Union{Group,File}) = h5g_get_num_objs(checkvalid(obj).id)
length(x::Attributes) = objinfo(x.parent).num_attrs

isempty(x::Union{Dataset,Group,File}) = length(x) == 0
function size(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    dims, maxdims = get_dims(dspace)
    close(dspace)
    convert(Tuple{Vararg{Int}}, dims)
end
size(dset::Union{Dataset,Attribute}, d) = d > ndims(dset) ? 1 : size(dset)[d]
length(dset::Union{Dataset,Attribute}) = prod(size(dset))
ndims(dset::Union{Dataset,Attribute}) = length(size(dset))
function eltype(dset::Union{Dataset,Attribute})
    T = Any
    dtype = datatype(dset)
    try
        T = hdf5_to_julia_eltype(dtype)
    finally
        close(dtype)
    end
    T
end
function isnull(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    ret = h5s_get_simple_extent_type(dspace.id) == H5S_NULL
    close(dspace)
    ret
end

# filename and name
filename(obj::Union{File,Group,Dataset,Attribute,Datatype}) = h5f_get_name(checkvalid(obj).id)
name(obj::Union{File,Group,Dataset,Datatype}) = h5i_get_name(checkvalid(obj).id)
name(attr::Attribute) = h5a_get_name(attr.id)
function Base.keys(x::Union{Group,File})
    checkvalid(x)
    n = length(x)
    return [h5l_get_name_by_idx(x, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, H5P_DEFAULT) for i = 1:n]
end

function Base.keys(x::Attributes)
    checkvalid(x.parent)
    n = length(x)
    return [h5a_get_name_by_idx(x.parent, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, H5P_DEFAULT) for i = 1:n]
end

# iteration by objects
function iterate(parent::Union{File,Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(h5o_open_by_idx(checkvalid(parent).id, ".", H5_INDEX_NAME, H5_ITER_INC, n-1, H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
end

lastindex(dset::Dataset) = length(dset)
lastindex(dset::Dataset, d::Int) = size(dset, d)

function parent(obj::Union{File, Group, Dataset})
    f = file(obj)
    path = name(obj)
    if length(path) == 1
        return f
    end
    parentname = dirname(path)
    if !isempty(parentname)
        return o_open(f, dirname(path))
    else
        return root(f)
    end
end

# Get the datatype of a dataset
datatype(dset::Dataset) = Datatype(h5d_get_type(checkvalid(dset).id), file(dset))
# Get the datatype of an attribute
datatype(dset::Attribute) = Datatype(h5a_get_type(checkvalid(dset).id), file(dset))

# Create a datatype from in-memory types
datatype(x::ScalarType) = Datatype(hdf5_type_id(typeof(x)), false)
datatype(::Type{T}) where {T<:ScalarType} = Datatype(hdf5_type_id(T), false)
datatype(A::AbstractArray{T}) where {T<:ScalarType} = Datatype(hdf5_type_id(T), false)
function datatype(::Type{Complex{T}}) where {T<:ScalarType}
  COMPLEX_SUPPORT[] || error("complex support disabled. call HDF5.enable_complex_support() to enable")
  dtype = h5t_create(H5T_COMPOUND, 2*sizeof(T))
  h5t_insert(dtype, COMPLEX_FIELD_NAMES[][1], 0, hdf5_type_id(T))
  h5t_insert(dtype, COMPLEX_FIELD_NAMES[][2], sizeof(T), hdf5_type_id(T))
  return Datatype(dtype)
end
datatype(x::Complex{T}) where {T<:ScalarType} = datatype(typeof(x))
datatype(A::AbstractArray{Complex{T}}) where {T<:ScalarType} = datatype(eltype(A))

function datatype(str::AbstractString)
    type_id = h5t_copy(hdf5_type_id(typeof(str)))
    h5t_set_size(type_id, max(sizeof(str), 1))
    h5t_set_cset(type_id, cset(typeof(str)))
    Datatype(type_id)
end
function datatype(::Array{S}) where {S<:AbstractString}
    type_id = h5t_copy(hdf5_type_id(S))
    h5t_set_size(type_id, H5T_VARIABLE)
    h5t_set_cset(type_id, cset(S))
    Datatype(type_id)
end
datatype(A::VLen{T}) where {T<:ScalarType} = Datatype(h5t_vlen_create(hdf5_type_id(T)))
function datatype(str::VLen{C}) where {C<:CharType}
    type_id = h5t_copy(hdf5_type_id(C))
    h5t_set_size(type_id, 1)
    h5t_set_cset(type_id, cset(C))
    Datatype(h5t_vlen_create(type_id))
end

sizeof(dtype::Datatype) = h5t_get_size(dtype)

# Get the dataspace of a dataset
dataspace(dset::Dataset) = Dataspace(h5d_get_space(checkvalid(dset).id))
# Get the dataspace of an attribute
dataspace(attr::Attribute) = Dataspace(h5a_get_space(checkvalid(attr).id))

# Create a dataspace from in-memory types
dataspace(x::Union{T, Complex{T}}) where {T<:ScalarType} = Dataspace(h5s_create(H5S_SCALAR))
dataspace(::AbstractString) = Dataspace(h5s_create(H5S_SCALAR))

function _dataspace(sz::Dims{N}, max_dims::Union{Dims{N}, Tuple{}}=()) where N
    dims = hsize_t[sz[i] for i in N:-1:1]
    if isempty(max_dims)
        maxd = dims
    else
        # This allows max_dims to be specified as -1 without triggering an overflow
        # exception due to the signed -> unsigned conversion.
        maxd = hsize_t[hssize_t(max_dims[i]) % hsize_t for i in N:-1:1]
    end
    return Dataspace(h5s_create_simple(length(dims), dims, maxd))
end
dataspace(A::AbstractArray{T,N}; max_dims::Union{Dims{N},Tuple{}} = ()) where {T,N} = _dataspace(size(A), max_dims)
# special array types
dataspace(v::VLen; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(size(v.data), max_dims)
dataspace(A::EmptyArray) = Dataspace(h5s_create(H5S_NULL))
dataspace(n::Nothing) = Dataspace(h5s_create(H5S_NULL))
# for giving sizes explicitly
dataspace(sz::Dims{N}; max_dims::Union{Dims{N},Tuple{}}=()) where {N} = _dataspace(sz, max_dims)
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(tuple(sz1, sz2, sz3...), max_dims)


function get_dims(dspace::Dataspace)
    dims = h5s_get_simple_extent_dims(dspace.id)
    return tuple(reverse!(dims[1])...), tuple(reverse!(dims[2])...)
end

"""
    get_dims(dset::HDF5.Dataset)

Get the array dimensions from a dataset and return a tuple of dims and maxdims.
"""
get_dims(dset::Dataset) = get_dims(dataspace(checkvalid(dset)))

"""
    set_dims!(dset::HDF5.Dataset, new_dims::Dims)

Change the current dimensions of a dataset to `new_dims`, limited by
`max_dims = get_dims(dset)[2]`. Reduction is possible and leads to loss of truncated data.
"""
set_dims!(dset::Dataset, new_dims::Dims) = h5d_set_extent(checkvalid(dset), hsize_t[reverse(new_dims)...])

"""
    start_swmr_write(h5::HDF5.File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://portal.hdfgroup.org/display/HDF5/Single+Writer+Multiple+Reader++-+SWMR).
"""
start_swmr_write(h5::File) = h5f_start_swmr_write(h5.id)

refresh(ds::Dataset) = h5d_refresh(checkvalid(ds).id)
flush(ds::Dataset) = h5d_flush(checkvalid(ds).id)

# Generic read functions
for (fsym, osym, ptype) in
    ((:d_read, :d_open, Union{File,Group}),
     (:a_read, :a_open, Union{File,Group,Dataset,Datatype}))
    @eval begin
        function ($fsym)(parent::$ptype, name::AbstractString)
            local ret
            obj = ($osym)(parent, name)
            try
                ret = read(obj)
            finally
                close(obj)
            end
            ret
        end
    end
end

# Datafile.jl defines generic read for multiple datasets, so we cannot simply add properties here.
function read(parent::Union{File,Group}, name::AbstractString; pv...)
    obj = getindex(parent, name; pv...)
    val = read(obj)
    close(obj)
    val
end

function read(parent::Union{File,Group}, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    obj = getindex(parent, name_type_pair[1]; pv...)
    val = read(obj, name_type_pair[2])
    close(obj)
    val
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5.Datatype. Specific file formats should provide their own read(dset).
const DatasetOrAttribute = Union{Dataset,Attribute}

function read(obj::DatasetOrAttribute)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    read(obj, T)
end

function getindex(dset::Dataset, I...)
    dtype = datatype(dset)
    T = get_jl_type(dtype)
    read(dset, T, I...)
end

# generic read function
function read(obj::DatasetOrAttribute, ::Type{T}, I...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    !isempty(I) && obj isa Attribute && error("HDF5 attributes do not support hyperslab selections")

    filetype = datatype(obj)
    memtype = Datatype(h5t_get_native_type(filetype.id))  # padded layout in memory
    close(filetype)

    if sizeof(T) != h5t_get_size(memtype.id)
        error("""
              Type size mismatch
              sizeof($T) = $(sizeof(T))
              sizeof($memtype) = $(h5t_get_size(memtype.id))
              """)
    end

    dspace = dataspace(obj)
    stype = h5s_get_simple_extent_type(dspace.id)
    stype == H5S_NULL && return EmptyArray{T}()

    if !isempty(I)
        indices = Base.to_indices(obj, I)
        dspace = hyperslab(dspace, indices...)
    end

    scalar = false
    if stype == H5S_SCALAR
        sz = (1,)
        scalar = true
    elseif isempty(I)
        sz, _ = get_dims(dspace)
    else
        sz = map(length, filter(i -> !isa(i, Int), indices))
        if isempty(sz)
            sz = (1,)
            scalar = true
        end
    end

    buf = Array{T}(undef, sz...)
    memspace = dataspace(buf)

    if obj isa Dataset
        h5d_read(obj.id, memtype.id, memspace.id, dspace.id, obj.xfer.id, buf)
    else
        h5a_read(obj.id, memtype.id, buf)
    end

    out = do_normalize(T) ? normalize_types.(buf) : buf

    xfer_id = obj isa Dataset ? obj.xfer.id : H5P_DEFAULT
    do_reclaim(T) && h5d_vlen_reclaim(memtype.id, memspace.id, xfer_id, buf)

    close(memtype)
    close(memspace)
    close(dspace)

    if scalar
        return out[1]
    else
        return out
    end
end
# `Type{String}` does not have a definite size, so the previous method does not accept
# it even though it will return a `String`. This explicit overload allows that usage.
function read(obj::DatasetOrAttribute, ::Type{String}, I...)
    dtype = datatype(obj)
    try
        T = get_jl_type(dtype)
        T <: Union{Cstring, FixedString} || error(name(obj), " cannot be read as type `String`")
        return read(obj, T, I...)
    finally
        close(dtype)
    end
end

# Read OPAQUE datasets and attributes
function read(obj::DatasetOrAttribute, ::Type{Opaque})
    local buf
    local len
    local tag
    sz = size(obj)
    objtype = datatype(obj)
    try
        len = h5t_get_size(objtype)
        buf = Vector{UInt8}(undef,prod(sz)*len)
        tag = h5t_get_tag(objtype.id)
        readarray(obj, objtype.id, buf)
    finally
        close(objtype)
    end
    data = Array{Array{UInt8}}(undef,sz)
    for i = 1:prod(sz)
        data[i] = buf[(i-1)*len+1:i*len]
    end
    Opaque(data, tag)
end

# Array constructor for datasets
Array(x::Dataset) = read(x)

# Clean up string buffer according to padding mode
function unpad(s::String, pad::Integer)
    if pad == H5T_STR_NULLTERM
        v = findfirst(isequal('\0'), s)
        v === nothing ? s : s[1:v-1]
    elseif pad == H5T_STR_NULLPAD
        rstrip(s, '\0')
    elseif pad == H5T_STR_SPACEPAD
        rstrip(s, ' ')
    else
        error("Unrecognized string padding mode $pad")
    end
end
unpad(s, pad::Integer) = unpad(String(s), pad)

# Dereference
function getindex(parent::Union{File,Group,Dataset}, r::Reference)
    r == Reference() && error("Reference is null")
    obj_id = h5r_dereference(checkvalid(parent).id, H5P_DEFAULT, H5R_OBJECT, r)
    h5object(obj_id, parent)
end

# convert special types to native julia types
normalize_types(x) = x
normalize_types(x::NamedTuple{T}) where {T} = NamedTuple{T}(map(normalize_types, values(x)))
normalize_types(x::Cstring) = unsafe_string(x)
normalize_types(x::FixedString) = unpad(String(collect(x.data)), pad(x))
normalize_types(x::FixedArray) = normalize_types.(reshape(collect(x.data), size(x)...))
normalize_types(x::VariableArray) = normalize_types.(copy(unsafe_wrap(Array, convert(Ptr{eltype(x)}, x.p), x.len, own=false)))

do_normalize(::Type{T}) where {T} = false
do_normalize(::Type{NamedTuple{T,U}}) where {U,T} = any(i -> do_normalize(fieldtype(U,i)), 1:fieldcount(U))
do_normalize(::Type{T}) where T <: Union{Cstring,FixedString,FixedArray,VariableArray} = true

do_reclaim(::Type{T}) where {T} = false
do_reclaim(::Type{NamedTuple{T,U}}) where {U,T} = any(i -> do_reclaim(fieldtype(U,i)), 1:fieldcount(U))
do_reclaim(::Type{T}) where T <: Union{Cstring,VariableArray} = true

read(attr::Attributes, name::AbstractString) = a_read(attr.parent, name)

# Reading with mmap
function iscontiguous(obj::Dataset)
    prop = h5d_get_create_plist(checkvalid(obj).id)
    try
        h5p_get_layout(prop) == H5D_CONTIGUOUS
    finally
        h5p_close(prop)
    end
end

ismmappable(::Type{Array{T}}) where {T<:ScalarType} = true
ismmappable(::Type) = false
ismmappable(obj::Dataset, ::Type{T}) where {T} = ismmappable(T) && iscontiguous(obj)
ismmappable(obj::Dataset) = ismmappable(obj, hdf5_to_julia(obj))

function readmmap(obj::Dataset, ::Type{Array{T}}) where {T}
    dims = size(obj)
    if isempty(dims)
        return T[]
    end
    if !Sys.iswindows()
        local fdint
        prop = h5d_get_access_plist(obj.id)
        try
            # TODO: Should check return value of h5f_get_driver()
            fdptr = h5f_get_vfd_handle(obj.file.id, prop)
            fdint = unsafe_load(convert(Ptr{Cint}, fdptr))
        finally
            h5p_close(prop)
        end
        fd = fdio(fdint)
    else
        # This is a workaround since the regular code path does not work on windows
        # (see #89 for background). The error is that "Mmap.mmap(fd, ...)" cannot
        # create create a valid file mapping. The question is if the handler
        # returned by "h5f_get_vfd_handle" has
        # the correct format as required by the "fdio" function. The former
        # calls
        # https://gitlabext.iag.uni-stuttgart.de/libs/hdf5/blob/develop/src/H5FDcore.c#L1209
        #
        # The workaround is to create a new file handle, which should actually
        # not make any problems. Since we need to know the permissions of the
        # original file handle, we first retrieve them using the "h5f_get_intent"
        # function

        # Check permissions
        intent = h5f_get_intent(obj.file.id)
        flag = intent == H5F_ACC_RDONLY ? "r" : "r+"
        fd = open(obj.file.filename, flag)
    end

    offset = h5d_get_offset(obj.id)
    if offset % Base.datatype_alignment(T) == 0
        A = Mmap.mmap(fd, Array{T,length(dims)}, dims, offset)
    else
        Aflat = Mmap.mmap(fd, Array{UInt8,1}, prod(dims)*sizeof(T), offset)
        A = reshape(reinterpret(T, Aflat), dims)
    end

    if Sys.iswindows()
        close(fd)
    end

    return A
end

function readmmap(obj::Dataset)
    T = hdf5_to_julia(obj)
    ismmappable(T) || error("Cannot mmap datasets of type $T")
    iscontiguous(obj) || error("Cannot mmap discontiguous dataset")
    readmmap(obj, T)
end

# Generic write
function write(parent::Union{File,Group}, name1::AbstractString, val1, name2::AbstractString, val2, nameval...) # FIXME: remove?
    if !iseven(length(nameval))
        error("name, value arguments must come in pairs")
    end
    write(parent, name1, val1)
    write(parent, name2, val2)
    for i = 1:2:length(nameval)
        thisname = nameval[i]
        if !isa(thisname, AbstractString)
            error("Argument ", i+5, " should be a string, but it's a ", typeof(thisname))
        end
        write(parent, thisname, nameval[i+1])
    end
end

# Plain dataset & attribute writes
# Due to method ambiguities we generate these explicitly

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = d_create(parent, name, data; properties...)

function d_create(parent::Union{File,Group}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        d_create(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end
function a_create(parent::Union{File,Object}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        a_create(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end

# Create and write, closing the objects upon exit
function d_write(parent::Union{File,Group}, name::AbstractString, data; pv...)
    obj, dtype = d_create(parent, name, data; pv...)
    try
        writearray(obj, dtype.id, data)
    catch exc
        o_delete(obj)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end
function a_write(parent::Union{File,Object}, name::AbstractString, data; pv...)
    obj, dtype = a_create(parent, name, data; pv...)
    try
        writearray(obj, dtype.id, data)
    catch exc
        o_delete(obj)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end

# Write to already-created objects
# Scalars
function write(obj::DatasetOrAttribute, x::Union{T,Array{T}}) where {T<:Union{ScalarType,<:AbstractString,Complex{<:ScalarType}}}
    dtype = datatype(x)
    try
        writearray(obj, dtype.id, x)
    finally
       close(dtype)
    end
end
# VLEN types
function write(obj::DatasetOrAttribute, data::VLen{T}) where {T<:Union{ScalarType,CharType}}
    dtype = datatype(data)
    try
        writearray(obj, dtype.id, data)
    finally
        close(dtype)
    end
end
# For plain files and groups, let "write(obj, name, val; properties...)" mean "d_write"
write(parent::Union{File,Group}, name::AbstractString, data::Union{T,AbstractArray{T}}; pv...) where {T<:Union{ScalarType,<:AbstractString,Complex{<:ScalarType}}} =
    d_write(parent, name, data; pv...)
# For datasets, "write(dset, name, val; properties...)" means "a_write"
write(parent::Dataset, name::AbstractString, data::Union{T,AbstractArray{T}}; pv...) where {T<:Union{ScalarType,<:AbstractString}} =
    a_write(parent, name, data; pv...)


# Indexing

Base.eachindex(::IndexLinear, A::Dataset) = Base.OneTo(length(A))
Base.axes(dset::Dataset) = map(Base.OneTo, size(dset))

# Write to a subset of a dataset using array slices: dataset[:,:,10] = array

setindex!(dset::Dataset, x, I::Union{AbstractRange,Integer,Colon}...) =
    _setindex!(dset, x, Base.to_indices(dset, I)...)
function _setindex!(dset::Dataset, X::Array, I::Union{AbstractRange{Int},Int}...)
    T = hdf5_to_julia(dset)
    _setindex!(dset, T, X, I...)
end
function _setindex!(dset::Dataset, T::Type, X::Array, I::Union{AbstractRange{Int},Int}...)
    if !(T <: Array)
        error("Dataset indexing (hyperslab) is available only for arrays")
    end
    ET = eltype(T)
    if !(ET <: Union{ScalarType, Complex{<:ScalarType}})
        error("Dataset indexing (hyperslab) is available only for bits types")
    end
    if length(X) != prod(map(length, I))
        error("number of elements in range and length of array must be equal")
    end
    if eltype(X) != ET
        X = convert(Array{ET}, X)
    end
    dsel_id = hyperslab(dset, I...)
    memtype = datatype(X)
    memspace = dataspace(X)
    try
        h5d_write(dset.id, memtype.id, memspace.id, dsel_id, dset.xfer.id, X)
    finally
        close(memtype)
        close(memspace)
        h5s_close(dsel_id)
    end
    X
end
function _setindex!(dset::Dataset, X::AbstractArray, I::Union{AbstractRange{Int},Int}...)
    T = hdf5_to_julia(dset)
    if !(T <: Array)
        error("Hyperslab interface is available only for arrays")
    end
    Y = convert(Array{eltype(T), ndims(X)}, X)
    _setindex!(dset, Y, I...)
end
function _setindex!(dset::Dataset, x::Number, I::Union{AbstractRange{Int},Int}...)
    T = hdf5_to_julia(dset)
    if !(T <: Array)
        error("Hyperslab interface is available only for arrays")
    end
    X = fill(convert(eltype(T), x), map(length, I))
    _setindex!(dset, X, I...)
end

function hyperslab(dspace::Dataspace, I::Union{AbstractRange{Int},Int}...)
    local dsel_id
    try
        dims, maxdims = get_dims(dspace)
        n_dims = length(dims)
        if length(I) != n_dims
            error("Wrong number of indices supplied, supplied length $(length(I)) but expected $(n_dims).")
        end
        dsel_id = h5s_copy(dspace.id)
        dsel_start  = Vector{hsize_t}(undef,n_dims)
        dsel_stride = Vector{hsize_t}(undef,n_dims)
        dsel_count  = Vector{hsize_t}(undef,n_dims)
        for k = 1:n_dims
            index = I[n_dims-k+1]
            if isa(index, Integer)
                dsel_start[k] = index-1
                dsel_stride[k] = 1
                dsel_count[k] = 1
            elseif isa(index, AbstractRange)
                dsel_start[k] = first(index)-1
                dsel_stride[k] = step(index)
                dsel_count[k] = length(index)
            else
                error("index must be range or integer")
            end
            if dsel_start[k] < 0 || dsel_start[k]+(dsel_count[k]-1)*dsel_stride[k] >= dims[n_dims-k+1]
                println(dsel_start)
                println(dsel_stride)
                println(dsel_count)
                println(reverse(dims))
                error("index out of range")
            end
        end
        h5s_select_hyperslab(dsel_id, H5S_SELECT_SET, dsel_start, dsel_stride, dsel_count, C_NULL)
    finally
        close(dspace)
    end
    Dataspace(dsel_id)
end

function hyperslab(dset::Dataset, I::Union{AbstractRange{Int},Int}...)
    dspace = dataspace(dset)
    return hyperslab(dspace, I...)
end

# Link to bytes in an external file
# If you need to link to multiple segments, use low-level interface
function d_create_external(parent::Union{File,Group}, name::AbstractString, filepath::AbstractString, t, sz::Dims, offset::Integer=0)
    checkvalid(parent)
    dcpl  = p_create(H5P_DATASET_CREATE)
    h5p_set_external(dcpl , filepath, Int(offset), prod(sz)*sizeof(t)) # TODO: allow H5F_UNLIMITED
    d_create(parent, name, datatype(t), dataspace(sz); dcpl=dcpl)
end

function do_write_chunk(dataset::Dataset, offset, chunk_bytes::Vector{UInt8}, filter_mask=0)
    checkvalid(dataset)
    offs = collect(hsize_t, reverse(offset)) .- 1
    h5do_write_chunk(dataset, H5P_DEFAULT, UInt32(filter_mask), offs, length(chunk_bytes), chunk_bytes)
end

struct ChunkStorage
    dataset::Dataset
end

function setindex!(chunk_storage::ChunkStorage, v::Tuple{<:Integer,Vector{UInt8}}, index::Integer...)
    do_write_chunk(chunk_storage.dataset, hsize_t.(index), v[2], UInt32(v[1]))
end

# end of high-level interface


### HDF5 utilities ###
readarray(dset::Dataset, type_id, buf) = h5d_read(dset.id, type_id, buf, dset.xfer.id)
readarray(attr::Attribute, type_id, buf) = h5a_read(attr.id, type_id, buf)
writearray(dset::Dataset, type_id, buf) = h5d_write(dset.id, type_id, buf, dset.xfer.id)
writearray(attr::Attribute, type_id, buf) = h5a_write(attr.id, type_id, buf)
writearray(dset::Dataset, type_id, ::EmptyArray) = nothing
writearray(attr::Attribute, type_id, ::EmptyArray) = nothing

# Determine Julia "native" type from the class, datatype, and dataspace
# For datasets, defined file formats should use attributes instead
function hdf5_to_julia(obj::Union{Dataset, Attribute})
    local T
    objtype = datatype(obj)
    try
        T = hdf5_to_julia_eltype(objtype)
    finally
        close(objtype)
    end
    if T <: VLen
        return T
    end
    # Determine whether it's an array
    objspace = dataspace(obj)
    try
        stype = h5s_get_simple_extent_type(objspace.id)
        if stype == H5S_SIMPLE
            return Array{T}
        elseif stype == H5S_NULL
            return EmptyArray{T}
        else
            return T
        end
    finally
        close(objspace)
    end
end

function hdf5_to_julia_eltype(objtype)
    local T
    class_id = h5t_get_class(objtype.id)
    if class_id == H5T_STRING
        cset = h5t_get_cset(objtype.id)
        n = h5t_get_size(objtype.id)
        if cset == H5T_CSET_ASCII
            T = (n == 1) ? ASCIIChar : String
        elseif cset == H5T_CSET_UTF8
            T = (n == 1) ? UTF8Char : String
        else
            error("character set ", cset, " not recognized")
        end
    elseif class_id == H5T_INTEGER || class_id == H5T_FLOAT
        T = get_mem_compatible_jl_type(objtype)
    elseif class_id == H5T_BITFIELD
        T = get_mem_compatible_jl_type(objtype)
    elseif class_id == H5T_ENUM
        T = get_mem_compatible_jl_type(objtype)
    elseif class_id == H5T_REFERENCE
        T = get_mem_compatible_jl_type(objtype)
    elseif class_id == H5T_OPAQUE
        T = Opaque
    elseif class_id == H5T_VLEN
        super_id = h5t_get_super(objtype.id)
        T = VLen{hdf5_to_julia_eltype(Datatype(super_id))}
    elseif class_id == H5T_COMPOUND
        T = get_mem_compatible_jl_type(objtype)
    elseif class_id == H5T_ARRAY
        T = get_mem_compatible_jl_type(objtype)
    else
        error("Class id ", class_id, " is not yet supported")
    end
    return T
end

function get_jl_type(objtype::Datatype)
    class_id = h5t_get_class(objtype.id)
    if class_id == H5T_OPAQUE
        return Opaque
    else
        return get_mem_compatible_jl_type(objtype)
    end
end

function get_jl_type(obj)
    dtype = datatype(obj)
    try
        return get_jl_type(dtype)
    finally
        close(dtype)
    end
end

function get_mem_compatible_jl_type(objtype::Datatype)
    class_id = h5t_get_class(objtype.id)
    if class_id == H5T_STRING
        if h5t_is_variable_str(objtype.id)
            return Cstring
        else
            n = h5t_get_size(objtype.id)
            pad = h5t_get_strpad(objtype.id)
            return FixedString{Int(n), pad}
        end
    elseif class_id == H5T_INTEGER || class_id == H5T_FLOAT
        native_type = h5t_get_native_type(objtype.id)
        try
            native_size = h5t_get_size(native_type)
            if class_id == H5T_INTEGER
                is_signed = h5t_get_sign(native_type)
            else
                is_signed = nothing
            end
            return _hdf5_type_map(class_id, is_signed, native_size)
        finally
            h5t_close(native_type)
        end
    elseif class_id == H5T_BITFIELD
        return Bool
    elseif class_id == H5T_ENUM
        super_type = h5t_get_super(objtype.id)
        try
            native_type = h5t_get_native_type(super_type)
            try
                native_size = h5t_get_size(native_type)
                is_signed = h5t_get_sign(native_type)
                return _hdf5_type_map(H5T_INTEGER, is_signed, native_size)
            finally
                h5t_close(native_type)
            end
        finally
            h5t_close(super_type)
        end
    elseif class_id == H5T_REFERENCE
        # TODO update to use version 1.12 reference functions/types
        return Reference
    elseif class_id == H5T_VLEN
        superid = h5t_get_super(objtype.id)
        return VariableArray{get_mem_compatible_jl_type(Datatype(superid))}
    elseif class_id == H5T_COMPOUND
        N = h5t_get_nmembers(objtype.id)

        membernames = ntuple(N) do i
            h5t_get_member_name(objtype.id, i-1)
        end

        membertypes = ntuple(N) do i
            dtype = Datatype(h5t_get_member_type(objtype.id, i-1))
            return get_mem_compatible_jl_type(dtype)
        end

        # check if should be interpreted as complex
        iscomplex = COMPLEX_SUPPORT[] &&
                    N == 2 &&
                    (membernames == COMPLEX_FIELD_NAMES[]) &&
                    (membertypes[1] == membertypes[2]) &&
                    (membertypes[1] <: ScalarType)

        if iscomplex
            return Complex{membertypes[1]}
        else
            return NamedTuple{Symbol.(membernames), Tuple{membertypes...}}
        end
    elseif class_id == H5T_ARRAY
        dims = h5t_get_array_dims(objtype.id)
        nd = length(dims)
        eltyp = Datatype(h5t_get_super(objtype.id))
        elT = get_mem_compatible_jl_type(eltyp)
        dimsizes = ntuple(i -> Int(dims[nd-i+1]), nd)  # reverse order
        return FixedArray{elT, dimsizes, prod(dimsizes)}
    end
    error("Class id ", class_id, " is not yet supported")
end

### Convenience wrappers ###
# These supply default values where possible
# See also the "special handling" section below
h5a_write(attr_id::hid_t, mem_type_id::hid_t, buf::String) = h5a_write(attr_id, mem_type_id, unsafe_wrap(Vector{UInt8}, pointer(buf), ncodeunits(buf)))
function h5a_write(attr_id::hid_t, mem_type_id::hid_t, x::T) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    h5a_write(attr_id, mem_type_id, tmp)
end
function h5a_write(attr_id::hid_t, memtype_id::hid_t, strs::Array{S}) where {S<:String}
    p = Ref{Cstring}(strs)
    h5a_write(attr_id, memtype_id, p)
end
function h5a_write(attr_id::hid_t, memtype_id::hid_t, v::VLen{T}) where {T<:Union{ScalarType,CharType}}
    vp = vlenpack(v)
    h5a_write(attr_id, memtype_id, vp)
end
h5a_create(loc_id, name, type_id, space_id) = h5a_create(loc_id, name, type_id, space_id, _attr_properties(name), H5P_DEFAULT)
h5a_open(obj_id, name) = h5a_open(obj_id, name, H5P_DEFAULT)
h5d_create(loc_id, name, type_id, space_id) = h5d_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5d_open(obj_id, name) = h5d_open(obj_id, name, H5P_DEFAULT)
function h5d_read(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::hid_t=H5P_DEFAULT)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot read arrays with a different stride than `Array`"))
    h5d_read(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::hid_t=H5P_DEFAULT)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, str::AbstractString, xfer::hid_t=H5P_DEFAULT)
    ccall((:H5Dwrite, libhdf5), herr_t, (hid_t, hid_t, hid_t, hid_t, hid_t, Cstring), dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, str)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, x::T, xfer::hid_t=H5P_DEFAULT) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, tmp)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, strs::Array{<:AbstractString}, xfer::hid_t=H5P_DEFAULT)
    p = Ref{Cstring}(strs)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, p)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, v::VLen{T}, xfer::hid_t=H5P_DEFAULT) where {T<:Union{ScalarType,CharType}}
    vp = vlenpack(v)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, vp)
end
h5f_create(filename) = h5f_create(filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT)
h5f_open(filename, mode) = h5f_open(filename, mode, H5P_DEFAULT)
h5g_create(obj_id, name) = h5g_create(obj_id, name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5g_create(obj_id, name, lcpl_id, gcpl_id) = h5g_create(obj_id, name, lcpl_id, gcpl_id, H5P_DEFAULT)
h5g_open(file_id, name) = h5g_open(file_id, name, H5P_DEFAULT)
h5l_exists(loc_id, name) = h5l_exists(loc_id, name, H5P_DEFAULT)
h5o_open(obj_id, name) = h5o_open(obj_id, name, H5P_DEFAULT)
#h5s_get_simple_extent_ndims(space_id::hid_t) = h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)
h5t_get_native_type(type_id::hid_t) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)


# Functions that require special handling

const libversion = h5_get_libversion()

vlen_get_buf_size(dset::Dataset, dtype::Datatype, dspace::Dataspace) =
    h5d_vlen_get_buf_size(dset.id, dtype.id, dspace.id)

### Property manipulation ###
get_access_properties(d::Dataset)   = Properties(h5d_get_access_plist(d.id), H5P_DATASET_ACCESS)
get_access_properties(f::File)      = Properties(h5f_get_access_plist(f.id), H5P_FILE_ACCESS)
get_create_properties(d::Dataset)   = Properties(h5d_get_create_plist(d.id), H5P_DATASET_CREATE)
get_create_properties(g::Group)     = Properties(h5g_get_create_plist(g.id), H5P_GROUP_CREATE)
get_create_properties(f::File)      = Properties(h5f_get_create_plist(f.id), H5P_FILE_CREATE)
get_create_properties(a::Attribute) = Properties(h5a_get_create_plist(a.id), H5P_ATTRIBUTE_CREATE)

get_chunk(p::Properties) = tuple(convert(Vector{Int}, reverse(h5p_get_chunk(p)))...)
set_chunk(p::Properties, dims...) = h5p_set_chunk(p.id, length(dims), hsize_t[reverse(dims)...])
function get_chunk(dset::Dataset)
    p = get_create_properties(dset)
    local ret
    try
        ret = get_chunk(p)
    finally
        close(p)
    end
    ret
end

get_alignment(p::Properties) = h5p_get_alignment(checkvalid(p).id)
get_alloc_time(p::Properties) = h5p_get_alloc_time(checkvalid(p).id)
get_userblock(p::Properties) = h5p_get_userblock(checkvalid(p).id)
get_fclose_degree(p::Properties) = h5p_get_fclose_degree(checkvalid(p).id)
get_libver_bounds(p::Properties) = h5p_get_libver_bounds(checkvalid(p).id)

"""
    get_datasets(file::HDF5.File) -> datasets::Vector{HDF5.Dataset}

Get all the datasets in an hdf5 file without loading the data.
"""
function get_datasets(file::File)
    list = Dataset[]
    get_datasets!(list, file)
    list
end
 function get_datasets!(list::Vector{Dataset}, node::Union{File,Group,Dataset})
    if isa(node, Dataset)
        push!(list, node)
    else
        for c in keys(node)
            get_datasets!(list, node[c])
        end
    end
end

# properties that require chunks in order to work (e.g. any filter)
# values do not matter -- just needed to form a NamedTuple with the desired keys
const chunked_props = (; compress=nothing, deflate=nothing, blosc=nothing, shuffle=nothing)

"""
    create_external(source::Union{HDF5.File, HDF5.Group}, source_relpath, target_filename, target_path;
                    lcpl_id=HDF5.H5P_DEFAULT, lapl_id=HDF5.H5P.DEFAULT)

Create an external link such that `source[source_relpath]` points to `target_path` within the file
with path `target_filename`; Calls `[H5Lcreate_external](https://www.hdfgroup.org/HDF5/doc/RM/RM_H5L.html#Link-CreateExternal)`.
"""
function create_external(source::Union{File,Group}, source_relpath, target_filename, target_path; lcpl_id=H5P_DEFAULT, lapl_id=H5P_DEFAULT)
    h5l_create_external(target_filename, target_path, source.id, source_relpath, lcpl_id, lapl_id)
    nothing
end

# error handling
function hiding_errors(f)
    error_stack = H5E_DEFAULT
    # error_stack = ccall((:H5Eget_current_stack, libhdf5), hid_t, ())
    old_func, old_client_data = h5e_get_auto(error_stack)
    h5e_set_auto(error_stack, C_NULL, C_NULL)
    res = f()
    h5e_set_auto(error_stack, old_func, old_client_data)
    return res
end

# Define globally because JLD uses this, too
const rehash! = Base.rehash!

# Across initializations of the library, the id of various properties
# will change. So don't hard-code the id (important for precompilation)
const UTF8_LINK_PROPERTIES = Ref{Properties}()
_link_properties(::AbstractString) = UTF8_LINK_PROPERTIES[]
const UTF8_ATTRIBUTE_PROPERTIES = Ref{Properties}()
_attr_properties(::AbstractString) = UTF8_ATTRIBUTE_PROPERTIES[]
const ASCII_LINK_PROPERTIES = Ref{Properties}()
const ASCII_ATTRIBUTE_PROPERTIES = Ref{Properties}()

const DEFAULT_PROPERTIES = Properties(H5P_DEFAULT, H5P_DEFAULT)

const HAS_PARALLEL = Ref(false)

"""
    has_parallel()

Returns `true` if the HDF5 libraries were compiled with parallel support,
and if parallel functionality was loaded into HDF5.jl.

For the second condition to be true, MPI.jl must be imported before HDF5.jl.
"""
has_parallel() = HAS_PARALLEL[]

function __init__()
    check_deps()

    # disable file locking as that can cause problems with mmap'ing
    if !haskey(ENV, "HDF5_USE_FILE_LOCKING")
        ENV["HDF5_USE_FILE_LOCKING"] = "FALSE"
    end

    register_blosc()

    # Turn off automatic error printing
    # h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)

    ASCII_LINK_PROPERTIES[] = p_create(H5P_LINK_CREATE; char_encoding = H5T_CSET_ASCII,
                                       create_intermediate_group = 1)
    UTF8_LINK_PROPERTIES[]  = p_create(H5P_LINK_CREATE; char_encoding = H5T_CSET_UTF8,
                                       create_intermediate_group = 1)
    ASCII_ATTRIBUTE_PROPERTIES[] = p_create(H5P_ATTRIBUTE_CREATE; char_encoding = H5T_CSET_ASCII)
    UTF8_ATTRIBUTE_PROPERTIES[]  = p_create(H5P_ATTRIBUTE_CREATE; char_encoding = H5T_CSET_UTF8)

    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" @eval include("mpio.jl")

    return nothing
end

include("deprecated.jl")

end  # module
