
abstract type Filter end

"""
    FILTERS

Maps filter id to filter type
"""
const FILTERS = Dict{H5Z_filter_t, Any}()

struct UnknownFilter <: Filter
    filter_id::H5Z_filter_t
    flags::Cuint
    data::Vector{Cuint}
    name::String
    config::Cuint
end


struct Deflate <: Filter
    level::Cuint
end
filterid(::Deflate) = H5Z_FILTER_DEFLATE
FILTERS[H5Z_FILTER_DEFLATE] = Deflate

struct Shuffle <: Filter
end
filterid(::Shuffle) = H5Z_FILTER_SHUFFLE
FILTERS[H5Z_FILTER_SHUFFLE] = Shuffle

struct Fletcher32 <: Filter
end
filterid(::Fletcher32) = H5Z_FILTER_FLETCHER32
FILTERS[H5Z_FILTER_FLETCHER32] = Fletcher32

struct Szip <: Filter
    options_mask::Cuint
    pixels_per_block::Cuint
end
filterid(::Szip) = H5Z_FILTER_SZIP
FILTERS[H5Z_FILTER_SZIP] = Szip

struct NBit <: Filter
end
filterid(::NBit) = H5Z_FILTER_NBIT
FILTERS[H5Z_FILTER_NBIT] = NBit

struct ScaleOffset <: Filter
    scale_type::Cint
    scale_factor::Cint
end
filterid(::ScaleOffset) = H5Z_FILTER_SCALEOFFSET
FILTERS[H5Z_FILTER_SCALEOFFSET] = ScaleOffset


    




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
    id = h5p_get_filter(f.plist, i-1, C_NULL, div(sizeof(F), sizeof(Cuint)), pointer_from_objref(ref), 0, C_NULL, C_NULL)
    @assert id == filterid(ref[])
    return ref[]
end

function Base.push!(f::FilterPipeline, deflate::Deflate)
    h5p_set_deflate(f.plist, deflate.level)
    return f
end



# Base.push!(filters::FilterPipeline, filter)
# Base.append!(filters::FilterPipeline, ...)
# Base.getindex(filters::FilterPipeline, i::Integer)
# Base.getindex(filters::FilterPipeline, ::Type{Filter})
# Base.empty!(filters::FilterPipeline)
# Base.delete!(filters::FilterPipeline, ::Type{Filter})
