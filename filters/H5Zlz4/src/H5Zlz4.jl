#=
Copyright (c) 2021 Mark Kittisopikul and Howard Hughes Medical Institute. License MIT, see LICENSE.txt
=#
module H5Zlz4

using CodecLz4
using HDF5: HDF5
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export H5Z_FILTER_LZ4, H5Z_filter_lz4, Lz4Filter

const CodecLz4Ext = Base.get_extension(HDF5, :CodecLz4Ext)

const H5Z_filter_lz4 = CodecLz4Ext.H5Z_filter_lz4
const Lz4Filter = CodecLz4Ext.Lz4Filter

const H5Z_FILTER_LZ4 = CodecLz4Ext.H5Z_FILTER_LZ4

const DEFAULT_BLOCK_SIZE = CodecLz4Ext.DEFAULT_BLOCK_SIZE
const lz4_name = CodecLz4Ext.lz4_name

const LZ4_AGGRESSION = CodecLz4Ext.LZ4_AGGRESSION

end
