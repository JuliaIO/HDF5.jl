###############################################
## Reading and writing Julia data .jld files ##
###############################################

module JLD
using HDF5
# Add methods to...
import HDF5: close, dump, exists, file, getindex, setindex!, g_create, g_open, o_delete, name, names, read, size, write,
             HDF5ReferenceObj, HDF5BitsKind, ismmappable, readmmap
import Base: length, endof, show, done, next, start, delete!

# .jld files written before v"0.4.0-dev+1419" might have Uint32 instead of UInt32 as the typename string.
# See julia issue #8907
if VERSION >= v"0.4.0-dev+1419"
    julia_type(s::String) = _julia_type(replace(s, r"Uint(?=\d{1,3})", "UInt"))
else
    julia_type(s::String) = _julia_type(s)
end


const magic_base = "Julia data file (HDF5), version "
const version_current = v"0.1"
const pathrefs = "/_refs"
const pathtypes = "/_types"
const pathrequire = "/_require"
const name_type_attr = "julia type"

typealias BitsKindOrByteString Union(HDF5BitsKind, ByteString)

### Dummy types used for converting attribute strings to Julia types
type UnsupportedType; end
type UnconvertedType; end
type CompositeKind; end   # here this means "a type with fields"


immutable JldDatatype
    dtype::HDF5Datatype
    index::Int
end

immutable JldWriteSession
    persist::Vector{Any} # To hold objects that should not be garbage-collected
    h5ref::ObjectIdDict  # To hold mapping from Object/Array -> HDF5ReferenceObject

    JldWriteSession() = new(Any[], ObjectIdDict())
end

# The Julia Data file type
# Purpose of the nrefs field:
# length(group) only returns the number of _completed_ items in a group. Since
# we'll write recursively, we need to keep track of the number of reference
# objects _started_.
type JldFile <: HDF5.DataFile
    plain::HDF5File
    version::VersionNumber
    toclose::Bool
    writeheader::Bool
    mmaparrays::Bool
    compress::Bool
    h5jltype::Dict{Int,Type}
    jlh5type::Dict{Type,JldDatatype}
    jlref::Dict{HDF5ReferenceObj,WeakRef}
    truncatemodules::Vector{ByteString}
    gref # Group references; can't annotate type here due to circularity
    nrefs::Int

    function JldFile(plain::HDF5File, version::VersionNumber=version_current, toclose::Bool=true,
                     writeheader::Bool=false, mmaparrays::Bool=false,
                     compress::Bool=false)
        f = new(plain, version, toclose, writeheader, mmaparrays, compress,
                Dict{HDF5Datatype,Type}(), Dict{Type,HDF5Datatype}(),
                Dict{HDF5ReferenceObj,WeakRef}(), ByteString[])
        if toclose
            finalizer(f, close)
        end
        f
    end
end

immutable JldGroup
    plain::HDF5Group
    file::JldFile
end

immutable JldDataset
    plain::HDF5Dataset
    file::JldFile
end

iscompressed(f::JldFile) = f.compress
iscompressed(g::JldGroup) = g.file.compress
iscompressed(d::JldGroup) = d.file.compress

immutable PointerException <: Exception; end
show(io::IO, ::PointerException) = print(io, "cannot write a pointer to JLD file")

immutable TypeMismatchException <: Exception
    typename::ByteString
end
show(io::IO, e::TypeMismatchException) =
    print(io, "stored type $(e.typename) does not match currently loaded type")

# Wrapper for associative keys
# We write this instead of the associative to avoid dependence on the
# Julia hash function
immutable AssociativeWrapper{K,V,T<:Associative}
    keys::Vector{K}
    values::Vector{V}
end

include("jld_types.jl")

file(x::JldFile) = x
file(x::Union(JldGroup, JldDataset)) = x.file

function close(f::JldFile)
    if f.toclose
        close(f.plain)
        if f.writeheader
            magic = zeros(Uint8, 512)
            tmp = string(magic_base, f.version)
            magic[1:length(tmp)] = tmp.data
            rawfid = open(f.plain.filename, "r+")
            write(rawfid, magic)
            close(rawfid)
        end
        f.toclose = false
    end
    nothing
end
close(g::Union(JldGroup, JldDataset)) = close(g.plain)
show(io::IO, fid::JldFile) = isvalid(fid.plain) ? print(io, "Julia data file version ", fid.version, ": ", fid.plain.filename) : print(io, "Julia data file (closed): ", fid.plain.filename)

