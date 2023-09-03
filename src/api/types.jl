## C types
const Ctime_t = Int

## HDF5 types and constants
const haddr_t  = UInt64
const hbool_t  = Bool
const herr_t   = Cint
const hid_t    = Int64
const hsize_t  = UInt64
const hssize_t = Int64
const htri_t   = Cint   # pseudo-boolean (negative if error)
@static if Sys.iswindows()
    const off_t = Int64
else
    const off_t = Int
end

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
@enum H5_index_t::Cint begin
    H5_INDEX_UNKNOWN = -1
    H5_INDEX_NAME = 0
    H5_INDEX_CRT_ORDER = 1
    H5_INDEX_N = 2
end
@enum H5_iter_order_t::Cint begin
    H5_ITER_UNKNOWN = -1
    H5_ITER_INC = 0
    H5_ITER_DEC = 1
    H5_ITER_NATIVE = 2
    H5_ITER_N = 3
end
@enum H5_iter_t::Cint begin
    H5_ITER_CONT  = 0
    H5_ITER_ERROR = -1
    H5_ITER_STOP  = 1
end
Base.convert(::Type{H5_iter_t}, x::Integer) = H5_iter_t(x)

const H5O_iterate1_t = Ptr{Cvoid}
const H5O_iterate2_t = Ptr{Cvoid}

struct _H5O_hdr_info_t_space
    total::hsize_t
    meta::hsize_t
    mesg::hsize_t
    free::hsize_t
end

struct _H5O_hdr_info_t_mesg
    present::UInt64
    shared::UInt64
end

struct H5O_hdr_info_t
    version::Cuint
    nmesgs::Cuint
    nchunks::Cuint
    flags::Cuint
    space::_H5O_hdr_info_t_space
    mesg::_H5O_hdr_info_t_mesg
end

struct H5_ih_info_t
    index_size::hsize_t
    heap_size::hsize_t
end

struct _H5O_native_info_t_meta_size
    obj::H5_ih_info_t
    attr::H5_ih_info_t
end

struct H5O_native_info_t
    hdr::H5O_hdr_info_t
    meta_size::_H5O_native_info_t_meta_size
end

const H5O_NATIVE_INFO_HDR = 0x0008
const H5O_NATIVE_INFO_META_SIZE = 0x0010
const H5O_NATIVE_INFO_ALL = H5O_NATIVE_INFO_HDR | H5O_NATIVE_INFO_META_SIZE

struct H5O_token_t
    __data::NTuple{16,UInt8}
end
@enum H5O_type_t::Cint begin
    H5O_TYPE_UNKNOWN = -1
    H5O_TYPE_GROUP = 0
    H5O_TYPE_DATASET = 1
    H5O_TYPE_NAMED_DATATYPE = 2
    H5O_TYPE_MAP = 3
    H5O_TYPE_NTYPES = 4
end

struct H5O_info1_t # version 1 type H5O_info1_t
    fileno::Culong
    addr::haddr_t
    otype::H5O_type_t # enum H5O_type_t
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
const H5O_info_t = H5O_info1_t

# The field "otype" is originally "type"
# Alias "otype" as "type" for compat with H5O_info2_t
Base.getproperty(oinfo::H5O_info1_t, field::Symbol) =
    field == :type ? getfield(oinfo, :otype) : getfield(oinfo, field)

struct H5O_info2_t
    fileno::Culong
    token::H5O_token_t
    type::H5O_type_t
    rc::Cuint
    atime::Ctime_t
    mtime::Ctime_t
    ctime::Ctime_t
    btime::Ctime_t
    num_attrs::hsize_t
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

# HDFS Drivers
struct H5FD_hdfs_fapl_t
    version::Int32
    namenode_name::NTuple{129,Cchar}
    namenode_port::Int32
    user_name::NTuple{129,Cchar}
    kerberos_ticket_cache::NTuple{129,Cchar}
    stream_buffer_size::Int32
end

const H5FD_ROS3_MAX_REGION_LEN = 32
const H5FD_ROS3_MAX_SECRET_ID_LEN = 128
const H5FD_ROS3_MAX_SECRET_KEY_LEN = 128

struct H5FD_ros3_fapl_t
    version::Int32
    authenticate::hbool_t
    aws_region::NTuple{H5FD_ROS3_MAX_REGION_LEN + 1,Cchar}
    secret_id::NTuple{H5FD_ROS3_MAX_SECRET_ID_LEN + 1,Cchar}
    secret_key::NTuple{H5FD_ROS3_MAX_SECRET_KEY_LEN + 1,Cchar}
