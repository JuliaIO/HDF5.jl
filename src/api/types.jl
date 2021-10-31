## C types
const Ctime_t = Int

## HDF5 types and constants
const haddr_t  = UInt64
const hbool_t  = Cuint
const herr_t   = Cint
const hid_t    = Int64
const hsize_t  = UInt64
const hssize_t = Int64
const htri_t   = Cint   # pseudo-boolean (negative if error)

const H5Z_filter_t = Cint

# For VLEN
struct hvl_t
    len::Csize_t
    p::Ptr{Cvoid}
end
const HVL_SIZE = sizeof(hvl_t)

# Reference types
struct hobj_ref_t
    buf::UInt64 # H5R_OBJ_REF_BUF_SIZE bytes
end
struct hdset_reg_ref_t
    buf::NTuple{12,UInt8} # H5R_DSET_REG_REF_BUF_SIZE bytes
end
const HOBJ_REF_T_NULL = hobj_ref_t(0x0)
const HDSET_REG_REF_T_NULL = hdset_reg_ref_t(ntuple(_ -> 0x0, Val(12)))

#= TODO: when upgraded to using newer HDF5 v1.12 reference API, can replace both with:
struct H5R_ref_t
    # Element type of UInt64 and not UInt8 to get 8-byte alignment
    buf::NTuple{8,UInt64} # H5R_REF_BUF_SIZE bytes
end
const H5R_REF_T_NULL = H5R_ref_t(ntuple(_ -> 0x0, Val(64)))
=#

# For attribute information
struct H5A_info_t
    corder_valid::hbool_t
    corder::UInt32 # typedef uint32_t H5O_msg_crt_idx_t
    cset::Cint
    data_size::hsize_t
end

# For group information
struct H5G_info_t
    storage_type::Cint # enum H5G_storage_type_t
    nlinks::hsize_t
    max_corder::Int64
    mounted::hbool_t
end

# For objects
struct H5_ih_info_t
    index_size::hsize_t
    heap_size::hsize_t
end
struct H5O_info_t # version 1 type H5O_info1_t
    fileno::Cuint
    addr::haddr_t
    otype::Cint # enum H5O_type_t
    rc::Cuint
    atime::Ctime_t
    mtime::Ctime_t
    ctime::Ctime_t
    btime::Ctime_t
    num_attrs::hsize_t
    #{ inlined struct H5O_hdr_info_t named type
    version::Cuint
    nmesgs::Cuint
    nchunks::Cuint
    flags::Cuint
    total::hsize_t
    meta::hsize_t
    mesg::hsize_t
    free::hsize_t
    present::UInt64
    shared::UInt64
    #}
    #{ inlined anonymous struct named meta_size
    meta_obj::H5_ih_info_t
    meta_attr::H5_ih_info_t
    #}
end

# For links
struct H5L_info_t
    linktype::Cint
    corder_valid::hbool_t
    corder::Int64
    cset::Cint # enum H5T_cset_t
    u::haddr_t # union { haddr_t address, size_t val_size }
end

# For registering filters
struct H5Z_class_t # version 2 type H5Z_class2_t
    version::Cint # = H5Z_CLASS_T_VERS
    id::H5Z_filter_t # Filter ID number
    encoder_present::Cuint # Does this filter have an encoder?
    decoder_present::Cuint # Does this filter have a decoder?
    name::Ptr{UInt8} # Comment for debugging
    can_apply::Ptr{Cvoid} # The "can apply" callback
    set_local::Ptr{Cvoid} # The "set local" callback
    filter::Ptr{Cvoid} # The filter callback
end

# Information about an error; element of error stack.
# See https://github.com/HDFGroup/hdf5/blob/hdf5-1_12_0/src/H5Epublic.h#L36-L44
struct H5E_error2_t
    cls_id::hid_t # class ID"
    maj_num::hid_t # major error ID
    min_num::hid_t # minor error number
    line::Cuint # line in file where the error occurs
    func_name::Cstring # function where the error occurred
    file_name::Cstring # file in which the error occurred
    desc::Cstring # optional supplied description
end


# MPI communicators required by H5P
abstract  type Hmpih end
primitive type Hmpih32 <: Hmpih 32 end # MPICH C/Fortran, OpenMPI Fortran: 32 bit handles
primitive type Hmpih64 <: Hmpih 64 end # OpenMPI C: pointers (mostly 64 bit)

# Private function to extract exported global library constants.
# Need to call H5open to ensure library is initalized before reading these constants.
# Although these are runtime initalized constants, in practice their values are stable, so
# we can precompile for improved latency.
let libhdf5handle = Ref(Libdl.dlopen(libhdf5))
    ccall(Libdl.dlsym(libhdf5handle[], :H5open), herr_t, ())
    global _read_const(sym::Symbol) = unsafe_load(cglobal(Libdl.dlsym(libhdf5handle[], sym), hid_t))
end

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

# used to "unset" chunk cache configuration parameters
const H5D_CHUNK_CACHE_NSLOTS_DEFAULT = -1 % Csize_t
const H5D_CHUNK_CACHE_NBYTES_DEFAULT = -1 % Csize_t
const H5D_CHUNK_CACHE_W0_DEFAULT = Cdouble(-1)