function jldopen(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool; mmaparrays::Bool=false, compress::Bool=false)
    local fj
    if ff && !wr
        error("Cannot append to a write-only file")
    end
    if !cr && !isfile(filename)
        error("File ", filename, " cannot be found")
    end
    version = version_current
    pa = p_create(HDF5.H5P_FILE_ACCESS)
    # HDF5.h5p_set_libver_bounds(pa, HDF5.H5F_LIBVER_18, HDF5.H5F_LIBVER_18)
    try
        pa["fclose_degree"] = HDF5.H5F_CLOSE_STRONG
        if cr && (tr || !isfile(filename))
            # We're truncating, so we don't have to check the format of an existing file
            # Set the user block to 512 bytes, to save room for the header
            p = p_create(HDF5.H5P_FILE_CREATE)
            local f
            try
                p["userblock"] = 512
                f = HDF5.h5f_create(filename, HDF5.H5F_ACC_TRUNC, p.id, pa.id)
            finally
                close(p)
            end
            fj = JldFile(HDF5File(f, filename), version, true, true, mmaparrays, compress)
            # initialize empty require list
            write(fj, pathrequire, ByteString[])
        else
            # Test whether this is a jld file
            sz = filesize(filename)
            if sz < 512
                error("File size indicates $filename cannot be a Julia data file")
            end
            magic = Array(Uint8, 512)
            rawfid = open(filename, "r")
            try
                magic = read!(rawfid, magic)
            finally
                close(rawfid)
            end
            if beginswith(magic, magic_base.data)
                version = convert(VersionNumber, bytestring(convert(Ptr{Uint8}, magic) + length(magic_base)))
                if version < v"0.1.0"
                    if !isdefined(JLD, :JLD00)
                        eval(:(include(joinpath($(dirname(@__FILE__)), "JLD00.jl"))))
                    end
                    fj = JLD00.jldopen(filename, rd, wr, cr, tr, ff; mmaparrays=mmaparrays)
                else
                    f = HDF5.h5f_open(filename, wr ? HDF5.H5F_ACC_RDWR : HDF5.H5F_ACC_RDONLY, pa.id)
                    fj = JldFile(HDF5File(f, filename), version, true, true, mmaparrays, compress)
                    # Load any required files/packages
                    if exists(fj, pathrequire)
                        r = read(fj, pathrequire)
                        for fn in r
                            require(fn)
                        end
                    end
                end
            else
                if ishdf5(filename)
                    println("$filename is an HDF5 file, but it is not a recognized Julia data file. Opening anyway.")
                    fj = JldFile(h5open(filename, rd, wr, cr, tr, ff), version_current, true, false, mmaparrays, compress)
                else
                    error("$filename does not seem to be a Julia data or HDF5 file")
                end
            end
        end
    finally
        close(pa)
    end
    return fj
end

function jldopen(fname::String, mode::String="r"; mmaparrays::Bool=false, compress::Bool=false)
    mode == "r"  ? jldopen(fname, true , false, false, false, false, mmaparrays=mmaparrays, compress=compress) :
    mode == "r+" ? jldopen(fname, true , true , false, false, false, mmaparrays=mmaparrays, compress=compress) :
    mode == "w"  ? jldopen(fname, false, true , true , true , false, mmaparrays=mmaparrays, compress=compress) :
#     mode == "w+" ? jldopen(fname, true , true , true , true , false) :
#     mode == "a"  ? jldopen(fname, false, true , true , false, true ) :
#     mode == "a+" ? jldopen(fname, true , true , true , false, true ) :
    error("invalid open mode: ", mode)
end

function jldopen(f::Function, args...; kws...)
    jld = jldopen(args...; kws...)
    try
        f(jld)
    finally
        close(jld)
    end
end

function jldobject(obj_id::HDF5.Hid, parent)
    obj_type = HDF5.h5i_get_type(obj_id)
    obj_type == HDF5.H5I_GROUP ? JldGroup(HDF5Group(obj_id, file(parent.plain)), file(parent)) :
    obj_type == HDF5.H5I_DATATYPE ? HDF5Datatype(obj_id) :
    obj_type == HDF5.H5I_DATASET ? JldDataset(HDF5Dataset(obj_id, file(parent.plain)), file(parent)) :
    error("Invalid object type for path ", path)
