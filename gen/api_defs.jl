# The `@bind` macro is used to automatically generate Julia bindings to the low-level
# HDF5 library functions.
#
# Each line should consist of two arguments:
#
#   1. An `@ccall`-like function definition expression for the C library interface,
#      including the return type.
#   2. Either an error string (which is thrown by `error()`) or an arbitrary expression
#      which may refer to any of the named function arguments.
#
# The C library names are automatically generated from the Julia function name by
# uppercasing the `h5?` and removing the first underscore ---
# e.g. `h5d_close` -> `H5Dclose`. Versioned function names (such as
# `h5d_open2` -> `H5Dopen2`) have the trailing number removed for the Julia function
# definition. Other arbitrary mappings may be added by adding an entry to the
# `bind_exceptions` Dict in `bind_generator.jl`.

###
### HDF5 General library functions
###

@bind h5_close()::herr_t "Error closing the HDF5 resources"
@bind h5_dont_atexit()::herr_t "Error calling dont_atexit"
@bind h5_free_memory(buf::Ptr{Cvoid})::herr_t "Error freeing memory"
@bind h5_garbage_collect()::herr_t "Error on garbage collect"
@bind h5_get_libversion(majnum::Ref{Cuint}, minnum::Ref{Cuint}, relnum::Ref{Cuint})::herr_t "Error getting HDF5 library version"
@bind h5_is_library_threadsafe(is_ts::Ref{Cuint})::herr_t "Error determining thread safety"
@bind h5_open()::herr_t "Error initializing the HDF5 library"
@bind h5_set_free_list_limits(reg_global_lim::Cint, reg_list_lim::Cint, arr_global_lim::Cint, arr_list_lim::Cint, blk_global_lim::Cint, blk_list_lim::Cint)::herr_t "Error setting limits on free lists"

###
### Attribute Interface
###

@bind h5a_close(id::hid_t)::herr_t "Error closing attribute"
@bind h5a_create2(loc_id::hid_t, pathname::Ptr{UInt8}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t)::hid_t error("Error creating attribute ", h5a_get_name(loc_id), "/", pathname)
@bind h5a_create_by_name(loc_id::hid_t, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t, lapl_id::hid_t)::hid_t error("Error creating attribute ", attr_name, " for object ", obj_name)
@bind h5a_delete(loc_id::hid_t, attr_name::Ptr{UInt8})::herr_t error("Error deleting attribute ", attr_name)
@bind h5a_delete_by_idx(loc_id::hid_t, obj_name::Ptr{UInt8}, idx_type::Cint, order::Cint, n::hsize_t, lapl_id::hid_t)::herr_t error("Error deleting attribute ", n, " from object ", obj_name)
@bind h5a_delete_by_name(loc_id::hid_t, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, lapl_id::hid_t)::herr_t error("Error removing attribute ", attr_name, " from object ", obj_name)
@bind h5a_exists(obj_id::hid_t, attr_name::Ptr{UInt8})::htri_t error("Error checking whether attribute ", attr_name, " exists")
@bind h5a_exists_by_name(loc_id::hid_t, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, lapl_id::hid_t)::htri_t error("Error checking whether object ", obj_name, " has attribute ", attr_name)
@bind h5a_get_create_plist(attr_id::hid_t)::hid_t "Cannot get creation property list"
@bind h5a_get_name(attr_id::hid_t, buf_size::Csize_t, buf::Ptr{UInt8})::Cssize_t "Error getting attribute name"
@bind h5a_get_name_by_idx(loc_id::hid_t, obj_name::Cstring, index_type::Cint, order::Cint, idx::hsize_t, name::Ptr{UInt8}, size::Csize_t, lapl_id::hid_t)::Cssize_t "Error getting attribute name"
@bind h5a_get_space(attr_id::hid_t)::hid_t "Error getting attribute dataspace"
@bind h5a_get_type(attr_id::hid_t)::hid_t "Error getting attribute type"
@bind h5a_iterate2(obj_id::hid_t, idx_type::Cint, order::Cint, n::Ptr{hsize_t}, op::Ptr{Cvoid}, op_data::Any)::herr_t error("Error iterating attributes in object ", h5i_get_name(obj_id))
@bind h5a_open(obj_id::hid_t, pathname::Ptr{UInt8}, aapl_id::hid_t)::hid_t error("Error opening attribute ", h5i_get_name(obj_id), "/", pathname)
@bind h5a_read(attr_id::hid_t, mem_type_id::hid_t, buf::Ptr{Cvoid})::herr_t error("Error reading attribute ", h5a_get_name(attr_id))
@bind h5a_write(attr_hid::hid_t, mem_type_id::hid_t, buf::Ptr{Cvoid})::herr_t "Error writing attribute data"

