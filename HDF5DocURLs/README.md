# HDF5DocURLs.jl

A small companion data package for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl) that maps HDF5 C API function and module/group names to their documentation URLs on `support.hdfgroup.org`.

HDF5.jl's generated docstrings resolve these URLs once, at HDF5.jl's own precompile time, via `func_url`/`group_url`. Because this package can be released independently of HDF5.jl, doc-link refreshes (or fixes for renamed/moved pages) can ship to every HDF5.jl release line that depends on it — without a new HDF5.jl release.

## Usage

```julia
using HDF5DocURLs

func_url("H5Fopen")   # => "https://support.hdfgroup.org/documentation/hdf5/latest/group___h5_f.html#..."
group_url("H5F")      # => "https://support.hdfgroup.org/documentation/hdf5/latest/group___h5_f.html"

func_url("NotARealFunction")                  # => DEFAULT_URL (fallback)
func_url("NotARealFunction"; default="")      # => ""
```

## Refreshing the data

The `gen/` directory (excluded from released tarballs via `.gitattributes`) contains the Doxygen-tag-parsing tool used to regenerate `data/hdf5_func_urls.tsv`/`data/hdf5_group_urls.tsv`:

1. Refresh `gen/hdf5.tag`, either by downloading it directly from `https://support.hdfgroup.org/documentation/hdf5/latest/hdf5.tag`, or by running `gen/generate_hdf5_tag.sh [hdf5-git-ref]` (requires `git`, `cmake`, `doxygen`).
2. From `gen/`, run `julia --project -m DoxygenTagParser` to regenerate the TSVs in `../data/`.
3. Bump this package's version and release.
