module HDF5

using Base: unsafe_convert, StringVector
using Requires: @require
# needed for filter(f, tuple) in julia 1.3
using Compat

import Libdl
import Mmap

### PUBLIC API ###

export
@read, @write,
h5open, h5read, h5write, h5rewrite, h5writeattr, h5readattr,
create_attribute, open_attribute, read_attribute, write_attribute, delete_attribute, attributes,
create_dataset, open_dataset, read_dataset, write_dataset,
create_group, open_group,
copy_object, open_object, delete_object,
create_datatype, commit_datatype, open_datatype,
create_property,
group_info, object_info,
dataspace, datatype

### The following require module scoping ###

# file, filename, name,
# get_chunk, get_datasets,
# get_access_properties, get_create_properties,
# root, readmmap, set_dims!,
# iscontiguous, iscompact, ischunked,
# ishdf5, ismmappable,
# refresh
# start_swmr_write
# create_external, create_external_dataset

### Types
# H5DataStore, Attribute, File, Group, Dataset, Datatype, Opaque,
# Dataspace, Object, Properties, VLen, ChunkStorage, Reference


const depsfile = joinpath(dirname(@__DIR__), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
          "and restart Julia.")
end

# Core API ccall wrappers
include("api_types.jl")
include("api.jl")
include("api_helpers.jl")


### Generic H5DataStore interface ###

# Common methods that could be applicable to any interface for reading/writing variables from a file, e.g. HDF5, JLD, or MAT files.
# Types inheriting from H5DataStore should have names, read, and write methods.
# Supertype of HDF5.File, HDF5.Group, JldFile, JldGroup, Matlabv5File, and MatlabHDF5File.
abstract type H5DataStore end

# Convenience macros
macro read(fid, sym)
    !isa(sym, Symbol) && error("Second input to @read must be a symbol (i.e., a variable)")
    esc(:($sym = read($fid, $(string(sym)))))
end
macro write(fid, sym)
    !isa(sym, Symbol) && error("Second input to @write must be a symbol (i.e., a variable)")
    esc(:(write($fid, $(string(sym)), $sym)))
end

# Read a list of variables, read(parent, "A", "B", "x", ...)
function Base.read(parent::H5DataStore, name::AbstractString...)
    tuple((read(parent, x) for x in name)...)
end

# Read every variable in the file
function Base.read(f::H5DataStore)
    vars = keys(f)
    vals = Vector{Any}(undef,length(vars))
    for i = 1:length(vars)
        vals[i] = read(f, vars[i])
    end
    Dict(zip(vars, vals))
end

### Base HDF5 structs ###

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
Base.length(c::ASCIIChar) = 1

struct UTF8Char <: CharType
    c::UInt8
end
Base.length(c::UTF8Char) = 1

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
            return native_size == 1 ? Int8 :
                   native_size == 2 ? Int16 :
                   native_size == 4 ? Int32 :
                   native_size == 8 ? Int64 :
                   throw(KeyError((class_id, is_signed, native_size)))
        else
            return native_size == 1 ? UInt8 :
                   native_size == 2 ? UInt16 :
                   native_size == 4 ? UInt32 :
                   native_size == 8 ? UInt64 :
                   throw(KeyError((class_id, is_signed, native_size)))
        end
    else
        return native_size == 4 ? Float32 :
               native_size == 8 ? Float64 :
               throw(KeyError((class_id, is_signed, native_size)))
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
mutable struct File <: H5DataStore
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
Base.cconvert(::Type{hid_t}, f::File) = f.id

mutable struct Group <: H5DataStore
    id::hid_t
    file::File         # the parent file

    function Group(id, file)
        g = new(id, file)
        finalizer(close, g)
        g
    end
end
Base.cconvert(::Type{hid_t}, g::Group) = g.id

mutable struct Properties
    id::hid_t
    class::hid_t
    function Properties(id = H5P_DEFAULT, class = H5P_DEFAULT)
        p = new(id, class)
        finalizer(close, p) # Essential, otherwise we get a memory leak, since closing file with CLOSE_STRONG is not doing it for us
        p
    end
end
Base.cconvert(::Type{hid_t}, p::Properties) = p.id

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
Base.cconvert(::Type{hid_t}, dset::Dataset) = dset.id

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
Base.cconvert(::Type{hid_t}, dtype::Datatype) = dtype.id
Base.hash(dtype::Datatype, h::UInt) = hash(dtype.id, hash(Datatype, h))
Base.:(==)(dt1::Datatype, dt2::Datatype) = h5t_equal(dt1, dt2)

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
Base.cconvert(::Type{hid_t}, dspace::Dataspace) = dspace.id
Base.:(==)(dspace1::Dataspace, dspace2::Dataspace) = h5s_extent_equal(checkvalid(dspace1), checkvalid(dspace2))
Base.hash(dspace::Dataspace, h::UInt) = hash(dspace.id, hash(Dataspace, h))
Base.copy(dspace::Dataspace) = Dataspace(h5s_copy(checkvalid(dspace)))

mutable struct Attribute
    id::hid_t
    file::File

    function Attribute(id, file)
        dset = new(id, file)
        finalizer(close, dset)
        dset
    end
end
Base.cconvert(::Type{hid_t}, attr::Attribute) = attr.id

struct Attributes
    parent::Union{File,Object}
end
attributes(p::Union{File,Object}) = Attributes(p)

# Methods for reference types
function Reference(parent::Union{File,Group,Dataset}, name::AbstractString)
    ref = Ref{hobj_ref_t}()
    h5r_create(ref, checkvalid(parent), name, H5R_OBJECT, -1)
    return Reference(ref[])
end
Base.:(==)(a::Reference, b::Reference) = a.r == b.r
Base.hash(x::Reference, h::UInt) = hash(x.r, h)

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
Base.size(::Type{FixedArray{T,D,L}}) where {T,D,L} = D
Base.size(x::FixedArray) = size(typeof(x))
Base.eltype(::Type{FixedArray{T,D,L}}) where {T,D,L} = T
Base.eltype(x::FixedArray) = eltype(typeof(x))

struct FixedString{N,PAD}
    data::NTuple{N,UInt8}
