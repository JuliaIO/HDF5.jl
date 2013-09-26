####################
## HDF5 interface ##
####################

module HDF5

## Add methods to...
import Base: close, convert, done, dump, endof, flush, getindex, has, isempty, isvalid, length, names, ndims, next, read, setindex!, show, size, start, write

## C types
typealias C_time_t Int

## HDF5 types and constants
typealias Hid         Cint
typealias Herr        Cint
typealias Hsize       Uint64
typealias Hssize      Int64
typealias Htri        Cint   # pseudo-boolean (negative if error)
typealias Haddr       Uint64

### Load and initialize the HDF library ###
libname = "libhdf5"
@unix_only const libhdf5 = dlopen(libname)
@windows_only begin
function findlibhdf5()    
    spaths = split(ENV["SYS_PATH"], ";")
    libfile = ""
    for p in spaths
        if !isempty(search(p, "HDF5"))
            dl = dlopen_e(joinpath(p,"hdf5.dll"))
            if dl != C_NULL
                ccall(:add_library_mapping,Cint,(Ptr{Cchar},Ptr{Void}),libname,dl)
                return dl
            end
        end
    end
    error("Library not found. See the README for installation instructions.")
end
const libhdf5 = findlibhdf5()
end

status = ccall(dlsym(libhdf5, :H5open), Herr, ())
if status < 0
    error("Can't initialize the HDF5 library")
end

# Function to extract exported library constants
# Kudos to the library developers for making these available this way!
read_const(sym::Symbol) = unsafe_load(convert(Ptr{Cint}, dlsym(libhdf5, sym)))

# iteration order constants
const H5_ITER_UNKNOWN = -1 
const H5_ITER_INC     = 0
const H5_ITER_DEC     = 1
const H5_ITER_NATIVE  = 2
const H5_ITER_N       = 3
# indexing type constants
const H5_INDEX_UNKNOWN   = -1
const H5_INDEX_NAME      = 0
const H5_INDEX_CRT_ORDER = 1
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
const H5F_SCOPE_LOCAL   = 0
const H5F_SCOPE_GLOBAL  = 1
const H5F_CLOSE_DEFAULT = 0
const H5F_CLOSE_WEAK    = 1
const H5F_CLOSE_SEMI    = 2
const H5F_CLOSE_STRONG  = 3
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
const H5R_OBJECT         = 0
const H5R_DATASET_REGION = 1
const H5R_OBJ_REF_BUF_SIZE      = 8
const H5R_DSET_REG_REF_BUF_SIZE = 12
# Dataspace constants
const H5S_ALL          = 0
const H5S_SCALAR       = 0
const H5S_SIMPLE       = 1
const H5S_NULL         = 2
const H5S_UNLIMITED    = typemax(Hsize)
const MAXIMUM_DIM = H5S_UNLIMITED
# Dataspace selection constants
const H5S_SELECT_SET   = 0
const H5S_SELECT_OR    = 1
const H5S_SELECT_AND   = 2
const H5S_SELECT_XOR   = 3
const H5S_SELECT_NOTB  = 4
const H5S_SELECT_NOTA  = 5
const H5S_SELECT_APPEND  = 6
const H5S_SELECT_PREPEND = 7
# type classes (C enum H5T_class_t)
const H5T_INTEGER      = convert(Hid, 0)
const H5T_FLOAT        = convert(Hid, 1)
const H5T_TIME         = convert(Hid, 2)  # not supported by HDF5 library
const H5T_STRING       = convert(Hid, 3)
const H5T_BITFIELD     = convert(Hid, 4)
const H5T_OPAQUE       = convert(Hid, 5)
const H5T_COMPOUND     = convert(Hid, 6)
const H5T_REFERENCE    = convert(Hid, 7)
const H5T_ENUM         = convert(Hid, 8)
const H5T_VLEN         = convert(Hid, 9)
const H5T_ARRAY        = convert(Hid, 10)
# Character types
const H5T_CSET_ASCII   = 0
const H5T_CSET_UTF8    = 1
# Sign types (C enum H5T_sign_t)
const H5T_SGN_NONE     = convert(Cint, 0)  # unsigned
const H5T_SGN_2        = convert(Cint, 1)  # 2's complement
# Search directions
const H5T_DIR_ASCEND   = 1
const H5T_DIR_DESCEND  = 2
# String padding modes
const H5T_STR_NULLTERM = 0
const H5T_STR_NULLPAD  = 1
const H5T_STR_SPACEPAD = 2
# Other type constants
const H5T_VARIABLE     = -1
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


## Conversion between Julia types and HDF5 atomic types
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

typealias HDF5BitsKind Union(Int8, Uint8, Int16, Uint16, Int32, Uint32, Int64, Uint64, Float32, Float64)
typealias BitsKindOrByteString Union(HDF5BitsKind, ByteString)

# It's not safe to use particular id codes because these can change, so we use characteristics of the type.
const hdf5_type_map = {
    (H5T_INTEGER, H5T_SGN_2, convert(Csize_t, 1)) => Int8,
    (H5T_INTEGER, H5T_SGN_2, convert(Csize_t, 2)) => Int16,
    (H5T_INTEGER, H5T_SGN_2, convert(Csize_t, 4)) => Int32,
    (H5T_INTEGER, H5T_SGN_2, convert(Csize_t, 8)) => Int64,
    (H5T_INTEGER, H5T_SGN_NONE, convert(Csize_t, 1)) => Uint8,
    (H5T_INTEGER, H5T_SGN_NONE, convert(Csize_t, 2)) => Uint16,
    (H5T_INTEGER, H5T_SGN_NONE, convert(Csize_t, 4)) => Uint32,
    (H5T_INTEGER, H5T_SGN_NONE, convert(Csize_t, 8)) => Uint64,
    (H5T_FLOAT, nothing, convert(Csize_t, 4)) => Float32,
    (H5T_FLOAT, nothing, convert(Csize_t, 8)) => Float64,
}

hdf5_type_id{S<:String}(::Type{S})  = H5T_C_S1

# Single character types
# These are needed to safely handle VLEN objects
abstract CharType <: String
type ASCIIChar<:CharType
    c::Uint8
end
length(c::ASCIIChar) = 1
type UTF8Char<:CharType
    c::Uint8
end
length(c::UTF8Char) = 1
chartype(::Type{ASCIIString}) = ASCIIChar
chartype(::Type{UTF8String})  = UTF8Char
stringtype(::Type{ASCIIChar}) = ASCIIString
stringtype(::Type{UTF8Char})  = UTF8String

cset(::Type{ASCIIString}) = H5T_CSET_ASCII
cset(::Type{ASCIIChar})   = H5T_CSET_ASCII
cset(::Type{UTF8String})  = H5T_CSET_UTF8
cset(::Type{UTF8Char})    = H5T_CSET_UTF8
cset(::Type{ByteString})  = H5T_CSET_UTF8

hdf5_type_id{C<:CharType}(::Type{C})  = H5T_C_S1

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
type HDF5File
    id::Hid
    filename::String

    function HDF5File(id, filename)
        f = new(id, filename)
        finalizer(f, close)
        f
    end
end
convert(::Type{Cint}, f::HDF5File) = f.id
show(io::IO, fid::HDF5File) = isvalid(fid) ? print(io, "HDF5 data file: ", fid.filename) : print(io, "Closed HFD5 data file: ", fid.filename)

type HDF5Group
    id::Hid
    file::HDF5File         # the parent file

    function HDF5Group(id, file)
        g = new(id, file)
        finalizer(g, close)
        g
    end
end
convert(::Type{Cint}, g::HDF5Group) = g.id
show(io::IO, g::HDF5Group) = isvalid(g) ? print(io, "HDF5 group: ", name(g), " (file: ", g.file.filename, ")") : print(io, "HDF5 group (invalid)")

type HDF5Dataset
    id::Hid
    file::HDF5File
    
    function HDF5Dataset(id, file)
        dset = new(id, file)
        finalizer(dset, close)
        dset
    end
end
convert(::Type{Cint}, dset::HDF5Dataset) = dset.id
show(io::IO, dset::HDF5Dataset) = isvalid(dset) ? print(io, "HDF5 dataset: ", name(dset), " (file: ", dset.file.filename, ")") : print(io, "HDF5 dataset (invalid)")

type HDF5Datatype
    id::Hid
    toclose::Bool

    function HDF5Datatype(id, toclose::Bool=false)
        nt = new(id)
        if toclose
            finalizer(nt, close)
        end
        nt
    end
end
convert(::Type{Cint}, dtype::HDF5Datatype) = dtype.id
show(io::IO, dtype::HDF5Datatype) = print(io, "HDF5 datatype ", dtype.id) # TODO: compound datatypes?

# Define an H5O Object type
typealias HDF5Object Union(HDF5Group, HDF5Dataset, HDF5Datatype)

type HDF5Dataspace
    id::Hid

    function HDF5Dataspace(id)
        dspace = new(id)
        finalizer(dspace, close)
        dspace
    end
end
convert(::Type{Cint}, dspace::HDF5Dataspace) = dspace.id

type HDF5Attribute
    id::Hid
    file::HDF5File
    
    function HDF5Attribute(id, file)
        dset = new(id, file)
        finalizer(dset, close)
        dset
    end
end
convert(::Type{Cint}, attr::HDF5Attribute) = attr.id
show(io::IO, attr::HDF5Attribute) = isvalid(attr) ? print(io, "HDF5 attribute: ", name(attr)) : print(io, "HDF5 attribute (invalid)")

type HDF5Attributes
    parent::Union(HDF5File, HDF5Group, HDF5Dataset)
end
attrs(p::Union(HDF5File, HDF5Group, HDF5Dataset)) = HDF5Attributes(p)

type HDF5Properties
    id::Hid

    function HDF5Properties(id)
        p = new(id)
        finalizer(p, close)
        p
    end
end
HDF5Properties() = HDF5Properties(H5P_DEFAULT)
convert(::Type{Cint}, p::HDF5Properties) = p.id

# Object reference types
immutable HDF5ReferenceObj
    r::Uint64 # Size must be H5R_OBJ_REF_BUF_SIZE
end
const HDF5ReferenceObj_NULL = HDF5ReferenceObj(uint64(0))
function HDF5ReferenceObj(parent::Union(HDF5File, HDF5Group, HDF5Dataset), name::ASCIIString)
    a = Array(HDF5ReferenceObj, 1)
    h5r_create(a, checkvalid(parent).id, name, H5R_OBJECT, -1)
    a[1]
end

# Compound types
# These are "raw" and not mapped to any Julia type
type HDF5Compound
    data::Array{Uint8}
    membertype::Vector{Type}
    membername::Vector{ASCIIString}
    memberoffset::Vector{Uint}
end

# Opaque types
type HDF5Opaque
    data
    tag::ASCIIString
end

# An empty array type
type EmptyArray{T}; end

# VLEN objects
type HDF5Vlen{T}
    data