###
### Dataset Interface
###

@bind h5d_close(dataset_id::hid_t)::herr_t "Error closing dataset"
@bind h5d_create2(loc_id::hid_t, pathname::Ptr{UInt8}, dtype_id::hid_t, space_id::hid_t, lcpl_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t)::hid_t error("Error creating dataset ", h5i_get_name(loc_id), "/", pathname)
@bind h5d_flush(dataset_id::hid_t)::herr_t "Error flushing dataset"
@bind h5d_get_access_plist(dataset_id::hid_t)::hid_t "Error getting dataset access property list"
@bind h5d_get_create_plist(dataset_id::hid_t)::hid_t "Error getting dataset create property list"
@bind h5d_get_offset(dataset_id::hid_t)::haddr_t "Error getting offset"
@bind h5d_get_space(dataset_id::hid_t)::hid_t "Error getting dataspace"
@bind h5d_get_type(dataset_id::hid_t)::hid_t "Error getting dataspace type"
@bind h5d_open2(loc_id::hid_t, pathname::Ptr{UInt8}, dapl_id::hid_t)::hid_t error("Error opening dataset ", h5i_get_name(loc_id), "/", pathname)
@bind h5d_read(dataset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, xfer_plist_id::hid_t, buf::Ptr{Cvoid})::herr_t error("Error reading dataset ", h5i_get_name(dataset_id))
@bind h5d_refresh(dataset_id::hid_t)::herr_t "Error refreshing dataset"
@bind h5d_set_extent(dataset_id::hid_t, new_dims::Ptr{hsize_t})::herr_t "Error extending dataset dimensions"
@bind h5d_vlen_get_buf_size(dset_id::hid_t, type_id::hid_t, space_id::hid_t, buf::Ptr{hsize_t})::herr_t "Error getting vlen buffer size"
@bind h5d_vlen_reclaim(type_id::hid_t, space_id::hid_t, plist_id::hid_t, buf::Ptr{Cvoid})::herr_t "Error reclaiming vlen buffer"
@bind h5d_write(dataset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, xfer_plist_id::hid_t, buf::Ptr{Cvoid})::herr_t "Error writing dataset"

###
### Error Interface
###

@bind h5e_get_auto2(estack_id::hid_t, func::Ref{Ptr{Cvoid}}, client_data::Ref{Ptr{Cvoid}})::herr_t "Error getting error reporting behavior"
@bind h5e_set_auto2(estack_id::hid_t, func::Ptr{Cvoid}, client_data::Ptr{Cvoid})::herr_t "Error setting error reporting behavior"
@bind h5e_get_current_stack()::hid_t "Unable to return current error stack"

###
### File Interface
###

