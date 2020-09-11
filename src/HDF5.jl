module HDF5

using Base: unsafe_convert, StringVector
using Requires: @require

import Base:
    close, convert, eltype, lastindex, flush, getindex, ==,
    isempty, isvalid, length, names, ndims, parent, read,
    setindex!, show, size, sizeof, write, isopen, iterate, eachindex, axes

import Libdl
import Mmap

# needed for filter(f, tuple) in julia 1.3
using Compat

export
    # types
    HDF5Attribute, HDF5File, HDF5Group, HDF5Dataset, HDF5Datatype,
    HDF5Dataspace, HDF5Object, HDF5Properties, HDF5Vlen, HDF5ChunkStorage,
    # functions
    a_create, a_delete, a_open, a_read, a_write, attrs,
    d_create, d_create_external, d_open, d_read, d_write,
    dataspace, datatype, exists, file, filename,
    g_create, g_open, get_access_properties, get_create_properties,
    get_chunk, get_datasets,
    h5open, h5read, h5rewrite, h5writeattr, h5readattr, h5write,
    has, iscontiguous, ishdf5, ismmappable, name,
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

function h5_get_libversion()
    majnum, minnum, relnum = Ref{Cuint}(), Ref{Cuint}(), Ref{Cuint}()
    status = ccall((:H5get_libversion, libhdf5), Cint, (Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), majnum, minnum, relnum)
    status < 0 && error("Error getting HDF5 library version")
    VersionNumber(majnum[], minnum[], relnum[])
end

const libversion = h5_get_libversion()

## C types
const C_time_t = Int

## HDF5 types and constants
const Hid    = Int64
const Herr   = Cint
const Hsize  = UInt64
const Hssize = Int64
const Htri   = Cint   # pseudo-boolean (negative if error)
const Haddr  = UInt64

# MPI communicators required by H5P
abstract  type Hmpih end
primitive type Hmpih32 <: Hmpih 32 end # MPICH C/Fortran, OpenMPI Fortran: 32 bit handles
primitive type Hmpih64 <: Hmpih 64 end # OpenMPI C: pointers (mostly 64 bit)

# Function to extract exported library constants
# Kudos to the library developers for making these available this way!
const libhdf5handle = Libdl.dlopen(libhdf5)
read_const(sym::Symbol) = unsafe_load(convert(Ptr{Hid}, Libdl.dlsym(libhdf5handle, sym)))

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
const H5_INDEX_N = 2
# dataset constants
const H5D_COMPACT      = 0
const H5D_CONTIGUOUS   = 1
const H5D_CHUNKED      = 2
# allocation times (C enum H5D_alloc_time_t)
const H5D_ALLOC_TIME_ERROR = -1
const H5D_ALLOC_TIME_DEFAULT = 0
const H5D_ALLOC_TIME_EARLY = 1
const H5D_ALLOC_TIME_LATE = 2
const H5D_ALLOC_TIME_INCR = 3
# error-related constants
const H5E_DEFAULT      = 0
# file access modes
const H5F_ACC_RDONLY     = 0x0000
const H5F_ACC_RDWR       = 0x0001
const H5F_ACC_TRUNC      = 0x0002
const H5F_ACC_EXCL       = 0x0004
const H5F_ACC_DEBUG      = 0x0008
const H5F_ACC_CREAT      = 0x0010
const H5F_ACC_SWMR_WRITE = 0x0020
const H5F_ACC_SWMR_READ  = 0x0040
# object types
const H5F_OBJ_FILE     = 0x0001
const H5F_OBJ_DATASET  = 0x0002
const H5F_OBJ_GROUP    = 0x0004
const H5F_OBJ_DATATYPE = 0x0008
const H5F_OBJ_ATTR     = 0x0010
const H5F_OBJ_ALL      = (H5F_OBJ_FILE|H5F_OBJ_DATASET|H5F_OBJ_GROUP|H5F_OBJ_DATATYPE|H5F_OBJ_ATTR)
const H5F_OBJ_LOCAL    = 0x0020
# other file constants
const H5F_SCOPE_LOCAL   = 0
const H5F_SCOPE_GLOBAL  = 1
const H5F_CLOSE_DEFAULT = 0
const H5F_CLOSE_WEAK    = 1
const H5F_CLOSE_SEMI    = 2
const H5F_CLOSE_STRONG  = 3
# file driver constants
const H5FD_MPIO_INDEPENDENT    = 0
const H5FD_MPIO_COLLECTIVE     = 1
const H5FD_MPIO_CHUNK_DEFAULT  = 0
const H5FD_MPIO_CHUNK_ONE_IO   = 1
const H5FD_MPIO_CHUNK_MULTI_IO = 2
const H5FD_MPIO_COLLECTIVE_IO  = 0
const H5FD_MPIO_INDIVIDUAL_IO  = 1
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
const H5P_DEFAULT          = Hid(0)
const H5P_OBJECT_CREATE    = read_const(:H5P_CLS_OBJECT_CREATE_ID_g)
const H5P_FILE_CREATE      = read_const(:H5P_CLS_FILE_CREATE_ID_g)
const H5P_FILE_ACCESS      = read_const(:H5P_CLS_FILE_ACCESS_ID_g)
const H5P_DATASET_CREATE   = read_const(:H5P_CLS_DATASET_CREATE_ID_g)
const H5P_DATASET_ACCESS   = read_const(:H5P_CLS_DATASET_ACCESS_ID_g)
const H5P_DATASET_XFER     = read_const(:H5P_CLS_DATASET_XFER_ID_g)
const H5P_FILE_MOUNT       = read_const(:H5P_CLS_FILE_MOUNT_ID_g)
const H5P_GROUP_CREATE     = read_const(:H5P_CLS_GROUP_CREATE_ID_g)
const H5P_GROUP_ACCESS     = read_const(:H5P_CLS_GROUP_ACCESS_ID_g)
const H5P_DATATYPE_CREATE  = read_const(:H5P_CLS_DATATYPE_CREATE_ID_g)
const H5P_DATATYPE_ACCESS  = read_const(:H5P_CLS_DATATYPE_ACCESS_ID_g)
const H5P_STRING_CREATE    = read_const(:H5P_CLS_STRING_CREATE_ID_g)
const H5P_ATTRIBUTE_CREATE = read_const(:H5P_CLS_ATTRIBUTE_CREATE_ID_g)
const H5P_OBJECT_COPY      = read_const(:H5P_CLS_OBJECT_COPY_ID_g)
const H5P_LINK_CREATE      = read_const(:H5P_CLS_LINK_CREATE_ID_g)
const H5P_LINK_ACCESS      = read_const(:H5P_CLS_LINK_ACCESS_ID_g)
# Reference constants
const H5R_OBJECT         = 0
const H5R_DATASET_REGION = 1
const H5R_OBJ_REF_BUF_SIZE      = 8
const H5R_DSET_REG_REF_BUF_SIZE = 12
# Dataspace constants
const H5S_ALL          = Hid(0)
const H5S_SCALAR       = Hid(0)
const H5S_SIMPLE       = Hid(1)
const H5S_NULL         = Hid(2)
const H5S_UNLIMITED    = typemax(Hsize)
# Dataspace selection constants
const H5S_SELECT_SET     = 0
const H5S_SELECT_OR      = 1
const H5S_SELECT_AND     = 2
const H5S_SELECT_XOR     = 3
const H5S_SELECT_NOTB    = 4
const H5S_SELECT_NOTA    = 5
const H5S_SELECT_APPEND  = 6
const H5S_SELECT_PREPEND = 7
# type classes (C enum H5T_class_t)
const H5T_INTEGER      = Hid(0)
const H5T_FLOAT        = Hid(1)
const H5T_TIME         = Hid(2)  # not supported by HDF5 library
const H5T_STRING       = Hid(3)
const H5T_BITFIELD     = Hid(4)
const H5T_OPAQUE       = Hid(5)
const H5T_COMPOUND     = Hid(6)
const H5T_REFERENCE    = Hid(7)
const H5T_ENUM         = Hid(8)
const H5T_VLEN         = Hid(9)
const H5T_ARRAY        = Hid(10)
# Character types
const H5T_CSET_ASCII   = 0
const H5T_CSET_UTF8    = 1
# Sign types (C enum H5T_sign_t)
const H5T_SGN_NONE     = Cint(0)  # unsigned
const H5T_SGN_2        = Cint(1)  # 2's complement
# Search directions
const H5T_DIR_ASCEND   = 1
const H5T_DIR_DESCEND  = 2
# String padding modes
const H5T_STR_NULLTERM = 0
const H5T_STR_NULLPAD  = 1
const H5T_STR_SPACEPAD = 2
# Other type constants
const H5T_VARIABLE     = reinterpret(UInt, -1)
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
const H5T_NATIVE_B8       = read_const(:H5T_NATIVE_B8_g)
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
# Library versions
const H5F_LIBVER_EARLIEST = 0
const H5F_LIBVER_V18      = 1
const H5F_LIBVER_V110     = 2
const H5F_LIBVER_LATEST   = H5F_LIBVER_V110

# Object reference types
struct HDF5ReferenceObj
    r::UInt64 # Size must be H5R_OBJ_REF_BUF_SIZE
end
const HDF5ReferenceObj_NULL = HDF5ReferenceObj(UInt64(0))

