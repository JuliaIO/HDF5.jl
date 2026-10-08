# Markdown link helpers for docstrings. All URLs come from HDF5DocURLs; the
# including scope must have `HDF5DocURLs` available (`import HDF5DocURLs`).
# Also included by `gen/gen_wrappers.jl`, so keep this file free of other
# dependencies.

"""
    h5doc(cfuncname, text="`\$cfuncname`")

Markdown link to the documentation for the HDF5 C API function `cfuncname`,
e.g. `h5doc("H5Pset_chunk")`. Resolved via `HDF5DocURLs.func_url`.
"""
h5doc(cfuncname, text="`$cfuncname`") = "[$text]($(HDF5DocURLs.func_url(cfuncname)))"

"""
    h5doc_group(groupname, text="`\$groupname`")

Markdown link to the documentation for the HDF5 C API module or documentation
page `groupname`, e.g. `h5doc_group("H5P")` or `h5doc_group("IntroParHDF5")`.
Resolved via `HDF5DocURLs.group_url`.
"""
h5doc_group(groupname, text="`$groupname`") =
    "[$text]($(HDF5DocURLs.group_url(groupname)))"

"""
    h5doc_anchor(anchor, text="`\$anchor`")

Markdown link to a section of the HDF5 documentation identified by its Doxygen
anchor id, e.g. `h5doc_anchor("subsec_dataspace_select", "Dataspace Selection")`.
Resolved via `HDF5DocURLs.anchor_url`.
"""
h5doc_anchor(anchor, text="`$anchor`") = "[$text]($(HDF5DocURLs.anchor_url(anchor)))"

"""
    h5doc_filter(id, text="`NAME` filter (ID \$id)")

Markdown link to the documentation for the HDF5 filter with identifier `id`,
e.g. `h5doc_filter(307)`. Resolved via `HDF5DocURLs.filter_url`.
"""
function h5doc_filter(id, text=nothing)
    if text === nothing
        name = HDF5DocURLs.filter_name(id)
        text = name === nothing ? "HDF5 filter ID $id" : "`$name` filter (ID $id)"
    end
    return "[$text]($(HDF5DocURLs.filter_url(id)))"
end

"""
    h5doc_external(name::Symbol, text)

Markdown link to the HDF Group resource `name`, e.g.
`h5doc_external(:registered_filters, "Registered Filter Plugins")`.
Resolved via `HDF5DocURLs.external_url`.
"""
h5doc_external(name::Symbol, text) = "[$text]($(HDF5DocURLs.external_url(name)))"