end
Base.length(::Type{FixedString{N,PAD}}) where {N,PAD} = N
Base.length(str::FixedString) = length(typeof(str))
pad(::Type{FixedString{N,PAD}}) where {N,PAD} = PAD
pad(x::T) where {T<:FixedString} = pad(T)

struct VariableArray{T}
    len::Csize_t
    p::Ptr{Cvoid}
end
Base.eltype(::Type{VariableArray{T}}) where T = T

# VLEN objects
struct VLen{T}
    data::Array
end
VLen(strs::Array{S}) where {S<:String} = VLen{chartype(S)}(strs)
VLen(A::Array{Array{T}}) where {T<:ScalarType} = VLen{T}(A)
VLen(A::Array{Array{T,N}}) where {T<:ScalarType,N} = VLen{T}(A)
function Base.cconvert(::Type{Ptr{Cvoid}}, v::VLen)
    len = length(v.data)
    h = Vector{hvl_t}(undef, len)
    for ii in 1:len
        d = v.data[ii]
        p = unsafe_convert(Ptr{UInt8}, d)
        h[ii] = hvl_t(length(d), p)
    end
    return h
end

include("show.jl")

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
function h5open(filename::AbstractString, mode::AbstractString = "r"; swmr::Bool = false, pv...)
    # With garbage collection, the other modes don't make sense
    fapl = create_property(H5P_FILE_ACCESS; pv..., fclose_degree = H5F_CLOSE_STRONG) # file access property list
    fcpl = isempty(pv) ? DEFAULT_PROPERTIES : create_property(H5P_FILE_CREATE; pv...) # file create property list
    rd, wr, cr, tr, ff =
        mode == "r"  ? (true,  false, false, false, false) :
        mode == "r+" ? (true,  true,  false, false, true ) :
        mode == "cw" ? (false, true,  true,  false, true ) :
        mode == "w"  ? (false, true,  true,  true,  false) :
        # mode == "w+" ? (true,  true,  true,  true,  false) :
        # mode == "a"  ? (true,  true,  true,  true,  true ) :
        error("invalid open mode: ", mode)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end

    if cr && (tr || !isfile(filename))
        flag = swmr ? H5F_ACC_TRUNC|H5F_ACC_SWMR_WRITE : H5F_ACC_TRUNC
        fid = h5f_create(filename, flag, fcpl, fapl)
    else
        ishdf5(filename) || error("unable to determine if $filename is accessible in the HDF5 format (file may not exist)")
        if wr
            flag = swmr ? H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE : H5F_ACC_RDWR
        else
            flag = swmr ? H5F_ACC_RDONLY|H5F_ACC_SWMR_READ : H5F_ACC_RDONLY
        end
        fid = h5f_open(filename, flag, fapl)
    end
    close(fapl)
    fcpl != DEFAULT_PROPERTIES && close(fcpl)
    return File(fid, filename)
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
        close(obj)
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
        close(obj)
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
        close(dset)
    finally
        close(fid)
    end
    dat
end

function h5writeattr(filename, name::AbstractString, data::Dict)
    fid = h5open(filename, "r+")
    try
        obj = fid[name]
        attrs = attributes(obj)
        for x in keys(data)
            attrs[x] = data[x]
        end
        close(obj)
    finally
        close(fid)
    end
end

function h5readattr(filename, name::AbstractString)
    local dat
    fid = h5open(filename,"r")
    try
        obj = fid[name]
        a = attributes(obj)
        dat = Dict(x => read(a[x]) for x in keys(a))
        close(obj)
    finally
        close(fid)
    end
    dat
end

# Ensure that objects haven't been closed
Base.isvalid(obj::Union{File,Properties,Datatype,Dataspace}) = obj.id != -1 && h5i_is_valid(obj)
Base.isvalid(obj::Union{Group,Dataset,Attribute}) = obj.id != -1 && obj.file.id != -1 && h5i_is_valid(obj)
Base.isvalid(obj::Attributes) = isvalid(obj.parent)
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Close functions

# Close functions that should try calling close regardless
function Base.close(obj::File)
    if obj.id != -1
        h5f_close(obj)
        obj.id = -1
    end
    nothing
end

"""
    isopen(obj::HDF5.File)

Returns `true` if `obj` has not been closed, `false` if it has been closed.
"""
Base.isopen(obj::File) = obj.id != -1


# Close functions that should first check that the file is still open. The common case is a
# file that has been closed with CLOSE_STRONG but there are still finalizers that have not run
# for the datasets, etc, in the file.

function Base.close(obj::Union{Group,Dataset})
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

function Base.close(obj::Attribute)
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            h5a_close(obj)
        end
        obj.id = -1
    end
    nothing
end

function Base.close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

function Base.close(obj::Dataspace)
    if obj.id != -1
        if isvalid(obj)
            h5s_close(obj)
        end
        obj.id = -1
    end
    nothing
end

function Base.close(obj::Properties)
    if obj.id != -1
        if isvalid(obj)
            h5p_close(obj)
        end
        obj.id = -1
    end
    nothing
end

"""
    ishdf5(name::AbstractString)

Returns `true` if the file specified by `name` is in the HDF5 format, and `false` otherwise.
"""
function ishdf5(name::AbstractString)
    isfile(name) || return false # fastpath in case the file is non-existant
    # TODO: v1.12 use the more robust h5f_is_accesible
    try
        # docs falsely claim h5f_is_hdf5 doesn't error, but it does and prints the error stack on fail
        # silence the error stack in case the call throws
        return silence_errors(() -> h5f_is_hdf5(name))
    catch
        return false
    end
end

# Extract the file
file(f::File) = f
file(o::Union{Object,Attribute}) = o.file
fd(obj::Object) = h5i_get_file_id(checkvalid(obj))

# Flush buffers
Base.flush(f::Union{Object,Attribute,Datatype,File}, scope = H5F_SCOPE_GLOBAL) = h5f_flush(checkvalid(f), scope)

