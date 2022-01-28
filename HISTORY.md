# HISTORY

Please also see the [release notes](https://github.com/JuliaIO/HDF5.jl/releases) for additional details.

## v0.16.1

* Minor bug fix to the test suite to ensure package tests pass

## v0.16.0

* Adds HDF5 support for ARM M1
* Revamped filter interface with the flexiblility to allow specification of a filter pipeline and external filter hooks
* New filter compression methods defined by external packaged: `H5Zblosc`, `H5Zlz4`, `H5Zbzip2`, `H5Zzstd`
* `filter` property name renamed to `filters`
* Generalized chunking API to accept `AbstractArray`
- New `move_link` method, which effectively renames an object
- Revamed internal `Properties` interface (non-user facing)

## v0.15.6

* Add `FileIO` integration

## v0.15.5

* Add the ability to use `attributes` for HDF5 datatypes

## v0.15.4

* Minor imporovement to an internal `ccall` wrapper

## v0.15.3

* Additional documentation on row/column ordering differences
* Improve iteration in order to support certain architectures, where the existing callbacks were failing.

## v0.15.2

* Fix `show` for `Attribute` printing

## v0.15.1

* Fix build system settings when using system provided HDF5 binaries

## v0.15.0

* Support reading of opaque data recursively
* Add support for a subset of libhdf5 table methods
* Improved error handling
* Improved `show` method printing heuristics
* Improved iteration protocol performance through the use of callbacks

## v0.14.2

* Fix performance of reading long strings
* Add additional `Dataspace` methods

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