end
HDF5Vlen{S<:ByteString}(strs::Array{S}) = HDF5Vlen{chartype(S)}(strs)
HDF5Vlen{T<:HDF5BitsKind}(A::Array{Array{T}}) = HDF5Vlen{T}(A)

## Types that correspond to C structs and get used for ccall
# For VLEN
immutable Hvl_t
    len::Csize_t
    p::Ptr{Void}
end
const HVL_SIZE = sizeof(Hvl_t) # and determine the size of the buffer needed
function vlenpack{T<:Union(HDF5BitsKind,CharType)}(v::HDF5Vlen{T})
    len = length(v.data)
    Tp = t2p(T)  # Ptr{Uint8} or Ptr{T}
    h = Array(Hvl_t, len)
    for i = 1:len
        h[i] = Hvl_t(convert(Csize_t, length(v.data[i])), convert(Ptr{Void}, convert(Tp, v.data[i])))
    end
    h
end

# For group information
immutable H5Ginfo
    storage_type::Cint
    nlinks::Hsize
    max_corder::Int64
    mounted::Cint
end

# For objects
immutable Hmetainfo
    index_size::Hsize
    heap_size::Hsize
end
immutable H5Oinfo
    fileno::Cuint
    addr::Hsize
    otype::Cint
    rc::Cuint
    atime::C_time_t
    mtime::C_time_t
    ctime::C_time_t
    btime::C_time_t
    num_attrs::Hsize
    version::Cuint
    nmesgs::Cuint
    nchunks::Cuint
    flags::Cuint
    total::Hsize
    meta::Hsize
    mesg::Hsize
    free::Hsize
    present::Uint64
    shared::Uint64
    meta_obj::Hmetainfo
    meta_attr::Hmetainfo
end
# For links
immutable H5LInfo
    linktype::Cint
    corder_valid::Cuint
    corder::Int64
    cset::Cint
    u::Uint64
end


### High-level interface ###
# Open or create an HDF5 file
function h5open(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end
    pa = p_create(H5P_FILE_ACCESS)
    pa["fclose_degree"] = H5F_CLOSE_STRONG
    if cr && (tr || !isfile(filename))
        fid = h5f_create(filename, H5F_ACC_TRUNC, H5P_DEFAULT, pa.id)
        close(pa)
    else
        if !h5f_is_hdf5(filename)
            error("This does not appear to be an HDF5 file")
        end
        fid = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY, pa.id)
    end
    close(pa)
    HDF5File(fid, filename)
end

function h5open(filename::String, mode::String="r")
    mode == "r"  ? h5open(filename, true,  false, false, false, false) :
    mode == "r+" ? h5open(filename, true,  true , false, false, true)  :
    mode == "w"  ? h5open(filename, false, true , true , true,  false)  :
#     mode == "w+" ? h5open(filename, true,  true , true , true,  false)  :
#     mode == "a"  ? h5open(filename, true,  true , true , true,  true)   :
    error("invalid open mode: ", mode)
end
function h5open(f::Function, args...)
    fid = h5open(args...)
    try
        f(fid)
    finally
        close(fid)
    end
end

# Ensure that objects haven't been closed
isvalid(obj::Union(HDF5File, HDF5Properties, HDF5Datatype, HDF5Dataspace)) = obj.id != -1 && h5i_is_valid(obj.id)
isvalid(obj::Union(HDF5Group, HDF5Dataset, HDF5Attribute)) = obj.id != -1 && obj.file.id != -1 && h5i_is_valid(obj.id)
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Close functions
for (h5type, h5func) in
    ((:HDF5File, :h5f_close),
     (:HDF5Properties, :h5p_close))
    # Close functions that should try calling close regardless
    @eval begin
        function close(obj::$h5type)
            if obj.id != -1
                $h5func(obj.id)
                obj.id = -1
            end
            nothing
        end
    end
end

for (h5type, h5func) in 
    ((:(Union(HDF5Group, HDF5Dataset)), :h5o_close),
     (:HDF5Attribute, :h5a_close))
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

function close(obj::HDF5Datatype)
    if obj.toclose && obj.id != -1
        if isvalid(obj)
            h5o_close(obj.id)
        end
        obj.id = -1
    end
    nothing
end

function close(obj::HDF5Dataspace)
    if obj.id != -1
        if isvalid(obj)
            h5s_close(obj.id)
        end
        obj.id = -1
    end
    nothing
end

# Testing file type
ishdf5(name::String) = h5f_is_hdf5(name)

# Extract the file
file(f::HDF5File) = f
file(g::HDF5Group) = g.file
file(dset::HDF5Dataset) = dset.file
fd(obj::HDF5Object) = h5i_get_file_id(checkvalid(obj).id)

# Flush buffers
flush(f::Union(HDF5Object, HDF5Attribute, HDF5Datatype), scope) = h5f_flush(checkvalid(f).id, scope)
flush(f::Union(HDF5Object, HDF5Attribute, HDF5Datatype)) = flush(f, H5F_SCOPE_GLOBAL)

# Open objects
g_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString) = HDF5Group(h5g_open(checkvalid(parent).id, name, H5P_DEFAULT), file(parent))
d_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString, apl::HDF5Properties) = HDF5Dataset(h5d_open(checkvalid(parent).id, name, apl.id), file(parent))
d_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString) = HDF5Dataset(h5d_open(checkvalid(parent).id, name, H5P_DEFAULT), file(parent))
t_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString, apl::HDF5Properties) = HDF5Datatype(h5t_open(checkvalid(parent).id, name, apl.id))
t_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString) = HDF5Datatype(h5t_open(checkvalid(parent).id, name, H5P_DEFAULT))
a_open(parent::Union(HDF5File, HDF5Object), name::ASCIIString) = HDF5Attribute(h5a_open(checkvalid(parent).id, name, H5P_DEFAULT), file(parent))
# Object (group, named datatype, or dataset) open
function h5object(obj_id::Hid, parent)
    obj_type = h5i_get_type(obj_id)
    obj_type == H5I_GROUP ? HDF5Group(obj_id, file(parent)) :
    obj_type == H5I_DATATYPE ? HDF5Datatype(obj_id) :
    obj_type == H5I_DATASET ? HDF5Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
o_open(parent, path::ASCIIString) = h5object(h5o_open(checkvalid(parent).id, path), parent)
# Get the root group
root(h5file::HDF5File) = g_open(h5file, "/")
root(obj::Union(HDF5Group, HDF5Dataset)) = g_open(file(obj), "/")
# getindex syntax: obj2 = obj1[path]
getindex(parent::Union(HDF5File, HDF5Group), path::ASCIIString) = o_open(parent, path)
getindex(dset::HDF5Dataset, name::ASCIIString) = a_open(dset, name)
getindex(x::HDF5Attributes, name::ASCIIString) = a_open(x.parent, name)

# Path manipulation
function joinpathh5(a::ASCIIString, b::ASCIIString)
    isempty(a) && return b
    isempty(b) && return a
    ae = a[end]
    b1 = b[1]
    ae == "/" && b1 == "/" && return a[1:end-1]*b
    (ae== "/" || b1 == "/") && return a*b
    return a*"/"*b
end
joinpathh5(a::ASCIIString, b::ASCIIString, c::ASCIIString) = joinpathh5(joinpathh5(a, b), c)

function split1(path::ASCIIString)
    m = match(r"/", path)
    if m == nothing
        return path, nothing
    else
        if m.offset == 1
            # Matches the root group
            return "/", path[2:end]
        else
            return path[1:m.offset-1], path[m.offset+1:end]
        end
    end
end

# Create objects
function parents_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, args...)
    g = split(path, "/")
    if isempty(g[1])
        g[1] = "/"
    end
    keepflag = Bool[!isempty(x) for x in g]
    g = g[keepflag]   # NOTE: performance bottleneck up to here; find a better way
    for i = 1:length(g)-1
        if !exists(parent, g[i])
            g_create(parent, g[i])
        end
        parent = g_open(parent, g[i])
    end
    tuple(parent.id, g[end], args...)
end        
g_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, lcpl::HDF5Properties, dcpl::HDF5Properties) = HDF5Group(h5g_create(parents_create(checkvalid(parent), path, lcpl.id, dcpl.id)...), file(parent))
g_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, lcpl::HDF5Properties) = HDF5Group(h5g_create(parents_create(checkvalid(parent), path, lcpl.id, H5P_DEFAULT)...), file(parent))
g_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString) = HDF5Group(h5g_create(parents_create(checkvalid(parent), path, H5P_DEFAULT, H5P_DEFAULT)...), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties, dapl::HDF5Properties) = HDF5Dataset(h5d_create(parents_create(checkvalid(parent), path, dtype.id, dspace.id, lcpl.id, dcpl.id, dapl.id)...), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties) = HDF5Dataset(h5d_create(parents_create(checkvalid(parent), path, dtype.id, dspace.id, lcpl.id, dcpl.id, H5P_DEFAULT)...), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace::HDF5Dataspace, lcpl::HDF5Properties) = HDF5Dataset(h5d_create(parents_create(checkvalid(parent), path, dtype.id, dspace.id, lcpl.id, H5P_DEFAULT, H5P_DEFAULT)...), file(parent))
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace::HDF5Dataspace) = HDF5Dataset(h5d_create(parents_create(checkvalid(parent), path, dtype.id, dspace.id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)...), file(parent))
# Setting dset creation properties with name/value pairs
function d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace::HDF5Dataspace, prop1::ASCIIString, val1, pv...)
    if !iseven(length(pv))
        error("Properties and values must come in pairs")
    end
    p = p_create(H5P_DATASET_CREATE)
    p[prop1] = val1
    for i = 1:2:length(pv)
        thisname = pv[i]
        if !isa(thisname, ASCIIString)
            error("Argument ", i+3, " should be a string, but it's a ", typeof(thisname))
        end
        p[thisname] = pv[i+1]
    end
    HDF5Dataset(h5d_create(parents_create(checkvalid(parent), path, dtype.id, dspace.id, H5P_DEFAULT, p.id, H5P_DEFAULT)...), file(parent))
end
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace_dims::Dims, prop1::ASCIIString, val1, pv...) = d_create(checkvalid(parent), path, dtype, dataspace(dspace_dims), prop1, val1, pv...)
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, dspace_dims::(Dims,Dims), prop1::ASCIIString, val1, pv...) = d_create(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]), prop1, val1, pv...)
d_create(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::Type, dspace_dims, prop1::ASCIIString, val1, pv...) = d_create(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]), prop1, val1, pv...)
# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
t_create(class_id, sz) = HDF5Datatype(h5t_create(class_id, sz))
function t_commit(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, lcpl::HDF5Properties, tcpl::HDF5Properties, tapl::HDF5Properties)
    h5t_commit(checkvalid(parent).id, path, dtype.id, lcpl.id, tcpl.id, tapl.id)
    dtype
