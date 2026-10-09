#=
Management of multiple implementations of the same HDF5 filter.

libhdf5 can only have one function registered for a given filter id at a time.
Several Julia packages (or a native plugin that libhdf5 finds on `HDF5_PLUGIN_PATH`)
may nevertheless implement the same filter id. This file keeps track of every
implementation that has been loaded and decides which one is registered with
libhdf5 according to a priority order that the user can configure.
=#

import Preferences

"""
    Implementation

A record of one implementation of a filter id: the `provider` (by default the name of the
package that defines the filter type, e.g. `:H5Zzstd`) and the `Filter` subtype `type`.
"""
struct Implementation
    provider::Symbol
    type::Type{<:Filter}
end

"""
    NATIVE

The reserved provider name `:native`. It stands for the filter plugins that libhdf5
loads itself from `HDF5_PLUGIN_PATH` (for example plugins built from
$(h5doc_external(:plugins_repo, "hdf5_plugins")) or shipped with `NetCDF_jll`).
Place `:native` in a priority list to prefer such a plugin over a Julia implementation.
"""
const NATIVE = :native

# filter id => implementations in order of registration
const IMPLEMENTATIONS = Dict{API.H5Z_filter_t,Vector{Implementation}}()
# filter id => provider currently registered with (or, for :native, loaded by) libhdf5
const ACTIVE = Dict{API.H5Z_filter_t,Symbol}()
# filter id => priority set at runtime via `set_priority!`
const RUNTIME_PRIORITY = Dict{API.H5Z_filter_t,Vector{Symbol}}()
# Settings from Preferences.jl, see `load_preferences!`
const PREFERENCES = (
    auto_register=Ref(true),
    disabled=Set{Symbol}(),
    priority=Dict{Union{Symbol,API.H5Z_filter_t},Vector{Symbol}}()
)
const IMPLEMENTATIONS_LOCK = ReentrantLock()

"""
    FILTER_NAMES

Short names that may be used instead of a filter id in priority settings.
"""
const FILTER_NAMES = Dict{Symbol,API.H5Z_filter_t}(
    :bzip2 => 307, :blosc => 32001, :lz4 => 32004, :bitshuffle => 32008, :zstd => 32015,
)

"""
    filter_id(x)

Resolve a filter id, a filter type, a filter name from [`FILTER_NAMES`](@ref) (such as
`:zstd`), or a string containing an integer filter id to an `API.H5Z_filter_t`.
"""
filter_id(id::Integer) = API.H5Z_filter_t(id)
filter_id(::Type{F}) where {F<:Filter} = filterid(F)
filter_id(f::Filter) = filterid(f)
function filter_id(name::Union{Symbol,AbstractString})
    id = tryparse(Int, string(name))
    id === nothing || return API.H5Z_filter_t(id)
    key = Symbol(lowercase(string(name)))
    haskey(FILTER_NAMES, key) || throw(
        ArgumentError(
            "Unknown filter name $(repr(name)). Use a filter id or one of $(sort!(collect(keys(FILTER_NAMES))))."
        )
    )
    return FILTER_NAMES[key]
end

default_provider(::Type{F}) where {F<:Filter} = Symbol(parentmodule(F))

_symbols(x) = Symbol[Symbol(s) for s in x]

"""
    load_preferences!()

(Re)read the filter settings from Preferences.jl and re-select the implementation of
every filter id that has been registered. The recognized preferences of HDF5.jl are

- `filter_auto_register` (`Bool`, default `true`): If `false`, implementations are recorded
  when their package is loaded but nothing is registered with libhdf5 until
  [`activate!`](@ref) or [`activate_all!`](@ref) is called.
- `filter_disabled` (list of provider names): Providers that are never selected
  automatically, e.g. `["H5Zbzip2"]`.
- `filter_priority` (table): Maps a filter id, a name from [`FILTER_NAMES`](@ref), or
  `"default"` to a list of provider names in decreasing priority, e.g.
  `zstd = ["H5ZChunkCodecZstd", "H5Zzstd"]`. Use `"native"` to refer to a plugin found by
  libhdf5 on `HDF5_PLUGIN_PATH`.

Set them with, for example,
```julia
using Preferences, HDF5
set_preferences!(HDF5, "filter_priority" => Dict("zstd" => ["native", "H5Zzstd"]))
```
and restart Julia (or call `HDF5.Filters.load_preferences!()`).
"""
function load_preferences!()
    lock(IMPLEMENTATIONS_LOCK) do
        mod = parentmodule(@__MODULE__)
        auto = Preferences.load_preference(mod, "filter_auto_register", true)
        if auto isa Bool
            PREFERENCES.auto_register[] = auto
        else
            @warn "Ignoring HDF5 preference filter_auto_register; expected a Bool" auto
            PREFERENCES.auto_register[] = true
        end
        empty!(PREFERENCES.disabled)
        disabled = Preferences.load_preference(mod, "filter_disabled", String[])
        if disabled isa AbstractVector
            union!(PREFERENCES.disabled, _symbols(disabled))
        else
            @warn "Ignoring HDF5 preference filter_disabled; expected a list of provider names" disabled
        end
        empty!(PREFERENCES.priority)
        priority = Preferences.load_preference(mod, "filter_priority", Dict{String,Any}())
        if priority isa AbstractDict
            for (key, providers) in priority
                try
                    k = string(key) == "default" ? :default : filter_id(key)
                    PREFERENCES.priority[k] = _symbols(providers)
                catch err
                    @warn "Ignoring HDF5 preference filter_priority entry" key exception =
                        err
                end
            end
        else
            @warn "Ignoring HDF5 preference filter_priority; expected a table" priority
        end
        foreach(select_implementation!, collect(keys(IMPLEMENTATIONS)))
    end
    return nothing
