# Properties

```@meta
CurrentModule = HDF5
```

HDF5 property lists are collections of name-value pairs which can be passed to other HDF5
functions to control features that are typically unimportant or whose default values are
usually used. In HDF5.jl, these options are typically handled by keyword arguments to such
functions, which will internally create the appropriate `Properties` objects, and
so users will not usually be required to construct them manually.

Not all properties defined by the HDF5 library are currently available in HDF5.jl. If you
require additional properties, please open an issue or pull request.

## Common functions

```@docs
setproperties!
```

## `Properties` types

```@docs
AttributeCreateProperties
FileAccessProperties
FileCreateProperties
GroupAccessProperties
GroupCreateProperties
DatasetCreateProperties
DatasetAccessProperties
DatatypeAccessProperties
DatasetTransferProperties
LinkCreateProperties
ObjectCreateProperties
StringCreateProperties
DatatypeCreateProperties
```

## Virtual Datasets

```@docs
VirtualMapping
VirtualLayout
```

## Drivers

```@meta
CurrentModule = HDF5
```

File drivers determine how the HDF5 is accessed. These can be set as the `driver` property in [`FileAccessProperties`](@ref).

```@meta
CurrentModule = HDF5.Drivers
```

```@docs
Core
POSIX
ROS3
MPIO
```

## Internals

```@meta
CurrentModule = HDF5
```

The following macros are used for defining new properties and property getters/setters.

```@docs
@propertyclass
@bool_property
@enum_property
@tuple_property
```