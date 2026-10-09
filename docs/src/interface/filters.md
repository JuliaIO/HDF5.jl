# Filters

HDF5 supports filters for compression and validation: these are applied sequentially to
each chunk of a dataset when writing data, and in reverse order when reading data.

```@meta
CurrentModule = HDF5
```

These can be set by passing a filter or vector of filters as a `filters` property to
[`DatasetCreateProperties`](@ref) or via the `filters` keyword argument of [`create_dataset`](@ref).

```@meta
CurrentModule = HDF5.Filters
```

## Example

```@docs
Filters
```

## Built-in Filters


```@docs
Deflate
Shuffle
Fletcher32
Szip
NBit
ScaleOffset
ExternalFilter
```

## External Filter Packages

Several external Julia packages implement HDF5 filter plugins in Julia.
As they are independent of HDF5.jl, they must be installed in order to use their plugins.

The
[H5Zbitshuffle.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5Zbitshuffle),
[H5Zblosc.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5Zblosc),
[H5Zbzip2.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5Zbzip2),
[H5Zlz4.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5Zlz4), and
[H5Zzstd.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5Zzstd) packages are maintained as
independent subdirectory packages within the HDF5.jl repository.

### H5Zblosc.jl

```@meta
CurrentModule = H5Zblosc
```

```@docs
BloscFilter
```

### H5Zbzip2.jl

```@meta
CurrentModule = H5Zbzip2
```

```@docs
Bzip2Filter
```

### H5Zlz4.jl

```@meta
CurrentModule = H5Zlz4
```

```@docs
Lz4Filter
```

### H5Zzstd.jl

```@meta
CurrentModule = H5Zzstd
```

```@docs
ZstdFilter
```

### H5Zbitshuffle

```@meta
CurrentModule = H5Zbitshuffle
```

```@docs
BitshuffleFilter
H5Zbitshuffle
```

### H5ZChunkCodecZstd.jl and H5ZChunkCodecBzip2.jl