# space status
const H5D_SPACE_STATUS_ERROR = Cint(-1)
const H5D_SPACE_STATUS_NOT_ALLOCATED = Cint(0)
const H5D_SPACE_STATUS_PART_ALLOCATED = Cint(1)
const H5D_SPACE_STATUS_ALLOCATED = Cint(2)
const H5D_space_status_t = Cint

# error-related constants
const H5E_DEFAULT      = 0
const H5E_WALK_UPWARD   = 0
const H5E_WALK_DOWNWARD = 1

# file access modes
const H5F_ACC_RDONLY     = 0x0000
const H5F_ACC_RDWR       = 0x0001
const H5F_ACC_TRUNC      = 0x0002
const H5F_ACC_EXCL       = 0x0004
const H5F_ACC_DEBUG      = 0x0008
const H5F_ACC_CREAT      = 0x0010
const H5F_ACC_SWMR_WRITE = 0x0020
const H5F_ACC_SWMR_READ  = 0x0040

# Library versions
const H5F_LIBVER_EARLIEST = 0
const H5F_LIBVER_V18      = 1
const H5F_LIBVER_V110     = 2
const H5F_LIBVER_V112     = 3
# H5F_LIBVER_LATEST defined in helpers.jl

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
const H5I_VFL          = 8

# Link constants
const H5L_TYPE_HARD    = 0
const H5L_TYPE_SOFT    = 1
const H5L_TYPE_EXTERNAL= 2

# Object constants
const H5O_TYPE_GROUP   = 0
const H5O_TYPE_DATASET = 1
const H5O_TYPE_NAMED_DATATYPE = 2

# Property constants
const H5P_DEFAULT          = hid_t(0)
const H5P_OBJECT_CREATE    = _read_const(:H5P_CLS_OBJECT_CREATE_ID_g)
const H5P_FILE_CREATE      = _read_const(:H5P_CLS_FILE_CREATE_ID_g)
const H5P_FILE_ACCESS      = _read_const(:H5P_CLS_FILE_ACCESS_ID_g)
const H5P_DATASET_CREATE   = _read_const(:H5P_CLS_DATASET_CREATE_ID_g)
const H5P_DATASET_ACCESS   = _read_const(:H5P_CLS_DATASET_ACCESS_ID_g)
const H5P_DATASET_XFER     = _read_const(:H5P_CLS_DATASET_XFER_ID_g)
const H5P_FILE_MOUNT       = _read_const(:H5P_CLS_FILE_MOUNT_ID_g)
const H5P_GROUP_CREATE     = _read_const(:H5P_CLS_GROUP_CREATE_ID_g)
const H5P_GROUP_ACCESS     = _read_const(:H5P_CLS_GROUP_ACCESS_ID_g)
const H5P_DATATYPE_CREATE  = _read_const(:H5P_CLS_DATATYPE_CREATE_ID_g)
const H5P_DATATYPE_ACCESS  = _read_const(:H5P_CLS_DATATYPE_ACCESS_ID_g)
const H5P_STRING_CREATE    = _read_const(:H5P_CLS_STRING_CREATE_ID_g)
const H5P_ATTRIBUTE_CREATE = _read_const(:H5P_CLS_ATTRIBUTE_CREATE_ID_g)
const H5P_OBJECT_COPY      = _read_const(:H5P_CLS_OBJECT_COPY_ID_g)
const H5P_LINK_CREATE      = _read_const(:H5P_CLS_LINK_CREATE_ID_g)
const H5P_LINK_ACCESS      = _read_const(:H5P_CLS_LINK_ACCESS_ID_g)

# Reference constants
const H5R_OBJECT         = 0
const H5R_DATASET_REGION = 1
const H5R_OBJ_REF_BUF_SIZE      = 8  # == sizeof(hobj_ref_t)
const H5R_DSET_REG_REF_BUF_SIZE = 12 # == sizeof(hdset_reg_ref_t)

# Dataspace constants
const H5S_ALL       = hid_t(0)
const H5S_UNLIMITED = typemax(hsize_t)

# Dataspace classes (C enum H5S_class_t)
const H5S_SCALAR = 0
const H5S_SIMPLE = 1
const H5S_NULL   = 2

# Dataspace selection constants (C enum H5S_seloper_t)
const H5S_SELECT_SET     = 0
const H5S_SELECT_OR      = 1
const H5S_SELECT_AND     = 2
const H5S_SELECT_XOR     = 3
const H5S_SELECT_NOTB    = 4
const H5S_SELECT_NOTA    = 5
const H5S_SELECT_APPEND  = 6
const H5S_SELECT_PREPEND = 7

# Dataspace selection types (C enum H5S_sel_type)
const H5S_SEL_NONE       = 0
const H5S_SEL_POINTS     = 1
const H5S_SEL_HYPERSLABS = 2
const H5S_SEL_ALL        = 3