end

getindex(parent::Union(JldFile, JldGroup), path::ByteString) =
    jldobject(HDF5.h5o_open(parent.plain.id, path), parent)

function getindex(parent::Union(JldFile, JldGroup, JldDataset), r::HDF5ReferenceObj)
    if r == HDF5.HDF5ReferenceObj_NULL; error("Reference is null"); end
    obj_id = HDF5.h5r_dereference(parent.plain.id, HDF5.H5R_OBJECT, r)
    jldobject(obj_id, parent)
end

### "Inherited" behaviors
g_create(parent::Union(JldFile, JldGroup), args...) = JldGroup(g_create(parent.plain, args...), file(parent))
function g_create(f::Function, parent::Union(JldFile, JldGroup), args...)
    g = JldGroup(g_create(parent.plain, args...), file(parent))
    try
        f(g)
    finally
        close(g)
    end
end
g_open(parent::Union(JldFile, JldGroup), args...) = JldGroup(g_open(parent.plain, args...), file(parent))
name(p::Union(JldFile, JldGroup, JldDataset)) = name(p.plain)
exists(p::Union(JldFile, JldGroup, JldDataset), path::ByteString) = exists(p.plain, path)
root(p::Union(JldFile, JldGroup, JldDataset)) = g_open(file(p), "/")
o_delete(parent::Union(JldFile, JldGroup), args...) = o_delete(parent.plain, args...)
function ensurepathsafe(path::ByteString)
    if any([beginswith(path, s) for s in (pathrefs,pathtypes,pathrequire)]) 
        error("$name is internal to the JLD format, use o_delete if you really want to delete it") 
    end
end
function delete!(o::JldDataset)
    fullpath = name(o)
    ensurepathsafe(fullpath)
    o_delete(o.file, fullpath)
    refspath = joinpath(pathrefs, fullpath[2:end])
    exists(o.file, refspath) && o_delete(o.file, refspath)
end
function delete!(g::JldGroup)
    fullpath = name(g)
    ensurepathsafe(fullpath)
    for o in g typeof(o) == JldDataset && delete!(o) end
    o_delete(g.file,name(g))
end
function delete!(parent::Union(JldFile, JldGroup), path::ByteString)
    exists(parent, path) || error("$path does not exist in $parent")
    delete!(parent[path])
end
delete!(parent::Union(JldFile, JldGroup), args::(ByteString...)) = for a in args delete!(parent,a) end
ismmappable(obj::JldDataset) = ismmappable(obj.plain)
readmmap(obj::JldDataset, args...) = readmmap(obj.plain, args...)
setindex!(parent::Union(JldFile, JldGroup), val, path::ASCIIString) = write(parent, path, val)

start(parent::Union(JldFile, JldGroup)) = (names(parent), 1)
done(parent::Union(JldFile, JldGroup), state) = state[2] > length(state[1])
next(parent::Union(JldFile, JldGroup), state) = parent[state[1][state[2]]], (state[1], state[2]+1)


### Julia data file format implementation ###


### Read ###

function read(parent::Union(JldFile, JldGroup), name::ByteString)
    local val
    obj = parent[name]
    try
        val = read(obj)
    finally
        close(obj)
    end
    val
end
read(parent::Union(JldFile,JldGroup), name::Symbol) = read(parent,bytestring(string(name)))

function read(obj::JldDataset)
    dtype = datatype(obj.plain)
    dspace_id = HDF5.h5d_get_space(obj.plain)
    extent_type = HDF5.h5s_get_simple_extent_type(dspace_id)
    try
        if extent_type == HDF5.H5S_SCALAR
            # Scalar value
            return read_scalar(obj, dtype, jldatatype(file(obj), dtype))
        elseif extent_type == HDF5.H5S_SIMPLE
            return read_array(obj, dtype, dspace_id, HDF5.H5S_ALL)
        elseif extent_type == HDF5.H5S_NULL
            # Empty array
            if HDF5.h5t_get_class(dtype) == HDF5.H5T_REFERENCE
                T = refarray_eltype(obj)
            else
                T = jldatatype(file(obj), dtype)
            end
            if exists(obj, "dims")
                dims = a_read(obj.plain, "dims")
                return Array(T, dims...)
            else
                return T[]
            end
        end
    finally
        HDF5.h5s_close(dspace_id)
    end
end

