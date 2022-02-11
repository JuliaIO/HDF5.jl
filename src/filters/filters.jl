"""
HDF5.Filters

This module contains the interface for using filters in HDF5.jl.

# Example Usage
```julia
using HDF5
using HDF5.Filters

# Create a new file
fn = tempname()

# Create test data
data = rand(1000, 1000)

# Open temp file for writing
f = h5open(fn, "w") 

# Create datasets
dsdeflate = create_dataset(f, "deflate", datatype(data), dataspace(data),
                           chunk=(100, 100), deflate=3)

dsshufdef = create_dataset(f, "shufdef", datatype(data), dataspace(data),
                           chunk=(100, 100), shuffle=true, deflate=3)

dsfiltdef = create_dataset(f, "filtdef", datatype(data), dataspace(data),
                           chunk=(100, 100), filters=Filters.Deflate(3))

dsfiltshufdef = create_dataset(f, "filtshufdef", datatype(data), dataspace(data),
                               chunk=(100, 100), filters=[Filters.Shuffle(), Filters.Deflate(3)])

# Write data
write(dsdeflate, data)
write(dsshufdef, data)
write(dsfiltdef, data)
write(dsfiltshufdef, data)

close(f)
```

## Additonal Examples

See [test/filter.jl](https://github.com/JuliaIO/HDF5.jl/blob/master/test/filter.jl) for further examples.
"""
module Filters

# builtin filters
export Deflate, Shuffle, Fletcher32, Szip, NBit, ScaleOffset

import ..HDF5: Properties, h5doc, API


"""
    Filter

Abstract type to describe HDF5 Filters.
See the Extended Help for information on implementing a new filter.

# Extended Help

## Filter interface

The Filter interface is implemented upon the Filter subtype.

See [`API.h5z_register`](@ref) for details.

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
    filterid(F) where {F <: Filter}


The internal filter id of a filter of type `F`.
"""
filterid

"""
    encoder_present(::Type{F}) where {F<:Filter}

Can the filter have an encode or compress the data?
Defaults to true.
Returns a Bool. See [`API.h5z_register`](@ref).
"""
encoder_present(::Type{F}) where {F<:Filter} = true

"""
    decoder_present(::Type{F}) where {F<:Filter}

Can the filter decode or decompress the data?
Defaults to true.
Returns a Bool.
See [`API.h5z_register`](@ref)
"""
decoder_present(::Type{F}) where {F<:Filter} = true

"""
    filtername(::Type{F}) where {F<:Filter}

What is the name of a filter?
Defaults to "Unnamed Filter"
Returns a String describing the filter. See [`API.h5z_register`](@ref)
"""
filtername(::Type{F}) where {F<:Filter} = "Unnamed Filter"

"""
    can_apply_func(::Type{F}) where {F<:Filter}

Return a function indicating whether the filter can be applied or `nothing` if no function exists.
The function signature is `func(dcpl_id::API.hid_t, type_id::API.hid_t, space_id::API.hid_t)`.
See [`API.h5z_register`](@ref)
"""
can_apply_func(::Type{F}) where {F<:Filter} = nothing

"""
    can_apply_cfunc(::Type{F}) where {F<:Filter}

Return a C function pointer for the can apply function.
By default, this will return the result of using `@cfunction` on the function
specified by `can_apply_func(F)` or `C_NULL` if `nothing`.

Overriding this will allow `@cfunction` to return a `Ptr{Nothing}` rather
than a `CFunction`` closure which may not work on all systems.
"""
function can_apply_cfunc(::Type{F}) where {F<:Filter}
    func = can_apply_func(F)
    if func === nothing
        return C_NULL
    else
        return @cfunction($func, API.herr_t, (API.hid_t,API.hid_t,API.hid_t))
    end
end

"""
    set_local_func(::Type{F}) where {F<:Filter}

Return a function that sets dataset specific parameters or `nothing` if no function exists.
The function signature is `func(dcpl_id::API.hid_t, type_id::API.hid_t, space_id::API.hid_t)`.
See [`API.h5z_register`](@ref).
"""
set_local_func(::Type{F}) where {F<:Filter} = nothing

"""
    set_local_cfunc(::Type{F}) where {F<:Filter}

Return a C function pointer for the set local function.
By default, this will return the result of using `@cfunction` on the function
specified by `set_local_func(F)` or `C_NULL` if `nothing`.

Overriding this will allow `@cfunction` to return a `Ptr{Nothing}` rather
than a `CFunction`` closure which may not work on all systems.
"""
function set_local_cfunc(::Type{F}) where {F<:Filter}
    func = set_local_func(F)
    if func === nothing
        return C_NULL
    else
        return @cfunction($func, API.herr_t, (API.hid_t,API.hid_t,API.hid_t))
    end
end


"""
    filter_func(::Type{F}) where {F<:Filter}

Returns a function that performs the actual filtering.

See [`API.h5z_register`](@ref)
"""
filter_func(::Type{F}) where {F<:Filter} = nothing

"""
    filter_cfunc(::Type{F}) where {F<:Filter}

Return a C function pointer for the filter function.
By default, this will return the result of using `@cfunction` on the function
specified by `filter_func(F)` or will throw an error if `nothing`.

Overriding this will allow `@cfunction` to return a `Ptr{Nothing}` rather
than a `CFunction`` closure which may not work on all systems.
"""
function filter_cfunc(::Type{F}) where {F<:Filter}
    func = filter_func(F)
    if func === nothing
        error("Filter function for $f must be defined via `filter_func`.")
    end
    c_filter_func = @cfunction($func, Csize_t,
                               (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                               Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))
    return c_filter_func
end

# Generic implementation of register_filter
"""
    register_filter(::Type{F}) where F <: Filter

Register the filter with the HDF5 library via [`API.h5z_register`](@ref).
Also add F to the FILTERS dictionary.
"""
function register_filter(::Type{F}) where F <: Filter
    id = filterid(F)
    encoder = encoder_present(F)
    decoder = decoder_present(F)
    name = filtername(F)
    can_apply = can_apply_cfunc(F)
    set_local = set_local_cfunc(F)
    func = filter_cfunc(F)
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
    FILTERS[id] = F
    return nothing
end

"""
    UnknownFilter(filter_id::API.H5Z_filter_t, flags::Cuint, data::Vector{Cuint}, name::String, config::Cuint)

An unknown filter.
"""
struct UnknownFilter <: Filter
    filter_id::API.H5Z_filter_t
    flags::Cuint
    data::Vector{Cuint}
    name::String
    config::Cuint
end
function UnknownFilter(filter_id, flags, data::Integer...)
    UnknownFilter(filter_id, flags, Cuint[data...], "Unknown Filter with id $filter_id", 0)
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
    if cd_nelmts[] > length(cd_values)
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
function Base.append!(filters::FilterPipeline, extra::Union{AbstractVector{<:Filter}, NTuple{N, Filter} where N})
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

# Convert a Filter to an Integer subtype using filterid
function Base.convert(::Type{I}, ::Type{F}) where {I <: Integer, F <: Filter}
    Base.convert(I, filterid(F))
end

include("builtin.jl")

end # module