## Conversion between Julia types and HDF5 atomic types
hdf5_type_id(::Type{Bool})       = H5T_NATIVE_B8
hdf5_type_id(::Type{Int8})       = H5T_NATIVE_INT8
hdf5_type_id(::Type{UInt8})      = H5T_NATIVE_UINT8
hdf5_type_id(::Type{Int16})      = H5T_NATIVE_INT16
hdf5_type_id(::Type{UInt16})     = H5T_NATIVE_UINT16
hdf5_type_id(::Type{Int32})      = H5T_NATIVE_INT32
hdf5_type_id(::Type{UInt32})     = H5T_NATIVE_UINT32
hdf5_type_id(::Type{Int64})      = H5T_NATIVE_INT64
hdf5_type_id(::Type{UInt64})     = H5T_NATIVE_UINT64
hdf5_type_id(::Type{Float32})    = H5T_NATIVE_FLOAT
hdf5_type_id(::Type{Float64})    = H5T_NATIVE_DOUBLE
hdf5_type_id(::Type{HDF5ReferenceObj}) = H5T_STD_REF_OBJ

const HDF5BitsKind = Union{Bool, Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Float32, Float64}
const HDF5Scalar = Union{HDF5BitsKind, HDF5ReferenceObj}
const ScalarOrString = Union{HDF5Scalar, String}

# It's not safe to use particular id codes because these can change, so we use characteristics of the type.
const hdf5_type_map = Dict(
    (H5T_INTEGER, H5T_SGN_2, Csize_t(1)) => Int8,
    (H5T_INTEGER, H5T_SGN_2, Csize_t(2)) => Int16,
    (H5T_INTEGER, H5T_SGN_2, Csize_t(4)) => Int32,
    (H5T_INTEGER, H5T_SGN_2, Csize_t(8)) => Int64,
    (H5T_INTEGER, H5T_SGN_NONE, Csize_t(1)) => UInt8,
    (H5T_INTEGER, H5T_SGN_NONE, Csize_t(2)) => UInt16,
    (H5T_INTEGER, H5T_SGN_NONE, Csize_t(4)) => UInt32,
    (H5T_INTEGER, H5T_SGN_NONE, Csize_t(8)) => UInt64,
    (H5T_FLOAT, nothing, Csize_t(4)) => Float32,
    (H5T_FLOAT, nothing, Csize_t(8)) => Float64,
)

hdf5_type_id(::Type{S}) where {S<:AbstractString}  = H5T_C_S1

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

cset(::Type{String}) = H5T_CSET_UTF8
cset(::Type{UTF8Char}) = H5T_CSET_UTF8
cset(::Type{ASCIIChar}) = H5T_CSET_ASCII

hdf5_type_id(::Type{C}) where {C<:CharType} = H5T_C_S1

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
mutable struct HDF5File <: DataFile
    id::Hid
    filename::String

    function HDF5File(id, filename, toclose::Bool=true)
        f = new(id, filename)
        if toclose
            finalizer(close, f)
        end
        f
    end
end
convert(::Type{Hid}, f::HDF5File) = f.id
function show(io::IO, fid::HDF5File)
    if isvalid(fid)
        print(io, "HDF5 data file: ", fid.filename)
    else
        print(io, "HFD5 data file (closed): ", fid.filename)
    end
end


mutable struct HDF5Group <: DataFile
    id::Hid
    file::HDF5File         # the parent file

    function HDF5Group(id, file)
        g = new(id, file)
        finalizer(close, g)
        g
    end
end
convert(::Type{Hid}, g::HDF5Group) = g.id
function show(io::IO, g::HDF5Group)
    if isvalid(g)
        print(io, "HDF5 group: ", name(g), " (file: ", g.file.filename, ")")
    else
        print(io, "HFD5 group (invalid)")
    end
end

mutable struct HDF5Properties
    id::Hid
    class::Hid
    function HDF5Properties(id, class::Hid = H5P_DEFAULT)
        p = new(id, class)
        finalizer(close, p) #Essential, otherwise we get a memory leak, since closing file with CLOSE_STRONG is not doing it for us
        p
    end
end
HDF5Properties() = HDF5Properties(H5P_DEFAULT)
convert(::Type{Hid}, p::HDF5Properties) = p.id

mutable struct HDF5Dataset
    id::Hid
    file::HDF5File
    xfer::HDF5Properties

    function HDF5Dataset(id, file, xfer = DEFAULT_PROPERTIES)
        dset = new(id, file, xfer)
        finalizer(close, dset)
        dset
    end
end
convert(::Type{Hid}, dset::HDF5Dataset) = dset.id
function show(io::IO, dset::HDF5Dataset)
    if isvalid(dset)
        print(io, "HDF5 dataset: ", name(dset), " (file: ", dset.file.filename, " xfer_mode: ", dset.xfer.id, ")")
    else
        print(io, "HFD5 dataset (invalid)")
    end
end

mutable struct HDF5Datatype
    id::Hid
    toclose::Bool
    file::HDF5File

    function HDF5Datatype(id, toclose::Bool=true)
        nt = new(id, toclose)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
    function HDF5Datatype(id, file::HDF5File, toclose::Bool=true)
        nt = new(id, toclose, file)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
end
convert(::Type{Hid}, dtype::HDF5Datatype) = dtype.id
show(io::IO, dtype::HDF5Datatype) = print(io, "HDF5 datatype: ", h5lt_dtype_to_text(dtype.id))
hash(dtype::HDF5Datatype, h::UInt) =
    (dtype.id % UInt + h) ^ (0xadaf9b66bc962084 % UInt)
==(dt1::HDF5Datatype, dt2::HDF5Datatype) = h5t_equal(dt1, dt2) > 0

# Define an H5O Object type
const HDF5Object = Union{HDF5Group, HDF5Dataset, HDF5Datatype}

mutable struct HDF5Dataspace
    id::Hid

    function HDF5Dataspace(id)
        dspace = new(id)
        finalizer(close, dspace)
        dspace
    end
end
convert(::Type{Hid}, dspace::HDF5Dataspace) = dspace.id

mutable struct HDF5Attribute
    id::Hid
    file::HDF5File

    function HDF5Attribute(id, file)
        dset = new(id, file)
        finalizer(close, dset)
        dset
    end
end
convert(::Type{Hid}, attr::HDF5Attribute) = attr.id
show(io::IO, attr::HDF5Attribute) = isvalid(attr) ? print(io, "HDF5 attribute: ", name(attr)) : print(io, "HDF5 attribute (invalid)")

mutable struct HDF5Attributes
    parent::Union{HDF5File, HDF5Group, HDF5Dataset}
end
attrs(p::Union{HDF5File, HDF5Group, HDF5Dataset}) = HDF5Attributes(p)

# Methods for reference types
const REF_TEMP_ARRAY = Ref{HDF5ReferenceObj}()
function HDF5ReferenceObj(parent::Union{HDF5File, HDF5Group, HDF5Dataset}, name::String)
    h5r_create(REF_TEMP_ARRAY, checkvalid(parent).id, name, H5R_OBJECT, -1)
    REF_TEMP_ARRAY[]
end
==(a::HDF5ReferenceObj, b::HDF5ReferenceObj) = a.r == b.r
hash(x::HDF5ReferenceObj, h::UInt) = hash(x.r, h)

# Opaque types
struct HDF5Opaque
    data
    tag::String
end

# An empty array type
struct EmptyArray{T} end

# Stub types to encode fixed-size arrays for H5T_ARRAY
struct FixedArray{T,D,L}
  data::NTuple{L, T}
end
size(::Type{FixedArray{T,D,L}}) where {T,D,L} = D
size(x::T) where T <: FixedArray = size(T)
eltype(::Type{FixedArray{T,D,L}}) where {T,D,L} = T
eltype(x::T) where T <: FixedArray = eltype(T)

struct FixedString{N, PAD}
  data::NTuple{N, UInt8}
end
length(::Type{FixedString{N, PAD}}) where {N, PAD} = N
length(x::T) where T <: FixedString = length(T)
pad(::Type{FixedString{N, PAD}}) where {N, PAD} = PAD
pad(x::T) where T <: FixedString = pad(T)

struct VariableArray{T}
  len::Csize_t
  p::Ptr{Cvoid}
end
eltype(::Type{VariableArray{T}}) where T = T

# VLEN objects
struct HDF5Vlen{T}
    data
end
HDF5Vlen(strs::Array{S}) where {S<:String} = HDF5Vlen{chartype(S)}(strs)
HDF5Vlen(A::Array{Array{T}}) where {T<:HDF5Scalar} = HDF5Vlen{T}(A)
HDF5Vlen(A::Array{Array{T,N}}) where {T<:HDF5Scalar,N} = HDF5Vlen{T}(A)

## Types that correspond to C structs and get used for ccall
# For VLEN
struct Hvl_t
    len::Csize_t
    p::Ptr{Cvoid}
end
const HVL_SIZE = sizeof(Hvl_t) # and determine the size of the buffer needed

t2p(::Type{T}) where {T<:HDF5Scalar} = Ptr{T}
t2p(::Type{C}) where {C<:CharType} = Ptr{UInt8}
function vlenpack(v::HDF5Vlen{T}) where {T<:Union{HDF5Scalar,CharType}}
    len = length(v.data)
    Tp = t2p(T)  # Ptr{UInt8} or Ptr{T}
    h = Vector{Hvl_t}(undef,len)
    for i = 1:len
        h[i] = Hvl_t(convert(Csize_t, length(v.data[i])), convert(Ptr{Cvoid}, unsafe_convert(Tp, v.data[i])))
    end
    h
