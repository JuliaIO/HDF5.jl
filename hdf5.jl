####################
## HDF5 interface ##
####################

require("strpack.jl")
#module HDF5
import Base.*
#load("hdf5_julia.jl")

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
# Link constants
const H5L_TYPE_HARD    = 0
const H5L_TYPE_SOFT    = 1
const H5L_TYPE_EXTERNAL= 2
# Object constants
const H5O_TYPE_GROUP   = 0
const H5O_TYPE_DATASET = 1
const H5O_TYPE_NAMED_DATATYPE = 2
# Property constants
const H5P_DEFAULT          = 0
const H5P_OBJECT_CREATE    = read_const(:H5P_CLS_OBJECT_CREATE_g)
const H5P_FILE_CREATE      = read_const(:H5P_CLS_FILE_CREATE_g)
const H5P_FILE_ACCESS      = read_const(:H5P_CLS_FILE_ACCESS_g)
const H5P_DATASET_CREATE   = read_const(:H5P_CLS_DATASET_CREATE_g)
const H5P_DATASET_ACCESS   = read_const(:H5P_CLS_DATASET_ACCESS_g)
const H5P_DATASET_XFER     = read_const(:H5P_CLS_DATASET_XFER_g)
const H5P_FILE_MOUNT       = read_const(:H5P_CLS_FILE_MOUNT_g)
const H5P_GROUP_CREATE     = read_const(:H5P_CLS_GROUP_CREATE_g)
const H5P_GROUP_ACCESS     = read_const(:H5P_CLS_GROUP_ACCESS_g)
const H5P_DATATYPE_CREATE  = read_const(:H5P_CLS_DATATYPE_CREATE_g)
const H5P_DATATYPE_ACCESS  = read_const(:H5P_CLS_DATATYPE_ACCESS_g)
const H5P_STRING_CREATE    = read_const(:H5P_CLS_STRING_CREATE_g)
const H5P_ATTRIBUTE_CREATE = read_const(:H5P_CLS_ATTRIBUTE_CREATE_g)
const H5P_OBJECT_COPY      = read_const(:H5P_CLS_OBJECT_COPY_g)
const H5P_LINK_CREATE      = read_const(:H5P_CLS_LINK_CREATE_g)
const H5P_LINK_ACCESS      = read_const(:H5P_CLS_LINK_ACCESS_g)
# Reference constants
const H5R_OBJECT       = 0
const H5R_DATASET_REGION = 1
const H5R_OBJ_REF_BUF_SIZE      = 8
const H5R_DSET_REG_REF_BUF_SIZE = 12
# Dataspace constants
const H5S_ALL          = 0
const H5S_SCALAR       = 0
const H5S_SIMPLE       = 1
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
const H5T_STD_I8LE        = read_const(:H5T_STD_I8LE_g)
const H5T_STD_I8BE        = read_const(:H5T_STD_I8BE_g)
const H5T_STD_U8LE        = read_const(:H5T_STD_U8LE_g)
const H5T_STD_U8BE        = read_const(:H5T_STD_U8BE_g)
const H5T_STD_I16LE       = read_const(:H5T_STD_I16LE_g)
const H5T_STD_I16BE       = read_const(:H5T_STD_I16BE_g)
const H5T_STD_U16LE       = read_const(:H5T_STD_U16LE_g)
const H5T_STD_U16BE       = read_const(:H5T_STD_U16BE_g)
const H5T_STD_I32LE       = read_const(:H5T_STD_I32LE_g)
const H5T_STD_I32BE       = read_const(:H5T_STD_I32BE_g)
const H5T_STD_U32LE       = read_const(:H5T_STD_U32LE_g)
const H5T_STD_U32BE       = read_const(:H5T_STD_U32BE_g)
const H5T_STD_I64LE       = read_const(:H5T_STD_I64LE_g)
const H5T_STD_I64BE       = read_const(:H5T_STD_I64BE_g)
const H5T_STD_U64LE       = read_const(:H5T_STD_U64LE_g)
const H5T_STD_U64BE       = read_const(:H5T_STD_U64BE_g)
const H5T_IEEE_F32LE      = read_const(:H5T_IEEE_F32LE_g)
const H5T_IEEE_F32BE      = read_const(:H5T_IEEE_F32BE_g)
const H5T_IEEE_F64LE      = read_const(:H5T_IEEE_F64LE_g)
const H5T_IEEE_F64BE      = read_const(:H5T_IEEE_F64BE_g)
const H5T_C_S1            = read_const(:H5T_C_S1_g)
const H5T_STD_REF_OBJ     = read_const(:H5T_STD_REF_OBJ_g)
const H5T_STD_REF_DSETREG = read_const(:H5T_STD_REF_DSETREG_g)
# Native types
const H5T_NATIVE_INT8     = read_const(:H5T_NATIVE_INT8_g)
const H5T_NATIVE_UINT8    = read_const(:H5T_NATIVE_UINT8_g)
const H5T_NATIVE_INT16    = read_const(:H5T_NATIVE_INT16_g)
const H5T_NATIVE_UINT16   = read_const(:H5T_NATIVE_UINT16_g)
const H5T_NATIVE_INT32    = read_const(:H5T_NATIVE_INT32_g)
const H5T_NATIVE_UINT32   = read_const(:H5T_NATIVE_UINT32_g)
const H5T_NATIVE_INT64    = read_const(:H5T_NATIVE_INT64_g)
const H5T_NATIVE_UINT64   = read_const(:H5T_NATIVE_UINT64_g)
const H5T_NATIVE_FLOAT    = read_const(:H5T_NATIVE_FLOAT_g)
const H5T_NATIVE_DOUBLE   = read_const(:H5T_NATIVE_DOUBLE_g)

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
# It's not safe to use particular id codes because these can change, so we use characteristics of the type.
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
# errors from calling close() twice on the same object. It's also there
# to prevent errors in cases where the object shouldn't be closed at
# all (like calling hdf5_type_id on BitsKind, which does not open a
# new resource, or calling h5s_create with H5S_SCALAR).