end
function t_commit(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, lcpl::HDF5Properties, tcpl::HDF5Properties)
    h5t_commit(checkvalid(parent).id, path, dtype.id, lcpl.id, tcpl.id, H5P_DEFAULT)
    dtype
end
function t_commit(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype, lcpl::HDF5Properties)
    h5t_commit(checkvalid(parent).id, path, dtype.id, lcpl.id, H5P_DEFAULT, H5P_DEFAULT)
    dtype
end
function t_commit(parent::Union(HDF5File, HDF5Group), path::ASCIIString, dtype::HDF5Datatype)
    h5t_commit(checkvalid(parent).id, path, dtype.id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
    dtype
end
a_create(parent::Union(HDF5File, HDF5Object), path::ASCIIString, dtype::HDF5Datatype, dspace::HDF5Dataspace) = HDF5Attribute(h5a_create(checkvalid(parent).id, path, dtype.id, dspace.id), file(parent))
p_create(class) = HDF5Properties(h5p_create(class))

# Delete objects
a_delete(parent::Union(HDF5File, HDF5Object), path::ASCIIString) = h5a_delete(checkvalid(parent).id, path)
o_delete(parent::Union(HDF5File, HDF5Group), path::ASCIIString, lapl::HDF5Properties) = h5l_delete(checkvalid(parent).id, path, lapl.id)
o_delete(parent::Union(HDF5File, HDF5Group), path::ASCIIString) = h5l_delete(checkvalid(parent).id, path, H5P_DEFAULT)

# Assign syntax: obj[path] = value
# Creates a dataset unless obj is a dataset, in which case it creates an attribute
setindex!(parent::Union(HDF5File, HDF5Group), val, path::ASCIIString) = write(parent, path, val)
setindex!(dset::HDF5Dataset, val, name::ASCIIString) = a_write(dset, name, val)
setindex!(x::HDF5Attributes, val, name::ASCIIString) = a_write(x.parent, name, val)
# Getting and setting properties: p["chunk"] = dims, p["compress"] = 6
function setindex!(p::HDF5Properties, val, name::ASCIIString)
    funcget, funcset = hdf5_prop_get_set[name]
    funcset(p, val...)
    return p
end
# Create a dataset with properties: obj[path, prop1, set1, ...] = val
function setindex!(parent::Union(HDF5File, HDF5Group), val, path::ASCIIString, prop1::ASCIIString, val1, pv...)
    if !iseven(length(pv))
        error("Properties and values must come in pairs")
    end
    p = p_create(H5P_DATASET_CREATE)
    p[prop1] = val1
    for i = 1:2:length(pv)
        thisname = pv[i]
        if !isa(thisname, ASCIIString)
            error("Argument ", i+3, " should be a string, but it's a ", typeof(thisname))
        end
        p[thisname] = pv[i+1]
    end
    write(parent, path, val, HDF5Properties(), p)
end

# Check existence
function exists(parent::Union(HDF5File, HDF5Group), path::ASCIIString, lapl::HDF5Properties)
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !h5l_exists(parent.id, first, lapl.id)
        return false
    end
    ret = true
    if !(rest === nothing) && !isempty(rest)
        obj = parent[first]
        ret = exists(obj, rest, lapl)
        close(obj)
    end
    ret
end
exists(attr::HDF5Attributes, path::ASCIIString) = h5a_exists(checkvalid(attr.parent).id, path)
exists(dset::HDF5Dataset, path::ASCIIString) = h5a_exists(checkvalid(dset).id, path)
exists(parent::Union(HDF5File, HDF5Group), path::ASCIIString) = exists(parent, path, HDF5Properties())
has(parent::Union(HDF5File, HDF5Group, HDF5Dataset), path::ASCIIString) = exists(parent, path)

# Querying items in the file
function info(obj::Union(HDF5Group,HDF5File))
    info = Array(H5Ginfo, 1)
    h5g_get_info(obj, info)
    info[1]
end
function objinfo(obj::Union(HDF5File, HDF5Object))
    info = Array(H5Oinfo, 1)
    h5o_get_info(obj.id, info)
    info[1]
end
function length(x::Union(HDF5Group,HDF5File))
    buf = [int32(0)]
    h5g_get_num_objs(x.id, buf)
    buf[1]
end
function length(x::HDF5Attributes)
    objinfo(x.parent).num_attrs
end

isempty(x::Union(HDF5Group,HDF5File)) = length(x) == 0
function size(obj::Union(HDF5Dataset, HDF5Attribute))
    dspace = dataspace(obj)
    dims, maxdims = get_dims(dspace)
    close(dspace)
    map(int, dims)
end
size(dset::Union(HDF5Dataset, HDF5Attribute), d) = d > ndims(dset) ? 1 : size(dset)[d]
length(dset::Union(HDF5Dataset, HDF5Attribute)) = prod(size(dset))
ndims(dset::Union(HDF5Dataset, HDF5Attribute)) = length(size(dset))

# filename and name
filename(obj::Union(HDF5File, HDF5Group, HDF5Dataset, HDF5Attribute, HDF5Datatype)) = h5f_get_name(checkvalid(obj).id)
name(obj::Union(HDF5File, HDF5Group, HDF5Dataset, HDF5Datatype)) = h5i_get_name(checkvalid(obj).id)
name(attr::HDF5Attribute) = h5a_get_name(attr.id)
function names(x::Union(HDF5Group,HDF5File))
    checkvalid(x)
    n = length(x)
    res = Array(ASCIIString, n)
    for i in 1:n
        len = h5g_get_objname_by_idx(x.id, i - 1, "", 0)
        buf = Array(Uint8, len+1)
        len = h5g_get_objname_by_idx(x.id, i - 1, buf, len+1)
        res[i] = convert(ASCIIString, buf[1:len])
    end
    res
end

function names(x::HDF5Attributes)
    checkvalid(x.parent)
    n = length(x)
    res = Array(ASCIIString, n)
    for i in 1:n
        len = h5a_get_name_by_idx(x.parent.id, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, "", 0, H5P_DEFAULT)
        buf = Array(Uint8, len+1)
        len = h5a_get_name_by_idx(x.parent.id, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, buf, len+1, H5P_DEFAULT)
        res[i] = convert(ASCIIString, buf[1:len])
    end
    res
end

# iteration by objects
# "next" opens new objects, "done" closes the old one. This prevents resource leaks.
start(parent::Union(HDF5File, HDF5Group)) = Any[1, nothing]
function done(parent::Union(HDF5File, HDF5Group), iter::Array{Any})
    obj = iter[2]
    if !(obj === nothing)
        close(obj)
    end
    iter[1] > length(parent)
end
function next(parent::Union(HDF5File, HDF5Group), iter)
    iter[2] = h5object(h5o_open_by_idx(checkvalid(parent).id, ".", H5_INDEX_NAME, H5_ITER_INC, iter[1]-1, H5P_DEFAULT), parent)
    iter[1] += 1
    (iter[2], iter)
end

endof(dset::HDF5Dataset) = length(dset)

function parent(obj::Union(HDF5File, HDF5Group, HDF5Dataset))
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

# It would also be nice to print the first few elements.
# FIXME: strings and array of variable-length strings
function dump(io::IO, x::HDF5Dataset, n::Int, indent)
    sz = size(x)
    print(io, "HDF5Dataset $sz : ")
    isempty(sz) || prod(sz) == 1 ? print(io, read(x)) :
    # the following is a bit kludgy, but there's no way to do x[1:3] for the multidimensional case
    length(sz) == 1 ? Base.show_delim_array(io, x[1:min(5,size(x)[1])], '[', ',', ' ', true) :
    length(sz) == 2 ? Base.show_delim_array(io, x[1,1:min(5,size(x)[2])], '[', ',', ' ', true) : ""
    println(io,)
end
function dump(io::IO, x::Union(HDF5File, HDF5Group), n::Int, indent)
    println(typeof(x), " len ", length(x))
    if n > 0
        i = 1
        for k in names(x)
            print(io, indent, "  ", k, ": ")
            v = o_open(x, k)
            dump(io, v, n - 1, strcat(indent, "  "))
            close(v)
            if i > 10
                println(io, indent, "  ...")
                break
            end
            i += 1
        end
    end
end

# Get the datatype of a dataset
datatype(dset::HDF5Dataset) = HDF5Datatype(h5d_get_type(checkvalid(dset).id))
# Get the datatype of an attribute
datatype(dset::HDF5Attribute) = HDF5Datatype(h5a_get_type(checkvalid(dset).id))

# Create a datatype from in-memory types
datatype{T<:HDF5BitsKind}(x::T) = HDF5Datatype(hdf5_type_id(T), false)
datatype{T<:HDF5BitsKind}(::Type{T}) = HDF5Datatype(hdf5_type_id(T), false)
datatype{T<:HDF5BitsKind}(A::Array{T}) = HDF5Datatype(hdf5_type_id(T), false)
function datatype{S<:ByteString}(str::S)
    type_id = h5t_copy(hdf5_type_id(S))
    h5t_set_size(type_id, max(length(str.data), 1))
    h5t_set_cset(type_id, cset(S))
    HDF5Datatype(type_id)
end
function datatype{S<:ByteString}(str::Array{S})
    type_id = h5t_copy(hdf5_type_id(S))
    h5t_set_size(type_id, H5T_VARIABLE)
    h5t_set_cset(type_id, cset(S))
    HDF5Datatype(type_id)
end
datatype(R::Array{HDF5ReferenceObj}) = HDF5Datatype(H5T_STD_REF_OBJ, false)
datatype{T<:HDF5BitsKind}(A::HDF5Vlen{T}) = HDF5Datatype(h5t_vlen_create(hdf5_type_id(T)))
function datatype{C<:CharType}(str::HDF5Vlen{C})
    type_id = h5t_copy(hdf5_type_id(C))
    h5t_set_size(type_id, 1)
    h5t_set_cset(type_id, cset(C))
    HDF5Datatype(h5t_vlen_create(type_id))
end

# Get the dataspace of a dataset
dataspace(dset::HDF5Dataset) = HDF5Dataspace(h5d_get_space(checkvalid(dset).id))
# Get the dataspace of an attribute
dataspace(attr::HDF5Attribute) = HDF5Dataspace(h5a_get_space(checkvalid(attr).id))

# Create a dataspace from in-memory types
dataspace{T<:HDF5BitsKind}(x::T) = HDF5Dataspace(h5s_create(H5S_SCALAR))
function _dataspace(sz::Int...; max_dims::Union(Dims, ())  = ())
    dims = convert(Array{Hsize, 1}, [reverse(sz)...])
    if any(dims .== 0)
        space_id = h5s_create(H5S_NULL)
    else
        if max_dims  == ()
            space_id = h5s_create_simple(length(dims), dims, dims)
        else
            space_id = h5s_create_simple(length(dims), dims, convert(Array{Hsize, 1},[reverse(max_dims)...]))
        end
    end
    HDF5Dataspace(space_id)
end
dataspace(A::Array; max_dims::Union(Dims, ())  = ()) = _dataspace(size(A)..., max_dims=max_dims)
dataspace(str::ByteString) = HDF5Dataspace(h5s_create(H5S_SCALAR))
dataspace(R::Array{HDF5ReferenceObj}; max_dims::Union(Dims, ())  = ()) = _dataspace(size(R)..., max_dims=max_dims)
dataspace(v::HDF5Vlen; max_dims::Union(Dims, ())  = ()) = _dataspace(size(v.data)..., max_dims=max_dims)
dataspace(n::Nothing) = HDF5Dataspace(h5s_create(H5S_NULL))
dataspace(sz::Dims; max_dims::Union(Dims, ())  = ()) = _dataspace(sz..., max_dims=max_dims)
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union(Dims, ())  = ()) = _dataspace(sz1, sz2, sz3..., max_dims=max_dims)

