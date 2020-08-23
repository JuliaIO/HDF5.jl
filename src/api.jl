function h5_close()
    status = ccall((:H5close, libhdf5), Int32, ())
    if status < 0
        error("Error closing the HDF5 resources")
    end
end

function h5_dont_atexit()
    status = ccall((:H5dont_atexit, libhdf5), Int32, ())
    if status < 0
        error("Error calling dont_atexit")
    end
end

function h5_garbage_collect()
    status = ccall((:H5garbage_collect, libhdf5), Int32, ())
    if status < 0
        error("Error on garbage collect")
    end
end

function h5_open()
    status = ccall((:H5open, libhdf5), Int32, ())
    if status < 0
        error("Error initializing the HDF5 library")
    end
end

function h5_set_free_list_limits(reg_global_lim, reg_list_lim, arr_global_lim, arr_list_lim, blk_global_lim, blk_list_lim)
    status = ccall((:H5set_free_list_limits, libhdf5), Int32, (Int32, Int32, Int32, Int32, Int32, Int32), reg_global_lim, reg_list_lim, arr_global_lim, arr_list_lim, blk_global_lim, blk_list_lim)
    if status < 0
        error("Error setting limits on free lists")
    end
end

function h5a_close(id)
    status = ccall((:H5Aclose, libhdf5), Int32, (Int64,), id)
    if status < 0
        error("Error closing attribute")
    end
end

function h5a_write(attr_hid, mem_type_id, buf)
    status = ccall((:H5Awrite, libhdf5), Int32, (Int64, Int64, Ptr{Nothing}), attr_hid, mem_type_id, buf)
    if status < 0
        error("Error writing attribute data")
    end
end

function h5d_close(dataset_id)
    status = ccall((:H5Dclose, libhdf5), Int32, (Int64,), dataset_id)
    if status < 0
        error("Error closing dataset")
    end
end

function h5d_flush(dataset_id)
    status = ccall((:H5Dflush, libhdf5), Int32, (Int64,), dataset_id)
    if status < 0
        error("Error flushing dataset")
    end
end

function h5d_oappend(dset_id, dxpl_id, index, num_elem, memtype, buffer)
    status = ccall((:H5DOappend, libhdf5_hl), Int32, (Int64, Int64, UInt32, UInt64, Int64, Ptr{Nothing}), dset_id, dxpl_id, index, num_elem, memtype, buffer)
    if status < 0
        error("error appending")
    end
end

function h5do_write_chunk(dset_id, dxpl_id, filter_mask, offset, bufsize, buf)
    status = ccall((:H5DOwrite_chunk, libhdf5_hl), Int32, (Int64, Int64, Int32, Ptr{UInt64}, UInt64, Ptr{Nothing}), dset_id, dxpl_id, filter_mask, offset, bufsize, buf)
    if status < 0
        error("Error writing chunk")
    end
end

function h5d_refresh(dataset_id)
    status = ccall((:H5Drefresh, libhdf5), Int32, (Int64,), dataset_id)
    if status < 0
        error("Error refreshing dataset")
    end
end

function h5d_set_extent(dataset_id, new_dims)
    status = ccall((:H5Dset_extent, libhdf5), Int32, (Int64, Ptr{UInt64}), dataset_id, new_dims)
    if status < 0
        error("Error extending dataset dimensions")
    end
end

function h5d_vlen_get_buf_size(dset_id, type_id, space_id, buf)
    status = ccall((:H5Dvlen_get_buf_size, libhdf5), Int32, (Int64, Int64, Int64, Ptr{UInt64}), dset_id, type_id, space_id, buf)
    if status < 0
        error("Error getting vlen buffer size")
    end
end

function h5d_vlen_reclaim(type_id, space_id, plist_id, buf)
    status = ccall((:H5Dvlen_reclaim, libhdf5), Int32, (Int64, Int64, Int64, Ptr{Nothing}), type_id, space_id, plist_id, buf)
    if status < 0
        error("Error reclaiming vlen buffer")
    end
end

