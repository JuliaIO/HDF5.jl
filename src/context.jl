struct HDF5Context
   attribute_access::AttributeAccessProperties
   attribute_create::AttributeCreateProperties
   dataset_access  ::DatasetAccessProperties
   dataset_create  ::DatasetCreateProperties
   dataset_transfer::DatasetTransferProperties
   datatype_access ::DatatypeAccessProperties
   datatype_create ::DatatypeCreateProperties
   file_access     ::FileAccessProperties
   file_create     ::FileCreateProperties
   file_mount      ::FileMountProperties
   group_access    ::GroupAccessProperties
   group_create    ::GroupCreateProperties
   link_access     ::LinkAccessProperties
   link_create     ::LinkCreateProperties
   object_copy     ::ObjectCopyProperties
   object_create   ::ObjectCreateProperties
   string_create   ::StringCreateProperties
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

const CONTEXT = HDF5Context()

get_context_property(name::Symbol) =
    getfield(get(task_local_storage(), :hdf5_context, CONTEXT), name)
