####################
## HDF5 interface ##
####################

module HDF5Mod
import Base.*

## C types

typealias C_int Int32
typealias C_unsigned Uint32
typealias C_char Uint8
typealias C_unsigned_long_long Uint64
typealias C_size_t Uint64

## HDF5 types and constants

typealias Hid         C_int
typealias Herr        C_int
typealias Hssize      C_int
typealias Hsize       C_size_t
typealias Htri        C_int   # pseudo-boolean (negative if error)
typealias Hiter_order C_int
typealias Hindex      C_int
typealias Htype       C_int
typealias Hclass      C_int
typealias Hsign       C_int
typealias Hdirection  C_int
typealias Hseloper    C_int

### Load and initialize the HDF library ###
const libhdf5 = dlopen("libhdf5")
status = ccall(dlsym(libhdf5, :H5open), Herr, ())
if status < 0
    error("Can't initialize the HDF5 library")
end

# Function to extract exported library constants
# Kudos to the library developers for making these available this way!
read_const(sym::Symbol) = unsafe_ref(convert(Ptr{C_int}, dlsym(libhdf5, sym)))

# dataset constants
const H5D_COMPACT      = 0
const H5D_CONTIGUOUS   = 1
const H5D_CHUNKED      = 2
# error-related constants
const H5E_DEFAULT      = 0
# file access modes
const H5F_ACC_RDONLY   = 0x00
const H5F_ACC_RDWR     = 0x01
const H5F_ACC_TRUNC    = 0x02
const H5F_ACC_EXCL     = 0x04
const H5F_ACC_DEBUG    = 0x08
const H5F_ACC_CREAT    = 0x10
# other file constants
const H5F_SCOPE_LOCAL  = 0
const H5F_SCOPE_GLOBAL = 1
# object types (C enum H5Itype_t)
const H5I_FILE         = 1
const H5I_GROUP        = 2
const H5I_DATATYPE     = 3
const H5I_DATASPACE    = 4
const H5I_DATASET      = 5
const H5I_ATTR         = 6
const H5I_REFERENCE    = 7
# Property constants
const H5P_DEFAULT      = 0
const H5P_DATASET_CREATE = read_const(:H5P_CLS_DATASET_CREATE_g)
# Dataspace constants
const H5S_ALL          = 0
const H5S_SCALAR       = 0
# Dataspace selection constants
const H5S_SELECT_SET   = 0
const H5S_SELECT_OR    = 1
const H5S_SELECT_AND   = 2
const H5S_SELECT_XOR   = 3
const H5S_SELECT_NOTB  = 4
const H5S_SELECT_NOTA  = 5
const H5S_SELECT_APPEND = 6
const H5S_SELECT_PREPEND = 7
# type classes (C enum H5T_class_t)
const H5T_INTEGER      = 0
const H5T_FLOAT        = 1
const H5T_TIME         = 2  # not supported by HDF5 library
const H5T_STRING       = 3
const H5T_BITFIELD     = 4
const H5T_OPAQUE       = 5
const H5T_COMPOUND     = 6
const H5T_REFERENCE    = 7
const H5T_ENUM         = 8
const H5T_VLEN         = 9
const H5T_ARRAY        = 10
# Sign types (C enum H5T_sign_t)
const H5T_SGN_NONE     = 0  # unsigned
const H5T_SGN_2        = 1  # 2's complement
# Search directions
const H5T_DIR_ASCEND   = 1
const H5T_DIR_DESCEND  = 2
# Type_id constants (LE = little endian, I16 = Int16, etc)
const H5T_STD_I8LE     = read_const(:H5T_STD_I8LE_g)
const H5T_STD_I8BE     = read_const(:H5T_STD_I8BE_g)
const H5T_STD_U8LE     = read_const(:H5T_STD_U8LE_g)
const H5T_STD_U8BE     = read_const(:H5T_STD_U8BE_g)
const H5T_STD_I16LE    = read_const(:H5T_STD_I16LE_g)
const H5T_STD_I16BE    = read_const(:H5T_STD_I16BE_g)
const H5T_STD_U16LE    = read_const(:H5T_STD_U16LE_g)
const H5T_STD_U16BE    = read_const(:H5T_STD_U16BE_g)
const H5T_STD_I32LE    = read_const(:H5T_STD_I32LE_g)
const H5T_STD_I32BE    = read_const(:H5T_STD_I32BE_g)
const H5T_STD_U32LE    = read_const(:H5T_STD_U32LE_g)
const H5T_STD_U32BE    = read_const(:H5T_STD_U32BE_g)
const H5T_STD_I64LE    = read_const(:H5T_STD_I64LE_g)
const H5T_STD_I64BE    = read_const(:H5T_STD_I64BE_g)
const H5T_STD_U64LE    = read_const(:H5T_STD_U64LE_g)
const H5T_STD_U64BE    = read_const(:H5T_STD_U64BE_g)
const H5T_IEEE_F32LE   = read_const(:H5T_IEEE_F32LE_g)
const H5T_IEEE_F32BE   = read_const(:H5T_IEEE_F32BE_g)
const H5T_IEEE_F64LE   = read_const(:H5T_IEEE_F64LE_g)
const H5T_IEEE_F64BE   = read_const(:H5T_IEEE_F64BE_g)
const H5T_C_S1         = read_const(:H5T_C_S1_g)
# Native types
const H5T_NATIVE_INT8   = read_const(:H5T_NATIVE_INT8_g)
const H5T_NATIVE_UINT8  = read_const(:H5T_NATIVE_UINT8_g)
const H5T_NATIVE_INT16  = read_const(:H5T_NATIVE_INT16_g)
const H5T_NATIVE_UINT16 = read_const(:H5T_NATIVE_UINT16_g)
const H5T_NATIVE_INT32  = read_const(:H5T_NATIVE_INT32_g)
const H5T_NATIVE_UINT32 = read_const(:H5T_NATIVE_UINT32_g)
const H5T_NATIVE_INT64  = read_const(:H5T_NATIVE_INT64_g)
const H5T_NATIVE_UINT64 = read_const(:H5T_NATIVE_UINT64_g)
const H5T_NATIVE_FLOAT  = read_const(:H5T_NATIVE_FLOAT_g)
const H5T_NATIVE_DOUBLE = read_const(:H5T_NATIVE_DOUBLE_g)

