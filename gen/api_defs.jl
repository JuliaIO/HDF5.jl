#! format: off
# The `@bind` macro is used to automatically generate Julia bindings to the low-level
# HDF5 library functions.
#
# Each line should consist of two arguments:
#
#   1. An `@ccall`-like function definition expression for the C library interface,
#      including the return type.
#   2. Either an error string (which is thrown by `hdf5error()`) or an expression which
#      builds an error string and may refer to any of the named function arguments.
#
# The C library names are automatically generated from the Julia function name by
# uppercasing the `h5?` and removing the first underscore ---
# e.g. `h5d_close` -> `H5Dclose`. Versioned function names (such as
# `h5d_open2` -> `H5Dopen2`) have the trailing number removed for the Julia function
# definition. Other arbitrary mappings may be added by adding an entry to the
# `bind_exceptions` Dict in `bind_generator.jl`.
#
# Execute gen_wrappers.jl to generate ../src/api/functions.jl from this file.

###
### HDF5 General library functions
###

@bind h5_close()::herr_t "Error closing the HDF5 resources"
@bind h5_dont_atexit()::herr_t "Error calling dont_atexit"
@bind h5_free_memory(buf::Ptr{Cvoid})::herr_t "Error freeing memory"
@bind h5_garbage_collect()::herr_t "Error on garbage collect"
@bind h5_get_libversion(majnum::Ref{Cuint}, minnum::Ref{Cuint}, relnum::Ref{Cuint})::herr_t "Error getting HDF5 library version"
@bind h5_is_library_threadsafe(is_ts::Ref{Cuchar})::herr_t "Error determining thread safety"
@bind h5_open()::herr_t "Error initializing the HDF5 library"
@bind h5_set_free_list_limits(reg_global_lim::Cint, reg_list_lim::Cint, arr_global_lim::Cint, arr_list_lim::Cint, blk_global_lim::Cint, blk_list_lim::Cint)::herr_t "Error setting limits on free lists"

###
### Attribute Interface
###

@bind h5a_close(id::hid_t)::herr_t "Error closing attribute"
@bind h5a_create2(loc_id::hid_t, attr_name::Cstring, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t)::hid_t string("Error creating attribute ", attr_name, " for object ", h5i_get_name(loc_id))
@bind h5a_create_by_name(loc_id::hid_t, obj_name::Cstring, attr_name::Cstring, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t, lapl_id::hid_t)::hid_t string("Error creating attribute ", attr_name, " for object ", obj_name)
@bind h5a_delete(loc_id::hid_t, attr_name::Cstring)::herr_t string("Error deleting attribute ", attr_name)
@bind h5a_delete_by_idx(loc_id::hid_t, obj_name::Cstring, idx_type::Cint, order::Cint, n::hsize_t, lapl_id::hid_t)::herr_t string("Error deleting attribute ", n, " from object ", obj_name)
@bind h5a_delete_by_name(loc_id::hid_t, obj_name::Cstring, attr_name::Cstring, lapl_id::hid_t)::herr_t string("Error removing attribute ", attr_name, " from object ", obj_name)
@bind h5a_exists(obj_id::hid_t, attr_name::Cstring)::htri_t string("Error checking whether attribute ", attr_name, " exists")
@bind h5a_exists_by_name(loc_id::hid_t, obj_name::Cstring, attr_name::Cstring, lapl_id::hid_t)::htri_t string("Error checking whether object ", obj_name, " has attribute ", attr_name)
@bind h5a_get_create_plist(attr_id::hid_t)::hid_t "Cannot get creation property list"
@bind h5a_get_name(attr_id::hid_t, buf_size::Csize_t, buf::Ptr{UInt8})::Cssize_t "Error getting attribute name"
@bind h5a_get_name_by_idx(loc_id::hid_t, obj_name::Cstring, index_type::Cint, order::Cint, idx::hsize_t, name::Ptr{UInt8}, size::Csize_t, lapl_id::hid_t)::Cssize_t "Error getting attribute name"
@bind h5a_get_space(attr_id::hid_t)::hid_t "Error getting attribute dataspace"
@bind h5a_get_type(attr_id::hid_t)::hid_t "Error getting attribute type"
@bind h5a_iterate2(obj_id::hid_t, idx_type::Cint, order::Cint, n::Ptr{hsize_t}, op::Ptr{Cvoid}, op_data::Any)::herr_t string("Error iterating attributes in object ", h5i_get_name(obj_id))
@bind h5a_open(obj_id::hid_t, attr_name::Cstring, aapl_id::hid_t)::hid_t string("Error opening attribute ", attr_name, " for object ", h5i_get_name(obj_id))
@bind h5a_open_by_idx(obj_id::hid_t, pathname::Cstring, idx_type::Cint, order::Cint, n::hsize_t, aapl_id::hid_t, lapl_id::hid_t)::hid_t string("Error opening attribute ", n, " of ", h5i_get_name(obj_id), "/", pathname)
@bind h5a_read(attr_id::hid_t, mem_type_id::hid_t, buf::Ptr{Cvoid})::herr_t string("Error reading attribute ", h5a_get_name(attr_id))
@bind h5a_rename(loc_id::hid_t, old_attr_name::Cstring, new_attr_name::Cstring)::herr_t string("Could not rename attribute")
@bind h5a_write(attr_hid::hid_t, mem_type_id::hid_t, buf::Ptr{Cvoid})::herr_t "Error writing attribute data"

###
### Dataset Interface
###

@bind h5d_chunk_iter(dset_id::hid_t, dxpl_id::hid_t, cb::Ptr{Nothing}, op_data::Any)::herr_t "Error iterating over chunks" (v"1.12.3", nothing)
@bind h5d_close(dataset_id::hid_t)::herr_t "Error closing dataset"
@bind h5d_create2(loc_id::hid_t, pathname::Cstring, dtype_id::hid_t, space_id::hid_t, lcpl_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t)::hid_t string("Error creating dataset ", h5i_get_name(loc_id), "/", pathname)
@bind h5d_create_anon(loc_id::hid_t, type_id::hid_t, space_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t)::hid_t "Error in creating anonymous dataset"
@bind h5d_extend(dataset_id::hid_t, size::Ptr{hsize_t})::herr_t "Error extending dataset" # deprecated in favor of h5d_set_extent
@bind h5d_fill(fill::Ptr{Cvoid}, fill_type_id::hid_t, buf::Ptr{Cvoid}, buf_type_id::hid_t, space_id::hid_t)::herr_t "Error filling dataset"
@bind h5d_flush(dataset_id::hid_t)::herr_t "Error flushing dataset"
@bind h5d_gather(src_space_id::hid_t, src_buf::Ptr{Cvoid}, type_id::hid_t, dst_buf_size::Csize_t, dst_buf::Ptr{Cvoid}, op::Ptr{Cvoid}, op_data::Any)::herr_t "Error gathering dataset"
@bind h5d_get_access_plist(dataset_id::hid_t)::hid_t "Error getting dataset access property list"
@bind h5d_get_chunk_info(dataset_id::hid_t, fspace_id::hid_t, index::hsize_t, offset::Ptr{hsize_t}, filter_mask::Ptr{Cuint}, addr::Ptr{haddr_t}, size::Ptr{hsize_t})::herr_t "Error getting chunk info"
@bind h5d_get_chunk_info_by_coord(dataset_id::hid_t, offset::Ptr{hsize_t}, filter_mask::Ptr{Cuint}, addr::Ptr{haddr_t}, size::Ptr{hsize_t})::herr_t "Error getting chunk info by coord" (v"1.10.5",nothing)
@bind h5d_get_chunk_storage_size(dataset_id::hid_t, offset::Ptr{hsize_t}, chunk_nbytes::Ptr{hsize_t})::herr_t "Error getting chunk storage size"
@bind h5d_get_create_plist(dataset_id::hid_t)::hid_t "Error getting dataset create property list"
@bind h5d_get_num_chunks(dataset_id::hid_t, fspace_id::hid_t, nchunks::Ptr{hsize_t})::herr_t "Error getting number of chunks" (v"1.10.5",nothing)
@bind h5d_get_offset(dataset_id::hid_t)::haddr_t "Error getting offset"
@bind h5d_get_space(dataset_id::hid_t)::hid_t "Error getting dataspace"
@bind h5d_get_space_status(dataset_id::hid_t, status::Ref{Cint})::herr_t "Error getting dataspace status"
@bind h5d_get_storage_size(dataset_id::hid_t)::hsize_t "Error getting storage size"
@bind h5d_get_type(dataset_id::hid_t)::hid_t "Error getting dataspace type"
@bind h5d_iterate(buf::Ptr{Cvoid}, type_id::hid_t, space_id::hid_t, operator::Ptr{Cvoid}, operator_data::Any)::herr_t "Error iterating dataset"
@bind h5d_open2(loc_id::hid_t, pathname::Cstring, dapl_id::hid_t)::hid_t string("Error opening dataset ", h5i_get_name(loc_id), "/", pathname)
@bind h5d_read(dataset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, xfer_plist_id::hid_t, buf::Ptr{Cvoid})::herr_t string("Error reading dataset ", h5i_get_name(dataset_id))
@bind h5d_read_chunk(dset::hid_t, dxpl_id::hid_t, offset::Ptr{hsize_t}, filters::Ptr{UInt32}, buf::Ptr{Cvoid})::herr_t "Error reading chunk"
@bind h5d_refresh(dataset_id::hid_t)::herr_t "Error refreshing dataset"
@bind h5d_scatter(op::Ptr{Cvoid}, op_data::Any, type_id::hid_t, dst_space_id::hid_t, dst_buf::Ptr{Cvoid})::herr_t "Error scattering to dataset"
@bind h5d_set_extent(dataset_id::hid_t, new_dims::Ptr{hsize_t})::herr_t "Error extending dataset dimensions"
@bind h5d_vlen_get_buf_size(dset_id::hid_t, type_id::hid_t, space_id::hid_t, buf::Ptr{hsize_t})::herr_t "Error getting vlen buffer size"
@bind h5d_vlen_reclaim(type_id::hid_t, space_id::hid_t, plist_id::hid_t, buf::Ptr{Cvoid})::herr_t "Error reclaiming vlen buffer"
@bind h5d_write(dataset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, xfer_plist_id::hid_t, buf::Ptr{Cvoid})::herr_t "Error writing dataset"
@bind h5d_write_chunk(dset_id::hid_t, dxpl_id::hid_t, filter_mask::UInt32, offset::Ptr{hsize_t}, bufsize::Csize_t, buf::Ptr{Cvoid})::herr_t "Error writing chunk"

###
### Error Interface
###