[H5ZChunkCodecZstd.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5ZChunkCodecZstd) and
[H5ZChunkCodecBzip2.jl](https://github.com/JuliaIO/HDF5.jl/tree/master/filters/H5ZChunkCodecBzip2) implement the
Zstandard and Bzip2 filters with [ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl). They are alternatives to
H5Zzstd.jl and H5Zbzip2.jl; see [Multiple implementations of a filter](@ref) below.

```@meta
CurrentModule = H5ZChunkCodecZstd
```

```@docs
ChunkCodecZstdFilter
H5ZChunkCodecZstd
```

```@meta
CurrentModule = H5ZChunkCodecBzip2
```

```@docs
ChunkCodecBzip2Filter
H5ZChunkCodecBzip2
```

## Multiple implementations of a filter

```@meta
CurrentModule = HDF5.Filters
```

libhdf5 holds a single function for each filter id, but a filter id may be implemented in several ways:
by different Julia packages (for example H5Zzstd.jl, which uses CodecZstd.jl, and H5ZChunkCodecZstd.jl, which uses
ChunkCodecs.jl) or by a native plugin that libhdf5 loads itself from the `HDF5_PLUGIN_PATH`
(for example plugins built from [hdf5_plugins](https://github.com/HDFGroup/hdf5_plugins) or distributed with NetCDF).
All of these implementations can be loaded together. HDF5.jl keeps track of each implementation (a *provider*, named
after its package, e.g. `:H5Zzstd`, or `:native`) and registers the one with the highest priority with libhdf5.
The data written is the same regardless of which implementation runs, so files remain interchangeable.

By default, the implementation that was loaded first is used. A filter type such as `ZstdFilter` only describes the
parameters of the filter; the implementation that runs is whichever is currently active for the filter id.

```julia
using HDF5, H5Zzstd, H5ZChunkCodecZstd
using HDF5.Filters

Filters.implementations(:zstd)       # H5Zzstd and H5ZChunkCodecZstd
Filters.active_implementation(:zstd) # :H5Zzstd
Filters.set_priority!(:zstd, :H5ZChunkCodecZstd, :H5Zzstd)
Filters.active_implementation(:zstd) # :H5ZChunkCodecZstd
Filters.set_priority!(:zstd, :native, :H5ZChunkCodecZstd) # prefer a plugin on HDF5_PLUGIN_PATH, if there is one
```

Filters can be referred to by id, by filter type, or by a name: `:bzip2`, `:blosc`, `:lz4`, `:bitshuffle`, or `:zstd`.
A provider that is listed but unavailable is skipped, so a priority list may end with a fallback.
Providers that are not listed are used after the listed ones, in the order they were loaded.

### Configuration with Preferences.jl

The priorities can be set persistently with [Preferences.jl](https://github.com/JuliaPackaging/Preferences.jl)
in the `LocalPreferences.toml` of the active project:

```toml
[HDF5]
# Which implementation to use, highest priority first. Keys are filter ids or names,
# "default" applies to every filter without its own entry.
filter_priority = { zstd = ["H5ZChunkCodecZstd", "H5Zzstd"], "32001" = ["native", "H5Zblosc"] }
# Providers that are never selected automatically
filter_disabled = ["H5Zbzip2"]
# Set to false to stop packages from registering their filters with libhdf5 when they are loaded.
# Nothing is registered until `Filters.activate_all!()` or `Filters.activate!` is called.
filter_auto_register = false
```

The same can be done from Julia with `Preferences.set_preferences!(HDF5, "filter_priority" => Dict("zstd" => ["H5ZChunkCodecZstd"]))`.
The preferences are read when HDF5.jl is loaded; `Filters.load_preferences!()` reads them again.
Priorities set with `Filters.set_priority!` or `Filters.activate!` take precedence over the preferences.

### Writing a filter package

A filter package defines a subtype of [`Filter`](@ref) and calls [`register_filter`](@ref) from its `__init__`.
This records the filter as an implementation, with the name of the package defining the type as its provider, and registers it
with libhdf5 unless another implementation takes priority. Use the `provider` keyword to choose another name.

```@docs
implementations
active_implementation
priority
set_priority!
reset_priority!
activate!
activate_all!
select_implementation!
load_preferences!
filter_id
FILTER_NAMES
NATIVE
Implementation
```

## Other External Filters

Additional filters can be dynamically loaded by the HDF5 library. See [External Links](@ref) below for more information.

### Using an ExternalFilter

```@meta
CurrentModule = HDF5.Filters
```

[`ExternalFilter`](@ref) can be used to insert a dynamically loaded filter into the [`FilterPipeline`](@ref) in an ad-hoc fashion.

#### Example for `bitshuffle`

If we do not have a defined subtype of [`Filter`](@ref) for the [bitshuffle filter](https://github.com/kiyo-masui/bitshuffle/blob/master/src/bshuf_h5filter.h)
we can create an `ExternalFilter`. From the header file or list of registered plugins, we see that the bitshuffle filter has an id of `32008`.

Furthermore, the header describes two options:
1. `block_size` (optional). Default is `0`.
2. `compression` - This can be `0` or `BSHUF_H5_COMPRESS_LZ4` (`2` as defined in the C header)

```julia
using HDF5.Filters

bitshuf = ExternalFilter(32008, Cuint[0, 0])
bitshuf_comp = ExternalFilter(32008, Cuint[0, 2])

data_A = rand(0:31, 1024)
data_B = rand(32:63, 1024)

filename, _ = mktemp()
h5open(filename, "w") do h5f
    # Indexing style
    h5f["ex_data_A", chunk=(32,), filters=bitshuf] = data_A
    # Procedural style
    d, dt = create_dataset(h5f, "ex_data_B", data_B, chunk=(32,), filters=[bitshuf_comp])
    write(d, data_B)
end
```

### Registered Filter Helpers

The HDF Group maintains a list of registered filters which have been assigned a filter ID number.
The module [`Filters.Registered`](@ref) contains information about registered filters including functions
to create an `ExternalFilter` for each registered filter.

### Creating a new Filter type

Examining the [bitshuffle filter source code](https://github.com/kiyo-masui/bitshuffle/blob/0aee87e142c71407aa097c660727f2621c71c493/src/bshuf_h5filter.c#L47-L64) we see that three additional data components get prepended to the options. These are
1. The major version
2. The minor version
3. The element size in bytes of the type via `H5Tget_size`.

```julia
import HDF5.Filters: FILTERS, Filter, FilterPipeline, filterid
using HDF5.API

const H5Z_BSHUF_ID = API.H5Z_filter_t(32008)
struct BitShuffleFilter <: HDF5.Filters.Filter
    major::Cuint
    minor::Cuint
    elem_size::Cuint
    block_size::Cuint
    compression::Cuint
    BitShuffleFilter(block_size, compression) = new(0, 0, 0, block_size, compression)
end
# filterid is the only required method of the filter interface
# since we are using an externally registered filter
filterid(::Type{BitShuffleFilter}) = H5Z_BSHUF_ID
FILTERS[H5Z_BSHUF_ID] = BitShuffleFilter

function Base.push!(p::FilterPipeline, f::BitShuffleFilter)
    ref = Ref(f)
    GC.@preserve ref begin
        API.h5p_set_filter(p.plist, H5Z_BSHUF_ID, API.H5Z_FLAG_OPTIONAL, 2, pointer_from_objref(ref) + sizeof(Cuint)*3)
    end
    return p
end
```

Because the first three elements are not provided directly via `h5p_set_filter`, we also needed to implement a custom `Base.push!` into the `FilterPipeline`.

## Filter Interface

```@meta
CurrentModule = HDF5.Filters
```

The filter interface is used to describe filters and obtain information on them.

```@docs
Filter
FilterPipeline
UnknownFilter
FILTERS
EXTERNAL_FILTER_JULIA_PACKAGES
filterid
isavailable
isdecoderenabled
isencoderenabled
decoder_present
encoder_present
ensure_filters_available
filtername
can_apply_func
can_apply_cfunc
set_local_func
set_local_cfunc
filter_func
filter_cfunc
register_filter
```

## Registered Filters

```@autodocs
Modules = [Registered]
```

## External Links

* A [list of registered filter plugins](https://github.com/HDFGroup/hdf5_plugins/blob/master/docs/RegisteredFilterPlugins.md) can be found on the HDF Group website.
* [See the HDF5 Documentation of HDF5 Filter Plugins for details.](https://support.hdfgroup.org/documentation/hdf5/latest/_h5_p_l__u_g.html#sec_filter_plugins)
* The source code for many external plugins have been collected in the [HDFGroup hdf5_plugins repository](https://github.com/HDFGroup/hdf5_plugins).
* [Compiled binaries of dynamically downloaded plugins](https://github.com/HDFGroup/hdf5_plugins/releases) by downloaded from HDF5 Group.