end

"""
    priority(id) -> Vector{Symbol}

The configured provider priority for filter `id` (a filter id, type or name), highest first.
Priorities set with [`set_priority!`](@ref) take precedence over the `filter_priority`
preference, which has the filter's own entry take precedence over its `"default"` entry.
Providers that are not listed are tried afterwards in the order they were loaded.
"""
function priority(x)
    id = filter_id(x)
    haskey(RUNTIME_PRIORITY, id) && return RUNTIME_PRIORITY[id]
    haskey(PREFERENCES.priority, id) && return PREFERENCES.priority[id]
    return get(PREFERENCES.priority, :default, Symbol[])
end

"""
    set_priority!(id, providers...)

Prefer the implementations of the filter `id` (a filter id, type or name such as `:zstd`)
in the order given by `providers`, e.g. `set_priority!(:zstd, :H5ZChunkCodecZstd, :native)`,
and select the implementation accordingly. Use `:native` for plugins found by libhdf5
on `HDF5_PLUGIN_PATH`. This overrides the `filter_priority` preference until
[`reset_priority!`](@ref).
"""
function set_priority!(x, providers::Union{Symbol,AbstractString}...)
    id = filter_id(x)
    lock(IMPLEMENTATIONS_LOCK) do
        RUNTIME_PRIORITY[id] = _symbols(providers)
        select_implementation!(id; force=true)
    end
    return nothing
end

"""
    reset_priority!(id)

Remove the priority set by [`set_priority!`](@ref) for the filter `id`.
"""
function reset_priority!(x)
    id = filter_id(x)
    lock(IMPLEMENTATIONS_LOCK) do
        delete!(RUNTIME_PRIORITY, id)
        select_implementation!(id; force=true)
    end
    return nothing
end

"""
    implementations(id) -> Vector{Implementation}

The implementations of filter `id` (a filter id, type or name) that have been loaded,
in order of loading.
"""
implementations(x) =
    lock(IMPLEMENTATIONS_LOCK) do
        copy(get(IMPLEMENTATIONS, filter_id(x), Implementation[]))
    end

"""
    active_implementation(id) -> Union{Symbol,Nothing}

The provider whose implementation of filter `id` is registered with libhdf5, `:native`
if libhdf5 is using a plugin it loaded itself, or `nothing` if the Julia side has not
registered the filter.
"""
active_implementation(x) =
    lock(IMPLEMENTATIONS_LOCK) do
        get(ACTIVE, filter_id(x), nothing)
    end

# Find the implementation with the given provider
function _find(id, provider)
    for impl in get(IMPLEMENTATIONS, id, Implementation[])
        impl.provider == provider && return impl
    end
    return nothing
end

# Register the filter type with libhdf5 and record F as the filter type for its id.
# Filter types that need special registration may extend this method.
function register_with_hdf5(::Type{F}) where {F<:Filter}
    id = filterid(F)
    encoder = encoder_present(F)
    decoder = decoder_present(F)
    name = filtername(F)
    can_apply = can_apply_cfunc(F)
    set_local = set_local_cfunc(F)
    func = filter_cfunc(F)
    GC.@preserve name begin
        API.h5z_register(
            API.H5Z_class_t(
                API.H5Z_CLASS_T_VERS,
                id,
                encoder,
                decoder,
                pointer(name),
                can_apply,
                set_local,
                func
            )
        )
    end
    FILTERS[id] = F
    return nothing
end

# Make libhdf5 use the implementation `impl`. Returns true on success.
function _activate_julia!(id, impl::Implementation)
    # Skip if already registered, but trust libhdf5 over our records in case the filter
    # was unregistered behind our back, e.g. by calling `API.h5z_unregister` directly.
    get(ACTIVE, id, nothing) == impl.provider &&
        get(FILTERS, id, nothing) === impl.type &&
        API.h5z_filter_avail(id) &&
        return true
    register_with_hdf5(impl.type)
    ACTIVE[id] = impl.provider
    FILTERS[id] = impl.type
    return true