## Scalars
read_scalar{T<:BitsKindOrByteString}(obj::JldDataset, dtype::HDF5Datatype, ::Type{T}) =
    read(obj.plain, T)
function read_scalar(obj::JldDataset, dtype::HDF5Datatype, T::Type)
    buf = Array(Uint8, sizeof(dtype))
    HDF5.readarray(obj.plain, dtype.id, buf)
    return after_read(jlconvert(T, file(obj), pointer(buf)))
end

after_read(x) = x

# Special case for associative, to rehash keys
function after_read{K,V,T}(x::AssociativeWrapper{K,V,T})
    ret = T()
    keys = x.keys
    values = x.values
    n = length(keys)
    if applicable(sizehint, ret, n)
        sizehint(ret, n)
    end
    for i = 1:n
        ret[keys[i]] = values[i]
    end
    ret
end

## Arrays

# Read an array
function read_array(obj::JldDataset, dtype::HDF5Datatype, dspace_id::HDF5.Hid, dsel_id::HDF5.Hid,
                    dims::(Int...)=convert((Int...), HDF5.h5s_get_simple_extent_dims(dspace_id)[1]))
    if HDF5.h5t_get_class(dtype) == HDF5.H5T_REFERENCE
        return read_refs(obj, refarray_eltype(obj), dspace_id, dsel_id, dims)
    else
        return read_vals(obj, dtype, jldatatype(file(obj), dtype), dspace_id, dsel_id, dims)
    end
end

# Arrays of basic HDF5 kinds
function read_vals{S<:HDF5BitsKind}(obj::JldDataset, dtype::HDF5Datatype, T::Union(Type{S}, Type{Complex{S}}),
                                    dspace_id::HDF5.Hid, dsel_id::HDF5.Hid, dims::(Int...))
    if obj.file.mmaparrays && HDF5.iscontiguous(obj.plain) && dsel_id == HDF5.H5S_ALL
        readmmap(obj.plain, Array{T})
    else
        out = Array(T, dims)
        HDF5.h5d_read(obj.plain.id, dtype.id, dspace_id, dsel_id, HDF5.H5P_DEFAULT, out)
        out
    end
end

# Arrays of immutables/bitstypes
function read_vals(obj::JldDataset, dtype::HDF5Datatype, T::Type, dspace_id::HDF5.Hid,
                   dsel_id::HDF5.Hid, dims::(Int...))
    n = prod(dims)
    h5sz = sizeof(dtype)
    out = Array(T, dims)

    # Read from file
    buf = Array(Uint8, h5sz*n)
    HDF5.h5d_read(obj.plain.id, dtype.id, dspace_id, dsel_id, HDF5.H5P_DEFAULT, buf)

    f = file(obj)
    h5offset = pointer(buf)
    if T.pointerfree && !T.mutable
        jloffset = pointer(out)
        jlsz = T.size

        # Perform conversion in buffer
        for i = 1:n
            jlconvert!(jloffset, T, f, h5offset)
            jloffset += jlsz
            h5offset += h5sz
        end
    else
        # Convert each item individually
        for i = 1:n
            out[i] = jlconvert(T, f, h5offset)
            h5offset += h5sz
        end
    end
    out
end

# Arrays of references
function read_refs{T}(obj::JldDataset, ::Type{T}, dspace_id::HDF5.Hid, dsel_id::HDF5.Hid,
                      dims::(Int...))
    refs = Array(HDF5ReferenceObj, dims)
    HDF5.h5d_read(obj.plain.id, HDF5.H5T_STD_REF_OBJ, dspace_id, dsel_id, HDF5.H5P_DEFAULT, refs)

    out = Array(T, dims)
    f = file(obj)
    for i = 1:length(refs)
        if refs[i] != HDF5.HDF5ReferenceObj_NULL
            out[i] = read_ref(f, refs[i])
        end
    end
    out
end

# Get element type of a reference array
function refarray_eltype(obj::JldDataset)
    typename = a_read(obj.plain, "julia eltype")
    T = julia_type(typename)
    if T == UnsupportedType
        warn("type $typename not present in workspace; interpreting array as Array{Any}")
        return Any
    end
    return T
end

