# The context API is under active development. This is an internal API and may change.

"""
    HDF5Context

*Internal API*

An `HDF5Context` is a collection of HDF5 property lists. It is meant to be used
as a `Task` local mechanism to store state and change the default property lists
for new objects.

Use the function `get_context_property(name::Symbol)` to access a property
list within the local context.

The context in `task_local_storage()[:hdf5_context]` will be checked first.
A common global HDF5Context is stored in the constant `HDF5.CONTEXT` and
serves as the default context if the current task does not have a
`:hdf5_context`.

# Fields

* attribute_access
* attribute_create
* dataset_access
* dataset_create
* dataset_tranfer
* datatype_access
* datatype_create
* file_access
* file_create
* file_mount
* group_access
* group_create
* link_access
* link_create
* object_copy
* object_create
* string_create
"""
struct HDF5Context
    attribute_access :: AttributeAccessProperties
    attribute_create :: AttributeCreateProperties
    dataset_access   :: DatasetAccessProperties
    dataset_create   :: DatasetCreateProperties
    dataset_transfer :: DatasetTransferProperties
    datatype_access  :: DatatypeAccessProperties
    datatype_create  :: DatatypeCreateProperties
    file_access      :: FileAccessProperties
    file_create      :: FileCreateProperties
    file_mount       :: FileMountProperties
    group_access     :: GroupAccessProperties
    group_create     :: GroupCreateProperties
    link_access      :: LinkAccessProperties
    link_create      :: LinkCreateProperties
    object_copy      :: ObjectCopyProperties
    object_create    :: ObjectCreateProperties
    string_create    :: StringCreateProperties
end

Base.copy(ctx::HDF5Context) =
    HDF5Context(map(n -> copy(getfield(ctx, n)), fieldnames(HDF5Context))...)

Base.close(ctx::HDF5Context) =
    foreach(n -> close(getfield(ctx, n)), fieldnames(HDF5Context))

function HDF5Context()
    HDF5Context(
        AttributeAccessProperties(),
        AttributeCreateProperties(),
        DatasetAccessProperties(),
        DatasetCreateProperties(),
        DatasetTransferProperties(),
        DatatypeAccessProperties(),
        DatatypeCreateProperties(),
        FileAccessProperties(),
        FileCreateProperties(),
        FileMountProperties(),
        GroupAccessProperties(),
        GroupCreateProperties(),
        LinkAccessProperties(),
        LinkCreateProperties(),
        ObjectCopyProperties(),
        ObjectCreateProperties(),
        StringCreateProperties(),
    )
end

"""
    HDF5.CONTEXT

*Internal API*

Default `HDF5Context`.
"""
const CONTEXT = HDF5Context()

"""
    get_context_property(name::Symbol)

*Internal API*

Retrieve a property list from the task local context, defaulting to
`HDF5.CONTEXT` if `task_local_storage()[:hdf5_context]` does not
exist.
"""
get_context_property(name::Symbol) =
    getfield(get(task_local_storage(), :hdf5_context, CONTEXT), name)
