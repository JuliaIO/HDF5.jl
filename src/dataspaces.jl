"""
    Dataspace

A dataspace defines the size and the shape of a dataset or an attribute, and is
also used for selecting a subset of a dataset.

# Constructors

    Dataspace(dims::Tuple; max_dims::Tuple=dims)

Construct a simple array `Dataspace` for the given dimensions `dims`. The maximum
dimensions `max_dims` specifies the maximum possible size: `HDF5.UNLIMITED` can
be used to indicate unlimited dimensions.
        
    Dataspace(())

Construct a scalar `Dataspace`. This is a dataspace containing a single element.

    Dataspace(nothing)

Construct a null `Dataspace`. This is a dataspace containing no elements.

See also [`dataspace`](@ref).

# Usage

The following functions have methods defined for `Dataspace` objects
- `==`
- `ndims`
- `size`
- `length`
- `isempty`
- [`isnull`](@ref)
"""
Dataspace # defined in types.jl

"""
    HDF5.UNLIMITED

A sentinel value which indicates an unlimited dimension in a
[`Dataspace`](@ref).

Can be used as an entry in the `max_dims` argument in the [`Dataspace`](@ref)
constructor or [`create_dataset`](@ref), or as a `count` argument in
[`BlockRange`](@ref) when selecting virtual dataset mappings.
"""
const UNLIMITED = -1

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

# null dataspace constructor
Dataspace(::Nothing; max_dims::Nothing=nothing) = Dataspace(API.h5s_create(API.H5S_NULL))

# reverese dims order, convert to hsize_t
_to_h5_dims(dims::Dims{N}) where {N} = API.hsize_t[dims[i] for i in N:-1:1]
function _from_h5_dims(h5_dims::Vector{API.hsize_t})
    N = length(h5_dims)
    ntuple(i -> @inbounds(Int(h5_dims[N - i + 1])), N)
end

# reverse dims order, convert to hsize_t, map UNLIMITED to H5S_UNLIMITED
_to_h5_maxdims(max_dims::Dims{N}) where {N} = API.hsize_t[
    max_dims[i] == HDF5.UNLIMITED ? API.H5S_UNLIMITED : API.hsize_t(max_dims[i]) for
    i in N:-1:1
]
_to_h5_maxdims(::Nothing) = C_NULL
function _from_h5_maxdims(h5_maxdims::Vector{API.hsize_t})
    N = length(h5_maxdims)
    ntuple(N) do i
        d = @inbounds(h5_maxdims[N - i + 1])
        d == API.H5S_UNLIMITED ? HDF5.UNLIMITED : Int(d)
    end
end

function Dataspace(dims::Dims{N}; max_dims::Union{Dims{N},Nothing}=nothing) where {N}
    return Dataspace(API.h5s_create_simple(N, _to_h5_dims(dims), _to_h5_maxdims(max_dims)))
end

"""
    dataspace(obj::Union{Attribute, Dataset, Dataspace})

The [`Dataspace`](@ref) of `obj`.
"""
dataspace(ds::Dataspace) = ds

# Create a dataspace from in-memory types
"""
    dataspace(data)

Constructs an appropriate `Dataspace` for representing a Julia object `data`.

 - strings or numbers: a scalar `Dataspace`
 - arrays: a simple `Dataspace`
 - `struct` types: a scalar `Dataspace`
 - `nothing` or an `EmptyArray`: a null dataspace
"""
function dataspace(x::T) where {T}
    if isstructtype(T)
        Dataspace(API.h5s_create(API.H5S_SCALAR))
    else
        throw(MethodError(dataspace, x))
    end
end
dataspace(x::Union{T,Complex{T}}) where {T<:ScalarType} =
    Dataspace(API.h5s_create(API.H5S_SCALAR))
dataspace(::AbstractString) = Dataspace(API.h5s_create(API.H5S_SCALAR))

dataspace(A::AbstractArray{T,N}; max_dims::Union{Dims{N},Nothing}=nothing) where {T,N} =
    Dataspace(size(A); max_dims)

# special array types
dataspace(v::VLen; max_dims::Union{Dims,Nothing}=nothing) =
    Dataspace(size(v.data); max_dims)

dataspace(A::EmptyArray) = Dataspace(nothing)
dataspace(n::Nothing) = Dataspace(nothing)

# convenience function
function dataspace(fn, obj::Union{Dataset,Attribute}, args...)
    dspace = dataspace(obj)
    try
        fn(dspace, args...)
    finally
        close(dspace)
    end
end

function Base.ndims(dspace::Dataspace)
    API.h5s_get_simple_extent_ndims(checkvalid(dspace))
end
Base.ndims(obj::Union{Dataset,Attribute}) = dataspace(ndims, obj)

function Base.size(dspace::Dataspace)
    h5_dims = API.h5s_get_simple_extent_dims(checkvalid(dspace), nothing)
    return _from_h5_dims(h5_dims)
end
Base.size(obj::Union{Dataset,Attribute}) = dataspace(size, obj)

function Base.size(dspace::Dataspace, d::Integer)
    d > 0 || throw(ArgumentError("invalid dimension d; must be positive integer"))
    N = ndims(dspace)
    d > N && return 1
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    return @inbounds Int(h5_dims[N - d + 1])
end
Base.size(obj::Union{Dataset,Attribute}, d::Integer) = dataspace(size, obj, d)

function Base.length(dspace::Dataspace)
    isnull(dspace) && return 0
    h5_dims = API.h5s_get_simple_extent_dims(checkvalid(dspace), nothing)
    return Int(prod(h5_dims))
end
Base.length(obj::Union{Dataset,Attribute}) = dataspace(length, obj)

