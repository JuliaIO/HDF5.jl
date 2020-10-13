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

# MPI communicators required by H5P
abstract  type Hmpih end
primitive type Hmpih32 <: Hmpih 32 end # MPICH C/Fortran, OpenMPI Fortran: 32 bit handles
primitive type Hmpih64 <: Hmpih 64 end # OpenMPI C: pointers (mostly 64 bit)

@defconstants H5 begin
    # iteration order constants
    ITER_UNKNOWN::Cint = -1
    ITER_INC::Cint     = 0
    ITER_DEC::Cint     = 1
    ITER_NATIVE::Cint  = 2
    ITER_N::Cint       = 3

    # indexing type constants
    INDEX_UNKNOWN::Cint   = -1
    INDEX_NAME::Cint      = 0
    INDEX_CRT_ORDER::Cint = 1
    INDEX_N::Cint         = 2
end

# dataset constants
@defconstants H5D begin
    # layouts (C enum H5D_layout_t
    COMPACT::Cint    = 0
    CONTIGUOUS::Cint = 1
    CHUNKED::Cint    = 2

    # allocation times (C enum H5D_alloc_time_t)
    ALLOC_TIME_ERROR::Cint   = -1
    ALLOC_TIME_DEFAULT::Cint = 0
    ALLOC_TIME_EARLY::Cint   = 1
    ALLOC_TIME_LATE::Cint    = 2
    ALLOC_TIME_INCR::Cint    = 3

    # used to "unset" chunk cache configuration parameters
    CHUNK_CACHE_NSLOTS_DEFAULT::Csize_t = -1 % Csize_t
    CHUNK_CACHE_NBYTES_DEFAULT::Csize_t = -1 % Csize_t
    CHUNK_CACHE_W0_DEFAULT::Cfloat      = -1.0f0
end

# error-related constants
@defconstants H5E begin
    DEFAULT::hid_t = 0
end

@defconstants H5F begin
    # file access modes
    ACC_RDONLY::Cuint     = 0x0000
    ACC_RDWR::Cuint       = 0x0001
    ACC_TRUNC::Cuint      = 0x0002
    ACC_EXCL::Cuint       = 0x0004
    ACC_DEBUG::Cuint      = 0x0008
    ACC_CREAT::Cuint      = 0x0010
    ACC_SWMR_WRITE::Cuint = 0x0020
    ACC_SWMR_READ::Cuint  = 0x0040

    # Library versions
    LIBVER_EARLIEST::Cint = 0
    LIBVER_V18::Cint      = 1
    LIBVER_V110::Cint     = 2
    LIBVER_LATEST::Cint   = 2 # H5F_LIBVER_V110

    # object types
    OBJ_FILE::Cuint     = 0x0001
    OBJ_DATASET::Cuint  = 0x0002
    OBJ_GROUP::Cuint    = 0x0004
    OBJ_DATATYPE::Cuint = 0x0008
    OBJ_ATTR::Cuint     = 0x0010
    OBJ_ALL::Cuint      = 0x001f # (H5F_OBJ_FILE|H5F_OBJ_DATASET|H5F_OBJ_GROUP|H5F_OBJ_DATATYPE|H5F_OBJ_ATTR)
    OBJ_LOCAL::Cuint    = 0x0020

    # other file constants
    SCOPE_LOCAL::Cint   = 0
    SCOPE_GLOBAL::Cint  = 1
    CLOSE_DEFAULT::Cint = 0
    CLOSE_WEAK::Cint    = 1
    CLOSE_SEMI::Cint    = 2
    CLOSE_STRONG::Cint  = 3
end

# file driver constants
@defconstants H5FD begin
    # C enum H5FD_mpio_xfer_t
    MPIO_INDEPENDENT::Cint    = 0
    MPIO_COLLECTIVE::Cint     = 1

    # C enum H5FD_mpio_chunk_opt_t
    MPIO_CHUNK_DEFAULT::Cint  = 0
    MPIO_CHUNK_ONE_IO::Cint   = 1
    MPIO_CHUNK_MULTI_IO::Cint = 2

    # C enum H5FD_mpio_collective_opt_t
    MPIO_COLLECTIVE_IO::Cint  = 0
    MPIO_INDIVIDUAL_IO::Cint  = 1
end

@defconstants H5I begin
    # object types (C enum H5Itype_t)
    FILE::Cint      = 1
    GROUP::Cint     = 2
    DATATYPE::Cint  = 3
    DATASPACE::Cint = 4
    DATASET::Cint   = 5
    ATTR::Cint      = 6
    REFERENCE::Cint = 7
    VFL::Cint       = 8
end

# Link constants
@defconstants H5L begin
    TYPE_HARD::Cint     = 0
    TYPE_SOFT::Cint     = 1
    TYPE_EXTERNAL::Cint = 2
end

# Object constants
@defconstants H5O begin
    TYPE_GROUP::Cint   = 0
    TYPE_DATASET::Cint = 1
    TYPE_NAMED_DATATYPE::Cint = 2
end