@bind h5f_close(file_id::hid_t)::herr_t "Error closing file"
@bind h5f_create(pathname::Ptr{UInt8}, flags::Cuint, fcpl_id::hid_t, fapl_id::hid_t)::hid_t error("Error creating file ", pathname)
@bind h5f_flush(object_id::hid_t, scope::Cint)::herr_t "Error flushing object to file"
@bind h5f_get_access_plist(file_id::hid_t)::hid_t "Error getting file access property list"
@bind h5f_get_create_plist(file_id::hid_t)::hid_t "Error getting file create property list"
@bind h5f_get_intent(file_id::hid_t, intent::Ptr{Cuint})::herr_t "Error getting file intent"
@bind h5f_get_name(obj_id::hid_t, buf::Ptr{UInt8}, buf_size::Csize_t)::Cssize_t "Error getting file name"
@bind h5f_get_obj_count(file_id::hid_t, types::Cuint)::Cssize_t "Error getting object count"
@bind h5f_get_obj_ids(file_id::hid_t, types::Cuint, max_objs::Csize_t, obj_id_list::Ptr{hid_t})::Cssize_t "Error getting objects"
@bind h5f_get_vfd_handle(file_id::hid_t, fapl_id::hid_t, file_handle::Ref{Ptr{Cvoid}})::herr_t "Error getting VFD handle"
@bind h5f_is_hdf5(pathname::Cstring)::htri_t error("Unable to access file ", pathname)
@bind h5f_open(pathname::Cstring, flags::Cuint, fapl_id::hid_t)::hid_t error("Error opening file ", pathname)
@bind h5f_start_swmr_write(id::hid_t)::herr_t "Error starting SWMR write"

###
### Group Interface
###

@bind h5g_close(group_id::hid_t)::herr_t "Error closing group"
@bind h5g_create2(loc_id::hid_t, pathname::Ptr{UInt8}, lcpl_id::hid_t, gcpl_id::hid_t, gapl_id::hid_t)::hid_t error("Error creating group ", h5i_get_name(loc_id), "/", pathname)
@bind h5g_get_create_plist(group_id::hid_t)::hid_t "Error getting group create property list"
@bind h5g_get_info(group_id::hid_t, buf::Ptr{H5G_info_t})::herr_t "Error getting group info"
@bind h5g_get_num_objs(loc_id::hid_t, num_obj::Ptr{hsize_t})::hid_t "Error getting group length"
@bind h5g_get_objname_by_idx(loc_id::hid_t, idx::hsize_t, pathname::Ptr{UInt8}, size::Csize_t)::Cssize_t error("Error getting group object name ", h5i_get_name(loc_id), "/", pathname)
@bind h5g_open2(loc_id::hid_t, pathname::Ptr{UInt8}, gapl_id::hid_t)::hid_t error("Error opening group ", h5i_get_name(loc_id), "/", pathname)

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

