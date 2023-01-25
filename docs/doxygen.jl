using EzXML, Documenter, Markdown, Downloads


const ver = "v1_14"
const baseurl = "https://docs.hdfgroup.org/hdf5/$ver"
const tagfile = joinpath(@__DIR__,"hdf5.tag")
Downloads.download("$baseurl/hdf5.tag", tagfile)
const tagdoc = readxml(tagfile)

#=

findall("/tagfile/compound/member[name='H5FD_mpio_init']", tagdoc)
findall("/tagfile/compound/member[name='H5Pset_driver']", tagdoc)[2]))
findall("/tagfile/compound[@kind='group']/member[name='H5Pset_driver']", tagdoc)
findall("/tagfile/compound[name='FAPL']/member[name='H5Pget_driver']", tagdoc)
findall("/tagfile/compound[title='The HDF5 Data Model and File Structure']/docanchor[@title='Group']", tagdoc)

=#

function doxygen_url(node)
    baseurl = "https://docs.hdfgroup.org/hdf5/v1_14"
    if node.name == "compound"
        filename = findfirst("filename", node).content
        anchor = nothing
    elseif node.name == "member"
        filename = findfirst("anchorfile", node).content
        anchor = findfirst("anchor", node).content
    elseif node.name == "docanchor"
        filename = findfirst("@file",node).content
        anchor = node.content
    else
        error("invalid node")
    end
    if isnothing(anchor)
        return "$baseurl/$filename"
    else
        return "$baseurl/$filename#$anchor"
    end
end

function doxygen_title(node)
    if node.name == "compound"
        return [
            Markdown.Italic([findfirst("title", node).content]),
            " in HDF5 documentation",
            ]
    elseif node.name == "member"
        name = findfirst("name", node).content
        return [
            Markdown.Code(name),
            " in HDF5 documentation",
            ]
    elseif node.name == "docanchor"
        return [
            Markdown.Italic([findfirst("../title", node).content]),
            " - ",
            Markdown.Italic([findfirst("@title", node).content]),
            " in HDF5 documentation",
            ]
    else
        error("invalid node")
    end
end

abstract type DoxygenLinker <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{DoxygenLinker}) = 3.1  # After cross-references

function Documenter.Selectors.runner(::Type{DoxygenLinker}, doc::Documenter.Documents.Document)
    @info "DoxygenLinker: expanding links"
    for (src, page) in doc.blueprint.pages
        empty!(page.globals.meta)
        for expanded in values(page.mapping)
            expand_doxygen(expanded, page, doc)
        end
    end
end

function expand_doxygen(elem, page, doc)
    Documenter.Documents.walk(page.globals.meta, elem) do link
        expand_doxygen(link, page.globals.meta, page, doc)
    end
end

function expand_doxygen(link::Markdown.Link, meta, page, doc)
    startswith(link.url, "@doxygen ") || return false
    xpath = chopprefix(link.url, "@doxygen ")

    nodes = findall(xpath, tagdoc)
    if length(nodes) == 0
        @warn "DoxygenLinker: cannot find node at $xpath"
        return false
    elseif length(nodes) > 1
        @warn "DoxygenLinker: multiple nodes matching $xpath"
    end
    node = first(nodes)

    link.url = doxygen_url(node)
    if isempty(link.text)
        link.text = doxygen_title(node)
    end
    return true
end

expand_doxygen(other, meta, page, doc) = true # Continue to `walk` through element `other`.