# Property constants
@defconstants H5P begin
    DEFAULT::hid_t = 0
    OBJECT_CREATE::hid_t
    FILE_CREATE::hid_t
    FILE_ACCESS::hid_t
    DATASET_CREATE::hid_t
    DATASET_ACCESS::hid_t
    DATASET_XFER::hid_t
    FILE_MOUNT::hid_t
    GROUP_CREATE::hid_t
    GROUP_ACCESS::hid_t
    DATATYPE_CREATE::hid_t
    DATATYPE_ACCESS::hid_t
    STRING_CREATE::hid_t
    ATTRIBUTE_CREATE::hid_t
    OBJECT_COPY::hid_t
    LINK_CREATE::hid_t
    LINK_ACCESS::hid_t
end

# Reference constants
@defconstants H5R begin
    OBJECT::Cint         = 0
    DATASET_REGION::Cint = 1
    OBJ_REF_BUF_SIZE::Cint      = 8  # == sizeof(hobj_ref_t)
    DSET_REG_REF_BUF_SIZE::Cint = 12 # == sizeof(hdset_reg_ref_t)
end

# Dataspace constants
@defconstants H5S begin
    # atomic data types
    ALL::hsize_t       = 0
    UNLIMITED::hsize_t = typemax(hsize_t)

    # Types of dataspaces (C enum H5S_class_t)
    SCALAR::hid_t    = hid_t(0)
    SIMPLE::hid_t    = hid_t(1)
    NULL::hid_t      = hid_t(2)

    # Dataspace selection constants (C enum H5S_seloper_t)
    SELECT_SET::Cint     = 0
    SELECT_OR::Cint      = 1
    SELECT_AND::Cint     = 2
    SELECT_XOR::Cint     = 3
    SELECT_NOTB::Cint    = 4
    SELECT_NOTA::Cint    = 5
    SELECT_APPEND::Cint  = 6
    SELECT_PREPEND::Cint = 7
end

@defconstants H5T begin
    # type classes (C enum H5T_class_t)
    INTEGER::hid_t   = 0
    FLOAT::hid_t     = 1
    TIME::hid_t      = 2  # not supported by HDF5 library
    STRING::hid_t    = 3
    BITFIELD::hid_t  = 4
    OPAQUE::hid_t    = 5
    COMPOUND::hid_t  = 6
    REFERENCE::hid_t = 7
    ENUM::hid_t      = 8
    VLEN::hid_t      = 9
    ARRAY::hid_t     = 10

    # Character types (C enum H5T_cset_t)
    CSET_ASCII::Cint = 0
    CSET_UTF8::Cint  = 1

    # String padding modes (C enum H5T_str_t)
    STR_NULLTERM::Cint = 0
    STR_NULLPAD::Cint  = 1
    STR_SPACEPAD::Cint = 2

    # Variable length string
    VARIABLE::Csize_t = -1 % Csize_t

    # Sign types (C enum H5T_sign_t)
    SGN_NONE::Cint = 0  # unsigned
    SGN_2::Cint    = 1  # 2's complement

    # Search directions (C enum H5T_direction_t)
    DIR_ASCEND::Cint  = 1
    DIR_DESCEND::Cint = 2

    # Type "constants" (LE = little endian, I16 = Int16, etc)
    STD_I8LE::hid_t
    STD_I8BE::hid_t
    STD_U8LE::hid_t
    STD_U8BE::hid_t
    STD_I16LE::hid_t
    STD_I16BE::hid_t
    STD_U16LE::hid_t
    STD_U16BE::hid_t
    STD_I32LE::hid_t
    STD_I32BE::hid_t
    STD_U32LE::hid_t
    STD_U32BE::hid_t
    STD_I64LE::hid_t
    STD_I64BE::hid_t
    STD_U64LE::hid_t
    STD_U64BE::hid_t
    IEEE_F32LE::hid_t
    IEEE_F32BE::hid_t
    IEEE_F64LE::hid_t
    IEEE_F64BE::hid_t
    C_S1::hid_t
    STD_REF_OBJ::hid_t
    STD_REF_DSETREG::hid_t
    NATIVE_B8::hid_t
    NATIVE_INT8::hid_t
    NATIVE_UINT8::hid_t
    NATIVE_INT16::hid_t
    NATIVE_UINT16::hid_t
    NATIVE_INT32::hid_t
    NATIVE_UINT32::hid_t
    NATIVE_INT64::hid_t
    NATIVE_UINT64::hid_t
    NATIVE_FLOAT::hid_t
    NATIVE_DOUBLE::hid_t
    NATIVE_FLOAT16::hid_t
end

# Filter constants
@defconstants H5Z begin
    FLAG_OPTIONAL::Cuint = 0x0001
    FLAG_REVERSE::Cuint = 0x0100
    CLASS_T_VERS::Cint = 1
end

