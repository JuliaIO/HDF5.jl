# H5ZChunkCodecZstd.jl

Implements the Zstandard filter (HDF5 filter id 32015) for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl)
using [ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl).

This is an alternative to `H5Zzstd`. Both can be loaded in the same session; HDF5.jl registers one
implementation per filter id with libhdf5. Choose with
`HDF5.Filters.set_priority!(:zstd, :H5ZChunkCodecZstd, :H5Zzstd)` or with the `filter_priority`
preference of HDF5.jl. See the HDF5.jl documentation on filters.
