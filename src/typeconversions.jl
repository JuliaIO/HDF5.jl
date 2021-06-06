### Base HDF5 structs ###

# High-level reference handler
struct Reference
    r::API.hobj_ref_t
end
Reference() = Reference(API.HOBJ_REF_T_NULL) # NULL reference to compare to
Base.cconvert(::Type{Ptr{T}}, ref::Reference) where {T<:Union{Reference,API.hobj_ref_t,Cvoid}} = Ref(ref)

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

cset(::Type{<:AbstractString}) = API.H5T_CSET_UTF8
cset(::Type{UTF8Char}) = API.H5T_CSET_UTF8
cset(::Type{ASCIIChar}) = API.H5T_CSET_ASCII

## Conversion between Julia types and HDF5 atomic types
hdf5_type_id(::Type{Bool})      = API.H5T_NATIVE_B8
hdf5_type_id(::Type{Int8})      = API.H5T_NATIVE_INT8
hdf5_type_id(::Type{UInt8})     = API.H5T_NATIVE_UINT8
hdf5_type_id(::Type{Int16})     = API.H5T_NATIVE_INT16
hdf5_type_id(::Type{UInt16})    = API.H5T_NATIVE_UINT16
hdf5_type_id(::Type{Int32})     = API.H5T_NATIVE_INT32
hdf5_type_id(::Type{UInt32})    = API.H5T_NATIVE_UINT32
hdf5_type_id(::Type{Int64})     = API.H5T_NATIVE_INT64
hdf5_type_id(::Type{UInt64})    = API.H5T_NATIVE_UINT64
hdf5_type_id(::Type{Float32})   = API.H5T_NATIVE_FLOAT
hdf5_type_id(::Type{Float64})   = API.H5T_NATIVE_DOUBLE
hdf5_type_id(::Type{Reference}) = API.H5T_STD_REF_OBJ

hdf5_type_id(::Type{<:AbstractString}) = API.H5T_C_S1

const BitsType = Union{Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64}
const ScalarType = Union{BitsType,Reference}

# It's not safe to use particular id codes because these can change, so we use characteristics of the type.
function _hdf5_type_map(class_id, is_signed, native_size)
    if class_id == API.H5T_INTEGER
        if is_signed == API.H5T_SGN_2
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


# Methods for reference types
function Reference(parent::Union{File,Group,Dataset}, name::AbstractString)
    ref = Ref{API.hobj_ref_t}()
    API.h5r_create(ref, checkvalid(parent), name, API.H5R_OBJECT, -1)
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
    h = Vector{API.hvl_t}(undef, len)
    for ii in 1:len
        d = v.data[ii]
        p = unsafe_convert(Ptr{UInt8}, d)
        h[ii] = API.hvl_t(length(d), p)
    end
    return h
end



# Create a datatype from in-memory types
datatype(x::ScalarType) = Datatype(hdf5_type_id(typeof(x)), false)
datatype(::Type{T}) where {T<:ScalarType} = Datatype(hdf5_type_id(T), false)
datatype(A::AbstractArray{T}) where {T<:ScalarType} = Datatype(hdf5_type_id(T), false)
function datatype(::Type{Complex{T}}) where {T<:ScalarType}
  COMPLEX_SUPPORT[] || error("complex support disabled. call HDF5.enable_complex_support() to enable")
  dtype = API.h5t_create(API.H5T_COMPOUND, 2*sizeof(T))
  API.h5t_insert(dtype, COMPLEX_FIELD_NAMES[][1], 0, hdf5_type_id(T))
  API.h5t_insert(dtype, COMPLEX_FIELD_NAMES[][2], sizeof(T), hdf5_type_id(T))
  return Datatype(dtype)
end
datatype(x::Complex{<:ScalarType}) = datatype(typeof(x))
datatype(A::AbstractArray{Complex{T}}) where {T<:ScalarType} = datatype(eltype(A))

function datatype(str::AbstractString)
    type_id = API.h5t_copy(hdf5_type_id(typeof(str)))
    API.h5t_set_size(type_id, max(sizeof(str), 1))
    API.h5t_set_cset(type_id, cset(typeof(str)))
    Datatype(type_id)
end
function datatype(::Array{S}) where {S<:AbstractString}
    type_id = API.h5t_copy(hdf5_type_id(S))
    API.h5t_set_size(type_id, API.H5T_VARIABLE)
    API.h5t_set_cset(type_id, cset(S))
    Datatype(type_id)
