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

function Base.close(obj::Dataspace)
    if obj.id != -1
        if isvalid(obj)
            API.h5s_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Dataspace) = obj.id != -1 && API.h5i_is_valid(obj)

Base.:(==)(dspace1::Dataspace, dspace2::Dataspace) = API.h5s_extent_equal(checkvalid(dspace1), checkvalid(dspace2))
Base.hash(dspace::Dataspace, h::UInt) = hash(dspace.id, hash(Dataspace, h))
Base.copy(dspace::Dataspace) = Dataspace(API.h5s_copy(checkvalid(dspace)))


function dataspace(fn, obj)
    dspace = dataspace(obj)
    try
        fn(dspace)
    finally
        close(dspace)
    end
end


function Base.ndims(dspace::Dataspace)
    checkvalid(dspace)
    return API.h5s_get_simple_extent_ndims(dspace)
end
function Base.size(dspace::Dataspace)
    checkvalid(dspace)
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    N = length(h5_dims)
    return ntuple(i -> @inbounds(Int(h5_dims[N-i+1])), N)
end
function Base.size(dspace::Dataspace, d::Integer)
    checkvalid(dspace)
    d > 0 || throw(ArgumentError("invalid dimension d; must be positive integer"))
    N = ndims(dspace)
    d > N && return 1
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    return @inbounds Int(h5_dims[N - d + 1])
end
function Base.length(dspace::Dataspace)
    checkvalid(dspace)
    isnull(dspace) && return 0
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    return Int(prod(h5_dims))
end
Base.isempty(dspace::Dataspace) = length(dspace) == 0

"""
    isnull(dspace::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute})

Determines whether the given object has no size (consistent with the `H5S_NULL` dataspace).

# Examples
```julia-repl
julia> HDF5.isnull(dataspace(HDF5.EmptyArray{Float64}()))
true

julia> HDF5.isnull(dataspace((0,)))
false
```
"""
function isnull(dspace::Dataspace)
    checkvalid(dspace)
    return API.h5s_get_simple_extent_type(dspace) == API.H5S_NULL
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
    dsel = copy(dspace)
    API.h5s_select_hyperslab(dsel, API.H5S_SELECT_SET, dsel_start, dsel_stride, dsel_count, C_NULL)
    return dsel
end