@bind h5l_create_external(target_file_name::Ptr{UInt8}, target_obj_name::Ptr{UInt8}, link_loc_id::hid_t, link_name::Ptr{UInt8}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name)
@bind h5l_create_hard(obj_loc_id::hid_t, obj_name::Ptr{UInt8}, link_loc_id::hid_t, link_name::Ptr{UInt8}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t error("Error creating hard link ", link_name, " pointing to ", obj_name)
@bind h5l_create_soft(target_path::Ptr{UInt8}, link_loc_id::hid_t, link_name::Ptr{UInt8}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t error("Error creating soft link ", link_name, " pointing to ", target_path)
@bind h5l_delete(obj_id::hid_t, pathname::Ptr{UInt8}, lapl_id::hid_t)::herr_t error("Error deleting ", h5i_get_name(obj_id), "/", pathname)
@bind h5l_exists(loc_id::hid_t, pathname::Ptr{UInt8}, lapl_id::hid_t)::htri_t error("Cannot determine whether ", pathname, " exists")
@bind h5l_get_info(link_loc_id::hid_t, link_name::Ptr{UInt8}, link_buf::Ptr{H5L_info_t}, lapl_id::hid_t)::herr_t error("Error getting info for link ", link_name)
@bind h5l_get_name_by_idx(loc_id::hid_t, group_name::Ptr{UInt8}, index_field::Cint, order::Cint, n::hsize_t, name::Ptr{UInt8}, size::Csize_t, lapl_id::hid_t)::Cssize_t "Error getting object name"
# libhdf5 v1.10 provides the name H5Literate
# libhdf5 v1.12 provides the same under H5Literate1, and a newer interface on H5Literate2
@bind h5l_iterate(group_id::hid_t, idx_type::Cint, order::Cint, idx::Ptr{hsize_t}, op::Ptr{Cvoid}, op_data::Any)::herr_t error("Error iterating through links in group ", h5i_get_name(group_id)) (nothing, v"1.12")
@bind h5l_iterate1(group_id::hid_t, idx_type::Cint, order::Cint, idx::Ptr{hsize_t}, op::Ptr{Cvoid}, op_data::Any)::herr_t error("Error iterating through links in group ", h5i_get_name(group_id)) (v"1.12", nothing)

###
### Object Interface
###

@bind h5o_close(object_id::hid_t)::herr_t "Error closing object"
@bind h5o_copy(src_loc_id::hid_t, src_name::Ptr{UInt8}, dst_loc_id::hid_t, dst_name::Ptr{UInt8}, ocpypl_id::hid_t, lcpl_id::hid_t)::herr_t error("Error copying object ", h5i_get_name(src_loc_id), "/", src_name, " to ", h5i_get_name(dst_loc_id), "/", dst_name)
@bind h5o_get_info1(object_id::hid_t, buf::Ptr{H5O_info_t})::herr_t "Error getting object info"
@bind h5o_open(loc_id::hid_t, pathname::Ptr{UInt8}, lapl_id::hid_t)::hid_t error("Error opening object ", h5i_get_name(loc_id), "/", pathname)
@bind h5o_open_by_addr(loc_id::hid_t, addr::haddr_t)::hid_t error("Error opening object by address")
@bind h5o_open_by_idx(loc_id::hid_t, group_name::Ptr{UInt8}, index_type::Cint, order::Cint, n::hsize_t, lapl_id::hid_t)::hid_t error("Error opening object of index ", n)

###
### Property Interface
###

@bind h5p_close(id::hid_t)::herr_t "Error closing property list"
@bind h5p_create(cls_id::hid_t)::hid_t "Error creating property list"
@bind h5p_get_alignment(fapl_id::hid_t, threshold::Ref{hsize_t}, alignment::Ref{hsize_t})::herr_t "Error getting alignment"
@bind h5p_get_alloc_time(plist_id::hid_t, alloc_time::Ptr{Cint})::herr_t "Error getting allocation timing"
@bind h5p_get_char_encoding(plist_id::hid_t, encoding::Ref{Cint})::herr_t "Error getting char encoding"
@bind h5p_get_chunk(plist_id::hid_t, n_dims::Cint, dims::Ptr{hsize_t})::Cint "Error getting chunk size"
@bind h5p_get_create_intermediate_group(lcpl_id::hid_t, crt_intermed_group::Ref{Cuint})::herr_t "Error getting create intermediate group property"
@bind h5p_get_driver(plist_id::hid_t)::hid_t "Error getting driver identifier"
@bind h5p_get_driver_info(plist_id::hid_t)::Ptr{Cvoid} # does not error
@bind h5p_get_dxpl_mpio(dxpl_id::hid_t, xfer_mode::Ptr{Cint})::herr_t "Error getting MPIO transfer mode"
@bind h5p_get_fapl_mpio32(fapl_id::hid_t, comm::Ptr{Hmpih32}, info::Ptr{Hmpih32})::herr_t "Error getting MPIO properties"
@bind h5p_get_fapl_mpio64(fapl_id::hid_t, comm::Ptr{Hmpih64}, info::Ptr{Hmpih64})::herr_t "Error getting MPIO properties"
@bind h5p_get_fclose_degree(fapl_id::hid_t, fc_degree::Ref{Cint})::herr_t "Error getting close degree"
@bind h5p_get_filter2(plist_id::hid_t, idx::Cuint, flags::Ref{Cuint}, cd_nelmts::Ref{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{UInt8}, filter_config::Ptr{Cuint})::H5Z_filter_t "Error getting filter ID"
@bind h5p_get_filter_by_id2(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Ref{Cuint}, cd_nelmts::Ref{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{UInt8}, filter_config::Ptr{Cuint})::herr_t "Error getting filter ID"
@bind h5p_get_nfilters(plist_id::hid_t)::Cint "Error getting nfilters"
@bind h5p_get_layout(plist_id::hid_t)::Cint error("Error getting layout")
@bind h5p_get_libver_bounds(fapl_id::hid_t, low::Ref{Cint}, high::Ref{Cint})::herr_t "Error getting library version bounds"
@bind h5p_get_local_heap_size_hint(plist_id::hid_t, size_hint::Ref{Csize_t})::herr_t "Error getting local heap size hint"
@bind h5p_get_obj_track_times(plist_id::hid_t, track_times::Ref{UInt8})::herr_t "Error setting object time tracking"
@bind h5p_get_userblock(plist_id::hid_t, len::Ptr{hsize_t})::herr_t "Error getting userblock"
@bind h5p_modify_filter(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})::herr_t "Error modifying filter"
@bind h5p_remove_filter(plist_id::hid_t, filter_id::H5Z_filter_t)::herr_t "Error removing filter"
@bind h5p_set_alignment(plist_id::hid_t, threshold::hsize_t, alignment::hsize_t)::herr_t "Error setting alignment"
@bind h5p_set_alloc_time(plist_id::hid_t, alloc_time::Cint)::herr_t "Error setting allocation timing"
@bind h5p_set_char_encoding(plist_id::hid_t, encoding::Cint)::herr_t "Error setting char encoding"
@bind h5p_set_chunk(plist_id::hid_t, ndims::Cint, dims::Ptr{hsize_t})::herr_t "Error setting chunk size"
@bind h5p_set_chunk_cache(dapl_id::hid_t, rdcc_nslots::Csize_t, rdcc_nbytes::Csize_t, rdcc_w0::Cdouble)::herr_t "Error setting chunk cache"
@bind h5p_set_create_intermediate_group(plist_id::hid_t, setting::Cuint)::herr_t "Error setting create intermediate group"
@bind h5p_set_deflate(plist_id::hid_t, setting::Cuint)::herr_t "Error setting compression method and level (deflate)"
@bind h5p_set_dxpl_mpio(dxpl_id::hid_t, xfer_mode::Cint)::herr_t "Error setting MPIO transfer mode"
@bind h5p_set_external(plist_id::hid_t, name::Ptr{UInt8}, offset::Int, size::Csize_t)::herr_t "Error setting external property"
@bind h5p_set_fapl_sec2(fapl_id::hid_t)::herr_t "Error setting Sec2 properties"
@bind h5p_set_fapl_mpio32(fapl_id::hid_t, comm::Hmpih32, info::Hmpih32)::herr_t "Error setting MPIO properties"
@bind h5p_set_fapl_mpio64(fapl_id::hid_t, comm::Hmpih64, info::Hmpih64)::herr_t "Error setting MPIO properties"
@bind h5p_set_fclose_degree(plist_id::hid_t, fc_degree::Cint)::herr_t "Error setting close degree"
@bind h5p_set_filter(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})::herr_t "Error setting filter"
@bind h5p_set_fletcher32(plist_id::hid_t)::herr_t "Error enabling Fletcher32 filter"
@bind h5p_set_layout(plist_id::hid_t, setting::Cint)::herr_t "Error setting layout"
@bind h5p_set_libver_bounds(fapl_id::hid_t, low::Cint, high::Cint)::herr_t "Error setting library version bounds"
@bind h5p_set_local_heap_size_hint(plist_id::hid_t, size_hint::Csize_t)::herr_t "Error setting local heap size hint"
@bind h5p_set_nbit(plist_id::hid_t)::herr_t "Error enabling nbit filter"
@bind h5p_set_obj_track_times(plist_id::hid_t, track_times::UInt8)::herr_t "Error setting object time tracking"
@bind h5p_set_scaleoffset(plist_id::hid_t, scale_type::Cint, scale_factor::Cint)::herr_t "Error enabling szip filter"
@bind h5p_set_shuffle(plist_id::hid_t)::herr_t "Error enabling shuffle filter"
@bind h5p_set_szip(plist_id::hid_t, options_mask::Cuint, pixels_per_block::Cuint)::herr_t "Error enabling szip filter"
@bind h5p_set_userblock(plist_id::hid_t, len::hsize_t)::herr_t "Error setting userblock"
@bind h5p_set_virtual(dcpl_id::hid_t, vspace_id::hid_t, src_file_name::Ptr{UInt8}, src_dset_name::Ptr{UInt8}, src_space_id::hid_t)::herr_t "Error setting virtual"

###
### Reference Interface
###

@bind h5r_create(ref::Ptr{Cvoid}, loc_id::hid_t, pathname::Ptr{UInt8}, ref_type::Cint, space_id::hid_t)::herr_t error("Error creating reference to object ", h5i_get_name(loc_id), "/", pathname)
@bind h5r_dereference2(obj_id::hid_t, oapl_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid})::hid_t "Error dereferencing object"
@bind h5r_get_obj_type2(loc_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid}, obj_type::Ptr{Cint})::herr_t "Error getting object type"
@bind h5r_get_region(loc_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid})::hid_t "Error getting region from reference"