end

struct H5FD_splitter_vfd_config_t
    magic::Int32
    version::Cuint
    rw_fapl_id::hid_t
    wo_fapl_id::hid_t
    wo_path::NTuple{4097,Cchar}
    log_file_path::NTuple{4097,Cchar}
    ignore_wo_errs::hbool_t
end

# Private function to extract exported global library constants.
# Need to call H5open to ensure library is initalized before reading these constants.
# Although these are runtime initalized constants, in practice their values are stable, so
# we can precompile for improved latency.
const libhdf5handle = Ref(dlopen(libhdf5))
ccall(dlsym(libhdf5handle[], :H5open), herr_t, ())
_read_const(sym::Symbol) = unsafe_load(cglobal(dlsym(libhdf5handle[], sym), hid_t))
_has_symbol(sym::Symbol) = dlsym(libhdf5handle[], sym; throw_error=false) !== nothing

# iteration order constants
# Moved to H5_iter_order_t enum
#const H5_ITER_UNKNOWN = -1
#const H5_ITER_INC     = 0
#const H5_ITER_DEC     = 1
#const H5_ITER_NATIVE  = 2
#const H5_ITER_N       = 3

# indexing type constants
# Moved to H5_index_t enum
#const H5_INDEX_UNKNOWN   = -1
#const H5_INDEX_NAME      = 0
#const H5_INDEX_CRT_ORDER = 1
#const H5_INDEX_N = 2

# dataset constants
const H5D_COMPACT    = 0
const H5D_CONTIGUOUS = 1
const H5D_CHUNKED    = 2
const H5D_VIRTUAL    = 3

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
const H5E_DEFAULT       = 0
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
@enum H5F_libver_t::Int32 begin
    H5F_LIBVER_ERROR = -1
    H5F_LIBVER_EARLIEST = 0
    H5F_LIBVER_V18 = 1
    H5F_LIBVER_V110 = 2
    H5F_LIBVER_V112 = 3
    H5F_LIBVER_V114 = 4
    H5F_LIBVER_V116 = 5
    H5F_LIBVER_NBOUNDS = 6
end
# H5F_LIBVER_LATEST defined in helpers.jl

# object types
const H5F_OBJ_FILE     = 0x0001
const H5F_OBJ_DATASET  = 0x0002
const H5F_OBJ_GROUP    = 0x0004
const H5F_OBJ_DATATYPE = 0x0008
const H5F_OBJ_ATTR     = 0x0010
const H5F_OBJ_ALL      = (H5F_OBJ_FILE | H5F_OBJ_DATASET | H5F_OBJ_GROUP | H5F_OBJ_DATATYPE | H5F_OBJ_ATTR)
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
const H5I_FILE      = 1
const H5I_GROUP     = 2
const H5I_DATATYPE  = 3
const H5I_DATASPACE = 4
const H5I_DATASET   = 5
const H5I_ATTR      = 6
const H5I_REFERENCE = 7
const H5I_VFL       = 8

# Link constants
const H5L_TYPE_HARD     = 0
const H5L_TYPE_SOFT     = 1
const H5L_TYPE_EXTERNAL = 2

# H5O_INFO constants
const H5O_INFO_BASIC = Cuint(0x0001)
const H5O_INFO_TIME = Cuint(0x0002)
const H5O_INFO_NUM_ATTRS = Cuint(0x0004)
const H5O_INFO_HDR = Cuint(0x0008)
const H5O_INFO_META_SIZE = Cuint(0x0010)
const H5O_INFO_ALL =
    H5O_INFO_BASIC | H5O_INFO_TIME | H5O_INFO_NUM_ATTRS | H5O_INFO_HDR | H5O_INFO_META_SIZE

# Object constants
# Moved to H5O_type_t enum
#const H5O_TYPE_GROUP   = 0
#const H5O_TYPE_DATASET = 1
#const H5O_TYPE_NAMED_DATATYPE = 2

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
const H5P_ATTRIBUTE_ACCESS = _read_const(:H5P_CLS_ATTRIBUTE_ACCESS_ID_g)
const H5P_ATTRIBUTE_CREATE = _read_const(:H5P_CLS_ATTRIBUTE_CREATE_ID_g)
const H5P_OBJECT_COPY      = _read_const(:H5P_CLS_OBJECT_COPY_ID_g)
const H5P_LINK_CREATE      = _read_const(:H5P_CLS_LINK_CREATE_ID_g)
const H5P_LINK_ACCESS      = _read_const(:H5P_CLS_LINK_ACCESS_ID_g)

