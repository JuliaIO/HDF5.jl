# H5Zchunkcodecs.jl

Implements the Zstandard (filter id 32015) and Bzip2 (filter id 307) filters for
[HDF5.jl](https://github.com/JuliaIO/HDF5.jl) using
[ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl).

These are alternatives to `H5Zzstd` and `H5Zbzip2`. Both can be loaded in the same session;
HDF5.jl registers one implementation per filter id with libhdf5. Choose with
`HDF5.Filters.set_priority!(:zstd, :H5Zchunkcodecs, :H5Zzstd)` or with the `filter_priority`
preference of HDF5.jl. See the HDF5.jl documentation on filters.