## Reference
function read_ref(f::JldFile, ref::HDF5ReferenceObj)
    if haskey(f.jlref, ref)
        # Stored as WeakRefs and may no longer exist
        val = f.jlref[ref].value
        val != nothing && return val
    end

    dset = f[ref]
    data = try
        read(dset)
    finally
        close(dset)
    end

    f.jlref[ref] = WeakRef(data)
    data
end

### Writing ###

write(parent::Union(JldFile, JldGroup), name::ByteString,
      data, wsession::JldWriteSession=JldWriteSession()) =
    close(_write(parent, name, data, wsession))

# Pick whether to use compact or default storage based on data size
const COMPACT_PROPERTIES = p_create(HDF5.H5P_DATASET_CREATE)
HDF5.h5p_set_layout(COMPACT_PROPERTIES.id, HDF5.H5D_COMPACT)
function dset_create_properties(parent, sz::Int, obj)
    sz <= 8192 && return COMPACT_PROPERTIES
    if iscompressed(parent)
        chunk = HDF5.heuristic_chunk(obj)
        if !isempty(chunk)
            p = p_create(HDF5.H5P_DATASET_CREATE)
            p["chunk"] = chunk
            p["blosc"] = 5
            return p
        end
    end
    return HDF5.DEFAULT_PROPERTIES
end

# Write "basic" types
function _write{T<:Union(HDF5BitsKind, ByteString)}(parent::Union(JldFile, JldGroup),
                                                    name::ByteString,
                                                    data::Union(T, Array{T}),
                                                    wsession::JldWriteSession)
    dset, dtype = d_create(parent.plain, bytestring(name), data, HDF5._link_properties(name), dset_create_properties(parent, sizeof(data), data))
    try
        # Write the attribute
        isa(data, Array) && isempty(data) && a_write(dset, "dims", [size(data)...])
        # Write the data
        HDF5.writearray(dset, dtype.id, data)
    finally
        close(dtype)
    end
    dset
end

# General array types
function _write{T}(parent::Union(JldFile, JldGroup),
                   path::ByteString, data::Array{T},
                   wsession::JldWriteSession)
    f = file(parent)
    dtype = h5fieldtype(f, T, true)
    buf = h5convert_array(f, data, dtype, wsession)
    dims = convert(Array{HDF5.Hsize, 1}, [reverse(size(data))...])
    dspace = dataspace(data)
    try
        dset = d_create(parent.plain, path, dtype.dtype, dspace, HDF5._link_properties(path), dset_create_properties(parent, sizeof(buf), buf))
        if dtype == JLD_REF_TYPE
            a_write(dset, "julia eltype", full_typename(f, T))
        end
        if isempty(data) && ndims(data) != 1
            a_write(dset, "dims", [size(data)...])
        else
            HDF5.writearray(dset, dtype.dtype.id, buf)
        end
        return dset
    finally
        close(dspace)
    end
end

# Dispatch correct method for Array{Union()}
_write(parent::Union(JldFile, JldGroup), path::ByteString, data::Array{Union()},
       wsession::JldWriteSession) =
    invoke(_write, (Union(JldFile, JldGroup), ByteString, Array, JldWriteSession), parent,
           path, data, wsession)

# Convert an array to the format to be written to the HDF5 file, either
# references or values
function h5convert_array(f::JldFile, data::Array,
                         dtype::JldDatatype, wsession::JldWriteSession)
    if dtype == JLD_REF_TYPE
        refs = Array(HDF5ReferenceObj, length(data))
        for i = 1:length(data)
            if isdefined(data, i)
                refs[i] = write_ref(f, data[i], wsession)
            else
                refs[i] = HDF5.HDF5ReferenceObj_NULL
            end
        end
        reinterpret(Uint8, refs) # for type stability
    else
        gen_h5convert(f, eltype(data))
        h5convert_vals(f, data, dtype, wsession)
    end
end

# Hack to ensure that _h5convert_vals isn't compiled before h5convert!
function h5convert_vals(f::JldFile, data::ANY, dtype::JldDatatype,
                        wsession::JldWriteSession)
    for i = true; end # prevents inlining
    _h5convert_vals(f, data, dtype, wsession)
end

# Convert an array of immutables or bitstypes to a buffer representing
# HDF5 compound objects. A separate function so that it is specialized.
function _h5convert_vals(f::JldFile, data::Array,
                         dtype::JldDatatype, wsession::JldWriteSession)
    sz = HDF5.h5t_get_size(dtype)
    n = length(data)
    buf = Array(Uint8, sz*n)
    offset = pointer(buf)
    for i = 1:n
        h5convert!(offset, f, data[i], wsession)
        offset += sz
    end
    buf