# Plugin constants, H5PL_type_t
const H5PL_TYPE_ERROR = -1
const H5PL_TYPE_FILTER = 0
const H5PL_TYPE_VOL = 1
const H5PL_TYPE_NONE = 2

const H5P_CRT_ORDER_TRACKED = 1
const H5P_CRT_ORDER_INDEXED = 2

# Reference constants
const H5R_OBJECT                = 0
const H5R_DATASET_REGION        = 1
const H5R_OBJ_REF_BUF_SIZE      = 8  # == sizeof(hobj_ref_t)
const H5R_DSET_REG_REF_BUF_SIZE = 12 # == sizeof(hdset_reg_ref_t)

# Dataspace constants
const H5S_ALL       = hid_t(0)
const H5S_UNLIMITED = typemax(hsize_t)

# Dataspace classes (C enum H5S_class_t)
@enum H5S_class_t::Cint begin
    H5S_NO_CLASS = -1
    H5S_SCALAR = 0
    H5S_SIMPLE = 1
    H5S_NULL = 2
end

# Dataspace selection constants (C enum H5S_seloper_t)
@enum H5S_seloper_t::Cint begin
    H5S_SELECT_NOOP = -1
    H5S_SELECT_SET = 0
    H5S_SELECT_OR = 1
    H5S_SELECT_AND = 2
    H5S_SELECT_XOR = 3
    H5S_SELECT_NOTB = 4
    H5S_SELECT_NOTA = 5
    H5S_SELECT_APPEND = 6
    H5S_SELECT_PREPEND = 7
    H5S_SELECT_INVALID = 8
end

# Dataspace selection types (C enum H5S_sel_type)
@enum H5S_sel_type::Cint begin
    H5S_SEL_ERROR = -1
    H5S_SEL_NONE = 0
    H5S_SEL_POINTS = 1
    H5S_SEL_HYPERSLABS = 2
    H5S_SEL_ALL = 3
    H5S_SEL_N = 4
end

# type classes (C enum H5T_class_t)
const H5T_NO_CLASS  = hid_t(-1)
const H5T_INTEGER   = hid_t(0)
const H5T_FLOAT     = hid_t(1)
const H5T_TIME      = hid_t(2)  # not supported by HDF5 library
const H5T_STRING    = hid_t(3)
const H5T_BITFIELD  = hid_t(4)
const H5T_OPAQUE    = hid_t(5)
const H5T_COMPOUND  = hid_t(6)
const H5T_REFERENCE = hid_t(7)
const H5T_ENUM      = hid_t(8)
const H5T_VLEN      = hid_t(9)
const H5T_ARRAY     = hid_t(10)

# Byte orders (C enum H5T_order_t)
const H5T_ORDER_ERROR = -1 # error
const H5T_ORDER_LE    = 0  # little endian
const H5T_ORDER_BE    = 1  # bit endian
const H5T_ORDER_VAX   = 2  # VAX mixed endian
const H5T_ORDER_MIXED = 3  # Compound type with mixed member orders
const H5T_ORDER_NONE  = 4  # no particular order (strings, bits,..)

# Floating-point normalization schemes (C enum H5T_norm_t)
const H5T_NORM_ERROR   = -1 # error
const H5T_NORM_IMPLIED = 0  # msb of mantissa isn't stored, always 1
const H5T_NORM_MSBSET  = 1  # msb of mantissa is always 1
const H5T_NORM_NONE    = 2   # not normalized

# Character types
const H5T_CSET_ASCII = 0
const H5T_CSET_UTF8  = 1

# Sign types (C enum H5T_sign_t)
const H5T_SGN_ERROR = Cint(-1) # error
const H5T_SGN_NONE  = Cint(0)  # unsigned
const H5T_SGN_2     = Cint(1)  # 2's complement
const H5T_NSGN      = Cint(2)  # sentinel: this must be last!

# Search directions
const H5T_DIR_ASCEND  = 1
const H5T_DIR_DESCEND = 2

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
const H5T_NATIVE_B8     = _read_const(:H5T_NATIVE_B8_g)
const H5T_NATIVE_INT8   = _read_const(:H5T_NATIVE_INT8_g)
const H5T_NATIVE_UINT8  = _read_const(:H5T_NATIVE_UINT8_g)
const H5T_NATIVE_INT16  = _read_const(:H5T_NATIVE_INT16_g)
const H5T_NATIVE_UINT16 = _read_const(:H5T_NATIVE_UINT16_g)
const H5T_NATIVE_INT32  = _read_const(:H5T_NATIVE_INT32_g)
const H5T_NATIVE_UINT32 = _read_const(:H5T_NATIVE_UINT32_g)
const H5T_NATIVE_INT64  = _read_const(:H5T_NATIVE_INT64_g)
const H5T_NATIVE_UINT64 = _read_const(:H5T_NATIVE_UINT64_g)
const H5T_NATIVE_FLOAT  = _read_const(:H5T_NATIVE_FLOAT_g)
const H5T_NATIVE_DOUBLE = _read_const(:H5T_NATIVE_DOUBLE_g)
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

