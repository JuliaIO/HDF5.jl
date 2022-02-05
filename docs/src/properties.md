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

## `Properties` types

```@docs
AttributeCreateProperties
FileAccessProperties
FileCreateProperties
GroupCreateProperties
DatasetCreateProperties
DatasetAccessProperties
DatasetTransferProperties
LinkCreateProperties
ObjectCreateProperties
StringCreateProperties
DatatypeCreateProperties
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
POSIX
MPIO
```