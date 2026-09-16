import HDF5DocURLs

"""
    _hdf5_func_doc_url(cfuncname::AbstractString) -> String

Look up the `libhdf5` documentation URL for C API function `cfuncname` (e.g.
`"H5Fopen"`) using the `HDF5DocURLs` package version resolved in the current
environment. Called via string interpolation directly inside the docstrings
in `functions.jl`/`helpers.jl`, so it runs exactly once — when those top-level
docstring expressions are evaluated while `HDF5.API` is loaded (i.e. during
`HDF5.jl`'s own precompilation) — not on every interactive `?h5f_open`-style
docstring lookup.
"""
_hdf5_func_doc_url(cfuncname::AbstractString) = HDF5DocURLs.func_url(cfuncname)

"""
    _hdf5_group_doc_url(groupname::AbstractString) -> String

Analogous to [`_hdf5_func_doc_url`](@ref) for an HDF5 module/group name (e.g. `"H5F"`).
"""
_hdf5_group_doc_url(groupname::AbstractString) = HDF5DocURLs.group_url(groupname)
