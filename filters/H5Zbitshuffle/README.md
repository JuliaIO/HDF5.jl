# H5Zbitshuffle.jl

Implements the bitshuffle filter for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl) in Julia,
with optional integrated lz4 and zstd (de)compression.

This implements [HDF5 filter ID 32008](https://portal.hdfgroup.org/display/support/Filters#Filters-32008)