###
### Dataspace Interface
###

@bind h5s_close(space_id::hid_t)::herr_t "Error closing dataspace"
@bind h5s_combine_select(space1_id::hid_t, op::Cint, space2_id::hid_t)::hid_t "Error combining dataspaces" (v"1.10.7", nothing)
@bind h5s_copy(space_id::hid_t)::hid_t "Error copying dataspace"
@bind h5s_create(class::Cint)::hid_t "Error creating dataspace"
@bind h5s_create_simple(rank::Cint, current_dims::Ptr{hsize_t}, maximum_dims::Ptr{hsize_t})::hid_t "Error creating simple dataspace"
@bind h5s_extent_equal(space1_id::hid_t, space2_id::hid_t)::htri_t "Error comparing dataspaces"
@bind h5s_get_regular_hyperslab(space_id::hid_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t "Error getting regular hyperslab selection"
@bind h5s_get_simple_extent_dims(space_id::hid_t, dims::Ptr{hsize_t}, maxdims::Ptr{hsize_t})::Cint "Error getting the dimensions for a dataspace"
@bind h5s_get_simple_extent_ndims(space_id::hid_t)::Cint "Error getting the number of dimensions for a dataspace"
@bind h5s_get_simple_extent_type(space_id::hid_t)::Cint "Error getting the dataspace type"
@bind h5s_get_select_hyper_nblocks(space_id::hid_t)::hssize_t "Error getting number of selected blocks"
@bind h5s_get_select_npoints(space_id::hid_t)::hsize_t "Error getting the number of selected points"
@bind h5s_get_select_type(space_id::hid_t)::Cint "Error getting the selection type"
@bind h5s_is_regular_hyperslab(space_id::hid_t)::htri_t "Error determining whether datapace is regular hyperslab"
@bind h5s_is_simple(space_id::hid_t)::htri_t "Error determining whether dataspace is simple"
@bind h5s_select_hyperslab(dspace_id::hid_t, seloper::Cint, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t "Error selecting hyperslab"
@bind h5s_set_extent_simple(dspace_id::hid_t, rank::Cint, current_size::Ptr{hsize_t}, maximum_size::Ptr{hsize_t})::herr_t "Error setting dataspace size"

###
### Datatype Interface
###

@bind h5t_array_create2(basetype_id::hid_t, ndims::Cuint, sz::Ptr{hsize_t})::hid_t error("Error creating H5T_ARRAY of id ", basetype_id, " and size ", sz)
@bind h5t_close(dtype_id::hid_t)::herr_t "Error closing datatype"
@bind h5t_committed(dtype_id::hid_t)::htri_t error("Error determining whether datatype is committed")
@bind h5t_commit2(loc_id::hid_t, name::Ptr{UInt8}, dtype_id::hid_t, lcpl_id::hid_t, tcpl_id::hid_t, tapl_id::hid_t)::herr_t "Error committing type"
@bind h5t_copy(dtype_id::hid_t)::hid_t "Error copying datatype"
@bind h5t_create(class_id::Cint, sz::Csize_t)::hid_t error("Error creating datatype of id ", class_id)
@bind h5t_enum_insert(dtype_id::hid_t, name::Cstring, value::Ptr{Cvoid})::herr_t error("Error adding ", name, " to enum datatype")
@bind h5t_equal(dtype_id1::hid_t, dtype_id2::hid_t)::htri_t "Error checking datatype equality"
@bind h5t_get_array_dims2(dtype_id::hid_t, dims::Ptr{hsize_t})::Cint "Error getting dimensions of array"
@bind h5t_get_array_ndims(dtype_id::hid_t)::Cint "Error getting ndims of array"
@bind h5t_get_class(dtype_id::hid_t)::Cint "Error getting class"
@bind h5t_get_cset(dtype_id::hid_t)::Cint "Error getting character set encoding"
@bind h5t_get_ebias(dtype_id::hid_t)::Csize_t # does not error
@bind h5t_get_fields(dtype_id::hid_t, spos::Ref{Csize_t}, epos::Ref{Csize_t}, esize::Ref{Csize_t}, mpos::Ref{Csize_t}, msize::Ref{Csize_t})::herr_t "Error getting datatype floating point bit positions"
@bind h5t_get_member_class(dtype_id::hid_t, index::Cuint)::Cint error("Error getting class of compound datatype member #", index)
@bind h5t_get_member_index(dtype_id::hid_t, membername::Ptr{UInt8})::Cint error("Error getting index of compound datatype member \"", membername, "\"")
@bind h5t_get_member_offset(dtype_id::hid_t, index::Cuint)::Csize_t # does not error
@bind h5t_get_member_type(dtype_id::hid_t, index::Cuint)::hid_t error("Error getting type of compound datatype member #", index)
@bind h5t_get_native_type(dtype_id::hid_t, direction::Cint)::hid_t "Error getting native type"
@bind h5t_get_nmembers(dtype_id::hid_t)::Cint "Error getting the number of members"
@bind h5t_get_sign(dtype_id::hid_t)::Cint "Error getting sign"
@bind h5t_get_size(dtype_id::hid_t)::Csize_t # does not error
@bind h5t_get_strpad(dtype_id::hid_t)::Cint "Error getting string padding"
@bind h5t_get_super(dtype_id::hid_t)::hid_t "Error getting super type"
@bind h5t_insert(dtype_id::hid_t, fieldname::Ptr{UInt8}, offset::Csize_t, field_id::hid_t)::herr_t error("Error adding field ", fieldname, " to compound datatype")
@bind h5t_is_variable_str(type_id::hid_t)::htri_t "Error determining whether string is of variable length"
@bind h5t_lock(type_id::hid_t)::herr_t "Error locking type"
@bind h5t_open2(loc_id::hid_t, name::Ptr{UInt8}, tapl_id::hid_t)::hid_t error("Error opening type ", h5i_get_name(loc_id), "/", name)
@bind h5t_set_cset(dtype_id::hid_t, cset::Cint)::herr_t "Error setting character set in datatype"
@bind h5t_set_ebias(dtype_id::hid_t, ebias::Csize_t)::herr_t "Error setting datatype floating point exponent bias"
@bind h5t_set_fields(dtype_id::hid_t, spos::Csize_t, epos::Csize_t, esize::Csize_t, mpos::Csize_t, msize::Csize_t)::herr_t "Error setting datatype floating point bit positions"
@bind h5t_set_precision(dtype_id::hid_t, sz::Csize_t)::herr_t "Error setting precision of datatype"
@bind h5t_set_size(dtype_id::hid_t, sz::Csize_t)::herr_t "Error setting size of datatype"
@bind h5t_set_strpad(dtype_id::hid_t, sz::Cint)::herr_t "Error setting size of datatype"
@bind h5t_set_tag(dtype_id::hid_t, tag::Cstring)::herr_t "Error setting opaque tag"
@bind h5t_vlen_create(base_type_id::hid_t)::hid_t "Error creating vlen type"
# The following are not automatically wrapped since they have requirements about freeing
# the memory that is returned from the calls.
#@bind h5t_get_member_name(dtype_id::hid_t, index::Cuint)::Cstring error("Error getting name of compound datatype member #", index)
#@bind h5t_get_tag(type_id::hid_t)::Cstring "Error getting datatype opaque tag"

###
### Optimized Functions Interface
###

@bind h5do_append(dset_id::hid_t, dxpl_id::hid_t, index::Cuint, num_elem::hsize_t, memtype::hid_t, buffer::Ptr{Cvoid})::herr_t "error appending"
@bind h5do_write_chunk(dset_id::hid_t, dxpl_id::hid_t, filter_mask::Int32, offset::Ptr{hsize_t}, bufsize::Csize_t, buf::Ptr{Cvoid})::herr_t "Error writing chunk"

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
@bind h5ds_set_scale(dsid::hid_t, dimname::Ptr{UInt8})::herr_t "Unable to set scale"


###
### HDF5 Lite Interface
###

@bind h5lt_dtype_to_text(datatype::hid_t, str::Ptr{UInt8}, lang_type::Cint, len::Ref{Csize_t})::herr_t "Error getting datatype text representation"

###
### Table Interface
###
@bind h5tb_append_records(loc_id::hid_t, dset_name::Ptr{UInt8}, nrecords::hsize_t, type_size::Csize_t, field_offset::Ptr{Csize_t}, field_sizes::Ptr{Csize_t}, data::Ptr{Cvoid})::herr_t "Error adding record to table"
@bind h5tb_get_field_info(loc_id::hid_t, table_name::Ptr{UInt8}, field_names::Ptr{Ptr{UInt8}}, field_sizes::Ptr{Csize_t}, field_offsets::Ptr{Csize_t}, type_size::Ptr{Csize_t})::herr_t "Error getting field information"
@bind h5tb_get_table_info(loc_id::hid_t, table_name::Ptr{UInt8}, nfields::Ptr{hsize_t}, nrecords::Ptr{hsize_t})::herr_t "Error getting table information"
# NOTE: The HDF5 docs incorrectly specify type_size::hsize_t where as it should be type_size::Csize_t
@bind h5tb_make_table(table_title::Ptr{UInt8}, loc_id::hid_t, dset_name::Ptr{UInt8}, nfields::hsize_t, nrecords::hsize_t, type_size::Csize_t, field_names::Ptr{Ptr{UInt8}}, field_offset::Ptr{Csize_t}, field_types::Ptr{hid_t}, chunk_size::hsize_t, fill_data::Ptr{Cvoid}, compress::Cint, data::Ptr{Cvoid})::herr_t "Error creating and writing dataset to table"
@bind h5tb_read_records(loc_id::hid_t, table_name::Ptr{UInt8}, start::hsize_t, nrecords::hsize_t, type_size::Csize_t, field_offsets::Ptr{Csize_t}, dst_sizes::Ptr{Csize_t}, data::Ptr{Cvoid})::herr_t "Error reading record from table"
@bind h5tb_read_table(loc_id::hid_t, table_name::Ptr{UInt8}, dst_size::Csize_t, dst_offset::Ptr{Csize_t}, dst_sizes::Ptr{Csize_t}, dst_buf::Ptr{Cvoid})::herr_t "Error reading table"
@bind h5tb_write_records(loc_id::hid_t, table_name::Ptr{UInt8}, start::hsize_t, nrecords::hsize_t, type_size::Csize_t, field_offsets::Ptr{UInt8}, field_sizes::Ptr{UInt8}, data::Ptr{Cvoid})::herr_t "Error writing record to table"

###
### Filter Interface
###

@bind h5z_register(filter_class::Ref{H5Z_class_t})::herr_t "Unable to register new filter"