const H5Z_FILTER_CONFIG_ENCODE_ENABLED = 0x0001
const H5Z_FILTER_CONFIG_DECODE_ENABLED = 0x0002

# fill time
@enum H5D_fill_time_t::Int32 begin
    H5D_FILL_TIME_ERROR = -1
    H5D_FILL_TIME_ALLOC = 0
    H5D_FILL_TIME_NEVER = 1
    H5D_FILL_TIME_IFSET = 2
end

@enum H5F_mem_t::Int32 begin
    H5FD_MEM_NOLIST = -1
    H5FD_MEM_DEFAULT = 0
    H5FD_MEM_SUPER = 1
    H5FD_MEM_BTREE = 2
    H5FD_MEM_DRAW = 3
    H5FD_MEM_GHEAP = 4
    H5FD_MEM_LHEAP = 5
    H5FD_MEM_OHDR = 6
    H5FD_MEM_NTYPES = 7
end

const H5FD_mem_t = H5F_mem_t

struct H5FD_file_image_callbacks_t
    image_malloc::Ptr{Cvoid}
    image_memcpy::Ptr{Cvoid}
    image_realloc::Ptr{Cvoid}
    image_free::Ptr{Cvoid}
    udata_copy::Ptr{Cvoid}
    udata_free::Ptr{Cvoid}
    udata::Ptr{Cvoid}
end

struct H5F_sect_info_t
    addr::haddr_t
    size::hsize_t
end

@enum H5F_fspace_strategy_t::UInt32 begin
    H5F_FSPACE_STRATEGY_FSM_AGGR = 0
    H5F_FSPACE_STRATEGY_PAGE = 1
    H5F_FSPACE_STRATEGY_AGGR = 2
    H5F_FSPACE_STRATEGY_NONE = 3
    H5F_FSPACE_STRATEGY_NTYPES = 4
end

@enum H5F_file_space_type_t::UInt32 begin
    H5F_FILE_SPACE_DEFAULT = 0
    H5F_FILE_SPACE_ALL_PERSIST = 1
    H5F_FILE_SPACE_ALL = 2
    H5F_FILE_SPACE_AGGR_VFD = 3
    H5F_FILE_SPACE_VFD = 4
    H5F_FILE_SPACE_NTYPES = 5
end

@enum H5Z_EDC_t::Int32 begin
    H5Z_ERROR_EDC = -1
    H5Z_DISABLE_EDC = 0
    H5Z_ENABLE_EDC = 1
    H5Z_NO_EDC = 2
end

# Callbacks
# typedef herr_t ( * H5P_prp_cb1_t ) ( const char * name , size_t size , void * value )
const H5P_prp_cb1_t = Ptr{Cvoid}
const H5P_prp_copy_func_t = H5P_prp_cb1_t
# typedef int ( * H5P_prp_compare_func_t ) ( const void * value1 , const void * value2 , size_t size )
const H5P_prp_compare_func_t = Ptr{Cvoid}
const H5P_prp_close_func_t = H5P_prp_cb1_t
const H5P_prp_create_func_t = H5P_prp_cb1_t
const H5P_prp_cb2_t = Ptr{Cvoid}
const H5P_prp_set_func_t = H5P_prp_cb2_t
const H5P_prp_get_func_t = H5P_prp_cb2_t
const H5P_prp_delete_func_t = H5P_prp_cb2_t
const H5P_cls_create_func_t = Ptr{Cvoid}
const H5P_cls_copy_func_t = Ptr{Cvoid}
const H5P_cls_close_func_t = Ptr{Cvoid}
const H5P_iterate_t = Ptr{Cvoid}
const H5D_append_cb_t = Ptr{Cvoid}
const H5L_elink_traverse_t = Ptr{Cvoid}
# typedef herr_t ( * H5F_flush_cb_t ) ( hid_t object_id , void * udata )
const H5F_flush_cb_t = Ptr{Cvoid}
# typedef H5O_mcdt_search_ret_t ( * H5O_mcdt_search_cb_t ) ( void * op_data )
const H5O_mcdt_search_cb_t = Ptr{Cvoid}
# typedef herr_t ( * H5T_conv_t ) ( hid_t src_id , hid_t dst_id , H5T_cdata_t * cdata , size_t nelmts , size_t buf_stride , size_t bkg_stride , void * buf , void * bkg , hid_t dset_xfer_plist )
const H5T_conv_t = Ptr{Cvoid}
# typedef H5T_conv_ret_t ( * H5T_conv_except_func_t ) ( H5T_conv_except_t except_type , hid_t src_id , hid_t dst_id , void * src_buf , void * dst_buf , void * user_data )
const H5T_conv_except_func_t = Ptr{Cvoid}
# typedef herr_t ( * H5M_iterate_t ) ( hid_t map_id , const void * key , void * op_data )
const H5M_iterate_t = Ptr{Cvoid}
# typedef void * ( * H5MM_allocate_t ) ( size_t size , void * alloc_info )
const H5MM_allocate_t = Ptr{Cvoid}
# typedef void ( * H5MM_free_t ) ( void * mem , void * free_info )
const H5MM_free_t = Ptr{Cvoid}
# typedef H5Z_cb_return_t ( * H5Z_filter_func_t ) ( H5Z_filter_t filter , void * buf , size_t buf_size , void * op_data )
const H5Z_filter_func_t = Ptr{Cvoid}

