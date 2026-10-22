# H5ZzstdC.jl

Registers the native C implementation of the Zstandard filter (HDF5 filter id 32015) from
[H5ZzstdC_jll](https://github.com/JuliaBinaryWrappers/H5ZzstdC_jll.jl) with
[HDF5.jl](https://github.com/JuliaIO/HDF5.jl), like the other filter packages.

This is an alternative to `H5Zzstd`, which implements the filter in Julia. Both can be loaded in the same
session; HDF5.jl registers one implementation per filter id with libhdf5. Choose with
`HDF5.Filters.set_priority!(:zstd, :H5ZzstdC, :H5Zzstd)` or with the `filter_priority` preference of HDF5.jl.
See the HDF5.jl documentation on filters.

The plugin in H5ZzstdC_jll is built against a specific HDF5_jll, so this package can only be installed with it.
