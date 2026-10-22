"""
    H5ZzstdC

The Zstandard HDF5 filter (id 32015) implemented by the native C plugin that
[H5ZzstdC_jll](https://github.com/JuliaBinaryWrappers/H5ZzstdC_jll.jl) packages.

This is an alternative to `H5Zzstd`, which implements the filter in Julia. The data written is
compatible with that package, and both can be loaded at the same time; see
[`HDF5.Filters.set_priority!`](@ref) and the `filter_priority` preference of HDF5.jl for
choosing which one libhdf5 uses. The provider name of this package is `:H5ZzstdC`.

Unlike a plugin that libhdf5 finds on `HDF5_PLUGIN_PATH` (the `:native` provider), this package
registers the filter of the C plugin with libhdf5 itself, so it takes part in the priorities
like the other filter packages and does not need a search path. Since the plugin is built
against a specific `HDF5_jll`, this package can only be installed with that version.
"""
module H5ZzstdC

using H5ZzstdC_jll: H5ZzstdC_jll
using Libdl: Libdl
using HDF5.API
import HDF5.Filters: Filter, filterid, filtername, register_filter, register_with_hdf5

export ZstdCFilter

const H5Z_FILTER_ZSTD = API.H5Z_filter_t(32015)
const zstd_name = "Zstandard compression: http://www.zstd.net"

"""
    plugin_path() -> String

Path of the native Zstandard plugin library.
"""
plugin_path() = H5ZzstdC_jll.libh5zstd_path

# Read the filter class that the plugin exports to libhdf5 for its dynamic loading.
# See `H5PLget_plugin_info` in the HDF5 documentation of plugins.
function plugin_class()::API.H5Z_class_t
    sym = Libdl.dlsym(H5ZzstdC_jll.libh5zstd_handle, :H5PLget_plugin_info)
    info = ccall(sym, Ptr{Cvoid}, ())
    info == C_NULL && error("H5ZzstdC: the plugin did not provide a filter class")
    return unsafe_load(Ptr{API.H5Z_class_t}(info))
end

"""
    ZstdCFilter(clevel)

Zstandard compression filter (filter id 32015) implemented by a native C plugin.
Uses the same `cd_values` as `H5Zzstd.ZstdFilter`, so data is interchangeable.
`clevel` is the compression level; negative levels are faster at the cost of compression.
"""
struct ZstdCFilter <: Filter
    clevel::Cuint
    ZstdCFilter(clevel::Integer) = new(clevel % Cuint)
end
ZstdCFilter() = ZstdCFilter(3)
Base.show(io::IO, f::ZstdCFilter) = print(io, "ZstdCFilter(", f.clevel % Cint, ")")

filterid(::Type{ZstdCFilter}) = H5Z_FILTER_ZSTD
filtername(::Type{ZstdCFilter}) = zstd_name

# The functions of the filter are in the C plugin; register its class as is.
register_with_hdf5(::Type{ZstdCFilter}) = API.h5z_register(Ref(plugin_class()))

function __init__()
    register_filter(ZstdCFilter)
end

end # module H5ZzstdC
