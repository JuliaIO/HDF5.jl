import Base: @deprecate, @deprecate_binding, depwarn

###
### v0.15 deprecations
###

### Add empty exists method for JLD,MAT to extend to smooth over deprecation process PR#790
export exists
function exists end

### Changed in PR#776
@deprecate create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace,
    lcpl::Properties, dcpl::Properties, dapl::Properties, dxpl::Properties) HDF5.Dataset(HDF5.h5d_create(parent, path, dtype, dspace, lcpl, dcpl, dapl), HDF5.file(parent), dxpl) false

### Changed in PR#798
@deprecate get_dims(dspace::Union{Dataspace,Dataset,Attribute}) get_extent_dims(dspace) false
@deprecate set_dims!(dset::Dataspace) set_extent_dims(dset) false


### 
@deprecate(create_property(class; kwargs...),
           class == HDF5.H5P_OBJECT_CREATE   ? ObjectCreateProperties(;kwargs...) :
           class == HDF5.H5P_FILE_CREATE     ? FileCreateProperties(;kwargs...) :
           class == HDF5.H5P_FILE_ACCESS     ? FileAccessProperties(;kwargs...) :
           class == HDF5.H5P_DATASET_CREATE  ? DatasetCreateProperties(;kwargs...) :
           class == HDF5.H5P_DATASET_ACCESS  ? DatasetAccessProperties(;kwargs...) :
           class == HDF5.H5P_DATASET_XFER    ? DatasetTransferProperties(;kwargs...) :
           class == HDF5.H5P_FILE_MOUNT      ? FileMountProperties(;kwargs...) :
           class == HDF5.H5P_GROUP_CREATE    ? GroupCreateProperties(;kwargs...) :
           class == HDF5.H5P_GROUP_ACCESS    ? GroupAccessProperties(;kwargs...) :
           class == HDF5.H5P_DATATYPE_CREATE ? DatatypeCreateProperties(;kwargs...) :
           class == HDF5.H5P_DATATYPE_ACCESS ? DatatypeAccessProperties(;kwargs...) :
           class == HDF5.H5P_STRING_CREATE   ? StringCreateProperties(;kwargs...) :
           class == HDF5.H5P_ATTRIBUTE_CREATE ? AttributeCreateProperties(;kwargs...) :
           class == HDF5.H5P_OBJECT_COPY     ? ObjectCopyProperties(;kwargs...) :
           class == HDF5.H5P_LINK_CREATE     ? LinkCreateProperties(;kwargs...) :
           class == HDF5.H5P_LINK_ACCESS     ? LinkAccessProperties(;kwargs...) :
           error("invalid class"))

import Base: getindex, setindex!
@deprecate getindex(p::Properties, name::Symbol) Base.getproperty(p, name)
@deprecate setindex!(p::Properties, val, name::Symbol) Base.setproperty!(p, name, val)

function Filters.set_shuffle!(p::Properties, ::Tuple{})
    depwarn("`shuffle=()` option is deprecated, use `shuffle=true`", :set_shuffle!)
    Filters.set_shuffle!(p, true)
end

for name in names(API; all=true)
    if name ∉ names(HDF5; all=true) && startswith(uppercase(String(name)), "H")
        depmsg = ", use HDF5.API.$name instead."
        @eval Base.@deprecate_binding $name API.$name false $depmsg
    end
end

