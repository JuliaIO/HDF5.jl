module Filters

export Deflate, Shuffle, Fletcher32, Szip, NBit, ScaleOffset, BloscFilter, Bzip2Filter, Lz4Filter, ZstdFilter

import ..HDF5: Properties, h5doc, API
using Requires: @require

"""
    Filter

Abstract type to describe HDF5 Filters.
See the Extended Help for information on implementing a new filter.

# Extended Help

## Filter interface

The Filter interface can be implemented upon either the Filter subtype or an instance.
The instance methods default to calling the same method on the type.

See API.h5z_register for details.

### Required Methods to Implement
* `filterid` - registered filter ID
* `filter_func` - implement the actual filter

### Optional Methods to Implement
* `filtername` - defaults to "Unnamed Filter"
* `encoder_present` - defaults to true
* `decoder_present` - defaults to true
* `can_apply_func` - defaults to nothing
* `set_local_func` - defaults to nothing

### Advanced Methods to Implement
* `can_apply_cfunc` - Defaults to wrapping @cfunction around the result of `can_apply_func`
* `set_local_cfunc` - Defaults to wrapping @cfunction around the result of `set_local_func`
* `filter_cfunc` - Defaults to wrapping @cfunction around the result of `filter_func`
* `register_filter` - Defaults to using the above functions to register the filter

Implement the Advanced Methods to avoid @cfunction from generating a runtime closure which may not work on all systems.
"""
abstract type Filter end

"""
    FILTERS

Maps filter id to filter type.
"""
const FILTERS = Dict{API.H5Z_filter_t, Type{<: Filter}}()

"""
    filterid(::F) where {F <: Filter}
    filterid(F) where {F <: Filter}


The internal filter id of a filter of type `F`.
"""
filterid(::F) where {F<:Filter} = filterid(F)

"""
    encoder_present(::F) where {F<:Filter}

Can the filter have an encode or compress the data?
Defaults to true.
Returns a Bool. See `API.h5z_register`.
"""
encoder_present(::F) where {F<:Filter} = encoder_present(F)
encoder_present(::Type{F}) where {F<:Filter} = true

"""
    decoder_present(::F) where {F<:Filter}

Can the filter decode or decompress the data?
Defaults to true.
Returns a Bool.
See `API.h5z_register`
"""
decoder_present(::F) where {F<:Filter} = decoder_present(F)
decoder_present(::Type{F}) where {F<:Filter} = true

"""
    filtername(::F) where {F<:Filter}

What is the name of a filter?
Defaults to "Unnamed Filter"
Returns a String describing the filter. See `API.h5z_register`
"""
filtername(::F) where {F<:Filter} = filtername(F)
filtername(::Type{F}) where {F<:Filter} = "Unnamed Filter"

"""
    can_apply_func(::F) where {F<:Filter}

Return a function indicating whether the filter can be applied or `nothing` is no function exists.
The function signature is `func(dcpl_id::API.hid_t, type_id::API.hid_t, space_id::API.hid_t)`.
See `API.h5z_register`
"""
can_apply_func(::F) where {F<:Filter} = can_apply_func(F)
can_apply_func(::Type{F}) where {F<:Filter} = nothing
function can_apply_cfunc(f::F) where {F<:Filter}
    func = can_apply_func(f)
    if func === nothing
        return C_NULL
    else
        return @cfunction($func, API.herr_t, (API.hid_t,API.hid_t,API.hid_t))
    end
end

"""
    set_local_func(::F) where {F<:Filter}

Return a function that sets dataset specific parameters or `nothing` if no function exists.
The function signature is `func(dcpl_id::API.hid_t, type_id::API.hid_t, space_id::API.hid_t)`.
See `API.h5z_register`
"""
set_local_func(::F) where {F<:Filter} = set_local_func(F)
set_local_func(::Type{F}) where {F<:Filter} = nothing
function set_local_cfunc(f::F) where {F<:Filter}
    func = set_local_func(f)
    if func === nothing
        return C_NULL
    else
        return @cfunction($func, API.herr_t, (API.hid_t,API.hid_t,API.hid_t))
    end
