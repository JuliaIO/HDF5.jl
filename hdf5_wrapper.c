#include "hdf5.h"
#include <stdlib.h>

/* This C wrapper is needed because Julia can't handle
   C structs yet. */
herr_t jl_H5Gn_members(hid_t group_id, hsize_t *nlinks) {
  H5G_info_t group_info;
  herr_t status = H5Gget_info(group_id, &group_info);
  *nlinks = group_info.nlinks;
  return status;
}

hid_t jl_HDF5_type_id(int element_type, int element_size, int is_signed) {
  if (element_type == 0)  { /* integer */
    if (element_size == sizeof(char)) {
      if (is_signed)
        return H5T_NATIVE_SCHAR;
      else
        return H5T_NATIVE_UCHAR;
    }
    else if (element_size == sizeof(short)) {
      if (is_signed)
        return H5T_NATIVE_SHORT;
      else
        return H5T_NATIVE_USHORT;
    }
    else if (element_size == sizeof(int)) {
      if (is_signed)
        return H5T_NATIVE_INT;
      else
        return H5T_NATIVE_UINT;
    }
    else if (element_size == sizeof(long)) {
      if (is_signed)
        return H5T_NATIVE_LONG;
      else
        return H5T_NATIVE_ULONG;
    }
    else if (element_size == sizeof(long long)) {
      if (is_signed)
        return H5T_NATIVE_LLONG;
      else
        return H5T_NATIVE_ULLONG;
    }
    else
      return (-1);
  }
  else if (element_type == 1) { /* float */
    if (element_size == sizeof(float))
      return H5T_NATIVE_FLOAT;
    else if (element_size == sizeof(double))
      return H5T_NATIVE_DOUBLE;
  }
  else
    return (-1);
}

/* Without the following useless function, the symbols defined
   in H5D.c are not in the dynamic library under MacOS.
   The symbols from H5Dio.c seem to be always there. */
hid_t jl_H5Dget_space(hid_t dataset_id) {
  return H5Dget_space(dataset_id);
}

hid_t jl_H5Tget_native_type(hid_t dataset_id, int order) {
  return H5Tget_native_type(dataset_id, order);
}
