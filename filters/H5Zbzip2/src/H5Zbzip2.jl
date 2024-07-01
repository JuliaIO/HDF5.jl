#=
Copyright (c) 2021 Mark Kittisopikul and Howard Hughes Medical Institute. License MIT, see LICENSE.txt
=#
module H5Zbzip2

using CodecBzip2: libbzip2
using HDF5: HDF5

# Remove the next three lines in the future
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export H5Z_FILTER_BZIP2, H5Z_filter_bzip2, Bzip2Filter

const CodecBzip2Ext = Base.get_extension(HDF5, :CodecBzip2Ext)

using .CodecBzip2Ext: H5Z_FILTER_BZIP2
using .CodecBzip2Ext: H5Z_filter_bzip2
using .CodecBzip2Ext: Bzip2Filter
using .CodecBzip2Ext: bzip2_name

end # module H5Zbzip2
