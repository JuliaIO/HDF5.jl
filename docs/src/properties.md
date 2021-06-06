# Properties

```@meta
CurrentModule = HDF5
```

HDF5 property lists are collections of name-value pairs which can be passed to other HDF5
functions to control features that are typically unimportant or whose default values are
usually used. In HDF5.jl, these options are typically handled by keyword arguments to such
functions, which will internally create the appropriate [`Properties`](@ref) objects, and
so users will not usually be required to construct them manually.

Not all properties defined by the HDF5 library are currently available in HDF5.jl. If you
require additional properties, please open an issue or pull request.

## `Properties` types

```@docs
Properties
AttributeCreateProperties
FileAccessProperties
FileCreateProperties
GroupCreateProperties
DatasetCreateProperties
DatasetTransferProperties
LinkCreateProperties
ObjectCreateProperties
```

## Filters

HDF5 supports filters for compression and validation: these are applied sequentially to
each chunk of a dataset when writing data, and in reverse order when reading data.

These can be set by passing a filter or vector of filters as a `filter` property to
[`DatasetCreateProperties`](@ref).

```@meta
CurrentModule = HDF5.Filters
```

```@docs
FilterPipeline
Deflate
Shuffle
Fletcher32
Szip
NBit
ScaleOffset
BloscFilter
```

## Drivers

File drivers determine how the HDF5 is accessed. These can be set as the `driver` property in [`FileAccessProperties`](@ref).

```@meta
CurrentModule = HDF5.Drivers
```

```@docs
POSIX
MPIO
```