abstract HDF5Object
abstract HDF5File <: HDF5Object

# This defines an "unformatted" HDF5 data file. Formatted files are defined in separate modules.
type PlainHDF5File <: HDF5File
    id::Hid
    filename::String
    toclose::Bool

    function PlainHDF5File(id, filename, toclose::Bool)
        f = new(id, filename, toclose)
        if toclose
            finalizer(f, close)
        end
        f
    end
end
PlainHDF5File(id, filename) = PlainHDF5File(id, filename, true)
convert(::Type{C_int}, f::HDF5File) = f.id
plain(f::HDF5File) = PlainHDF5File(f.id, f.filename, false)

type HDF5Group{F<:HDF5File} <: HDF5Object
    id::Hid
    file::F         # the parent file
    toclose::Bool

    function HDF5Group(id, file, toclose::Bool)
        g = new(id, file, toclose)
        if toclose
            finalizer(g, close)
        end
        g
    end
end
HDF5Group{F<:HDF5File}(id, file::F, toclose::Bool) = HDF5Group{F}(id, file, toclose)
HDF5Group(id, file) = HDF5Group(id, file, true)
convert(::Type{C_int}, g::HDF5Group) = g.id
plain(g::HDF5Group) = HDF5Group(g.id, plain(g.file), false)

type HDF5Dataset{F<:HDF5File} <: HDF5Object
    id::Hid
    file::F
    toclose::Bool
    
    function HDF5Dataset(id, file, toclose::Bool)
        dset = new(id, file, toclose)
        if toclose
            finalizer(dset, close)
        end
        dset
    end
end
HDF5Dataset{F<:HDF5File}(id, file::F, toclose::Bool) = HDF5Dataset{F}(id, file, toclose)
HDF5Dataset(id, file) = HDF5Dataset(id, file, true)
convert(::Type{C_int}, dset::HDF5Dataset) = dset.id
plain(dset::HDF5Dataset) = HDF5Dataset(dset.id, plain(dset.file), false)

type HDF5Datatype <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Datatype(id, toclose::Bool)
        nt = new(id, toclose)
        if toclose
            finalizer(nt, close)
        end
        nt
    end
end
HDF5Datatype(id) = HDF5Datatype(id, true)
convert(::Type{C_int}, dtype::HDF5Datatype) = dtype.id

type HDF5Dataspace <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Dataspace(id, toclose::Bool)
        dspace = new(id, toclose)
        if toclose
            finalizer(dspace, close)
        end
        dspace
    end
end
HDF5Dataspace(id) = HDF5Dataspace(id, true)
convert(::Type{C_int}, dspace::HDF5Dataspace) = dspace.id

type HDF5Attribute <: HDF5Object
    id::Hid
    toclose::Bool
    
    function HDF5Attribute(id, toclose::Bool)
        attr = new(id, toclose)
        if toclose
            finalizer(attr, close)
        end
        attr
    end
end
HDF5Attribute(id) = HDF5Attribute(id, true)
convert(::Type{C_int}, attr::HDF5Attribute) = attr.id

type HDF5Properties <: HDF5Object
    id::Hid
    toclose::Bool

    function HDF5Properties(id, toclose::Bool)
        p = new(id, toclose)
        if toclose
            finalizer(p, close)
        end
        p
    end