Base.isempty(dspace::Dataspace) = length(dspace) == 0
Base.isempty(obj::Union{Dataset,Attribute}) = dataspace(isempty, obj)

"""
    isnull(dspace::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute})

Determines whether the given object has no size (consistent with the `API.H5S_NULL` dataspace).

# Examples
```julia-repl
julia> HDF5.isnull(Dataspace(nothing))
true

julia> HDF5.isnull(Dataspace(()))
false

julia> HDF5.isnull(Dataspace((0,)))
false
```
"""
function isnull(dspace::Dataspace)
    return API.h5s_get_simple_extent_type(checkvalid(dspace)) == API.H5S_NULL
end
isnull(obj::Union{Dataset,Attribute}) = dataspace(isnull, obj)

"""
    HDF5.set_extent_dims(dspace::HDF5.Dataspace, new_dims::Dims, max_dims::Union{Dims,Nothing} = nothing)

Change the dimensions of a dataspace `dspace` to `new_dims`, optionally with the maximum possible
dimensions `max_dims` different from the active size `new_dims`. If not given, `max_dims` is set equal
to `new_dims`.
"""
function set_extent_dims(
    dspace::Dataspace, dims::Dims{N}, max_dims::Union{Dims{N},Nothing}=nothing
) where {N}
    checkvalid(dspace)
    API.h5s_set_extent_simple(dspace, N, _to_h5_dims(dims), _to_h5_maxdims(max_dims))
    return nothing
end

"""
    HDF5.get_extent_dims(obj::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute}) -> dims, maxdims

Get the array dimensions from a dataspace, dataset, or attribute and return a tuple of `dims` and `maxdims`.
"""
function get_extent_dims(dspace::Dataspace)
    checkvalid(dspace)
    h5_dims, h5_maxdims = API.h5s_get_simple_extent_dims(dspace)
    return _from_h5_dims(h5_dims), _from_h5_maxdims(h5_maxdims)
end
get_extent_dims(obj::Union{Dataset,Attribute}) = dataspace(get_extent_dims, obj)

# Selection
"""
    HDF5.is_selection_valid(dspace::HDF5.Dataspace)

Determines whether the selection is valid for the extent of the dataspace.
"""
function is_selection_valid(dspace::Dataspace)
    return API.h5s_select_valid(checkvalid(dspace))
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

- `count`: the number of blocks. Can be [`HDF5.UNLIMITED`](@ref) for an
  unlimited number of blocks (e.g. for a virtual dataset mapping).

- `block`: the number of elements in each block.


    HDF5.BlockRange(obj::Union{Integer, OrdinalRange})

Convert `obj` to a `BlockRange` object.

# External links
- [HDF5 User Guide, section 7.4.2.1 "Selecting
  Hyperslabs"](https://support.hdfgroup.org/HDF5/doc/UG/HDF5_Users_Guide-Responsive%20HTML5/index.html#t=HDF5_Users_Guide%2FDataspaces%2FHDF5_Dataspaces_and_Partial_I_O.htm%23TOC_7_4_2_Programming_Modelbc-8&rhtocid=7.2.0_2)
"""
function BlockRange(; start::Integer, stride::Integer=1, count::Integer=1, block::Integer=1)
    if count == UNLIMITED
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
function select_hyperslab!(dspace::Dataspace, op::API.H5S_seloper_t, idxs::Tuple)
    N = ndims(dspace)
    length(idxs) == N || error("Number of indices does not match dimension of Dataspace")

    blockranges = map(idxs, size(dspace)) do idx, dim
        if idx isa Colon
            BlockRange(Base.OneTo(dim))
        else
            BlockRange(idx)
        end
    end
    _start0 = API.hsize_t[blockranges[N - i + 1].start0 for i in 1:N]
    _stride = API.hsize_t[blockranges[N - i + 1].stride for i in 1:N]
    _count = API.hsize_t[blockranges[N - i + 1].count for i in 1:N]
    _block = API.hsize_t[blockranges[N - i + 1].block for i in 1:N]

    API.h5s_select_hyperslab(dspace, op, _start0, _stride, _count, _block)
    return dspace
end
select_hyperslab!(dspace::Dataspace, op, idxs::Tuple) =
    select_hyperslab!(dspace, _seloper(op), idxs)

# convert to API.H5S_seloper_t value
function _seloper(op::Symbol)
    if op == :select
        API.H5S_SELECT_SET
    elseif op == :or
        API.H5S_SELECT_OR
    elseif op == :and
        API.H5S_SELECT_AND
    elseif op == :xor
        API.H5S_SELECT_XOR
    elseif op == :notb
        API.H5S_SELECT_NOTB
    elseif op == :nota
        API.H5S_SELECT_NOTA
    else
        error("invalid operator $op")
    end
end
_seloper(::typeof(|)) = API.H5S_SELECT_OR
_seloper(::typeof(∪)) = API.H5S_SELECT_OR
_seloper(::typeof(&)) = API.H5S_SELECT_AND
_seloper(::typeof(∩)) = API.H5S_SELECT_AND
_seloper(::typeof(⊻)) = API.H5S_SELECT_XOR
_seloper(::typeof(setdiff)) = API.H5S_SELECT_NOTB

select_hyperslab!(dspace::Dataspace, idxs::Tuple) = select_hyperslab!(dspace, :select, idxs)

function hyperslab(dspace::Dataspace, I::Tuple)
    select_hyperslab!(copy(dspace), I)
end

hyperslab(dspace::Dataspace, I::Union{AbstractRange{Int},Integer,BlockRange}...) =
    hyperslab(dspace, I)
hyperslab(dset::Dataset, I...) = dataspace(hyperslab, dset, I...)
