### Read and write operations common to multiple types

# Convenience macros
macro read(fid, sym)
    !isa(sym, Symbol) && error("Second input to @read must be a symbol (i.e., a variable)")
    esc(:($sym = read($fid, $(string(sym)))))
end
macro write(fid, sym)
    !isa(sym, Symbol) && error("Second input to @write must be a symbol (i.e., a variable)")
    esc(:(write($fid, $(string(sym)), $sym)))
end

# Generic read functions

"""
    read(parent::Union{HDF5.File, HDF5.Group}, name::AbstractString; pv...)
    read(parent::Union{HDF5.File, HDF5.Group}, name::AbstractString => dt::HDF5.Datatype; pv...)

Read a dataset or attribute from a HDF5 file of group identified by `name`.
Optionally, specify the [`HDF5.Datatype`](@ref) to be read.
"""
function Base.read(parent::Union{File,Group}, name::AbstractString; pv...)
    obj = getindex(parent, name; pv...)
    val = read(obj)
    close(obj)
    val
end

function Base.read(
    parent::Union{File,Group}, name_type_pair::Pair{<:AbstractString,DataType}; pv...
)
    obj = getindex(parent, name_type_pair[1]; pv...)
    val = read(obj, name_type_pair[2])
    close(obj)
    val
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5.Datatype. Specific file formats should provide their own read(dset).
const DatasetOrAttribute = Union{Dataset,Attribute}

"""
    read(obj::HDF5.DatasetOrAttribute}

Read the data within a [`HDF5.Dataset`](@ref) or [`HDF5.Attribute`](@ref).
"""
function Base.read(obj::DatasetOrAttribute)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    val = generic_read(obj, dtype, T)
    close(dtype)
    return val
end

function Base.getindex(obj::DatasetOrAttribute, I...)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

function Base.read(obj::DatasetOrAttribute, ::Type{T}, I...) where {T}
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
    T <: Union{Cstring,FixedString} || error(name(obj), " cannot be read as type `String`")
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

"""
    copyto!(output_buffer::AbstractArray{T}, obj::Union{DatasetOrAttribute}) where T

Copy [part of] a HDF5 dataset or attribute to a preallocated output buffer.
The output buffer must be convertible to a pointer and have a contiguous layout.
"""
function Base.copyto!(
    output_buffer::AbstractArray{T}, obj::DatasetOrAttribute, I...
) where {T}
    dtype = datatype(obj)
    val = nothing
    try
        val = generic_read!(output_buffer, obj, dtype, T, I...)
    finally
        close(dtype)
    end
    return val
end

# Special handling for reading OPAQUE datasets and attributes
function generic_read!(
    buf::Matrix{UInt8}, obj::DatasetOrAttribute, filetype::Datatype, ::Type{Opaque}
)
    generic_read(obj, filetype, Opaque, buf)
end
function generic_read(
    obj::DatasetOrAttribute,
    filetype::Datatype,
    ::Type{Opaque},
    buf::Union{Matrix{UInt8},Nothing}=nothing
)
    sz = size(obj)
    if isnothing(buf)
        buf = Matrix{UInt8}(undef, sizeof(filetype), prod(sz))
    end
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
        data = reshape([buf[:, i] for i in 1:prod(sz)], sz...)
    end
    return Opaque(data, tag)
end

# generic read function
function generic_read!(
    buf::Union{AbstractMatrix{UInt8},AbstractArray{T}},
    obj::DatasetOrAttribute,
    filetype::Datatype,
    ::Type{T},
    I...
) where {T}
    return _generic_read(obj, filetype, T, buf, I...)
end
function generic_read(
    obj::DatasetOrAttribute, filetype::Datatype, ::Type{T}, I...
) where {T}
    return _generic_read(obj, filetype, T, nothing, I...)
end
function _generic_read(
    obj::DatasetOrAttribute,
    filetype::Datatype,
    ::Type{T},
    buf::Union{AbstractMatrix{UInt8},AbstractArray{T},Nothing},
    I...
) where {T}
    sz, scalar, dspace = _size_of_buffer(obj, I)

    if isempty(sz)
        close(dspace)
        return EmptyArray{T}()
    end

    try
        if isnothing(buf)
            buf = _normalized_buffer(T, sz)
        else
            sizeof(buf) != prod(sz) * sizeof(T) && error(
                "Provided array buffer of size, $(size(buf)), and element type, $(eltype(buf)), does not match the dataset of size, $sz, and type, $T"
            )
        end
    catch err
        close(dspace)
        rethrow(err)
    end

    memtype = _memtype(filetype, T)
    memspace = isempty(I) ? dspace : dataspace(sz)

    try
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

        if scalar
            return out[1]
        else
            return out
        end
    catch e
        # Add nicer errors if reading fails.
        if obj isa Dataset
            prop = get_create_properties(obj)
            try
                Filters.ensure_filters_available(Filters.FilterPipeline(prop))
            finally
                close(prop)
            end
        end
        throw(e)
    finally
        close(memtype)
        close(memspace)
        close(dspace)
    end
end