end
HDF5Properties(id) = HDF5Properties(id, true)
HDF5Properties() = HDF5Properties(H5P_DEFAULT, false)
convert(::Type{C_int}, p::HDF5Properties) = p.id

# A Julia type that allows you to specify the intended meaning of a path string
#
# ref by name alone can be ambiguous: for example, groups can have both
# attributes and datasets, and there does not appear to be anything that prevents
# you from using the same name for one of each.
#  type HDF5ObjType{T<:HDF5Object}
#      name::ByteString
#      properties::HDF5Properties
#  end
#  group(path::ByteString, prop::HDF5Properties) = HDF5ObjType{HDF5Group}(path, prop)
#  group(path::ByteString) = HDF5ObjType{HDF5Group}(path, HDF5Properties())
#  dataset(path::ByteString, prop::HDF5Properties) = HDF5ObjType{HDF5Dataset}(path, prop)
#  dataset(path::ByteString) = HDF5ObjType{HDF5Dataset}(path, HDF5Properties())
#  datatype(path::ByteString, prop::HDF5Properties) = HDF5ObjType{HDF5Datatype}(path, prop)
#  datatype(path::ByteString) = HDF5ObjType{HDF5Datatype}(path, HDF5Properties())
#  attribute(path::ByteString, prop::HDF5Properties) = HDF5ObjType{HDF5Attribute}(path, prop)
#  attribute(path::ByteString) = HDF5ObjType{HDF5Attribute}(path, HDF5Properties())

# Types to collect information from HDF5
type H5LInfo
    linktype::C_int
    corder_valid::C_unsigned
    corder::Int64
    cset::C_int
    u::Uint64
end
H5LInfo() = H5LInfo(int32(0), uint32(0), int64(0), int32(0), uint64(0))

# Object reference type
type HDF5ReferenceObj; end

### High-level interface ###
# Open or create an HDF5 file
function h5open(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool, toclose::Bool)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end
    if cr && (tr || !isfile(filename))
        fid = h5f_create(filename)
    else
        if !h5f_is_hdf5(filename)
            error("This does not appear to be an HDF5 file")
        end
        fid = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY)
    end
    PlainHDF5File(fid, filename, toclose)
end

function h5open(filename::String, mode::String, toclose::Bool)
    mode == "r"  ? h5open(filename, true,  false, false, false, false, toclose) :
    mode == "r+" ? h5open(filename, true,  true , false, false, true, toclose)  :
    mode == "w"  ? h5open(filename, false, true , true , true,  false, toclose)  :
    mode == "w+" ? h5open(filename, true,  true , true , true,  false, toclose)  :
    mode == "a"  ? h5open(filename, true,  true , true , true,  true, toclose)   :
    error("invalid open mode: ", mode)
end
h5open(filename::String, mode::String) = h5open(filename, mode, true)
h5open(filename::String) = h5open(filename, "r")

# Close functions
for (h5type, h5func) in
    ((HDF5File, :h5f_close),
     (HDF5Group, :h5o_close),
     (HDF5Dataset, :h5o_close),
     (HDF5Datatype, :h5o_close),
     (HDF5Dataspace, :h5s_close),
     (HDF5Attribute, :h5a_close),
     (HDF5Properties, :h5p_close))
    @eval begin
        function close(obj::$h5type)
            if obj.toclose
                $h5func(obj.id)
                obj.toclose = false
            end
            nothing
        end
    end
end

# Extract the file
file(f::HDF5File) = f
file(g::HDF5Group) = g.file
file(dset::HDF5Dataset) = dset.file

# Open objects
g_open(parent::Union(HDF5File, HDF5Group), name::ByteString) = HDF5Group(h5g_open(parent.id, name, H5P_DEFAULT), file(parent))
d_open(parent::Union(HDF5File, HDF5Group), name::ByteString, apl::HDF5Properties) = HDF5Dataset(h5d_open(parent.id, name, apl.id), file(parent))
d_open(parent::Union(HDF5File, HDF5Group), name::ByteString) = HDF5Dataset(h5d_open(parent.id, name, H5P_DEFAULT), file(parent))
t_open(parent::Union(HDF5Group, HDF5Dataset), name::ByteString, apl::HDF5Properties) = HDF5Datatype(h5t_open(parent.id, name, apl.id))
t_open(parent::Union(HDF5Group, HDF5Dataset), name::ByteString) = HDF5Datatype(h5t_open(parent.id, name, H5P_DEFAULT))
a_open(parent::Union(HDF5Group, HDF5Dataset), name::ByteString) = HDF5Attribute(h5a_open(parent.id, name, H5P_DEFAULT))
# "Generic" (group, named datatype, or dataset) open
function o_open(parent, path::ByteString)
    obj_id   = h5o_open(parent.id, path)
    obj_type = h5i_get_type(obj_id)
    obj_type == H5I_GROUP ? HDF5Group(obj_id, file(parent)) :
    obj_type == H5I_DATATYPE ? HDF5NamedType(obj_id) :
    obj_type == H5I_DATASET ? HDF5Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