hdf5_type_id(::Type{Int8})       = H5T_NATIVE_INT8
hdf5_type_id(::Type{Uint8})      = H5T_NATIVE_UINT8
hdf5_type_id(::Type{Int16})      = H5T_NATIVE_INT16
hdf5_type_id(::Type{Uint16})     = H5T_NATIVE_UINT16
hdf5_type_id(::Type{Int32})      = H5T_NATIVE_INT32
hdf5_type_id(::Type{Uint32})     = H5T_NATIVE_UINT32
hdf5_type_id(::Type{Int64})      = H5T_NATIVE_INT64
hdf5_type_id(::Type{Uint64})     = H5T_NATIVE_UINT64
hdf5_type_id(::Type{Float32})    = H5T_NATIVE_FLOAT
hdf5_type_id(::Type{Float64})    = H5T_NATIVE_DOUBLE
hdf5_type_id(::Type{ByteString}) = H5T_C_S1

typealias HDF5BitsKind Union(Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64, Float32, Float64)

## Julia types corresponding to the HDF5 base types
const hdf5_type_map = {
    (H5T_INTEGER, H5T_SGN_2, 1) => Int8,
    (H5T_INTEGER, H5T_SGN_2, 2) => Int16,
    (H5T_INTEGER, H5T_SGN_2, 4) => Int32,
    (H5T_INTEGER, H5T_SGN_2, 8) => Int64,
    (H5T_INTEGER, H5T_SGN_NONE, 1) => Uint8,
    (H5T_INTEGER, H5T_SGN_NONE, 2) => Uint16,
    (H5T_INTEGER, H5T_SGN_NONE, 4) => Uint32,
    (H5T_INTEGER, H5T_SGN_NONE, 8) => Uint64,
    (H5T_FLOAT, nothing, 4) => Float32,
    (H5T_FLOAT, nothing, 8) => Float64,
}

## HDF5 uses a plain integer to refer to each file, group, or
## dataset. These are wrapped into special types in order to allow
## method dispatch.

# Note re finalizers: we use them to ensure that objects passed back
# to the user will eventually be cleaned up properly. However, since
# finalizers don't run on a predictable schedule, we also call close
# directly on function exit. (This avoids certain problems, like those
# that occur when passing a freshly-created file to some other
# application). The "toclose" field in the types is there to prevent
# errors from calling close twice on the same object. It's also there
# to prevent errors in cases where the object shouldn't be closed at
# all (like calling hdf5_type_id on BitsKind, which does not open a
# new resource, or calling h5s_create with H5S_SCALAR).

abstract HDF5Object

type HDF5File <: HDF5Object
    id::Hid
    filename::String
    toclose::Bool

   function HDF5File(id, filename, toclose::Bool)
       f = new(id, filename, toclose)
       finalizer(f, close)
       f
   end
end
HDF5File(id, filename) = HDF5File(id, filename, true)
convert(::Type{C_int}, f::HDF5File) = f.id

type HDF5Group <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Group(id, toclose::Bool)
        g = new(id, toclose)
        finalizer(g, close)
        g
    end
end
HDF5Group(id) = HDF5Group(id, true)
convert(::Type{C_int}, g::HDF5Group) = g.id

type HDF5Dataset <: HDF5Object
    id::Hid
    toclose::Bool
    
    function HDF5Dataset(id, toclose::Bool)
        dset = new(id, toclose)
        finalizer(dset, close)
        dset
    end
end
HDF5Dataset(id) = HDF5Dataset(id, true)
convert(::Type{C_int}, dset::HDF5Dataset) = dset.id

