# Regenerate ../data/hdf5_filter_urls.tsv from The HDF Group's registered filter list.
# Run `julia gen/registered_filters.jl [path-or-url-of-RegisteredFilterPlugins.md]`.
# Uses only the standard library.

using Downloads

const REGISTRY_MD_URL = "https://raw.githubusercontent.com/HDFGroup/hdf5_plugins/master/docs/RegisteredFilterPlugins.md"
const REGISTRY_PAGE_URL = "https://github.com/HDFGroup/hdf5_plugins/blob/master/docs/RegisteredFilterPlugins.md"

function main(src=REGISTRY_MD_URL)
    md = if startswith(src, "https://")
        String(take!(Downloads.download(src, IOBuffer())))
    else
        read(src, String)
    end
    # Summary table rows look like:
    #   |`307`     |<a href="#bzip2">BZIP2</a>   |BZIP2 lossless compression ...|
    rx = r"^\|`(\d+)`\s*\|<a href=\"#([^\"]+)\">([^<]+)</a>"m
    rows = [(parse(Int, m[1]), String(m[3]), String(m[2])) for m in eachmatch(rx, md)]
    isempty(rows) &&
        error("no registered filters found in $src; has the table format changed?")
    sort!(rows)
    open(joinpath(@__DIR__, "..", "data", "hdf5_filter_urls.tsv"), "w") do io
        for (id, name, anchor) in rows
            println(io, id, "\t", name, "\t", REGISTRY_PAGE_URL, "#", anchor)
        end
    end
    return length(rows)
end

if abspath(PROGRAM_FILE) == @__FILE__
    println("wrote ", main(isempty(ARGS) ? REGISTRY_MD_URL : ARGS[1]), " filters")
end
