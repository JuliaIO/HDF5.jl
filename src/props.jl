using HDF5

function supername(h)
    name = unsafe_string(ccall((:H5Pget_class_name, HDF5.libhdf5), Cstring, (HDF5.hid_t,), h))
    sh = ccall((:H5Pget_class_parent, HDF5.libhdf5), HDF5.hid_t, (HDF5.hid_t,), h)
    sname = unsafe_string(ccall((:H5Pget_class_name, HDF5.libhdf5), Cstring, (HDF5.hid_t,), sh))
    println(name, " => ", sname)
end

for h in [
HDF5.H5P_OBJECT_CREATE   ,
HDF5.H5P_FILE_CREATE     ,
HDF5.H5P_FILE_ACCESS     ,
HDF5.H5P_DATASET_CREATE  ,
HDF5.H5P_DATASET_ACCESS  ,
HDF5.H5P_DATASET_XFER    ,
HDF5.H5P_FILE_MOUNT      ,
HDF5.H5P_GROUP_CREATE    ,
HDF5.H5P_GROUP_ACCESS    ,
HDF5.H5P_DATATYPE_CREATE ,
HDF5.H5P_DATATYPE_ACCESS ,
HDF5.H5P_STRING_CREATE   ,
HDF5.H5P_ATTRIBUTE_CREATE,
HDF5.H5P_ATTRIBUTE_ACCESS,
HDF5.H5P_OBJECT_COPY     ,
HDF5.H5P_LINK_CREATE     ,
HDF5.H5P_LINK_ACCESS     ,
]
    supername(h)
end
                
