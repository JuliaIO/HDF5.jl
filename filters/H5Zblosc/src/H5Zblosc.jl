module H5Zblosc
# port of https://github.com/Blosc/c-blosc/blob/3a668dcc9f61ad22b5c0a0ab45fe8dad387277fd/hdf5/blosc_filter.c (copyright 2010 Francesc Alted, license: MIT/expat)

import Blosc
using HDF5: HDF5

# The next block of lines can be removed
using HDF5.API
import HDF5.Filters: Filter, FilterPipeline
import HDF5.Filters:
    filterid,
    register_filter,
    filtername,
    filter_func,
    filter_cfunc,
    set_local_func,
    set_local_cfunc
import HDF5.Filters.Shuffle

export H5Z_FILTER_BLOSC, blosc_filter, BloscFilter

# Import Blosc shuffle constants
import Blosc: NOSHUFFLE, SHUFFLE, BITSHUFFLE

const BloscExt = Base.get_extension(HDF5, :BloscExt)

using .BloscExt: blosc_filter
using .BloscExt: BloscFilter

using .BloscExt: H5Z_FILTER_BLOSC
using .BloscExt: FILTER_BLOSC_VERSION
using .BloscExt: blosc_name

end # module H5Zblosc
