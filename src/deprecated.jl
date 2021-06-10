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
export create_property

function create_property(class; kwargs...)
    (oldname, newname, newtype) =
        class == HDF5.API.H5P_OBJECT_CREATE    ? (:H5P_OBJECT_CREATE, :ObjectCreateProperties, ObjectCreateProperties) :
        class == HDF5.API.H5P_FILE_CREATE      ? (:H5P_FILE_CREATE, :FileCreateProperties, FileCreateProperties) :
        class == HDF5.API.H5P_FILE_ACCESS      ? (:H5P_FILE_ACCESS, :FileAccessProperties, FileAccessProperties) :
        class == HDF5.API.H5P_DATASET_CREATE   ? (:H5P_DATASET_CREATE, :DatasetCreateProperties, DatasetCreateProperties) :
        class == HDF5.API.H5P_DATASET_ACCESS   ? (:H5P_DATASET_ACCESS, :DatasetAccessProperties, DatasetAccessProperties) :
        class == HDF5.API.H5P_DATASET_XFER     ? (:H5P_DATASET_XFER, :DatasetTransferProperties, DatasetTransferProperties) :
        class == HDF5.API.H5P_FILE_MOUNT       ? (:H5P_FILE_MOUNT, :FileMountProperties, FileMountProperties) :
        class == HDF5.API.H5P_GROUP_CREATE     ? (:H5P_GROUP_CREATE, :GroupCreateProperties, GroupCreateProperties) :
        class == HDF5.API.H5P_GROUP_ACCESS     ? (:H5P_GROUP_ACCESS, :GroupAccessProperties, GroupAccessProperties) :
        class == HDF5.API.H5P_DATATYPE_CREATE  ? (:H5P_DATATYPE_CREATE, :DatatypeCreateProperties, DatatypeCreateProperties) :
        class == HDF5.API.H5P_DATATYPE_ACCESS  ? (:H5P_DATATYPE_ACCESS, :DatatypeAccessProperties, DatatypeAccessProperties) :
        class == HDF5.API.H5P_STRING_CREATE    ? (:H5P_STRING_CREATE, :StringCreateProperties, StringCreateProperties) :
        class == HDF5.API.H5P_ATTRIBUTE_CREATE ? (:H5P_ATTRIBUTE_CREATE, :AttributeCreateProperties, AttributeCreateProperties) :
        class == HDF5.API.H5P_OBJECT_COPY      ? (:H5P_OBJECT_COPY, :ObjectCopyProperties, ObjectCopyProperties) :
        class == HDF5.API.H5P_LINK_CREATE      ? (:H5P_LINK_CREATE, :LinkCreateProperties, LinkCreateProperties) :
        class == HDF5.API.H5P_LINK_ACCESS      ? (:H5P_LINK_ACCESS, :LinkAccessProperties, LinkAccessProperties) :
        error("invalid class")
    Base.depwarn("`create_property(HDF5,$oldname; kwargs...)` has been deprecated, use `$newname(;kwargs...)` instead.", :create_property)
    init!(newtype(;kwargs...))
end
import Base: getindex, setindex!
@deprecate getindex(p::Properties, name::Symbol) Base.getproperty(p, name)
@deprecate setindex!(p::Properties, val, name::Symbol) Base.setproperty!(p, name, val)

function Filters.set_shuffle!(p::Properties, ::Tuple{})
    depwarn("`shuffle=()` option is deprecated, use `shuffle=true`", :set_shuffle!)
    Filters.set_shuffle!(p, true)
end

Base.@deprecate_binding DEFAULT_PROPERTIES Properties{PropertyClass}() false

for name in names(API; all=true)
    if name ∉ names(HDF5; all=true) && startswith(uppercase(String(name)), "H")
        depmsg = ", use HDF5.API.$name instead."
        @eval Base.@deprecate_binding $name API.$name false $depmsg
    end
end

