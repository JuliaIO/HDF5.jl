#=
Copyright (c) 2021 Mark Kittisopikul and Howard Hughes Medical Institute. License MIT, see LICENSE.txt
=#
module H5Zlz4

using CodecLz4
using HDF5: HDF5

# The next three lines can be removed
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export H5Z_FILTER_LZ4, H5Z_filter_lz4, Lz4Filter

const CodecLz4Ext = Base.get_extension(HDF5, :CodecLz4Ext)

using .CodecLz4Ext: H5Z_filter_lz4
using .CodecLz4Ext: Lz4Filter

using .CodecLz4Ext: H5Z_FILTER_LZ4

using .CodecLz4Ext: DEFAULT_BLOCK_SIZE
using .CodecLz4Ext: lz4_name

using .CodecLz4Ext: LZ4_AGGRESSION

end
