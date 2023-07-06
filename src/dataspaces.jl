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
Dataspace # defined in types.jl

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
 - `struct` types: a scalar `Dataspace`
 - `nothing` or an `EmptyArray`: a null dataspace
"""
dataspace(x::T) where {T} =
    if isstructtype(T)
        Dataspace(API.h5s_create(API.H5S_SCALAR))
    else
        throw(MethodError(dataspace, x))
    end
dataspace(x::Union{T,Complex{T}}) where {T<:ScalarType} =
    Dataspace(API.h5s_create(API.H5S_SCALAR))
dataspace(::AbstractString) = Dataspace(API.h5s_create(API.H5S_SCALAR))

function _dataspace(sz::Dims{N}, max_dims::Union{Dims{N},Tuple{}}=()) where {N}
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
dataspace(A::AbstractArray{T,N}; max_dims::Union{Dims{N},Tuple{}}=()) where {T,N} =
    _dataspace(size(A), max_dims)
# special array types
dataspace(v::VLen; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(size(v.data), max_dims)
dataspace(A::EmptyArray) = Dataspace(API.h5s_create(API.H5S_NULL))
dataspace(n::Nothing) = Dataspace(API.h5s_create(API.H5S_NULL))

# for giving sizes explicitly
"""
    dataspace(dims::Tuple; max_dims::Tuple=dims)
    dataspace(dims::Tuple, max_dims::Tuple)

Construct a simple `Dataspace` for the given dimensions `dims`. The maximum
dimensions `maxdims` specifies the maximum possible size: `-1` can be used to
indicate unlimited dimensions.
"""
dataspace(sz::Dims{N}; max_dims::Union{Dims{N},Tuple{}}=()) where {N} =
    _dataspace(sz, max_dims)
dataspace(sz::Dims{N}, max_dims::Union{Dims{N},Tuple{}}) where {N} =
    _dataspace(sz, max_dims)
dataspace(dims::Tuple{Dims{N},Dims{N}}) where {N} = _dataspace(first(dims), last(dims))
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union{Dims,Tuple{}}=()) =
    _dataspace(tuple(sz1, sz2, sz3...), max_dims)

function Base.ndims(dspace::Dataspace)
    API.h5s_get_simple_extent_ndims(checkvalid(dspace))
end
function Base.size(dspace::Dataspace)
    h5_dims = API.h5s_get_simple_extent_dims(checkvalid(dspace), nothing)
    N = length(h5_dims)
    return ntuple(i -> @inbounds(Int(h5_dims[N - i + 1])), N)
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

"""
    HDF5.get_regular_hyperslab(dspace)::Tuple

Get the hyperslab selection from `dspace`. Returns a tuple of [`BlockRange`](@ref) objects.
"""
function get_regular_hyperslab(dspace::Dataspace)
    start0, stride, count, block = API.h5s_get_regular_hyperslab(dspace)
    N = length(start0)
    ntuple(N) do i
        ri = N - i + 1
        @inbounds BlockRange(start0[ri], stride[ri], count[ri], block[ri])
    end
end

struct BlockRange
    start0::API.hsize_t
    stride::API.hsize_t
    count::API.hsize_t
    block::API.hsize_t
end

"""
    HDF5.BlockRange(;start::Integer, stride::Integer=1, count::Integer=1, block::Integer=1)

A `BlockRange` represents a selection along a single dimension of a HDF5
hyperslab. It is similar to a Julia `range` object, with some extra features for
selecting multiple contiguous blocks.

- `start`: the index of the first element in the first block (1-based).
- `stride`: the step between the first element of each block (must be >0)
- `count`: the number of blocks (can be -1 for an unlimited number of blocks)
- `block`: the number of elements in each block.


    HDF5.BlockRange(obj::Union{Integer, OrdinalRange})

Convert `obj` to a `BlockRange` object.

