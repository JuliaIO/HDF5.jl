#==
Most of the code has been moved into 
==#
"""
The bitshuffle filter for HDF5. See https://portal.hdfgroup.org/display/support/Filters#Filters-32008
and https://github.com/kiyo-masui/bitshuffle for details.
"""
module H5Zbitshuffle

using bitshuffle_jll

using HDF5: HDF5
using HDF5.API
import HDF5.Filters:
    Filter,
    filterid,
    register_filter,
    filtername,
    filter_func,
    filter_cfunc,
    set_local_func,
    set_local_cfunc

export BSHUF_H5_COMPRESS_LZ4,
    BSHUF_H5_COMPRESS_ZSTD, BitshuffleFilter, H5Z_filter_bitshuffle

const bitshuffle_jll_ext = Base.get_extension(HDF5, :bitshuffle_jll_ext)

const BSHUF_H5_COMPRESS_LZ4 = bitshuffle_jll_ext.BSHUF_H5_COMPRESS_LZ4
const BSHUF_H5_COMPRESS_ZSTD = bitshuffle_jll_ext.BSHUF_H5_COMPRESS_ZSTD
const BitshuffleFilter = bitshuffle_jll_ext.BitshuffleFilter
const H5Z_filter_bitshuffle = bitshuffle_jll_ext.H5Z_filter_bitshuffle

const BSHUF_H5_COMPRESS_LZ4 = bitshuffle_jll_ext.BSHUF_H5_COMPRESS_LZ4
const BSHUF_H5_COMPRESS_ZSTD = bitshuffle_jll_ext.BSHUF_H5_COMPRESS_ZSTD
const H5Z_FILTER_BITSHUFFLE = bitshuffle_jll_ext.H5Z_FILTER_BITSHUFFLE

const BSHUF_VERSION_MAJOR = bitshuffle_jll_ext.BSHUF_VERSION_MAJOR
const BSHUF_VERSION_MINOR = bitshuffle_jll_ext.BSHUF_VERSION_MINOR
const BSHUF_VERSION_POINT = bitshuffle_jll_ext.BSHUF_VERSION_POINT

const bitshuffle_name = bitshuffle_jll_ext.bitshuffle_name

end # module
