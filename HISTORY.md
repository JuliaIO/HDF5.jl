# HISTORY

Please also see the [release notes](https://github.com/JuliaIO/HDF5.jl/releases) for additional details.

## v0.16.8

* Fix issue related to seg fault when loading with MPI
* Add `create_dataset` convenience forms for dataspace
* Add `meta_block_size` property to H5P and add additional H5P coverage
* Add fapl and fcpl as keywords for h5open

## v0.16.7

* Fix issue related to serial driver loading when MPI is called

## v0.16.6

* Add filespace management API calls

## v0.16.5

* Core driver API support
* Addition of `fill_time` and `fill_value` dataset properties
* Add type order precision API methods

## v0.16.4

* Anonymous dataset support
* Allow property lists to be passed into `create_dataset`

## v0.16.3

* `track_order` support in `write` and `read`, integration with FileIO and `OrderedDict`'s automatic detection
* `ExternalFilter` addition as the public interface and new documentation 
* External dataset support

## v0.16.2

* Minimum Blosc.jl version has been updated
* Support for the  BITSHUFFLE option with the Blosc filter

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