type HDF5Type <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Type(id, toclose::Bool)
        nt = new(id)
        finalizer(nt, close)
        nt
    end
end
HDF5Type(id) = HDF5Type(id, true)
convert(::Type{C_int}, dtype::HDF5Type) = dtype.id

type HDF5Dataspace <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Dataspace(id, toclose::Bool)
        dspace = new(id, toclose)
        finalizer(dspace, close)
        dspace
    end
end
HDF5Dataspace(id) = HDF5Dataspace(id, true)
convert(::Type{C_int}, dspace::HDF5Dataspace) = dspace.id

type HDF5Properties <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Properties(id, toclose::Bool)
        p = new(id, toclose)
        finalizer(p, close)
        p
    end
end
HDF5Properties(id) = HDF5Properties(id, true)
HDF5Properties() = HDF5Properties(H5P_DEFAULT, false)
convert(::Type{C_int}, p::HDF5Properties) = p.id

### High-level interface ###
# Open or create an HDF5 file
function h5open(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool, finalize::Bool)
    if !rd
        error("HDF5 files have no write-only mode")
    end
    if cr && !rd
        error("Can't create a read-only HDF5 file")
    end
    if ff && !wr
        error("Cannot append to a read-only HDF5 file")
    end
    if !cr && !isfile(filename)
        error("File ", filename, " cannot be found")
    end
    if wr && cr && tr && !ff
        fid = h5f_create(filename)
    else
        fid = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY)
    end
    HDF5File(fid, filename, finalize)
end
h5open(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool) = h5open(filename, rd, wr, cr, tr, ff, true)

function h5open(filename::String, mode::String)
    mode == "r"  ? h5open(filename, true,  false, false, false, false) :
    mode == "r+" ? h5open(filename, true,  true , false, false, true)  :
    mode == "w"  ? h5open(filename, true,  true , true , true, false)  :
    mode == "w+" ? h5open(filename, true,  true , true , true, false)  :
    mode == "a"  ? h5open(filename, true,  true , true , true, true)   :
    error("invalid open mode: ", mode)
end

h5open(filename::String) = h5open(filename, true, false, false, false, false)

# Close a file
function close(file::HDF5File)
    if file.toclose
        h5f_close(file.id)
        file.toclose = false
    end
    nothing
end

# Close a group, dataset or datatype
function close(object::Union(HDF5Group, HDF5Dataset, HDF5Type))
    if object.toclose
        h5o_close(object.id)
        object.toclose = false
    end
    nothing
end

# Close a dataspace
function close(dspace::HDF5Dataspace)
    if dspace.toclose
        h5s_close(dspace.id)
        dspace.toclose = false
    end
    nothing
end

# Close an attribute
# Close a property list
function close(p::HDF5Properties)
    if p.toclose
        h5p_close(p.id)
        p.toclose = false
    end
    nothing
end

# Access an object
function ref(parent::Union(HDF5File, HDF5Group), path::ByteString)
    obj_id   = h5o_open(parent.id, path)
    obj_type = h5i_get_type(obj_id)
    obj_type == H5I_GROUP ? HDF5Group(obj_id) :
    obj_type == H5I_DATATYPE ? HDF5NamedType(obj_id) :
    obj_type == H5I_DATASET ? HDF5Dataset(obj_id) :
    error("Invalid object type for path ", path)
end

# Get the root group
root(h5file::HDF5File) = h5file["/"]

# Create a group
function group(parent::Union(HDF5File, HDF5Group), path::ByteString)
    group_id = h5g_create(parent.id, path)
    HDF5Group(group_id)
end

# Create a property list
properties() = HDF5Properties(h5p_create(H5P_DATASET_CREATE))

# Create a dataset
# Use this form if you want to control details such as
# compression. For simple cases, write(parent, "name", val) is easier.
function dataset(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Type, dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties, dapl::HDF5Properties)
    dset_id = h5d_create(parent.id, path, dtype.id, dspace.id, lcpl.id, dcpl.id, dapl.id)
    HDF5Dataset(dset_id)
end
dataset(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Type, dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties) = dataset(parent, path, dtype, dspace, lcpl, dcpl, HDF5Properties())
dataset(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Type, dspace::HDF5Dataspace, lcpl::HDF5Properties) = dataset(parent, path, dtype, dspace, lcpl, HDF5Properties(), HDF5Properties())
dataset(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Type, dspace::HDF5Dataspace) = dataset(parent, path, dtype, dspace, HDF5Properties(), HDF5Properties(), HDF5Properties())

# Getting and setting properties: p["chunk"] = dims, p["compress"] = 6
function assign(p::HDF5Properties, val, name::ByteString)
    funcget, funcset = hdf5_prop_get_set[name]
    funcset(p, val...)
    return p
end

