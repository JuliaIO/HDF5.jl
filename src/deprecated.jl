import Base: @deprecate, @deprecate_binding, depwarn

###
### v0.16 deprecations
###

### Changed in PR #844
@deprecate silence_errors(f::Function) f()

for name in names(API; all=true)
    if name ∉ names(HDF5; all=true) && startswith(uppercase(String(name)), "H")
        depmsg = ", use HDF5.API.$name instead."
        @eval Base.@deprecate_binding $name API.$name false $depmsg
    end
end

### Changed in PR #847
import Base: getindex, setindex!
@deprecate getindex(p::Properties, name::Symbol) Base.getproperty(p, name)
@deprecate setindex!(p::Properties, val, name::Symbol) Base.setproperty!(p, name, val)

# UTF8_LINK_PROPERTIES etc. used to be Refs, so required UTF8_LINK_PROPERTIES[] to set.
@deprecate getindex(p::Properties) p

function create_property(class; kwargs...)
    (oldname, newtype) =
        class == HDF5.API.H5P_OBJECT_CREATE    ? (:H5P_OBJECT_CREATE, ObjectCreateProperties) :
        class == HDF5.API.H5P_FILE_CREATE      ? (:H5P_FILE_CREATE, FileCreateProperties) :
        class == HDF5.API.H5P_FILE_ACCESS      ? (:H5P_FILE_ACCESS, FileAccessProperties) :
        class == HDF5.API.H5P_DATASET_CREATE   ? (:H5P_DATASET_CREATE, DatasetCreateProperties) :
        class == HDF5.API.H5P_DATASET_ACCESS   ? (:H5P_DATASET_ACCESS, DatasetAccessProperties) :
        class == HDF5.API.H5P_DATASET_XFER     ? (:H5P_DATASET_XFER, DatasetTransferProperties) :
        class == HDF5.API.H5P_FILE_MOUNT       ? (:H5P_FILE_MOUNT, FileMountProperties) :
        class == HDF5.API.H5P_GROUP_CREATE     ? (:H5P_GROUP_CREATE, GroupCreateProperties) :
        class == HDF5.API.H5P_GROUP_ACCESS     ? (:H5P_GROUP_ACCESS, GroupAccessProperties) :
        class == HDF5.API.H5P_DATATYPE_CREATE  ? (:H5P_DATATYPE_CREATE, DatatypeCreateProperties) :
        class == HDF5.API.H5P_DATATYPE_ACCESS  ? (:H5P_DATATYPE_ACCESS, DatatypeAccessProperties) :
        class == HDF5.API.H5P_STRING_CREATE    ? (:H5P_STRING_CREATE, StringCreateProperties) :
        class == HDF5.API.H5P_ATTRIBUTE_CREATE ? (:H5P_ATTRIBUTE_CREATE, AttributeCreateProperties) :
        class == HDF5.API.H5P_OBJECT_COPY      ? (:H5P_OBJECT_COPY, ObjectCopyProperties) :
        class == HDF5.API.H5P_LINK_CREATE      ? (:H5P_LINK_CREATE, LinkCreateProperties) :
        class == HDF5.API.H5P_LINK_ACCESS      ? (:H5P_LINK_ACCESS, LinkAccessProperties) :
        error("invalid class")
    Base.depwarn(
        "`create_property(HDF5.$oldname; kwargs...)` has been deprecated, use `$newtype(;kwargs...)` instead.",
        :create_property
    )
    init!(newtype(; kwargs...))
end

@deprecate set_chunk(p::Properties, dims...) set_chunk!(p, dims) false
@deprecate get_userblock(p::Properties) p.userblock false

function set_shuffle!(p::Properties, ::Tuple{})
    depwarn("`shuffle=()` option is deprecated, use `shuffle=true`", :set_shuffle!)
    set_shuffle!(p, true)
end

# see src/properties.jl for the following deprecated keywords
# :compress
# :fapl_mpio
# :track_times

### Changed in PR #887
# see src/properties.jl for the following deprecated keyword
# :filter

### Changed in PR #902
import Base: append!, push!
import .Filters: ExternalFilter
@deprecate append!(filters::Filters.FilterPipeline, extra::NTuple{N,Integer}) where {N} append!(
    filters, [ExternalFilter(extra...)]
)
@deprecate push!(p::Filters.FilterPipeline, f::NTuple{N,Integer}) where {N} push!(
    p, ExternalFilter(f...)
)
@deprecate ExternalFilter(t::Tuple) ExternalFilter(t...) false

### Changed in PR #979
# Querying items in the file
@deprecate object_info(obj::Union{File,Object}) API.h5o_get_info1(checkvalid(obj))

### Changed in PR #994
@deprecate set_track_order(p::Properties, val::Bool) set_track_order!(
    p::Properties, val::Bool
) false