end

# For group information
struct H5Ginfo
    storage_type::Cint
    nlinks::Hsize
    max_corder::Int64
    mounted::Cint
end

# For objects
struct Hmetainfo
    index_size::Hsize
    heap_size::Hsize
end
struct H5Oinfo
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
    present::UInt64
    shared::UInt64
    meta_obj::Hmetainfo
    meta_attr::Hmetainfo
end
# For links
struct H5LInfo
    linktype::Cint
    corder_valid::Cuint
    corder::Int64
    cset::Cint
    u::UInt64
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
        cpl::HDF5Properties=DEFAULT_PROPERTIES, apl::HDF5Properties=DEFAULT_PROPERTIES; swmr=false)
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
        fid = h5f_create(filename, flag, cpl.id, apl.id)
    else
        if !h5f_is_hdf5(filename)
            error("This does not appear to be an HDF5 file")
        end
        if wr
            flag = swmr ? H5F_ACC_RDWR|H5F_ACC_SWMR_WRITE : H5F_ACC_RDWR
        else
            flag = swmr ? H5F_ACC_RDONLY|H5F_ACC_SWMR_READ : H5F_ACC_RDONLY
        end
        fid = h5f_open(filename, flag, apl.id)
    end
    if close_apl
        # Close properties manually to avoid errors when the file is
        # closed before the properties are gc'ed
        close(apl)
    end
    HDF5File(fid, filename)
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
`HDF5File` upon completion. For example with a `do` block:


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

function h5write(filename, name::String, data; pv...)
    fid = h5open(filename, "cw"; pv...)
    try
        write(fid, name, data)
    finally
        close(fid)
    end
end

function h5read(filename, name::String; pv...)
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

function h5read(filename, name_type_pair::Pair{String, DataType}; pv...)
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

function h5read(filename, name::String, indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}}; pv...)
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

function h5writeattr(filename, name::String, data::Dict)
    fid = h5open(filename, "r+")
    try
        for x in keys(data)
            attrs(fid[name])[x] = data[x]
        end
    finally
        close(fid)
    end
end

function h5readattr(filename, name::String)
    local dat
    fid = h5open(filename,"r")
    try
        a = attrs(fid[name])
        dat = Dict(x => read(a[x]) for x in names(a))
    finally
        close(fid)
    end
    dat
end

# Ensure that objects haven't been closed
isvalid(obj::Union{HDF5File, HDF5Properties, HDF5Datatype, HDF5Dataspace}) = obj.id != -1 && h5i_is_valid(obj.id)
isvalid(obj::Union{HDF5Group, HDF5Dataset, HDF5Attribute}) = obj.id != -1 && obj.file.id != -1 && h5i_is_valid(obj.id)
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Close functions

# Close functions that should try calling close regardless
function close(obj::HDF5File)
    if obj.id != -1
        h5f_close(obj.id)
        obj.id = -1
    end
    nothing
end

"""
    isopen(obj::HDF5File)

Returns `true` if `obj` has not been closed, `false` if it has been closed.
"""
isopen(obj::HDF5File) = obj.id != -1

for (h5type, h5func) in
    ((:(Union{HDF5Group, HDF5Dataset}), :h5o_close),
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
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
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

function close(obj::HDF5Properties)
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
file(f::HDF5File) = f
file(g::HDF5Group) = g.file
file(dset::HDF5Dataset) = dset.file
file(dtype::HDF5Datatype) = dtype.file
file(a::HDF5Attribute) = a.file
fd(obj::HDF5Object) = h5i_get_file_id(checkvalid(obj).id)

# Flush buffers
flush(f::Union{HDF5Object, HDF5Attribute, HDF5Datatype, HDF5File}, scope) = h5f_flush(checkvalid(f).id, scope)
flush(f::Union{HDF5Object, HDF5Attribute, HDF5Datatype, HDF5File}) = flush(f, H5F_SCOPE_GLOBAL)

# Open objects
g_open(parent::Union{HDF5File, HDF5Group}, name::String, apl::HDF5Properties=DEFAULT_PROPERTIES) = HDF5Group(h5g_open(checkvalid(parent).id, name, apl.id), file(parent))
d_open(parent::Union{HDF5File, HDF5Group}, name::String, apl::HDF5Properties=DEFAULT_PROPERTIES, xpl::HDF5Properties=DEFAULT_PROPERTIES) = HDF5Dataset(h5d_open(checkvalid(parent).id, name, apl.id), file(parent), xpl)
t_open(parent::Union{HDF5File, HDF5Group}, name::String, apl::HDF5Properties=DEFAULT_PROPERTIES) = HDF5Datatype(h5t_open(checkvalid(parent).id, name, apl.id), file(parent))
a_open(parent::Union{HDF5File, HDF5Object}, name::String) = HDF5Attribute(h5a_open(checkvalid(parent).id, name, H5P_DEFAULT), file(parent))
# Object (group, named datatype, or dataset) open
function h5object(obj_id::Hid, parent)
    obj_type = h5i_get_type(obj_id)
    obj_type == H5I_GROUP ? HDF5Group(obj_id, file(parent)) :
    obj_type == H5I_DATATYPE ? HDF5Datatype(obj_id, file(parent)) :
    obj_type == H5I_DATASET ? HDF5Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
o_open(parent, path::String) = h5object(h5o_open(checkvalid(parent).id, path), parent)
function gettype(parent, path::String)
    obj_id = h5o_open(checkvalid(parent).id, path)
    t = h5i_get_type(obj_id)
    h5o_close(obj_id)
    t
end
# Get the root group
root(h5file::HDF5File) = g_open(h5file, "/")
root(obj::Union{HDF5Group, HDF5Dataset}) = g_open(file(obj), "/")
# getindex syntax: obj2 = obj1[path]
#getindex(parent::Union{HDF5File, HDF5Group}, path::String) = o_open(parent, path)
getindex(dset::HDF5Dataset, name::String) = a_open(dset, name)
getindex(x::HDF5Attributes, name::String) = a_open(x.parent, name)

const hdf5_obj_open = Dict(
    H5I_DATASET   => (d_open, H5P_DATASET_ACCESS, H5P_DATASET_XFER),
    H5I_DATATYPE  => (t_open, H5P_DATATYPE_ACCESS),
    H5I_GROUP     => (g_open, H5P_GROUP_ACCESS),
)
function getindex(parent::Union{HDF5File, HDF5Group}, path::String; pv...)
    objtype = gettype(parent, path)
    fun, propids = hdf5_obj_open[objtype]
    props = [p_create(prop; pv...) for prop in propids]
    obj = fun(parent, path, props...)
end

# Path manipulation
function split1(path::String)
    off = findfirst(isequal('/'),path)
    if off === nothing
        return path, nothing
    else
        if off == 1
            # Matches the root group
            return "/", path[2:end]
        else
            return path[1:prevind(path, off)], path[nextind(path, off):end]
        end
    end
end

function g_create(parent::Union{HDF5File, HDF5Group}, path::String,
                  lcpl::HDF5Properties=_link_properties(path),
                  dcpl::HDF5Properties=DEFAULT_PROPERTIES)
    HDF5Group(h5g_create(checkvalid(parent).id, path, lcpl.id, dcpl.id), file(parent))
end
function g_create(f::Function, parent::Union{HDF5File, HDF5Group}, args...)
    g = g_create(parent, args...)
    try
        f(g)
    finally
        close(g)
    end
end

function d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype,
                  dspace::HDF5Dataspace, lcpl::HDF5Properties, dcpl::HDF5Properties,
                  dapl::HDF5Properties, dxpl::HDF5Properties)
    HDF5Dataset(h5d_create(checkvalid(parent).id, path, dtype.id, dspace.id, lcpl.id,
                dcpl.id, dapl.id), file(parent), dxpl)
end

# Setting dset creation properties with name/value pairs
function d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, dspace::HDF5Dataspace; pv...)
    dcpl = isempty(pv) ? DEFAULT_PROPERTIES : p_create(H5P_DATASET_CREATE; pv...)
    dxpl = isempty(pv) ? DEFAULT_PROPERTIES : p_create(H5P_DATASET_XFER; pv...)
    dapl = isempty(pv) ? DEFAULT_PROPERTIES : p_create(H5P_DATASET_ACCESS; pv...)
    HDF5Dataset(h5d_create(checkvalid(parent).id, path, dtype.id, dspace.id, _link_properties(path), dcpl.id, dapl.id), file(parent), dxpl)
