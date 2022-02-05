# Filters

HDF5 supports filters for compression and validation: these are applied sequentially to
each chunk of a dataset when writing data, and in reverse order when reading data.

```@meta
CurrentModule = HDF5
```

These can be set by passing a filter or vector of filters as a `filters` property to
[`DatasetCreateProperties`](@ref).

## Filter Interface

```@meta
CurrentModule = HDF5.Filters
```

The filter interface is used to describe filters and obtain information on them.

```@docs
Filters
Filter
FilterPipeline
UnknownFilter
FILTERS
filterid
encoder_present
decoder_present
filtername
can_apply_func
can_apply_cfunc
set_local_func
set_local_cfunc
filter_func
filter_cfunc
register_filter
```

## Built-in Filters


```@docs
Deflate
Shuffle
Fletcher32
Szip
NBit
ScaleOffset
```

## External Filter Packages

Several external Julia packages implement HDF5 filter plugins in Julia.
As they are independent of HDF5.jl, they must be installed in order to use their plugins.

The
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

## Other External Filters

Additional filters can be dynamically loaded by the HDF5 library. See the links below for more information.

### External Links

* A [list of registered filter plugins](https://portal.hdfgroup.org/display/support/Registered+Filter+Plugins) can be found on the HDF Group website.
* [See the HDF5 Documentation of HDF5 Filter Plugins for details.](https://portal.hdfgroup.org/display/support/HDF5+Filter+Plugins)
* The source code for many external plugins have been collected in the [HDFGroup hdf5_plugins repository](https://github.com/HDFGroup/hdf5_plugins).