# Check existence
function exists(parent::Union(HDF5File, HDF5Group), path::ByteString)
    parts = split(path, "/")
    name = parts[1]
    i = 1
    while h5l_exists(parent.id, name) && i < length(parts)
        i += 1
        name = name*"/"*parts[i]
    end
    if i < length(parts)
        return false
    end
    true
end

# Get the datatype corresponding to a dataset
datatype(dset::HDF5Dataset) = HDF5Type(h5d_get_type(dset.id))

# Create a datatype from in-memory types
datatype{T<:HDF5BitsKind}(A::Array{T}) = HDF5Type(hdf5_type_id(eltype(A)), false)
function datatype(str::ByteString)
    type_id = h5t_copy(hdf5_type_id(ByteString))
    h5t_set_size(type_id, length(str))
    HDF5Type(type_id)
end

# Get the dataspace corresponding to a dataset
function dataspace(dset::HDF5Dataset)
    space_id = h5d_get_space(dset.id)
    if !h5s_is_simple(space_id)
        h5o_close(space_id)
        error("Non-simple dataspaces are not yet implemented")
    end
    HDF5Dataspace(space_id)
end

# Create a dataspace from in-memory types
function dataspace(A::Array)
    dims = convert(Array{Hsize, 1}, [reverse(size(A))...])
    space_id = h5s_create_simple(length(dims), dims, dims)
    HDF5Dataspace(space_id)
end
dataspace(str::ByteString) = HDF5Dataspace(h5s_create(H5S_SCALAR), false)

# Get the array dimensions from a dataspace
# Returns both dims and maxdims
get_dims(dspace::HDF5Dataspace) = h5s_get_simple_extent_dims(dspace.id)

# Read a dataset (see also "Reading arrays using ref" below)
function read(dset::HDF5Dataset)
    local ret
    dtype = datatype(dset)
    try
        T = jltype(dtype)
        if T == ByteString
            native_type = h5t_get_native_type(dtype.id)
            n = h5t_get_size(native_type)
            buf = Array(Uint8, n)
            h5d_read(dset.id, dtype.id, buf)
            ret = bytestring(buf)
        else
            dspace = dataspace(dset)
            try
                dims, maxdims = get_dims(dspace)
                data = Array(T, dims...)
                h5d_read(dset.id, dtype.id, data)
                ret = data
            catch err
                close(dspace)
                throw(err)
            end
            close(dspace)
        end
    catch err
        close(dtype)
        throw(err)
    end
    close(dtype)
    ret
end
function read(parent::Union(HDF5File, HDF5Group), name::ByteString)
    local ret
    obj = parent[name]
    if isa(obj, HDF5Dataset)
        try
            ret = read(obj)
        catch err
            close(obj)
            throw(err)
        end
    else
        if isa(obj, HDF5Group) && exists(obj, "size")
            # read an array of arrays
            try
                sz = read(obj, "size")
                ret = Array(Any, sz...)
                for i = 1:numel(ret)
                    ret[i] = read(obj, string(i))
                end
            catch err
                close(obj)
                println("Error reading array-of-arrays")
                throw(err)
            end
        else
            close(obj)
            error(name, " is not a dataset, but I don't recognize the format")
        end
    end
    close(obj)
    ret
end
function read(parent::Union(HDF5File, HDF5Group), name::ByteString...)
    n = length(name)
    out = Array(Any, n)
    for i = 1:n
        out[i] = read(parent, name[i])
    end
    return tuple(out...)
end

# Write a dataset
function write{T<:HDF5BitsKind}(dset::HDF5Dataset, data::Array{T})
    dtype = datatype(data)
    try
        h5d_write(dset.id, dtype.id, data)
    catch err
        close(dtype)
        throw(err)
    end
    close(dtype)
end
function write{T<:HDF5BitsKind}(parent::Union(HDF5File, HDF5Group), name::ByteString, data::Array{T})
    dtype = datatype(data)
    try
        dspace = dataspace(data)
        try
            dataset_id = h5d_create(parent.id, name, dtype.id, dspace.id)
            try
                h5d_write(dataset_id, dtype.id, data)
            catch err
                h5o_close(dataset_id)
                throw(err)
            end
            h5o_close(dataset_id)
        catch err
            close(dspace)
            throw(err)
        end
        close(dspace)
    catch err
        close(dtype)
        throw(err)
    end
    close(dtype)
end
function write(parent::Union(HDF5File, HDF5Group), name::ByteString, data::ByteString)
    dtype = datatype(data)
    dspace = dataspace(data)
    dataset_id = h5d_create(parent.id, name, dtype.id, dspace.id)
    try
        h5d_write(dataset_id, dtype.id, data)
    catch err
        h5o_close(dataset_id)
        throw(err)
    end
    h5o_close(dataset_id)
end

# Handle arrays-of-arrays, etc
function write(parent::Union(HDF5File, HDF5Group), name::ByteString, A::AbstractArray)
    sz = [size(A)...]
    grp = group(parent, name)
    write(grp, "size", sz)
    for i = 1:numel(A)
        write(grp, string(i), A[i])
    end
