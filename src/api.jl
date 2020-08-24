function h5_close()
    status = ccall((:H5close, libhdf5), Herr, ())
    if status < 0
        error("Error closing the HDF5 resources")
    end
    return nothing
end

function h5_dont_atexit()
    status = ccall((:H5dont_atexit, libhdf5), Herr, ())
    if status < 0
        error("Error calling dont_atexit")
    end
    return nothing
end

function h5_garbage_collect()
    status = ccall((:H5garbage_collect, libhdf5), Herr, ())
    if status < 0
        error("Error on garbage collect")
    end
    return nothing
end

function h5_open()
    status = ccall((:H5open, libhdf5), Herr, ())
    if status < 0
        error("Error initializing the HDF5 library")
    end
    return nothing
end

function h5_set_free_list_limits(reg_global_lim, reg_list_lim, arr_global_lim, arr_list_lim, blk_global_lim, blk_list_lim)
    status = ccall((:H5set_free_list_limits, libhdf5), Herr, (Cint, Cint, Cint, Cint, Cint, Cint), reg_global_lim, reg_list_lim, arr_global_lim, arr_list_lim, blk_global_lim, blk_list_lim)
    if status < 0
        error("Error setting limits on free lists")
    end
    return nothing
end

function h5a_close(id)
    status = ccall((:H5Aclose, libhdf5), Herr, (Hid,), id)
    if status < 0
        error("Error closing attribute")
    end
    return nothing
end

function h5a_write(attr_hid, mem_type_id, buf)
    status = ccall((:H5Awrite, libhdf5), Herr, (Hid, Hid, Ptr{Cvoid}), attr_hid, mem_type_id, buf)
    if status < 0
        error("Error writing attribute data")
    end
    return nothing
end

function h5d_close(dataset_id)
    status = ccall((:H5Dclose, libhdf5), Herr, (Hid,), dataset_id)
    if status < 0
        error("Error closing dataset")
    end
    return nothing
end

function h5d_flush(dataset_id)
    status = ccall((:H5Dflush, libhdf5), Herr, (Hid,), dataset_id)
    if status < 0
        error("Error flushing dataset")
    end
    return nothing
end

function h5d_oappend(dset_id, dxpl_id, index, num_elem, memtype, buffer)
    status = ccall((:H5DOappend, libhdf5_hl), Herr, (Hid, Hid, Cuint, Hsize, Hid, Ptr{Cvoid}), dset_id, dxpl_id, index, num_elem, memtype, buffer)
    if status < 0
        error("error appending")
    end
    return nothing
end

function h5do_write_chunk(dset_id, dxpl_id, filter_mask, offset, bufsize, buf)
    status = ccall((:H5DOwrite_chunk, libhdf5_hl), Herr, (Hid, Hid, Int32, Ptr{Hsize}, Csize_t, Ptr{Cvoid}), dset_id, dxpl_id, filter_mask, offset, bufsize, buf)
    if status < 0
        error("Error writing chunk")
    end
    return nothing
end

function h5d_refresh(dataset_id)
    status = ccall((:H5Drefresh, libhdf5), Herr, (Hid,), dataset_id)
    if status < 0
        error("Error refreshing dataset")
    end
    return nothing
end

function h5d_set_extent(dataset_id, new_dims)
    status = ccall((:H5Dset_extent, libhdf5), Herr, (Hid, Ptr{Hsize}), dataset_id, new_dims)
    if status < 0
        error("Error extending dataset dimensions")
    end
    return nothing
end

function h5d_vlen_get_buf_size(dset_id, type_id, space_id, buf)
    status = ccall((:H5Dvlen_get_buf_size, libhdf5), Herr, (Hid, Hid, Hid, Ptr{Hsize}), dset_id, type_id, space_id, buf)
    if status < 0
        error("Error getting vlen buffer size")
    end
    return nothing
end

function h5d_vlen_reclaim(type_id, space_id, plist_id, buf)
    status = ccall((:H5Dvlen_reclaim, libhdf5), Herr, (Hid, Hid, Hid, Ptr{Cvoid}), type_id, space_id, plist_id, buf)
    if status < 0
        error("Error reclaiming vlen buffer")
    end
    return nothing
end

function h5d_write(dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    status = ccall((:H5Dwrite, libhdf5), Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Cvoid}), dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    if status < 0
        error("Error writing dataset")
    end
    return nothing
end

function h5e_set_auto(estack_id, func, client_data)
    status = ccall((:H5Eset_auto2, libhdf5), Herr, (Hid, Ptr{Cvoid}, Ptr{Cvoid}), estack_id, func, client_data)
    if status < 0
        error("Error setting error reporting behavior")
    end
    return nothing
end

function h5f_close(file_id)
    status = ccall((:H5Fclose, libhdf5), Herr, (Hid,), file_id)
    if status < 0
        error("Error closing file")
    end
    return nothing
end

function h5f_flush(object_id, scope)
    status = ccall((:H5Fflush, libhdf5), Herr, (Hid, Cint), object_id, scope)
    if status < 0
        error("Error flushing object to file")
    end
    return nothing