# type classes (C enum H5T_class_t)
const H5T_INTEGER      = hid_t(0)
const H5T_FLOAT        = hid_t(1)
const H5T_TIME         = hid_t(2)  # not supported by HDF5 library
const H5T_STRING       = hid_t(3)
const H5T_BITFIELD     = hid_t(4)
const H5T_OPAQUE       = hid_t(5)
const H5T_COMPOUND     = hid_t(6)
const H5T_REFERENCE    = hid_t(7)
const H5T_ENUM         = hid_t(8)
const H5T_VLEN         = hid_t(9)
const H5T_ARRAY        = hid_t(10)

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

# Type_id constants (LE = little endian, I16 = Int16, etc)
const H5T_STD_I8LE        = _read_const(:H5T_STD_I8LE_g)
const H5T_STD_I8BE        = _read_const(:H5T_STD_I8BE_g)
const H5T_STD_U8LE        = _read_const(:H5T_STD_U8LE_g)
const H5T_STD_U8BE        = _read_const(:H5T_STD_U8BE_g)
const H5T_STD_I16LE       = _read_const(:H5T_STD_I16LE_g)
const H5T_STD_I16BE       = _read_const(:H5T_STD_I16BE_g)
const H5T_STD_U16LE       = _read_const(:H5T_STD_U16LE_g)
const H5T_STD_U16BE       = _read_const(:H5T_STD_U16BE_g)
const H5T_STD_I32LE       = _read_const(:H5T_STD_I32LE_g)
const H5T_STD_I32BE       = _read_const(:H5T_STD_I32BE_g)
const H5T_STD_U32LE       = _read_const(:H5T_STD_U32LE_g)
const H5T_STD_U32BE       = _read_const(:H5T_STD_U32BE_g)
const H5T_STD_I64LE       = _read_const(:H5T_STD_I64LE_g)
const H5T_STD_I64BE       = _read_const(:H5T_STD_I64BE_g)
const H5T_STD_U64LE       = _read_const(:H5T_STD_U64LE_g)
const H5T_STD_U64BE       = _read_const(:H5T_STD_U64BE_g)
const H5T_IEEE_F32LE      = _read_const(:H5T_IEEE_F32LE_g)
const H5T_IEEE_F32BE      = _read_const(:H5T_IEEE_F32BE_g)
const H5T_IEEE_F64LE      = _read_const(:H5T_IEEE_F64LE_g)
const H5T_IEEE_F64BE      = _read_const(:H5T_IEEE_F64BE_g)
const H5T_C_S1            = _read_const(:H5T_C_S1_g)
const H5T_STD_REF_OBJ     = _read_const(:H5T_STD_REF_OBJ_g)
const H5T_STD_REF_DSETREG = _read_const(:H5T_STD_REF_DSETREG_g)
# Native types
const H5T_NATIVE_B8       = _read_const(:H5T_NATIVE_B8_g)
const H5T_NATIVE_INT8     = _read_const(:H5T_NATIVE_INT8_g)
const H5T_NATIVE_UINT8    = _read_const(:H5T_NATIVE_UINT8_g)
const H5T_NATIVE_INT16    = _read_const(:H5T_NATIVE_INT16_g)
const H5T_NATIVE_UINT16   = _read_const(:H5T_NATIVE_UINT16_g)
const H5T_NATIVE_INT32    = _read_const(:H5T_NATIVE_INT32_g)
const H5T_NATIVE_UINT32   = _read_const(:H5T_NATIVE_UINT32_g)
const H5T_NATIVE_INT64    = _read_const(:H5T_NATIVE_INT64_g)
const H5T_NATIVE_UINT64   = _read_const(:H5T_NATIVE_UINT64_g)
const H5T_NATIVE_FLOAT    = _read_const(:H5T_NATIVE_FLOAT_g)
const H5T_NATIVE_DOUBLE   = _read_const(:H5T_NATIVE_DOUBLE_g)
# Other type constants
const H5T_VARIABLE = reinterpret(UInt, -1)

# Filter constants
const H5Z_FLAG_MANDATORY = 0x0000
const H5Z_FLAG_OPTIONAL = 0x0001
const H5Z_FLAG_REVERSE = 0x0100
const H5Z_CLASS_T_VERS = 1

# predefined filters
const H5Z_FILTER_ALL = H5Z_filter_t(0)
const H5Z_FILTER_NONE = H5Z_filter_t(0)
const H5Z_FILTER_DEFLATE = H5Z_filter_t(1)
const H5Z_FILTER_SHUFFLE = H5Z_filter_t(2)
const H5Z_FILTER_FLETCHER32 = H5Z_filter_t(3)
const H5Z_FILTER_SZIP = H5Z_filter_t(4)
const H5Z_FILTER_NBIT = H5Z_filter_t(5)
const H5Z_FILTER_SCALEOFFSET = H5Z_filter_t(6)

const H5_SZIP_EC_OPTION_MASK = Cuint(4)
const H5_SZIP_NN_OPTION_MASK = Cuint(32)
const H5_SZIP_MAX_PIXELS_PER_BLOCK = Cuint(32)