@bind h5e_get_auto2(estack_id::hid_t, func::Ref{Ptr{Cvoid}}, client_data::Ref{Ptr{Cvoid}})::herr_t "Error getting error reporting behavior"
@bind h5e_set_auto2(estack_id::hid_t, func::Ptr{Cvoid}, client_data::Ptr{Cvoid})::herr_t "Error setting error reporting behavior"
@bind h5e_get_current_stack()::hid_t "Unable to return current error stack"
@bind h5e_get_msg(mesg_id::hid_t, mesg_type::Ref{Cint}, mesg::Ref{UInt8}, len::Csize_t)::Cssize_t "Error getting message"
@bind h5e_get_num(estack_id::hid_t)::Cssize_t "Error getting stack length"
@bind h5e_close_stack(stack_id::hid_t)::herr_t "Error closing stack"
@bind h5e_walk2(stack_id::hid_t, direction::Cint, op::Ptr{Cvoid}, op_data::Any)::herr_t "Error walking stack"

###
### File Interface
###

@bind h5f_clear_elink_file_cache(file_id::hid_t)::herr_t "Error in h5f_clear_elink_file_cache (not annotated)"
@bind h5f_close(file_id::hid_t)::herr_t "Error closing file"
@bind h5f_create(pathname::Cstring, flags::Cuint, fcpl_id::hid_t, fapl_id::hid_t)::hid_t "Error creating file $pathname"
@bind h5f_delete(filename::Cstring, fapl_id::hid_t)::herr_t "Error in h5f_delete (not annotated)"
@bind h5f_flush(object_id::hid_t, scope::Cint)::herr_t "Error flushing object to file"
@bind h5f_format_convert(fid::hid_t)::herr_t "Error in h5f_format_convert (not annotated)"
@bind h5f_get_access_plist(file_id::hid_t)::hid_t "Error getting file access property list"
@bind h5f_get_create_plist(file_id::hid_t)::hid_t "Error getting file create property list"
@bind h5f_get_dset_no_attrs_hint(file_id::hid_t, minimize::Ptr{hbool_t})::herr_t "Error getting dataset no attributes hint"
@bind h5f_get_eoa(file_id::hid_t, eoa::Ptr{haddr_t})::herr_t "Error in h5f_get_eoa (not annotated)"
@bind h5f_get_file_image(file_id::hid_t, buf_ptr::Ptr{Cvoid}, buf_len::Csize_t)::Cssize_t "Error in h5f_get_file_image (not annotated)"
@bind h5f_get_fileno(file_id::hid_t, fileno::Ptr{Culong})::herr_t "Error in h5f_get_fileno (not annotated)"
@bind h5f_get_filesize(file_id::hid_t, size::Ptr{hsize_t})::herr_t "Error in h5f_get_filesize (not annotated)"
@bind h5f_get_free_sections(file_id::hid_t, type::H5F_mem_t, nsects::Csize_t, sect_info::Ptr{H5F_sect_info_t})::Cssize_t "Error in h5f_get_free_sections (not annotated)"
@bind h5f_get_freespace(file_id::hid_t)::hssize_t "Error in h5f_get_freespace (not annotated)"
@bind h5f_get_intent(file_id::hid_t, intent::Ptr{Cuint})::herr_t "Error getting file intent"
@bind h5f_get_info2(obj_id::hid_t, file_info::Ptr{H5F_info2_t})::herr_t "Error in h5f_get_info2 (not annotated)"
@bind h5f_get_mdc_config(file_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t "Error in h5f_get_mdc_config (not annotated)"
@bind h5f_get_mdc_hit_rate(file_id::hid_t, hit_rate_ptr::Ptr{Cdouble})::herr_t "Error in h5f_get_mdc_hit_rate (not annotated)"
@bind h5f_get_mdc_image_info(file_id::hid_t, image_addr::Ptr{haddr_t}, image_size::Ptr{hsize_t})::herr_t "Error in h5f_get_mdc_image_info (not annotated)"
@bind h5f_get_mdc_logging_status(file_id::hid_t, is_enabled::Ptr{hbool_t}, is_currently_logging::Ptr{hbool_t})::herr_t "Error in h5f_get_mdc_logging_status (not annotated)"
@bind h5f_get_mdc_size(file_id::hid_t, max_size_ptr::Ptr{Csize_t}, min_clean_size_ptr::Ptr{Csize_t}, cur_size_ptr::Ptr{Csize_t}, cur_num_entries_ptr::Ptr{Cint})::herr_t "Error in h5f_get_mdc_size (not annotated)"
@bind h5f_get_metadata_read_retry_info(file_id::hid_t, info::Ptr{H5F_retry_info_t})::herr_t "Error in h5f_get_metadata_read_retry_info (not annotated)"
@bind h5f_get_mpi_atomicity(file_id::hid_t, flag::Ptr{hbool_t})::herr_t "Error in h5f_get_mpi_atomicity (not annotated)"
@bind h5f_get_name(obj_id::hid_t, buf::Ptr{UInt8}, buf_size::Csize_t)::Cssize_t "Error getting file name"
@bind h5f_get_obj_count(file_id::hid_t, types::Cuint)::Cssize_t "Error getting object count"
@bind h5f_get_obj_ids(file_id::hid_t, types::Cuint, max_objs::Csize_t, obj_id_list::Ptr{hid_t})::Cssize_t "Error getting objects"
@bind h5f_get_page_buffering_stats(file_id::hid_t, accesses::Ptr{Cuint}, hits::Ptr{Cuint}, misses::Ptr{Cuint}, evictions::Ptr{Cuint}, bypasses::Ptr{Cuint})::herr_t "Error in h5f_get_page_buffering_stats (not annotated)"
@bind h5f_get_vfd_handle(file_id::hid_t, fapl_id::hid_t, file_handle::Ref{Ptr{Cvoid}})::herr_t "Error getting VFD handle"
@bind h5f_increment_filesize(file_id::hid_t, increment::hsize_t)::herr_t "Error in h5f_increment_filesize (not annotated)"
@bind h5f_is_accessible(container_name::Cstring, fapl_id::hid_t)::htri_t "Error in h5f_is_accessible (not annotated)"
@bind h5f_is_hdf5(pathname::Cstring)::htri_t "Unable to access file $pathname"
@bind h5f_mount(loc::hid_t, name::Cstring, child::hid_t, plist::hid_t)::herr_t "Error in h5f_mount (not annotated)"
@bind h5f_open(pathname::Cstring, flags::Cuint, fapl_id::hid_t)::hid_t "Error opening file $pathname"
@bind h5f_reopen(file_id::hid_t)::hid_t "Error in h5f_reopen (not annotated)"
@bind h5f_reset_mdc_hit_rate_stats(file_id::hid_t)::herr_t "Error in h5f_reset_mdc_hit_rate_stats (not annotated)"
@bind h5f_reset_page_buffering_stats(file_id::hid_t)::herr_t "Error in h5f_reset_page_buffering_stats (not annotated)"
@bind h5f_set_dset_no_attrs_hint(file_id::hid_t, minimize::hbool_t)::herr_t "Error in setting dataset no attributes hint"
@bind h5f_set_libver_bounds(file_id::hid_t, low::H5F_libver_t, high::H5F_libver_t)::herr_t "Error in h5f_set_libver_bounds (not annotated)"
@bind h5f_set_mdc_config(file_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t "Error in h5f_set_mdc_config (not annotated)"
@bind h5f_set_mpi_atomicity(file_id::hid_t, flag::hbool_t)::herr_t "Error in h5f_set_mpi_atomicity (not annotated)"
@bind h5f_start_mdc_logging(file_id::hid_t)::herr_t "Error in h5f_start_mdc_logging (not annotated)"
@bind h5f_start_swmr_write(id::hid_t)::herr_t "Error starting SWMR write"
@bind h5f_stop_mdc_logging(file_id::hid_t)::herr_t "Error in h5f_stop_mdc_logging (not annotated)"
@bind h5f_unmount(loc::hid_t, name::Cstring)::herr_t "Error in h5f_unmount (not annotated)"

###
### Group Interface
###

@bind h5g_close(group_id::hid_t)::herr_t "Error closing group"
@bind h5g_create2(loc_id::hid_t, pathname::Cstring, lcpl_id::hid_t, gcpl_id::hid_t, gapl_id::hid_t)::hid_t "Error creating group $(h5i_get_name(loc_id))/$(pathname)"
@bind h5g_get_create_plist(group_id::hid_t)::hid_t "Error getting group create property list"
@bind h5g_get_info(group_id::hid_t, buf::Ptr{H5G_info_t})::herr_t "Error getting group info"
@bind h5g_get_num_objs(loc_id::hid_t, num_obj::Ptr{hsize_t})::hid_t "Error getting group length"
@bind h5g_get_objname_by_idx(loc_id::hid_t, idx::hsize_t, pathname::Ptr{UInt8}, size::Csize_t)::Cssize_t "Error getting group object name $(h5i_get_name(loc_id))/$(pathname)"
@bind h5g_open2(loc_id::hid_t, pathname::Cstring, gapl_id::hid_t)::hid_t "Error opening group $(h5i_get_name(loc_id))/$(pathname)"

###
### Identifier Interface
###

@bind h5i_dec_ref(obj_id::hid_t)::Cint "Error decementing reference"
@bind h5i_get_file_id(obj_id::hid_t)::hid_t "Error getting file identifier"
@bind h5i_get_name(obj_id::hid_t, buf::Ptr{UInt8}, buf_size::Csize_t)::Cssize_t "Error getting object name"
@bind h5i_get_ref(obj_id::hid_t)::Cint "Error getting reference count"
@bind h5i_get_type(obj_id::hid_t)::Cint "Error getting type"
@bind h5i_inc_ref(obj_id::hid_t)::Cint "Error incrementing identifier refcount"
@bind h5i_is_valid(obj_id::hid_t)::htri_t "Cannot determine whether object is valid"

###
### Link Interface
###

@bind h5l_create_external(target_file_name::Cstring, target_obj_name::Cstring, link_loc_id::hid_t, link_name::Cstring, lcpl_id::hid_t, lapl_id::hid_t)::herr_t string("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name)
@bind h5l_create_hard(obj_loc_id::hid_t, obj_name::Cstring, link_loc_id::hid_t, link_name::Cstring, lcpl_id::hid_t, lapl_id::hid_t)::herr_t string("Error creating hard link ", link_name, " pointing to ", obj_name)
@bind h5l_create_soft(target_path::Cstring, link_loc_id::hid_t, link_name::Cstring, lcpl_id::hid_t, lapl_id::hid_t)::herr_t string("Error creating soft link ", link_name, " pointing to ", target_path)
@bind h5l_delete(obj_id::hid_t, pathname::Cstring, lapl_id::hid_t)::herr_t string("Error deleting ", h5i_get_name(obj_id), "/", pathname)
@bind h5l_move(src_obj_id::hid_t, src_name::Cstring, dest_obj_id::hid_t, dest_name::Cstring, lcpl_id::hid_t, lapl_id::hid_t)::herr_t string("Error moving ", h5i_get_name(src_obj_id), "/", src_name, " to ", h5i_get_name(dest_obj_id), "/", dest_name)
@bind h5l_exists(loc_id::hid_t, pathname::Cstring, lapl_id::hid_t)::htri_t string("Cannot determine whether ", pathname, " exists")
@bind h5l_get_info(link_loc_id::hid_t, link_name::Cstring, link_buf::Ptr{H5L_info_t}, lapl_id::hid_t)::herr_t string("Error getting info for link ", link_name)
@bind h5l_get_name_by_idx(loc_id::hid_t, group_name::Cstring, index_field::Cint, order::Cint, n::hsize_t, name::Ptr{UInt8}, size::Csize_t, lapl_id::hid_t)::Cssize_t "Error getting object name"
# libhdf5 v1.10 provides the name H5Literate
# libhdf5 v1.12 provides the same under H5Literate1, and a newer interface on H5Literate2
@bind h5l_iterate(group_id::hid_t, idx_type::Cint, order::Cint, idx::Ptr{hsize_t}, op::Ptr{Cvoid}, op_data::Any)::herr_t string("Error iterating through links in group ", h5i_get_name(group_id)) (nothing, v"1.12")
@bind h5l_iterate1(group_id::hid_t, idx_type::Cint, order::Cint, idx::Ptr{hsize_t}, op::Ptr{Cvoid}, op_data::Any)::herr_t string("Error iterating through links in group ", h5i_get_name(group_id)) (v"1.12", nothing)

###
### Object Interface
###


@bind h5o_are_mdc_flushes_disabled(object_id::hid_t, are_disabled::Ptr{hbool_t})::herr_t "Error in h5o_are_mdc_flushes_disabled (not annotated)"
@bind h5o_close(object_id::hid_t)::herr_t "Error closing object"
@bind h5o_copy(src_loc_id::hid_t, src_name::Cstring, dst_loc_id::hid_t, dst_name::Cstring, ocpypl_id::hid_t, lcpl_id::hid_t)::herr_t string("Error copying object ", h5i_get_name(src_loc_id), "/", src_name, " to ", h5i_get_name(dst_loc_id), "/", dst_name)
@bind h5o_decr_refcount(object_id::hid_t)::herr_t "Error in h5o_decr_refcount (not annotated)"
@bind h5o_disable_mdc_flushes(object_id::hid_t)::herr_t "Error in h5o_disable_mdc_flushes (not annotated)"
@bind h5o_enable_mdc_flushes(object_id::hid_t)::herr_t "Error in h5o_enable_mdc_flushes (not annotated)"
@bind h5o_exists_by_name(loc_id::hid_t, name::Cstring, lapl_id::hid_t)::htri_t "Error in h5o_exists_by_name (not annotated)"
@bind h5o_flush(obj_id::hid_t)::herr_t "Error in h5o_flush (not annotated)"
@bind h5o_get_comment(obj_id::hid_t, comment::Ptr{Cchar}, bufsize::Csize_t)::Cssize_t "Error in h5o_get_comment (not annotated)"
@bind h5o_get_comment_by_name(loc_id::hid_t, name::Cstring, comment::Ptr{Cchar}, bufsize::Csize_t, lapl_id::hid_t)::Cssize_t "Error in h5o_get_comment_by_name (not annotated)"
@bind h5o_get_info1(object_id::hid_t, buf::Ptr{H5O_info1_t})::herr_t "Error getting object info" (nothing, v"1.10.3")
@bind h5o_get_info2(loc_id::hid_t, oinfo::Ptr{H5O_info1_t}, fields::Cuint)::herr_t "Error in h5o_get_info2 (not annotated)" (v"1.10.3", v"1.12.0")
@bind h5o_get_info3(loc_id::hid_t, oinfo::Ptr{H5O_info2_t}, fields::Cuint)::herr_t "Error in h5o_get_info3 (not annotated)" (v"1.12.0", nothing)
@bind h5o_get_info_by_idx1(loc_id::hid_t, group_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_info1_t}, lapl_id::hid_t)::herr_t "Error in h5o_get_info_by_idx1 (not annotated)" (nothing, v"1.10.3")
@bind h5o_get_info_by_idx2(loc_id::hid_t, group_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_info1_t}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_get_info_by_idx2 (not annotated)" (v"1.10.3", v"1.12.0")
@bind h5o_get_info_by_idx3(loc_id::hid_t, group_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_info2_t}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_get_info_by_idx3 (not annotated)" (v"1.12.0", nothing)
@bind h5o_get_info_by_name1(loc_id::hid_t, name::Cstring, oinfo::Ptr{H5O_info1_t}, lapl_id::hid_t)::herr_t "Error in h5o_get_info_by_name1 (not annotated)" (nothing, v"1.10.3")
@bind h5o_get_info_by_name2(loc_id::hid_t, name::Cstring, oinfo::Ptr{H5O_info1_t}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_get_info_by_name2 (not annotated)" (v"1.10.3", v"1.12.0")
@bind h5o_get_info_by_name3(loc_id::hid_t, name::Cstring, oinfo::Ptr{H5O_info2_t}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_get_info_by_name3 (not annotated)" (v"1.12.0", nothing)
@bind h5o_get_native_info(loc_id::hid_t, oinfo::Ptr{H5O_native_info_t}, fields::Cuint)::herr_t "Error in h5o_get_native_info (not annotated)"
@bind h5o_get_native_info_by_idx(loc_id::hid_t, group_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_native_info_t}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_get_native_info_by_idx (not annotated)"
@bind h5o_get_native_info_by_name(loc_id::hid_t, name::Cstring, oinfo::Ptr{H5O_native_info_t}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_get_native_info_by_name (not annotated)"
@bind h5o_incr_refcount(object_id::hid_t)::herr_t "Error in h5o_incr_refcount (not annotated)"
@bind h5o_link(obj_id::hid_t, new_loc_id::hid_t, new_name::Cstring, lcpl_id::hid_t, lapl_id::hid_t)::herr_t "Error in h5o_link (not annotated)"
@bind h5o_open(loc_id::hid_t, pathname::Cstring, lapl_id::hid_t)::hid_t string("Error opening object ", h5i_get_name(loc_id), "/", pathname)
@bind h5o_open_by_addr(loc_id::hid_t, addr::haddr_t)::hid_t "Error opening object by address"
@bind h5o_open_by_idx(loc_id::hid_t, group_name::Cstring, index_type::Cint, order::Cint, n::hsize_t, lapl_id::hid_t)::hid_t string("Error opening object of index ", n)
@bind h5o_refresh(oid::hid_t)::herr_t "Error in h5o_refresh (not annotated)"
@bind h5o_set_comment(obj_id::hid_t, comment::Cstring)::herr_t "Error in h5o_set_comment (not annotated)"
@bind h5o_set_comment_by_name(loc_id::hid_t, name::Cstring, comment::Cstring, lapl_id::hid_t)::herr_t "Error in h5o_set_comment_by_name (not annotated)"
@bind h5o_token_cmp(loc_id::hid_t, token1::Ptr{H5O_token_t}, token2::Ptr{H5O_token_t}, cmp_value::Ptr{Cint})::herr_t "Error in h5o_token_cmp (not annotated)"
@bind h5o_token_from_str(loc_id::hid_t, token_str::Cstring, token::Ptr{H5O_token_t})::herr_t "Error in h5o_token_from_str (not annotated)"
@bind h5o_token_to_str(loc_id::hid_t, token::Ptr{H5O_token_t}, token_str::Ptr{Ptr{Cchar}})::herr_t "Error in h5o_token_to_str (not annotated)"
@bind h5o_visit1(obj_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid})::herr_t "Error in h5o_visit1 (not annotated)" (nothing, v"1.12.0")
#@bind h5o_visit2(obj_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid}, fields::Cuint)::herr_t "Error in h5o_visit2 (not annotated)"
@bind h5o_visit3(obj_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate2_t, op_data::Ptr{Cvoid}, fields::Cuint)::herr_t "Error in h5o_visit3 (not annotated)" (v"1.12.0", nothing)
@bind h5o_visit_by_name1(loc_id::hid_t, obj_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t "Error in h5o_visit_by_name1 (not annotated)" (nothing, v"1.12.0")
#@bind h5o_visit_by_name2(loc_id::hid_t, obj_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_visit_by_name2 (not annotated)"
@bind h5o_visit_by_name3(loc_id::hid_t, obj_name::Cstring, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate2_t, op_data::Ptr{Cvoid}, fields::Cuint, lapl_id::hid_t)::herr_t "Error in h5o_visit_by_name3 (not annotated)" (v"1.12.0", nothing)

###
### Property Interface
###

# get
@bind h5p_get(plist_id::hid_t, name::Cstring, value::Ptr{Cvoid})::herr_t "Error in h5p_get (not annotated)"
@bind h5p_get_alignment(fapl_id::hid_t, threshold::Ref{hsize_t}, alignment::Ref{hsize_t})::herr_t "Error getting alignment"
@bind h5p_get_alloc_time(plist_id::hid_t, alloc_time::Ptr{Cint})::herr_t "Error getting allocation timing"
@bind h5p_get_append_flush(dapl_id::hid_t, dims::Cuint, boundary::Ptr{hsize_t}, func::Ptr{H5D_append_cb_t}, udata::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_append_flush (not annotated)"
@bind h5p_get_attr_creation_order(plist_id::hid_t, crt_order_flags::Ptr{Cuint})::herr_t "Error getting attribute creation order"
@bind h5p_get_attr_phase_change(plist_id::hid_t, max_compact::Ptr{Cuint}, min_dense::Ptr{Cuint})::herr_t "Error in h5p_get_attr_phase_change (not annotated)"
@bind h5p_get_btree_ratios(plist_id::hid_t, left::Ptr{Cdouble}, middle::Ptr{Cdouble}, right::Ptr{Cdouble})::herr_t "Error in h5p_get_btree_ratios (not annotated)"
@bind h5p_get_buffer(plist_id::hid_t, tconv::Ptr{Ptr{Cvoid}}, bkg::Ptr{Ptr{Cvoid}})::Csize_t "Error in h5p_get_buffer (not annotated)"
@bind h5p_get_cache(plist_id::hid_t, mdc_nelmts::Ptr{Cint}, rdcc_nslots::Ptr{Csize_t}, rdcc_nbytes::Ptr{Csize_t}, rdcc_w0::Ptr{Cdouble})::herr_t "Error in h5p_get_cache (not annotated)"
@bind h5p_get_char_encoding(plist_id::hid_t, encoding::Ref{Cint})::herr_t "Error getting char encoding"
@bind h5p_get_chunk(plist_id::hid_t, n_dims::Cint, dims::Ptr{hsize_t})::Cint "Error getting chunk size"
@bind h5p_get_chunk_cache(dapl_id::hid_t, rdcc_nslots::Ptr{Csize_t}, rdcc_nbytes::Ptr{Csize_t}, rdcc_w0::Ptr{Cdouble})::herr_t "Error in h5p_get_chunk_cache (not annotated)"
@bind h5p_get_chunk_opts(plist_id::hid_t, opts::Ptr{Cuint})::herr_t "Error in h5p_get_chunk_opts (not annotated)"
@bind h5p_get_class(plist_id::hid_t)::hid_t "Error in h5p_get_class (not annotated)"
#@bind h5p_get_class_name(pclass_id::hid_t)::Ptr{Cchar} "Error in h5p_get_class_name (not annotated)"
@bind h5p_get_class_parent(pclass_id::hid_t)::hid_t "Error in h5p_get_class_parent (not annotated)"
@bind h5p_get_copy_object(plist_id::hid_t, copy_options::Ptr{Cuint})::herr_t "Error in h5p_get_copy_object (not annotated)"
@bind h5p_get_core_write_tracking(fapl_id::hid_t, is_enabled::Ptr{hbool_t}, page_size::Ptr{Csize_t})::herr_t "Error in h5p_get_core_write_tracking (not annotated)"
@bind h5p_get_create_intermediate_group(lcpl_id::hid_t, crt_intermed_group::Ref{Cuint})::herr_t "Error getting create intermediate group property"
@bind h5p_get_data_transform(plist_id::hid_t, expression::Ptr{Cchar}, size::Csize_t)::Cssize_t "Error in h5p_get_data_transform (not annotated)"
@bind h5p_get_driver(plist_id::hid_t)::hid_t "Error getting driver identifier"
@bind h5p_get_driver_info(plist_id::hid_t)::Ptr{Cvoid} "Error getting driver info"
@bind h5p_get_dset_no_attrs_hint(dcpl_id::hid_t, minimize::Ptr{hbool_t})::herr_t "Error in getting dataset no attributes hint property"
@bind h5p_get_dxpl_mpio(dxpl_id::hid_t, xfer_mode::Ptr{Cint})::herr_t "Error getting MPIO transfer mode"
@bind h5p_get_edc_check(plist_id::hid_t)::H5Z_EDC_t "Error in h5p_get_edc_check (not annotated)"
@bind h5p_get_efile_prefix(dapl_id::hid_t, prefix::Ptr{UInt8}, size::Csize_t)::Cssize_t "Error getting external file prefix"
@bind h5p_get_elink_acc_flags(lapl_id::hid_t, flags::Ptr{Cuint})::herr_t "Error in h5p_get_elink_acc_flags (not annotated)"
@bind h5p_get_elink_cb(lapl_id::hid_t, func::Ptr{H5L_elink_traverse_t}, op_data::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_elink_cb (not annotated)"
@bind h5p_get_elink_fapl(lapl_id::hid_t)::hid_t "Error in h5p_get_elink_fapl (not annotated)"
@bind h5p_get_elink_file_cache_size(plist_id::hid_t, efc_size::Ptr{Cuint})::herr_t "Error in h5p_get_elink_file_cache_size (not annotated)"
@bind h5p_get_elink_prefix(plist_id::hid_t, prefix::Ptr{Cchar}, size::Csize_t)::Cssize_t "Error in h5p_get_elink_prefix (not annotated)"
@bind h5p_get_est_link_info(plist_id::hid_t, est_num_entries::Ptr{Cuint}, est_name_len::Ptr{Cuint})::herr_t "Error in h5p_get_est_link_info (not annotated)"
@bind h5p_get_evict_on_close(fapl_id::hid_t, evict_on_close::Ptr{hbool_t})::herr_t "Error in h5p_get_evict_on_close (not annotated)"
@bind h5p_get_external(plist::hid_t, idx::Cuint, name_size::Csize_t, name::Ptr{Cuchar}, offset::Ptr{off_t}, size::Ptr{hsize_t})::herr_t "Error getting external file properties"
@bind h5p_get_external_count(plist::hid_t)::Cint "Error getting external count"
@bind h5p_get_family_offset(fapl_id::hid_t, offset::Ptr{hsize_t})::herr_t "Error in h5p_get_family_offset (not annotated)"
@bind h5p_get_fapl_core(fapl_id::hid_t, increment::Ptr{Csize_t}, backing_store::Ptr{hbool_t})::herr_t "Error in h5p_get_fapl_core (not annotated)"
@bind h5p_get_fapl_family(fapl_id::hid_t, memb_size::Ptr{hsize_t}, memb_fapl_id::Ptr{hid_t})::herr_t "Error in h5p_get_fapl_family (not annotated)"
@bind h5p_get_fapl_hdfs(fapl_id::hid_t, fa_out::Ptr{H5FD_hdfs_fapl_t})::herr_t "Error in h5p_get_fapl_hdfs (not annotated)"
@bind h5p_get_fapl_multi(fapl_id::hid_t, memb_map::Ptr{H5FD_mem_t}, memb_fapl::Ptr{hid_t}, memb_name::Ptr{Ptr{Cchar}}, memb_addr::Ptr{haddr_t}, relax::Ptr{hbool_t})::herr_t "Error in h5p_get_fapl_multi (not annotated)"
@bind h5p_get_fapl_splitter(fapl_id::hid_t, config_ptr::Ptr{H5FD_splitter_vfd_config_t})::herr_t "Error in h5p_get_fapl_splitter (not annotated)"
@bind h5p_get_fapl_ros3(fapl_id::hid_t, fa_out::Ptr{H5FD_ros3_fapl_t})::herr_t "Error in getting ros3 properties"
@bind h5p_get_fclose_degree(fapl_id::hid_t, fc_degree::Ref{Cint})::herr_t "Error getting close degree"
@bind h5p_get_file_image(fapl_id::hid_t, buf_ptr_ptr::Ptr{Ptr{Cvoid}}, buf_len_ptr::Ptr{Csize_t})::herr_t "Error in h5p_get_file_image (not annotated)"
@bind h5p_get_file_image_callbacks(fapl_id::hid_t, callbacks_ptr::Ptr{H5FD_file_image_callbacks_t})::herr_t "Error in h5p_get_file_image_callbacks (not annotated)"
@bind h5p_get_file_locking(fapl_id::hid_t, use_file_locking::Ptr{hbool_t}, ignore_when_disabled::Ptr{hbool_t})::herr_t "Error in h5p_get_file_locking (not annotated)"
@bind h5p_get_file_space(plist_id::hid_t, strategy::Ptr{H5F_file_space_type_t}, threshold::Ptr{hsize_t})::herr_t "Error in h5p_get_file_space (not annotated)"
@bind h5p_get_file_space_page_size(plist_id::hid_t, fsp_size::Ptr{hsize_t})::herr_t "Error in h5p_get_file_space_page_size (not annotated)"
@bind h5p_get_file_space_strategy(plist_id::hid_t, strategy::Ptr{H5F_fspace_strategy_t}, persist::Ptr{hbool_t}, threshold::Ptr{hsize_t})::herr_t "Error in h5p_get_file_space_strategy (not annotated)"
@bind h5p_get_fill_time(plist_id::hid_t, fill_time::Ptr{H5D_fill_time_t})::herr_t "Error in h5p_get_fill_time (not annotated)"
@bind h5p_get_fill_value(plist_id::hid_t, type_id::hid_t, value::Ptr{Cvoid})::herr_t "Error in h5p_get_fill_value (not annotated)"
@bind h5p_get_filter2(plist_id::hid_t, idx::Cuint, flags::Ptr{Cuint}, cd_nemlts::Ref{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{Cchar}, filter_config::Ptr{Cuint})::H5Z_filter_t "Error getting filter"
@bind h5p_get_filter_by_id2(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Ref{Cuint}, cd_nelmts::Ref{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{UInt8}, filter_config::Ptr{Cuint})::herr_t "Error getting filter ID"
@bind h5p_get_gc_references(fapl_id::hid_t, gc_ref::Ptr{Cuint})::herr_t "Error in h5p_get_gc_references (not annotated)"
@bind h5p_get_hyper_vector_size(fapl_id::hid_t, size::Ptr{Csize_t})::herr_t "Error in h5p_get_hyper_vector_size (not annotated)"
@bind h5p_get_istore_k(plist_id::hid_t, ik::Ptr{Cuint})::herr_t "Error in h5p_get_istore_k (not annotated)"
@bind h5p_get_layout(plist_id::hid_t)::Cint string("Error getting layout")
@bind h5p_get_libver_bounds(fapl_id::hid_t, low::Ref{Cint}, high::Ref{Cint})::herr_t "Error getting library version bounds"
@bind h5p_get_link_creation_order(plist_id::hid_t, crt_order_flags::Ptr{Cuint})::herr_t "Error getting link creation order"
@bind h5p_get_link_phase_change(plist_id::hid_t, max_compact::Ptr{Cuint}, min_dense::Ptr{Cuint})::herr_t "Error in h5p_get_link_phase_change (not annotated)"
@bind h5p_get_local_heap_size_hint(plist_id::hid_t, size_hint::Ref{Csize_t})::herr_t "Error getting local heap size hint"
@bind h5p_get_mcdt_search_cb(plist_id::hid_t, func::Ptr{H5O_mcdt_search_cb_t}, op_data::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_mcdt_search_cb (not annotated)"
@bind h5p_get_mdc_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t "Error in h5p_get_mdc_config (not annotated)"
@bind h5p_get_mdc_image_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_image_config_t})::herr_t "Error in h5p_get_mdc_image_config (not annotated)"
@bind h5p_get_mdc_log_options(plist_id::hid_t, is_enabled::Ptr{hbool_t}, location::Ptr{Cchar}, location_size::Ptr{Csize_t}, start_on_access::Ptr{hbool_t})::herr_t "Error in h5p_get_mdc_log_options (not annotated)"
@bind h5p_get_meta_block_size(fapl_id::hid_t, size::Ptr{hsize_t})::herr_t "Error in h5p_get_meta_block_size (not annotated)"
@bind h5p_get_metadata_read_attempts(plist_id::hid_t, attempts::Ptr{Cuint})::herr_t "Error in h5p_get_metadata_read_attempts (not annotated)"
@bind h5p_get_multi_type(fapl_id::hid_t, type::Ptr{H5FD_mem_t})::herr_t "Error in h5p_get_multi_type (not annotated)"
@bind h5p_get_nfilters(plist_id::hid_t)::Cint "Error getting nfilters"
@bind h5p_get_nlinks(plist_id::hid_t, nlinks::Ptr{Csize_t})::herr_t "Error in h5p_get_nlinks (not annotated)"
@bind h5p_get_nprops(id::hid_t, nprops::Ptr{Csize_t})::herr_t "Error in h5p_get_nprops (not annotated)"
@bind h5p_get_obj_track_times(plist_id::hid_t, track_times::Ref{UInt8})::herr_t "Error getting object time tracking"
@bind h5p_get_object_flush_cb(plist_id::hid_t, func::Ptr{H5F_flush_cb_t}, udata::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_object_flush_cb (not annotated)"
@bind h5p_get_page_buffer_size(plist_id::hid_t, buf_size::Ptr{Csize_t}, min_meta_perc::Ptr{Cuint}, min_raw_perc::Ptr{Cuint})::herr_t "Error in h5p_get_page_buffer_size (not annotated)"
@bind h5p_get_preserve(plist_id::hid_t)::Cint "Error in h5p_get_preserve (not annotated)"
@bind h5p_get_shared_mesg_index(plist_id::hid_t, index_num::Cuint, mesg_type_flags::Ptr{Cuint}, min_mesg_size::Ptr{Cuint})::herr_t "Error in h5p_get_shared_mesg_index (not annotated)"
@bind h5p_get_shared_mesg_nindexes(plist_id::hid_t, nindexes::Ptr{Cuint})::herr_t "Error in h5p_get_shared_mesg_nindexes (not annotated)"
@bind h5p_get_shared_mesg_phase_change(plist_id::hid_t, max_list::Ptr{Cuint}, min_btree::Ptr{Cuint})::herr_t "Error in h5p_get_shared_mesg_phase_change (not annotated)"
@bind h5p_get_sieve_buf_size(fapl_id::hid_t, size::Ptr{Csize_t})::herr_t "Error in h5p_get_sieve_buf_size (not annotated)"
@bind h5p_get_size(id::hid_t, name::Ptr{Cchar}, size::Ptr{Csize_t})::herr_t "Error in h5p_get_size (not annotated)"
@bind h5p_get_sizes(plist_id::hid_t, sizeof_addr::Ptr{Csize_t}, sizeof_size::Ptr{Csize_t})::herr_t "Error in h5p_get_sizes (not annotated)"
@bind h5p_get_small_data_block_size(fapl_id::hid_t, size::Ptr{hsize_t})::herr_t "Error in h5p_get_small_data_block_size (not annotated)"
@bind h5p_get_sym_k(plist_id::hid_t, ik::Ptr{Cuint}, lk::Ptr{Cuint})::herr_t "Error in h5p_get_sym_k (not annotated)"
@bind h5p_get_type_conv_cb(dxpl_id::hid_t, op::Ptr{H5T_conv_except_func_t}, operate_data::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_type_conv_cb (not annotated)"
@bind h5p_get_userblock(plist_id::hid_t, len::Ptr{hsize_t})::herr_t "Error getting userblock"
@bind h5p_get_version(plist_id::hid_t, boot::Ptr{Cuint}, freelist::Ptr{Cuint}, stab::Ptr{Cuint}, shhdr::Ptr{Cuint})::herr_t "Error in h5p_get_version (not annotated)"
@bind h5p_get_virtual_count(dcpl_id::hid_t, count::Ptr{Csize_t})::herr_t "Error in h5p_get_virtual_count (not annotated)"
@bind h5p_get_virtual_dsetname(dcpl_id::hid_t, index::Csize_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t "Error in h5p_get_virtual_dsetname (not annotated)"
@bind h5p_get_virtual_filename(dcpl_id::hid_t, index::Csize_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t "Error in h5p_get_virtual_filename (not annotated)"
@bind h5p_get_virtual_prefix(dapl_id::hid_t, prefix::Ptr{Cchar}, size::Csize_t)::Cssize_t "Error in h5p_get_virtual_prefix (not annotated)"
@bind h5p_get_virtual_printf_gap(dapl_id::hid_t, gap_size::Ptr{hsize_t})::herr_t "Error in h5p_get_virtual_printf_gap (not annotated)"
@bind h5p_get_virtual_srcspace(dcpl_id::hid_t, index::Csize_t)::hid_t "Error in h5p_get_virtual_srcspace (not annotated)"
@bind h5p_get_virtual_view(dapl_id::hid_t, view::Ptr{H5D_vds_view_t})::herr_t "Error in h5p_get_virtual_view (not annotated)"
@bind h5p_get_virtual_vspace(dcpl_id::hid_t, index::Csize_t)::hid_t "Error in h5p_get_virtual_vspace (not annotated)"
@bind h5p_get_vlen_mem_manager(plist_id::hid_t, alloc_func::Ptr{H5MM_allocate_t}, alloc_info::Ptr{Ptr{Cvoid}}, free_func::Ptr{H5MM_free_t}, free_info::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_vlen_mem_manager (not annotated)"
@bind h5p_get_vol_id(plist_id::hid_t, vol_id::Ptr{hid_t})::herr_t "Error in h5p_get_vol_id (not annotated)"
@bind h5p_get_vol_info(plist_id::hid_t, vol_info::Ptr{Ptr{Cvoid}})::herr_t "Error in h5p_get_vol_info (not annotated)"

# set
@bind h5p_set(plist_id::hid_t, name::Cstring, value::Ptr{Cvoid})::herr_t "Error in h5p_set (not annotated)"
@bind h5p_set_alignment(plist_id::hid_t, threshold::hsize_t, alignment::hsize_t)::herr_t "Error setting alignment"
@bind h5p_set_alloc_time(plist_id::hid_t, alloc_time::Cint)::herr_t "Error setting allocation timing"
@bind h5p_set_append_flush(dapl_id::hid_t, ndims::Cuint, boundary::Ptr{hsize_t}, func::H5D_append_cb_t, udata::Ptr{Cvoid})::herr_t "Error in h5p_set_append_flush (not annotated)"
@bind h5p_set_attr_creation_order(plist_id::hid_t, crt_order_flags::Cuint)::herr_t "Error setting attribute creation order"
@bind h5p_set_attr_phase_change(plist_id::hid_t, max_compact::Cuint, min_dense::Cuint)::herr_t "Error in h5p_set_attr_phase_change (not annotated)"
@bind h5p_set_btree_ratios(plist_id::hid_t, left::Cdouble, middle::Cdouble, right::Cdouble)::herr_t "Error in h5p_set_btree_ratios (not annotated)"
@bind h5p_set_buffer(plist_id::hid_t, size::Csize_t, tconv::Ptr{Cvoid}, bkg::Ptr{Cvoid})::herr_t "Error in h5p_set_buffer (not annotated)"
@bind h5p_set_cache(plist_id::hid_t, mdc_nelmts::Cint, rdcc_nslots::Csize_t, rdcc_nbytes::Csize_t, rdcc_w0::Cdouble)::herr_t "Error in h5p_set_cache (not annotated)"
@bind h5p_set_char_encoding(plist_id::hid_t, encoding::Cint)::herr_t "Error setting char encoding"
@bind h5p_set_chunk(plist_id::hid_t, ndims::Cint, dims::Ptr{hsize_t})::herr_t "Error setting chunk size"
@bind h5p_set_chunk_cache(dapl_id::hid_t, rdcc_nslots::Csize_t, rdcc_nbytes::Csize_t, rdcc_w0::Cdouble)::herr_t "Error setting chunk cache"
@bind h5p_set_chunk_opts(plist_id::hid_t, opts::Cuint)::herr_t "Error in h5p_set_chunk_opts (not annotated)"
@bind h5p_set_copy_object(plist_id::hid_t, copy_options::Cuint)::herr_t "Error in h5p_set_copy_object (not annotated)"
@bind h5p_set_core_write_tracking(fapl_id::hid_t, is_enabled::hbool_t, page_size::Csize_t)::herr_t "Error in h5p_set_core_write_tracking (not annotated)"
@bind h5p_set_create_intermediate_group(plist_id::hid_t, setting::Cuint)::herr_t "Error setting create intermediate group"
@bind h5p_set_data_transform(plist_id::hid_t, expression::Cstring)::herr_t "Error in h5p_set_data_transform (not annotated)"
@bind h5p_set_deflate(plist_id::hid_t, setting::Cuint)::herr_t "Error setting compression method and level (deflate)"
@bind h5p_set_driver(plist_id::hid_t, driver_id::hid_t, driver_info::Ptr{Cvoid})::herr_t "Error in h5p_set_driver (not annotated)"
@bind h5p_set_dset_no_attrs_hint(dcpl_id::hid_t, minimize::hbool_t)::herr_t "Error in setting dataset no attributes hint property"
@bind h5p_set_dxpl_mpio(dxpl_id::hid_t, xfer_mode::Cint)::herr_t "Error setting MPIO transfer mode"
@bind h5p_set_edc_check(plist_id::hid_t, check::H5Z_EDC_t)::herr_t "Error in h5p_set_edc_check (not annotated)"
@bind h5p_set_efile_prefix(plist_id::hid_t, prefix::Cstring)::herr_t "Error setting external file prefix"
@bind h5p_set_elink_acc_flags(lapl_id::hid_t, flags::Cuint)::herr_t "Error in h5p_set_elink_acc_flags (not annotated)"
@bind h5p_set_elink_cb(lapl_id::hid_t, func::H5L_elink_traverse_t, op_data::Ptr{Cvoid})::herr_t "Error in h5p_set_elink_cb (not annotated)"
@bind h5p_set_elink_fapl(lapl_id::hid_t, fapl_id::hid_t)::herr_t "Error in h5p_set_elink_fapl (not annotated)"
@bind h5p_set_elink_file_cache_size(plist_id::hid_t, efc_size::Cuint)::herr_t "Error in h5p_set_elink_file_cache_size (not annotated)"
@bind h5p_set_elink_prefix(plist_id::hid_t, prefix::Cstring)::herr_t "Error in h5p_set_elink_prefix (not annotated)"
@bind h5p_set_est_link_info(plist_id::hid_t, est_num_entries::Cuint, est_name_len::Cuint)::herr_t "Error in h5p_set_est_link_info (not annotated)"
@bind h5p_set_evict_on_close(fapl_id::hid_t, evict_on_close::hbool_t)::herr_t "Error in h5p_set_evict_on_close (not annotated)"
@bind h5p_set_external(plist_id::hid_t, name::Cstring, offset::off_t, size::hsize_t)::herr_t "Error setting external property"
@bind h5p_set_family_offset(fapl_id::hid_t, offset::hsize_t)::herr_t "Error in h5p_set_family_offset (not annotated)"
@bind h5p_set_fapl_core(fapl_id::hid_t, increment::Csize_t, backing_store::hbool_t)::herr_t "Error in h5p_set_fapl_core (not annotated)"
@bind h5p_set_fapl_family(fapl_id::hid_t, memb_size::hsize_t, memb_fapl_id::hid_t)::herr_t "Error in h5p_set_fapl_family (not annotated)"
@bind h5p_set_fapl_hdfs(fapl_id::hid_t, fa::Ptr{H5FD_hdfs_fapl_t})::herr_t "Error in h5p_set_fapl_hdfs (not annotated)"
@bind h5p_set_fapl_log(fapl_id::hid_t, logfile::Cstring, flags::Culonglong, buf_size::Csize_t)::herr_t "Error in h5p_set_fapl_log (not annotated)"
@bind h5p_set_fapl_multi(fapl_id::hid_t, memb_map::Ptr{H5FD_mem_t}, memb_fapl::Ptr{hid_t}, memb_name::Ptr{Cstring}, memb_addr::Ptr{haddr_t}, relax::hbool_t)::herr_t "Error in h5p_set_fapl_multi (not annotated)"
@bind h5p_set_fapl_sec2(fapl_id::hid_t)::herr_t "Error setting Sec2 properties"
@bind h5p_set_fapl_ros3(fapl_id::hid_t, fa::Ptr{H5FD_ros3_fapl_t})::herr_t "Error in setting ros3 properties"
@bind h5p_set_fapl_split(fapl::hid_t, meta_ext::Cstring, meta_plist_id::hid_t, raw_ext::Cstring, raw_plist_id::hid_t)::herr_t "Error in h5p_set_fapl_split (not annotated)"
@bind h5p_set_fapl_splitter(fapl_id::hid_t, config_ptr::Ptr{H5FD_splitter_vfd_config_t})::herr_t "Error in h5p_set_fapl_splitter (not annotated)"
@bind h5p_set_fapl_stdio(fapl_id::hid_t)::herr_t "Error in h5p_set_fapl_stdio (not annotated)"
@bind h5p_set_fapl_windows(fapl_id::hid_t)::herr_t "Error in h5p_set_fapl_windows (not annotated)"
@bind h5p_set_fclose_degree(plist_id::hid_t, fc_degree::Cint)::herr_t "Error setting close degree"
@bind h5p_set_file_image(fapl_id::hid_t, buf_ptr::Ptr{Cvoid}, buf_len::Csize_t)::herr_t "Error in h5p_set_file_image (not annotated)"
@bind h5p_set_file_image_callbacks(fapl_id::hid_t, callbacks_ptr::Ptr{H5FD_file_image_callbacks_t})::herr_t "Error in h5p_set_file_image_callbacks (not annotated)"
@bind h5p_set_file_locking(fapl_id::hid_t, use_file_locking::hbool_t, ignore_when_disabled::hbool_t)::herr_t "Error in h5p_set_file_locking (not annotated)"
@bind h5p_set_file_space(plist_id::hid_t, strategy::H5F_file_space_type_t, threshold::hsize_t)::herr_t "Error in h5p_set_file_space (not annotated)"
@bind h5p_set_file_space_page_size(plist_id::hid_t, fsp_size::hsize_t)::herr_t "Error in h5p_set_file_space_page_size (not annotated)"
@bind h5p_set_file_space_strategy(plist_id::hid_t, strategy::H5F_fspace_strategy_t, persist::hbool_t, threshold::hsize_t)::herr_t "Error in h5p_set_file_space_strategy (not annotated)"
@bind h5p_set_fill_time(plist_id::hid_t, fill_time::H5D_fill_time_t)::herr_t "Error in h5p_set_fill_time (not annotated)"
@bind h5p_set_fill_value(plist_id::hid_t, type_id::hid_t, value::Ptr{Cvoid})::herr_t "Error in h5p_set_fill_value (not annotated)"
@bind h5p_set_filter(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})::herr_t "Error setting filter"
@bind h5p_set_filter_callback(plist_id::hid_t, func::H5Z_filter_func_t, op_data::Ptr{Cvoid})::herr_t "Error in h5p_set_filter_callback (not annotated)"
@bind h5p_set_fletcher32(plist_id::hid_t)::herr_t "Error enabling Fletcher32 filter"
@bind h5p_set_gc_references(fapl_id::hid_t, gc_ref::Cuint)::herr_t "Error in h5p_set_gc_references (not annotated)"
@bind h5p_set_hyper_vector_size(plist_id::hid_t, size::Csize_t)::herr_t "Error in h5p_set_hyper_vector_size (not annotated)"
@bind h5p_set_istore_k(plist_id::hid_t, ik::Cuint)::herr_t "Error in h5p_set_istore_k (not annotated)"
@bind h5p_set_layout(plist_id::hid_t, setting::Cint)::herr_t "Error setting layout"
@bind h5p_set_libver_bounds(fapl_id::hid_t, low::Cint, high::Cint)::herr_t "Error setting library version bounds"
@bind h5p_set_link_creation_order(plist_id::hid_t, crt_order_flags::Cuint)::herr_t "Error setting link creation order"
@bind h5p_set_link_phase_change(plist_id::hid_t, max_compact::Cuint, min_dense::Cuint)::herr_t "Error in h5p_set_link_phase_change (not annotated)"
@bind h5p_set_local_heap_size_hint(plist_id::hid_t, size_hint::Csize_t)::herr_t "Error setting local heap size hint"
@bind h5p_set_mcdt_search_cb(plist_id::hid_t, func::H5O_mcdt_search_cb_t, op_data::Ptr{Cvoid})::herr_t "Error in h5p_set_mcdt_search_cb (not annotated)"
@bind h5p_set_mdc_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t "Error in h5p_set_mdc_config (not annotated)"
@bind h5p_set_mdc_image_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_image_config_t})::herr_t "Error in h5p_set_mdc_image_config (not annotated)"
@bind h5p_set_mdc_log_options(plist_id::hid_t, is_enabled::hbool_t, location::Cstring, start_on_access::hbool_t)::herr_t "Error in h5p_set_mdc_log_options (not annotated)"
@bind h5p_set_meta_block_size(fapl_id::hid_t, size::hsize_t)::herr_t "Error in h5p_set_meta_block_size (not annotated)"
@bind h5p_set_metadata_read_attempts(plist_id::hid_t, attempts::Cuint)::herr_t "Error in h5p_set_metadata_read_attempts (not annotated)"
@bind h5p_set_multi_type(fapl_id::hid_t, type::H5FD_mem_t)::herr_t "Error in h5p_set_multi_type (not annotated)"
@bind h5p_set_nbit(plist_id::hid_t)::herr_t "Error enabling nbit filter"
@bind h5p_set_nlinks(plist_id::hid_t, nlinks::Csize_t)::herr_t "Error in h5p_set_nlinks (not annotated)"
@bind h5p_set_obj_track_times(plist_id::hid_t, track_times::UInt8)::herr_t "Error setting object time tracking"
@bind h5p_set_object_flush_cb(plist_id::hid_t, func::H5F_flush_cb_t, udata::Ptr{Cvoid})::herr_t "Error in h5p_set_object_flush_cb (not annotated)"
@bind h5p_set_page_buffer_size(plist_id::hid_t, buf_size::Csize_t, min_meta_per::Cuint, min_raw_per::Cuint)::herr_t "Error in h5p_set_page_buffer_size (not annotated)"
@bind h5p_set_preserve(plist_id::hid_t, status::hbool_t)::herr_t "Error in h5p_set_preserve (not annotated)"
@bind h5p_set_scaleoffset(plist_id::hid_t, scale_type::Cint, scale_factor::Cint)::herr_t "Error enabling szip filter"
@bind h5p_set_shared_mesg_index(plist_id::hid_t, index_num::Cuint, mesg_type_flags::Cuint, min_mesg_size::Cuint)::herr_t "Error in h5p_set_shared_mesg_index (not annotated)"
@bind h5p_set_shared_mesg_nindexes(plist_id::hid_t, nindexes::Cuint)::herr_t "Error in h5p_set_shared_mesg_nindexes (not annotated)"
@bind h5p_set_shared_mesg_phase_change(plist_id::hid_t, max_list::Cuint, min_btree::Cuint)::herr_t "Error in h5p_set_shared_mesg_phase_change (not annotated)"
@bind h5p_set_shuffle(plist_id::hid_t)::herr_t "Error enabling shuffle filter"
@bind h5p_set_sieve_buf_size(fapl_id::hid_t, size::Csize_t)::herr_t "Error in h5p_set_sieve_buf_size (not annotated)"
@bind h5p_set_sizes(plist_id::hid_t, sizeof_addr::Csize_t, sizeof_size::Csize_t)::herr_t "Error in h5p_set_sizes (not annotated)"
@bind h5p_set_small_data_block_size(fapl_id::hid_t, size::hsize_t)::herr_t "Error in h5p_set_small_data_block_size (not annotated)"
@bind h5p_set_sym_k(plist_id::hid_t, ik::Cuint, lk::Cuint)::herr_t "Error in h5p_set_sym_k (not annotated)"
@bind h5p_set_szip(plist_id::hid_t, options_mask::Cuint, pixels_per_block::Cuint)::herr_t "Error enabling szip filter"
@bind h5p_set_type_conv_cb(dxpl_id::hid_t, op::H5T_conv_except_func_t, operate_data::Ptr{Cvoid})::herr_t "Error in h5p_set_type_conv_cb (not annotated)"
@bind h5p_set_userblock(plist_id::hid_t, len::hsize_t)::herr_t "Error setting userblock"
@bind h5p_set_virtual(dcpl_id::hid_t, vspace_id::hid_t, src_file_name::Cstring, src_dset_name::Cstring, src_space_id::hid_t)::herr_t "Error setting virtual"
@bind h5p_set_virtual_prefix(dapl_id::hid_t, prefix::Cstring)::herr_t "Error in h5p_set_virtual_prefix (not annotated)"
@bind h5p_set_virtual_printf_gap(dapl_id::hid_t, gap_size::hsize_t)::herr_t "Error in h5p_set_virtual_printf_gap (not annotated)"
@bind h5p_set_virtual_view(dapl_id::hid_t, view::H5D_vds_view_t)::herr_t "Error in h5p_set_virtual_view (not annotated)"
@bind h5p_set_vlen_mem_manager(plist_id::hid_t, alloc_func::H5MM_allocate_t, alloc_info::Ptr{Cvoid}, free_func::H5MM_free_t, free_info::Ptr{Cvoid})::herr_t "Error in h5p_set_vlen_mem_manager (not annotated)"
@bind h5p_set_vol(plist_id::hid_t, new_vol_id::hid_t, new_vol_info::Ptr{Cvoid})::herr_t "Error in h5p_set_vol (not annotated)"

# others

@bind h5p_add_merge_committed_dtype_path(plist_id::hid_t, path::Cstring)::herr_t "Error in h5p_add_merge_committed_dtype_path (not annotated)"
@bind h5p_all_filters_avail(plist_id::hid_t)::htri_t "Error in h5p_all_filters_avail (not annotated)"
@bind h5p_close(id::hid_t)::herr_t "Error closing property list"
@bind h5p_close_class(plist_id::hid_t)::herr_t "Error in h5p_close_class (not annotated)"
@bind h5p_copy(plist_id::hid_t)::hid_t "Error in h5p_copy (not annotated)"
@bind h5p_copy_prop(dst_id::hid_t, src_id::hid_t, name::Cstring)::herr_t "Error in h5p_copy_prop (not annotated)"
@bind h5p_create(cls_id::hid_t)::hid_t "Error creating property list"
@bind h5p_create_class(parent::hid_t, name::Cstring, create::H5P_cls_create_func_t, create_data::Ptr{Cvoid}, copy::H5P_cls_copy_func_t, copy_data::Ptr{Cvoid}, close::H5P_cls_close_func_t, close_data::Ptr{Cvoid})::hid_t "Error in h5p_create_class (not annotated)"
@bind h5p_decode(buf::Ptr{Cvoid})::hid_t "Error in h5p_decode (not annotated)"
@bind h5p_encode1(plist_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t})::herr_t "Error in h5p_encode1 (not annotated)"
@bind h5p_encode2(plist_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t}, fapl_id::hid_t)::herr_t "Error in h5p_encode2 (not annotated)"
@bind h5p_equal(id1::hid_t, id2::hid_t)::htri_t "Error in h5p_equal (not annotated)"
@bind h5p_exist(plist_id::hid_t, name::Cstring)::htri_t "Error in h5p_exist (not annotated)"
@bind h5p_fill_value_defined(plist::hid_t, status::Ptr{H5D_fill_value_t})::herr_t "Error in h5p_fill_value_defined (not annotated)"
@bind h5p_free_merge_committed_dtype_paths(plist_id::hid_t)::herr_t "Error in h5p_free_merge_committed_dtype_paths (not annotated)"
@bind h5p_insert1(plist_id::hid_t, name::Cstring, size::Csize_t, value::Ptr{Cvoid}, prp_set::H5P_prp_set_func_t, prp_get::H5P_prp_get_func_t, prp_delete::H5P_prp_delete_func_t, prp_copy::H5P_prp_copy_func_t, prp_close::H5P_prp_close_func_t)::herr_t "Error in h5p_insert1 (not annotated)"
@bind h5p_insert2(plist_id::hid_t, name::Cstring, size::Csize_t, value::Ptr{Cvoid}, set::H5P_prp_set_func_t, get::H5P_prp_get_func_t, prp_del::H5P_prp_delete_func_t, copy::H5P_prp_copy_func_t, compare::H5P_prp_compare_func_t, close::H5P_prp_close_func_t)::herr_t "Error in h5p_insert2 (not annotated)"
@bind h5p_isa_class(plist_id::hid_t, pclass_id::hid_t)::htri_t "Error in h5p_isa_class (not annotated)"
@bind h5p_iterate(id::hid_t, idx::Ptr{Cint}, iter_func::H5P_iterate_t, iter_data::Ptr{Cvoid})::Cint "Error in h5p_iterate (not annotated)"
@bind h5p_modify_filter(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})::herr_t "Error modifying filter"
@bind h5p_register1(cls_id::hid_t, name::Cstring, size::Csize_t, def_value::Ptr{Cvoid}, prp_create::H5P_prp_create_func_t, prp_set::H5P_prp_set_func_t, prp_get::H5P_prp_get_func_t, prp_del::H5P_prp_delete_func_t, prp_copy::H5P_prp_copy_func_t, prp_close::H5P_prp_close_func_t)::herr_t "Error in h5p_register1 (not annotated)"
@bind h5p_register2(cls_id::hid_t, name::Cstring, size::Csize_t, def_value::Ptr{Cvoid}, create::H5P_prp_create_func_t, set::H5P_prp_set_func_t, get::H5P_prp_get_func_t, prp_del::H5P_prp_delete_func_t, copy::H5P_prp_copy_func_t, compare::H5P_prp_compare_func_t, close::H5P_prp_close_func_t)::herr_t "Error in h5p_register2 (not annotated)"
@bind h5p_remove(plist_id::hid_t, name::Cstring)::herr_t "Error in h5p_remove (not annotated)"
@bind h5p_remove_filter(plist_id::hid_t, filter_id::H5Z_filter_t)::herr_t "Error removing filter"
@bind h5p_unregister(pclass_id::hid_t, name::Cstring)::herr_t "Error in h5p_unregister (not annotated)"

###
### Plugin Interface
###

@bind h5pl_set_loading_state(plugin_control_mask::Cuint)::herr_t "Error setting plugin loading state"
@bind h5pl_get_loading_state(plugin_control_mask::Ptr{Cuint})::herr_t "Error getting plugin loading state"
@bind h5pl_append(search_path::Cstring)::herr_t "Error appending plugin path"
@bind h5pl_prepend(search_path::Cstring)::herr_t "Error prepending plugin path"
@bind h5pl_replace(search_path::Cstring, index::Cuint)::herr_t "Error replacing plugin path"
@bind h5pl_insert(search_path::Cstring, index::Cuint)::herr_t "Error inserting plugin path"
@bind h5pl_remove(index::Cuint)::herr_t "Error removing plugin path"
@bind h5pl_get(index::Cuint, path_buf::Ptr{Cchar}, buf_size::Csize_t)::Cssize_t "Error getting plugin path"
@bind h5pl_size(num_paths::Ptr{Cuint})::herr_t "Error in getting number of plugins paths"

###
### Reference Interface
###

@bind h5r_create(ref::Ptr{Cvoid}, loc_id::hid_t, pathname::Cstring, ref_type::Cint, space_id::hid_t)::herr_t string("Error creating reference to object ", h5i_get_name(loc_id), "/", pathname)
@bind h5r_dereference2(obj_id::hid_t, oapl_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid})::hid_t "Error dereferencing object"
@bind h5r_get_obj_type2(loc_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid}, obj_type::Ptr{Cint})::herr_t "Error getting object type"
@bind h5r_get_region(loc_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid})::hid_t "Error getting region from reference"

###
### Dataspace Interface
###

@bind h5s_close(space_id::hid_t)::herr_t "Error closing dataspace"
@bind h5s_combine_hyperslab(dspace_id::hid_t, seloper::H5S_seloper_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t "Error selecting hyperslab"
@bind h5s_combine_select(space1_id::hid_t, op::H5S_seloper_t , space2_id::hid_t)::hid_t "Error combining dataspaces" (v"1.10.7", nothing)
@bind h5s_copy(space_id::hid_t)::hid_t "Error copying dataspace"
@bind h5s_create(class::Cint)::hid_t "Error creating dataspace"
@bind h5s_create_simple(rank::Cint, current_dims::Ptr{hsize_t}, maximum_dims::Ptr{hsize_t})::hid_t "Error creating simple dataspace"
@bind h5s_extent_copy(dst::hid_t, src::hid_t)::herr_t "Error copying extent"
@bind h5s_extent_equal(space1_id::hid_t, space2_id::hid_t)::htri_t "Error comparing dataspaces"
@bind h5s_get_regular_hyperslab(space_id::hid_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t "Error getting regular hyperslab selection"
@bind h5s_get_select_bounds(space_id::hid_t, starts::Ptr{hsize_t}, ends::Ptr{hsize_t})::herr_t "Error getting bounding box for selection"
@bind h5s_get_select_elem_npoints(space_id::hid_t)::hssize_t "Error getting number of elements in dataspace selection"
@bind h5s_get_select_elem_pointlist(space_id::hid_t, startpoint::hsize_t, numpoints::hsize_t, buf::Ptr{hsize_t})::herr_t "Error getting list of element points"
@bind h5s_get_select_hyper_blocklist(space_id::hid_t, startblock::hsize_t, numblocks::hsize_t, buf::Ptr{hsize_t})::herr_t "Error getting list of hyperslab blocks"
@bind h5s_get_select_hyper_nblocks(space_id::hid_t)::hssize_t "Error getting number of selected blocks"
@bind h5s_get_select_npoints(space_id::hid_t)::hsize_t "Error getting the number of selected points"
@bind h5s_get_select_type(space_id::hid_t)::H5S_sel_type "Error getting the selection type"
@bind h5s_get_simple_extent_dims(space_id::hid_t, dims::Ptr{hsize_t}, maxdims::Ptr{hsize_t})::Cint "Error getting the dimensions for a dataspace"
@bind h5s_get_simple_extent_ndims(space_id::hid_t)::Cint "Error getting the number of dimensions for a dataspace"
@bind h5s_get_simple_extent_type(space_id::hid_t)::H5S_class_t "Error getting the dataspace type"
@bind h5s_is_regular_hyperslab(space_id::hid_t)::htri_t "Error determining whether datapace is regular hyperslab"
@bind h5s_is_simple(space_id::hid_t)::htri_t "Error determining whether dataspace is simple"
@bind h5s_modify_select(space_id::hid_t, op::H5S_seloper_t, space2_id::hid_t)::herr_t "Error modifying selection"
@bind h5s_offset_simple(space_id::hid_t, offset::Ptr{hssize_t})::herr_t "Error offsetting simple dataspace extent"
@bind h5s_select_adjust(space_id::hid_t, offset::Ptr{hssize_t})::herr_t "Error adjusting selection offset"
@bind h5s_select_all(space_id::hid_t)::herr_t "Error selecting all of dataspace"
@bind h5s_select_copy(dst::hid_t, src::hid_t)::herr_t "Error copying selection"
@bind h5s_select_elements(space_id::hid_t, op::H5S_seloper_t, num_elem::Csize_t, coord::Ptr{hsize_t})::herr_t "Error selecting elements"
@bind h5s_select_hyperslab(dspace_id::hid_t, seloper::H5S_seloper_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t "Error selecting hyperslab"
@bind h5s_select_intersect_block(space_id::hid_t, starts::Ptr{hsize_t}, ends::Ptr{hsize_t})::htri_t "Error determining whether selection intersects block"
@bind h5s_select_shape_same(space1_id::hid_t, space2_id::hid_t)::htri_t "Error determining whether dataspace shapes are the same"
@bind h5s_select_valid(spaceid::hid_t)::htri_t "Error determining whether selection is within extent"
@bind h5s_set_extent_none(space_id::hid_t)::herr_t "Error setting dataspace extent to none"
@bind h5s_set_extent_simple(dspace_id::hid_t, rank::Cint, current_size::Ptr{hsize_t}, maximum_size::Ptr{hsize_t})::herr_t "Error setting dataspace size"

###
### Datatype Interface
###

@bind h5t_array_create2(basetype_id::hid_t, ndims::Cuint, sz::Ptr{hsize_t})::hid_t string("Error creating H5T_ARRAY of id ", basetype_id, " and size ", sz)
@bind h5t_close(dtype_id::hid_t)::herr_t "Error closing datatype"
@bind h5t_committed(dtype_id::hid_t)::htri_t "Error determining whether datatype is committed"
@bind h5t_commit2(loc_id::hid_t, name::Cstring, dtype_id::hid_t, lcpl_id::hid_t, tcpl_id::hid_t, tapl_id::hid_t)::herr_t "Error committing type"
# @bind h5t_commit_anon
# @bind h5t_compiler_conv
@bind h5t_copy(dtype_id::hid_t)::hid_t "Error copying datatype"
@bind h5t_create(class_id::Cint, sz::Csize_t)::hid_t string("Error creating datatype of id ", class_id)
# @bind h5t_decode
# @bind h5t_detect_class
# @bind h5t_encode
# @bind h5t_enum_create
@bind h5t_enum_insert(dtype_id::hid_t, name::Cstring, value::Ptr{Cvoid})::herr_t string("Error adding ", name, " to enum datatype")
# @bind h5t_enum_nameof
# @bind h5t_enum_valueof
@bind h5t_equal(dtype_id1::hid_t, dtype_id2::hid_t)::htri_t "Error checking datatype equality"
# @bind ht5_find
@bind h5t_get_array_dims2(dtype_id::hid_t, dims::Ptr{hsize_t})::Cint "Error getting dimensions of array"
@bind h5t_get_array_ndims(dtype_id::hid_t)::Cint "Error getting ndims of array"
@bind h5t_get_class(dtype_id::hid_t)::Cint "Error getting class"
@bind h5t_get_cset(dtype_id::hid_t)::Cint "Error getting character set encoding"
@bind h5t_get_ebias(dtype_id::hid_t)::Csize_t "Error getting exponent bias"
@bind h5t_get_fields(dtype_id::hid_t, spos::Ref{Csize_t}, epos::Ref{Csize_t}, esize::Ref{Csize_t}, mpos::Ref{Csize_t}, msize::Ref{Csize_t})::herr_t "Error getting datatype floating point bit positions"
@bind h5t_get_member_class(dtype_id::hid_t, index::Cuint)::Cint string("Error getting class of compound datatype member #", index)
@bind h5t_get_member_index(dtype_id::hid_t, membername::Cstring)::Cint string("Error getting index of compound datatype member \"", membername, "\"")
# @bind h5t_get_member_name(dtype_id::hid_t, index::Cuint)::Cstring string("Error getting name of compound datatype member #", index) # See below
@bind h5t_get_member_offset(dtype_id::hid_t, index::Cuint)::Csize_t "Error getting offset of compound datatype #$(index)"
@bind h5t_get_member_type(dtype_id::hid_t, index::Cuint)::hid_t string("Error getting type of compound datatype member #", index)
# @bind h5t_get_member_value
@bind h5t_get_native_type(dtype_id::hid_t, direction::Cint)::hid_t "Error getting native type"
@bind h5t_get_nmembers(dtype_id::hid_t)::Cint "Error getting the number of members"
# @bind h5t_get_norm
@bind h5t_get_offset(dtype_id::hid_t)::Cint "Error getting offset"
@bind h5t_get_order(dtype_id::hid_t)::Cint "Error getting order"
# @bind h5t_get_pad(dtype_id::hid_t, lsb::Ptr{H5T_pad_t}, msb::Ptr{H5T_pad_t})::herr_t "Error getting pad"
@bind h5t_get_precision(dtype_id::hid_t)::Csize_t "Error getting precision"
@bind h5t_get_sign(dtype_id::hid_t)::Cint "Error getting sign"
@bind h5t_get_size(dtype_id::hid_t)::Csize_t "Error getting type size"
@bind h5t_get_strpad(dtype_id::hid_t)::Cint "Error getting string padding"
@bind h5t_get_super(dtype_id::hid_t)::hid_t "Error getting super type"
# @bind h5t_get_tag(type_id::hid_t)::Cstring "Error getting datatype opaque tag" # See below
@bind h5t_insert(dtype_id::hid_t, fieldname::Cstring, offset::Csize_t, field_id::hid_t)::herr_t string("Error adding field ", fieldname, " to compound datatype")
@bind h5t_is_variable_str(type_id::hid_t)::htri_t "Error determining whether string is of variable length"
@bind h5t_lock(type_id::hid_t)::herr_t "Error locking type"
@bind h5t_open2(loc_id::hid_t, name::Cstring, tapl_id::hid_t)::hid_t string("Error opening type ", h5i_get_name(loc_id), "/", name)
# @bind h5t_pack
# @bind h5t_reclaim
# @bind h5t_refresh
# @bind h5t_register
@bind h5t_set_cset(dtype_id::hid_t, cset::Cint)::herr_t "Error setting character set in datatype"
@bind h5t_set_ebias(dtype_id::hid_t, ebias::Csize_t)::herr_t "Error setting datatype floating point exponent bias"
@bind h5t_set_fields(dtype_id::hid_t, spos::Csize_t, epos::Csize_t, esize::Csize_t, mpos::Csize_t, msize::Csize_t)::herr_t "Error setting datatype floating point bit positions"
# @bind h5t_set_inpad(dtype_id::hid_t, inpad::H5T_pad_t)::herr_t "Error setting inpad"
# @bind h5t_set_norm(dtype_id::hid_t, norm::H5T_norm_t)::herr_t "Error setting mantissa"
@bind h5t_set_offset(dtype_id::hid_t, offset::Csize_t)::herr_t "Error setting offset"
@bind h5t_set_order(dtype_id::hid_t, order::Cint)::herr_t "Error setting order"
@bind h5t_set_precision(dtype_id::hid_t, sz::Csize_t)::herr_t "Error setting precision of datatype"
@bind h5t_set_size(dtype_id::hid_t, sz::Csize_t)::herr_t "Error setting size of datatype"
@bind h5t_set_strpad(dtype_id::hid_t, sz::Cint)::herr_t "Error setting size of datatype"
@bind h5t_set_tag(dtype_id::hid_t, tag::Cstring)::herr_t "Error setting opaque tag"
# @bind h5t_unregister
@bind h5t_vlen_create(base_type_id::hid_t)::hid_t "Error creating vlen type"
# The following are not automatically wrapped since they have requirements about freeing
# the memory that is returned from the calls. They are implemented via api_helpers.jl
#@bind h5t_get_member_name(dtype_id::hid_t, index::Cuint)::Cstring string("Error getting name of compound datatype member #", index)
#@bind h5t_get_tag(type_id::hid_t)::Cstring "Error getting datatype opaque tag"

###
### Optimized Functions Interface
###

@bind h5do_append(dset_id::hid_t, dxpl_id::hid_t, index::Cuint, num_elem::hsize_t, memtype::hid_t, buffer::Ptr{Cvoid})::herr_t "error appending"
# h5do_write_chunk is deprecated as of hdflib 1.10.3
@bind h5do_write_chunk(dset_id::hid_t, dxpl_id::hid_t, filter_mask::UInt32, offset::Ptr{hsize_t}, bufsize::Csize_t, buf::Ptr{Cvoid})::herr_t "Error writing chunk"

###
### High Level Dimension Scale Interface
###

@bind h5ds_attach_scale(did::hid_t, dsid::hid_t, idx::Cuint)::herr_t "Unable to attach scale"
@bind h5ds_detach_scale(did::hid_t, dsid::hid_t, idx::Cuint)::herr_t "Unable to detach scale"
@bind h5ds_get_label(did::hid_t, idx::Cuint, label::Ptr{UInt8}, size::hsize_t)::herr_t "Unable to get label"
@bind h5ds_get_num_scales(did::hid_t, idx::Cuint)::Cint "Error getting number of scales"
@bind h5ds_get_scale_name(did::hid_t, name::Ptr{UInt8}, size::Csize_t)::Cssize_t "Unable to get scale name"
@bind h5ds_is_attached(did::hid_t, dsid::hid_t, idx::Cuint)::htri_t "Unable to check if dimension is attached"
@bind h5ds_is_scale(did::hid_t)::htri_t "Unable to check if dataset is scale"
@bind h5ds_set_label(did::hid_t, idx::Cuint, label::Ref{UInt8})::herr_t "Unable to set label"
@bind h5ds_set_scale(dsid::hid_t, dimname::Cstring)::herr_t "Unable to set scale"


###
### HDF5 Lite Interface
###

@bind h5lt_dtype_to_text(datatype::hid_t, str::Ptr{UInt8}, lang_type::Cint, len::Ref{Csize_t})::herr_t "Error getting datatype text representation"

###
### Table Interface
###
@bind h5tb_append_records(loc_id::hid_t, dset_name::Cstring, nrecords::hsize_t, type_size::Csize_t, field_offset::Ptr{Csize_t}, field_sizes::Ptr{Csize_t}, data::Ptr{Cvoid})::herr_t "Error adding record to table"
@bind h5tb_get_field_info(loc_id::hid_t, table_name::Cstring, field_names::Ptr{Ptr{UInt8}}, field_sizes::Ptr{Csize_t}, field_offsets::Ptr{Csize_t}, type_size::Ptr{Csize_t})::herr_t "Error getting field information"
@bind h5tb_get_table_info(loc_id::hid_t, table_name::Cstring, nfields::Ptr{hsize_t}, nrecords::Ptr{hsize_t})::herr_t "Error getting table information"
# NOTE: The HDF5 docs incorrectly specify type_size::hsize_t where as it should be type_size::Csize_t
@bind h5tb_make_table(table_title::Cstring, loc_id::hid_t, dset_name::Cstring, nfields::hsize_t, nrecords::hsize_t, type_size::Csize_t, field_names::Ptr{Cstring}, field_offset::Ptr{Csize_t}, field_types::Ptr{hid_t}, chunk_size::hsize_t, fill_data::Ptr{Cvoid}, compress::Cint, data::Ptr{Cvoid})::herr_t "Error creating and writing dataset to table"
@bind h5tb_read_records(loc_id::hid_t, table_name::Cstring, start::hsize_t, nrecords::hsize_t, type_size::Csize_t, field_offsets::Ptr{Csize_t}, dst_sizes::Ptr{Csize_t}, data::Ptr{Cvoid})::herr_t "Error reading record from table"
@bind h5tb_read_table(loc_id::hid_t, table_name::Cstring, dst_size::Csize_t, dst_offset::Ptr{Csize_t}, dst_sizes::Ptr{Csize_t}, dst_buf::Ptr{Cvoid})::herr_t "Error reading table"
@bind h5tb_write_records(loc_id::hid_t, table_name::Cstring, start::hsize_t, nrecords::hsize_t, type_size::Csize_t, field_offsets::Ptr{Csize_t}, field_sizes::Ptr{Csize_t}, data::Ptr{Cvoid})::herr_t "Error writing record to table"

###
### Filter Interface
###

@bind h5z_register(filter_class::Ref{H5Z_class_t})::herr_t "Unable to register new filter"
@bind h5z_unregister(id::H5Z_filter_t)::herr_t "Unable to unregister filter"
@bind h5z_filter_avail(id::H5Z_filter_t)::htri_t "Unable to get check filter availability"
@bind h5z_get_filter_info(filter::H5Z_filter_t, filter_config_flags::Ptr{Cuint})::herr_t "Error getting filter information"

###
### File driver interface
### FD consts: these are defined in hdf5 as macros

@bind h5fd_core_init()::hid_t "Error initializing file driver"
@bind h5fd_family_init()::hid_t "Error initializing file driver"
@bind h5fd_log_init()::hid_t "Error initializing file driver"
@bind h5fd_mpio_init()::hid_t "Error initializing file driver"
@bind h5fd_multi_init()::hid_t "Error initializing file driver"
@bind h5fd_sec2_init()::hid_t "Error initializing file driver"
@bind h5fd_stdio_init()::hid_t "Error initializing file driver"