end

# Get reference group, creating a new one if necessary
function get_gref(f::JldFile)
    isdefined(f, :gref) && return f.gref::JldGroup

    if !exists(f, pathrefs)
        gref = f.gref = g_create(f, pathrefs)
    else
        gref = f.gref = f[pathrefs]
    end
    f.nrefs = length(gref)
    gref
end

# Write a reference
function write_ref(parent::JldFile, data, wsession::JldWriteSession)
    # Check whether we have already written this object
    ref = get(wsession.h5ref, data, HDF5.HDF5ReferenceObj_NULL)
    ref != HDF5.HDF5ReferenceObj_NULL && return ref

    # Write an new reference
    gref = get_gref(parent)
    name = @sprintf "%08d" (parent.nrefs += 1)
    dset = _write(gref, name, data, wsession)

    # Add reference to reference list
    ref = HDF5ReferenceObj(HDF5.objinfo(dset).addr)
    close(dset)
    if !isa(data, Tuple) && typeof(data).mutable
        wsession.h5ref[data] = ref
    end
    ref
end
write_ref(parent::JldGroup, data, wsession::JldWriteSession) =
    write_ref(file(parent), data, wsession)

# Special case for associative, to rehash keys
function _write(parent::Union(JldFile, JldGroup), name::ByteString,
                d::Associative, wsession::JldWriteSession)
    n = length(d)
    K, V = eltype(d)
    ks = Array(K, n)
    vs = Array(V, n)
    i = 0
    for (k,v) in d
        ks[i+=1] = k
        vs[i] = v
    end
    write_compound(parent, name, AssociativeWrapper{K,V,typeof(d)}(ks, vs), wsession)
end

# Expressions, drop line numbers
function _write(parent::Union(JldFile, JldGroup),
                name::ByteString, ex::Expr,
                wsession::JldWriteSession)
    args = ex.args
    # Discard "line" expressions
    keep = trues(length(args))
    for i = 1:length(args)
        if isa(args[i], Expr) && args[i].head == :line
            keep[i] = false
        end
    end
    newex = Expr(ex.head)
    newex.args = args[keep]
    write_compound(parent, name, newex, wsession)
end

# Generic (tuples, immutables, and compound types)
_write(parent::Union(JldFile, JldGroup), name::ByteString, s,
      wsession::JldWriteSession) =
    write_compound(parent, name, s, wsession)
function write_compound(parent::Union(JldFile, JldGroup), name::ByteString,
                        s, wsession::JldWriteSession)
    T = typeof(s)
    f = file(parent)
    dtype = h5type(f, T, true)
    gen_h5convert(f, T)

    buf = Array(Uint8, HDF5.h5t_get_size(dtype))
    h5convert!(pointer(buf), file(parent), s, wsession)

    dspace = HDF5Dataspace(HDF5.h5s_create(HDF5.H5S_SCALAR))
    try
        dset = HDF5.d_create(parent.plain, name, dtype.dtype, dspace, HDF5._link_properties(name), dset_create_properties(parent, length(buf), buf))
        HDF5.writearray(dset, dtype.dtype.id, buf)
        return dset
    finally
        close(dspace)
    end
end

### Size, length, etc ###
size(dset::JldDataset) = size(dset.plain)
length(dset::JldDataset) = prod(size(dset))
endof(dset::JldDataset) = length(dset)

### Read/write via getindex/setindex! ###
function getindex(dset::JldDataset, indices::Union(Integer, RangeIndex)...)
    sz = map(length, indices)
    dsel_id = HDF5.hyperslab(dset.plain, indices...)
    try
        dspace = HDF5._dataspace(sz)
        try
            return read_array(dset, datatype(dset.plain), dspace.id, dsel_id, sz)
        finally
            close(dspace)
        end
    finally
        HDF5.h5s_close(dsel_id)
    end
end

