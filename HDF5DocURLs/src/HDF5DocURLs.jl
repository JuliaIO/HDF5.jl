module HDF5DocURLs

export func_url, group_url

"""
    DEFAULT_URL

Fallback documentation URL prefix returned by [`func_url`](@ref)/[`group_url`](@ref)
when a name is not found in this package's bundled data (e.g. a C function or
module added to `libhdf5` after this package's `hdf5.tag` snapshot was taken).
"""
const DEFAULT_URL = "https://support.hdfgroup.org/documentation/hdf5/latest/"

const _DATA_DIR = joinpath(dirname(@__DIR__), "data")
const _FUNC_URLS_PATH = joinpath(_DATA_DIR, "hdf5_func_urls.tsv")
const _GROUP_URLS_PATH = joinpath(_DATA_DIR, "hdf5_group_urls.tsv")

Base.include_dependency(_FUNC_URLS_PATH)
Base.include_dependency(_GROUP_URLS_PATH)

function _load_tsv(path::AbstractString)
    d = Dict{String,String}()
    for line in eachline(path)
        isempty(line) && continue
        k, v = split(line, '\t'; limit=2)
        d[k] = v
    end
    return d
end

"""
    FUNC_URLS::Dict{String,String}

Mapping from HDF5 C API function name (e.g. `"H5Fopen"`) to its documentation
URL, loaded once from the bundled `data/hdf5_func_urls.tsv` when this module
is loaded/precompiled.
"""
const FUNC_URLS = _load_tsv(_FUNC_URLS_PATH)

"""
    GROUP_URLS::Dict{String,String}

Mapping from HDF5 C API module/group name (e.g. `"H5F"`) to its documentation
URL, loaded once from the bundled `data/hdf5_group_urls.tsv` when this module
is loaded/precompiled.
"""
const GROUP_URLS = _load_tsv(_GROUP_URLS_PATH)

"""
    func_url(cfuncname::AbstractString; default::AbstractString=DEFAULT_URL) -> String

Documentation URL for the HDF5 C API function named `cfuncname` (e.g.
`"H5Fopen"`), as of the `hdf5.tag` snapshot vendored in this version of
HDF5DocURLs. Returns `default` if `cfuncname` is not found.
"""
func_url(cfuncname::AbstractString; default::AbstractString=DEFAULT_URL) =
    get(FUNC_URLS, String(cfuncname), default)

"""
    group_url(groupname::AbstractString; default::AbstractString=DEFAULT_URL) -> String

Documentation URL for an HDF5 C API module/group (e.g. `"H5F"`), as of the
`hdf5.tag` snapshot vendored in this version of HDF5DocURLs. Returns `default`
if `groupname` is not found.
"""
group_url(groupname::AbstractString; default::AbstractString=DEFAULT_URL) =
    get(GROUP_URLS, String(groupname), default)

end