end

function hf5start_swmr_write(id)
    status = ccall((:H5Fstart_swmr_write, libhdf5), Herr, (Hid,), id)
    if status < 0
        error("Error starting SWMR write")
    end
    return nothing
end

function h5f_get_vfd_handle(file_id, fapl_id, file_handle)
    status = ccall((:H5Fget_vfd_handle, libhdf5), Herr, (Hid, Hid, Ptr{Ptr{Cint}}), file_id, fapl_id, file_handle)
    if status < 0
        error("Error getting VFD handle")
    end
    return nothing
end

function h5f_get_intend(file_id, intent)
    status = ccall((:H5Fget_intent, libhdf5), Herr, (Hid, Ptr{Cuint}), file_id, intent)
    if status < 0
        error("Error getting file intent")
    end
    return nothing
end

function h5g_close(group_id)
    status = ccall((:H5Gclose, libhdf5), Herr, (Hid,), group_id)
    if status < 0
        error("Error closing group")
    end
    return nothing
end

function h5g_get_info(group_id, buf)
    status = ccall((:H5Gget_info, libhdf5), Herr, (Hid, Ptr{H5Ginfo}), group_id, buf)
    if status < 0
        error("Error getting group info")
    end
    return nothing
end

function h5o_get_info(object_id, buf)
    status = ccall((:H5Oget_info1, libhdf5), Herr, (Hid, Ptr{H5Oinfo}), object_id, buf)
    if status < 0
        error("Error getting object info")
    end
    return nothing
end

function h5o_close(object_id)
    status = ccall((:H5Oclose, libhdf5), Herr, (Hid,), object_id)
    if status < 0
        error("Error closing object")
    end
    return nothing
end

function h5p_close(id)
    status = ccall((:H5Pclose, libhdf5), Herr, (Hid,), id)
    if status < 0
        error("Error closing property list")
    end
    return nothing
end

function h5p_get_alloc_time(plist_id, alloc_time)
    status = ccall((:H5Pget_alloc_time, libhdf5), Herr, (Hid, Ptr{Cint}), plist_id, alloc_time)
    if status < 0
        error("Error getting allocation timing")
    end
    return nothing
end

function h5p_get_dxpl_mpio(dxpl_id, xfer_mode)
    status = ccall((:H5Pget_dxpl_mpio, libhdf5), Herr, (Hid, Ptr{Cint}), dxpl_id, xfer_mode)
    if status < 0
        error("Error getting MPIO transfer mode")
    end
    return nothing
end

function h5p_get_fapl_mpio32(fapl_id, comm, info)
    status = ccall((:H5Pget_fapl_mpio, libhdf5), Herr, (Hid, Ptr{Hmpih32}, Ptr{Hmpih32}), fapl_id, comm, info)
    if status < 0
        error("Error getting MPIO properties")
    end
    return nothing
end

function h5p_get_fapl_mpio64(fapl_id, comm, info)
    status = ccall((:H5Pget_fapl_mpio, libhdf5), Herr, (Hid, Ptr{Hmpih64}, Ptr{Hmpih64}), fapl_id, comm, info)
    if status < 0
        error("Error getting MPIO properties")
    end
    return nothing
end

function h5p_get_fclose_degree(plist_id, fc_degree)
    status = ccall((:H5Pget_fclose_degree, libhdf5), Herr, (Hid, Ptr{Cint}), plist_id, fc_degree)
    if status < 0
        error("Error getting close degree")
    end
    return nothing
end

function h5p_get_userblock(plist_id, len)
    status = ccall((:H5Pget_userblock, libhdf5), Herr, (Hid, Ptr{Hsize}), plist_id, len)
    if status < 0
        error("Error getting userblock")
    end
    return nothing
end

function h5p_set_alloc_time(plist_id, alloc_time)
    status = ccall((:H5Pset_alloc_time, libhdf5), Herr, (Hid, Cint), plist_id, alloc_time)
    if status < 0
        error("Error setting allocation timing")
    end
    return nothing
end

function h5p_set_char_encoding(plist_id, encoding)
    status = ccall((:H5Pset_char_encoding, libhdf5), Herr, (Hid, Cint), plist_id, encoding)
    if status < 0
        error("Error setting char encoding")
    end
    return nothing
end

function h5p_set_chunk(plist_id, ndims, dims)
    status = ccall((:H5Pset_chunk, libhdf5), Herr, (Hid, Cint, Ptr{Hsize}), plist_id, ndims, dims)
    if status < 0
        error("Error setting chunk size")
    end
    return nothing
end

function h5p_set_create_intermediate_group(plist_id, setting)
    status = ccall((:H5Pset_create_intermediate_group, libhdf5), Herr, (Hid, Cuint), plist_id, setting)
    if status < 0
        error("Error setting create intermediate group")
    end
    return nothing
end

function h5p_set_external(plist_id, name, offset, size)
    status = ccall((:H5Pset_external, libhdf5), Herr, (Hid, Ptr{UInt8}, Int, Csize_t), plist_id, name, offset, size)
    if status < 0
        error("Error setting external property")
    end
    return nothing
