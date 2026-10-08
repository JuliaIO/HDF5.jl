module HDF5DocURLs

export func_url, group_url, anchor_url, filter_url, filter_name, external_url

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
const _ANCHOR_URLS_PATH = joinpath(_DATA_DIR, "hdf5_anchor_urls.tsv")
const _FILTER_URLS_PATH = joinpath(_DATA_DIR, "hdf5_filter_urls.tsv")

Base.include_dependency(_FUNC_URLS_PATH)
Base.include_dependency(_GROUP_URLS_PATH)
Base.include_dependency(_ANCHOR_URLS_PATH)
Base.include_dependency(_FILTER_URLS_PATH)

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

"""
    ANCHOR_URLS::Dict{String,String}

Mapping from a Doxygen section anchor id (e.g. `"subsec_dataspace_select"`) to the
URL of that section, loaded once from the bundled `data/hdf5_anchor_urls.tsv`.
"""
const ANCHOR_URLS = _load_tsv(_ANCHOR_URLS_PATH)

"""
    anchor_url(anchor::AbstractString; default::AbstractString=DEFAULT_URL) -> String

Documentation URL for the section of an HDF5 documentation page identified by the
Doxygen anchor id `anchor` (e.g. `"subsec_dataspace_select"`). Returns `default` if
`anchor` is not found. For a whole page, e.g. `"IntroParHDF5"` or `"SWMRTN"`, use
[`group_url`](@ref), which also resolves Doxygen page names.
"""
anchor_url(anchor::AbstractString; default::AbstractString=DEFAULT_URL) =
    get(ANCHOR_URLS, String(anchor), default)

"""
    REGISTRY_URL

URL of The HDF Group's list of registered filter plugins.
"""
const REGISTRY_URL = "https://github.com/HDFGroup/hdf5_plugins/blob/master/docs/RegisteredFilterPlugins.md"

# Filters built into libhdf5 are documented with their `H5Pset_*` functions
const _BUILTIN_FILTERS = Dict{Int,Tuple{String,String}}(
    1 => ("deflate", "H5Pset_deflate"),
    2 => ("shuffle", "H5Pset_shuffle"),
    3 => ("fletcher32", "H5Pset_fletcher32"),
    4 => ("szip", "H5Pset_szip"),
    5 => ("nbit", "H5Pset_nbit"),
    6 => ("scaleoffset", "H5Pset_scaleoffset"),
)

function _load_filters(path::AbstractString)
    d = Dict{Int,Tuple{String,String}}()
    for line in eachline(path)
        isempty(line) && continue
        id, name, url = split(line, '\t'; limit=3)
        d[parse(Int, id)] = (name, url)
    end
    return d
end

"""
    FILTERS::Dict{Int,Tuple{String,String}}

Mapping from registered HDF5 filter id to `(name, url)`, loaded once from the
bundled `data/hdf5_filter_urls.tsv`, which is derived from
[`REGISTRY_URL`](@ref).
"""
const FILTERS = _load_filters(_FILTER_URLS_PATH)

"""
    filter_url(id::Integer; default::AbstractString=REGISTRY_URL) -> String

Documentation URL for the HDF5 filter with identifier `id`. For the filters built
into libhdf5 (ids 1-6: deflate, shuffle, fletcher32, szip, nbit, scaleoffset)
this is the page of the corresponding `H5Pset_*` function. For filters registered
with The HDF Group (e.g. `307` for BZIP2 or `32001` for Blosc) it is the entry in
the registry of filter plugins. Returns `default`, the registry page itself, for
unknown ids.
"""
function filter_url(id::Integer; default::AbstractString=REGISTRY_URL)
    haskey(_BUILTIN_FILTERS, id) && return func_url(last(_BUILTIN_FILTERS[id]); default)
    entry = get(FILTERS, Int(id), nothing)
    return entry === nothing ? String(default) : last(entry)
end

"""
    filter_name(id::Integer) -> Union{String,Nothing}

Name of the HDF5 filter with identifier `id` (e.g. `"BZIP2"` for `307`), or
`nothing` if `id` is neither built into libhdf5 nor in the bundled registry.
"""
function filter_name(id::Integer)
    haskey(_BUILTIN_FILTERS, id) && return first(_BUILTIN_FILTERS[id])
    entry = get(FILTERS, Int(id), nothing)
    return entry === nothing ? nothing : first(entry)
end

"""
    EXTERNAL_URLS::Dict{Symbol,String}

Hand-maintained URLs of HDF Group resources that are not in the Doxygen reference
documentation. See [`external_url`](@ref).
"""
const EXTERNAL_URLS = Dict{Symbol,String}(
    :hdf5 => "https://www.hdfgroup.org/solutions/hdf5/",
    :registered_filters => REGISTRY_URL,
    :plugins_repo => "https://github.com/HDFGroup/hdf5_plugins",
    :plugins_zstd => "https://github.com/HDFGroup/hdf5_plugins/tree/master/ZSTD",
    :plugins_releases => "https://github.com/HDFGroup/hdf5_plugins/releases",
    :example_files => "https://support.hdfgroup.org/ftp/HDF5/examples/files/exbyapi/",
)

"""
    external_url(name::Symbol) -> String

URL of an HDF Group resource outside of the Doxygen reference documentation. One of
$(join(("`:$k`" for k in sort!(collect(keys(EXTERNAL_URLS)))), ", ")).
Throws an `ArgumentError` for an unknown `name`.
"""
function external_url(name::Symbol)
    haskey(EXTERNAL_URLS, name) ||
        throw(ArgumentError("unknown external URL `:$name`; known: $(sort!(collect(keys(EXTERNAL_URLS))))"))
    return EXTERNAL_URLS[name]
end

end
