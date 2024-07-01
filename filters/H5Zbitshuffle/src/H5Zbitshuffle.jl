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
# The next block of lines can be removed
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

using .bitshuffle_jll_ext: BSHUF_H5_COMPRESS_LZ4
using .bitshuffle_jll_ext: BSHUF_H5_COMPRESS_ZSTD
using .bitshuffle_jll_ext: BitshuffleFilter
using .bitshuffle_jll_ext: H5Z_filter_bitshuffle

using .bitshuffle_jll_ext: BSHUF_H5_COMPRESS_LZ4
using .bitshuffle_jll_ext: BSHUF_H5_COMPRESS_ZSTD
using .bitshuffle_jll_ext: H5Z_FILTER_BITSHUFFLE

using .bitshuffle_jll_ext: BSHUF_VERSION_MAJOR
using .bitshuffle_jll_ext: BSHUF_VERSION_MINOR
using .bitshuffle_jll_ext: BSHUF_VERSION_POINT

using .bitshuffle_jll_ext: bitshuffle_name

end # module