function h5d_write(dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    status = ccall((:H5Dwrite, libhdf5), Int32, (Int64, Int64, Int64, Int64, Int64, Ptr{Nothing}), dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    if status < 0
        error("Error writing dataset")
    end
end

function h5e_set_auto(estack_id, func, client_data)
    status = ccall((:H5Eset_auto2, libhdf5), Int32, (Int64, Ptr{Nothing}, Ptr{Nothing}), estack_id, func, client_data)
    if status < 0
        error("Error setting error reporting behavior")
    end
end

function h5f_close(file_id)
    status = ccall((:H5Fclose, libhdf5), Int32, (Int64,), file_id)
    if status < 0
        error("Error closing file")
    end
end

function h5f_flush(object_id, scope)
    status = ccall((:H5Fflush, libhdf5), Int32, (Int64, Int32), object_id, scope)
    if status < 0
        error("Error flushing object to file")
    end
end

function hf5start_swmr_write(id)
    status = ccall((:H5Fstart_swmr_write, libhdf5), Int32, (Int64,), id)
    if status < 0
        error("Error starting SWMR write")
    end
end

function h5f_get_vfd_handle(file_id, fapl_id, file_handle)
    status = ccall((:H5Fget_vfd_handle, libhdf5), Int32, (Int64, Int64, Ptr{Ptr{Int32}}), file_id, fapl_id, file_handle)
    if status < 0
        error("Error getting VFD handle")
    end
end

function h5f_get_intend(file_id, intent)
    status = ccall((:H5Fget_intent, libhdf5), Int32, (Int64, Ptr{UInt32}), file_id, intent)
    if status < 0
        error("Error getting file intent")
    end
end

function h5g_close(group_id)
    status = ccall((:H5Gclose, libhdf5), Int32, (Int64,), group_id)
    if status < 0
        error("Error closing group")
    end
end

function h5g_get_info(group_id, buf)
    status = ccall((:H5Gget_info, libhdf5), Int32, (Int64, Ptr{HDF5.H5Ginfo}), group_id, buf)
    if status < 0
        error("Error getting group info")
    end
end

function h5o_get_info(object_id, buf)
    status = ccall((:H5Oget_info1, libhdf5), Int32, (Int64, Ptr{HDF5.H5Oinfo}), object_id, buf)
    if status < 0
        error("Error getting object info")
    end
end

function h5o_close(object_id)
    status = ccall((:H5Oclose, libhdf5), Int32, (Int64,), object_id)
    if status < 0
        error("Error closing object")
    end
end

function h5p_close(id)
    status = ccall((:H5Pclose, libhdf5), Int32, (Int64,), id)
    if status < 0
        error("Error closing property list")
    end
end

function h5p_get_alloc_time(plist_id, alloc_time)
    status = ccall((:H5Pget_alloc_time, libhdf5), Int32, (Int64, Ptr{Int32}), plist_id, alloc_time)
    if status < 0
        error("Error getting allocation timing")
    end
end

function h5p_get_dxpl_mpio(dxpl_id, xfer_mode)
    status = ccall((:H5Pget_dxpl_mpio, libhdf5), Int32, (Int64, Ptr{Int32}), dxpl_id, xfer_mode)
    if status < 0
        error("Error getting MPIO transfer mode")
    end
end

function h5p_get_fapl_mpio32(fapl_id, comm, info)
    status = ccall((:H5Pget_fapl_mpio, libhdf5), Int32, (Int64, Ptr{HDF5.Hmpih32}, Ptr{HDF5.Hmpih32}), fapl_id, comm, info)
    if status < 0
        error("Error getting MPIO properties")
    end
end

function h5p_get_fapl_mpio64(fapl_id, comm, info)
    status = ccall((:H5Pget_fapl_mpio, libhdf5), Int32, (Int64, Ptr{HDF5.Hmpih64}, Ptr{HDF5.Hmpih64}), fapl_id, comm, info)
    if status < 0
        error("Error getting MPIO properties")
    end
end

function h5p_get_fclose_degree(plist_id, fc_degree)
    status = ccall((:H5Pget_fclose_degree, libhdf5), Int32, (Int64, Ptr{Int32}), plist_id, fc_degree)
    if status < 0
        error("Error getting close degree")
    end
end

function h5p_get_userblock(plist_id, len)
    status = ccall((:H5Pget_userblock, libhdf5), Int32, (Int64, Ptr{UInt64}), plist_id, len)
    if status < 0
        error("Error getting userblock")
    end
end

function h5p_set_alloc_time(plist_id, alloc_time)
    status = ccall((:H5Pset_alloc_time, libhdf5), Int32, (Int64, Int32), plist_id, alloc_time)
    if status < 0
        error("Error setting allocation timing")
    end
end

function h5p_set_char_encoding(plist_id, encoding)
    status = ccall((:H5Pset_char_encoding, libhdf5), Int32, (Int64, Int32), plist_id, encoding)
    if status < 0
        error("Error setting char encoding")
    end
end

function h5p_set_chunk(plist_id, ndims, dims)
    status = ccall((:H5Pset_chunk, libhdf5), Int32, (Int64, Int32, Ptr{UInt64}), plist_id, ndims, dims)
    if status < 0
        error("Error setting chunk size")
    end
end

function h5p_set_create_intermediate_group(plist_id, setting)
    status = ccall((:H5Pset_create_intermediate_group, libhdf5), Int32, (Int64, UInt32), plist_id, setting)
    if status < 0
        error("Error setting create intermediate group")
    end
end

function h5p_set_external(plist_id, name, offset, size)
    status = ccall((:H5Pset_external, libhdf5), Int32, (Int64, Ptr{UInt8}, Int64, UInt64), plist_id, name, offset, size)
    if status < 0
        error("Error setting external property")
    end
end

function h5p_set_dxpl_mpio(dxpl_id, xfer_mode)
    status = ccall((:H5Pset_dxpl_mpio, libhdf5), Int32, (Int64, Int32), dxpl_id, xfer_mode)
    if status < 0
        error("Error setting MPIO transfer mode")
    end
end

function h5p_set_fapl_mpio32(fapl_id, comm, info)
    status = ccall((:H5Pset_fapl_mpio, libhdf5), Int32, (Int64, HDF5.Hmpih32, HDF5.Hmpih32), fapl_id, comm, info)
    if status < 0
        error("Error setting MPIO properties")
    end
end

function h5p_set_fapl_mpio64(fapl_id, comm, info)
    status = ccall((:H5Pset_fapl_mpio, libhdf5), Int32, (Int64, HDF5.Hmpih64, HDF5.Hmpih64), fapl_id, comm, info)
    if status < 0
        error("Error setting MPIO properties")
    end
end

function h5p_set_fclose_degree(plist_id, fc_degree)
    status = ccall((:H5Pset_fclose_degree, libhdf5), Int32, (Int64, Int32), plist_id, fc_degree)
    if status < 0
        error("Error setting close degree")
    end
end

function h5p_set_deflate(plist_id, setting)
    status = ccall((:H5Pset_deflate, libhdf5), Int32, (Int64, UInt32), plist_id, setting)
    if status < 0
        error("Error setting compression method and level (deflate)")
    end
end

function h5p_set_layout(plist_id, setting)
    status = ccall((:H5Pset_layout, libhdf5), Int32, (Int64, Int32), plist_id, setting)
    if status < 0
        error("Error setting layout")
    end
end

function h5p_set_libver_bounds(fapl_id, libver_low, libver_high)
    status = ccall((:H5Pset_libver_bounds, libhdf5), Int32, (Int64, Int32, Int32), fapl_id, libver_low, libver_high)
    if status < 0
        error("Error setting library version bounds")
    end
end

function h5p_set_local_heap_size_hint(fapl_id, size_hint)
    status = ccall((:H5Pset_local_heap_size_hint, libhdf5), Int32, (Int64, UInt32), fapl_id, size_hint)
    if status < 0
        error("Error setting local heap size hint")
    end
end

function h5p_set_shuffle(plist_id)
    status = ccall((:H5Pset_shuffle, libhdf5), Int32, (Int64,), plist_id)
    if status < 0
        error("Error enabling shuffle filter")
    end
end

function h5p_set_userblock(plist_id, len)
    status = ccall((:H5Pset_userblock, libhdf5), Int32, (Int64, UInt64), plist_id, len)
    if status < 0
        error("Error setting userblock")
    end
end

function h5p_set_obj_track_times(plist_id, track_times)
    status = ccall((:H5Pset_obj_track_times, libhdf5), Int32, (Int64, UInt8), plist_id, track_times)
    if status < 0
        error("Error setting object time tracking")
    end
end

function h5p_get_alignment(plist_id, threshold, alignment)
    status = ccall((:H5Pget_alignment, libhdf5), Int32, (Int64, Ptr{UInt64}, Ptr{UInt64}), plist_id, threshold, alignment)
    if status < 0
        error("Error getting alignment")
    end
end

function h5p_set_alignment(plist_id, threshold, alignment)
    status = ccall((:H5Pset_alignment, libhdf5), Int32, (Int64, UInt64, UInt64), plist_id, threshold, alignment)
    if status < 0
        error("Error setting alignment")
    end
end

function h5s_close(space_id)
    status = ccall((:H5Sclose, libhdf5), Int32, (Int64,), space_id)
    if status < 0
        error("Error closing dataspace")
    end
end

function h5s_select_hyperslab(dspace_id, seloper, start, stride, count, block)
    status = ccall((:H5Sselect_hyperslab, libhdf5), Int32, (Int64, Int32, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}, Ptr{UInt64}), dspace_id, seloper, start, stride, count, block)
    if status < 0
        error("Error selecting hyperslab")
    end
end

function h5t_commit(loc_id, name, dtype_id, lcpl_id, tcpl_id, tapl_id)
    status = ccall((:H5Tcommit2, libhdf5), Int32, (Int64, Ptr{UInt8}, Int64, Int64, Int64, Int64), loc_id, name, dtype_id, lcpl_id, tcpl_id, tapl_id)
    if status < 0
        error("Error committing type")
    end
end

function h5t_close(dtype_id)
    status = ccall((:H5Tclose, libhdf5), Int32, (Int64,), dtype_id)
    if status < 0
        error("Error closing datatype")
    end
end

function h5t_set_cset(dtype_id, cset)
    status = ccall((:H5Tset_cset, libhdf5), Int32, (Int64, Int32), dtype_id, cset)
    if status < 0
        error("Error setting character set in datatype")
    end
end

function h5t_set_size(dtype_id, sz)
    status = ccall((:H5Tset_size, libhdf5), Int32, (Int64, UInt64), dtype_id, sz)
    if status < 0
        error("Error setting size of datatype")
    end
end

function h5t_set_strpad(dtype_id, sz)
    status = ccall((:H5Tset_strpad, libhdf5), Int32, (Int64, Int32), dtype_id, sz)
    if status < 0
        error("Error setting size of datatype")
    end
end

function h5t_set_precision(dtype_id, sz)
    status = ccall((:H5Tset_precision, libhdf5), Int32, (Int64, UInt64), dtype_id, sz)
    if status < 0
        error("Error setting precision of datatype")
    end
end

function h5a_create(loc_id, pathname, type_id, space_id, acpl_id, aapl_id)
    ret = ccall((:H5Acreate2, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64, Int64, Int64, Int64), loc_id, pathname, type_id, space_id, acpl_id, aapl_id)
    if ret < 0
        error("Error creating attribute ", h5a_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5a_create_by_name(loc_id, obj_name, attr_name, type_id, space_id, acpl_id, aapl_id, lapl_id)
    ret = ccall((:H5Acreate_by_name, libhdf5), Int64, (Int64, Ptr{UInt8}, Ptr{UInt8}, Int64, Int64, Int64, Int64, Int64), loc_id, obj_name, attr_name, type_id, space_id, acpl_id, aapl_id, lapl_id)
    if ret < 0
        error("Error creating attribute ", attr_name, " for object ", obj_name)
    end
    return ret
end

function h5a_delete(loc_id, attr_name)
    ret = ccall((:H5Adelete, libhdf5), Int32, (Int64, Ptr{UInt8}), loc_id, attr_name)
    if ret < 0
        error("Error deleting attribute ", attr_name)
    end
    return ret
end

function h5a_delete_by_idx(loc_id, obj_name, idx_type, order, n, lapl_id)
    ret = ccall((:H5delete_by_idx, libhdf5), Int32, (Int64, Ptr{UInt8}, Int32, Int32, UInt64, Int64), loc_id, obj_name, idx_type, order, n, lapl_id)
    if ret < 0
        error("Error deleting attribute ", n, " from object ", obj_name)
    end
    return ret
end

function h5a_delete_by_name(loc_id, obj_name, attr_name, lapl_id)
    ret = ccall((:H5delete_by_name, libhdf5), Int32, (Int64, Ptr{UInt8}, Ptr{UInt8}, Int64), loc_id, obj_name, attr_name, lapl_id)
    if ret < 0
        error("Error removing attribute ", attr_name, " from object ", obj_name)
    end
    return ret
end

function h5a_get_create_plist(attr_id)
    ret = ccall((:H5Aget_create_plist, libhdf5), Int64, (Int64,), attr_id)
    if ret < 0
        error("Cannot get creation property list")
    end
    return ret
end

function h5a_get_name(attr_id, buf_size, buf)
    ret = ccall((:H5Aget_name, libhdf5), Int64, (Int64, UInt64, Ptr{UInt8}), attr_id, buf_size, buf)
    if ret < 0
        error("Error getting attribute name")
    end
    return ret
end

function h5a_get_name_by_idx(loc_id, obj_name, index_type, order, idx, name, size, lapl_id)
    ret = ccall((:H5Aget_name_by_idx, libhdf5), Int64, (Int64, Ptr{UInt8}, Int32, Int32, UInt64, Ptr{UInt8}, UInt64, Int64), loc_id, obj_name, index_type, order, idx, name, size, lapl_id)
    if ret < 0
        error("Error getting attribute name")
    end
    return ret
end

function h5a_get_space(attr_id)
    ret = ccall((:H5Aget_space, libhdf5), Int64, (Int64,), attr_id)
    if ret < 0
        error("Error getting attribute dataspace")
    end
    return ret
end

function h5a_get_type(attr_id)
    ret = ccall((:H5Aget_type, libhdf5), Int64, (Int64,), attr_id)
    if ret < 0
        error("Error getting attribute type")
    end
    return ret
end

function h5a_open(obj_id, pathname, aapl_id)
    ret = ccall((:H5Aopen, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64), obj_id, pathname, aapl_id)
    if ret < 0
        error("Error opening attribute ", h5i_get_name(obj_id), "/", pathname)
    end
    return ret
end

function h5a_read(attr_id, mem_type_id, buf)
    ret = ccall((:H5Aread, libhdf5), Int32, (Int64, Int64, Ptr{Nothing}), attr_id, mem_type_id, buf)
    if ret < 0
        error("Error reading attribute ", h5a_get_name(attr_id))
    end
    return ret
end

function h5d_create(loc_id, pathname, dtype_id, space_id, lcpl_id, dcpl_id, dapl_id)
    ret = ccall((:H5Dcreate2, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64, Int64, Int64, Int64, Int64), loc_id, pathname, dtype_id, space_id, lcpl_id, dcpl_id, dapl_id)
    if ret < 0
        error("Error creating dataset ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5d_get_access_plist(dataset_id)
    ret = ccall((:H5Dget_access_plist, libhdf5), Int64, (Int64,), dataset_id)
    if ret < 0
        error("Error getting dataset access property list")
    end
    return ret
end

function h5d_get_create_plist(dataset_id)
    ret = ccall((:H5Dget_create_plist, libhdf5), Int64, (Int64,), dataset_id)
    if ret < 0
        error("Error getting dataset create property list")
    end
    return ret
end

function h5d_get_offset(dataset_id)
    ret = ccall((:H5Dget_offset, libhdf5), UInt64, (Int64,), dataset_id)
    if ret < 0
        error("Error getting offset")
    end
    return ret
end

function h5d_get_space(dataset_id)
    ret = ccall((:H5Dget_space, libhdf5), Int64, (Int64,), dataset_id)
    if ret < 0
        error("Error getting dataspace")
    end
    return ret
end

function h5d_get_type(dataset_id)
    ret = ccall((:H5Dget_type, libhdf5), Int64, (Int64,), dataset_id)
    if ret < 0
        error("Error getting dataspace type")
    end
    return ret
end

function h5d_open(loc_id, pathname, dapl_id)
    ret = ccall((:H5Dopen2, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64), loc_id, pathname, dapl_id)
    if ret < 0
        error("Error opening dataset ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5d_read(dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    ret = ccall((:H5Dread, libhdf5), Int32, (Int64, Int64, Int64, Int64, Int64, Ptr{Nothing}), dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    if ret < 0
        error("Error reading dataset ", h5i_get_name(dataset_id))
    end
    return ret
end

function h5f_create(pathname, flags, fcpl_id, fapl_id)
    ret = ccall((:H5Fcreate, libhdf5), Int64, (Ptr{UInt8}, UInt32, Int64, Int64), pathname, flags, fcpl_id, fapl_id)
    if ret < 0
        error("Error creating file ", pathname)
    end
    return ret
end

function h5f_get_access_plist(file_id)
    ret = ccall((:H5Fget_access_plist, libhdf5), Int64, (Int64,), file_id)
    if ret < 0
        error("Error getting file access property list")
    end
    return ret
end

function h5f_get_create_plist(file_id)
    ret = ccall((:H5Fget_create_plist, libhdf5), Int64, (Int64,), file_id)
    if ret < 0
        error("Error getting file create property list")
    end
    return ret
end

function h5f_get_name(obj_id, buf, buf_size)
    ret = ccall((:H5Fget_name, libhdf5), Int64, (Int64, Ptr{UInt8}, UInt64), obj_id, buf, buf_size)
    if ret < 0
        error("Error getting file name")
    end
    return ret
end

function h5f_open(pathname, flags, fapl_id)
    ret = ccall((:H5Fopen, libhdf5), Int64, (Cstring, UInt32, Int64), pathname, flags, fapl_id)
    if ret < 0
        error("Error opening file ", pathname)
    end
    return ret
end

function h5g_create(loc_id, pathname, lcpl_id, gcpl_id, gapl_id)
    ret = ccall((:H5Gcreate2, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64, Int64, Int64), loc_id, pathname, lcpl_id, gcpl_id, gapl_id)
    if ret < 0
        error("Error creating group ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5g_get_create_plist(group_id)
    ret = ccall((:H5Gget_create_plist, libhdf5), Int64, (Int64,), group_id)
    if ret < 0
        error("Error getting group create property list")
    end
    return ret
end

function h5g_get_objname_by_idx(loc_id, idx, pathname, size)
    ret = ccall((:H5Gget_objname_by_idx, libhdf5), Int64, (Int64, UInt64, Ptr{UInt8}, UInt64), loc_id, idx, pathname, size)
    if ret < 0
        error("Error getting group object name ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5g_get_num_objs(loc_id, num_obj)
    ret = ccall((:H5Gget_num_objs, libhdf5), Int64, (Int64, Ptr{UInt64}), loc_id, num_obj)
    if ret < 0
        error("Error getting group length")
    end
    return ret
end

function h5g_open(loc_id, pathname, gapl_id)
    ret = ccall((:H5Gopen2, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64), loc_id, pathname, gapl_id)
    if ret < 0
        error("Error opening group ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5i_get_file_id(obj_id)
    ret = ccall((:H5Iget_file_id, libhdf5), Int64, (Int64,), obj_id)
    if ret < 0
        error("Error getting file identifier")
    end
    return ret
end

function h5i_get_name(obj_id, buf, buf_size)
    ret = ccall((:H5Iget_name, libhdf5), Int64, (Int64, Ptr{UInt8}, UInt64), obj_id, buf, buf_size)
    if ret < 0
        error("Error getting object name")
    end
    return ret
end

function h5i_get_ref(obj_id)
    ret = ccall((:H5Iget_ref, libhdf5), Int32, (Int64,), obj_id)
    if ret < 0
        error("Error getting reference count")
    end
    return ret
end

function h5i_get_type(obj_id)
    ret = ccall((:H5Iget_type, libhdf5), Int32, (Int64,), obj_id)
    if ret < 0
        error("Error getting type")
    end
    return ret
end

function h5i_dec_ref(obj_id)
    ret = ccall((:H5Idec_ref, libhdf5), Int32, (Int64,), obj_id)
    if ret < 0
        error("Error decementing reference")
    end
    return ret
end

function h5l_delete(obj_id, pathname, lapl_id)
    ret = ccall((:H5Ldelete, libhdf5), Int32, (Int64, Ptr{UInt8}, Int64), obj_id, pathname, lapl_id)
    if ret < 0
        error("Error deleting ", h5i_get_name(obj_id), "/", pathname)
    end
    return ret
end

function h5l_create_external(target_file_name, target_obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    ret = ccall((:H5Lcreate_external, libhdf5), Int32, (Ptr{UInt8}, Ptr{UInt8}, Int64, Ptr{UInt8}, Int64, Int64), target_file_name, target_obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    if ret < 0
        error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name)
    end
    return ret
end

function h5l_create_hard(obj_loc_id, obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    ret = ccall((:H5Lcreate_hard, libhdf5), Int32, (Int64, Ptr{UInt8}, Int64, Ptr{UInt8}, Int64, Int64), obj_loc_id, obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    if ret < 0
        error("Error creating hard link ", link_name, " pointing to ", obj_name)
    end
    return ret
end

function h5l_create_soft(target_path, link_loc_id, link_name, lcpl_id, lapl_id)
    ret = ccall((:H5Lcreate_soft, libhdf5), Int32, (Ptr{UInt8}, Int64, Ptr{UInt8}, Int64, Int64), target_path, link_loc_id, link_name, lcpl_id, lapl_id)
    if ret < 0
        error("Error creating soft link ", link_name, " pointing to ", target_path)
    end
    return ret
end

function h5l_get_info(link_loc_id, link_name, link_buf, lapl_id)
    ret = ccall((:H5Lget_info, libhdf5), Int32, (Int64, Ptr{UInt8}, Ptr{HDF5.H5LInfo}, Int64), link_loc_id, link_name, link_buf, lapl_id)
    if ret < 0
        error("Error getting info for link ", link_name)
    end
    return ret
end

function h5o_open(loc_id, pathname, lapl_id)
    ret = ccall((:H5Oopen, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64), loc_id, pathname, lapl_id)
    if ret < 0
        error("Error opening object ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5o_open_by_idx(loc_id, group_name, index_type, order, n, lapl_id)
    ret = ccall((:H5Oopen_by_idx, libhdf5), Int64, (Int64, Ptr{UInt8}, Int32, Int32, UInt64, Int64), loc_id, group_name, index_type, order, n, lapl_id)
    if ret < 0
        error("Error opening object of index ", n)
    end
    return ret
end

function h5o_open_by_addr(loc_id, addr)
    ret = ccall((:H5Oopen_by_addr, libhdf5), Int64, (Int64, UInt64), loc_id, addr)
    if ret < 0
        error("Error opening object by address")
    end
    return ret
end

function h5o_copy(src_loc_id, src_name, dst_loc_id, dst_name, ocpypl_id, lcpl_id)
    ret = ccall((:H5Ocopy, libhdf5), Int32, (Int64, Ptr{UInt8}, Int64, Ptr{UInt8}, Int64, Int64), src_loc_id, src_name, dst_loc_id, dst_name, ocpypl_id, lcpl_id)
    if ret < 0
        error("Error copying object ", h5i_get_name(src_loc_id), "/", src_name, " to ", h5i_get_name(dst_loc_id), "/", dst_name)
    end
    return ret
end

function h5p_create(cls_id)
    ret = ccall((:H5Pcreate, libhdf5), Int64, (Int64,), cls_id)
    if ret < 0
        "Error creating property list"
    end
    return ret
end

function h5p_get_chunk(plist_id, n_dims, dims)
    ret = ccall((:H5Pget_chunk, libhdf5), Int32, (Int64, Int32, Ptr{UInt64}), plist_id, n_dims, dims)
    if ret < 0
        error("Error getting chunk size")
    end
    return ret
end

function h5p_get_layout(plist_id)
    ret = ccall((:H5Pget_layout, libhdf5), Int32, (Int64,), plist_id)
    if ret < 0
        error("Error getting layout")
    end
    return ret
end

function h5p_get_driver_info(plist_id)
    ret = ccall((:H5Pget_driver_info, libhdf5), Ptr{Nothing}, (Int64,), plist_id)
    if ret < 0
        "Error getting driver info"
    end
    return ret
end

function h5p_get_driver(plist_id)
    ret = ccall((:H5Pget_driver, libhdf5), Int64, (Int64,), plist_id)
    if ret < 0
        "Error getting driver identifier"
    end
    return ret
end

function h5r_create(ref, loc_id, pathname, ref_type, space_id)
    ret = ccall((:H5Rcreate, libhdf5), Int32, (Ptr{HDF5.HDF5ReferenceObj}, Int64, Ptr{UInt8}, Int32, Int64), ref, loc_id, pathname, ref_type, space_id)
    if ret < 0
        error("Error creating reference to object ", hi5_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5r_get_obj_type(loc_id, ref_type, ref, obj_type)
    ret = ccall((:H5Rget_obj_type2, libhdf5), Int32, (Int64, Int32, Ptr{Nothing}, Ptr{Int32}), loc_id, ref_type, ref, obj_type)
    if ret < 0
        error("Error getting object type")
    end
    return ret
end

function h5r_get_region(loc_id, ref_type, ref)
    ret = ccall((:H5Rget_region, libhdf5), Int64, (Int64, Int32, Ptr{Nothing}), loc_id, ref_type, ref)
    if ret < 0
        error("Error getting region from reference")
    end
    return ret
end

function h5s_copy(space_id)
    ret = ccall((:H5Scopy, libhdf5), Int64, (Int64,), space_id)
    if ret < 0
        error("Error copying dataspace")
    end
    return ret
end

function h5s_create(class)
    ret = ccall((:H5Screate, libhdf5), Int64, (Int32,), class)
    if ret < 0
        error("Error creating dataspace")
    end
    return ret
end

function h5s_create_simple(rank, current_dims, maximum_dims)
    ret = ccall((:H5Screate_simple, libhdf5), Int64, (Int32, Ptr{UInt64}, Ptr{UInt64}), rank, current_dims, maximum_dims)
    if ret < 0
        error("Error creating simple dataspace")
    end
    return ret
end

function h5s_get_simple_extent_dims(space_id, dims, maxdims)
    ret = ccall((:H5Sget_simple_extent_dims, libhdf5), Int32, (Int64, Ptr{UInt64}, Ptr{UInt64}), space_id, dims, maxdims)
    if ret < 0
        error("Error getting the dimensions for a dataspace")
    end
    return ret
end

function h5s_get_simple_extent_ndims(space_id)
    ret = ccall((:H5Sget_simple_extent_ndims, libhdf5), Int32, (Int64,), space_id)
    if ret < 0
        error("Error getting the number of dimensions for a dataspace")
    end
    return ret
end

function h5s_get_simple_extent_type(space_id)
    ret = ccall((:H5Sget_simple_extent_type, libhdf5), Int32, (Int64,), space_id)
    if ret < 0
        error("Error getting the dataspace type")
    end
    return ret
end

function h5t_array_create(basetype_id, ndims, sz)
    ret = ccall((:H5Tarray_create2, libhdf5), Int64, (Int64, UInt32, Ptr{UInt64}), basetype_id, ndims, sz)
    if ret < 0
        error("Error creating H5T_ARRAY of id ", basetype_id, " and size ", sz)
    end
    return ret
end

function h5t_copy(dtype_id)
    ret = ccall((:H5Tcopy, libhdf5), Int64, (Int64,), dtype_id)
    if ret < 0
        error("Error copying datatype")
    end
    return ret
end

function h5t_create(class_id, sz)
    ret = ccall((:H5Tcreate, libhdf5), Int64, (Int32, UInt64), class_id, sz)
    if ret < 0
        error("Error creating datatype of id ", class_id)
    end
    return ret
end

function h5t_equal(dtype_id1, dtype_id2)
    ret = ccall((:H5Tequal, libhdf5), Int64, (Int64, Int64), dtype_id1, dtype_id2)
    if ret < 0
        error("Error checking datatype equality")
    end
    return ret
end

function h5t_get_array_dims(dtype_id, dims)
    ret = ccall((:H5Tget_array_dims2, libhdf5), Int32, (Int64, Ptr{UInt64}), dtype_id, dims)
    if ret < 0
        error("Error getting dimensions of array")
    end
    return ret
end

function h5t_get_array_ndims(dtype_id)
    ret = ccall((:H5Tget_array_ndims, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error getting ndims of array")
    end
    return ret
end

function h5t_get_class(dtype_id)
    ret = ccall((:H5Tget_class, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error getting class")
    end
    return ret
end

function h5t_get_cset(dtype_id)
    ret = ccall((:H5Tget_cset, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error getting character set encoding")
    end
    return ret
end

function h5t_get_member_class(dtype_id, index)
    ret = ccall((:H5Tget_member_class, libhdf5), Int32, (Int64, UInt32), dtype_id, index)
    if ret < 0
        error("Error getting class of compound datatype member #", index)
    end
    return ret
end

function h5t_get_member_index(dtype_id, membername)
    ret = ccall((:H5Tget_member_index, libhdf5), Int32, (Int64, Ptr{UInt8}), dtype_id, membername)
    if ret < 0
        error("Error getting index of compound datatype member \"", membername, "\"")
    end
    return ret
end

function h5t_get_member_offset(dtype_id, index)
    ret = ccall((:H5Tget_member_offset, libhdf5), UInt64, (Int64, UInt32), dtype_id, index)
    if ret < 0
        error("Error getting offset of compound datatype member #", index)
    end
    return ret
end

function h5t_get_member_type(dtype_id, index)
    ret = ccall((:H5Tget_member_type, libhdf5), Int64, (Int64, UInt32), dtype_id, index)
    if ret < 0
        error("Error getting type of compound datatype member #", index)
    end
    return ret
end

function h5t_get_native_type(dtype_id, direction)
    ret = ccall((:H5Tget_native_type, libhdf5), Int64, (Int64, Int32), dtype_id, direction)
    if ret < 0
        error("Error getting native type")
    end
    return ret
end

function h5t_get_nmembers(dtype_id)
    ret = ccall((:H5Tget_nmembers, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error getting the number of members")
    end
    return ret
end

function h5t_get_sign(dtype_id)
    ret = ccall((:H5Tget_sign, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error getting sign")
    end
    return ret
end

function h5t_get_size(dtype_id)
    ret = ccall((:H5Tget_size, libhdf5), UInt64, (Int64,), dtype_id)
    if ret < 0
        error("Error getting size")
    end
    return ret
end

function h5t_get_super(dtype_id)
    ret = ccall((:H5Tget_super, libhdf5), Int64, (Int64,), dtype_id)
    if ret < 0
        error("Error getting super type")
    end
    return ret
end

function h5t_get_strpad(dtype_id)
    ret = ccall((:H5Tget_strpad, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error getting string padding")
    end
    return ret
end

function h5t_insert(dtype_id, fieldname, offset, field_id)
    ret = ccall((:H5Tinsert, libhdf5), Int32, (Int64, Ptr{UInt8}, UInt64, Int64), dtype_id, fieldname, offset, field_id)
    if ret < 0
        error("Error adding field ", fieldname, " to compound datatype")
    end
    return ret
end

function h5t_open(loc_id, name, tapl_id)
    ret = ccall((:H5Topen2, libhdf5), Int64, (Int64, Ptr{UInt8}, Int64), loc_id, name, tapl_id)
    if ret < 0
        error("Error opening type ", h5i_get_name(loc_id), "/", name)
    end
    return ret
end

function h5t_vlen_create(base_type_id)
    ret = ccall((:H5Tvlen_create, libhdf5), Int64, (Int64,), base_type_id)
    if ret < 0
        error("Error creating vlen type")
    end
    return ret
end

function h5a_exists(obj_id, attr_name)
    ret = ccall((:H5Aexists, libhdf5), Int32, (Int64, Ptr{UInt8}), obj_id, attr_name)
    if ret < 0
        error("Error checking whether attribute ", attr_name, " exists")
    end
    return ret > 0
end

function h5a_exists_by_name(loc_id, obj_name, attr_name, lapl_id)
    ret = ccall((:H5Aexists_by_name, libhdf5), Int32, (Int64, Ptr{UInt8}, Ptr{UInt8}, Int64), loc_id, obj_name, attr_name, lapl_id)
    if ret < 0
        error("Error checking whether object ", obj_name, " has attribute ", attr_name)
    end
    return ret > 0
end

function h5f_is_hdf5(pathname)
    ret = ccall((:H5Fis_hdf5, libhdf5), Int32, (Cstring,), pathname)
    if ret < 0
        error("Cannot access file ", pathname)
    end
    return ret > 0
end

function h5i_is_valid(obj_id)
    ret = ccall((:H5Iis_valid, libhdf5), Int32, (Int64,), obj_id)
    if ret < 0
        error("Cannot determine whether object is valid")
    end
    return ret > 0
end

function h5l_exists(loc_id, pathname, lapl_id)
    ret = ccall((:H5Lexists, libhdf5), Int32, (Int64, Ptr{UInt8}, Int64), loc_id, pathname, lapl_id)
    if ret < 0
        error("Cannot determine whether ", pathname, " exists")
    end
    return ret > 0
end

function h5s_is_simple(space_id)
    ret = ccall((:H5Sis_simple, libhdf5), Int32, (Int64,), space_id)
    if ret < 0
        error("Error determining whether dataspace is simple")
    end
    return ret > 0
end

function h5t_is_variable_str(type_id)
    ret = ccall((:H5Tis_variable_str, libhdf5), Int32, (Int64,), type_id)
    if ret < 0
        error("Error determining whether string is of variable length")
    end
    return ret > 0
end

function h5t_committed(dtype_id)
    ret = ccall((:H5Tcommitted, libhdf5), Int32, (Int64,), dtype_id)
    if ret < 0
        error("Error determining whether datatype is committed")
    end
    return ret > 0
end