# Get the array dimensions from a dataspace or a dataset
# Returns both dims and maxdims
get_dims(dspace::HDF5Dataspace) = h5s_get_simple_extent_dims(dspace.id)
get_dims(dset::HDF5Dataset) = get_dims(dataspace(checkvalid(dset)))

# change the current dimensions of a dataset, new_dims fit in max_dims = get_dims(dset)[2]
# reduction is possible, and leads to loss of truncated data
set_dims!(dset::HDF5Dataset, new_dims::Dims) = h5d_set_extent(checkvalid(dset), [reverse(new_dims)...])

# Convenience macros
macro read(fid, sym)
    if !isa(sym, Symbol)
        error("Second input to @read must be a symbol (i.e., a variable)")
    end
    esc(:($sym = read($fid, $(string(sym)))))
end
macro write(fid, sym)
    if !isa(sym, Symbol)
        error("Second input to @write must be a symbol (i.e., a variable)")
    end
    esc(:(write($fid, $(string(sym)), $sym)))
end

# Generic read functions
for (fsym, osym, ptype) in
    ((:d_read, :d_open, Union(HDF5File, HDF5Group)),
     (:a_read, :a_open, Union(HDF5File, HDF5Group, HDF5Dataset)))
    @eval begin
        function ($fsym)(parent::$ptype, name::ASCIIString)
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
function read(parent::Union(HDF5File, HDF5Group), name::ASCIIString)
    obj = o_open(parent, name)
    val = read(obj)
    close(obj)
    val
end
# Read a list of variables, read(parent, "A", "B", "x", ...)
function read(parent::Union(HDF5File, HDF5Group), name::ASCIIString...)
    n = length(name)
    out = Array(Any, n)
    for i = 1:n
        out[i] = read(parent, name[i])
    end
    return tuple(out...)
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5Datatype. Specific file formats should provide their own read(dset).
typealias DatasetOrAttribute Union(HDF5Dataset, HDF5Attribute)
function read(obj::DatasetOrAttribute)
    local T
    T = hdf5_to_julia(obj)
    read(obj, T)
end
# Read scalars (BitsKind only)
function read{T<:HDF5BitsKind}(obj::DatasetOrAttribute, ::Type{T})
    x = read(obj, Array{T})
    x[1]
end
# Read array of BitsKind
function read{T<:HDF5BitsKind}(obj::DatasetOrAttribute, ::Type{Array{T}})
    local data
    dims = size(obj)
    dspace = dataspace(obj)
    data = Array(T, dims...)
    readarray(obj, hdf5_type_id(T), data)
    data
end
# Empty arrays
function read{T<:BitsKindOrByteString}(obj::DatasetOrAttribute, ::Type{EmptyArray{T}})
    Array(T, 0)
end

# Clean up string buffer according to padding mode
function unpad(s::ByteString, pad::Cint)
    if pad == H5T_STR_NULLTERM
        v = search(s, '\0')
        v == 0 ? s : s[1:v-1]
    elseif pad == H5T_STR_NULLPAD
        rstrip(s, '\0')
    elseif pad == H5T_STR_SPACEPAD
        rstrip(s, ' ')
    else
        error("Unrecognized string padding mode $pad")
    end
end
# Read string
function read{S<:ByteString}(obj::DatasetOrAttribute, ::Type{S})
    local ret::S
    objtype = datatype(obj)
    try
        n = h5t_get_size(objtype.id)
        pad = h5t_get_strpad(objtype.id)
        buf = Array(Uint8, n)
        readarray(obj, objtype.id, buf)
        ret = unpad(convert(S, buf), pad)
    finally
        close(objtype)
    end
    ret
end
read{S<:CharType}(obj::DatasetOrAttribute, ::Type{S}) = read(obj, stringtype(S))
# Read array of strings
function read{S<:ByteString}(obj::DatasetOrAttribute, ::Type{Array{S}})
    local isvar::Bool
    local ret::Array{S}
    sz = size(obj)
    len = prod(sz)
    objtype = datatype(obj)
    try
        isvar = h5t_is_variable_str(objtype.id)
        ilen = int(h5t_get_size(objtype.id))
    finally
        close(objtype)
    end
    memtype_id = h5t_copy(H5T_C_S1)
    if isempty(sz)
        ret = Array(S, 0)
    else
        ret = Array(S, sz...)
        if isvar
            # Variable-length
            buf = Array(Ptr{Uint8}, len)
            h5t_set_size(memtype_id, H5T_VARIABLE)
            readarray(obj, memtype_id, buf)
            # FIXME? Who owns the memory for each string? Will Julia free it?
            for i = 1:len
                ret[i] = bytestring(buf[i])
            end
        else
            # Fixed length
            ilen += 1  # for null terminator
            buf = Array(Uint8, len*ilen)
            h5t_set_size(memtype_id, ilen)
            readarray(obj, memtype_id, buf)
            p = convert(Ptr{Uint8}, buf)
            for i = 1:len
                ret[i] = bytestring(p)
                p += ilen
            end
        end
    end
    h5t_close(memtype_id)
    ret
end
read{S<:CharType}(obj::DatasetOrAttribute, ::Type{Array{S}}) = read(obj, Array{stringtype(S)})
# Empty Array of strings
function read{C<:CharType}(obj::DatasetOrAttribute, ::Type{EmptyArray{C}})
    Array(stringtype(C), 0)
end
# Read an array of references
function read(obj::HDF5Dataset, ::Type{Array{HDF5ReferenceObj}})
    dims = size(obj)
    refs = Array(HDF5ReferenceObj, dims...)
    h5d_read(obj.id, H5T_STD_REF_OBJ, refs)
    refs
end
function read(obj::HDF5Attribute, ::Type{Array{HDF5ReferenceObj}})
    dims = size(obj)
    refs = Array(HDF5ReferenceObj, dims...)
    h5a_read(obj.id, H5T_STD_REF_OBJ, refs)
    refs
end
# Dereference
function getindex(parent::Union(HDF5File, HDF5Group, HDF5Dataset), r::HDF5ReferenceObj)
    if r == HDF5ReferenceObj_NULL; error("Reference is null"); end
    obj_id = h5r_dereference(checkvalid(parent).id, H5R_OBJECT, r)
    h5object(obj_id, parent)
end
# Read compound type
function read(obj::HDF5Dataset, ::Type{Array{HDF5Compound}})
    t = datatype(obj)
    n = h5t_get_nmembers(t.id)
    membertype = Array(Type, n)
    membername = Array(ASCIIString, n)
    memberoffset = Array(Uint64, n)
    sz = 0
    for i = 1:n
        filetype = HDF5Datatype(h5t_get_member_type(t.id, i-1))
        T = hdf5_to_julia_eltype(filetype)
        if T == ASCIIString
            error("Not yet supported")  # need to handle the vlen issues
