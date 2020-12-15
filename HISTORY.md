## v0.14.2

* We no longer ship binaries for Linux on i686 and armv7 for the v1.12 release of HDF5_jll.

## v0.14

### Breaking Changes

* The following functions have been unexported and do not have an automatic deprecation warning. Please use the `HDF5` module prefix to call these functions:
  - `file`
  - `filename`
  - `name`
  - `get_chunk`
  - `get_datasets`
  - `iscontiguous`
  - `ishdf5`
  - `ismmappable`
  - `root`
  - `readmmap`
  - `set_dims!`
  - `get_access_properties`
  - `get_create_properties`
  - `create_external_dataset`

* Properties are now set using keyword arguments instead of by pairs of string and value positional arguments.
  For example `dset = d_create(h5f, "A", datatype(Int64), dataspace(10,10), "chunk", (3,3))` is now written as
  `dset = d_create(h5f, "A", datatype(Int64), dataspace(10,10), chunk=(3,3))`. Additionally the key type used for
  directly setting `HDF5Properties` objects has changed from a `String` to a `Symbol`, e.g.
  `apl["fclose_degree"] = H5F_CLOSE_STRONG` is now written as `apl[:fclose_degree] = H5F_CLOSE_STRONG` ([#632](https://github.com/JuliaIO/HDF5.jl/pull/632)).