end

# Reading arrays using ref
function ref(dset::HDF5Dataset, indices...)
    local ret
    dtype = datatype(dset)
    try
        T = jltype(dtype)
        if T == ByteString
            error("Cannot read strings using dset[...] syntax")
        end
        dspace = dataspace(dset)
        try
            dims, maxdims = get_dims(dspace)
            n_dims = length(dims)
            if length(indices) != n_dims
                error("Wrong number of indices supplied")
            end
            dsel_id = h5s_copy(dspace.id)
            try
                dsel_start  = Array(Hsize, n_dims)
                dsel_stride = Array(Hsize, n_dims)
                dsel_count  = Array(Hsize, n_dims)
                for k = 1:n_dims
                    index = indices[n_dims-k+1]
                    if isa(index, Integer)
                        dsel_start[k] = index-1
                        dsel_stride[k] = 1
                        dsel_count[k] = 1
                    elseif isa(index, Ranges)
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
                ret = Array(T, map(length, indices))
                memtype = datatype(ret)
                memspace = dataspace(ret)
                try
                    h5d_read(dset.id, memtype.id, memspace.id, dsel_id, H5P_DEFAULT, ret)
                catch err
                    close(memtype)
                    close(memspace)
                    throw(err)
                end
                close(memtype)
                close(memspace)
            catch err
                h5s_close(dsel_id)
                throw(err)
            end
            h5s_close(dsel_id)
        catch err
            close(dspace)
            throw(err)
        end
        close(dspace)
    catch err
        close(dtype)
        throw(err)
    end
    close(dtype)
    ret
end

# end of high-level interface

### HDF5 utilities ###
# Get the corresponding Julia type
function jltype(dt::HDF5Type)
    jltype(dt.id)
end
function jltype(type_id::Hid)
    native_type = h5t_get_native_type(type_id)
    element_type = h5t_get_class(native_type)
    element_size = h5t_get_size(native_type)
    if element_type == H5T_INTEGER
        is_signed = h5t_get_sign(type_id)
    else
        is_signed = nothing
    end
    if element_type == H5T_STRING
        return ByteString
    else
        T = hdf5_type_map[(element_type, is_signed, element_size)]
    end
end

# Property manipulation
function get_chunk(p::HDF5Properties)
    n = h5p_get_chunk(p, 0, C_NULL)
    cdims = Array(Hsize, n)
    h5p_get_chunk(p, n, cdims)
    tuple(convert(Array{Int}, cdims)...)
end
function set_chunk(p::HDF5Properties, dims...)
    n = length(dims)
    cdims = Array(Hsize, n)
    for i = 1:n
        cdims[i] = dims[i]
    end
    h5p_set_chunk(p.id, n, cdims)
end