# Get the root group
root(h5file::HDF5File) = g_open(h5file, "/")

# Create objects
g_create(parent::Union(HDF5File, HDF5Group), path::ByteString, lcpl::HDF5Properties, dcpl::HDF5Properties) = HDF5Group(h5g_create(parent.id, path, lcpl.id, dcpl.id), file(parent))
g_create(parent::Union(HDF5File, HDF5Group), path::ByteString, lcpl::HDF5Properties) = HDF5Group(h5g_create(parent.id, path, lcpl.id, H5P_DEFAULT), file(parent))
g_create(parent::Union(HDF5File, HDF5Group), path::ByteString) = HDF5Group(h5g_create(parent.id, path, H5P_DEFAULT, H5P_DEFAULT), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Datatype, dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties, dapl::HDF5Properties) = HDF5Dataset(h5d_create(parent.id, path, dtype.id, dspace.id, lcpl.id, dcpl.id, dapl.id), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Datatype, dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties) = HDF5Dataset(h5d_create(parent.id, path, dtype.id, dspace.id, lcpl.id, dcpl.id, H5P_DEFAULT), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Datatype, dspace::HDF5Dataspace, lcpl::HDF5Properties) = HDF5Dataset(h5d_create(parent.id, path, dtype.id, dspace.id, lcpl.id, H5P_DEFAULT, H5P_DEFAULT), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ByteString, dtype::HDF5Datatype, dspace::HDF5Dataspace) = HDF5Dataset(h5d_create(parent.id, path, dtype.id, dspace.id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT), file(parent))
# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
t_create(class_id, sz) = HDF5Datatype(h5t_create(class_id, sz))
function t_commit(parent::Union(HDF5Group, HDF5Dataset), path::ByteString, dtype::HDF5Datatype, lcpl::HDF5Properties, tcpl::HDF5Properties, tapl::HDF5Properties)
    h5t_commit(parent.id, path, dtype.id, lcpl.id, tcpl.id, tapl.id)
    dtype
end
function t_commit(parent::Union(HDF5Group, HDF5Dataset), path::ByteString, dtype::HDF5Datatype, lcpl::HDF5Properties, tcpl::HDF5Properties)
    h5t_commit(parent.id, path, dtype.id, lcpl.id, tcpl.id, H5P_DEFAULT)
    dtype
end
function t_commit(parent::Union(HDF5Group, HDF5Dataset), path::ByteString, dtype::HDF5Datatype, lcpl::HDF5Properties)
    h5t_commit(parent.id, path, dtype.id, lcpl.id, H5P_DEFAULT, H5P_DEFAULT)
    dtype
