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

const DEFAULT_URL_PREFIX = "https://docs.hdfgroup.org/hdf5/v1_14/"
const HDF5_TAG_URL = "$(DEFAULT_URL_PREFIX)hdf5.tag"

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
                    if func_name == "H5Pget_chunk"
                        println(compound_element)
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
    return funcdict, groupdict
end

"""
    hdf5_func_url

Build the documentation URL from the anchorfile and anchor.
"""
function hdf5_func_url(info::HDF5FunctionInfo; prefix=DEFAULT_URL_PREFIX)
    return prefix * info.anchorfile * "#" * info.anchor
end

function hdf5_group_url(info::HDF5GroupInfo; prefix="https://docs.hdfgroup.org/hdf5/v1_14/")
    return prefix * info.filename
end

"""
    save_to_tab_separated_values

Save the function names and documentation URLs to a file, separated by a time, with one function per line.
"""
function save_to_tab_separated_values(
    func_filename::AbstractString="hdf5_func_urls.tsv",
    group_filename::AbstractString="hdf5_group_urls.tsv",
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

function __init__()
    if abspath(PROGRAM_FILE) == @__FILE__()
        main()
    end
end

"""
    main()

Executed when `julia --project=. src/DoxygenTagParser` is run from the shell.
"""
function main()
    nargs = length(ARGS)
    tsv_file = nargs > 0 ? ARGS[1] : "hdf5_func_urls.tsv"
    group_file = nargs > 1 ? ARGS[2] : "hdf5_group_urls.tsv"
    tag_file = nargs > 2 ? ARGS[3] : HDF5_TAG_URL
    info = parse_tag_file(tag_file)
    save_to_tab_separated_values(tsv_file, group_file, info)
end

end
