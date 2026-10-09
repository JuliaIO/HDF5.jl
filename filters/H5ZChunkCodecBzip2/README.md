# H5ZChunkCodecBzip2.jl

Implements the Bzip2 filter (HDF5 filter id 307) for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl)
using [ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl).

This is an alternative to `H5Zbzip2`. Both can be loaded in the same session; HDF5.jl registers one
implementation per filter id with libhdf5. Choose with
`HDF5.Filters.set_priority!(:bzip2, :H5ZChunkCodecBzip2, :H5Zbzip2)` or with the `filter_priority`
preference of HDF5.jl. See the HDF5.jl documentation on filters.