### Convenience wrappers ###
# These supply default values where possible
h5d_create(loc_id::Hid, name::ByteString, type_id::Hid, space_id::Hid) = h5d_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5d_open(obj_id::Hid, name::ByteString) = h5d_open(obj_id, name, H5P_DEFAULT)
h5d_read(dataset_id::Hid, datatype_id::Hid, buf::Array) = h5d_read(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
h5d_write(dataset_id::Hid, datatype_id::Hid, buf::Array) = h5d_write(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
h5d_write(dataset_id::Hid, datatype_id::Hid, buf::ByteString) = h5d_write(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf.data)
h5f_create(filename::ByteString) = h5f_create(filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT)
h5f_open(filename::ByteString, mode) = h5f_open(filename, mode, H5P_DEFAULT)
h5g_create(obj_id::Hid, name::ByteString) = h5g_create(obj_id, name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5g_open(file_id::Hid, name::ByteString) = h5g_open(file_id, name, H5P_DEFAULT)
h5l_exists(loc_id::Hid, name::ByteString) = h5l_exists(loc_id, name, H5P_DEFAULT)
h5o_open(obj_id::Hid, name::ByteString) = h5o_open(obj_id, name, H5P_DEFAULT)
#h5s_get_simple_extent_ndims(space_id::Hid) = h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)
h5t_get_native_type(type_id::Hid) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)

### Utilities for generating ccall wrapper functions programmatically ###

function ccallexpr(ccallsym::Symbol, outtype, argtypes::Tuple, argsyms::Tuple)
    ccallargs = Any[expr(:quote, ccallsym), outtype, expr(:tuple, Any[argtypes...])]
    ccallargs = ccallsyms(ccallargs, length(argtypes), argsyms)
    expr(:ccall, ccallargs)
end

function ccallexpr(lib::Ptr, ccallsym::Symbol, outtype, argtypes::Tuple, argsyms::Tuple)
    ccallargs = Any[expr(:call, Any[:dlsym, lib, expr(:quote, ccallsym)]), outtype, expr(:tuple, Any[argtypes...])]
    ccallargs = ccallsyms(ccallargs, length(argtypes), argsyms)
    expr(:ccall, ccallargs)
end

function ccallsyms(ccallargs, n, argsyms)
    if n > 0
        if length(argsyms) == n
            ccallargs = Any[ccallargs..., argsyms...]
        else
            for i = 1:length(argsyms)-1
                push(ccallargs, argsyms[i])
            end
            for i = 1:n-length(argsyms)+1
                push(ccallargs, expr(:ref, argsyms[end], i))
            end
        end
    end
    ccallargs
end

function funcdecexpr(funcsym, n::Int, argsyms)
    if length(argsyms) == n
        return expr(:call, Any[funcsym, argsyms...])
    else
        exargs = Any[funcsym, argsyms[1:end-1]...]
        push(exargs, expr(:..., argsyms[end]))
        return expr(:call, exargs)
    end
end

### ccall wrappers ###

# Note: use alphabetical order

# Functions that return Herr, pass back nothing to Julia, with simple
# error messages
for (jlname, h5name, outtype, argtypes, argsyms, msg) in
    ((:h5_close, :H5close, Herr, (), (), "Error closing the HDF5 resources"),
     (:h5_dont_atexit, :H5dont_atexit, Herr, (), (), "Error calling dont_atexit"),
     (:h5_garbage_collect, :H5garbage_collect, Herr, (), (), "Error on garbage collect"),
     (:h5_open, :H5open, Herr, (), (), "Error initializing the HDF5 library"),
     (:h5_set_free_list_limits, :H5set_free_list_limits, Herr, (C_int, C_int, C_int, C_int, C_int, C_int), (:reg_global_lim, :reg_list_lim, :arr_global_lim, :arr_list_lim, :blk_global_lim, :blk_list_lim), "Error setting limits on free lists"),
     (:h5a_close, :H5Aclose, Herr, (Hid,), (:id,), "Error closing attribute"),
     (:h5e_set_auto, :H5Eset_auto2, Herr, (Hid, Ptr{Void}, Ptr{Void}), (:estack_id, :func, :client_data), "Error setting error reporting behavior"),  # FIXME callbacks, for now pass C_NULL for both pointers
     (:h5d_close, :H5Dclose, Herr, (Hid,), (:dataset_id,), "Error closing dataset"),
     (:h5d_write, :H5Dwrite, Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Void}), (:dataset_id, :mem_type_id, :mem_space_id, :file_space_id, :xfer_plist_id, :buf), "Error writing dataset"),
     (:h5f_close, :H5Fclose, Herr, (Hid,), (:file_id,), "Error closing file"),
     (:h5f_flush, :H5Fflush, Herr, (Hid, C_int), (:object_id, :scope,), "Error flushing object to file"),
     (:h5g_close, :H5Gclose, Herr, (Hid,), (:group_id,), "Error closing group"),
     (:h5o_close, :H5Oclose, Herr, (Hid,), (:object_id,), "Error closing object"),
     (:h5p_close, :H5Pclose, Herr, (Hid,), (:id,), "Error closing property list"),
     (:h5p_set_chunk, :H5Pset_chunk, Herr, (Hid, C_int, Ptr{Hsize}), (:plist_id, :ndims, :dims), "Error setting chunk size"),
     (:h5p_set_deflate, :H5Pset_deflate, Herr, (Hid, C_unsigned), (:plist_id, :setting), "Error setting compression method and level (deflate)"),
     (:h5p_set_layout, :H5Pset_layout, Herr, (Hid, C_int), (:plist_id, :setting), "Error setting layout"),
     (:h5s_close, :H5Sclose, Herr, (Hid,), (:space_id,), "Error closing dataspace"),
     (:h5s_select_hyperslab, :H5Sselect_hyperslab, Herr, (Hid, Hseloper, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}), (:dspace_id, :seloper, :start, :stride, :count, :block), "Error selecting hyperslab"),
     (:h5t_close, :H5Tclose, Herr, (Hid,), (:dtype_id,), "Error closing datatype"),
     (:h5t_set_size, :H5Tset_size, Herr, (Hid, C_size_t), (:dtype_id, :sz), "Error setting size of datatype"))

     ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
     ex_ccall = ccallexpr(libhdf5, h5name, outtype, argtypes, argsyms)
     ex_body = quote
         status = $ex_ccall
         if status < 0
             error($msg)
         end
     end
     ex_func = expr(:function, Any[ex_dec, ex_body])
     @eval begin
         $ex_func
     end
end