"""
    similar(obj::DatasetOrAttribute, [::Type{T}], [dims::Integer...]; normalize = true)

Return a `Array{T}` or `Matrix{UInt8}` to that can contain [part of] the dataset.

The `normalize` keyword will normalize the buffer for string and array datatypes.
"""
function Base.similar(
    obj::DatasetOrAttribute, ::Type{T}, dims::Dims; normalize::Bool=true
) where {T}
    filetype = datatype(obj)
    try
        return similar(obj, filetype, T, dims; normalize=normalize)
    finally
        close(filetype)
    end
end
Base.similar(
    obj::DatasetOrAttribute, ::Type{T}, dims::Integer...; normalize::Bool=true
) where {T} = similar(obj, T, Int.(dims); normalize=normalize)

# Base.similar without specifying the Julia type
function Base.similar(obj::DatasetOrAttribute, dims::Dims; normalize::Bool=true)
    filetype = datatype(obj)
    try
        T = get_jl_type(filetype)
        return similar(obj, filetype, T, dims; normalize=normalize)
    finally
        close(filetype)
    end
end
Base.similar(obj::DatasetOrAttribute, dims::Integer...; normalize::Bool=true) =
    similar(obj, Int.(dims); normalize=normalize)

# Opaque types
function Base.similar(
    obj::DatasetOrAttribute, filetype::Datatype, ::Type{Opaque}; normalize::Bool=true
)
    # normalize keyword for consistency, but it is ignored for Opaque
    sz = size(obj)
    return Matrix{UInt8}(undef, sizeof(filetype), prod(sz))
end

# Undocumented Base.similar signature allowing filetype to be specified
function Base.similar(
    obj::DatasetOrAttribute, filetype::Datatype, ::Type{T}, dims::Dims; normalize::Bool=true
) where {T}
    # We are reusing code that expect indices
    I = Base.OneTo.(dims)
    sz, scalar, dspace = _size_of_buffer(obj, I)
    memtype = _memtype(filetype, T)
    try
        buf = _normalized_buffer(T, sz)

        if normalize && do_normalize(T)
            buf = reshape(normalize_types(T, buf), sz)
        end

        return buf
    finally
        close(dspace)
        close(memtype)
    end
end
Base.similar(
    obj::DatasetOrAttribute,
    filetype::Datatype,
    ::Type{T},
    dims::Integer...;
    normalize::Bool=true
) where {T} = similar(obj, filetype, T, Int.(dims); normalize=normalize)

# Utilities used in Base.similar implementation

#=
    _memtype(filetype::Datatype, T)

This is a utility function originall from generic_read.
It gets the native memory type for the system based on filetype, and checks
if the size matches.
=#
@inline function _memtype(filetype::Datatype, ::Type{T}) where {T}
    !isconcretetype(T) && error("type $T is not concrete")

    # padded layout in memory
    memtype = Datatype(API.h5t_get_native_type(filetype))

    if sizeof(T) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($T) = $(sizeof(T))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

    return memtype
end

@inline function _memtype(filetype::Datatype, ::Type{S}) where {S<:AbstractString}
    return datatype(S)
end

#=
    _size_of_buffer(obj::DatasetOrAttribute, [I::Tuple, dspace::Dataspace])

This is a utility function originally from generic_read, but factored out.
The primary purpose is to determine the size and shape of the buffer to
create in order to hold the contents of a Dataset or Attribute.

# Arguments
* obj - A Dataset or Attribute
* I - (optional) indices, defaults to ()
* dspace - (optional) dataspace, defaults to dataspace(obj).
           This argument will be consumed by hyperslab and returned.

# Returns
* `sz` the size of the selection
* `scalar`, which is true if the value should be read as a scalar.
* `dspace`, hyper
=#
@inline function _size_of_buffer(
    obj::DatasetOrAttribute, I::Tuple=(), dspace::Dataspace=dataspace(obj)
)
    !isempty(I) &&
        obj isa Attribute &&
        error("HDF5 attributes do not support hyperslab selections")

    stype = API.h5s_get_simple_extent_type(dspace)

    if !isempty(I) && stype != API.H5S_NULL
        indices = Base.to_indices(obj, I)
        dspace = hyperslab(dspace, indices...)
    end

    scalar = false
    if stype == API.H5S_SCALAR
        sz = (1,)
        scalar = true
    elseif stype == API.H5S_NULL
        sz = ()
        # scalar = false
    elseif isempty(I)
        sz = size(dspace)
        # scalar = false
    else
        # Determine the size by the length of non-Int indices
        sz = map(length, filter(i -> !isa(i, Int), indices))
        if isempty(sz)
            # All indices are Int, so this is scalar
            sz = (1,)
            scalar = true
        end
    end

    return sz, scalar, dspace
end

#=
    _normalized_buffer(T, sz)

Return a Matrix{UInt8} for a normalized type or `Array{T}` for a regular type.
See `do_normalize` in typeconversions.jl.
=#
@inline function _normalized_buffer(::Type{T}, sz::NTuple{N,Int}) where {T,N}
    if do_normalize(T)
        # The entire dataset is read into in a buffer matrix where the first dimension at
        # any stage of normalization is the bytes for a single element of type `T`, and
        # the second dimension of the matrix runs through all elements.
        buf = Matrix{UInt8}(undef, sizeof(T), prod(sz))
    else
        buf = Array{T}(undef, sz...)
    end

    return buf
end