#             T = Ptr{Uint8}
        end
        membertype[i] = T
        memberoffset[i] = sz
        sz += sizeof(T)
        membername[i] = h5t_get_member_name(t.id, i-1)
    end
    # Build the "memory type"
    memtype_id = h5t_create(H5T_COMPOUND, sz)
    for i = 1:n
        h5t_insert(memtype_id, membername[i], memberoffset[i], hdf5_type_id(membertype[i])) # FIXME strings
    end
    # Read the raw data
    buf = Array(Uint8, length(obj)*sz)
    h5d_read(obj.id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
    HDF5Compound(buf, membertype, membername, memberoffset)
end

# Read OPAQUE datasets and attributes
function read(obj::DatasetOrAttribute, ::Type{Array{HDF5Opaque}})
    local buf
    local len
    local tag
    sz = size(obj)
    objtype = datatype(obj)
    try
        len = h5t_get_size(objtype)
        buf = Array(Uint8, prod(sz)*len)
        tag = h5t_get_tag(objtype.id)
        readarray(obj, objtype.id, buf)
    finally
        close(objtype)
    end
    data = Array(Array{Uint8}, sz...)
    for i = 1:prod(sz)
        data[i] = buf[(i-1)*len+1:i*len]
    end
    HDF5Opaque(data, tag)
end

# Read VLEN arrays and character arrays
atype{T<:HDF5BitsKind}(::Type{T}) = Array{T}
atype{C<:CharType}(::Type{C}) = stringtype(C)
p2a{T<:HDF5BitsKind}(p::Ptr{T}, len::Int) = pointer_to_array(p, (len,), true)
p2a{C<:CharType}(p::Ptr{C}, len::Int) = convert(stringtype(C), bytestring(convert(Ptr{Uint8}, p), len))
t2p{T<:HDF5BitsKind}(::Type{T}) = Ptr{T}
t2p{C<:CharType}(::Type{C}) = Ptr{Uint8}
function read{T<:Union(HDF5BitsKind,CharType)}(obj::DatasetOrAttribute, ::Type{HDF5Vlen{T}})
    local data
    sz = size(obj)
    len = prod(sz)
    # Read the data
    structbuf = Array(Hvl_t, len)
    memtype_id = h5t_vlen_create(hdf5_type_id(T))
    readarray(obj, memtype_id, structbuf)
    h5t_close(memtype_id)
    # Unpack the data
    data = Array(atype(T), sz...)
    for i = 1:len
        h = structbuf[i]
        data[i] = p2a(convert(Ptr{T}, h.p), int(h.len))
    end
    # FIXME? Ownership of buffer (no need to call reclaim, right?)
    data
end
read(attr::HDF5Attributes, name::ASCIIString) = a_read(attr.parent, name)

# Reading with mmap
function iscontiguous(obj::HDF5Dataset)
    prop = h5d_get_create_plist(checkvalid(obj).id)
    try
        h5p_get_layout(prop) != H5D_CHUNKED
    finally
        h5p_close(prop)
    end
end

ismmappable{T<:HDF5BitsKind}(::Type{Array{T}}) = true
ismmappable(::Type) = false
ismmappable{T}(obj::HDF5Dataset, ::Type{T}) = ismmappable(T) && iscontiguous(obj)
ismmappable(obj::HDF5Dataset) = ismmappable(obj, hdf5_to_julia(obj))

function readmmap{T<:HDF5BitsKind}(obj::HDF5Dataset, ::Type{Array{T}})
    local fd
    prop = h5d_get_access_plist(checkvalid(obj).id)
    try
        ret = Ptr{Cint}[0]
        h5f_get_vfd_handle(obj.file.id, prop, ret)
        fd = unsafe_load(ret[1])
    finally
        HDF5.h5p_close(prop)
    end
    
    offset = h5d_get_offset(obj.id)
    if offset == uint64(-1)
        error("Error mmapping array")
    end
    mmap_array(T, size(obj), fdio(fd), convert(FileOffset, offset))
end

function readmmap(obj::HDF5Dataset)
    T = hdf5_to_julia(obj)
    if !ismmappable(T); error("Cannot mmap datasets of type $T"); end
    if !iscontiguous(obj); error("Cannot mmap discontiguous dataset"); end
    readmmap(obj, T)
end

# Generic write
function write(parent::Union(HDF5File, HDF5Group), name1::ASCIIString, val1, name2::ASCIIString, val2, nameval...)
    if !iseven(length(nameval))
        error("name, value arguments must come in pairs")
    end
    write(parent, name1, val1)
    write(parent, name2, val2)
    for i = 1:2:length(nameval)
        thisname = nameval[i]
        if !isa(thisname, ASCIIString)
            error("Argument ", i+5, " should be a string, but it's a ", typeof(thisname))
        end
        write(parent, thisname, nameval[i+1])
    end
end

# Plain dataset & attribute writes
# Due to method ambiguities we generate these explicitly

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = d_create(parent, name, data)
# You can also pass in property lists
for (privatesym, fsym, ptype) in
    ((:_d_create, :d_create, Union(HDF5File, HDF5Group)),
     (:_a_create, :a_create, Union(HDF5Group, HDF5Dataset)))
    @eval begin
        # Generic create (hidden)
        function ($privatesym)(parent::$ptype, name::ASCIIString, data, plists...)
            local dtype
            local obj
            dtype = datatype(data)
            dspace = dataspace(data)
            try
                obj = ($fsym)(parent, name, dtype, dspace, plists...)
            finally
                close(dspace)
            end
            obj, dtype
        end
        # Scalar types
        ($fsym){T<:BitsKindOrByteString}(parent::$ptype, name::ASCIIString, data::Union(T, Array{T}), plists...) =
            ($privatesym)(parent, name, data, plists...)
        # VLEN types
        ($fsym){T<:Union(HDF5BitsKind,CharType)}(parent::$ptype, name::ASCIIString, data::HDF5Vlen{T}, plists...) =
            ($privatesym)(parent, name, data, plists...)
    end
end
# ReferenceObjArray
function d_create(parent::Union(HDF5File, HDF5Group), name::ASCIIString, data::Array{HDF5ReferenceObj}, plists...)
    local obj
    dtype = datatype(data)
    dspace = dataspace(data)
    try
        obj = d_create(parent, name, dtype, dspace, plists...)
    finally
        close(dspace)
    end
    obj, dtype
end
# Create and write, closing the objects upon exit
for (privatesym, fsym, ptype, crsym) in
    ((:_d_write, :d_write, Union(HDF5File, HDF5Group), :d_create),
     (:_a_write, :a_write, Union(HDF5File, HDF5Object{HDF5File}, HDF5Datatype), :a_create))
    @eval begin
        # Generic write (hidden)
        function ($privatesym)(parent::$ptype, name::ASCIIString, data, plists...)
            obj, dtype = ($crsym)(parent, name, data, plists...)
            try
                writearray(obj, dtype.id, data)
            finally
                close(obj)
                close(dtype)
            end
        end
        # Scalar types
        ($fsym){T<:BitsKindOrByteString}(parent::$ptype, name::ASCIIString, data::Union(T, Array{T}), plists...) =
            ($privatesym)(parent, name, data, plists...)
        # VLEN types
        ($fsym){T<:Union(HDF5BitsKind,CharType)}(parent::$ptype, name::ASCIIString, data::HDF5Vlen{T}, plists...) =
            ($privatesym)(parent, name, data, plists...)
    end
end
# Write to already-created objects
# Scalars
function write{T<:BitsKindOrByteString}(obj::DatasetOrAttribute, x::Union(T, Array{T}))
    dtype = datatype(x)
    try
        writearray(obj, dtype.id, x)
    finally
       close(dtype)
    end
end
# VLEN types
function write{T<:Union(HDF5BitsKind,CharType)}(obj::DatasetOrAttribute, data::HDF5Vlen{T})
    dtype = datatype(data)
    try
        writearray(obj, dtype.id, data)
    finally
        close(dtype)
    end
end
# For plain files and groups, let "write(obj, name, val)" mean "d_write"
write{T<:BitsKindOrByteString}(parent::Union(HDF5File, HDF5Group), name::ASCIIString, data::Union(T, Array{T}), plists...) =
    d_write(parent, name, data, plists...)
# For datasets, "write(dset, name, val)" means "a_write"
write{T<:BitsKindOrByteString}(parent::HDF5Dataset, name::ASCIIString, data::Union(T, Array{T}), plists...) = a_write(parent, name, data, plists...)

# Reading arrays using getindex: data = dset[:,:,10]
function getindex(dset::HDF5Dataset, indices::RangeIndex...)
    local T
    dtype = datatype(dset)
    try
        T = hdf5_to_julia_eltype(dtype)
    finally
        close(dtype)
    end
    if !(T<:HDF5BitsKind)
        error("Dataset indexing (hyperslab) is available only for bits types")
    end
    dsel_id = hyperslab(dset, indices...)
    ret = Array(T, map(length, indices))
    memtype = datatype(ret)
    memspace = dataspace(ret)
    try
        h5d_read(dset.id, memtype.id, memspace.id, dsel_id, H5P_DEFAULT, ret)
    finally
        close(memtype)
        close(memspace)
        h5s_close(dsel_id)
    end
    ret
end

# Write to a subset of a dataset using array slices: dataset[:,:,10] = array
function setindex!(dset::HDF5Dataset, X::Array, indices::RangeIndex...)
    T = hdf5_to_julia(dset)
    if !(T<:Array)
        error("Dataset indexing (hyperslab) is available only for arrays")
    end
    if !(T.parameters[1]<:HDF5BitsKind)
        error("Dataset indexing (hyperslab) is available only for bits types")
    end
    if length(X) != prod([length(idxs) for idxs in
                         filter(idx -> isa(idx, Ranges),
                                [indices[i] for i in 1:length(indices)])])
        error("number of elements in range and length of array must be equal")
    end
    if eltype(X) != T.parameters[1]
        X = convert(Array{T.parameters[1]}, X)
    end
    dsel_id = hyperslab(dset, indices...)
    memtype = datatype(X)
    memspace = dataspace(X)
    try
        h5d_write(dset.id, memtype.id, memspace.id, dsel_id, H5P_DEFAULT, X)
    finally
        close(memtype)
        close(memspace)
        h5s_close(dsel_id)
    end
    X
end

function setindex!(dset::HDF5Dataset, X::AbstractArray, indices::RangeIndex...)
    T = hdf5_to_julia(dset)
    if !(T<:Array)
        error("Hyperslab interface is available only for arrays")
    end
    Y = convert(Array{T.parameters[1], ndims(X)}, X)
    setindex!(dset, Y, indices...)
end

function setindex!(dset::HDF5Dataset, x::Number, indices::RangeIndex...)
    T = hdf5_to_julia(dset)
    if !(T<:Array)
        error("Hyperslab interface is available only for arrays")
    end
    X = fill(convert(T.parameters[1], x), map(length, indices))
    setindex!(dset, X, indices...)
end

function hyperslab(dset::HDF5Dataset, indices::RangeIndex...)
    local dsel_id
    dspace = dataspace(dset)
    try
        dims, maxdims = get_dims(dspace)
        n_dims = length(dims)
        if length(indices) != n_dims
            @show n_dims
            @show indices
            error("Wrong number of indices supplied")
        end
        dsel_id = h5s_copy(dspace.id)
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
    finally
        close(dspace)
    end
    dsel_id
end

# Link to bytes in an external file
# If you need to link to multiple segments, use low-level interface
function d_create_external(parent::Union(HDF5File, HDF5Group), name::ASCIIString, filepath::ByteString, t, sz::Dims, offset::Integer)
    checkvalid(parent)
    p = p_create(HDF5.H5P_DATASET_CREATE)
    h5p_set_external(p, filepath, int(offset), prod(sz)*sizeof(t))
    d_create(parent, name, datatype(t), dataspace(sz), HDF5Properties(), p)
end
d_create_external(parent::Union(HDF5File, HDF5Group), name::ASCIIString, filepath::ByteString, t::Type, sz::Dims) = d_create_external(parent, name, filepath, t, sz, 0)

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
        T = hdf5_to_julia_eltype(objtype)
    finally
        close(objtype)
    end
    if T <: HDF5Vlen
        return T
    end
    # Determine whether it's an array
    objspace = dataspace(obj)
    try
        stype = h5s_get_simple_extent_type(objspace.id)
        if stype == H5S_SIMPLE
            T = Array{T}
        elseif stype == H5S_NULL
            T = EmptyArray{T}
        end
    finally
        close(objspace)
    end
    T
end

function hdf5_to_julia_eltype(objtype)
    local T
    class_id = h5t_get_class(objtype.id)
    if class_id == H5T_STRING
        cset = h5t_get_cset(objtype.id)
        n = h5t_get_size(objtype.id)
        if cset == H5T_CSET_ASCII
            T = (n == 1) ? ASCIIChar : ASCIIString
        elseif cset == H5T_CSET_UTF8
            T = (n == 1) ? UTF8Char : UTF8String
        else
            error("character set ", cset, " not recognized")
        end
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
    elseif class_id == H5T_OPAQUE
        T = HDF5Opaque
    elseif class_id == H5T_VLEN
        super_id = h5t_get_super(objtype.id)
        T = HDF5Vlen{hdf5_to_julia_eltype(HDF5Datatype(super_id))}
    elseif class_id == H5T_COMPOUND
        T = HDF5Compound
    else
        error("Class id ", class_id, " is not yet supported")
    end
    T
end


### Convenience wrappers ###
# These supply default values where possible
# See also the "special handling" section below
const EMPTY_STRING = Uint8[0x00]
h5a_write(attr_id::Hid, mem_type_id::Hid, buf::ByteString) = h5a_write(attr_id, mem_type_id, buf.data)
function h5a_write{T<:HDF5BitsKind}(attr_id::Hid, mem_type_id::Hid, x::T)
    tmp = Array(T, 1)
    tmp[1] = x
    h5a_write(attr_id, mem_type_id, tmp)
end
function h5a_write{S<:ByteString}(attr_id::Hid, memtype_id::Hid, strs::Array{S})
    len = length(strs)
    p = Array(Ptr{Uint8}, size(strs))
    for i = 1:len
        p[i] = convert(Ptr{Uint8}, strs[i])
    end
    h5a_write(attr_id, memtype_id, p)
end
function h5a_write{T<:Union(HDF5BitsKind,CharType)}(attr_id::Hid, memtype_id::Hid, v::HDF5Vlen{T})
    vp = vlenpack(v)
    h5a_write(attr_id, memtype_id, vp)
end
h5a_create(loc_id::Hid, name::ASCIIString, type_id::Hid, space_id::Hid) = h5a_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT)
h5a_open(obj_id::Hid, name::ASCIIString) = h5a_open(obj_id, name, H5P_DEFAULT)
h5d_create(loc_id::Hid, name::ASCIIString, type_id::Hid, space_id::Hid) = h5d_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5d_open(obj_id::Hid, name::ASCIIString) = h5d_open(obj_id, name, H5P_DEFAULT)
h5d_read(dataset_id::Hid, memtype_id::Hid, buf::Array) = h5d_read(dataset_id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
h5d_write(dataset_id::Hid, memtype_id::Hid, buf::Array) = h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, buf)
h5d_write(dataset_id::Hid, memtype_id::Hid, buf::ByteString) =
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, isempty(buf) ? EMPTY_STRING : buf.data)
function h5d_write{T<:HDF5BitsKind}(dataset_id::Hid, memtype_id::Hid, x::T)
    tmp = Array(T, 1)
    tmp[1] = x
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, tmp)
end
function h5d_write{S<:ByteString}(dataset_id::Hid, memtype_id::Hid, strs::Array{S})
    len = length(strs)
    p = Array(Ptr{Uint8}, size(strs))
    for i = 1:len
        p[i] = isempty(strs[i]) ? EMPTY_STRING : convert(Ptr{Uint8}, strs[i])
    end
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, p)
end
function h5d_write{T<:Union(HDF5BitsKind,CharType)}(dataset_id::Hid, memtype_id::Hid, v::HDF5Vlen{T})
    vp = vlenpack(v)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, H5P_DEFAULT, vp)