function setindex!{T,N}(dset::JldDataset, X::AbstractArray{T,N}, indices::RangeIndex...)
    f = file(dset)
    sz = map(length, indices)
    dsel_id = HDF5.hyperslab(dset.plain, indices...)
    try
        dtype = datatype(dset.plain)
        try
            # Convert array to writeable buffer
            if HDF5.h5t_get_class(dtype) == HDF5.H5T_REFERENCE
                written_eltype = refarray_eltype(dset)
                jldtype = JLD_REF_TYPE
            else
                written_eltype = jldatatype(f, dtype)
                jldtype = JldDatatype(dtype, -1)
            end

            buf = h5convert_array(f, convert(Array{written_eltype,N}, X), jldtype,
                                  JldWriteSession())

            dspace = HDF5._dataspace(sz)
            try
                HDF5.h5d_write(dset.plain.id, dtype, dspace, dsel_id, HDF5.H5P_DEFAULT, buf)
            finally
                close(dspace)
            end
        finally
            close(dtype)
        end
    finally
        HDF5.h5s_close(dsel_id)
    end
end

length(x::Union(JldFile, JldGroup)) = length(names(x))

### Converting attribute strings to Julia types

is_valid_type_ex(s::Symbol) = true
is_valid_type_ex(s::QuoteNode) = true
is_valid_type_ex(x::Int) = true
is_valid_type_ex(e::Expr) = ((e.head == :curly || e.head == :tuple || e.head == :.) && all(map(is_valid_type_ex, e.args))) ||
                            (e.head == :call && (e.args[1] == :Union || e.args[1] == :TypeVar))

# Work around https://github.com/JuliaLang/julia/issues/8226
const _typedict = Dict{String,Type}()
_typedict["Core.Type{TypeVar(:T,Union(Core.Any,Core.Undef))}"] = Type

function _julia_type(s::String)
    typ = get(_typedict, s, UnconvertedType)
    if typ == UnconvertedType
        typ = julia_type(parse(s))
        if typ != UnsupportedType
            _typedict[s] = typ
        end
    end
    typ
end

function julia_type(e::Union(Symbol, Expr))
    if is_valid_type_ex(e)
        try     # try needed to catch undefined symbols
            typ = eval(Main, e)
            isa(typ, Type) && return typ
        end
    end
    return UnsupportedType
end

### Converting Julia types to fully qualified names
function full_typename(io::IO, file::JldFile, jltype::UnionType)
    print(io, "Union(")
    if !isempty(jltype.types)
        full_typename(io, file, jltype.types[1])
        for i = 2:length(jltype.types)
            print(io, ',')
            full_typename(io, file, jltype.types[i])
        end
    end
    print(io, ')')
end
function full_typename(io::IO, file::JldFile, tv::TypeVar)
    if is(tv.lb, None) && is(tv.ub, Any)
        print(io, "TypeVar(:", tv.name, ")")
    elseif is(tv.lb, None)
        print(io, "TypeVar(:", tv.name, ",")
        full_typename(io, file, tv.ub)
        print(io, ')')
    else
        print(io, "TypeVar(:")
        print(io, tv.name)
        print(io, ',')
        full_typename(io, file, tv.lb)
        print(io, ',')
        full_typename(io, file, tv.ub)
        print(io, ')')
    end
end
function full_typename(io::IO, file::JldFile, jltype::(Type...))
    print(io, '(')
    for t in jltype
        full_typename(io, file, t)
        print(io, ',')
    end
    print(io, ')')
end
full_typename(io::IO, ::JldFile, x) = print(io, x)
function full_typename(io::IO, file::JldFile, jltype::DataType)
    mod = jltype.name.module
    if mod != Main
        mname = string(mod)
        for x in file.truncatemodules
            if beginswith(mname, x)
                mname = length(x) == length(mname) ? "" : mname[sizeof(x)+1:end]
                break
            end
        end

        if !isempty(mname)
            print(io, mname)
            print(io, '.')
        end
    end

    print(io, jltype.name.name)
    if !isempty(jltype.parameters)
        print(io, '{')
        full_typename(io, file, jltype.parameters[1])
        for i = 2:length(jltype.parameters)
            print(io, ',')
            full_typename(io, file, jltype.parameters[i])
        end
        print(io, '}')
    end
end
function full_typename(file::JldFile, x)
    io = IOBuffer(Array(Uint8, 64), true, true)
    truncate(io, 0)
    full_typename(io, file, x)
    takebuf_string(io)
end

function truncate_module_path(file::JldFile, mod::Module)
    push!(file.truncatemodules, string(mod))
end