# Functions returning a single argument, and/or with more complex
# error messages
for (jlname, h5name, outtype, argtypes, argsyms, ex_error) in
    ((:h5a_create, :H5Acreate2, Hid, (Hid, Ptr{Uint8}, Hid, Hid, Hid, Hid), (:loc_id, :name, :type_id, :space_id, :acpl_id, :aapl_id), :(error("Error creating attribute ", name))),
     (:h5a_create_by_name, :H5Acreate_by_name, Hid, (Hid, Ptr{Uint8}, Ptr{Uint8}, Hid, Hid, Hid, Hid, Hid), (:loc_id, :obj_name, :attr_name, :type_id, :space_id, :acpl_id, :aapl_id, :lapl_id), :(error("Error creating attribute ", attr_name, " for object ", obj_name))),
     (:h5a_delete, :H5Adelete, Herr, (Hid, Ptr{Uint8}), (:loc_id, :attr_name), :(error("Error deleting attribute ", attr_name))),
     (:h5a_delete_by_idx, :H5delete_by_idx, Herr, (Hid, Ptr{Uint8}, Hindex, Hiter_order, Hsize, Hid), (:loc_id, :obj_name, :idx_type, :order, :n, :lapl_id), :(error("Error deleting attribute ", n, " from object ", obj_name))),
     (:h5a_delete_by_name, :H5delete_by_name, Herr, (Hid, Ptr{Uint8}, Ptr{Uint8}, Hid), (:loc_id, :obj_name, :attr_name, :lapl_id), :(error("Error removing attribute ", attr_name, " from object ", obj_name))),
     (:h5a_get_create_plist, :H5Aget_create_plist, Hid, (Hid,), (:attr_id,), :(error("Cannot get creation property list"))),
     (:h5a_get_name, :H5Aget_name, Hssize, (Hid, C_size_t, Ptr{Uint8}), (:attr_id, :buf_size, :buf), :(error("Error getting attribute name"))),
     (:h5a_open, :H5Aopen, Hid, (Hid, Ptr{Uint8}, Hid), (:obj_id, :name, :aapl_id), :(error("Error opening attribute ", name))),
     (:h5d_create, :H5Dcreate2, Hid, (Hid, Ptr{Uint8}, Hid, Hid, Hid, Hid, Hid), (:loc_id, :name, :dtype_id, :space_id, :dlcpl_id, :dcpl_id, :dapl_id), :(error("Error creating dataset ", name))),
     (:h5d_get_access_plist, :H5Dget_access_plist, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataset access property list"))),     
     (:h5d_get_create_plist, :H5Dget_create_plist, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataset create property list"))),     
     (:h5d_get_space, :H5Dget_space, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataspace"))),     
     (:h5d_get_type, :H5Dget_type, Htype, (Hid,), (:dataset_id,), :(error("Error getting dataspace type"))),
     (:h5d_open, :H5Dopen2, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :name, :dapl_id), :(error("Error opening dataset ", name))),
     (:h5d_read, :H5Dread, Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Void}), (:dataset_id, :mem_type_id, :mem_space_id, :file_space_id, :xfer_plist_id, :buf), :(error("Error reading dataset"))),
     (:h5f_create, :H5Fcreate, Hid, (Ptr{Uint8}, C_unsigned, Hid, Hid), (:name, :flags, :fcpl_id, :fapl_id), :(error("Error creating file ", name))),
     (:h5f_get_access_plist, :H5Fget_access_plist, Hid, (Hid,), (:file_id,), :(error("Error getting file access property list"))),     
     (:h5f_get_create_plist, :H5Fget_create_plist, Hid, (Hid,), (:file_id,), :(error("Error getting file create property list"))),     
     (:h5f_get_name, :H5Fget_name, Hssize, (Hid, Ptr{Uint8}, C_size_t), (:obj_id, :buf, :buf_size), :(error("Error getting file name"))),
     (:h5f_open, :H5Fopen, Hid, (Ptr{Uint8}, C_unsigned, Hid), (:name, :flags, :fapl_id), :(error("Error opening file ", name))),
     (:h5g_create, :H5Gcreate2, Hid, (Hid, Ptr{Uint8}, Hid, Hid, Hid), (:loc_id, :name, :lcpl_id, :gcpl_id, :gapl_id), :(error("Error creating group ", name))),
     (:h5g_get_create_plist, :H5Gget_create_plist, Hid, (Hid,), (:group_id,), :(error("Error getting group create property list"))),     
     (:h5g_open, :H5Gopen2, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :name, :gapl_id), :(error("Error opening group ", name))),
     (:h5i_get_type, :H5Iget_type, Htype, (Hid,), (:obj_id,), :(error("Error getting type"))),
     (:h5o_open, :H5Oopen, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :name, :lapl_id), :(error("Error opening object ", name))),
     (:h5p_create, :H5Pcreate, Hid, (Hid,), (:cls_id,), "Error creating property list"),
     (:h5p_get_chunk, :H5Pget_chunk, C_int, (Hid, C_int, Ptr{Hsize}), (:plist_id, :n_dims, :dims), :(error("Error getting chunk size"))),
     (:h5p_get_layout, :H5Pget_layout, C_int, (Hid,), (:plist_id,), :(error("Error getting layout"))),
     (:h5s_copy, :H5Scopy, Hid, (Hid,), (:space_id,), :(error("Error copying dataspace"))),
     (:h5s_create, :H5Screate, Hid, (Hclass,), (:class,), :(error("Error creating dataspace"))),
     (:h5s_create_simple, :H5Screate_simple, Hid, (C_int, Ptr{Hsize}, Ptr{Hsize}), (:rank, :current_dims, :maximum_dims), :(error("Error creating simple dataspace"))),
     (:h5s_get_simple_extent_dims, :H5Sget_simple_extent_dims, C_int, (Hid, Ptr{Hsize}, Ptr{Hsize}), (:space_id, :dims, :maxdims), :(error("Error getting the dimensions for a dataspace"))),
     (:h5s_get_simple_extent_ndims, :H5Sget_simple_extent_ndims, C_int, (Hid,), (:space_id,), :(error("Error getting the number of dimensions for a dataspace"))),
     (:h5t_copy, :H5Tcopy, Hid, (Hid,), (:dtype_id,), :(error("Error copying datatype"))),
     (:h5t_get_class, :H5Tget_class, Hclass, (Hid,), (:dtype_id,), :(error("Error getting class"))),
     (:h5t_get_native_type, :H5Tget_native_type, Hid, (Hid, Hdirection), (:dtype_id, :direction), :(error("Error getting native type"))),
     (:h5t_get_sign, :H5Tget_sign, Hsign, (Hid,), (:dtype_id,), :(error("Error getting sign"))),
     (:h5t_get_size, :H5Tget_size, C_size_t, (Hid,), (:dtype_id,), :(error("Error getting size")))
)

    ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
    ex_ccall = ccallexpr(libhdf5, h5name, outtype, argtypes, argsyms)
    ex_body = quote
        ret = $ex_ccall
        if ret < 0
            $ex_error
        end
        return ret
    end
    ex_func = expr(:function, Any[ex_dec, ex_body])
    @eval begin
        $ex_func
    end
