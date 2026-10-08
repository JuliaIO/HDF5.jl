# bitshuffle_jll_ext

Implements the bitshuffle filter for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl) in Julia,
with optional integrated lz4 and zstd (de)compression.

This implements [HDF5 filter ID 32008](https://github.com/HDFGroup/hdf5_plugins/blob/master/docs/RegisteredFilterPlugins.md#bitshuffle)
