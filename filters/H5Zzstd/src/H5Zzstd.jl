"""
    H5Zzstd

Transitional package to HDF5/CodecZstdExt.

The contents of this package are now contained within the package extension
CodecZstdExt. Loading this package will load the package extension.
"""
module H5Zzstd

using HDF5: HDF5
using CodecZstd: CodecZstd
const CodecZstdExt = Base.get_extension(HDF5, :CodecZstdExt)

using .CodecZstdExt: H5Z_FILTER_ZSTD
using .CodecZstdExt: zstd_name

using .CodecZstdExt: H5Z_filter_zstd
using .CodecZstdExt: H5Z_FILTER_ZSTD
using .CodecZstdExt: ZstdFilter

export H5Z_filter_zstd, H5Z_FILTER_ZSTD, ZstdFilter

end # module H5Zzstd