end

function h5p_set_dxpl_mpio(dxpl_id, xfer_mode)
    status = ccall((:H5Pset_dxpl_mpio, libhdf5), Herr, (Hid, Cint), dxpl_id, xfer_mode)
    if status < 0
        error("Error setting MPIO transfer mode")
    end
    return nothing
end

function h5p_set_fapl_mpio32(fapl_id, comm, info)
    status = ccall((:H5Pset_fapl_mpio, libhdf5), Herr, (Hid, Hmpih32, Hmpih32), fapl_id, comm, info)
    if status < 0
        error("Error setting MPIO properties")
    end
    return nothing
end

function h5p_set_fapl_mpio64(fapl_id, comm, info)
    status = ccall((:H5Pset_fapl_mpio, libhdf5), Herr, (Hid, Hmpih64, Hmpih64), fapl_id, comm, info)
    if status < 0
        error("Error setting MPIO properties")
    end
    return nothing
end

function h5p_set_fclose_degree(plist_id, fc_degree)
    status = ccall((:H5Pset_fclose_degree, libhdf5), Herr, (Hid, Cint), plist_id, fc_degree)
    if status < 0
        error("Error setting close degree")
    end
    return nothing
end

function h5p_set_deflate(plist_id, setting)
    status = ccall((:H5Pset_deflate, libhdf5), Herr, (Hid, Cuint), plist_id, setting)
    if status < 0
        error("Error setting compression method and level (deflate)")
    end
    return nothing
end

function h5p_set_layout(plist_id, setting)
    status = ccall((:H5Pset_layout, libhdf5), Herr, (Hid, Cint), plist_id, setting)
    if status < 0
        error("Error setting layout")
    end
    return nothing
end

function h5p_set_libver_bounds(fapl_id, libver_low, libver_high)
    status = ccall((:H5Pset_libver_bounds, libhdf5), Herr, (Hid, Cint, Cint), fapl_id, libver_low, libver_high)
    if status < 0
        error("Error setting library version bounds")
    end
    return nothing
end

function h5p_set_local_heap_size_hint(fapl_id, size_hint)
    status = ccall((:H5Pset_local_heap_size_hint, libhdf5), Herr, (Hid, Cuint), fapl_id, size_hint)
    if status < 0
        error("Error setting local heap size hint")
    end
    return nothing
end

function h5p_set_shuffle(plist_id)
    status = ccall((:H5Pset_shuffle, libhdf5), Herr, (Hid,), plist_id)
    if status < 0
        error("Error enabling shuffle filter")
    end
    return nothing
end

function h5p_set_userblock(plist_id, len)
    status = ccall((:H5Pset_userblock, libhdf5), Herr, (Hid, Hsize), plist_id, len)
    if status < 0
        error("Error setting userblock")
    end
    return nothing
end

function h5p_set_obj_track_times(plist_id, track_times)
    status = ccall((:H5Pset_obj_track_times, libhdf5), Herr, (Hid, UInt8), plist_id, track_times)
    if status < 0
        error("Error setting object time tracking")
    end
    return nothing
end

function h5p_get_alignment(plist_id, threshold, alignment)
    status = ccall((:H5Pget_alignment, libhdf5), Herr, (Hid, Ptr{Hsize}, Ptr{Hsize}), plist_id, threshold, alignment)
    if status < 0
        error("Error getting alignment")
    end
    return nothing
end

function h5p_set_alignment(plist_id, threshold, alignment)
    status = ccall((:H5Pset_alignment, libhdf5), Herr, (Hid, Hsize, Hsize), plist_id, threshold, alignment)
    if status < 0
        error("Error setting alignment")
    end
    return nothing
end

function h5s_close(space_id)
    status = ccall((:H5Sclose, libhdf5), Herr, (Hid,), space_id)
    if status < 0
        error("Error closing dataspace")
    end
    return nothing
end

function h5s_select_hyperslab(dspace_id, seloper, start, stride, count, block)
    status = ccall((:H5Sselect_hyperslab, libhdf5), Herr, (Hid, Cint, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}), dspace_id, seloper, start, stride, count, block)
    if status < 0
        error("Error selecting hyperslab")
    end
    return nothing
end

function h5t_commit(loc_id, name, dtype_id, lcpl_id, tcpl_id, tapl_id)
    status = ccall((:H5Tcommit2, libhdf5), Herr, (Hid, Ptr{UInt8}, Hid, Hid, Hid, Hid), loc_id, name, dtype_id, lcpl_id, tcpl_id, tapl_id)
    if status < 0
        error("Error committing type")
    end
    return nothing
end

function h5t_close(dtype_id)
    status = ccall((:H5Tclose, libhdf5), Herr, (Hid,), dtype_id)
    if status < 0
        error("Error closing datatype")
    end
    return nothing
end

function h5t_set_cset(dtype_id, cset)
    status = ccall((:H5Tset_cset, libhdf5), Herr, (Hid, Cint), dtype_id, cset)
    if status < 0
        error("Error setting character set in datatype")
    end
    return nothing
end

