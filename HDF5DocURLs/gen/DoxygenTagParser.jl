module DoxygenTagParser

using Downloads
using LightXML

export parse_tag_file, hdf5_func_url, save_to_tab_separated_values

struct HDF5FunctionInfo
    name::String
    anchorfile::String
    anchor::String
    arglist::String
end

struct HDF5GroupInfo
    name::String
    title::String
    filename::String
end

const DEFAULT_URL_PREFIX = "https://support.hdfgroup.org/documentation/hdf5/latest/"

"""
Bare, unnumbered HDF5 C API names that libhdf5 later split into numbered
variants (e.g. `H5Literate` -> `H5Literate1`/`H5Literate2`). The current
Doxygen tag file only documents the numbered variants as real `function`
members; the bare name appears solely as a `#define` compatibility macro
(aliasing to whichever numbered variant is selected via `H5_VERSION_GE`),
which this parser otherwise ignores (see `parse_tag_file`), leaving the bare
name to fall back to the generic docs root.

Each target below is picked to match the exact version HDF5.jl itself binds
the bare C symbol to (verified against both `gen/api_defs.jl`'s version
tuples/comments and the tag file's `arglist` for each numbered variant):
  - `H5Dread_chunk` -> `H5Dread_chunk1`: `gen/api_defs.jl`'s `h5d_read_chunk`
    binds the bare symbol for libhdf5 `< v"2.0"` ("The function was renamed
    to H5Dread_chunk1 in v2.0"); `H5Dread_chunk1`'s 5-argument arglist
    matches, `H5Dread_chunk2`'s added `buf_size` parameter does not.
  - `H5Lget_info` -> `H5Lget_info1`: `h5l_get_info` binds the bare symbol
    unconditionally (all supported libhdf5 versions) using HDF5.jl's single
    `H5L_info_t` struct; `H5Lget_info1`'s arglist takes `H5L_info1_t*`
    (matching field-for-field), `H5Lget_info2`'s takes the newer
    `H5L_info2_t*`.
  - `H5Literate` -> `H5Literate1`: `h5l_iterate` binds the bare symbol for
    libhdf5 `< v"1.12"` ("libhdf5 v1.10 provides the name H5Literate...v1.12
    provides the same under H5Literate1"); `H5Literate1`'s arglist takes the
    matching `H5L_iterate1_t` callback type, `H5Literate2`'s takes the newer
    `H5L_iterate2_t`.

None of the newer `*2` variants above are bound by HDF5.jl at all yet; see
https://github.com/JuliaIO/HDF5.jl/issues/1248 (opened to track adding them).
"""
const COMPAT_MACRO_ALIASES = Dict(
    "H5Dread_chunk" => "H5Dread_chunk1",
    "H5Lget_info" => "H5Lget_info1",
    "H5Literate" => "H5Literate1",
)

"""
To refresh hdf5.tag, either download it directly from
`"\$(DEFAULT_URL_PREFIX)hdf5.tag"` (HDF Group's continuously-updated tag file
for the latest HDF5 docs), or generate it from the HDF5 source code by
running `generate_hdf5_tag.sh` (see that script for setup requirements).
Either way, overwrite `joinpath(@__DIR__, "hdf5.tag")`, i.e. `HDF5_TAG_URL`
below.
"""
const HDF5_TAG_URL = joinpath(@__DIR__, "hdf5.tag")