end
datatype(A::VLen{T}) where {T<:ScalarType} = Datatype(API.h5t_vlen_create(hdf5_type_id(T)))
function datatype(str::VLen{C}) where {C<:CharType}
    type_id = API.h5t_copy(hdf5_type_id(C))
    API.h5t_set_size(type_id, 1)
    API.h5t_set_cset(type_id, cset(C))
    Datatype(API.h5t_vlen_create(type_id))
end



# Create a dataspace from in-memory types
dataspace(x::Union{T, Complex{T}}) where {T<:ScalarType} = Dataspace(API.h5s_create(API.H5S_SCALAR))
dataspace(::AbstractString) = Dataspace(API.h5s_create(API.H5S_SCALAR))

function _dataspace(sz::Dims{N}, max_dims::Union{Dims{N}, Tuple{}}=()) where N
    dims = API.hsize_t[sz[i] for i in N:-1:1]
    if isempty(max_dims)
        maxd = dims
    else
        # This allows max_dims to be specified as -1 without triggering an overflow
        # exception due to the signed -> unsigned conversion.
        maxd = API.hsize_t[API.hssize_t(max_dims[i]) % API.hsize_t for i in N:-1:1]
    end
    return Dataspace(API.h5s_create_simple(length(dims), dims, maxd))