end


"""
    filter_func(::F) where {F<:Filter}

Returns a function that performs the actual filtering.

See `API.h5z_register`
"""
filter_func(::F) where {F<:Filter} = filter_func(F)
filter_func(::Type{F}) where {F<:Filter} = nothing
function filter_cfunc(f::F) where {F<:Filter}
    func = filter_func(f)
    if func === nothing
        error("Filter function for $f must be defined via `filter_func`.")
    end
    c_filter_func = @cfunction($func, Csize_t,
                               (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                               Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))
    return c_filter_func
end

struct UnknownFilter <: Filter
    filter_id::API.H5Z_filter_t
    flags::Cuint
    data::Vector{Cuint}
    name::String
    config::Cuint
end
filterid(filter::UnknownFilter) = filter.filter_id
filtername(filter::UnknownFilter) = filter.name
filtername(::Type{UnknownFilter}) = "Unknown Filter"
encoder_present(::Type{UnknownFilter}) = false
decoder_present(::Type{UnknownFilter}) = false

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
function Base.push!(p::FilterPipeline, f::F) where F <: Filter
    ref = Ref(f)
    GC.@preserve ref begin
        API.h5p_set_filter(p.plist, filterid(F), API.H5Z_FLAG_OPTIONAL, div(sizeof(F), sizeof(Cuint)), pointer_from_objref(ref))
    end
    return p
end
function Base.push!(p::FilterPipeline, f::UnknownFilter)
    GC.@preserve f begin
        API.h5p_set_filter(p.plist, f.filter_id, f.flags, length(f.data), pointer(f.data))
    end
end

# Generic implementation of register_filter
"""
    register_filter(filter::F) where F <: Filter

Register the filter with the HDF5 library via API.h5z_register.
Also add F to the FILTERS dictionary.
"""
function register_filter(filter::F) where F <: Filter
    id = filterid(filter)
    encoder = encoder_present(filter)
    decoder = decoder_present(filter)
    name = filtername(filter)
    can_apply = can_apply_cfunc(filter)
    set_local = set_local_cfunc(filter)
    func = filter_cfunc(filter)
    GC.@preserve name begin
        API.h5z_register(API.H5Z_class_t(
            API.H5Z_CLASS_T_VERS,
            id,
            encoder,
            decoder,
            pointer(name),
            can_apply,
            set_local,
            func
        ))
    end
    # Should this be the filter instance rather than the type?
    FILTERS[id] = F
    return nothing
end
register_filter(::Type{F}) where {F<:Filter} = register_filter(F())

function register_filters()
    # Load filter codec packages which should trigger Requires.jl
    @eval begin
        using Blosc
        using CodecBzip2
        using CodecLz4
        using CodecZstd
    end
end

include("builtin.jl")

function __init__()
    @require Blosc="a74b3585-a348-5f62-a45c-50e91977d574" @eval begin
        include("H5Zblosc.jl")
        import .H5Zblosc: register_blosc, BloscFilter
        register_blosc()
    end
    @require CodecBzip2="523fee87-0ab8-5b00-afb7-3ecf72e48cfd" @eval begin
        include("H5Zbzip2.jl")
        import .H5Zbzip2: register_bzip2, Bzip2Filter
        register_bzip2()
    end
    @require CodecLz4="5ba52731-8f18-5e0d-9241-30f10d1ec561" @eval begin
        include("H5Zlz4.jl")
        import .H5Zlz4: register_lz4, Lz4Filter
        register_lz4()
    end
    @require CodecZstd="6b39b394-51ab-5f42-8807-6242bab2b4c2" @eval begin
        include("H5Zzstd.jl")
        import .H5Zzstd: register_zstd, ZstdFilter
        register_zstd()
    end
end

precompile(register_filters, ())

end # module