function __init_globals__()
    libh = Libdl.dlopen(libhdf5)
    # Ensure runtime is initialized
    ccall(Libdl.dlsym(libh, :H5open), herr_t, ())
    # Note: dlsym must occur outside cglobal statement on Julia 1.5 and earlier or else
    # segfaults.
    function read_const(sym::Symbol)
        symptr = Libdl.dlsym(libh, sym)
        return unsafe_load(cglobal(symptr, hid_t))
    end

    H5P.OBJECT_CREATE    = read_const(:H5P_CLS_OBJECT_CREATE_ID_g)
    H5P.FILE_CREATE      = read_const(:H5P_CLS_FILE_CREATE_ID_g)
    H5P.FILE_ACCESS      = read_const(:H5P_CLS_FILE_ACCESS_ID_g)
    H5P.DATASET_CREATE   = read_const(:H5P_CLS_DATASET_CREATE_ID_g)
    H5P.DATASET_ACCESS   = read_const(:H5P_CLS_DATASET_ACCESS_ID_g)
    H5P.DATASET_XFER     = read_const(:H5P_CLS_DATASET_XFER_ID_g)
    H5P.FILE_MOUNT       = read_const(:H5P_CLS_FILE_MOUNT_ID_g)
    H5P.GROUP_CREATE     = read_const(:H5P_CLS_GROUP_CREATE_ID_g)
    H5P.GROUP_ACCESS     = read_const(:H5P_CLS_GROUP_ACCESS_ID_g)
    H5P.DATATYPE_CREATE  = read_const(:H5P_CLS_DATATYPE_CREATE_ID_g)
    H5P.DATATYPE_ACCESS  = read_const(:H5P_CLS_DATATYPE_ACCESS_ID_g)
    H5P.STRING_CREATE    = read_const(:H5P_CLS_STRING_CREATE_ID_g)
    H5P.ATTRIBUTE_CREATE = read_const(:H5P_CLS_ATTRIBUTE_CREATE_ID_g)
    H5P.OBJECT_COPY      = read_const(:H5P_CLS_OBJECT_COPY_ID_g)
    H5P.LINK_CREATE      = read_const(:H5P_CLS_LINK_CREATE_ID_g)
    H5P.LINK_ACCESS      = read_const(:H5P_CLS_LINK_ACCESS_ID_g)

    H5T.STD_I8LE        = read_const(:H5T_STD_I8LE_g)
    H5T.STD_I8BE        = read_const(:H5T_STD_I8BE_g)
    H5T.STD_U8LE        = read_const(:H5T_STD_U8LE_g)
    H5T.STD_U8BE        = read_const(:H5T_STD_U8BE_g)
    H5T.STD_I16LE       = read_const(:H5T_STD_I16LE_g)
    H5T.STD_I16BE       = read_const(:H5T_STD_I16BE_g)
    H5T.STD_U16LE       = read_const(:H5T_STD_U16LE_g)
    H5T.STD_U16BE       = read_const(:H5T_STD_U16BE_g)
    H5T.STD_I32LE       = read_const(:H5T_STD_I32LE_g)
    H5T.STD_I32BE       = read_const(:H5T_STD_I32BE_g)
    H5T.STD_U32LE       = read_const(:H5T_STD_U32LE_g)
    H5T.STD_U32BE       = read_const(:H5T_STD_U32BE_g)
    H5T.STD_I64LE       = read_const(:H5T_STD_I64LE_g)
    H5T.STD_I64BE       = read_const(:H5T_STD_I64BE_g)
    H5T.STD_U64LE       = read_const(:H5T_STD_U64LE_g)
    H5T.STD_U64BE       = read_const(:H5T_STD_U64BE_g)
    H5T.IEEE_F32LE      = read_const(:H5T_IEEE_F32LE_g)
    H5T.IEEE_F32BE      = read_const(:H5T_IEEE_F32BE_g)
    H5T.IEEE_F64LE      = read_const(:H5T_IEEE_F64LE_g)
    H5T.IEEE_F64BE      = read_const(:H5T_IEEE_F64BE_g)
    H5T.C_S1            = read_const(:H5T_C_S1_g)
    H5T.STD_REF_OBJ     = read_const(:H5T_STD_REF_OBJ_g)
    H5T.STD_REF_DSETREG = read_const(:H5T_STD_REF_DSETREG_g)
    H5T.NATIVE_B8       = read_const(:H5T_NATIVE_B8_g)
    H5T.NATIVE_INT8     = read_const(:H5T_NATIVE_INT8_g)
    H5T.NATIVE_UINT8    = read_const(:H5T_NATIVE_UINT8_g)
    H5T.NATIVE_INT16    = read_const(:H5T_NATIVE_INT16_g)
    H5T.NATIVE_UINT16   = read_const(:H5T_NATIVE_UINT16_g)
    H5T.NATIVE_INT32    = read_const(:H5T_NATIVE_INT32_g)
    H5T.NATIVE_UINT32   = read_const(:H5T_NATIVE_UINT32_g)
    H5T.NATIVE_INT64    = read_const(:H5T_NATIVE_INT64_g)
    H5T.NATIVE_UINT64   = read_const(:H5T_NATIVE_UINT64_g)
    H5T.NATIVE_FLOAT    = read_const(:H5T_NATIVE_FLOAT_g)
    H5T.NATIVE_DOUBLE   = read_const(:H5T_NATIVE_DOUBLE_g)

    nothing
end
