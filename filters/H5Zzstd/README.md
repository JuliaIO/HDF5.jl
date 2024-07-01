# H5Zzstd.jl

Implements the Zstd filter for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl) in Julia.
See the [documentation](https://juliaio.github.io/HDF5.jl/stable/filters/#H5Zzstd.jl)

This implements [HDF5 ZStandard Filter 32015](https://portal.hdfgroup.org/display/support/Filters#Filters-32015)

This is a transitional package as the contents of this package are now
implemented by `CodecZstdExt`, an extension package to HDF5 that loads
when CodecZstd.jl is loaded.

Loading this package will trigger loading of the extension since this
package loads both HDF5.jl and CodecZstd.jl.