end
d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, dspace_dims::Dims; pv...) = d_create(checkvalid(parent), path, dtype, dataspace(dspace_dims); pv...)
d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, dspace_dims::Tuple{Dims,Dims}; pv...) = d_create(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::Type, dspace_dims; pv...) = d_create(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
t_create(class_id, sz) = HDF5Datatype(h5t_create(class_id, sz))
function t_commit(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, lcpl::HDF5Properties, tcpl::HDF5Properties, tapl::HDF5Properties)
    h5p_set_char_encoding(lcpl.id, cset(typeof(path)))
    h5t_commit(checkvalid(parent).id, path, dtype.id, lcpl.id, tcpl.id, tapl.id)
    dtype.file = file(parent)
    dtype
end
function t_commit(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, lcpl::HDF5Properties, tcpl::HDF5Properties)
    h5p_set_char_encoding(lcpl.id, cset(typeof(path)))
    h5t_commit(checkvalid(parent).id, path, dtype.id, lcpl.id, tcpl.id, H5P_DEFAULT)
    dtype.file = file(parent)
    dtype
end
function t_commit(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, lcpl::HDF5Properties)
    h5p_set_char_encoding(lcpl.id, cset(typeof(path)))
    h5t_commit(checkvalid(parent).id, path, dtype.id, lcpl.id, H5P_DEFAULT, H5P_DEFAULT)
    dtype.file = file(parent)
    dtype
end
t_commit(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype) = t_commit(parent, path, dtype, p_create(H5P_LINK_CREATE))

a_create(parent::Union{HDF5File, HDF5Object}, name::String, dtype::HDF5Datatype, dspace::HDF5Dataspace) = HDF5Attribute(h5a_create(checkvalid(parent).id, name, dtype.id, dspace.id), file(parent))
function p_create(class; pv...)
  p = HDF5Properties(h5p_create(class), class)
  for (k,v) in pairs(pv)
    if hdf5_prop_get_set[k][3] == class
      p[k] = v
    end
  end
  return p
end

# Delete objects
a_delete(parent::Union{HDF5File, HDF5Object}, path::String) = h5a_delete(checkvalid(parent).id, path)
o_delete(parent::Union{HDF5File, HDF5Group}, path::String, lapl::HDF5Properties) = h5l_delete(checkvalid(parent).id, path, lapl.id)
o_delete(parent::Union{HDF5File, HDF5Group}, path::String) = h5l_delete(checkvalid(parent).id, path, H5P_DEFAULT)
o_delete(obj::HDF5Object) = o_delete(parent(obj), ascii(split(name(obj),"/")[end]))

# Copy objects
o_copy(src_parent::Union{HDF5File, HDF5Group}, src_path::String, dst_parent::Union{HDF5File, HDF5Group}, dst_path::String) = h5o_copy(checkvalid(src_parent).id, src_path, checkvalid(dst_parent).id, dst_path, H5P_DEFAULT, _link_properties(dst_path))
o_copy(src_obj::HDF5Object, dst_parent::Union{HDF5File, HDF5Group}, dst_path::String) = h5o_copy(checkvalid(src_obj).id, ".", checkvalid(dst_parent).id, dst_path, H5P_DEFAULT, _link_properties(dst_path))

# Assign syntax: obj[path] = value
# Creates a dataset unless obj is a dataset, in which case it creates an attribute
setindex!(dset::HDF5Dataset, val, name::String) = a_write(dset, name, val)
setindex!(x::HDF5Attributes, val, name::String) = a_write(x.parent, name, val)
# Getting and setting properties: p[:chunk] = dims, p[:compress] = 6
function setindex!(p::HDF5Properties, val, name::Symbol)
    funcget, funcset = hdf5_prop_get_set[name]
    funcset(p, val...)
    return p
end
# Create a dataset with properties: obj[path, prop = val, ...] = val
function setindex!(parent::Union{HDF5File, HDF5Group}, val, path::String; pv...)
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
function exists(parent::Union{HDF5File, HDF5Group}, path::String, lapl::HDF5Properties)
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !h5l_exists(parent.id, first, lapl.id)
        return false
    end
    ret = true
    if rest !== nothing && !isempty(rest)
        obj = parent[first]
        ret = exists(obj, rest, lapl)
        close(obj)
    end
    ret
end
exists(attr::HDF5Attributes, path::String) = h5a_exists(checkvalid(attr.parent).id, path)
exists(dset::Union{HDF5Dataset, HDF5Datatype}, path::String) = h5a_exists(checkvalid(dset).id, path)
exists(parent::Union{HDF5File, HDF5Group}, path::String) = exists(parent, path, HDF5Properties())
has(parent::Union{HDF5File, HDF5Group, HDF5Dataset}, path::String) = exists(parent, path)

# Querying items in the file
const H5GINFO_TEMP_ARRAY = Ref{H5Ginfo}()
function info(obj::Union{HDF5Group,HDF5File})
    h5g_get_info(obj, H5GINFO_TEMP_ARRAY)
    H5GINFO_TEMP_ARRAY[]
end

const H5OINFO_TEMP_ARRAY = Ref{H5Oinfo}()
function objinfo(obj::Union{HDF5File, HDF5Object})
    h5o_get_info(obj.id, H5OINFO_TEMP_ARRAY)
    H5OINFO_TEMP_ARRAY[]
end

const LENGTH_TEMP_ARRAY = Ref{UInt64}()
function length(x::Union{HDF5Group,HDF5File})
    h5g_get_num_objs(x.id, LENGTH_TEMP_ARRAY)
    LENGTH_TEMP_ARRAY[]
end

function length(x::HDF5Attributes)
    objinfo(x.parent).num_attrs
end

isempty(x::Union{HDF5Dataset,HDF5Group,HDF5File}) = length(x) == 0
function size(obj::Union{HDF5Dataset, HDF5Attribute})
    dspace = dataspace(obj)
    dims, maxdims = get_dims(dspace)
    close(dspace)
    convert(Tuple{Vararg{Int}}, dims)
end
size(dset::Union{HDF5Dataset, HDF5Attribute}, d) = d > ndims(dset) ? 1 : size(dset)[d]
length(dset::Union{HDF5Dataset, HDF5Attribute}) = prod(size(dset))
ndims(dset::Union{HDF5Dataset, HDF5Attribute}) = length(size(dset))
function eltype(dset::Union{HDF5Dataset, HDF5Attribute})
    T = Any
    dtype = datatype(dset)
    try
        T = hdf5_to_julia_eltype(dtype)
    finally
        close(dtype)
    end
    T
end
function isnull(obj::Union{HDF5Dataset, HDF5Attribute})
    dspace = dataspace(obj)
    ret = h5s_get_simple_extent_type(dspace.id) == H5S_NULL
    close(dspace)
    ret
end

# filename and name
filename(obj::Union{HDF5File, HDF5Group, HDF5Dataset, HDF5Attribute, HDF5Datatype}) = h5f_get_name(checkvalid(obj).id)
name(obj::Union{HDF5File, HDF5Group, HDF5Dataset, HDF5Datatype}) = h5i_get_name(checkvalid(obj).id)
name(attr::HDF5Attribute) = h5a_get_name(attr.id)
function names(x::Union{HDF5Group,HDF5File})
    checkvalid(x)
    n = length(x)
    [h5l_get_name_by_idx(x,i) for i = 1:n]
end

function h5l_get_name_by_idx(x::Union{HDF5Group,HDF5File}, i)
    len = h5l_get_name_by_idx(x.id, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, C_NULL, 0, H5P_DEFAULT)
    buf = Base.StringVector(len)
    h5l_get_name_by_idx(x.id, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, buf, len+1, H5P_DEFAULT)
    return String(buf)
end

function names(x::HDF5Attributes)
    checkvalid(x.parent)
    n = length(x)
    [h5a_get_name_by_idx(x,i) for i = 1:n]
end

function h5a_get_name_by_idx(x::HDF5Attributes, i)
    len = h5a_get_name_by_idx(x.parent.id, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, C_NULL, 0, H5P_DEFAULT)
    buf = Base.StringVector(len)
    h5a_get_name_by_idx(x.parent.id, ".", H5_INDEX_NAME, H5_ITER_INC, i-1, buf, len+1, H5P_DEFAULT)
    return String(buf)
end

# iteration by objects
function iterate(parent::Union{HDF5File, HDF5Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(h5o_open_by_idx(checkvalid(parent).id, ".", H5_INDEX_NAME, H5_ITER_INC, n-1, H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
end

lastindex(dset::HDF5Dataset) = length(dset)
lastindex(dset::HDF5Dataset, d::Int) = size(dset, d)

function parent(obj::Union{HDF5File, HDF5Group, HDF5Dataset})
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
datatype(dset::HDF5Dataset) = HDF5Datatype(h5d_get_type(checkvalid(dset).id), file(dset))
# Get the datatype of an attribute
datatype(dset::HDF5Attribute) = HDF5Datatype(h5a_get_type(checkvalid(dset).id), file(dset))

# Create a datatype from in-memory types
datatype(x::HDF5Scalar) = HDF5Datatype(hdf5_type_id(typeof(x)), false)
datatype(::Type{T}) where {T<:HDF5Scalar} = HDF5Datatype(hdf5_type_id(T), false)
datatype(A::AbstractArray{T}) where {T<:HDF5Scalar} = HDF5Datatype(hdf5_type_id(T), false)
function datatype(::Type{Complex{T}}) where {T<:HDF5Scalar}
  COMPLEX_SUPPORT[] || error("complex support disabled. call HDF5.enable_complex_support() to enable")
  dtype = h5t_create(H5T_COMPOUND, 2*sizeof(T))
  h5t_insert(dtype, COMPLEX_FIELD_NAMES[][1], 0, hdf5_type_id(T))
  h5t_insert(dtype, COMPLEX_FIELD_NAMES[][2], sizeof(T), hdf5_type_id(T))
  return HDF5Datatype(dtype)
end
datatype(x::Complex{T}) where {T<:HDF5Scalar} = datatype(typeof(x))
datatype(A::AbstractArray{Complex{T}}) where {T<:HDF5Scalar} = datatype(eltype(A))

function datatype(str::String)
    type_id = h5t_copy(hdf5_type_id(typeof(str)))
    h5t_set_size(type_id, max(sizeof(str), 1))
    h5t_set_cset(type_id, cset(typeof(str)))
    HDF5Datatype(type_id)
end
function datatype(str::Array{S}) where {S<:String}
    type_id = h5t_copy(hdf5_type_id(S))
    h5t_set_size(type_id, H5T_VARIABLE)
    h5t_set_cset(type_id, cset(S))
    HDF5Datatype(type_id)
end
datatype(A::HDF5Vlen{T}) where {T<:HDF5Scalar} = HDF5Datatype(h5t_vlen_create(hdf5_type_id(T)))
function datatype(str::HDF5Vlen{C}) where {C<:CharType}
    type_id = h5t_copy(hdf5_type_id(C))
    h5t_set_size(type_id, 1)
    h5t_set_cset(type_id, cset(C))
    HDF5Datatype(h5t_vlen_create(type_id))
end

sizeof(dtype::HDF5Datatype) = h5t_get_size(dtype)

# Get the dataspace of a dataset
dataspace(dset::HDF5Dataset) = HDF5Dataspace(h5d_get_space(checkvalid(dset).id))
# Get the dataspace of an attribute
dataspace(attr::HDF5Attribute) = HDF5Dataspace(h5a_get_space(checkvalid(attr).id))

# Create a dataspace from in-memory types
dataspace(x::Union{T, Complex{T}}) where {T<:HDF5Scalar} = HDF5Dataspace(h5s_create(H5S_SCALAR))

function _dataspace(sz::Tuple{Vararg{Int}}, max_dims::Union{Dims, Tuple{}}=())
    dims = Vector{Hsize}(undef,length(sz))
    any_zero = false
    for i = 1:length(sz)
        dims[end-i+1] = sz[i]
        any_zero |= sz[i] == 0
    end

    if any_zero
        space_id = h5s_create(H5S_NULL)
    else
        if isempty(max_dims)
            space_id = h5s_create_simple(length(dims), dims, dims)
        else
            # This allows max_dims to be specified as -1 without
            # triggering an overflow exception due to the signed->
            # unsigned conversion.
            space_id = h5s_create_simple(length(dims), dims,
                                         reinterpret(Hsize, convert(Vector{Hssize},
                                                                    [reverse(max_dims)...])))
        end
    end
    HDF5Dataspace(space_id)
end
dataspace(A::AbstractArray; max_dims::Union{Dims, Tuple{}} = ()) = _dataspace(size(A), max_dims)
dataspace(str::String) = HDF5Dataspace(h5s_create(H5S_SCALAR))
dataspace(v::HDF5Vlen; max_dims::Union{Dims, Tuple{}}=()) = _dataspace(size(v.data), max_dims)
dataspace(n::Nothing) = HDF5Dataspace(h5s_create(H5S_NULL))
dataspace(sz::Dims; max_dims::Union{Dims, Tuple{}}=()) = _dataspace(sz, max_dims)
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union{Dims, Tuple{}}=()) = _dataspace(tuple(sz1, sz2, sz3...), max_dims)


get_dims(dspace::HDF5Dataspace) = h5s_get_simple_extent_dims(dspace.id)

"""
    get_dims(dset::HDF5Dataset)

Get the array dimensions from a dataset and return a tuple of dims and maxdims.
"""
get_dims(dset::HDF5Dataset) = get_dims(dataspace(checkvalid(dset)))

"""
    set_dims!(dset::HDF5Dataset, new_dims::Dims)

Change the current dimensions of a dataset to `new_dims`, limited by
`max_dims = get_dims(dset)[2]`. Reduction is possible and leads to loss of truncated data.
"""
set_dims!(dset::HDF5Dataset, new_dims::Dims) = h5d_set_extent(checkvalid(dset), Hsize[reverse(new_dims)...])

"""
    start_swmr_write(h5::HDF5File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://support.hdfgroup.org/HDF5/doc/RM/RM_H5F.html#File-StartSwmrWrite).
"""
start_swmr_write(h5::HDF5File) = h5f_start_swmr_write(h5.id)

refresh(ds::HDF5Dataset) = h5d_refresh(checkvalid(ds).id)
flush(ds::HDF5Dataset) = h5d_flush(checkvalid(ds).id)

# Generic read functions
for (fsym, osym, ptype) in
    ((:d_read, :d_open, Union{HDF5File, HDF5Group}),
     (:a_read, :a_open, Union{HDF5File, HDF5Group, HDF5Dataset, HDF5Datatype}))
    @eval begin
        function ($fsym)(parent::$ptype, name::String)
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
function read(parent::Union{HDF5File, HDF5Group}, name::String; pv...)
    obj = getindex(parent, name; pv...)
    val = read(obj)
    close(obj)
    val
end

function read(parent::Union{HDF5File, HDF5Group}, name_type_pair::Pair{String, DataType}; pv...)
    obj = getindex(parent, name_type_pair[1]; pv...)
    val = read(obj, name_type_pair[2])
    close(obj)
    val
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5Datatype. Specific file formats should provide their own read(dset).
const DatasetOrAttribute = Union{HDF5Dataset, HDF5Attribute}

function read(obj::DatasetOrAttribute)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    read(obj, T)
end

function getindex(dset::HDF5Dataset, I...)
    dtype = datatype(dset)
    T = get_jl_type(dtype)
    read(dset, T, I...)
end

# generic read function
function read(obj::DatasetOrAttribute, ::Type{T}, I...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    !isempty(I) && obj isa HDF5Attribute && error("HDF5 attributes do not support hyperslab selections")

    filetype = datatype(obj)
    memtype = HDF5Datatype(h5t_get_native_type(filetype.id))  # padded layout in memory
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
    stype == H5S_NULL && return T[]

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

    if obj isa HDF5Dataset
        h5d_read(obj.id, memtype.id, memspace.id, dspace.id, obj.xfer.id, buf)
    else
        h5a_read(obj.id, memtype.id, buf)
    end

    out = do_normalize(T) ? normalize_types.(buf) : buf

    xfer_id = obj isa HDF5Dataset ? obj.xfer.id : H5P_DEFAULT
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

# Read OPAQUE datasets and attributes
function read(obj::DatasetOrAttribute, ::Type{HDF5Opaque})
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
    HDF5Opaque(data, tag)
end

# Array constructor for datasets
Array(x::HDF5Dataset) = read(x)

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
function getindex(parent::Union{HDF5File, HDF5Group, HDF5Dataset}, r::HDF5ReferenceObj)
    r == HDF5ReferenceObj_NULL && error("Reference is null")
    obj_id = h5r_dereference(checkvalid(parent).id, H5R_OBJECT, r)
    h5object(obj_id, parent)
end

# convert special types to native julia types
normalize_types(x) = x
normalize_types(x::NamedTuple{T}) where T = NamedTuple{T}(map(normalize_types, values(x)))
normalize_types(x::Cstring) = unsafe_string(x)
normalize_types(x::FixedString) = unpad(String(collect(x.data)), pad(x))
normalize_types(x::FixedArray) = normalize_types.(reshape(collect(x.data), size(x)...))
normalize_types(x::VariableArray) = normalize_types.(copy(unsafe_wrap(Array, convert(Ptr{eltype(x)}, x.p), x.len, own=false)))

do_normalize(::Type{T}) where T = false
do_normalize(::Type{NamedTuple{T, U}}) where T where U = any(i -> do_normalize(fieldtype(U,i)), 1:fieldcount(U))
do_normalize(::Type{T}) where T <: Union{Cstring, FixedString, FixedArray, VariableArray} = true

do_reclaim(::Type{T}) where T = false
do_reclaim(::Type{NamedTuple{T, U}}) where T where U =  any(i -> do_reclaim(fieldtype(U,i)), 1:fieldcount(U))
do_reclaim(::Type{T}) where T <: Union{Cstring, VariableArray} = true

read(attr::HDF5Attributes, name::String) = a_read(attr.parent, name)

# Reading with mmap
function iscontiguous(obj::HDF5Dataset)
    prop = h5d_get_create_plist(checkvalid(obj).id)
    try
        h5p_get_layout(prop) == H5D_CONTIGUOUS
    finally
        h5p_close(prop)
    end
end

ismmappable(::Type{Array{T}}) where {T<:HDF5Scalar} = true
ismmappable(::Type) = false
ismmappable(obj::HDF5Dataset, ::Type{T}) where {T} = ismmappable(T) && iscontiguous(obj)
ismmappable(obj::HDF5Dataset) = ismmappable(obj, hdf5_to_julia(obj))

function readmmap(obj::HDF5Dataset, ::Type{Array{T}}) where {T}
    dims = size(obj)
    if isempty(dims)
        return T[]
    end
    if !Sys.iswindows()
        local fdint
        prop = h5d_get_access_plist(checkvalid(obj).id)
        try
            ret = Ref{Ptr{Cint}}()
            h5f_get_vfd_handle(obj.file.id, prop, ret)
            fdint = unsafe_load(ret[])
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
        intent = Ref{Cuint}()
        h5f_get_intent(obj.file, intent)
        if intent[] == H5F_ACC_RDONLY
            flag = "r"
        else
            flag = "r+"
        end
        fd = open(obj.file.filename, flag)
    end

    offset = h5d_get_offset(obj.id)
    if offset == -1 % Haddr
        error("Error mmapping array")
    end
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

function readmmap(obj::HDF5Dataset)
    T = hdf5_to_julia(obj)
    ismmappable(T) || error("Cannot mmap datasets of type $T")
    iscontiguous(obj) || error("Cannot mmap discontiguous dataset")
    readmmap(obj, T)
end

# Generic write
function write(parent::Union{HDF5File, HDF5Group}, name1::String, val1, name2::String, val2, nameval...)
    if !iseven(length(nameval))
        error("name, value arguments must come in pairs")
    end
    write(parent, name1, val1)
    write(parent, name2, val2)
    for i = 1:2:length(nameval)
        thisname = nameval[i]
        if !isa(thisname, String)
            error("Argument ", i+5, " should be a string, but it's a ", typeof(thisname))
        end
        write(parent, thisname, nameval[i+1])
    end
end

# Plain dataset & attribute writes
# Due to method ambiguities we generate these explicitly

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = d_create(parent, name, data; properties...)
for (privatesym, fsym, ptype) in
    ((:_d_create, :d_create, Union{HDF5File, HDF5Group}),
     (:_a_create, :a_create, Union{HDF5File, HDF5Group, HDF5Dataset, HDF5Datatype}))
    @eval begin
        # Generic create (hidden)
        function ($privatesym)(parent::$ptype, name::String, data; pv...)
            local obj
            dtype = datatype(data)
            dspace = dataspace(data)
            try
                obj = ($fsym)(parent, name, dtype, dspace; pv...)
            finally
                close(dspace)
            end
            obj, dtype
        end
        # Scalar types
        ($fsym)(parent::$ptype, name::String, data::Union{T, AbstractArray{T}}; pv...) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}} =
            ($privatesym)(parent, name, data; pv...)
        # VLEN types
        ($fsym)(parent::$ptype, name::String, data::HDF5Vlen{T}; pv...) where {T<:Union{HDF5Scalar,CharType}} =
            ($privatesym)(parent, name, data; pv...)
    end
end
# Create and write, closing the objects upon exit
for (privatesym, fsym, ptype, crsym) in
    ((:_d_write, :d_write, Union{HDF5File, HDF5Group}, :d_create),
     (:_a_write, :a_write, Union{HDF5File, HDF5Object, HDF5Datatype}, :a_create))
    @eval begin
        # Generic write (hidden)
        function ($privatesym)(parent::$ptype, name::String, data; pv...)
            obj, dtype = ($crsym)(parent, name, data; pv...)
            try
                writearray(obj, dtype.id, data)
            finally
                close(obj)
                close(dtype)
            end
        end
        # Scalar types
        ($fsym)(parent::$ptype, name::String, data::Union{T, AbstractArray{T}}; pv...) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}} =
            ($privatesym)(parent, name, data; pv...)
        # VLEN types
        ($fsym)(parent::$ptype, name::String, data::HDF5Vlen{T}; pv...) where {T<:Union{HDF5Scalar,CharType}} =
            ($privatesym)(parent, name, data; pv...)
    end
end
# Write to already-created objects
# Scalars
function write(obj::DatasetOrAttribute, x::Union{T, Array{T}}) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}}
    dtype = datatype(x)
    try
        writearray(obj, dtype.id, x)
    finally
       close(dtype)
    end