# External links
- [HDF5 User Guide, section 7.4.2.1 "Selecting Hyperslabs"](https://support.hdfgroup.org/HDF5/doc/UG/HDF5_Users_Guide-Responsive%20HTML5/index.html#t=HDF5_Users_Guide%2FDataspaces%2FHDF5_Dataspaces_and_Partial_I_O.htm%23TOC_7_4_2_Programming_Modelbc-8&rhtocid=7.2.0_2)
"""
function BlockRange(; start::Integer, stride::Integer=1, count::Integer=1, block::Integer=1)
    if count == -1
        count = API.H5S_UNLIMITED
    end
    BlockRange(start - 1, stride, count, block)
end
BlockRange(start::Integer; stride=1, count=1, block=1) =
    BlockRange(; start=start, stride=stride, count=count, block=block)
BlockRange(r::AbstractUnitRange; stride=max(length(r), 1), count=1) =
    BlockRange(; start=first(r), stride=stride, count=count, block=length(r))
BlockRange(r::OrdinalRange) = BlockRange(; start=first(r), stride=step(r), count=length(r))
BlockRange(br::BlockRange) = br

Base.to_index(d::Dataset, br::BlockRange) = br
Base.length(br::BlockRange) = Int(br.count * br.block)

function Base.range(br::BlockRange)
    start = Int(br.start0 + 1)
    if br.count == 1
        # UnitRange
        return range(start; length=Int(br.block))
    elseif br.block == 1 && br.count != API.H5S_UNLIMITED
        # StepRange
        return range(start; step=Int(br.stride), length=Int(br.count))
    else
        error("$br cannot be converted to a Julia range")
    end
end
Base.convert(::Type{T}, br::BlockRange) where {T<:AbstractRange} = convert(T, range(br))

"""
    HDF5.select_hyperslab!(dspace::Dataspace, [op, ], idxs::Tuple)

Selects a hyperslab region of the `dspace`. `idxs` should be a tuple of
integers, ranges or [`BlockRange`](@ref) objects.

- `op` determines how the new selection is to be combined with the already
  selected dataspace:
  - `:select` (default): replace the existing selection with the new selection.
  - `:or`: adds the new selection to the existing selection.
     Aliases: `|`, `∪`, `union`.
  - `:and`: retains only the overlapping portions of the new and existing
    selection. Aliases: `&`, `∩`, `intersect`.
  - `:xor`: retains only the elements that are members of the new selection or
    the existing selection, excluding elements that are members of both
    selections. Aliases: `⊻`, `xor`
  - `:notb`: retains only elements of the existing selection that are not in the
    new selection. Alias: `setdiff`.
  - `:nota`: retains only elements of the new selection that are not in the
    existing selection.

"""
function select_hyperslab!(
    dspace::Dataspace, op::Union{Symbol,typeof.((&, |, ⊻, ∪, ∩, setdiff))...}, idxs::Tuple
)
    N = ndims(dspace)
    length(idxs) == N || error("Number of indices does not match dimension of Dataspace")

    blockranges = map(BlockRange, idxs)
    _start0 = API.hsize_t[blockranges[N - i + 1].start0 for i in 1:N]
    _stride = API.hsize_t[blockranges[N - i + 1].stride for i in 1:N]
    _count = API.hsize_t[blockranges[N - i + 1].count for i in 1:N]
    _block = API.hsize_t[blockranges[N - i + 1].block for i in 1:N]

    _op = if op == :select
        API.H5S_SELECT_SET
    elseif (op == :or || op === (|) || op === (∪))
        API.H5S_SELECT_OR
    elseif (op == :and || op === (&) || op === (∩))
        API.H5S_SELECT_AND
    elseif (op == :xor || op === (⊻))
        API.H5S_SELECT_XOR
    elseif op == :notb || op === setdiff
        API.H5S_SELECT_NOTB
    elseif op == :nota
        API.H5S_SELECT_NOTA
    else
        error("invalid operator $op")
    end

    API.h5s_select_hyperslab(dspace, _op, _start0, _stride, _count, _block)
    return dspace
end
select_hyperslab!(dspace::Dataspace, idxs::Tuple) = select_hyperslab!(dspace, :select, idxs)

hyperslab(dspace::Dataspace, I::Union{AbstractRange{Int},Integer,BlockRange}...) =
    hyperslab(dspace, I)

function hyperslab(dspace::Dataspace, I::Tuple)
    select_hyperslab!(copy(dspace), I)
end

# methods for Dataset/Attribute which operate on Dataspace
function Base.ndims(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    try
        return Base.ndims(dspace)
    finally
        close(dspace)
    end
end
function Base.size(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    try
        return Base.size(dspace)
    finally
        close(dspace)
    end
end
function Base.size(obj::Union{Dataset,Attribute}, d::Integer)
    dspace = dataspace(obj)
    try
        return Base.size(dspace, d)
    finally
        close(dspace)
    end
end
function Base.length(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    try
        return Base.length(dspace)
    finally
        close(dspace)
    end
end
function Base.isempty(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    try
        return Base.isempty(dspace)
    finally
        close(dspace)
    end
end
function isnull(obj::Union{Dataset,Attribute})
    dspace = dataspace(obj)
    try
        return isnull(dspace)
    finally
        close(dspace)
    end
end

function hyperslab(dset::Dataset, I::Union{AbstractRange{Int},Int}...)
    dspace = dataspace(dset)
    try
        return hyperslab(dspace, I...)
    finally
        close(dspace)
    end
end
