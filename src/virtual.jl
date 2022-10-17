"""
    VirtualMapping(
        vspace::Dataspace,
        srcfile::AbstractString,
        srcdset::AbstractString,
        srcspace::Dataspace
    )

Specify a map of elements of the virtual dataset (VDS) described by `vspace` to
the elements of the source dataset described by `srcspace`. The source dataset
is identified by the name of the file where it is located, `srcfile`, and the
name of the dataset, `srcdset`.

Both `srcfile` and `srcdset` support "printf"-style formats with `%b` being
replaced by the block count of the selection.

For more details on how source file resolution works, see
[`H5P_SET_VIRTUAL`](https://portal.hdfgroup.org/display/HDF5/H5P_SET_VIRTUAL).
"""
struct VirtualMapping
    vspace::Dataspace
    srcfile::String
    srcdset::String
    srcspace::Dataspace
end

"""
    VirtualLayout(dcpl::DatasetCreateProperties)

The collection of [`VirtualMapping`](@ref)s associated with `dcpl`. This is an
`AbstractVector{VirtualMapping}`, supporting `length`, `getindex` and `push!`.
"""
struct VirtualLayout <: AbstractVector{VirtualMapping}
    dcpl::DatasetCreateProperties
end

function Base.length(vlayout::VirtualLayout)
    return API.h5p_get_virtual_count(vlayout.dcpl)
end
Base.size(vlayout::VirtualLayout) = (length(vlayout),)

function Base.push!(vlayout::VirtualLayout, vmap::VirtualMapping)
    API.h5p_set_virtual(
        vlayout.dcpl, vmap.vspace, vmap.srcfile, vmap.srcdset, vmap.srcspace
    )
    return vlayout
end
function Base.append!(vlayout::VirtualLayout, vmaps)
    for vmap in vmaps
        push!(vlayout, vmap)
    end
    return vlayout
end

function Base.getindex(vlayout::VirtualLayout, i::Integer)
    vspace = Dataspace(API.h5p_get_virtual_vspace(vlayout.dcpl, i - 1))
    srcfile = API.h5p_get_virtual_filename(vlayout.dcpl, i - 1)
    srcdset = API.h5p_get_virtual_dsetname(vlayout.dcpl, i - 1)
    srcspace = Dataspace(API.h5p_get_virtual_srcspace(vlayout.dcpl, i - 1))
    return VirtualMapping(vspace, srcfile, srcdset, srcspace)
end