end
# VLEN types
function write(obj::DatasetOrAttribute, data::HDF5Vlen{T}) where {T<:Union{HDF5Scalar,CharType}}
    dtype = datatype(data)
    try
        writearray(obj, dtype.id, data)
    finally
        close(dtype)
    end
end
# For plain files and groups, let "write(obj, name, val; properties...)" mean "d_write"
write(parent::Union{HDF5File, HDF5Group}, name::String, data::Union{T, AbstractArray{T}}; pv...) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}} =
    d_write(parent, name, data; pv...)
# For datasets, "write(dset, name, val; properties...)" means "a_write"
write(parent::HDF5Dataset, name::String, data::Union{T, AbstractArray{T}}; pv...) where {T<:ScalarOrString} =
    a_write(parent, name, data; pv...)


# Indexing

Base.eachindex(::IndexLinear, A::HDF5Dataset) = Base.OneTo(length(A))
Base.axes(dset::HDF5Dataset) = map(Base.OneTo, size(dset))

# Write to a subset of a dataset using array slices: dataset[:,:,10] = array

setindex!(dset::HDF5Dataset, x, I::Union{AbstractRange,Integer,Colon}...) =
    _setindex!(dset, x, Base.to_indices(dset, I)...)
function _setindex!(dset::HDF5Dataset, X::Array, I::Union{AbstractRange{Int},Int}...)
    T = hdf5_to_julia(dset)
    _setindex!(dset, T, X, I...)