end
function t_commit(parent::Union(HDF5Group, HDF5Dataset), path::ByteString, dtype::HDF5Datatype)
    h5t_commit(parent.id, path, dtype.id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
    dtype
end
a_create(dset::HDF5Dataset, path::ByteString, dtype::HDF5Datatype, dspace::HDF5Dataspace) = HDF5Attribute(h5a_create(dset.id, path, dtype.id, dspace.id))
p_create(class) = HDF5Properties(h5p_create(class))

# Getting and setting properties: p["chunk"] = dims, p["compress"] = 6
function assign(p::HDF5Properties, val, name::ByteString)
    funcget, funcset = hdf5_prop_get_set[name]
    funcset(p, val...)
    return p
end

# Check existence
function exists(parent::Union(HDF5File, HDF5Group), path::ByteString, lapl::HDF5Properties)
    parts = split(path, "/")
    name = parts[1]
    i = 1
    while h5l_exists(parent.id, name, lapl.id) && i < length(parts)
        i += 1
        name = name*"/"*parts[i]
    end
    if i < length(parts)
        return false
    end
    true
end
exists(parent::Union(HDF5File, HDF5Group), path::ByteString) = exists(parent, path, p_create())

# Get the datatype of a dataset
datatype(dset::HDF5Dataset) = HDF5Datatype(h5d_get_type(dset.id))
# Get the datatype of an attribute
datatype(dset::HDF5Attribute) = HDF5Datatype(h5a_get_type(dset.id))

# Create a datatype from in-memory types
datatype{T<:HDF5BitsKind}(x::T) = HDF5Datatype(hdf5_type_id(T), false)
datatype{T<:HDF5BitsKind}(A::Array{T}) = HDF5Datatype(hdf5_type_id(eltype(A)), false)
function datatype(str::ByteString)
    type_id = h5t_copy(hdf5_type_id(ByteString))
    h5t_set_size(type_id, length(str))
    HDF5Datatype(type_id)
end

# Get the dataspace of a dataset
dataspace(dset::HDF5Dataset) = HDF5Dataspace(h5d_get_space(dset.id))
# Get the dataspace of an attribute
dataspace(attr::HDF5Attribute) = HDF5DataSpace(h5a_get_space(attr.id))

# Create a dataspace from in-memory types
dataspace{T<:HDF5BitsKind}(x::T) = HDF5Dataspace(h5s_create(H5S_SCALAR))
function dataspace(A::Array)
    dims = convert(Array{Hsize, 1}, [reverse(size(A))...])
    space_id = h5s_create_simple(length(dims), dims, dims)
    HDF5Dataspace(space_id)
end
dataspace(str::ByteString) = HDF5Dataspace(h5s_create(H5S_SCALAR))

# Get the array dimensions from a dataspace
# Returns both dims and maxdims
get_dims(dspace::HDF5Dataspace) = h5s_get_simple_extent_dims(dspace.id)


# Generic read functions
for (fsym, osym, ptype) in
    ((:d_read, :d_open, Union(HDF5File, HDF5Group)),
     (:a_read, :a_open, Union(HDF5Group, HDF5Dataset)))
    @eval begin
        function ($fsym)(parent::$ptype, name::ByteString)
            local ret
            obj = ($osym)(parent, name)
        #      try
                ret = read(obj)
        #      catch err
        #          close(obj)
        #          throw(err)
        #      end
            close(obj)
            ret
        end
    end
end
# "read" defaults to d_read
read{F<:HDF5File}(parent::Union(F, HDF5Group{F}), name::ByteString) = d_read(parent, name)
# Read a list of variables
function read{F<:HDF5File}(parent::Union(F, HDF5Group{F}), name::ByteString...)
    n = length(name)
    out = Array(Any, n)
    for i = 1:n
        out[i] = read(parent, name[i])
    end
    return tuple(out...)
end

# "Plain" (unformatted) reads. These only work for simple types
# See also "Reading arrays using ref" below
# This infers the Julia type from the HDF5Datatype. Specific formats should provide their own read(dset). This one can be used by calling read(plain(dset)).
function read(obj::Union(HDF5Dataset{PlainHDF5File}, HDF5Attribute))
    local T
    T = hdf5_to_julia(obj)
    read(obj, T)
end
# To avoid method ambiguities, we cannot use Unions
for objtype in (HDF5Dataset{PlainHDF5File}, HDF5Attribute)
    for T in (Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64, Float32, Float64)
        @eval begin
            # Read scalars (BitsKind only)
            function read(obj::$objtype, ::Type{$T})
                x = read(obj, Array{$T})
                x[1]
            end
            # Read array of BitsKind
            function read(obj::$objtype, ::Type{Array{$T}})
                local data
                dspace = dataspace(obj)
            #              try
                    dims, maxdims = get_dims(dspace)
                    data = Array($T, dims...)
                    readarray(obj, hdf5_type_id($T), data)
            #              catch err
            #                  close(dspace)
            #                  throw(err)
            #              end
                close(dspace)
                data
            end
        end
    end
    @eval begin
        # Read string
        function read(obj::$objtype, ::Type{ByteString})
            local ret::ByteString
            objtype = datatype(obj)
        #      try
                n = h5t_get_size(objtype.id)
                buf = Array(Uint8, n)
                readarray(obj, objtype.id, buf)
                ret = bytestring(buf)
        #      catch err
        #          close(objtype)
        #          throw(err)
        #      end
            close(objtype)
            ret
        end
    end
end
# Read an array of references
function read(obj::HDF5Dataset{PlainHDF5File}, ::Type{Array{HDF5ReferenceObj}})
    local refs::Array{Uint8}
    dspace = dataspace(obj)
#      try
        dims, maxdims = get_dims(dspace)
        refs = Array(Uint8, H5R_OBJ_REF_BUF_SIZE, dims...)
        h5d_read(obj.id, H5T_STD_REF_OBJ, refs)
#      catch err
#          close(dspace)
#          throw(err)
#      end
    close(dspace)
    refs
end

# Generic write
function write{F<:HDF5File}(parent::Union(F, HDF5Group{F}), name1::ByteString, val1, name2::ByteString, val2, nameval...)
    if !iseven(length(nameval))
        error("name, value arguments must come in pairs")
    end
    write(parent, name1, val1)
    write(parent, name2, val2)
    for i = 1:2:length(nameval)
        thisname = nameval[i]
        if !isa(thisname, ByteString)
            error("Argument ", i, " should be a string, but it's a ", typeof(thisname))
        end
        write(parent, thisname, nameval[i+1])
    end
end

# Plain dataset & attribute writes
# Due to method ambiguities we generate these explicitly

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = d_create(parent, name, data)
for (privatesym, fsym, ptype) in
    ((:_d_create, :d_create, Union(PlainHDF5File, HDF5Group{PlainHDF5File})),
     (:_a_create, :a_create, Union(HDF5Group{PlainHDF5File}, HDF5Dataset{PlainHDF5File})))
    @eval begin
        # Generic create (hidden)
        function ($privatesym)(parent::$ptype, name::ByteString, data)
            local dtype
            local obj
            dtype = datatype(data)
            try
                dspace = dataspace(data)
                try
                    obj = ($fsym)(parent, name, dtype, dspace)
                catch err
                    close(dspace)
                    throw(err)
                end
                close(dspace)
            catch err
                close(dtype)
                throw(err)
            end
            obj, dtype
        end
        # Scalar types
        ($fsym){T<:HDF5BitsKind}(parent::$ptype, name::ByteString, data::T) = ($privatesym)(parent, name, data)
        # Arrays
        ($fsym){T<:HDF5BitsKind}(parent::$ptype, name::ByteString, data::Array{T}) = ($privatesym)(parent, name, data)
        # ByteStrings
        ($fsym)(parent::$ptype, name::ByteString, data::ByteString) = ($privatesym)(parent, name, data)
    end
end
# Create and write, closing the objects upon exit
for (privatesym, fsym, ptype, crsym) in
    ((:_d_write, :d_write, Union(PlainHDF5File, HDF5Group{PlainHDF5File}), :d_create),
     (:_a_write, :a_write, Union(HDF5Group{PlainHDF5File}, HDF5Dataset{PlainHDF5File}), :a_create))
    @eval begin
        # Generic write (hidden)
        function ($privatesym)(parent::$ptype, name::ByteString, data)
            obj, dtype = ($crsym)(parent, name, data)
            try
                writearray(obj, dtype.id, data)
            catch err
                close(obj)
                close(dtype)
                throw(err)
            end
            close(obj)
            close(dtype)
        end
        # Scalar types
        ($fsym){T<:HDF5BitsKind}(parent::$ptype, name::ByteString, data::T) = ($privatesym)(parent, name, data)
        # Arrays
        ($fsym){T<:HDF5BitsKind}(parent::$ptype, name::ByteString, data::Array{T}) = ($privatesym)(parent, name, data)
        # ByteStrings
        ($fsym)(parent::$ptype, name::ByteString, data::ByteString) = ($privatesym)(parent, name, data)
    end
end

for objtype in (HDF5Dataset{PlainHDF5File}, HDF5Attribute)
    for T in (Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64, Float32, Float64)
        @eval begin
            # Scalars
            function write(obj::$objtype, x::$T)
                dtype = datatype(x)
#                try
                    writearray(obj, dtype.id, x)
#                catch err
#                    close(dtype)
#                    throw(err)
#                end
                close(dtype)
            end
            # Arrays
            function write(obj::$objtype, data::Array{$T})
                dtype = datatype(data)
#                try
                    writearray(obj, dtype.id, data)
#                catch err
#                    close(dtype)
#                    throw(err)
#                end
                close(dtype)
            end
        end
    end
    # ByteString
    @eval begin
        function write(obj::$objtype, str::ByteString)
            dtype = datatype(str)
#            try
                writearray(obj, dtype.id, str)
#              catch err
#                  close(dtype)
#                  throw(err)
#              end
            close(dtype)
        end
    end
end
# For plain, let "write" mean "d_write"
write{T<:HDF5BitsKind}(parent::Union(PlainHDF5File, HDF5Group{PlainHDF5File}), name::ByteString, data::T) = d_write(parent, name, data)
write{T<:HDF5BitsKind}(parent::Union(PlainHDF5File, HDF5Group{PlainHDF5File}), name::ByteString, data::Array{T}) = d_write(parent, name, data)
write(parent::Union(PlainHDF5File, HDF5Group{PlainHDF5File}), name::ByteString, data::ByteString) = d_write(parent, name, data)
# Write to already-created objects


# Reading arrays using ref
function ref(dset::HDF5Dataset{PlainHDF5File}, indices...)
    local ret
    dtype = datatype(dset)
    try
        T = hdf5_to_julia_eltype(dset, dtype)
        println(T)
        if !(T <: HDF5BitsKind)
            error("Must be a HDF5BitsKind array to use dset[...] syntax")
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
readarray(dset::HDF5Dataset, type_id, buf) = h5d_read(dset.id, type_id, buf)
readarray(attr::HDF5Attribute, type_id, buf) = h5a_read(attr.id, type_id, buf)
writearray(dset::HDF5Dataset, type_id, buf) = h5d_write(dset.id, type_id, buf)
writearray(attr::HDF5Attribute, type_id, buf) = h5a_write(attr.id, type_id, buf)

# Determine Julia "native" type from the class, datatype, and dataspace
# For datasets, defined file formats should use attributes instead
function hdf5_to_julia(obj::Union(HDF5Dataset, HDF5Attribute))
    local T
    objtype = datatype(obj)
    try
        T = hdf5_to_julia_eltype(obj, objtype)
    catch err
        close(objtype)
        throw(err)
    end
    close(objtype)
    if T != ByteString
        # Determine whether it's an array
        objspace = dataspace(obj)
        try
            if h5s_is_simple(objspace.id)
                T = Array{T}
            end
        catch err
            close(objspace)
            throw(err)
        end
        close(objspace)
    end
    T
end

function hdf5_to_julia_eltype(obj, objtype)
    local T
    class_id = h5t_get_class(objtype.id)
    if class_id == H5T_STRING
        T = ByteString
    elseif class_id == H5T_INTEGER || class_id == H5T_FLOAT
        native_type = h5t_get_native_type(objtype.id)
        native_size = h5t_get_size(native_type)
        if class_id == H5T_INTEGER
            is_signed = h5t_get_sign(native_type)
        else
            is_signed = nothing
        end
        T = hdf5_type_map[(class_id, is_signed, native_size)]
    elseif class_id == H5T_REFERENCE
        # How to test whether it's a region reference or an object reference??
        T = HDF5ReferenceObj
    else
        error("Class id ", class_id, " is not yet supported")
    end
    T
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
#  set_userblock(p::HDF5Properties, len) = h5p_set_userblock(p.id, len)
function get_userblock(p::HDF5Properties)
    alen = Array(Hsize, 1)
    h5p_get_userblock(p.id, alen)
    alen[1]
end
 

### Format specifications ###

#  f2e_map = {
#      :FORMAT_JULIA_V1      => ".h5",
#      :FORMAT_MATLAB_V73    => ".mat",
#  }
#  e2f_map = {
#      ".h5"    => :FORMAT_JULIA_V1,
#      ".mat"   => :FORMAT_MATLAB_V73,
#  }
#f2write_map = {
#    :FORMAT_JULIA_V1      => h5write_julia,
#    :FORMAT_MATLAB_V73    => h5write_matlab,
#}

### Convenience wrappers ###
# These supply default values where possible
# See also the "special handling" section below
h5a_write(attr_id::Hid, mem_type_id::Hid, buf::ByteString) = h5a_write(attr_id, mem_type_id, buf.data)
function h5a_write{T<:HDF5BitsKind}(attr_id::Hid, mem_type_id::Hid, x::T)
    tmp = Array(T, 1)
    tmp[1] = x
    h5a_write(attr_id, mem_type_id, tmp)
end
h5a_create(loc_id::Hid, name::ByteString, type_id::Hid, space_id::Hid) = h5a_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT)
h5a_open(obj_id::Hid, name::ByteString) = h5a_open(obj_id, name, H5P_DEFAULT)
h5d_create(loc_id::Hid, name::ByteString, type_id::Hid, space_id::Hid) = h5d_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5d_open(obj_id::Hid, name::ByteString) = h5d_open(obj_id, name, H5P_DEFAULT)
h5d_read(dataset_id::Hid, datatype_id::Hid, buf::Array) = h5d_read(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
h5d_write(dataset_id::Hid, datatype_id::Hid, buf::Array) = h5d_write(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
h5d_write(dataset_id::Hid, datatype_id::Hid, buf::ByteString) = h5d_write(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf.data)
function h5d_write{T<:HDF5BitsKind}(dataset_id::Hid, datatype_id::Hid, x::T)
    tmp = Array(T, 1)
    tmp[1] = x
    h5d_write(dataset_id, datatype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, tmp)
end
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
     (:h5a_write, :H5Awrite, Herr, (Hid, Hid, Ptr{Void}), (:attr_hid, :mem_type_id, :buf), "Error writing attribute data"),
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
     (:h5p_set_userblock, :H5Pset_userblock, Herr, (Hid, Hsize), (:plist_id, :len), "Error setting userblock"),
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
     (:h5a_get_space, :H5Aget_space, Hid, (Hid,), (:attr_id,), :(error("Error getting attribute dataspace"))),
     (:h5a_get_type, :H5Aget_type, Hid, (Hid,), (:attr_id,), :(error("Error getting attribute type"))),
     (:h5a_open, :H5Aopen, Hid, (Hid, Ptr{Uint8}, Hid), (:obj_id, :name, :aapl_id), :(error("Error opening attribute ", name))),
     (:h5a_read, :H5Aread, Herr, (Hid, Hid, Ptr{Uint8}), (:attr_id, :mem_type_id, :buf), :(error("Error reading attribute"))),
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
     (:h5l_create_external, :H5Lcreate_hard_external, Herr, (Ptr{Uint8}, Ptr{Uint8}, Hid, Ptr{Uint8}, Hid, Hid), (:target_file_name, :target_obj_name, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name))),
     (:h5l_create_hard, :H5Lcreate_hard, Herr, (Hid, Ptr{Uint8}, Hid, Ptr{Uint8}, Hid, Hid), (:obj_loc_id, :obj_name, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating hard link ", link_name, " pointing to ", obj_name))),
     (:h5l_create_soft, :H5Lcreate_soft, Herr, (Ptr{Uint8}, Hid, Ptr{Uint8}, Hid, Hid), (:target_path, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating soft link ", link_name, " pointing to ", target_path))),
     (:h5l_exists, :H5Lexists, Htri, (Hid, Ptr{Uint8}, Hid), (:loc_id, :name, :lapl_id), :(error("Cannot determine whether link ", name, " exists, check each item along the path"))),
     (:h5l_get_info, :H5Lget_info, Herr, (Hid, Ptr{Uint8}, Ptr{Void}, Hid), (:link_loc_id, :link_name, :link_buf, :lapl_id), :(error("Error getting info for link ", link_name))),
     (:h5o_open, :H5Oopen, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :name, :lapl_id), :(error("Error opening object ", name))),
     (:h5p_create, :H5Pcreate, Hid, (Hid,), (:cls_id,), "Error creating property list"),
     (:h5p_get_chunk, :H5Pget_chunk, C_int, (Hid, C_int, Ptr{Hsize}), (:plist_id, :n_dims, :dims), :(error("Error getting chunk size"))),
     (:h5p_get_layout, :H5Pget_layout, C_int, (Hid,), (:plist_id,), :(error("Error getting layout"))),
     (:h5p_get_userblock, :H5Pget_layout, Herr, (Hid, Ptr{Hsize}), (:plist_id, :len), :(error("Error getting userblock"))),
     (:h5r_create, :H5Rcreate, Herr, (Ptr{Void}, Hid, Ptr{Uint8}, C_int), (:ref, :loc_id, :name, :ref_type, :space_id), :(error("Error creating reference to object ", name))),
     (:h5r_dereference, :H5Rdereference, Hid, (Hid, C_int, Ptr{Void}), (:obj_id, :ref_type, :ref), :(error("Error dereferencing object"))),
     (:h5r_get_obj_type, :H5Rget_obj_type2, Herr, (Hid, C_int, Ptr{Void}, Ptr{C_int}), (:loc_id, :ref_type, :ref, :obj_type), :(error("Error getting object type"))),
     (:h5r_get_region, :H5Rget_region, Hid, (Hid, C_int, Ptr{Void}), (:loc_id, :ref_type, :ref), :(error("Error getting region from reference"))),
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
function h5l_get_info(link_loc_id::Hid, link_name::ByteString, lapl_id::Hid)
    io = IOString()
    i = H5LInfo()
    pack(io, i)
    h5l_get_info(link_loc_id, link_name, io.data, lapl_id)
    seek(io, 0)
    unpack(io, H5LInfo)
end


### Property functions get/set pairs ###
const hdf5_prop_get_set = {
    "chunk"         => (get_chunk, set_chunk),
    "compress"      => (nothing, h5p_set_deflate),
    "deflate"       => (nothing, h5p_set_deflate),
    "layout"        => (h5p_get_layout, h5p_set_layout),
    "userblock"     => (get_userblock, h5p_set_userblock),
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
    HDF5Datatype,
    HDF5Dataspace,
    HDF5Properties,
    # Functions
    attribute,
    close,
    create,
    dataset,
    datatype,
    exists,
    group,
    h5open,
    properties,
    read,
    ref,
    root,
    write

#  end  # module