# Open objects
open_group(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Group(h5g_open(checkvalid(parent), name, apl), file(parent))
open_dataset(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES, xpl::Properties=DEFAULT_PROPERTIES) = Dataset(h5d_open(checkvalid(parent), name, apl), file(parent), xpl)
open_datatype(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Datatype(h5t_open(checkvalid(parent), name, apl), file(parent))
open_attribute(parent::Union{File,Object}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Attribute(h5a_open(checkvalid(parent), name, apl), file(parent))
# Object (group, named datatype, or dataset) open
function h5object(obj_id::hid_t, parent)
    obj_type = h5i_get_type(obj_id)
    obj_type == H5I_GROUP ? Group(obj_id, file(parent)) :
    obj_type == H5I_DATATYPE ? Datatype(obj_id, file(parent)) :
    obj_type == H5I_DATASET ? Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
open_object(parent, path::AbstractString) = h5object(h5o_open(checkvalid(parent), path, H5P_DEFAULT), parent)
function gettype(parent, path::AbstractString)
    obj_id = h5o_open(checkvalid(parent), path, H5P_DEFAULT)
    obj_type = h5i_get_type(obj_id)
    h5o_close(obj_id)
    return obj_type
end
# Get the root group
root(h5file::File) = open_group(h5file, "/")
root(obj::Union{Group,Dataset}) = open_group(file(obj), "/")

function Base.getindex(dset::Dataset, name::AbstractString)
    haskey(dset, name) || throw(KeyError(name))
    open_attribute(dset, name)
end
function Base.getindex(x::Attributes, name::AbstractString)
    haskey(x, name) || throw(KeyError(name))
    open_attribute(x.parent, name)
end
function Base.getindex(parent::Union{File,Group}, path::AbstractString; pv...)
    haskey(parent, path) || throw(KeyError(path))
    # Faster than below if defaults are OK
    isempty(pv) && return open_object(parent, path)
    obj_type = gettype(parent, path)
    if obj_type == H5I_DATASET
        dapl = create_property(H5P_DATASET_ACCESS; pv...)
        dxpl = create_property(H5P_DATASET_XFER; pv...)
        return open_dataset(parent, path, dapl, dxpl)
    elseif obj_type == H5I_GROUP
        gapl = create_property(H5P_GROUP_ACCESS; pv...)
        return open_group(parent, path, gapl)
    else#if obj_type == H5I_DATATYPE # only remaining choice
        tapl = create_property(H5P_DATATYPE_ACCESS; pv...)
        return open_datatype(parent, path, tapl)
    end
end

# Path manipulation
function split1(path::AbstractString)
    ind = findfirst('/', path)
    isnothing(ind) && return path, ""
    if ind == 1 # matches root group
        return "/", path[2:end]
    else
        indm1, indp1 = prevind(path, ind), nextind(path, ind)
        return path[1:indm1], path[indp1:end] # better to use begin:indm1, but only available on v1.5
    end
end

function create_group(parent::Union{File,Group}, path::AbstractString,
                  lcpl::Properties=_link_properties(path),
                  gcpl::Properties=DEFAULT_PROPERTIES)
    haskey(parent, path) && error("cannot create group: object \"", path, "\" already exists at ", name(parent))
    Group(h5g_create(parent, path, lcpl, gcpl, H5P_DEFAULT), file(parent))
end

# Setting dset creation properties with name/value pairs
function create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace; pv...)
    dcpl = isempty(pv) ? DEFAULT_PROPERTIES : create_property(H5P_DATASET_CREATE; pv...)
    dxpl = isempty(pv) ? DEFAULT_PROPERTIES : create_property(H5P_DATASET_XFER; pv...)
    dapl = isempty(pv) ? DEFAULT_PROPERTIES : create_property(H5P_DATASET_ACCESS; pv...)
    haskey(parent, path) && error("cannot create dataset: object \"", path, "\" already exists at ", name(parent))
    Dataset(h5d_create(parent, path, dtype, dspace, _link_properties(path), dcpl, dapl), file(parent), dxpl)
end
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Dims; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims); pv...)
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Type, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
create_datatype(class_id, sz) = Datatype(h5t_create(class_id, sz))
function commit_datatype(parent::Union{File,Group}, path::AbstractString, dtype::Datatype,
                  lcpl::Properties=create_property(H5P_LINK_CREATE), tcpl::Properties=DEFAULT_PROPERTIES, tapl::Properties=DEFAULT_PROPERTIES)
    h5p_set_char_encoding(lcpl, cset(typeof(path)))
    h5t_commit(checkvalid(parent), path, dtype, lcpl, tcpl, tapl)
    dtype.file = file(parent)
    return dtype
end

function create_attribute(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace)
    attrid = h5a_create(checkvalid(parent), name, dtype, dspace, _attr_properties(name), H5P_DEFAULT)
    return Attribute(attrid, file(parent))
end

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

function create_property(class; pv...)
    p = Properties(h5p_create(class), class)
    for (k, v) in pairs(pv)
        _prop_set!(p, k, v, false)
    end
    return p
end

# Delete objects
delete_attribute(parent::Union{File,Object}, path::AbstractString) = h5a_delete(checkvalid(parent), path)
delete_object(parent::Union{File,Group}, path::AbstractString, lapl::Properties=DEFAULT_PROPERTIES) = h5l_delete(checkvalid(parent), path, lapl)
delete_object(obj::Object) = delete_object(parent(obj), ascii(split(name(obj),"/")[end])) # FIXME: remove ascii?

# Copy objects
copy_object(src_parent::Union{File,Group}, src_path::AbstractString, dst_parent::Union{File,Group}, dst_path::AbstractString) = h5o_copy(checkvalid(src_parent), src_path, checkvalid(dst_parent), dst_path, H5P_DEFAULT, _link_properties(dst_path))
copy_object(src_obj::Object, dst_parent::Union{File,Group}, dst_path::AbstractString) = h5o_copy(checkvalid(src_obj), ".", checkvalid(dst_parent), dst_path, H5P_DEFAULT, _link_properties(dst_path))

# Assign syntax: obj[path] = value
# Creates a dataset unless obj is a dataset, in which case it creates an attribute
Base.setindex!(dset::Dataset, val, name::AbstractString) = write_attribute(dset, name, val)
Base.setindex!(x::Attributes, val, name::AbstractString) = write_attribute(x.parent, name, val)
# Getting and setting properties: p[:chunk] = dims, p[:compress] = 6
Base.getindex(p::Properties, name::Symbol) = _prop_get(checkvalid(p), name)
function Base.setindex!(p::Properties, val, name::Symbol)
    _prop_set!(checkvalid(p), name, val, true)
    return p