end
dataspace(A::AbstractArray{T,N}; max_dims::Union{Dims{N},Tuple{}} = ()) where {T,N} = _dataspace(size(A), max_dims)
# special array types
dataspace(v::VLen; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(size(v.data), max_dims)
dataspace(A::EmptyArray) = Dataspace(API.h5s_create(API.H5S_NULL))
dataspace(n::Nothing) = Dataspace(API.h5s_create(API.H5S_NULL))
# for giving sizes explicitly
dataspace(sz::Dims{N}; max_dims::Union{Dims{N},Tuple{}}=()) where {N} = _dataspace(sz, max_dims)
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(tuple(sz1, sz2, sz3...), max_dims)


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

const DatasetOrAttribute = Union{Dataset,Attribute}

# Special handling for reading OPAQUE datasets and attributes
function generic_read(obj::DatasetOrAttribute, filetype::Datatype, ::Type{Opaque})
    sz  = size(obj)
    buf = Matrix{UInt8}(undef, sizeof(filetype), prod(sz))
    if obj isa Dataset
        read_dataset(obj, filetype, buf, obj.xfer)
    else
        read_attribute(obj, filetype, buf)
    end
    tag = API.h5t_get_tag(filetype)
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

    memtype = Datatype(API.h5t_get_native_type(filetype))  # padded layout in memory

    if sizeof(T) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($T) = $(sizeof(T))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

    dspace = dataspace(obj)
    stype = API.h5s_get_simple_extent_type(dspace)
    stype == API.H5S_NULL && return EmptyArray{T}()

    if !isempty(I)
        indices = Base.to_indices(obj, I)
        dspace = hyperslab(dspace, indices...)
    end

    scalar = false
    if stype == API.H5S_SCALAR
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
        API.h5d_read(obj, memtype, memspace, dspace, obj.xfer, buf)
    else
        API.h5a_read(obj, memtype, buf)
    end

    if do_normalize(T)
        out = reshape(normalize_types(T, buf), sz...)
    else
        out = buf
    end

    xfer_id = obj isa Dataset ? obj.xfer.id : API.H5P_DEFAULT
    do_reclaim(T) && API.h5d_vlen_reclaim(memtype, memspace, xfer_id, buf)

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
    if pad == API.H5T_STR_NULLTERM # null-terminated
        ind = findfirst(isequal('\0'), s)
        isnothing(ind) ? s : s[1:prevind(s, ind)]
    elseif pad == API.H5T_STR_NULLPAD # padded with nulls
        rstrip(s, '\0')
    elseif pad == API.H5T_STR_SPACEPAD # padded with spaces
        rstrip(s, ' ')
    else
        error("Unrecognized string padding mode $pad")
    end
end
unpad(s, pad::Integer) = unpad(String(s), pad)

# Dereference
function _deref(parent, r::Reference)
    r == Reference() && error("Reference is null")
    obj_id = API.h5r_dereference(checkvalid(parent), API.H5P_DEFAULT, API.H5R_OBJECT, r)
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


function get_jl_type(obj_type::Datatype)
    class_id = API.h5t_get_class(obj_type)
    if class_id == API.H5T_OPAQUE
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
    class_id = API.h5t_get_class(obj_type)
    if class_id == API.H5T_STRING
        if API.h5t_is_variable_str(obj_type)
            return Cstring
        else
            N = sizeof(obj_type)
            PAD = API.h5t_get_strpad(obj_type)
            return FixedString{N,PAD}
        end
    elseif class_id == API.H5T_INTEGER || class_id == API.H5T_FLOAT
        native_type = API.h5t_get_native_type(obj_type)
        try
            native_size = API.h5t_get_size(native_type)
            if class_id == API.H5T_INTEGER
                is_signed = API.h5t_get_sign(native_type)
            else
                is_signed = nothing
            end
            return _hdf5_type_map(class_id, is_signed, native_size)
        finally
            API.h5t_close(native_type)
        end
    elseif class_id == API.H5T_BITFIELD
        return Bool
    elseif class_id == API.H5T_ENUM
        super_type = API.h5t_get_super(obj_type)
        try
            native_type = API.h5t_get_native_type(super_type)
            try
                native_size = API.h5t_get_size(native_type)
                is_signed = API.h5t_get_sign(native_type)
                return _hdf5_type_map(API.H5T_INTEGER, is_signed, native_size)
            finally
                API.h5t_close(native_type)
            end
        finally
            API.h5t_close(super_type)
        end
    elseif class_id == API.H5T_REFERENCE
        # TODO update to use version 1.12 reference functions/types
        return Reference
    elseif class_id == API.H5T_OPAQUE
        # TODO: opaque objects should get their own fixed-size data type; punning like
        #       this permits recursively reading (i.e. compound data type containing an
        #       opaque field). Requires figuring out what to do about the tag...
        len = Int(API.h5t_get_size(obj_type))
        return FixedArray{UInt8, (len,), len}
    elseif class_id == API.H5T_VLEN
        superid = API.h5t_get_super(obj_type)
        return VariableArray{get_mem_compatible_jl_type(Datatype(superid))}
    elseif class_id == API.H5T_COMPOUND
        N = API.h5t_get_nmembers(obj_type)

        membernames = ntuple(N) do i
            API.h5t_get_member_name(obj_type, i-1)
        end

        membertypes = ntuple(N) do i
            dtype = Datatype(API.h5t_get_member_type(obj_type, i-1))
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
    elseif class_id == API.H5T_ARRAY
        dims = API.h5t_get_array_dims(obj_type)
        nd = length(dims)
        eltyp = Datatype(API.h5t_get_super(obj_type))
        elT = get_mem_compatible_jl_type(eltyp)
        dimsizes = ntuple(i -> Int(dims[nd-i+1]), nd)  # reverse order
        return FixedArray{elT, dimsizes, prod(dimsizes)}
    end
    error("Class id ", class_id, " is not yet supported")
end


function read_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::DatasetTransferProperties=dataset.xfer)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot read arrays with a different stride than `Array`"))
    API.h5d_read(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
end

function write_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::DatasetTransferProperties=dataset.xfer)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
end
function write_dataset(dataset::Dataset, memtype::Datatype, str::AbstractString, xfer::DatasetTransferProperties=dataset.xfer)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        # unsafe_convert(Cstring, strbuf) is responsible for enforcing the no-'\0' policy,
        # but then need explicit convert to Ptr{UInt8} since Ptr{Cstring} -> Ptr{Cvoid} is
        # not automatic.
        buf = convert(Ptr{UInt8}, Base.unsafe_convert(Cstring, strbuf))
        API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
    end
end
function write_dataset(dataset::Dataset, memtype::Datatype, x::T, xfer::DatasetTransferProperties=dataset.xfer) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, tmp)
end
function write_dataset(dataset::Dataset, memtype::Datatype, strs::Array{<:AbstractString}, xfer::DatasetTransferProperties=dataset.xfer)
    p = Ref{Cstring}(strs)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, p)
end
write_dataset(dataset::Dataset, memtype::Datatype, ::EmptyArray, xfer::DatasetTransferProperties=dataset.xfer) = nothing

# type-specific behaviors
function write_attribute(attr::Attribute, memtype::Datatype, str::AbstractString)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        buf = Base.unsafe_convert(Ptr{UInt8}, strbuf)
        API.h5a_write(attr, memtype, buf)
    end
end
function write_attribute(attr::Attribute, memtype::Datatype, x::T) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    API.h5a_write(attr, memtype, tmp)
end
function write_attribute(attr::Attribute, memtype::Datatype, strs::Array{<:AbstractString})
    p = Ref{Cstring}(strs)
    API.h5a_write(attr, memtype, p)
end
write_attribute(attr::Attribute, memtype::Datatype, ::EmptyArray) = nothing