function h5t_set_size(dtype_id, sz)
    status = ccall((:H5Tset_size, libhdf5), Herr, (Hid, Csize_t), dtype_id, sz)
    if status < 0
        error("Error setting size of datatype")
    end
    return nothing
end

function h5t_set_strpad(dtype_id, sz)
    status = ccall((:H5Tset_strpad, libhdf5), Herr, (Hid, Cint), dtype_id, sz)
    if status < 0
        error("Error setting size of datatype")
    end
    return nothing
end

function h5t_set_precision(dtype_id, sz)
    status = ccall((:H5Tset_precision, libhdf5), Herr, (Hid, Csize_t), dtype_id, sz)
    if status < 0
        error("Error setting precision of datatype")
    end
    return nothing
end

function h5a_create(loc_id, pathname, type_id, space_id, acpl_id, aapl_id)
    ret = ccall((:H5Acreate2, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid, Hid, Hid, Hid), loc_id, pathname, type_id, space_id, acpl_id, aapl_id)
    if ret < 0
        error("Error creating attribute ", h5a_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5a_create_by_name(loc_id, obj_name, attr_name, type_id, space_id, acpl_id, aapl_id, lapl_id)
    ret = ccall((:H5Acreate_by_name, libhdf5), Hid, (Hid, Ptr{UInt8}, Ptr{UInt8}, Hid, Hid, Hid, Hid, Hid), loc_id, obj_name, attr_name, type_id, space_id, acpl_id, aapl_id, lapl_id)
    if ret < 0
        error("Error creating attribute ", attr_name, " for object ", obj_name)
    end
    return ret
end

function h5a_delete(loc_id, attr_name)
    ret = ccall((:H5Adelete, libhdf5), Herr, (Hid, Ptr{UInt8}), loc_id, attr_name)
    if ret < 0
        error("Error deleting attribute ", attr_name)
    end
    return ret
end

function h5a_delete_by_idx(loc_id, obj_name, idx_type, order, n, lapl_id)
    ret = ccall((:H5delete_by_idx, libhdf5), Herr, (Hid, Ptr{UInt8}, Cint, Cint, Hsize, Hid), loc_id, obj_name, idx_type, order, n, lapl_id)
    if ret < 0
        error("Error deleting attribute ", n, " from object ", obj_name)
    end
    return ret
end

function h5a_delete_by_name(loc_id, obj_name, attr_name, lapl_id)
    ret = ccall((:H5delete_by_name, libhdf5), Herr, (Hid, Ptr{UInt8}, Ptr{UInt8}, Hid), loc_id, obj_name, attr_name, lapl_id)
    if ret < 0
        error("Error removing attribute ", attr_name, " from object ", obj_name)
    end
    return ret
end

function h5a_get_create_plist(attr_id)
    ret = ccall((:H5Aget_create_plist, libhdf5), Hid, (Hid,), attr_id)
    if ret < 0
        error("Cannot get creation property list")
    end
    return ret
end

function h5a_get_name(attr_id, buf_size, buf)
    ret = ccall((:H5Aget_name, libhdf5), Cssize_t, (Hid, Csize_t, Ptr{UInt8}), attr_id, buf_size, buf)
    if ret < 0
        error("Error getting attribute name")
    end
    return ret
end

function h5a_get_name_by_idx(loc_id, obj_name, index_type, order, idx, name, size, lapl_id)
    ret = ccall((:H5Aget_name_by_idx, libhdf5), Cssize_t, (Hid, Ptr{UInt8}, Cint, Cint, Hsize, Ptr{UInt8}, Csize_t, Hid), loc_id, obj_name, index_type, order, idx, name, size, lapl_id)
    if ret < 0
        error("Error getting attribute name")
    end
    return ret
end

function h5a_get_space(attr_id)
    ret = ccall((:H5Aget_space, libhdf5), Hid, (Hid,), attr_id)
    if ret < 0
        error("Error getting attribute dataspace")
    end
    return ret
end

function h5a_get_type(attr_id)
    ret = ccall((:H5Aget_type, libhdf5), Hid, (Hid,), attr_id)
    if ret < 0
        error("Error getting attribute type")
    end
    return ret
end

function h5a_open(obj_id, pathname, aapl_id)
    ret = ccall((:H5Aopen, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid), obj_id, pathname, aapl_id)
    if ret < 0
        error("Error opening attribute ", h5i_get_name(obj_id), "/", pathname)
    end
    return ret
end

function h5a_read(attr_id, mem_type_id, buf)
    ret = ccall((:H5Aread, libhdf5), Herr, (Hid, Hid, Ptr{Cvoid}), attr_id, mem_type_id, buf)
    if ret < 0
        error("Error reading attribute ", h5a_get_name(attr_id))
    end
    return ret
end

function h5d_create(loc_id, pathname, dtype_id, space_id, lcpl_id, dcpl_id, dapl_id)
    ret = ccall((:H5Dcreate2, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid, Hid, Hid, Hid, Hid), loc_id, pathname, dtype_id, space_id, lcpl_id, dcpl_id, dapl_id)
    if ret < 0
        error("Error creating dataset ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5d_get_access_plist(dataset_id)
    ret = ccall((:H5Dget_access_plist, libhdf5), Hid, (Hid,), dataset_id)
    if ret < 0
        error("Error getting dataset access property list")
    end
    return ret
end

function h5d_get_create_plist(dataset_id)
    ret = ccall((:H5Dget_create_plist, libhdf5), Hid, (Hid,), dataset_id)
    if ret < 0
        error("Error getting dataset create property list")
    end
    return ret
end

function h5d_get_offset(dataset_id)
    ret = ccall((:H5Dget_offset, libhdf5), Haddr, (Hid,), dataset_id)
    if ret < 0
        error("Error getting offset")
    end
    return ret
end

function h5d_get_space(dataset_id)
    ret = ccall((:H5Dget_space, libhdf5), Hid, (Hid,), dataset_id)
    if ret < 0
        error("Error getting dataspace")
    end
    return ret
end

function h5d_get_type(dataset_id)
    ret = ccall((:H5Dget_type, libhdf5), Hid, (Hid,), dataset_id)
    if ret < 0
        error("Error getting dataspace type")
    end
    return ret
end

function h5d_open(loc_id, pathname, dapl_id)
    ret = ccall((:H5Dopen2, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid), loc_id, pathname, dapl_id)
    if ret < 0
        error("Error opening dataset ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5d_read(dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    ret = ccall((:H5Dread, libhdf5), Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Cvoid}), dataset_id, mem_type_id, mem_space_id, file_space_id, xfer_plist_id, buf)
    if ret < 0
        error("Error reading dataset ", h5i_get_name(dataset_id))
    end
    return ret
end

function h5f_create(pathname, flags, fcpl_id, fapl_id)
    ret = ccall((:H5Fcreate, libhdf5), Hid, (Ptr{UInt8}, Cuint, Hid, Hid), pathname, flags, fcpl_id, fapl_id)
    if ret < 0
        error("Error creating file ", pathname)
    end
    return ret
end

function h5f_get_access_plist(file_id)
    ret = ccall((:H5Fget_access_plist, libhdf5), Hid, (Hid,), file_id)
    if ret < 0
        error("Error getting file access property list")
    end
    return ret
end

function h5f_get_create_plist(file_id)
    ret = ccall((:H5Fget_create_plist, libhdf5), Hid, (Hid,), file_id)
    if ret < 0
        error("Error getting file create property list")
    end
    return ret
end

function h5f_get_name(obj_id, buf, buf_size)
    ret = ccall((:H5Fget_name, libhdf5), Cssize_t, (Hid, Ptr{UInt8}, Csize_t), obj_id, buf, buf_size)
    if ret < 0
        error("Error getting file name")
    end
    return ret
end

function h5f_open(pathname, flags, fapl_id)
    ret = ccall((:H5Fopen, libhdf5), Hid, (Cstring, Cuint, Hid), pathname, flags, fapl_id)
    if ret < 0
        error("Error opening file ", pathname)
    end
    return ret
end

function h5g_create(loc_id, pathname, lcpl_id, gcpl_id, gapl_id)
    ret = ccall((:H5Gcreate2, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid, Hid, Hid), loc_id, pathname, lcpl_id, gcpl_id, gapl_id)
    if ret < 0
        error("Error creating group ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5g_get_create_plist(group_id)
    ret = ccall((:H5Gget_create_plist, libhdf5), Hid, (Hid,), group_id)
    if ret < 0
        error("Error getting group create property list")
    end
    return ret
end

function h5g_get_objname_by_idx(loc_id, idx, pathname, size)
    ret = ccall((:H5Gget_objname_by_idx, libhdf5), Cssize_t, (Hid, Hsize, Ptr{UInt8}, Csize_t), loc_id, idx, pathname, size)
    if ret < 0
        error("Error getting group object name ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5g_get_num_objs(loc_id, num_obj)
    ret = ccall((:H5Gget_num_objs, libhdf5), Hid, (Hid, Ptr{Hsize}), loc_id, num_obj)
    if ret < 0
        error("Error getting group length")
    end
    return ret
end

function h5g_open(loc_id, pathname, gapl_id)
    ret = ccall((:H5Gopen2, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid), loc_id, pathname, gapl_id)
    if ret < 0
        error("Error opening group ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5i_get_file_id(obj_id)
    ret = ccall((:H5Iget_file_id, libhdf5), Hid, (Hid,), obj_id)
    if ret < 0
        error("Error getting file identifier")
    end
    return ret
end

function h5i_get_name(obj_id, buf, buf_size)
    ret = ccall((:H5Iget_name, libhdf5), Cssize_t, (Hid, Ptr{UInt8}, Csize_t), obj_id, buf, buf_size)
    if ret < 0
        error("Error getting object name")
    end
    return ret
end

function h5i_get_ref(obj_id)
    ret = ccall((:H5Iget_ref, libhdf5), Cint, (Hid,), obj_id)
    if ret < 0
        error("Error getting reference count")
    end
    return ret
end

function h5i_get_type(obj_id)
    ret = ccall((:H5Iget_type, libhdf5), Cint, (Hid,), obj_id)
    if ret < 0
        error("Error getting type")
    end
    return ret
end

function h5i_dec_ref(obj_id)
    ret = ccall((:H5Idec_ref, libhdf5), Cint, (Hid,), obj_id)
    if ret < 0
        error("Error decementing reference")
    end
    return ret
end

function h5l_delete(obj_id, pathname, lapl_id)
    ret = ccall((:H5Ldelete, libhdf5), Herr, (Hid, Ptr{UInt8}, Hid), obj_id, pathname, lapl_id)
    if ret < 0
        error("Error deleting ", h5i_get_name(obj_id), "/", pathname)
    end
    return ret
end

function h5l_create_external(target_file_name, target_obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    ret = ccall((:H5Lcreate_external, libhdf5), Herr, (Ptr{UInt8}, Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), target_file_name, target_obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    if ret < 0
        error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name)
    end
    return ret
end

function h5l_create_hard(obj_loc_id, obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    ret = ccall((:H5Lcreate_hard, libhdf5), Herr, (Hid, Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), obj_loc_id, obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    if ret < 0
        error("Error creating hard link ", link_name, " pointing to ", obj_name)
    end
    return ret
end

function h5l_create_soft(target_path, link_loc_id, link_name, lcpl_id, lapl_id)
    ret = ccall((:H5Lcreate_soft, libhdf5), Herr, (Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), target_path, link_loc_id, link_name, lcpl_id, lapl_id)
    if ret < 0
        error("Error creating soft link ", link_name, " pointing to ", target_path)
    end
    return ret
end

function h5l_get_info(link_loc_id, link_name, link_buf, lapl_id)
    ret = ccall((:H5Lget_info, libhdf5), Herr, (Hid, Ptr{UInt8}, Ptr{H5LInfo}, Hid), link_loc_id, link_name, link_buf, lapl_id)
    if ret < 0
        error("Error getting info for link ", link_name)
    end
    return ret
end

function h5o_open(loc_id, pathname, lapl_id)
    ret = ccall((:H5Oopen, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid), loc_id, pathname, lapl_id)
    if ret < 0
        error("Error opening object ", h5i_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5o_open_by_idx(loc_id, group_name, index_type, order, n, lapl_id)
    ret = ccall((:H5Oopen_by_idx, libhdf5), Hid, (Hid, Ptr{UInt8}, Cint, Cint, Hsize, Hid), loc_id, group_name, index_type, order, n, lapl_id)
    if ret < 0
        error("Error opening object of index ", n)
    end
    return ret
end

function h5o_open_by_addr(loc_id, addr)
    ret = ccall((:H5Oopen_by_addr, libhdf5), Hid, (Hid, Haddr), loc_id, addr)
    if ret < 0
        error("Error opening object by address")
    end
    return ret
end

function h5o_copy(src_loc_id, src_name, dst_loc_id, dst_name, ocpypl_id, lcpl_id)
    ret = ccall((:H5Ocopy, libhdf5), Herr, (Hid, Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), src_loc_id, src_name, dst_loc_id, dst_name, ocpypl_id, lcpl_id)
    if ret < 0
        error("Error copying object ", h5i_get_name(src_loc_id), "/", src_name, " to ", h5i_get_name(dst_loc_id), "/", dst_name)
    end
    return ret
end

function h5p_create(cls_id)
    ret = ccall((:H5Pcreate, libhdf5), Hid, (Hid,), cls_id)
    if ret < 0
        "Error creating property list"
    end
    return ret
end

function h5p_get_chunk(plist_id, n_dims, dims)
    ret = ccall((:H5Pget_chunk, libhdf5), Cint, (Hid, Cint, Ptr{Hsize}), plist_id, n_dims, dims)
    if ret < 0
        error("Error getting chunk size")
    end
    return ret
end

function h5p_get_layout(plist_id)
    ret = ccall((:H5Pget_layout, libhdf5), Cint, (Hid,), plist_id)
    if ret < 0
        error("Error getting layout")
    end
    return ret
end

function h5p_get_driver_info(plist_id)
    ret = ccall((:H5Pget_driver_info, libhdf5), Ptr{Cvoid}, (Hid,), plist_id)
    if ret < 0
        "Error getting driver info"
    end
    return ret
end

function h5p_get_driver(plist_id)
    ret = ccall((:H5Pget_driver, libhdf5), Hid, (Hid,), plist_id)
    if ret < 0
        "Error getting driver identifier"
    end
    return ret
end

function h5r_create(ref, loc_id, pathname, ref_type, space_id)
    ret = ccall((:H5Rcreate, libhdf5), Herr, (Ptr{HDF5ReferenceObj}, Hid, Ptr{UInt8}, Cint, Hid), ref, loc_id, pathname, ref_type, space_id)
    if ret < 0
        error("Error creating reference to object ", hi5_get_name(loc_id), "/", pathname)
    end
    return ret
end

function h5r_get_obj_type(loc_id, ref_type, ref, obj_type)
    ret = ccall((:H5Rget_obj_type2, libhdf5), Herr, (Hid, Cint, Ptr{Cvoid}, Ptr{Cint}), loc_id, ref_type, ref, obj_type)
    if ret < 0
        error("Error getting object type")
    end
    return ret
end

function h5r_get_region(loc_id, ref_type, ref)
    ret = ccall((:H5Rget_region, libhdf5), Hid, (Hid, Cint, Ptr{Cvoid}), loc_id, ref_type, ref)
    if ret < 0
        error("Error getting region from reference")
    end
    return ret
end

function h5s_copy(space_id)
    ret = ccall((:H5Scopy, libhdf5), Hid, (Hid,), space_id)
    if ret < 0
        error("Error copying dataspace")
    end
    return ret
end

function h5s_create(class)
    ret = ccall((:H5Screate, libhdf5), Hid, (Cint,), class)
    if ret < 0
        error("Error creating dataspace")
    end
    return ret
end

function h5s_create_simple(rank, current_dims, maximum_dims)
    ret = ccall((:H5Screate_simple, libhdf5), Hid, (Cint, Ptr{Hsize}, Ptr{Hsize}), rank, current_dims, maximum_dims)
    if ret < 0
        error("Error creating simple dataspace")
    end
    return ret
end

function h5s_get_simple_extent_dims(space_id, dims, maxdims)
    ret = ccall((:H5Sget_simple_extent_dims, libhdf5), Cint, (Hid, Ptr{Hsize}, Ptr{Hsize}), space_id, dims, maxdims)
    if ret < 0
        error("Error getting the dimensions for a dataspace")
    end
    return ret
end

function h5s_get_simple_extent_ndims(space_id)
    ret = ccall((:H5Sget_simple_extent_ndims, libhdf5), Cint, (Hid,), space_id)
    if ret < 0
        error("Error getting the number of dimensions for a dataspace")
    end
    return ret
end

function h5s_get_simple_extent_type(space_id)
    ret = ccall((:H5Sget_simple_extent_type, libhdf5), Cint, (Hid,), space_id)
    if ret < 0
        error("Error getting the dataspace type")
    end
    return ret
end

function h5t_array_create(basetype_id, ndims, sz)
    ret = ccall((:H5Tarray_create2, libhdf5), Hid, (Hid, Cuint, Ptr{Hsize}), basetype_id, ndims, sz)
    if ret < 0
        error("Error creating H5T_ARRAY of id ", basetype_id, " and size ", sz)
    end
    return ret
end

function h5t_copy(dtype_id)
    ret = ccall((:H5Tcopy, libhdf5), Hid, (Hid,), dtype_id)
    if ret < 0
        error("Error copying datatype")
    end
    return ret
end

function h5t_create(class_id, sz)
    ret = ccall((:H5Tcreate, libhdf5), Hid, (Cint, Csize_t), class_id, sz)
    if ret < 0
        error("Error creating datatype of id ", class_id)
    end
    return ret
end

function h5t_equal(dtype_id1, dtype_id2)
    ret = ccall((:H5Tequal, libhdf5), Hid, (Hid, Hid), dtype_id1, dtype_id2)
    if ret < 0
        error("Error checking datatype equality")
    end
    return ret
end

function h5t_get_array_dims(dtype_id, dims)
    ret = ccall((:H5Tget_array_dims2, libhdf5), Cint, (Hid, Ptr{Hsize}), dtype_id, dims)
    if ret < 0
        error("Error getting dimensions of array")
    end
    return ret
end

function h5t_get_array_ndims(dtype_id)
    ret = ccall((:H5Tget_array_ndims, libhdf5), Cint, (Hid,), dtype_id)
    if ret < 0
        error("Error getting ndims of array")
    end
    return ret
end

function h5t_get_class(dtype_id)
    ret = ccall((:H5Tget_class, libhdf5), Cint, (Hid,), dtype_id)
    if ret < 0
        error("Error getting class")
    end
    return ret
end

function h5t_get_cset(dtype_id)
    ret = ccall((:H5Tget_cset, libhdf5), Cint, (Hid,), dtype_id)
    if ret < 0
        error("Error getting character set encoding")
    end
    return ret
end

function h5t_get_member_class(dtype_id, index)
    ret = ccall((:H5Tget_member_class, libhdf5), Cint, (Hid, Cuint), dtype_id, index)
    if ret < 0
        error("Error getting class of compound datatype member #", index)
    end
    return ret
end

function h5t_get_member_index(dtype_id, membername)
    ret = ccall((:H5Tget_member_index, libhdf5), Cint, (Hid, Ptr{UInt8}), dtype_id, membername)
    if ret < 0
        error("Error getting index of compound datatype member \"", membername, "\"")
    end
    return ret
end

function h5t_get_member_offset(dtype_id, index)
    ret = ccall((:H5Tget_member_offset, libhdf5), Csize_t, (Hid, Cuint), dtype_id, index)
    if ret < 0
        error("Error getting offset of compound datatype member #", index)
    end
    return ret
end

function h5t_get_member_type(dtype_id, index)
    ret = ccall((:H5Tget_member_type, libhdf5), Hid, (Hid, Cuint), dtype_id, index)
    if ret < 0
        error("Error getting type of compound datatype member #", index)
    end
    return ret
end

function h5t_get_native_type(dtype_id, direction)
    ret = ccall((:H5Tget_native_type, libhdf5), Hid, (Hid, Cint), dtype_id, direction)
    if ret < 0
        error("Error getting native type")
    end
    return ret
end

function h5t_get_nmembers(dtype_id)
    ret = ccall((:H5Tget_nmembers, libhdf5), Cint, (Hid,), dtype_id)
    if ret < 0
        error("Error getting the number of members")
    end
    return ret
end

function h5t_get_sign(dtype_id)
    ret = ccall((:H5Tget_sign, libhdf5), Cint, (Hid,), dtype_id)
    if ret < 0
        error("Error getting sign")
    end
    return ret
end

function h5t_get_size(dtype_id)
    ret = ccall((:H5Tget_size, libhdf5), Csize_t, (Hid,), dtype_id)
    if ret < 0
        error("Error getting size")
    end
    return ret
end

function h5t_get_super(dtype_id)
    ret = ccall((:H5Tget_super, libhdf5), Hid, (Hid,), dtype_id)
    if ret < 0
        error("Error getting super type")
    end
    return ret
end

function h5t_get_strpad(dtype_id)
    ret = ccall((:H5Tget_strpad, libhdf5), Cint, (Hid,), dtype_id)
    if ret < 0
        error("Error getting string padding")
    end
    return ret
end

function h5t_insert(dtype_id, fieldname, offset, field_id)
    ret = ccall((:H5Tinsert, libhdf5), Herr, (Hid, Ptr{UInt8}, Csize_t, Hid), dtype_id, fieldname, offset, field_id)
    if ret < 0
        error("Error adding field ", fieldname, " to compound datatype")
    end
    return ret
end

function h5t_open(loc_id, name, tapl_id)
    ret = ccall((:H5Topen2, libhdf5), Hid, (Hid, Ptr{UInt8}, Hid), loc_id, name, tapl_id)
    if ret < 0
        error("Error opening type ", h5i_get_name(loc_id), "/", name)
    end
    return ret
end

function h5t_vlen_create(base_type_id)
    ret = ccall((:H5Tvlen_create, libhdf5), Hid, (Hid,), base_type_id)
    if ret < 0
        error("Error creating vlen type")
    end
    return ret
end

function h5tb_get_field_info(loc_id, table_name, field_names, field_sizes, field_offsets, type_size)
    ret = ccall((:H5TBget_field_info, libhdf5_hl), Herr, (Hid, Ptr{UInt8}, Ptr{Ptr{UInt8}}, Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}), loc_id, table_name, field_names, field_sizes, field_offsets, type_size)
    if ret < 0
        error("Error getting field information")
    end
    return ret
end

function h5a_exists(obj_id, attr_name)
    ret = ccall((:H5Aexists, libhdf5), Htri, (Hid, Ptr{UInt8}), obj_id, attr_name)
    if ret < 0
        error("Error checking whether attribute ", attr_name, " exists")
    end
    return ret > 0
end

function h5a_exists_by_name(loc_id, obj_name, attr_name, lapl_id)
    ret = ccall((:H5Aexists_by_name, libhdf5), Htri, (Hid, Ptr{UInt8}, Ptr{UInt8}, Hid), loc_id, obj_name, attr_name, lapl_id)
    if ret < 0
        error("Error checking whether object ", obj_name, " has attribute ", attr_name)
    end
    return ret > 0
end

function h5f_is_hdf5(pathname)
    ret = ccall((:H5Fis_hdf5, libhdf5), Htri, (Cstring,), pathname)
    if ret < 0
        error("Cannot access file ", pathname)
    end
    return ret > 0
end

function h5i_is_valid(obj_id)
    ret = ccall((:H5Iis_valid, libhdf5), Htri, (Hid,), obj_id)
    if ret < 0
        error("Cannot determine whether object is valid")
    end
    return ret > 0
end

function h5l_exists(loc_id, pathname, lapl_id)
    ret = ccall((:H5Lexists, libhdf5), Htri, (Hid, Ptr{UInt8}, Hid), loc_id, pathname, lapl_id)
    if ret < 0
        error("Cannot determine whether ", pathname, " exists")
    end
    return ret > 0
end

function h5s_is_simple(space_id)
    ret = ccall((:H5Sis_simple, libhdf5), Htri, (Hid,), space_id)
    if ret < 0
        error("Error determining whether dataspace is simple")
    end
    return ret > 0
end

function h5t_is_variable_str(type_id)
    ret = ccall((:H5Tis_variable_str, libhdf5), Htri, (Hid,), type_id)
    if ret < 0
        error("Error determining whether string is of variable length")
    end
    return ret > 0
end

function h5t_committed(dtype_id)
    ret = ccall((:H5Tcommitted, libhdf5), Htri, (Hid,), dtype_id)
    if ret < 0
        error("Error determining whether datatype is committed")
    end
    return ret > 0
end
