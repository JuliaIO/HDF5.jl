"""
    HDF5.Dataspace

A dataspace defines the size and the shape of a dataset or an attribute.

A dataspace is typically constructed by calling [`dataspace`](@ref).

The following functions have methods defined for `Dataspace` objects
- `==`
- `ndims`
- `size`
- `length`
- `isempty`
- [`isnull`](@ref)
"""
mutable struct Dataspace
    id::API.hid_t

    function Dataspace(id)
        dspace = new(id)
        finalizer(close, dspace)
        dspace
    end
end
Base.cconvert(::Type{API.hid_t}, dspace::Dataspace) = dspace
Base.unsafe_convert(::Type{API.hid_t}, dspace::Dataspace) = dspace.id

Base.:(==)(dspace1::Dataspace, dspace2::Dataspace) =
    API.h5s_extent_equal(checkvalid(dspace1), checkvalid(dspace2))
Base.hash(dspace::Dataspace, h::UInt) = hash(dspace.id, hash(Dataspace, h))
Base.copy(dspace::Dataspace) = Dataspace(API.h5s_copy(checkvalid(dspace)))

function Base.close(obj::Dataspace)
    if obj.id != -1
        if isvalid(obj)
            API.h5s_close(obj)
        end
        obj.id = -1
    end
    nothing
end

"""
    dataspace(obj::Union{Attribute, Dataset, Dataspace})

The [`Dataspace`](@ref) of `obj`.
"""
dataspace(ds::Dataspace) = ds


# Create a dataspace from in-memory types
"""
    dataspace(data)

The default `Dataspace` used for representing a Julia object `data`:
 - strings or numbers: a scalar `Dataspace`
 - arrays: a simple `Dataspace`
 - `nothing` or an `EmptyArray`: a null dataspace
"""
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
"""
    dataspace(dims::Tuple; maxdims::Tuple=dims)

Construct a simple `Dataspace` for the given dimensions `dims`. The maximum
dimensions `maxdims` specifies the maximum possible size: `-1` can be used to
indicate unlimited dimensions.
"""
dataspace(sz::Dims{N}; max_dims::Union{Dims{N},Tuple{}}=()) where {N} = _dataspace(sz, max_dims)
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(tuple(sz1, sz2, sz3...), max_dims)


function Base.ndims(dspace::Dataspace)
    API.h5s_get_simple_extent_ndims(checkvalid(dspace))
end
function Base.size(dspace::Dataspace)
    h5_dims = API.h5s_get_simple_extent_dims(checkvalid(dspace), nothing)
    N = length(h5_dims)
    return ntuple(i -> @inbounds(Int(h5_dims[N-i+1])), N)
end
function Base.size(dspace::Dataspace, d::Integer)
    d > 0 || throw(ArgumentError("invalid dimension d; must be positive integer"))
    N = ndims(dspace)
    d > N && return 1
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    return @inbounds Int(h5_dims[N - d + 1])
end
function Base.length(dspace::Dataspace)
    isnull(dspace) && return 0
    h5_dims = API.h5s_get_simple_extent_dims(checkvalid(dspace), nothing)
    return Int(prod(h5_dims))
end
Base.isempty(dspace::Dataspace) = length(dspace) == 0


"""
    isnull(dspace::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute})

Determines whether the given object has no size (consistent with the `API.H5S_NULL` dataspace).

# Examples
```julia-repl
julia> HDF5.isnull(dataspace(HDF5.EmptyArray{Float64}()))
true

julia> HDF5.isnull(dataspace((0,)))
false
```
"""
function isnull(dspace::Dataspace)
    return API.h5s_get_simple_extent_type(checkvalid(dspace)) == API.H5S_NULL
end


function get_regular_hyperslab(dspace::Dataspace)
    start, stride, count, block = API.h5s_get_regular_hyperslab(dspace)
    N = length(start)
    @inline rev(v) = ntuple(i -> @inbounds(Int(v[N-i+1])), N)
    return rev(start), rev(stride), rev(count), rev(block)
end

function hyperslab(dspace::Dataspace, I::Union{AbstractRange{Int},Int}...)
    dims = size(dspace)
    n_dims = length(dims)
    if length(I) != n_dims
        error("Wrong number of indices supplied, supplied length $(length(I)) but expected $(n_dims).")
    end
    dsel_id = API.h5s_copy(dspace)
    dsel_start  = Vector{API.hsize_t}(undef,n_dims)
    dsel_stride = Vector{API.hsize_t}(undef,n_dims)
    dsel_count  = Vector{API.hsize_t}(undef,n_dims)
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
    API.h5s_select_hyperslab(dsel_id, API.H5S_SELECT_SET, dsel_start, dsel_stride, dsel_count, C_NULL)
    return Dataspace(dsel_id)
end