end
# Create a dataset with properties: obj[path, prop = val, ...] = val
function Base.setindex!(parent::Union{File,Group}, val, path::AbstractString; pv...)
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
function Base.haskey(parent::Union{File,Group}, path::AbstractString, lapl::Properties = DEFAULT_PROPERTIES)
    checkvalid(parent)
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !h5l_exists(parent, first, lapl)
        return false
    end
    exists = true
    if !isempty(rest)
        obj = parent[first]
        exists = haskey(obj, rest, lapl)
        close(obj)
    end
    return exists
end
Base.haskey(attr::Attributes, path::AbstractString) = h5a_exists(checkvalid(attr.parent), path)
Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) = h5a_exists(checkvalid(dset), path)

# Querying items in the file
group_info(obj::Union{Group,File}) = h5g_get_info(checkvalid(obj))
object_info(obj::Union{File,Object}) = h5o_get_info(checkvalid(obj))

Base.length(obj::Union{Group,File}) = Int(h5g_get_num_objs(checkvalid(obj)))
Base.length(x::Attributes) = Int(object_info(x.parent).num_attrs)

Base.isempty(x::Union{Group,File}) = length(x) == 0
Base.eltype(dset::Union{Dataset,Attribute}) = get_jl_type(dset)

# filename and name
filename(obj::Union{File,Group,Dataset,Attribute,Datatype}) = h5f_get_name(checkvalid(obj))
name(obj::Union{File,Group,Dataset,Datatype}) = h5i_get_name(checkvalid(obj))
name(attr::Attribute) = h5a_get_name(attr)
function Base.keys(x::Union{Group,File})
    checkvalid(x)
    children = sizehint!(String[], length(x))
    h5l_iterate(x, H5_INDEX_NAME, H5_ITER_INC) do _, name, _
        push!(children, unsafe_string(name))
        return herr_t(0)
    end
    return children
end

function Base.keys(x::Attributes)
    checkvalid(x.parent)
    children = sizehint!(String[], length(x))
    h5a_iterate(x.parent, H5_INDEX_NAME, H5_ITER_INC) do _, attr_name, _
        push!(children, unsafe_string(attr_name))
        return herr_t(0)
    end
    return children
end