"""
    parse_tag_file(url)

Parse a Doxygen tag file. This defaults to "$HDF5_TAG_URL".
"""
function parse_tag_file(hdf5_tag_url=HDF5_TAG_URL)
    filename = if startswith(hdf5_tag_url, "https://")
        Downloads.download(hdf5_tag_url, basename(hdf5_tag_url))
        basename(hdf5_tag_url)
    else
        hdf5_tag_url
    end
    funcdict = Dict{String,HDF5FunctionInfo}()
    groupdict = Dict{String,HDF5GroupInfo}()
    parsed = LightXML.parse_file(filename)
    tag_root = root(parsed)
    for compound_element in child_elements(tag_root)
        compound_kind = attribute(compound_element, "kind")
        if compound_kind == "class"
            # Java or C++ methods
            continue
        elseif compound_kind == "group" || compound_kind == "page"
            group_name = ""
            group_title = ""
            group_filename = ""
            for compound_child in child_elements(compound_element)
                if name(compound_child) == "member" &&
                    attribute(compound_child, "kind") == "function"
                    func_name = ""
                    func_anchorfile = ""
                    func_anchor = ""
                    func_arglist = ""
                    for func_child in child_elements(compound_child)
                        func_child_name = name(func_child)
                        if func_child_name == "name"
                            func_name = content(func_child)
                        elseif func_child_name == "anchorfile"
                            func_anchorfile = content(func_child)
                        elseif func_child_name == "anchor"
                            func_anchor = content(func_child)
                        elseif func_child_name == "arglist"
                            func_arglist = content(func_child)
                        end
                    end
                    funcdict[func_name] = HDF5FunctionInfo(
                        func_name, func_anchorfile, func_anchor, func_arglist
                    )
                elseif name(compound_child) == "name"
                    group_name = content(compound_child)
                elseif name(compound_child) == "title"
                    group_title = content(compound_child)
                    if startswith(group_title, "Java")
                        break
                    end
                elseif name(compound_child) == "filename"
                    group_filename = content(compound_child)
                end
            end
            if startswith(group_title, "Java")
                continue
            end
            groupdict[group_name] = HDF5GroupInfo(group_name, group_title, group_filename)
        end
    end
    for (alias, target) in COMPAT_MACRO_ALIASES
        haskey(funcdict, alias) && continue  # tag file now documents this name directly
        haskey(funcdict, target) || error(
            "COMPAT_MACRO_ALIASES: target `$target` for alias `$alias` was not found " *
            "in the parsed tag file. Either the tag file is stale/corrupt, or `$target` " *
            "has been renamed/removed upstream -- update COMPAT_MACRO_ALIASES to match.",
        )
        funcdict[alias] = funcdict[target]
    end
    return funcdict, groupdict
end

"""
    hdf5_func_url

Build the documentation URL from the anchorfile and anchor.
"""
function hdf5_func_url(info::HDF5FunctionInfo; prefix=DEFAULT_URL_PREFIX)
    return prefix * info.anchorfile * "#" * info.anchor
end

function hdf5_group_url(info::HDF5GroupInfo; prefix=DEFAULT_URL_PREFIX)
    return prefix * info.filename
end

"""
    save_to_tab_separated_values

Save the function names and documentation URLs to a file, separated by a tab, with one function per line.
"""
function save_to_tab_separated_values(
    func_filename::AbstractString=joinpath(@__DIR__, "..", "data", "hdf5_func_urls.tsv"),
    group_filename::AbstractString=joinpath(@__DIR__, "..", "data", "hdf5_group_urls.tsv"),
    info::Tuple{Dict{String,HDF5FunctionInfo},Dict{String,HDF5GroupInfo}}=parse_tag_file()
)
    funcinfo, groupinfo = info
    open(func_filename, "w") do f
        sorted_funcs = sort!(collect(keys(funcinfo)))
        for func in sorted_funcs
            println(f, func, "\t", hdf5_func_url(funcinfo[func]))
        end
    end
    open(group_filename, "w") do f
        sorted_groups = sort!(collect(keys(groupinfo)))
        for group in sorted_groups
            println(f, group, "\t", hdf5_group_url(groupinfo[group]))
        end
    end
end

"""
    main()

Executed when `julia --project -m DoxygenTagParser` is run from the shell.
Regenerates `../data/hdf5_func_urls.tsv` and `../data/hdf5_group_urls.tsv`
from `hdf5.tag` (or the paths/URL given as ARGS) by default.
"""
function (@main)(ARGS)
    nargs = length(ARGS)
    tsv_file = nargs > 0 ? ARGS[1] : joinpath(@__DIR__, "..", "data", "hdf5_func_urls.tsv")
    group_file = nargs > 1 ? ARGS[2] : joinpath(@__DIR__, "..", "data", "hdf5_group_urls.tsv")
    tag_file = nargs > 2 ? ARGS[3] : HDF5_TAG_URL
    info = parse_tag_file(tag_file)
    save_to_tab_separated_values(tsv_file, group_file, info)
end

end