function names(parent::Union(JldFile, JldGroup))
    n = names(parent.plain)
    keep = trues(length(n))
    const reserved = [pathrefs[2:end], pathtypes[2:end], pathrequire[2:end]]
    for i = 1:length(n)
        if in(n[i], reserved)
            keep[i] = false
        end
    end
    n[keep]
end

function save_write(f, s, vname, wsession::JldWriteSession)
    if !isa(vname, Function)
        try
            write(f, s, vname)
        catch e
            if isa(e, PointerException)
                warn("Skipping $vname because it contains a pointer")
            end
        end
    end
end

macro save(filename, vars...)
    if isempty(vars)
        # Save all variables in the current module
        writeexprs = Array(Expr, 0)
        m = current_module()
        for vname in names(m)
            s = string(vname)
            if !ismatch(r"^_+[0-9]*$", s) # skip IJulia history vars
                v = eval(m, vname)
                if !isa(v, Module)
                    push!(writeexprs, :(save_write(f, $s, $(esc(vname)), wsession)))
                end
            end
        end
    else
        writeexprs = Array(Expr, length(vars))
        for i = 1:length(vars)
            writeexprs[i] = :(write(f, $(string(vars[i])), $(esc(vars[i])), wsession))
        end
    end

    quote
        local f = jldopen($(esc(filename)), "w")
        wsession = JldWriteSession()
        try
            $(Expr(:block, writeexprs...))
        finally
            close(f)
        end
    end
end

macro load(filename, vars...)
    if isempty(vars)
        if isa(filename, Expr)
            filename = eval(current_module(), filename)
        end
        # Load all variables in the top level of the file
        readexprs = Array(Expr, 0)
        vars = Array(Expr, 0)
        f = jldopen(filename)
        nms = names(f)
        for n in nms
            obj = f[n]
            if isa(obj, JldDataset)
                sym = esc(symbol(n))
                push!(readexprs, :($sym = read($f, $n)))
                push!(vars, sym)
            end
        end
        return Expr(:block, 
                    Expr(:global, vars...),
                    Expr(:try,  Expr(:block, readexprs...), false, false,
                         :(close($f))),
                    Symbol[v.args[1] for v in vars]) # "unescape" vars
    else
        readexprs = Array(Expr, length(vars))
        for i = 1:length(vars)
            readexprs[i] = :($(esc(vars[i])) = read(f, $(string(vars[i]))))
        end
        return Expr(:block, 
                    Expr(:global, map(esc, vars)...),
                    :(local f = jldopen($(esc(filename)))),
                    Expr(:try,  Expr(:block, readexprs...), false, false,
                         :(close(f))),
                    Symbol[v for v in vars]) # vars is a tuple
    end
end

# Save all the key-value pairs in the dict as top-level variables of the JLD
function save(filename::String, dict::Associative; compress::Bool=false)
    jldopen(filename, "w"; compress=compress) do file
        wsession = JldWriteSession()
        for (k,v) in dict
            write(file, bytestring(k), v, wsession)
        end
    end
end
# Or the names and values may be specified as alternating pairs
function save(filename::String, name::String, value, pairs...; compress::Bool=false)
    if isodd(length(pairs)) || !isa(pairs[1:2:end], (String...)) 
        throw(ArgumentError("arguments must be in name-value pairs"))
    end
    jldopen(filename, "w"; compress=compress) do file
        wsession = JldWriteSession()
        write(file, bytestring(name), value, wsession)
        for i=1:2:length(pairs)
            write(file, bytestring(pairs[i]), pairs[i+1], wsession)
        end
    end
end

# load with just a filename returns a dictionary containing all the variables
function load(filename::String)
    jldopen(filename, "r") do file
        (ByteString => Any)[var => read(file, var) for var in names(file)]
    end
end
# When called with explicitly requested variable names, return each one
function load(filename::String, varname::String)
    jldopen(filename, "r") do file
        read(file, varname)
    end
end
load(filename::String, varnames::String...) = load(filename, varnames)
function load(filename::String, varnames::(String...))
    jldopen(filename, "r") do file
        map((var)->read(file, var), varnames)
    end
end

function addrequire(file::JldFile, filename::String)
    files = read(file, pathrequire)
    push!(files, filename)
    o_delete(file, pathrequire)
    write(file, pathrequire, files)
end

export
    addrequire,
    ismmappable,
    jldopen,
    o_delete,
    plain,
    readmmap,
    readsafely,
    @load,
    @save,
    load,
    save,
    truncate_module_path

end