# iteration by objects
function Base.iterate(parent::Union{File,Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(h5o_open_by_idx(checkvalid(parent), ".", H5_INDEX_NAME, H5_ITER_INC, n-1, H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
end

Base.lastindex(dset::Dataset) = length(dset)
Base.lastindex(dset::Dataset, d::Int) = size(dset, d)

function Base.parent(obj::Union{File,Group,Dataset})
    f = file(obj)
    path = name(obj)
    if length(path) == 1
        return f
    end
    parentname = dirname(path)
    if !isempty(parentname)
        return open_object(f, dirname(path))
    else
        return root(f)
    end
end

# Get the datatype of a dataset
datatype(dset::Dataset) = Datatype(h5d_get_type(checkvalid(dset)), file(dset))
# Get the datatype of an attribute
datatype(dset::Attribute) = Datatype(h5a_get_type(checkvalid(dset)), file(dset))

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
datatype(x::Complex{<:ScalarType}) = datatype(typeof(x))
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

Base.sizeof(dtype::Datatype) = Int(h5t_get_size(dtype))

# Get the dataspace of a dataset
dataspace(dset::Dataset) = Dataspace(h5d_get_space(checkvalid(dset)))
# Get the dataspace of an attribute
dataspace(attr::Attribute) = Dataspace(h5a_get_space(checkvalid(attr)))

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


function Base.ndims(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    ret = h5s_get_simple_extent_ndims(dspace)
    obj isa Dataspace || close(dspace)
    return ret
end
function Base.size(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    h5_dims = h5s_get_simple_extent_dims(dspace, nothing)
    N = length(h5_dims)
    ret = ntuple(i -> @inbounds(Int(h5_dims[N-i+1])), N)
    obj isa Dataspace || close(dspace)
    return ret
end
function Base.size(obj::Union{Dataspace,Dataset,Attribute}, d::Integer)
    d > 0 || throw(ArgumentError("invalid dimension d; must be positive integer"))
    N = ndims(obj)
    d > N && return 1
    dspace = obj isa Dataspace ? obj : dataspace(obj)
    h5_dims = h5s_get_simple_extent_dims(dspace, nothing)
    ret = @inbounds Int(h5_dims[N - d + 1])
    obj isa Dataspace || close(dspace)
    return ret
end
function Base.length(obj::Union{Dataspace,Dataset,Attribute})
    isnull(obj) && return 0
    dspace = obj isa Dataspace ? obj : dataspace(obj)
    h5_dims = h5s_get_simple_extent_dims(dspace, nothing)
    ret = Int(prod(h5_dims))
    obj isa Dataspace || close(dspace)
    return ret
end
Base.isempty(dspace::Union{Dataspace,Dataset,Attribute}) = length(dspace) == 0

"""
    isnull(dspace::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute})

Determines whether the given object has no size (consistent with the `H5S_NULL` dataspace).

# Examples
```julia-repl
julia> HDF5.isnull(dataspace(HDF5.EmptyArray{Float64}()))
true

julia> HDF5.isnull(dataspace((0,)))
false
```
"""
function isnull(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    ret = h5s_get_simple_extent_type(dspace) == H5S_NULL
    obj isa Dataspace || close(dspace)
    return ret
end


function get_regular_hyperslab(dspace::Dataspace)
    start, stride, count, block = h5s_get_regular_hyperslab(dspace)
    N = length(start)
    @inline rev(v) = ntuple(i -> @inbounds(Int(v[N-i+1])), N)
    return rev(start), rev(stride), rev(count), rev(block)
end


"""
    start_swmr_write(h5::HDF5.File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://portal.hdfgroup.org/display/HDF5/Single+Writer+Multiple+Reader++-+SWMR).
"""
start_swmr_write(h5::File) = h5f_start_swmr_write(h5)

refresh(ds::Dataset) = h5d_refresh(checkvalid(ds))
Base.flush(ds::Dataset) = h5d_flush(checkvalid(ds))

# Generic read functions
# Generic read functions
function read_dataset(parent::Union{File,Group}, name::AbstractString)
    local ret
    obj = open_dataset(parent, name)
    try
        ret = read(obj)
    finally
        close(obj)
    end
    ret
end

function read_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)
    local ret
    obj = open_attribute(parent, name)
    try
        ret = read(obj)
    finally
        close(obj)
    end
    ret
end

function Base.read(parent::Union{File,Group}, name::AbstractString; pv...)
    obj = getindex(parent, name; pv...)
    val = read(obj)
    close(obj)
    val
end

function Base.read(parent::Union{File,Group}, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    obj = getindex(parent, name_type_pair[1]; pv...)
    val = read(obj, name_type_pair[2])
    close(obj)
    val
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5.Datatype. Specific file formats should provide their own read(dset).
const DatasetOrAttribute = Union{Dataset,Attribute}

function Base.read(obj::DatasetOrAttribute)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    val = generic_read(obj, dtype, T)
    close(dtype)
    return val
end

function Base.getindex(dset::Dataset, I...)
    dtype = datatype(dset)
    T = get_jl_type(dtype)
    val = generic_read(dset, dtype, T, I...)
    close(dtype)
    return val
end

function Base.read(obj::DatasetOrAttribute, ::Type{T}, I...) where T
    dtype = datatype(obj)
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

# `Type{String}` does not have a definite size, so the generic_read does not accept
# it even though it will return a `String`. This explicit overload allows that usage.
function Base.read(obj::DatasetOrAttribute, ::Type{String}, I...)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    T <: Union{Cstring, FixedString} || error(name(obj), " cannot be read as type `String`")
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

# Special handling for reading OPAQUE datasets and attributes
function generic_read(obj::DatasetOrAttribute, filetype::Datatype, ::Type{Opaque})
    sz  = size(obj)
    buf = Matrix{UInt8}(undef, sizeof(filetype), prod(sz))
    if obj isa Dataset
        read_dataset(obj, filetype, buf, obj.xfer)
    else
        read_attribute(obj, filetype, buf)
    end
    tag = h5t_get_tag(filetype)
    if isempty(sz)
        # scalar (only) result
        data = vec(buf)
    else
        # array of opaque objects
        data = reshape([buf[:,i] for i in 1:prod(sz)], sz...)
    end
    return Opaque(data, tag)
end

# generic read function
function generic_read(obj::DatasetOrAttribute, filetype::Datatype, ::Type{T}, I...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    !isempty(I) && obj isa Attribute && error("HDF5 attributes do not support hyperslab selections")

    memtype = Datatype(h5t_get_native_type(filetype))  # padded layout in memory

    if sizeof(T) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($T) = $(sizeof(T))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

    dspace = dataspace(obj)
    stype = h5s_get_simple_extent_type(dspace)
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
        sz = size(dspace)
    else
        sz = map(length, filter(i -> !isa(i, Int), indices))
        if isempty(sz)
            sz = (1,)
            scalar = true
        end
    end

    if do_normalize(T)
        # The entire dataset is read into in a buffer matrix where the first dimension at
        # any stage of normalization is the bytes for a single element of type `T`, and
        # the second dimension of the matrix runs through all elements.
        buf = Matrix{UInt8}(undef, sizeof(T), prod(sz))
    else
        buf = Array{T}(undef, sz...)
    end
    memspace = isempty(I) ? dspace : dataspace(sz)

    if obj isa Dataset
        h5d_read(obj, memtype, memspace, dspace, obj.xfer, buf)
    else
        h5a_read(obj, memtype, buf)
    end

    if do_normalize(T)
        out = reshape(normalize_types(T, buf), sz...)
    else
        out = buf
    end

    xfer_id = obj isa Dataset ? obj.xfer.id : H5P_DEFAULT
    do_reclaim(T) && h5d_vlen_reclaim(memtype, memspace, xfer_id, buf)

    close(memtype)
    close(memspace)
    close(dspace)

    if scalar
        return out[1]
    else
        return out
    end
end

# Array constructor for datasets
Array(x::Dataset) = read(x)

# Clean up string buffer according to padding mode
function unpad(s::String, pad::Integer)::String
    if pad == H5T_STR_NULLTERM # null-terminated
        ind = findfirst(isequal('\0'), s)
        isnothing(ind) ? s : s[1:prevind(s, ind)]
    elseif pad == H5T_STR_NULLPAD # padded with nulls
        rstrip(s, '\0')
    elseif pad == H5T_STR_SPACEPAD # padded with spaces
        rstrip(s, ' ')
    else
        error("Unrecognized string padding mode $pad")
    end
end
unpad(s, pad::Integer) = unpad(String(s), pad)

# Dereference
function _deref(parent, r::Reference)
    r == Reference() && error("Reference is null")
    obj_id = h5r_dereference(checkvalid(parent), H5P_DEFAULT, H5R_OBJECT, r)
    h5object(obj_id, parent)
end
Base.getindex(parent::Union{File,Group}, r::Reference) = _deref(parent, r)
Base.getindex(parent::Dataset, r::Reference) = _deref(parent, r) # defined separately to resolve ambiguity

# convert special types to native julia types
function normalize_types(::Type{T}, buf::AbstractMatrix{UInt8}) where {T}
    # First dimension spans bytes of a single element of type T --- (recursively) normalize
    # each range of bytes to final type, returning vector of normalized data.
    return [_normalize_types(T, view(buf, :, ind)) for ind in axes(buf, 2)]
end

# high-level description which should always work --- here, the buffer contains the bytes
# for exactly 1 element of an object of type T, so reinterpret the `UInt8` vector as a
# length-1 array of type `T` and extract the (only) element.
function _typed_load(::Type{T}, buf::AbstractVector{UInt8}) where {T}
    return @inbounds reinterpret(T, buf)[1]
end
# fast-path for common concrete types with simple layout (which should be nearly all cases)
function _typed_load(::Type{T}, buf::V) where {T, V <: Union{Vector{UInt8}, Base.FastContiguousSubArray{UInt8,1}}}
    dest = Ref{T}()
    GC.@preserve dest buf Base._memcpy!(unsafe_convert(Ptr{Cvoid}, dest), pointer(buf), sizeof(T))
    return dest[]
    # TODO: The above can maybe be replaced with
    #   return GC.@preserve buf unsafe_load(convert(Ptr{t}, pointer(buf)))
    # dependent on data elements being properly aligned for all datatypes, on all
    # platforms.
end

_normalize_types(::Type{T}, buf::AbstractVector{UInt8}) where {T} = _typed_load(T, buf)
function _normalize_types(::Type{T}, buf::AbstractVector{UInt8}) where {K, T <: NamedTuple{K}}
    # Compound data types do not necessarily have members of uniform size, so instead of
    # dim-1 => bytes of single element and dim-2 => over elements, just loop over exact
    # byte ranges within the provided buffer vector.
    nv = ntuple(length(K)) do ii
        elT = fieldtype(T, ii)
        off = fieldoffset(T, ii) % Int
        sub = view(buf, off .+ (1:sizeof(elT)))
        return _normalize_types(elT, sub)
    end
    return NamedTuple{K}(nv)
end
function _normalize_types(::Type{V}, buf::AbstractVector{UInt8}) where {T, V <: VariableArray{T}}
    va = _typed_load(V, buf)
    pbuf = unsafe_wrap(Array, convert(Ptr{UInt8}, va.p), (sizeof(T), Int(va.len)))
    if do_normalize(T)
        # If `T` a non-trivial type, recursively normalize the vlen buffer.
        return normalize_types(T, pbuf)
    else
        # Otherwise if `T` is simple type, directly reinterpret the vlen buffer.
        # (copy since libhdf5 will reclaim `pbuf = va.p` in `h5d_vlen_reclaim`)
        return copy(vec(reinterpret(T, pbuf)))
    end
end
function _normalize_types(::Type{F}, buf::AbstractVector{UInt8}) where {T, F <: FixedArray{T}}
    if do_normalize(T)
        # If `T` a non-trivial type, recursively normalize the buffer after reshaping to
        # matrix with dim-1 => bytes of single element and dim-2 => over elements.
        return reshape(normalize_types(T, reshape(buf, sizeof(T), :)), size(F)...)
    else
        # Otherwise, if `T` is simple type, directly reinterpret the array and reshape to
        # final dimensions. The copy ensures (a) the returned array is independent of
        # [potentially much larger] read() buffer, and (b) that the returned data is an
        # Array and not ReshapedArray of ReinterpretArray of SubArray of ...
        return copy(reshape(reinterpret(T, buf), size(F)...))
    end
end
_normalize_types(::Type{Cstring}, buf::AbstractVector{UInt8}) = unsafe_string(_typed_load(Ptr{UInt8}, buf))
_normalize_types(::Type{T}, buf::AbstractVector{UInt8}) where {T <: FixedString} = unpad(String(buf), pad(T))

do_normalize(::Type{T}) where {T} = false
do_normalize(::Type{NamedTuple{T,U}}) where {U,T} = any(i -> do_normalize(fieldtype(U,i)), 1:fieldcount(U))
do_normalize(::Type{T}) where {T <: Union{Cstring,FixedString,FixedArray,VariableArray}} = true

do_reclaim(::Type{T}) where {T} = false
do_reclaim(::Type{NamedTuple{T,U}}) where {U,T} = any(i -> do_reclaim(fieldtype(U,i)), 1:fieldcount(U))
do_reclaim(::Type{T}) where T <: Union{Cstring,VariableArray} = true

Base.read(attr::Attributes, name::AbstractString) = read_attribute(attr.parent, name)

function iscompact(obj::Dataset)
    prop = h5d_get_create_plist(checkvalid(obj))
    try
        h5p_get_layout(prop) == H5D_COMPACT
    finally
        h5p_close(prop)
    end
end

function ischunked(obj::Dataset)
    prop = h5d_get_create_plist(checkvalid(obj))
    try
        h5p_get_layout(prop) == H5D_CHUNKED
    finally
        h5p_close(prop)
    end
end

function iscontiguous(obj::Dataset)
    prop = h5d_get_create_plist(checkvalid(obj))
    try
        h5p_get_layout(prop) == H5D_CONTIGUOUS
    finally
        h5p_close(prop)
    end
end

# Reading with mmap
ismmappable(::Type{<:ScalarType}) = true
ismmappable(::Type) = false
ismmappable(obj::Dataset, ::Type{T}) where {T} = ismmappable(T) && iscontiguous(obj)
ismmappable(obj::Dataset) = ismmappable(obj, get_jl_type(obj))

function readmmap(obj::Dataset, ::Type{T}) where {T}
    dspace = dataspace(obj)
    stype = h5s_get_simple_extent_type(dspace)
    (stype != H5S_SIMPLE) && error("can only mmap simple dataspaces")
    dims = size(dspace)

    if isempty(dims)
        return T[]
    end
    if !Sys.iswindows()
        local fdint
        prop = h5d_get_access_plist(obj)
        try
            # TODO: Should check return value of h5f_get_driver()
            fdptr = h5f_get_vfd_handle(obj.file, prop)
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
        intent = h5f_get_intent(obj.file)
        flag = intent == H5F_ACC_RDONLY ? "r" : "r+"
        fd = open(obj.file.filename, flag)
    end

    offset = h5d_get_offset(obj)
    if offset % Base.datatype_alignment(T) == 0
        A = Mmap.mmap(fd, Array{T,length(dims)}, dims, offset)
    else
        Aflat = Mmap.mmap(fd, Vector{UInt8}, prod(dims)*sizeof(T), offset)
        A = reshape(reinterpret(T, Aflat), dims)
    end

    if Sys.iswindows()
        close(fd)
    end

    return A
end

function readmmap(obj::Dataset)
    T = get_jl_type(obj)
    ismmappable(T) || error("Cannot mmap datasets of type $T")
    iscontiguous(obj) || error("Cannot mmap discontiguous dataset")
    readmmap(obj, T)
end

# Generic write
function Base.write(parent::Union{File,Group}, name1::AbstractString, val1, name2::AbstractString, val2, nameval...) # FIXME: remove?
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
# The return syntax is: dset, dtype = create_dataset(parent, name, data; properties...)

function create_dataset(parent::Union{File,Group}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        create_dataset(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end
function create_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        create_attribute(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end

# Create and write, closing the objects upon exit
function write_dataset(parent::Union{File,Group}, name::AbstractString, data; pv...)
    obj, dtype = create_dataset(parent, name, data; pv...)
    try
        write_dataset(obj, dtype, data)
    catch exc
        delete_object(obj)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end
function write_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    obj, dtype = create_attribute(parent, name, data; pv...)
    try
        write_attribute(obj, dtype, data)
    catch exc
        delete_attribute(parent, name)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end

# Write to already-created objects
function Base.write(obj::Attribute, x)
    dtype = datatype(x)
    try
        write_attribute(obj, dtype, x)
    finally
        close(dtype)
    end
end
function Base.write(obj::Dataset, x)
    dtype = datatype(x)
    try
        write_dataset(obj, dtype, x)
    finally
        close(dtype)
    end
end

# For plain files and groups, let "write(obj, name, val; properties...)" mean "write_dataset"
Base.write(parent::Union{File,Group}, name::AbstractString, data; pv...) = write_dataset(parent, name, data; pv...)
# For datasets, "write(dset, name, val; properties...)" means "write_attribute"
Base.write(parent::Dataset, name::AbstractString, data; pv...) = write_attribute(parent, name, data; pv...)


# Indexing

Base.eachindex(::IndexLinear, A::Dataset) = Base.OneTo(length(A))
Base.axes(dset::Dataset) = map(Base.OneTo, size(dset))

# Write to a subset of a dataset using array slices: dataset[:,:,10] = array

const IndexType = Union{AbstractRange{Int},Int,Colon}
function Base.setindex!(dset::Dataset, X::Array{T}, I::IndexType...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    U = get_jl_type(dset)

    # perform conversions for numeric types
    if (U <: Number) && (T <: Number) && U !== T
        X = convert(Array{U}, X)
    end

    filetype = datatype(dset)
    memtype = Datatype(h5t_get_native_type(filetype))  # padded layout in memory
    close(filetype)

    elT = eltype(X)
    if sizeof(elT) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($elT) = $(sizeof(elT))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

    dspace = dataspace(dset)
    stype = h5s_get_simple_extent_type(dspace)
    stype == H5S_NULL && error("attempting to write to null dataspace")

    indices = Base.to_indices(dset, I)
    dspace = hyperslab(dspace, indices...)

    memspace = dataspace(X)

    if h5s_get_select_npoints(dspace) != h5s_get_select_npoints(memspace)
        error("number of elements in src and dest arrays must be equal")
    end

    try
        h5d_write(dset, memtype, memspace, dspace, dset.xfer, X)
    finally
        close(memtype)
        close(memspace)
        close(dspace)
    end

    return X
end

function Base.setindex!(dset::Dataset, x::T, I::IndexType...) where T <: Number
    indices = Base.to_indices(dset, I)
    X = fill(x, map(length, indices))
    Base.setindex!(dset, X, indices...)
end

function Base.setindex!(dset::Dataset, X::AbstractArray, I::IndexType...)
    Base.setindex!(dset, Array(X), I...)
end

function hyperslab(dspace::Dataspace, I::Union{AbstractRange{Int},Int}...)
    local dsel_id
    try
        dims = size(dspace)
        n_dims = length(dims)
        if length(I) != n_dims
            error("Wrong number of indices supplied, supplied length $(length(I)) but expected $(n_dims).")
        end
        dsel_id = h5s_copy(dspace)
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
function create_external_dataset(parent::Union{File,Group}, name::AbstractString, filepath::AbstractString, t, sz::Dims, offset::Integer=0)
    checkvalid(parent)
    dcpl  = create_property(H5P_DATASET_CREATE)
    h5p_set_external(dcpl , filepath, offset, prod(sz)*sizeof(t)) # TODO: allow H5F_UNLIMITED
    create_dataset(parent, name, datatype(t), dataspace(sz); dcpl=dcpl)
end

function do_write_chunk(dataset::Dataset, offset, chunk_bytes::Vector{UInt8}, filter_mask=0)
    checkvalid(dataset)
    offs = collect(hsize_t, reverse(offset)) .- 1
    h5do_write_chunk(dataset, H5P_DEFAULT, UInt32(filter_mask), offs, length(chunk_bytes), chunk_bytes)
end

struct ChunkStorage
    dataset::Dataset
end

function Base.setindex!(chunk_storage::ChunkStorage, v::Tuple{<:Integer,Vector{UInt8}}, index::Integer...)
    do_write_chunk(chunk_storage.dataset, hsize_t.(index), v[2], UInt32(v[1]))
end

# end of high-level interface


include("api_midlevel.jl")


### HDF5 utilities ###

function get_jl_type(obj_type::Datatype)
    class_id = h5t_get_class(obj_type)
    if class_id == H5T_OPAQUE
        return Opaque
    else
        return get_mem_compatible_jl_type(obj_type)
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

function get_mem_compatible_jl_type(obj_type::Datatype)
    class_id = h5t_get_class(obj_type)
    if class_id == H5T_STRING
        if h5t_is_variable_str(obj_type)
            return Cstring
        else
            N = sizeof(obj_type)
            PAD = h5t_get_strpad(obj_type)
            return FixedString{N,PAD}
        end
    elseif class_id == H5T_INTEGER || class_id == H5T_FLOAT
        native_type = h5t_get_native_type(obj_type)
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
        super_type = h5t_get_super(obj_type)
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
    elseif class_id == H5T_OPAQUE
        # TODO: opaque objects should get their own fixed-size data type; punning like
        #       this permits recursively reading (i.e. compound data type containing an
        #       opaque field). Requires figuring out what to do about the tag...
        len = Int(h5t_get_size(obj_type))
        return FixedArray{UInt8, (len,), len}
    elseif class_id == H5T_VLEN
        superid = h5t_get_super(obj_type)
        return VariableArray{get_mem_compatible_jl_type(Datatype(superid))}
    elseif class_id == H5T_COMPOUND
        N = h5t_get_nmembers(obj_type)

        membernames = ntuple(N) do i
            h5t_get_member_name(obj_type, i-1)
        end

        membertypes = ntuple(N) do i
            dtype = Datatype(h5t_get_member_type(obj_type, i-1))
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
        dims = h5t_get_array_dims(obj_type)
        nd = length(dims)
        eltyp = Datatype(h5t_get_super(obj_type))
        elT = get_mem_compatible_jl_type(eltyp)
        dimsizes = ntuple(i -> Int(dims[nd-i+1]), nd)  # reverse order
        return FixedArray{elT, dimsizes, prod(dimsizes)}
    end
    error("Class id ", class_id, " is not yet supported")
end

# default behavior
read_attribute(attr::Attribute, memtype::Datatype, buf) = h5a_read(attr, memtype, buf)
write_attribute(attr::Attribute, memtype::Datatype, x) = h5a_write(attr, memtype, x)
read_dataset(dset::Dataset, memtype::Datatype, buf, xfer::Properties=dset.xfer) =
    h5d_read(dset, memtype, H5S_ALL, H5S_ALL, xfer, buf)
write_dataset(dset::Dataset, memtype::Datatype, x, xfer::Properties=dset.xfer) =
    h5d_write(dset, memtype, H5S_ALL, H5S_ALL, xfer, x)

# type-specific behaviors
function write_attribute(attr::Attribute, memtype::Datatype, str::AbstractString)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        buf = Base.unsafe_convert(Ptr{UInt8}, strbuf)
        h5a_write(attr, memtype, buf)
    end
end
function write_attribute(attr::Attribute, memtype::Datatype, x::T) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    h5a_write(attr, memtype, tmp)
end
function write_attribute(attr::Attribute, memtype::Datatype, strs::Array{<:AbstractString})
    p = Ref{Cstring}(strs)
    h5a_write(attr, memtype, p)
end
write_attribute(attr::Attribute, memtype::Datatype, ::EmptyArray) = nothing

function read_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::Properties=dataset.xfer)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot read arrays with a different stride than `Array`"))
    h5d_read(dataset, memtype, H5S_ALL, H5S_ALL, xfer, buf)
end

function write_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::Properties=dataset.xfer)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    h5d_write(dataset, memtype, H5S_ALL, H5S_ALL, xfer, buf)
end
function write_dataset(dataset::Dataset, memtype::Datatype, str::AbstractString, xfer::Properties=dataset.xfer)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        # unsafe_convert(Cstring, strbuf) is responsible for enforcing the no-'\0' policy,
        # but then need explicit convert to Ptr{UInt8} since Ptr{Cstring} -> Ptr{Cvoid} is
        # not automatic.
        buf = convert(Ptr{UInt8}, Base.unsafe_convert(Cstring, strbuf))
        h5d_write(dataset, memtype, H5S_ALL, H5S_ALL, xfer, buf)
    end
end
function write_dataset(dataset::Dataset, memtype::Datatype, x::T, xfer::Properties=dataset.xfer) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    h5d_write(dataset, memtype, H5S_ALL, H5S_ALL, xfer, tmp)
end
function write_dataset(dataset::Dataset, memtype::Datatype, strs::Array{<:AbstractString}, xfer::Properties=dataset.xfer)
    p = Ref{Cstring}(strs)
    h5d_write(dataset, memtype, H5S_ALL, H5S_ALL, xfer, p)
end
write_dataset(dataset::Dataset, memtype::Datatype, ::EmptyArray, xfer::Properties=dataset.xfer) = nothing

#h5s_get_simple_extent_ndims(space_id::hid_t) = h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)
h5t_get_native_type(type_id) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)


# Functions that require special handling

const libversion = h5_get_libversion()

vlen_get_buf_size(dset::Dataset, dtype::Datatype, dspace::Dataspace) = h5d_vlen_get_buf_size(dset, dtype, dspace)

### Property manipulation ###
get_access_properties(d::Dataset)   = Properties(h5d_get_access_plist(d), H5P_DATASET_ACCESS)
get_access_properties(f::File)      = Properties(h5f_get_access_plist(f), H5P_FILE_ACCESS)
get_create_properties(d::Dataset)   = Properties(h5d_get_create_plist(d), H5P_DATASET_CREATE)
get_create_properties(g::Group)     = Properties(h5g_get_create_plist(g), H5P_GROUP_CREATE)
get_create_properties(f::File)      = Properties(h5f_get_create_plist(f), H5P_FILE_CREATE)
get_create_properties(a::Attribute) = Properties(h5a_get_create_plist(a), H5P_ATTRIBUTE_CREATE)

get_chunk(p::Properties) = tuple(convert(Vector{Int}, reverse(h5p_get_chunk(p)))...)
set_chunk(p::Properties, dims...) = h5p_set_chunk(p, length(dims), hsize_t[reverse(dims)...])
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

get_alignment(p::Properties)     = h5p_get_alignment(checkvalid(p))
get_alloc_time(p::Properties)    = h5p_get_alloc_time(checkvalid(p))
get_userblock(p::Properties)     = h5p_get_userblock(checkvalid(p))
get_fclose_degree(p::Properties) = h5p_get_fclose_degree(checkvalid(p))
get_libver_bounds(p::Properties) = h5p_get_libver_bounds(checkvalid(p))

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
    h5l_create_external(target_filename, target_path, source, source_relpath, lcpl_id, lapl_id)
    nothing
end

# Across initializations of the library, the id of various properties
# will change. So don't hard-code the id (important for precompilation)
const UTF8_LINK_PROPERTIES = Ref{Properties}()
_link_properties(::AbstractString) = UTF8_LINK_PROPERTIES[]
const UTF8_ATTRIBUTE_PROPERTIES = Ref{Properties}()
_attr_properties(::AbstractString) = UTF8_ATTRIBUTE_PROPERTIES[]
const ASCII_LINK_PROPERTIES = Ref{Properties}()
const ASCII_ATTRIBUTE_PROPERTIES = Ref{Properties}()

const DEFAULT_PROPERTIES = Properties()

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

    ASCII_LINK_PROPERTIES[] = create_property(H5P_LINK_CREATE; char_encoding = H5T_CSET_ASCII,
                                       create_intermediate_group = 1)
    UTF8_LINK_PROPERTIES[]  = create_property(H5P_LINK_CREATE; char_encoding = H5T_CSET_UTF8,
                                       create_intermediate_group = 1)
    ASCII_ATTRIBUTE_PROPERTIES[] = create_property(H5P_ATTRIBUTE_CREATE; char_encoding = H5T_CSET_ASCII)
    UTF8_ATTRIBUTE_PROPERTIES[]  = create_property(H5P_ATTRIBUTE_CREATE; char_encoding = H5T_CSET_UTF8)

    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" @eval include("mpio.jl")

    return nothing
end

include("deprecated.jl")

end  # module