end

# Functions like the above, returning a Julia boolean
for (jlname, h5name, outtype, argtypes, argsyms, ex_error) in
    ((:h5a_exists, :H5Aexists, Htri, (Hid, Ptr{Uint8}), (:obj_id, :attr_name), :(error("Error checking whether attribute ", attr_name, " exists"))),
     (:h5a_exists_by_name, :H5Aexists_by_name, Htri, (Hid, Ptr{Uint8}, Ptr{Uint8}, Hid), (:loc_id, :obj_name, :attr_name, :lapl_id), :(error("Error checking whether object ", obj_name, " has attribute ", attr_name))),
     (:h5f_is_hdf5, :H5Fis_hdf5, Htri, (Ptr{Uint8},), (:name,), :(error("Cannot access file ", name))),
     (:h5l_exists, :H5Lexists, Htri, (Hid, Ptr{Uint8}, Hid), (:loc_id, :name, :lapl_id), :(error("Cannot determine whether ", name, " exists"))),
     (:h5s_is_simple, :H5Sis_simple, Htri, (Hid,), (:space_id,), :(error("Error determining whether dataspace is simple")))
)
    ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
    ex_ccall = ccallexpr(libhdf5, h5name, outtype, argtypes, argsyms)
    ex_body = quote
        ret = $ex_ccall
        if ret < 0
            $ex_error
        end
        return ret > 0
    end
    ex_func = expr(:function, Any[ex_dec, ex_body])
    @eval begin
        $ex_func
    end
end

# Functions that require special handling
_majnum = Array(C_unsigned, 1)
_minnum = Array(C_unsigned, 1)
_relnum = Array(C_unsigned, 1)
function h5_get_libversion()
    status = ccall(dlsym(libhdf5, :H5get_libversion),
                   Herr,
                   (Ptr{C_unsigned}, Ptr{C_unsigned}, Ptr{C_unsigned}),
                   _majnum, _minnum, _relnum)
    if status < 0
        error("Error getting HDF5 library version")
    end
    return _majnum[1], _minnum[1], _relnum[1]
end
function h5s_get_simple_extent_dims(space_id::Hid)
    n = h5s_get_simple_extent_ndims(space_id)
    dims = Array(Hsize, n)
    maxdims = Array(Hsize, n)
    h5s_get_simple_extent_dims(space_id, dims, maxdims)
    return tuple(reverse(dims)...), tuple(reverse(maxdims)...)
end

### Property functions get/set pairs ###
const hdf5_prop_get_set = {
    "chunk"         => (get_chunk, set_chunk),
    "deflate"       => (nothing, h5p_set_deflate),
    "compress"      => (nothing, h5p_set_deflate),
    "layout"        => (h5p_get_layout, h5p_set_layout),
}

### Initialize the HDF library ###

# Turn off automatic error printing
#h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)

export
    # Types 
    HDF5Object,
    HDF5File,
    HDF5Group,
    HDF5Dataset,
    HDF5Type,
    HDF5Dataspace,
    HDF5Properties,
    # Functions
    close,
    create,
    exists,
    h5open,
    properties,
    read,
    ref,
    root,
    write

end  # module