end
function _setindex!(dset::HDF5Dataset,T::Type, X::Array, I::Union{AbstractRange{Int},Int}...)
    if !(T <: Array)
        error("Dataset indexing (hyperslab) is available only for arrays")
    end
    ET = eltype(T)
    if !(ET <: Union{HDF5Scalar, Complex{<:HDF5Scalar}})
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
function _setindex!(dset::HDF5Dataset, X::AbstractArray, I::Union{AbstractRange{Int},Int}...)
    T = hdf5_to_julia(dset)
    if !(T <: Array)
        error("Hyperslab interface is available only for arrays")
    end
    Y = convert(Array{eltype(T), ndims(X)}, X)
    _setindex!(dset, Y, I...)
end
function _setindex!(dset::HDF5Dataset, x::Number, I::Union{AbstractRange{Int},Int}...)
    T = hdf5_to_julia(dset)
    if !(T <: Array)
        error("Hyperslab interface is available only for arrays")
    end
    X = fill(convert(eltype(T), x), map(length, I))
    _setindex!(dset, X, I...)
end

function hyperslab(dspace::HDF5Dataspace, I::Union{AbstractRange{Int},Int}...)
    local dsel_id
    try
        dims, maxdims = get_dims(dspace)
        n_dims = length(dims)
        if length(I) != n_dims
            error("Wrong number of indices supplied, supplied length $(length(I)) but expected $(n_dims).")
        end
        dsel_id = h5s_copy(dspace.id)
        dsel_start  = Vector{Hsize}(undef,n_dims)
        dsel_stride = Vector{Hsize}(undef,n_dims)
        dsel_count  = Vector{Hsize}(undef,n_dims)
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
    HDF5Dataspace(dsel_id)
end

function hyperslab(dset::HDF5Dataset, I::Union{AbstractRange{Int},Int}...)
    dspace = dataspace(dset)
    return hyperslab(dspace, I...)
end

# Link to bytes in an external file
# If you need to link to multiple segments, use low-level interface
function d_create_external(parent::Union{HDF5File, HDF5Group}, name::String, filepath::String, t, sz::Dims, offset::Integer)
    checkvalid(parent)
    p = p_create(H5P_DATASET_CREATE)
    h5p_set_external(p, filepath, Int(offset), prod(sz)*sizeof(t))
    d_create(parent, name, datatype(t), dataspace(sz), HDF5Properties(), p)
end
d_create_external(parent::Union{HDF5File, HDF5Group}, name::String, filepath::String, t::Type, sz::Dims) = d_create_external(parent, name, filepath, t, sz, 0)

function do_write_chunk(dataset::HDF5Dataset, offset, chunk_bytes::Vector{UInt8}, filter_mask=0)
    checkvalid(dataset)
    offs = collect(Hsize, reverse(offset)) .- 1
    h5do_write_chunk(dataset, H5P_DEFAULT, UInt32(filter_mask), offs, length(chunk_bytes), chunk_bytes)
end

struct HDF5ChunkStorage
    dataset::HDF5Dataset
end

function setindex!(chunk_storage::HDF5ChunkStorage, v::Tuple{<:Integer,Vector{UInt8}}, index::Integer...)
    do_write_chunk(chunk_storage.dataset, Hsize.(index), v[2], UInt32(v[1]))
end

# end of high-level interface


### HDF5 utilities ###
readarray(dset::HDF5Dataset, type_id, buf) = h5d_read(dset.id, type_id, buf, dset.xfer.id)
readarray(attr::HDF5Attribute, type_id, buf) = h5a_read(attr.id, type_id, buf)
writearray(dset::HDF5Dataset, type_id, buf) = h5d_write(dset.id, type_id, buf, dset.xfer.id)
writearray(attr::HDF5Attribute, type_id, buf) = h5a_write(attr.id, type_id, buf)

# Determine Julia "native" type from the class, datatype, and dataspace
# For datasets, defined file formats should use attributes instead
function hdf5_to_julia(obj::Union{HDF5Dataset, HDF5Attribute})
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
        T = HDF5Opaque
    elseif class_id == H5T_VLEN
        super_id = h5t_get_super(objtype.id)
        T = HDF5Vlen{hdf5_to_julia_eltype(HDF5Datatype(super_id))}
    elseif class_id == H5T_COMPOUND
        T = get_mem_compatible_jl_type(objtype)
    elseif class_id == H5T_ARRAY
        T = get_mem_compatible_jl_type(objtype)
    else
        error("Class id ", class_id, " is not yet supported")
    end
    return T
end

function get_jl_type(objtype::HDF5Datatype)
    class_id = h5t_get_class(objtype.id)
    if class_id == H5T_OPAQUE
        return HDF5Opaque
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