end
h5f_create(filename::ByteString) = h5f_create(filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT)
h5f_open(filename::ByteString, mode) = h5f_open(filename, mode, H5P_DEFAULT)
h5g_create(obj_id::Hid, name::ASCIIString) = h5g_create(obj_id, name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5g_create(obj_id::Hid, name::ASCIIString, lcpl_id, gcpl_id) = h5g_create(obj_id, name, lcpl_id, gcpl_id, H5P_DEFAULT)
h5g_open(file_id::Hid, name::ASCIIString) = h5g_open(file_id, name, H5P_DEFAULT)
h5l_exists(loc_id::Hid, name::ASCIIString) = h5l_exists(loc_id, name, H5P_DEFAULT)
h5o_open(obj_id::Hid, name::ASCIIString) = h5o_open(obj_id, name, H5P_DEFAULT)
#h5s_get_simple_extent_ndims(space_id::Hid) = h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)
h5t_get_native_type(type_id::Hid) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)
function h5r_dereference(obj_id::Hid, ref_type::Integer, pointee::HDF5ReferenceObj)
    ret = ccall(dlsym(libhdf5, :H5Rdereference), Hid, (Hid, Cint, Ptr{HDF5ReferenceObj}), obj_id, ref_type, &pointee)
    if ret < 0
        error("Error dereferencing object")
    end
    ret
end

### Utilities for generating ccall wrapper functions programmatically ###

function ccallexpr(ccallsym::Symbol, outtype, argtypes::Tuple, argsyms::Tuple)
    ccallargs = Any[Expr(:quote, ccallsym), outtype, Expr(:tuple, argtypes...)]
    ccallargs = ccallsyms(ccallargs, length(argtypes), argsyms)
    Expr(:ccall, ccallargs...)
end

function ccallexpr(lib::Ptr, ccallsym::Symbol, outtype, argtypes::Tuple, argsyms::Tuple)
    ccallargs = Any[Expr(:call, :dlsym, lib, Expr(:quote, ccallsym)), outtype, Expr(:tuple, argtypes...)]
    ccallargs = ccallsyms(ccallargs, length(argtypes), argsyms)
    Expr(:ccall, ccallargs...)
end

function ccallsyms(ccallargs, n, argsyms)
    if n > 0
        if length(argsyms) == n
            ccallargs = Any[ccallargs..., argsyms...]
        else
            for i = 1:length(argsyms)-1
                push!(ccallargs, argsyms[i])
            end
            for i = 1:n-length(argsyms)+1
                push!(ccallargs, Expr(:getindex, argsyms[end], i))
            end
        end
    end
    ccallargs
end

function funcdecexpr(funcsym, n::Int, argsyms)
    if length(argsyms) == n
        return Expr(:call, funcsym, argsyms...)
    else
        exargs = Any[funcsym, argsyms[1:end-1]...]
        push!(exargs, Expr(:..., argsyms[end]))
        return Expr(:call, exargs...)
    end
end

### ccall wrappers ###

# Note: use alphabetical order

# Functions that return Herr, pass back nothing to Julia (as an output), with simple
# error messages
for (jlname, h5name, outtype, argtypes, argsyms, msg) in
    ((:h5_close, :H5close, Herr, (), (), "Error closing the HDF5 resources"),
     (:h5_dont_atexit, :H5dont_atexit, Herr, (), (), "Error calling dont_atexit"),
     (:h5_garbage_collect, :H5garbage_collect, Herr, (), (), "Error on garbage collect"),
     (:h5_open, :H5open, Herr, (), (), "Error initializing the HDF5 library"),
     (:h5_set_free_list_limits, :H5set_free_list_limits, Herr, (Cint, Cint, Cint, Cint, Cint, Cint), (:reg_global_lim, :reg_list_lim, :arr_global_lim, :arr_list_lim, :blk_global_lim, :blk_list_lim), "Error setting limits on free lists"),
     (:h5a_close, :H5Aclose, Herr, (Hid,), (:id,), "Error closing attribute"),
     (:h5a_write, :H5Awrite, Herr, (Hid, Hid, Ptr{Void}), (:attr_hid, :mem_type_id, :buf), "Error writing attribute data"),
     (:h5d_close, :H5Dclose, Herr, (Hid,), (:dataset_id,), "Error closing dataset"),
     (:h5d_set_extent, :H5Dset_extent, Herr, (Hid, Ptr{Hsize}), (:dataset_id, :new_dims), "Error extending dataset dimensions"),
     (:h5d_vlen_get_buf_size, :H5Dvlen_get_buf_size, Herr, (Hid, Hid, Hid, Ptr{Hsize}), (:dset_id, :type_id, :space_id, :buf), "Error getting vlen buffer size"),
     (:h5d_vlen_reclaim, :H5Dvlen_reclaim, Herr, (Hid, Hid, Hid, Ptr{Void}), (:type_id, :space_id, :plist_id, :buf), "Error reclaiming vlen buffer"),
     (:h5d_write, :H5Dwrite, Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Void}), (:dataset_id, :mem_type_id, :mem_space_id, :file_space_id, :xfer_plist_id, :buf), "Error writing dataset"),
     (:h5e_set_auto, :H5Eset_auto2, Herr, (Hid, Ptr{Void}, Ptr{Void}), (:estack_id, :func, :client_data), "Error setting error reporting behavior"),  # FIXME callbacks, for now pass C_NULL for both pointers
     (:h5f_close, :H5Fclose, Herr, (Hid,), (:file_id,), "Error closing file"),
     (:h5f_flush, :H5Fflush, Herr, (Hid, Cint), (:object_id, :scope,), "Error flushing object to file"),
     (:h5f_get_vfd_handle, :H5Fget_vfd_handle, Herr, (Hid, Hid, Ptr{Ptr{Cint}}), (:file_id, :fapl_id, :file_handle), "Error getting VFD handle"),
     (:h5g_close, :H5Gclose, Herr, (Hid,), (:group_id,), "Error closing group"),
     (:h5g_get_info, :H5Gget_info, Herr, (Hid, Ptr{H5Ginfo}), (:group_id, :buf), "Error getting group info"),
     (:h5o_get_info, :H5Oget_info, Herr, (Hid, Ptr{H5Oinfo}), (:object_id, :buf), "Error getting object info"),
     (:h5o_close, :H5Oclose, Herr, (Hid,), (:object_id,), "Error closing object"),
     (:h5p_close, :H5Pclose, Herr, (Hid,), (:id,), "Error closing property list"),
     (:h5p_get_fclose_degree, :H5Pget_fclose_degree, Herr, (Hid, Ptr{Cint}), (:plist_id, :fc_degree), "Error getting close degree"),
     (:h5p_get_userblock, :H5Pget_userblock, Herr, (Hid, Ptr{Hsize}), (:plist_id, :len), "Error getting userblock"),
     (:h5p_set_chunk, :H5Pset_chunk, Herr, (Hid, Cint, Ptr{Hsize}), (:plist_id, :ndims, :dims), "Error setting chunk size"),
     (:h5p_set_external, :H5Pset_external, Herr, (Hid, Ptr{Uint8}, Int, Csize_t), (:plist_id, :name, :offset, :size), "Error setting external property"),
     (:h5p_set_fclose_degree, :H5Pset_fclose_degree, Herr, (Hid, Cint), (:plist_id, :fc_degree), "Error setting close degree"),
     (:h5p_set_deflate, :H5Pset_deflate, Herr, (Hid, Cuint), (:plist_id, :setting), "Error setting compression method and level (deflate)"),
     (:h5p_set_layout, :H5Pset_layout, Herr, (Hid, Cint), (:plist_id, :setting), "Error setting layout"),
     (:h5p_set_userblock, :H5Pset_userblock, Herr, (Hid, Hsize), (:plist_id, :len), "Error setting userblock"),
     (:h5s_close, :H5Sclose, Herr, (Hid,), (:space_id,), "Error closing dataspace"),
     (:h5s_select_hyperslab, :H5Sselect_hyperslab, Herr, (Hid, Cint, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}), (:dspace_id, :seloper, :start, :stride, :count, :block), "Error selecting hyperslab"),
     (:h5t_commit, :H5Tcommit2, Herr, (Hid, Ptr{Uint8}, Hid, Hid, Hid, Hid), (:loc_id, :name, :dtype_id, :lcpl_id, :tcpl_id, :tapl_id), "Error committing type"),
     (:h5t_close, :H5Tclose, Herr, (Hid,), (:dtype_id,), "Error closing datatype"),
     (:h5t_set_cset, :H5Tset_cset, Herr, (Hid, Cint), (:dtype_id, :cset), "Error setting character set in datatype"),
     (:h5t_set_size, :H5Tset_size, Herr, (Hid, Csize_t), (:dtype_id, :sz), "Error setting size of datatype"),
    )

    ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
    ex_ccall = ccallexpr(libhdf5, h5name, outtype, argtypes, argsyms)
    ex_body = quote
        status = $ex_ccall
        if status < 0
            error($msg)
        end
    end
    ex_func = Expr(:function, ex_dec, ex_body)
    @eval begin
        $ex_func
    end
