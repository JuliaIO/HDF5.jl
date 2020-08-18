## v0.14

* Properties are now set using keyword arguments instead of by pairs of string and value positional arguments.
  For example `dset = d_create(h5f, "A", datatype(Int64), dataspace(10,10), "chunk", (3,3))` is now written as
  `dset = d_create(h5f, "A", datatype(Int64), dataspace(10,10), chunk=(3,3))`. Additionally the key type used for
  directly setting `HDF5Properties` objects has changed from a `String` to a `Symbol`, e.g.
  `apl["fclose_degree"] = H5F_CLOSE_STRONG` is now written as `apl[:fclose_degree] = H5F_CLOSE_STRONG` ([#632](https://github.com/JuliaIO/HDF5.jl/pull/632)).
