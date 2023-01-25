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

const hdf5_tag_url = "https://docs.hdfgroup.org/hdf5/develop/hdf5.tag"

"""
    parse_tag_file(url)

Parse a Doxygen tag file. This defaults to "$hdf5_tag_url".
"""
function parse_tag_file(hdf5_tag_url = hdf5_tag_url)
    filename = if startswith(hdf5_tag_url, "https://")
        Downloads.download(hdf5_tag_url, basename(hdf5_tag_url))
        basename(hdf5_tag_url)
    else
        hdf5_tag_url
    end
    funcdict = Dict{String, HDF5FunctionInfo}()
    parsed = LightXML.parse_file(filename)
    tag_root = root(parsed)
    for compound_element in child_elements(tag_root)
        for compound_child in child_elements(compound_element)
            if name(compound_child) == "member" && attribute(compound_child, "kind") == "function"
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
                funcdict[func_name] = HDF5FunctionInfo(func_name, func_anchorfile, func_anchor, func_arglist)
            end
        end
    end
    return funcdict
end

"""
    hdf5_func_url

Build the documentation URL from the anchorfile and anchor.
"""
function hdf5_func_url(info::HDF5FunctionInfo; prefix = "https://docs.hdfgroup.org/hdf5/develop/")
    return prefix * info.anchorfile * "#" * info.anchor
end

"""
    save_to_tab_separated_values

Save the function names and documentation URLs to a file, separated by a time, with one function per line.
"""
function save_to_tab_separated_values(filename::AbstractString = "hdf5_func_urls.tsv", funcinfo::Dict{String, HDF5FunctionInfo} = parse_tag_file())
    open(filename, "w") do f
        sorted_funcs = sort!(collect(keys(funcinfo)))
        for func in sorted_funcs
            println(f, func,"\t",hdf5_func_url(funcinfo[func]))
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
    tag_file = nargs > 1 ? ARGS[2] : hdf5_tag_url
    funcinfo = parse_tag_file(tag_file)
    save_to_tab_separated_values(tsv_file, funcinfo)
end

end