struct H5Z_cb_t
    func::H5Z_filter_func_t
    op_data::Ptr{Cvoid}
end

@enum H5C_cache_incr_mode::UInt32 begin
    H5C_incr__off = 0
    H5C_incr__threshold = 1
end

@enum H5C_cache_flash_incr_mode::UInt32 begin
    H5C_flash_incr__off = 0
    H5C_flash_incr__add_space = 1
end

@enum H5C_cache_decr_mode::UInt32 begin
    H5C_decr__off = 0
    H5C_decr__threshold = 1
    H5C_decr__age_out = 2
    H5C_decr__age_out_with_threshold = 3
end

struct H5AC_cache_config_t
    version::Cint
    rpt_fcn_enabled::hbool_t
    open_trace_file::hbool_t
    close_trace_file::hbool_t
    trace_file_name::NTuple{1025,Cchar}
    evictions_enabled::hbool_t
    set_initial_size::hbool_t
    initial_size::Csize_t
    min_clean_fraction::Cdouble
    max_size::Csize_t
    min_size::Csize_t
    epoch_length::Clong
    incr_mode::H5C_cache_incr_mode
    lower_hr_threshold::Cdouble
    increment::Cdouble
    apply_max_increment::hbool_t
    max_increment::Csize_t
    flash_incr_mode::H5C_cache_flash_incr_mode
    flash_multiple::Cdouble
    flash_threshold::Cdouble
    decr_mode::H5C_cache_decr_mode
    upper_hr_threshold::Cdouble
    decrement::Cdouble
    apply_max_decrement::hbool_t
    max_decrement::Csize_t
    epochs_before_eviction::Cint
    apply_empty_reserve::hbool_t
    empty_reserve::Cdouble
    dirty_bytes_threshold::Csize_t
    metadata_write_strategy::Cint
end

struct H5AC_cache_image_config_t
    version::Cint
    generate_image::hbool_t
    save_resize_status::hbool_t
    entry_ageout::Cint
end

@enum H5D_vds_view_t::Int32 begin
    H5D_VDS_ERROR = -1
    H5D_VDS_FIRST_MISSING = 0
    H5D_VDS_LAST_AVAILABLE = 1
end

@enum H5D_fill_value_t::Int32 begin
    H5D_FILL_VALUE_ERROR = -1
    H5D_FILL_VALUE_UNDEFINED = 0
    H5D_FILL_VALUE_DEFAULT = 1
    H5D_FILL_VALUE_USER_DEFINED = 2
end

struct H5F_info2_super
    version::Cuint
    super_size::hsize_t
    super_ext_size::hsize_t
end

struct H5F_info2_free
    version::Cuint
    meta_size::hsize_t
    tot_space::hsize_t
end

struct H5F_info2_sohm
    version::Cuint
    hdr_size::hsize_t
    msgs_info::H5_ih_info_t
end

struct H5F_info2_t
    super::H5F_info2_super
    free::H5F_info2_free
    sohm::H5F_info2_sohm
end

struct H5F_retry_info_t
    nbins::Cuint
    retries::NTuple{21,Ptr{UInt32}}
end