end

# Functions returning a single argument, and/or with more complex
# error messages
for (jlname, h5name, outtype, argtypes, argsyms, ex_error) in
    ((:h5a_create, :H5Acreate2, Hid, (Hid, Ptr{Uint8}, Hid, Hid, Hid, Hid), (:loc_id, :pathname, :type_id, :space_id, :acpl_id, :aapl_id), :(error("Error creating attribute ", h5a_get_name(loc_id), "/", pathname))),
     (:h5a_create_by_name, :H5Acreate_by_name, Hid, (Hid, Ptr{Uint8}, Ptr{Uint8}, Hid, Hid, Hid, Hid, Hid), (:loc_id, :obj_name, :attr_name, :type_id, :space_id, :acpl_id, :aapl_id, :lapl_id), :(error("Error creating attribute ", attr_name, " for object ", obj_name))),
     (:h5a_delete, :H5Adelete, Herr, (Hid, Ptr{Uint8}), (:loc_id, :attr_name), :(error("Error deleting attribute ", attr_name))),
     (:h5a_delete_by_idx, :H5delete_by_idx, Herr, (Hid, Ptr{Uint8}, Cint, Cint, Hsize, Hid), (:loc_id, :obj_name, :idx_type, :order, :n, :lapl_id), :(error("Error deleting attribute ", n, " from object ", obj_name))),
     (:h5a_delete_by_name, :H5delete_by_name, Herr, (Hid, Ptr{Uint8}, Ptr{Uint8}, Hid), (:loc_id, :obj_name, :attr_name, :lapl_id), :(error("Error removing attribute ", attr_name, " from object ", obj_name))),
     (:h5a_get_create_plist, :H5Aget_create_plist, Hid, (Hid,), (:attr_id,), :(error("Cannot get creation property list"))),
     (:h5a_get_name, :H5Aget_name, Cssize_t, (Hid, Csize_t, Ptr{Uint8}), (:attr_id, :buf_size, :buf), :(error("Error getting attribute name"))),
     (:h5a_get_name_by_idx, :H5Aget_name_by_idx, Cssize_t, (Hid, Ptr{Uint8}, Cint, Cint, Hsize, Ptr{Uint8}, Csize_t, Hid), (:loc_id, :obj_name, :index_type, :order, :idx, :name, :size, :lapl_id), :(error("Error getting attribute name"))),
     (:h5a_get_space, :H5Aget_space, Hid, (Hid,), (:attr_id,), :(error("Error getting attribute dataspace"))),
     (:h5a_get_type, :H5Aget_type, Hid, (Hid,), (:attr_id,), :(error("Error getting attribute type"))),
     (:h5a_open, :H5Aopen, Hid, (Hid, Ptr{Uint8}, Hid), (:obj_id, :pathname, :aapl_id), :(error("Error opening attribute ", h5a_get_name(obj_id), "/", pathname))),
     (:h5a_read, :H5Aread, Herr, (Hid, Hid, Ptr{Uint8}), (:attr_id, :mem_type_id, :buf), :(error("Error reading attribute ", h5a_get_name(attr_id)))),
     (:h5d_create, :H5Dcreate2, Hid, (Hid, Ptr{Uint8}, Hid, Hid, Hid, Hid, Hid), (:loc_id, :pathname, :dtype_id, :space_id, :dlcpl_id, :dcpl_id, :dapl_id), :(error("Error creating dataset ", h5i_get_name(loc_id), "/", pathname))),
     (:h5d_get_access_plist, :H5Dget_access_plist, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataset access property list"))),     
     (:h5d_get_create_plist, :H5Dget_create_plist, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataset create property list"))),     
     (:h5d_get_offset, :H5Dget_offset, Haddr, (Hid,), (:dataset_id,), :(error("Error getting offset"))),     
     (:h5d_get_space, :H5Dget_space, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataspace"))),     
     (:h5d_get_type, :H5Dget_type, Cint, (Hid,), (:dataset_id,), :(error("Error getting dataspace type"))),
     (:h5d_open, :H5Dopen2, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :pathname, :dapl_id), :(error("Error opening dataset ", h5i_get_name(loc_id), "/", pathname))),
     (:h5d_read, :H5Dread, Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Void}), (:dataset_id, :mem_type_id, :mem_space_id, :file_space_id, :xfer_plist_id, :buf), :(error("Error reading dataset ", h5i_get_name(dataset_id)))),
     (:h5f_create, :H5Fcreate, Hid, (Ptr{Uint8}, Cuint, Hid, Hid), (:pathname, :flags, :fcpl_id, :fapl_id), :(error("Error creating file ", pathname))),
     (:h5f_get_access_plist, :H5Fget_access_plist, Hid, (Hid,), (:file_id,), :(error("Error getting file access property list"))),     
     (:h5f_get_create_plist, :H5Fget_create_plist, Hid, (Hid,), (:file_id,), :(error("Error getting file create property list"))),
     (:h5f_get_name, :H5Fget_name, Cssize_t, (Hid, Ptr{Uint8}, Csize_t), (:obj_id, :buf, :buf_size), :(error("Error getting file name"))),
     (:h5f_open, :H5Fopen, Hid, (Ptr{Uint8}, Cuint, Hid), (:pathname, :flags, :fapl_id), :(error("Error opening file ", pathname))),
     (:h5g_create, :H5Gcreate2, Hid, (Hid, Ptr{Uint8}, Hid, Hid, Hid), (:loc_id, :pathname, :lcpl_id, :gcpl_id, :gapl_id), :(error("Error creating group ", h5i_get_name(loc_id), "/", pathname))),
     (:h5g_get_create_plist, :H5Gget_create_plist, Hid, (Hid,), (:group_id,), :(error("Error getting group create property list"))),
     (:h5g_get_objname_by_idx, :H5Gget_objname_by_idx, Hid, (Hid, Hsize, Ptr{Uint8}, Csize_t), (:loc_id, :idx, :pathname, :size), :(error("Error getting group object name ", h5i_get_name(loc_id), "/", pathname))),
     (:h5g_get_num_objs, :H5Gget_num_objs, Hid, (Hid, Ptr{Uint8}), (:loc_id, :num_obj), :(error("Error getting group length"))),
     (:h5g_open, :H5Gopen2, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :pathname, :gapl_id), :(error("Error opening group ", h5i_get_name(loc_id), "/", pathname))),
     (:h5i_get_file_id, :H5Iget_file_id, Hid, (Hid,), (:obj_id,), :(error("Error getting file identifier"))),
     (:h5i_get_name, :H5Iget_name, Cssize_t, (Hid, Ptr{Uint8}, Csize_t), (:obj_id, :buf, :buf_size), :(error("Error getting object name"))),
     (:h5i_get_ref, :H5Iget_ref, Cint, (Hid,), (:obj_id,), :(error("Error getting reference count"))),
     (:h5i_get_type, :H5Iget_type, Cint, (Hid,), (:obj_id,), :(error("Error getting type"))),
     (:h5l_delete, :H5Ldelete, Herr, (Hid, Ptr{Uint8}, Hid), (:obj_id, :pathname, :lapl_id), :(error("Error deleting ", h5i_get_name(obj_id), "/", pathname))),
     (:h5l_create_external, :H5Lcreate_hard_external, Herr, (Ptr{Uint8}, Ptr{Uint8}, Hid, Ptr{Uint8}, Hid, Hid), (:target_file_name, :target_obj_name, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name))),
     (:h5l_create_hard, :H5Lcreate_hard, Herr, (Hid, Ptr{Uint8}, Hid, Ptr{Uint8}, Hid, Hid), (:obj_loc_id, :obj_name, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating hard link ", link_name, " pointing to ", obj_name))),
     (:h5l_create_soft, :H5Lcreate_soft, Herr, (Ptr{Uint8}, Hid, Ptr{Uint8}, Hid, Hid), (:target_path, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating soft link ", link_name, " pointing to ", target_path))),
     (:h5l_exists, :H5Lexists, Htri, (Hid, Ptr{Uint8}, Hid), (:loc_id, :pathname, :lapl_id), :(error("Cannot determine whether link ", h5i_get_name(loc_id), "/", pathname, " exists, check each item along the path"))),
     (:h5l_get_info, :H5Lget_info, Herr, (Hid, Ptr{Uint8}, Ptr{H5LInfo}, Hid), (:link_loc_id, :link_name, :link_buf, :lapl_id), :(error("Error getting info for link ", link_name))),
     (:h5o_open, :H5Oopen, Hid, (Hid, Ptr{Uint8}, Hid), (:loc_id, :pathname, :lapl_id), :(error("Error opening object ", h5i_get_name(loc_id), "/", pathname))),
     (:h5o_open_by_idx, :H5Oopen_by_idx, Hid, (Hid, Ptr{Uint8}, Cint, Cint, Hsize, Hid), (:loc_id, :group_name, :index_type, :order, :n, :lapl_id), :(error("Error opening object of index ", n))),
     (:h5p_create, :H5Pcreate, Hid, (Hid,), (:cls_id,), "Error creating property list"),
     (:h5p_get_chunk, :H5Pget_chunk, Cint, (Hid, Cint, Ptr{Hsize}), (:plist_id, :n_dims, :dims), :(error("Error getting chunk size"))),
     (:h5p_get_layout, :H5Pget_layout, Cint, (Hid,), (:plist_id,), :(error("Error getting layout"))),
     (:h5p_get_driver, :H5Pget_driver_info, Ptr{Void}, (Hid,), (:plist_id,), "Error getting driver info"),
     (:h5r_create, :H5Rcreate, Herr, (Ptr{HDF5ReferenceObj}, Hid, Ptr{Uint8}, Cint, Hid), (:ref, :loc_id, :pathname, :ref_type, :space_id), :(error("Error creating reference to object ", hi5_get_name(loc_id), "/", pathname))),
     (:h5r_get_obj_type, :H5Rget_obj_type2, Herr, (Hid, Cint, Ptr{Void}, Ptr{Cint}), (:loc_id, :ref_type, :ref, :obj_type), :(error("Error getting object type"))),
     (:h5r_get_region, :H5Rget_region, Hid, (Hid, Cint, Ptr{Void}), (:loc_id, :ref_type, :ref), :(error("Error getting region from reference"))),
     (:h5s_copy, :H5Scopy, Hid, (Hid,), (:space_id,), :(error("Error copying dataspace"))),
     (:h5s_create, :H5Screate, Hid, (Cint,), (:class,), :(error("Error creating dataspace"))),
     (:h5s_create_simple, :H5Screate_simple, Hid, (Cint, Ptr{Hsize}, Ptr{Hsize}), (:rank, :current_dims, :maximum_dims), :(error("Error creating simple dataspace"))),
     (:h5s_get_simple_extent_dims, :H5Sget_simple_extent_dims, Cint, (Hid, Ptr{Hsize}, Ptr{Hsize}), (:space_id, :dims, :maxdims), :(error("Error getting the dimensions for a dataspace"))),
     (:h5s_get_simple_extent_ndims, :H5Sget_simple_extent_ndims, Cint, (Hid,), (:space_id,), :(error("Error getting the number of dimensions for a dataspace"))),
     (:h5s_get_simple_extent_type, :H5Sget_simple_extent_type, Cint, (Hid,), (:space_id,), :(error("Error getting the dataspace type"))),
     (:h5t_copy, :H5Tcopy, Hid, (Hid,), (:dtype_id,), :(error("Error copying datatype"))),
     (:h5t_create, :H5Tcreate, Hid, (Cint, Csize_t), (:class_id, :sz), :(error("Error creating datatype of id ", classid))),
     (:h5t_get_class, :H5Tget_class, Cint, (Hid,), (:dtype_id,), :(error("Error getting class"))),
     (:h5t_get_cset, :H5Tget_cset, Cint, (Hid,), (:dtype_id,), :(error("Error getting character set encoding"))),
     (:h5t_get_member_class, :H5Tget_member_class, Cint, (Hid, Cuint), (:dtype_id, :index), :(error("Error getting class of compound datatype member #", index))),
     (:h5t_get_member_index, :H5Tget_member_index, Cint, (Hid, Ptr{Uint8}), (:dtype_id, :membername), :(error("Error getting index of compound datatype member \"", membername, "\""))),
     (:h5t_get_member_offset, :H5Tget_member_offset, Csize_t, (Hid, Cuint), (:dtype_id, :index), :(error("Error getting offset of compound datatype member #", index))),
     (:h5t_get_member_type, :H5Tget_member_type, Hid, (Hid, Cuint), (:dtype_id, :index), :(error("Error getting type of compound datatype member #", index))),
     (:h5t_get_native_type, :H5Tget_native_type, Hid, (Hid, Cint), (:dtype_id, :direction), :(error("Error getting native type"))),
     (:h5t_get_nmembers, :H5Tget_nmembers, Cint, (Hid,), (:dtype_id,), :(error("Error getting the number of members"))),
     (:h5t_get_sign, :H5Tget_sign, Cint, (Hid,), (:dtype_id,), :(error("Error getting sign"))),
     (:h5t_get_size, :H5Tget_size, Csize_t, (Hid,), (:dtype_id,), :(error("Error getting size"))),
     (:h5t_get_super, :H5Tget_super, Hid, (Hid,), (:dtype_id,), :(error("Error getting super type"))),
     (:h5t_get_strpad, :H5Tget_strpad, Cint, (Hid,), (:dtype_id,), :(error("Error getting string padding"))),
     (:h5t_insert, :H5Tinsert, Herr, (Hid, Ptr{Uint8}, Csize_t, Hid), (:dtype_id, :fieldname, :offset, :field_id), :(error("Error adding field ", fieldname, " to compound datatype"))),
     (:h5t_vlen_create, :H5Tvlen_create, Hid, (Hid,), (:base_type_id,), :(error("Error creating vlen type"))),
     ## The following doesn't work because it's in libhdf5_hl.so.
     ## (:h5tb_get_field_info, :H5TBget_field_info, Herr, (Hid, Ptr{Uint8}, Ptr{Ptr{Uint8}}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}), (:loc_id, :table_name, :field_names, :field_sizes, :field_offsets, :type_size), :(error("Error getting field information")))
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
    ex_func = Expr(:function, ex_dec, ex_body)
    @eval begin
        $ex_func
    end
end

# Functions like the above, returning a Julia boolean
for (jlname, h5name, outtype, argtypes, argsyms, ex_error) in
    ((:h5a_exists, :H5Aexists, Htri, (Hid, Ptr{Uint8}), (:obj_id, :attr_name), :(error("Error checking whether attribute ", attr_name, " exists"))),
     (:h5a_exists_by_name, :H5Aexists_by_name, Htri, (Hid, Ptr{Uint8}, Ptr{Uint8}, Hid), (:loc_id, :obj_name, :attr_name, :lapl_id), :(error("Error checking whether object ", obj_name, " has attribute ", attr_name))),
     (:h5f_is_hdf5, :H5Fis_hdf5, Htri, (Ptr{Uint8},), (:pathname,), :(error("Cannot access file ", pathname))),
     (:h5i_is_valid, :H5Iis_valid, Htri, (Hid,), (:obj_id,), :(error("Cannot determine whether object is valid"))),
     (:h5l_exists, :H5Lexists, Htri, (Hid, Ptr{Uint8}, Hid), (:loc_id, :pathname, :lapl_id), :(error("Cannot determine whether ", pathname, " exists"))),
     (:h5s_is_simple, :H5Sis_simple, Htri, (Hid,), (:space_id,), :(error("Error determining whether dataspace is simple"))),
     (:h5t_is_variable_str, :H5Tis_variable_str, Htri, (Hid,), (:type_id,), :(error("Error determining whether string is of variable length"))),
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
    ex_func = Expr(:function, ex_dec, ex_body)
    @eval begin
        $ex_func
    end
end

# Functions that require special handling
_majnum = Array(Cuint, 1)
_minnum = Array(Cuint, 1)
_relnum = Array(Cuint, 1)
function h5_get_libversion()
    status = ccall(dlsym(libhdf5, :H5get_libversion),
                   Herr,
                   (Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}),
                   _majnum, _minnum, _relnum)
    if status < 0
        error("Error getting HDF5 library version")
    end
    return _majnum[1], _minnum[1], _relnum[1]
end
function h5a_get_name(attr_id::Hid)
    len = h5a_get_name(attr_id, 0, C_NULL) # order of args differs from {f,i}_get_name
    buf = Array(Uint8, len+1)
    h5a_get_name(attr_id, len+1, buf)
    convert(ASCIIString, buf[1:len])
end
function h5f_get_name(loc_id::Hid)
    len = h5f_get_name(loc_id, C_NULL, 0)
    buf = Array(Uint8, len+1)
    h5f_get_name(loc_id, buf, len+1)
    convert(ASCIIString, buf[1:len])
end
function h5i_get_name(loc_id::Hid)
    len = h5i_get_name(loc_id, C_NULL, 0)
    buf = Array(Uint8, len+1)
    h5i_get_name(loc_id, buf, len+1)
    convert(ASCIIString, buf[1:len])
end
function h5l_get_info(link_loc_id::Hid, link_name::ASCIIString, lapl_id::Hid)
    info = Array(H5LInfo, 1)
    h5l_get_info(link_loc_id, link_name, info, lapl_id)
    info[1]
end
function h5s_get_simple_extent_dims(space_id::Hid)
    n = h5s_get_simple_extent_ndims(space_id)
    dims = Array(Hsize, n)
    maxdims = Array(Hsize, n)
    h5s_get_simple_extent_dims(space_id, dims, maxdims)
    return tuple(reverse(dims)...), tuple(reverse(maxdims)...)
end
function h5t_get_member_name(type_id::Hid, index::Integer)
    pn = ccall(dlsym(libhdf5, :H5Tget_member_name),
               Ptr{Uint8},
               (Hid, Cuint),
               type_id, index)
    if pn == C_NULL
        error("Error getting name of compound datatype member #", index)
    end
    ascii(bytestring(pn))
end
function h5t_get_tag(type_id::Hid)
    pc = ccall(dlsym(libhdf5, :H5Tget_tag),
                   Ptr{Uint8},
                   (Hid,),
                   type_id)
    if pc == C_NULL
        error("Error getting opaque tag")
    end
    ascii(bytestring(pc))
end

function vlen_get_buf_size(dset::HDF5Dataset, dtype::HDF5Datatype, dspace::HDF5Dataspace)
    sz = Array(Hsize, 1)
    h5d_vlen_get_buf_size(dset.id, dtype.id, dspace.id, sz)
    sz[1]
end

### Property manipulation ###
get_create_properties(dset::HDF5Dataset) = HDF5Properties(h5d_get_create_plist(dset.id))
get_create_properties(g::HDF5Group) = HDF5Properties(h5g_get_create_plist(dset.id))
get_create_properties(g::HDF5File) = HDF5Properties(h5f_get_create_plist(dset.id))
get_create_properties(g::HDF5Attribute) = HDF5Properties(h5a_get_create_plist(dset.id))
function get_chunk(p::HDF5Properties)
    n = h5p_get_chunk(p, 0, C_NULL)
    cdims = Array(Hsize, n)
    h5p_get_chunk(p, n, cdims)
    tuple(convert(Array{Int}, reverse(cdims))...)
end
function get_chunk(dset::HDF5Dataset)
    p = get_create_properties(dset)
    local ret
    try
        ret = get_chunk(p)
    finally
        close(p)
    end
    ret
end
set_chunk(p::HDF5Properties, dims...) = h5p_set_chunk(p.id, length(dims), Hsize[reverse(dims)...])
function get_userblock(p::HDF5Properties)
    alen = Array(Hsize, 1)
    h5p_get_userblock(p.id, alen)
    alen[1]
end
function get_fclose_degree(p::HDF5Properties)
    out = Array(Cint, 1)
    h5p_get_fclose_degee(p.id, out)
    out[1]
end
# property function get/set pairs
const hdf5_prop_get_set = {
    "chunk"         => (get_chunk, set_chunk),
    "fclose_degree" => (get_fclose_degree, h5p_set_fclose_degree),
    "compress"      => (nothing, h5p_set_deflate),
    "deflate"       => (nothing, h5p_set_deflate),
    "layout"        => (h5p_get_layout, h5p_set_layout),
    "userblock"     => (get_userblock, h5p_set_userblock),
}


# Turn off automatic error printing
# h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)

export
    # Types
    HDF5Attribute,
    HDF5File,
    HDF5Group,
    HDF5Dataset,
    HDF5Datatype,
    HDF5Dataspace,
    HDF5Object,
    HDF5Properties,
    HDF5Vlen,
    HDF5File,
    # Functions
    a_create,
    a_delete,
    a_open,
    a_read,
    a_write,
    attrs,
    close,
    create,
    d_create,
    d_create_external,
    d_open,
    d_read,
    d_write,
    dataspace,
    datatype,
    exists,
    fid,
    file,
    filename,
    g_create,
    g_open,
    get_chunk,
    get_create_properties,
    getindex,
    h5open,
    has,
    iscontiguous,
    ishdf5,
    ismmappable,
    length,
    name,
    names,
    o_delete,
    o_open,
    p_create,
    parent,
    plain,
    read,
    readmmap,
    @read,
    root,
    set_dims!,
    setindex!,
    size,
    t_create,
    t_commit,
    write,
    @write

end  # module
