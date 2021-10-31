module Filters

export Deflate, Shuffle, Fletcher32, Szip, NBit, ScaleOffset, BloscFilter

import ..HDF5: Properties, h5doc, API

abstract type Filter end

"""
    FILTERS

Maps filter id to filter type.
"""
const FILTERS = Dict{API.H5Z_filter_t, Any}()

"""
    filterid(::F)
    filterid(F)

The internal filter id of a filter of type `F`.
"""
filterid(::F) where {F<:Filter} = filterid(F)

struct UnknownFilter <: Filter
    filter_id::API.H5Z_filter_t
    flags::Cuint
    data::Vector{Cuint}
    name::String
    config::Cuint
end

"""
    FilterPipeline(plist::DatasetCreateProperties)

The filter pipeline associated with `plist`. Acts like a `AbstractVector{Filter}`,
supporting the following operations:

- `length(pipeline)`: the number of filters.
- `pipeline[i]` to return the `i`th filter.
- `pipeline[FilterType]` to return a filter of type `FilterType`
- `push!(pipline, filter)` to add an extra filter to the pipeline.
- `append!(pipeline, filters)` to add multiple filters to the pipeline.
- `delete!(pipeline, FilterType)` to remove a filter of type `FilterType` from the pipeline.
- `empty!(pipeline)` to remove all filters from the pipeline.
"""
struct FilterPipeline{P<:Properties} <: AbstractVector{Filter}
    plist::P
end

function Base.length(f::FilterPipeline)
    API.h5p_get_nfilters(f.plist)
end
Base.size(f::FilterPipeline) = (length(f),)

function Base.getindex(f::FilterPipeline, i::Integer)
    id = API.h5p_get_filter(f.plist, i-1, C_NULL, C_NULL, C_NULL, 0, C_NULL, C_NULL)
    F = get(FILTERS, id, UnknownFilter)
    return getindex(f, F, i)
end

function Base.getindex(f::FilterPipeline, ::Type{UnknownFilter}, i::Integer, cd_values::Vector{Cuint} = Cuint[])
    flags = Ref{Cuint}()
    cd_nelmts = Ref{Csize_t}(length(cd_values))
    namebuf = Array{UInt8}(undef, 256)
    config = Ref{Cuint}()
    id = API.h5p_get_filter(f.plist, i-1, flags, cd_nelmts, cd_values, length(namebuf), namebuf, config)
    if cd_nelmts[] < length(cd_values)
        resize!(cd_values, cd_nelmts[])
        return getindex(f, UnknownFilter, i, cd_values)
    end
    resize!(namebuf, findfirst(isequal(0), namebuf)-1)
    resize!(cd_values, cd_nelmts[])
    return UnknownFilter(id, flags[], cd_values, String(namebuf), config[])
end

function Base.getindex(f::FilterPipeline, ::Type{F}, i::Integer) where {F<:Filter}
    @assert isbitstype(F)
    ref = Ref{F}()
    GC.@preserve ref begin
        id = API.h5p_get_filter(f.plist, i-1, C_NULL, div(sizeof(F), sizeof(Cuint)), pointer_from_objref(ref), 0, C_NULL, C_NULL)
    end
    @assert id == filterid(F)
    return ref[]
end
function Base.getindex(f::FilterPipeline, ::Type{F}) where {F<:Filter}
    @assert isbitstype(F)
    ref = Ref{F}()
    GC.@preserve ref begin
        API.h5p_get_filter_by_id(f.plist, filterid(F), C_NULL, div(sizeof(F), sizeof(Cuint)), pointer_from_objref(ref), 0, C_NULL, C_NULL)
    end
    return ref[]
end


function Base.empty!(filters::FilterPipeline)
    API.h5p_remove_filter(filters.plist, API.H5Z_FILTER_ALL)
    return filters
end
function Base.delete!(filters::FilterPipeline, ::Type{F}) where {F<:Filter}
    API.h5p_remove_filter(filters.plist, filterid(F))
    return filters
end
function Base.append!(filters::FilterPipeline, extra)
    for filter in extra
        push!(filters, filter)
    end
    return filters
end

include("builtin.jl")
include("blosc.jl")

end # module
