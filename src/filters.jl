module Filters

abstract type Filter end

"""
    FILTERS

Maps filter id to filter type.
"""
const FILTERS = Dict{H5Z_filter_t, Any}()

"""
    filterid(::F)
    filterid(F)

The internal filter id of a filter of type `F`.
"""
filterid(::F) where {F<:Filter} = filterid(F)

struct UnknownFilter <: Filter
    filter_id::H5Z_filter_t
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
    h5p_get_nfilters(f.plist)
end
Base.size(f::FilterPipeline) = (length(f),)

function Base.getindex(f::FilterPipeline, i::Integer)
    id = h5p_get_filter(f.plist, i-1, C_NULL, C_NULL, C_NULL, 0, C_NULL, C_NULL)
    F = get(FILTERS, id, UnknownFilter)
    return getindex(f, F, i)
end

function Base.getindex(f::FilterPipeline, ::Type{UnknownFilter}, i::Integer, cd_values::Vector{Cuint} = Cuint[])
    flags = Ref{Cuint}()
    cd_nelmts = Ref{Csize_t}(length(cd_values))
    namebuf = Array{UInt8}(undef, 256)
    config = Ref{Cuint}()
    id = h5p_get_filter(f.plist, i-1, flags, cd_nelmts, cd_values, length(namebuf), namebuf, config)
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
        id = h5p_get_filter(f.plist, i-1, C_NULL, div(sizeof(F), sizeof(Cuint)), pointer_from_objref(ref), 0, C_NULL, C_NULL)
    end
    @assert id == filterid(F)
    return ref[]
end
function Base.getindex(f::FilterPipeline, ::Type{F}) where {F<:Filter}
    @assert isbitstype(F)
    ref = Ref{F}()
    GC.@preserve ref begin
        h5p_get_filter_by_id(f.plist, filterid(F), C_NULL, div(sizeof(F), sizeof(Cuint)), pointer_from_objref(ref), 0, C_NULL, C_NULL)
    end
    return ref[]
end


function Base.empty!(filters::FilterPipeline)
    h5p_remove_filter(filters.plist, H5Z_FILTER_ALL)
    return filters
end
function Base.delete!(filters::FilterPipeline, ::Type{F}) where {F<:Filter}
    h5p_remove_filter(filters.plist, filterid(F))
    return filters
end
function Base.append!(filters::FilterPipeline, extra)
    for filter in extra
        push!(filters, filter)
    end
    return filters
end



struct Deflate <: Filter
    level::Cuint
end
filterid(::Type{Deflate}) = H5Z_FILTER_DEFLATE
FILTERS[H5Z_FILTER_DEFLATE] = Deflate

function Base.push!(f::FilterPipeline, deflate::Deflate)
    h5p_set_deflate(f.plist, deflate.level)
    return f
end


struct Shuffle <: Filter
end
filterid(::Type{Shuffle}) = H5Z_FILTER_SHUFFLE
FILTERS[H5Z_FILTER_SHUFFLE] = Shuffle

function Base.push!(f::FilterPipeline, ::Shuffle)
    h5p_set_shuffle(f.plist)
    return f
end


struct Fletcher32 <: Filter
end
filterid(::Type{Fletcher32}) = H5Z_FILTER_FLETCHER32
FILTERS[H5Z_FILTER_FLETCHER32] = Fletcher32
function Base.push!(f::FilterPipeline, ::Fletcher32)
    h5p_set_fletcher32(f.plist)
    return f
end


struct Szip <: Filter
    options_mask::Cuint
    pixels_per_block::Cuint
end
filterid(::Type{Szip}) = H5Z_FILTER_SZIP
FILTERS[H5Z_FILTER_SZIP] = Szip
function Base.push!(f::FilterPipeline, szip::Szip)
    h5p_set_szip(f.plist, szip.options_mask, szip.pixels_per_block)
    return f
end


struct NBit <: Filter
end
filterid(::Type{NBit}) = H5Z_FILTER_NBIT
FILTERS[H5Z_FILTER_NBIT] = NBit
function Base.push!(f::FilterPipeline, ::NBit)
    h5p_set_nbit(f.plist)
    return f
end


struct ScaleOffset <: Filter
    scale_type::Cint
    scale_factor::Cint
end
filterid(::Type{ScaleOffset}) = H5Z_FILTER_SCALEOFFSET
FILTERS[H5Z_FILTER_SCALEOFFSET] = ScaleOffset
function Base.push!(f::FilterPipeline, scaleoffset::ScaleOffset)
    h5p_set_scaleoffset(f.plist, scaleoffset.scale_type, scaleoffset.scale_factor)
    return f
end

end