function get_mem_compatible_jl_type(objtype::HDF5Datatype)
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
            return hdf5_type_map[(class_id, is_signed, native_size)]
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
                return hdf5_type_map[(H5T_INTEGER, is_signed, native_size)]
            finally
                h5t_close(native_type)
            end
        finally
            h5t_close(super_type)
        end
    elseif class_id == H5T_REFERENCE
        # TODO update to use version 1.12 reference functions/types
        return HDF5ReferenceObj
    elseif class_id == H5T_VLEN
        superid = h5t_get_super(objtype.id)
        return VariableArray{get_mem_compatible_jl_type(HDF5Datatype(superid))}
    elseif class_id == H5T_COMPOUND
        N = h5t_get_nmembers(objtype.id)

        membernames = ntuple(N) do i
            h5t_get_member_name(objtype.id, i-1)
        end

        membertypes = ntuple(N) do i
            dtype = HDF5Datatype(h5t_get_member_type(objtype.id, i-1))
            return get_mem_compatible_jl_type(dtype)
        end

        # check if should be interpreted as complex
        iscomplex = COMPLEX_SUPPORT[] &&
                    N == 2 &&
                    (membernames == COMPLEX_FIELD_NAMES[]) &&
                    (membertypes[1] == membertypes[2]) &&
                    (membertypes[1] <: HDF5Scalar)

        if iscomplex
            return Complex{membertypes[1]}
        else
            return NamedTuple{Symbol.(membernames), Tuple{membertypes...}}
        end
    elseif class_id == H5T_ARRAY
        nd = h5t_get_array_ndims(objtype.id)
        dims = Vector{Hsize}(undef,nd)
        h5t_get_array_dims(objtype.id, dims)
        eltyp = HDF5Datatype(h5t_get_super(objtype.id))
        elT = get_mem_compatible_jl_type(eltyp)
        dimsizes = ntuple(i -> Int(dims[nd-i+1]), nd)  # reverse order
        return FixedArray{elT, dimsizes, prod(dimsizes)}
    end
    error("Class id ", class_id, " is not yet supported")
end

### Convenience wrappers ###
# These supply default values where possible
# See also the "special handling" section below
h5a_write(attr_id::Hid, mem_type_id::Hid, buf::String) = h5a_write(attr_id, mem_type_id, unsafe_wrap(Vector{UInt8}, pointer(buf), ncodeunits(buf)))
function h5a_write(attr_id::Hid, mem_type_id::Hid, x::T) where {T<:Union{HDF5Scalar, Complex{<:HDF5Scalar}}}
    tmp = Ref{T}(x)
    h5a_write(attr_id, mem_type_id, tmp)
end
function h5a_write(attr_id::Hid, memtype_id::Hid, strs::Array{S}) where {S<:String}
    p = Ref{Cstring}(strs)
    h5a_write(attr_id, memtype_id, p)
end
function h5a_write(attr_id::Hid, memtype_id::Hid, v::HDF5Vlen{T}) where {T<:Union{HDF5Scalar,CharType}}
    vp = vlenpack(v)
    h5a_write(attr_id, memtype_id, vp)
end
h5a_create(loc_id::Hid, name::String, type_id::Hid, space_id::Hid) = h5a_create(loc_id, name, type_id, space_id, _attr_properties(name), H5P_DEFAULT)
h5a_open(obj_id::Hid, name::String) = h5a_open(obj_id, name, H5P_DEFAULT)
h5d_create(loc_id::Hid, name::String, type_id::Hid, space_id::Hid) = h5d_create(loc_id, name, type_id, space_id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5d_open(obj_id::Hid, name::String) = h5d_open(obj_id, name, H5P_DEFAULT)
function h5d_read(dataset_id::Hid, memtype_id::Hid, buf::AbstractArray, xfer::Hid=H5P_DEFAULT)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot read arrays with a different stride than `Array`"))
    h5d_read(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
end
function h5d_write(dataset_id::Hid, memtype_id::Hid, buf::AbstractArray, xfer::Hid=H5P_DEFAULT)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
end
function h5d_write(dataset_id::Hid, memtype_id::Hid, str::String, xfer::Hid=H5P_DEFAULT)
    ccall((:H5Dwrite, libhdf5), Herr, (Hid, Hid, Hid, Hid, Hid, Cstring), dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, str)
end
function h5d_write(dataset_id::Hid, memtype_id::Hid, x::T, xfer::Hid=H5P_DEFAULT) where {T<:Union{HDF5Scalar, Complex{<:HDF5Scalar}}}
    tmp = Ref{T}(x)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, tmp)
end
function h5d_write(dataset_id::Hid, memtype_id::Hid, strs::Array{S}, xfer::Hid=H5P_DEFAULT) where {S<:String}
    p = Ref{Cstring}(strs)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, p)
end
function h5d_write(dataset_id::Hid, memtype_id::Hid, v::HDF5Vlen{T}, xfer::Hid=H5P_DEFAULT) where {T<:Union{HDF5Scalar,CharType}}
    vp = vlenpack(v)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, vp)
end
h5f_create(filename::String) = h5f_create(filename, H5F_ACC_TRUNC, H5P_DEFAULT, H5P_DEFAULT)
h5f_open(filename::String, mode) = h5f_open(filename, mode, H5P_DEFAULT)
h5g_create(obj_id::Hid, name::String) = h5g_create(obj_id, name, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT)
h5g_create(obj_id::Hid, name::String, lcpl_id, gcpl_id) = h5g_create(obj_id, name, lcpl_id, gcpl_id, H5P_DEFAULT)
h5g_open(file_id::Hid, name::String) = h5g_open(file_id, name, H5P_DEFAULT)
h5l_exists(loc_id::Hid, name::String) = h5l_exists(loc_id, name, H5P_DEFAULT)
h5o_open(obj_id::Hid, name::String) = h5o_open(obj_id, name, H5P_DEFAULT)
#h5s_get_simple_extent_ndims(space_id::Hid) = h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)
h5t_get_native_type(type_id::Hid) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)
function h5r_dereference(obj_id::Hid, ref_type::Integer, pointee::HDF5ReferenceObj)
    ret = ccall((:H5Rdereference1, libhdf5), Hid, (Hid, Cint, Ref{HDF5ReferenceObj}),
                obj_id, ref_type, pointee)
    if ret < 0
        error("Error dereferencing object")
    end
    ret
end

# Core API ccall wrappers
include("api.jl")

# Functions that require special handling

function h5a_get_name(attr_id::Hid)
    len = h5a_get_name(attr_id, 0, C_NULL) # order of args differs from {f,i}_get_name
    buf = Vector{UInt8}(undef,len+1)
    h5a_get_name(attr_id, len+1, buf)
    String(buf[1:len])
end
function h5f_get_name(loc_id::Hid)
    len = h5f_get_name(loc_id, C_NULL, 0)
    buf = Vector{UInt8}(undef,len+1)
    h5f_get_name(loc_id, buf, len+1)
    String(buf[1:len])
end
function h5i_get_name(loc_id::Hid)
    len = h5i_get_name(loc_id, C_NULL, 0)
    buf = Vector{UInt8}(undef,len+1)
    h5i_get_name(loc_id, buf, len+1)
    String(buf[1:len])
end
function h5l_get_info(link_loc_id::Hid, link_name::String, lapl_id::Hid)
    info = Ref{H5LInfo}()
    h5l_get_info(link_loc_id, link_name, info, lapl_id)
    info[]
end

function h5lt_dtype_to_text(dtype_id)
    len = Ref{Csize_t}()
    status = ccall((:H5LTdtype_to_text, libhdf5_hl), Herr, (Hid, Ptr{UInt8}, Int, Ref{Csize_t}), dtype_id, C_NULL, 0, len)
    status < 0 && error("Error getting dtype text representation")

    buf = Base.StringVector(len[]-1)
    status = ccall((:H5LTdtype_to_text, libhdf5_hl), Herr, (Hid, Ptr{UInt8}, Int, Ref{Csize_t}), dtype_id, buf, 0, len)
    status < 0 && error("Error getting dtype text representation")

    dtype_text = String(buf)
    return dtype_text
end

function h5s_get_simple_extent_dims(space_id::Hid)
    n = h5s_get_simple_extent_ndims(space_id)
    dims = Vector{Hsize}(undef,n)
    maxdims = Vector{Hsize}(undef,n)
    h5s_get_simple_extent_dims(space_id, dims, maxdims)
    return tuple(reverse!(dims)...), tuple(reverse!(maxdims)...)
end
function h5t_get_member_name(type_id::Hid, index::Integer)
    pn = ccall((:H5Tget_member_name, libhdf5), Ptr{UInt8}, (Hid, Cuint), type_id, index)
    if pn == C_NULL
        error("Error getting name of compound datatype member #", index)
    end
    s = unsafe_string(pn)
    Libc.free(pn)
    s
end
function h5t_get_tag(type_id::Hid)
    pc = ccall((:H5Tget_tag, libhdf5),
                   Ptr{UInt8},
                   (Hid,),
                   type_id)
    if pc == C_NULL
        error("Error getting opaque tag")
    end
    s = unsafe_string(pc)
    Libc.free(pc)
    s
end