end

# Let libhdf5 find the filter itself. Returns true if a native plugin is available.
function _activate_native!(id)
    if get(ACTIVE, id, nothing) !== nothing && ACTIVE[id] !== NATIVE
        try
            API.h5z_unregister(id)
        catch err
            @debug "Could not unregister filter $id before looking for a native plugin" exception =
                err
            return false
        end
        delete!(ACTIVE, id)
    end
    if API.h5z_filter_avail(id)
        ACTIVE[id] = NATIVE
        return true
    end
    return false
end

"""
    select_implementation!(id; force=false)

Register the highest priority available implementation of filter `id` with libhdf5.
Nothing happens if `filter_auto_register` is `false`, unless `force=true`.
"""
function select_implementation!(x; force::Bool=false)
    id = filter_id(x)
    lock(IMPLEMENTATIONS_LOCK) do
        (force || PREFERENCES.auto_register[]) || return nothing
        impls = get(IMPLEMENTATIONS, id, Implementation[])
        isempty(impls) && return nothing
        listed = priority(id)
        candidates = Symbol[]
        for p in listed
            p in candidates || push!(candidates, p)
        end
        for impl in impls
            impl.provider in candidates || push!(candidates, impl.provider)
        end
        for provider in candidates
            provider in PREFERENCES.disabled && continue
            if provider === NATIVE
                _activate_native!(id) && return nothing
            else
                impl = _find(id, provider)
                impl === nothing && continue
                _activate_julia!(id, impl) && return nothing
            end
        end
        return nothing
    end
end

"""
    activate!(F::Type{<:Filter})
    activate!(id, provider)

Make the implementation `F`, or the implementation of filter `id` from `provider`, the one
that libhdf5 uses, regardless of priorities and of `filter_auto_register`. Use the provider
`:native` to use a plugin that libhdf5 finds on `HDF5_PLUGIN_PATH`. The choice holds until
the priorities change.
"""
function activate!(::Type{F}; provider::Symbol=default_provider(F)) where {F<:Filter}
    id = filterid(F)
    lock(IMPLEMENTATIONS_LOCK) do
        _record!(id, provider, F)
        activate!(id, provider)
    end
end
function activate!(x, provider::Union{Symbol,AbstractString})
    id = filter_id(x)
    provider = Symbol(provider)
    lock(IMPLEMENTATIONS_LOCK) do
        if provider === NATIVE
            _activate_native!(id) || error(
                "No native plugin for filter $id was found by libhdf5; check HDF5_PLUGIN_PATH."
            )
        else
            impl = _find(id, provider)
            impl === nothing && error(
                "No implementation of filter $id from $provider is loaded. Loaded: $(join(getproperty.(get(IMPLEMENTATIONS, id, Implementation[]), :provider), ", "))"
            )
            _activate_julia!(id, impl)
        end
        # Keep the choice stable, i.e. make it the first priority
        RUNTIME_PRIORITY[id] = Symbol[
            provider
            filter(!=(provider), get(RUNTIME_PRIORITY, id, priority(id)))
        ]
    end
    return nothing
end

"""
    activate_all!()

Select an implementation for every loaded filter, ignoring `filter_auto_register`.
Use this after loading packages when automatic registration is disabled.
"""
function activate_all!()
    lock(IMPLEMENTATIONS_LOCK) do
        for id in collect(keys(IMPLEMENTATIONS))
            select_implementation!(id; force=true)
        end
    end
    return nothing
end

function _record!(id, provider::Symbol, ::Type{F}) where {F<:Filter}
    impls = get!(IMPLEMENTATIONS, id) do
        Implementation[]
    end
    i = findfirst(impl -> impl.provider == provider, impls)
    if i === nothing
        push!(impls, Implementation(provider, F))
    else
        impls[i] = Implementation(provider, F)
    end
    return nothing
end

"""
    register_filter(::Type{F}; provider=Symbol(parentmodule(F))) where F <: Filter

Make the filter type `F` available as an implementation of its filter id and, unless a
higher priority implementation exists or automatic registration is disabled, register
it with the HDF5 library via [`API.h5z_register`](@ref). Also add `F` to the `FILTERS`
dictionary if it becomes the active implementation.

Filter packages call this from `__init__`. Several packages may implement the same
filter id; see [`set_priority!`](@ref) and [`load_preferences!`](@ref) for choosing which one
is used.
"""
function register_filter(::Type{F}; provider::Symbol=default_provider(F)) where {F<:Filter}
    id = filterid(F)
    lock(IMPLEMENTATIONS_LOCK) do
        _record!(id, provider, F)
        select_implementation!(id)
    end
    return nothing
end