function h5f_get_obj_ids(file_id::Hid, types::Integer)
    sz = ccall((:H5Fget_obj_count, libhdf5), Int, (Hid, UInt32),
               file_id, types)
    sz >= 0 || error("error getting object count")
    hids = Vector{Hid}(undef,sz)
    sz2 = ccall((:H5Fget_obj_ids, libhdf5), Int, (Hid, UInt32, UInt, Ptr{Hid}),
          file_id, types, sz, hids)
    sz2 >= 0 || error("error getting objects")
    sz2 != sz && resize!(hids, sz2)
    hids
end

function vlen_get_buf_size(dset::HDF5Dataset, dtype::HDF5Datatype, dspace::HDF5Dataspace)
    sz = Ref{Hsize}()
    h5d_vlen_get_buf_size(dset.id, dtype.id, dspace.id, sz)
    sz[]
end

### Property manipulation ###
get_access_properties(d::HDF5Dataset)   = HDF5Properties(h5d_get_access_plist(d.id), H5P_DATASET_ACCESS)
get_access_properties(f::HDF5File)      = HDF5Properties(h5f_get_access_plist(f.id), H5P_FILE_ACCESS)
get_create_properties(d::HDF5Dataset)   = HDF5Properties(h5d_get_create_plist(d.id), H5P_DATASET_CREATE)
get_create_properties(g::HDF5Group)     = HDF5Properties(h5g_get_create_plist(g.id), H5P_GROUP_CREATE)
get_create_properties(f::HDF5File)      = HDF5Properties(h5f_get_create_plist(f.id), H5P_FILE_CREATE)
get_create_properties(a::HDF5Attribute) = HDF5Properties(h5a_get_create_plist(a.id), H5P_ATTRIBUTE_CREATE)
function get_alloc_time(p::HDF5Properties)
    alloc_time = Ref{Cint}()
    h5p_get_alloc_time(p.id, alloc_time)
    return alloc_time[]
end
function get_chunk(p::HDF5Properties)
    n = h5p_get_chunk(p, 0, C_NULL)
    cdims = Vector{Hsize}(undef,n)
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
    alen = Ref{Hsize}()
    h5p_get_userblock(p.id, alen)
    alen[]
end
function get_fclose_degree(p::HDF5Properties)
    out = Ref{Cint}()
    h5p_get_fclose_degee(p.id, out)
    out[]
end
function get_libver_bounds(p::HDF5Properties)
    out1 = Ref{Cint}()
    out2 = Ref{Cint}()
    h5p_get_libver_bounds(p.id, out1, out2)
    out1[], out2[]
end

"""
    get_datasets(file::HDF5File) -> datasets::Vector{HDF5Dataset}

Get all the datasets in an hdf5 file without loading the data.
"""
function get_datasets(file::HDF5File)
    list = HDF5Dataset[]
    get_datasets!(list, file)
    list
end
 function get_datasets!(list::Vector{HDF5Dataset}, node::Union{HDF5File,HDF5Group,HDF5Dataset})
    if isa(node, HDF5Dataset)
        push!(list, node)
    else
        for c in names(node)
            get_datasets!(list, node[c])
        end
    end
end

function get_alignment(p::HDF5Properties)
    threshold = Ref{Hsize}()
    alignment = Ref{Hsize}()
    h5p_get_alignment(p, threshold, alignment)
    return threshold[], alignment[]
end

# Map property names to function and attribute symbol
# Property names should follow the naming introduced by HDF5, i.e.
# keyname => (h5p_get_keyname, h5p_set_keyname, id )
const hdf5_prop_get_set = Dict(
    :alignment     => (get_alignment, h5p_set_alignment,             H5P_FILE_ACCESS),
    :alloc_time    => (get_alloc_time, h5p_set_alloc_time,           H5P_DATASET_CREATE),
    :blosc         => (nothing, h5p_set_blosc,                       H5P_DATASET_CREATE),
    :char_encoding => (nothing, h5p_set_char_encoding,               H5P_LINK_CREATE),
    :chunk         => (get_chunk, set_chunk,                         H5P_DATASET_CREATE),
    :compress      => (nothing, h5p_set_deflate,                     H5P_DATASET_CREATE),
    :create_intermediate_group => (nothing, h5p_set_create_intermediate_group, H5P_LINK_CREATE),
    :deflate       => (nothing, h5p_set_deflate,                     H5P_DATASET_CREATE),
    :driver        => (h5p_get_driver, nothing,                      H5P_FILE_ACCESS),
    :driver_info   => (h5p_get_driver_info, nothing,                 H5P_FILE_ACCESS),
    :external      => (nothing, h5p_set_external,                    H5P_DATASET_CREATE),
    :fclose_degree => (get_fclose_degree, h5p_set_fclose_degree,     H5P_FILE_ACCESS),
    :layout        => (h5p_get_layout, h5p_set_layout,               H5P_DATASET_CREATE),
    :libver_bounds => (get_libver_bounds, h5p_set_libver_bounds,     H5P_FILE_ACCESS),
    :local_heap_size_hint => (nothing, h5p_set_local_heap_size_hint, H5P_GROUP_CREATE),
    :shuffle       => (nothing, h5p_set_shuffle,                     H5P_DATASET_CREATE),
    :userblock     => (get_userblock, h5p_set_userblock,             H5P_FILE_CREATE),
    :track_times   => (nothing, h5p_set_obj_track_times,             H5P_OBJECT_CREATE),
)

# properties that require chunks in order to work (e.g. any filter)
# values do not matter -- just needed to form a NamedTuple with the desired keys
const chunked_props = (; compress=nothing, deflate=nothing, blosc=nothing, shuffle=nothing)

"""
    create_external(source::Union{HDF5File, HDF5Group}, source_relpath, target_filename, target_path;
                    lcpl_id=HDF5.H5P_DEFAULT, lapl_id=HDF5.H5P.DEFAULT)

Create an external link such that `source[source_relpath]` points to `target_path` within the file
with path `target_filename`; Calls `[H5Lcreate_external](https://www.hdfgroup.org/HDF5/doc/RM/RM_H5L.html#Link-CreateExternal)`.
"""
function create_external(source::Union{HDF5File, HDF5Group}, source_relpath, target_filename, target_path; lcpl_id=H5P_DEFAULT, lapl_id=H5P_DEFAULT)
    h5l_create_external(target_filename, target_path, source.id, source_relpath, lcpl_id, lapl_id)
    nothing
end

# error handling
function hiding_errors(f)
    error_stack = H5E_DEFAULT
    # error_stack = ccall((:H5Eget_current_stack, libhdf5), Hid, ())
    old_func = Ref{Ptr{Cvoid}}()
    old_client_data = Ref{Ptr{Cvoid}}()
    ccall((:H5Eget_auto2, libhdf5), Herr, (Hid, Ptr{Ptr{Cvoid}}, Ptr{Ptr{Cvoid}}),
        error_stack, old_func, old_client_data)
    ccall((:H5Eset_auto2, libhdf5), Herr, (Hid, Ptr{Cvoid}, Ptr{Cvoid}),
        error_stack, C_NULL, C_NULL)
    res = f()
    ccall((:H5Eset_auto2, libhdf5), Herr, (Hid, Ptr{Cvoid}, Ptr{Cvoid}),
        error_stack, old_func[], old_client_data[])
    res
end

# Define globally because JLD uses this, too
const rehash! = Base.rehash!

# Across initializations of the library, the id of various properties
# will change. So don't hard-code the id (important for precompilation)
const UTF8_LINK_PROPERTIES = Ref{HDF5Properties}()
_link_properties(path::String) = UTF8_LINK_PROPERTIES[]
const UTF8_ATTRIBUTE_PROPERTIES = Ref{HDF5Properties}()
_attr_properties(path::String) = UTF8_ATTRIBUTE_PROPERTIES[]
const ASCII_LINK_PROPERTIES = Ref{HDF5Properties}()
const ASCII_ATTRIBUTE_PROPERTIES = Ref{HDF5Properties}()

const DEFAULT_PROPERTIES = HDF5Properties(H5P_DEFAULT, H5P_DEFAULT)

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

    ASCII_LINK_PROPERTIES[] = p_create(H5P_LINK_CREATE)
    h5p_set_char_encoding(ASCII_LINK_PROPERTIES[].id, H5T_CSET_ASCII)
    h5p_set_create_intermediate_group(ASCII_LINK_PROPERTIES[].id, 1)
    UTF8_LINK_PROPERTIES[] = p_create(H5P_LINK_CREATE)
    h5p_set_char_encoding(UTF8_LINK_PROPERTIES[].id, H5T_CSET_UTF8)
    h5p_set_create_intermediate_group(UTF8_LINK_PROPERTIES[].id, 1)
    ASCII_ATTRIBUTE_PROPERTIES[] = p_create(H5P_ATTRIBUTE_CREATE)
    h5p_set_char_encoding(ASCII_ATTRIBUTE_PROPERTIES[].id, H5T_CSET_ASCII)
    UTF8_ATTRIBUTE_PROPERTIES[] = p_create(H5P_ATTRIBUTE_CREATE)
    h5p_set_char_encoding(UTF8_ATTRIBUTE_PROPERTIES[].id, H5T_CSET_UTF8)

    rehash!(hdf5_type_map, length(hdf5_type_map.keys))
    rehash!(hdf5_prop_get_set, length(hdf5_prop_get_set.keys))
    rehash!(hdf5_obj_open, length(hdf5_obj_open.keys))

    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" @eval include("mpio.jl")

    return nothing
end

include("deprecated.jl")

end  # module
