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
# e.g. `h5d_close` -> `H5Dclose`.
# For versioned bindings (such as `H5Dopen2`), the mapping between names is given
# explicitly in the `bind_exceptions` Dict in `bind_generator.jl`.

###
### HDF5 General library functions
###

@bind h5_close()::Herr "Error closing the HDF5 resources"
@bind h5_dont_atexit()::Herr "Error calling dont_atexit"
@bind h5_garbage_collect()::Herr "Error on garbage collect"
@bind h5_open()::Herr "Error initializing the HDF5 library"
@bind h5_set_free_list_limits(reg_global_lim::Cint, reg_list_lim::Cint, arr_global_lim::Cint, arr_list_lim::Cint, blk_global_lim::Cint, blk_list_lim::Cint)::Herr "Error setting limits on free lists"

###
### Attribute Interface
###

@bind h5a_close(id::Hid)::Herr "Error closing attribute"
@bind h5a_create(loc_id::Hid, pathname::Ptr{UInt8}, type_id::Hid, space_id::Hid, acpl_id::Hid, aapl_id::Hid)::Hid error("Error creating attribute ", h5a_get_name(loc_id), "/", pathname)
@bind h5a_create_by_name(loc_id::Hid, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, type_id::Hid, space_id::Hid, acpl_id::Hid, aapl_id::Hid, lapl_id::Hid)::Hid error("Error creating attribute ", attr_name, " for object ", obj_name)
@bind h5a_delete(loc_id::Hid, attr_name::Ptr{UInt8})::Herr error("Error deleting attribute ", attr_name)
@bind h5a_delete_by_idx(loc_id::Hid, obj_name::Ptr{UInt8}, idx_type::Cint, order::Cint, n::Hsize, lapl_id::Hid)::Herr error("Error deleting attribute ", n, " from object ", obj_name)
@bind h5a_delete_by_name(loc_id::Hid, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, lapl_id::Hid)::Herr error("Error removing attribute ", attr_name, " from object ", obj_name)
@bind h5a_exists(obj_id::Hid, attr_name::Ptr{UInt8})::Htri error("Error checking whether attribute ", attr_name, " exists")
@bind h5a_exists_by_name(loc_id::Hid, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, lapl_id::Hid)::Htri error("Error checking whether object ", obj_name, " has attribute ", attr_name)
@bind h5a_get_create_plist(attr_id::Hid)::Hid error("Cannot get creation property list")
@bind h5a_get_name(attr_id::Hid, buf_size::Csize_t, buf::Ptr{UInt8})::Cssize_t "Error getting attribute name"
@bind h5a_get_name_by_idx(loc_id::Hid, obj_name::Ptr{UInt8}, index_type::Cint, order::Cint, idx::Hsize, name::Ptr{UInt8}, size::Csize_t, lapl_id::Hid)::Cssize_t error("Error getting attribute name")
@bind h5a_get_space(attr_id::Hid)::Hid "Error getting attribute dataspace"
@bind h5a_get_type(attr_id::Hid)::Hid "Error getting attribute type"
@bind h5a_open(obj_id::Hid, pathname::Ptr{UInt8}, aapl_id::Hid)::Hid error("Error opening attribute ", h5i_get_name(obj_id), "/", pathname)
@bind h5a_read(attr_id::Hid, mem_type_id::Hid, buf::Ptr{Cvoid})::Herr error("Error reading attribute ", h5a_get_name(attr_id))
@bind h5a_write(attr_hid::Hid, mem_type_id::Hid, buf::Ptr{Cvoid})::Herr "Error writing attribute data"

###
### Dataset Interface
###

@bind h5d_close(dataset_id::Hid)::Herr "Error closing dataset"
@bind h5d_create(loc_id::Hid, pathname::Ptr{UInt8}, dtype_id::Hid, space_id::Hid, lcpl_id::Hid, dcpl_id::Hid, dapl_id::Hid)::Hid error("Error creating dataset ", h5i_get_name(loc_id), "/", pathname)
@bind h5d_flush(dataset_id::Hid)::Herr "Error flushing dataset"
@bind h5d_get_access_plist(dataset_id::Hid)::Hid "Error getting dataset access property list"
@bind h5d_get_create_plist(dataset_id::Hid)::Hid "Error getting dataset create property list"
@bind h5d_get_offset(dataset_id::Hid)::Haddr "Error getting offset"
@bind h5d_get_space(dataset_id::Hid)::Hid "Error getting dataspace"
@bind h5d_get_type(dataset_id::Hid)::Hid "Error getting dataspace type"
@bind h5d_open(loc_id::Hid, pathname::Ptr{UInt8}, dapl_id::Hid)::Hid error("Error opening dataset ", h5i_get_name(loc_id), "/", pathname)
@bind h5d_read(dataset_id::Hid, mem_type_id::Hid, mem_space_id::Hid, file_space_id::Hid, xfer_plist_id::Hid, buf::Ptr{Cvoid})::Herr error("Error reading dataset ", h5i_get_name(dataset_id))
@bind h5d_refresh(dataset_id::Hid)::Herr "Error refreshing dataset"
@bind h5d_set_extent(dataset_id::Hid, new_dims::Ptr{Hsize})::Herr "Error extending dataset dimensions"
@bind h5d_vlen_get_buf_size(dset_id::Hid, type_id::Hid, space_id::Hid, buf::Ptr{Hsize})::Herr "Error getting vlen buffer size"
@bind h5d_vlen_reclaim(type_id::Hid, space_id::Hid, plist_id::Hid, buf::Ptr{Cvoid})::Herr "Error reclaiming vlen buffer"
@bind h5d_write(dataset_id::Hid, mem_type_id::Hid, mem_space_id::Hid, file_space_id::Hid, xfer_plist_id::Hid, buf::Ptr{Cvoid})::Herr "Error writing dataset"

###
### Error Interface
###

@bind h5e_set_auto(estack_id::Hid, func::Ptr{Cvoid}, client_data::Ptr{Cvoid})::Herr "Error setting error reporting behavior"

###
### File Interface
###

@bind h5f_close(file_id::Hid)::Herr "Error closing file"
@bind h5f_create(pathname::Ptr{UInt8}, flags::Cuint, fcpl_id::Hid, fapl_id::Hid)::Hid error("Error creating file ", pathname)
@bind h5f_flush(object_id::Hid, scope::Cint)::Herr "Error flushing object to file"
@bind h5f_get_access_plist(file_id::Hid)::Hid "Error getting file access property list"
@bind h5f_get_create_plist(file_id::Hid)::Hid "Error getting file create property list"
@bind h5f_get_intent(file_id::Hid, intent::Ptr{Cuint})::Herr "Error getting file intent"
@bind h5f_get_name(obj_id::Hid, buf::Ptr{UInt8}, buf_size::Csize_t)::Cssize_t "Error getting file name"
@bind h5f_get_vfd_handle(file_id::Hid, fapl_id::Hid, file_handle::Ptr{Ptr{Cint}})::Herr "Error getting VFD handle"
@bind h5f_is_hdf5(pathname::Cstring)::Htri error("Cannot access file ", pathname)
@bind h5f_open(pathname::Cstring, flags::Cuint, fapl_id::Hid)::Hid error("Error opening file ", pathname)
@bind h5f_start_swmr_write(id::Hid)::Herr "Error starting SWMR write"

###
### Group Interface
###

@bind h5g_close(group_id::Hid)::Herr "Error closing group"
@bind h5g_create(loc_id::Hid, pathname::Ptr{UInt8}, lcpl_id::Hid, gcpl_id::Hid, gapl_id::Hid)::Hid error("Error creating group ", h5i_get_name(loc_id), "/", pathname)
@bind h5g_get_create_plist(group_id::Hid)::Hid "Error getting group create property list"
@bind h5g_get_info(group_id::Hid, buf::Ptr{H5Ginfo})::Herr "Error getting group info"
@bind h5g_get_num_objs(loc_id::Hid, num_obj::Ptr{Hsize})::Hid "Error getting group length"
@bind h5g_get_objname_by_idx(loc_id::Hid, idx::Hsize, pathname::Ptr{UInt8}, size::Csize_t)::Cssize_t error("Error getting group object name ", h5i_get_name(loc_id), "/", pathname)
@bind h5g_open(loc_id::Hid, pathname::Ptr{UInt8}, gapl_id::Hid)::Hid error("Error opening group ", h5i_get_name(loc_id), "/", pathname)

###
### Identifier Interface
###

@bind h5i_dec_ref(obj_id::Hid)::Cint "Error decementing reference"
@bind h5i_get_file_id(obj_id::Hid)::Hid "Error getting file identifier"
@bind h5i_get_name(obj_id::Hid, buf::Ptr{UInt8}, buf_size::Csize_t)::Cssize_t "Error getting object name"
@bind h5i_get_ref(obj_id::Hid)::Cint "Error getting reference count"
@bind h5i_get_type(obj_id::Hid)::Cint "Error getting type"
@bind h5i_is_valid(obj_id::Hid)::Htri "Cannot determine whether object is valid"

###
### Link Interface
###

@bind h5l_create_external(target_file_name::Ptr{UInt8}, target_obj_name::Ptr{UInt8}, link_loc_id::Hid, link_name::Ptr{UInt8}, lcpl_id::Hid, lapl_id::Hid)::Herr error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name)
@bind h5l_create_hard(obj_loc_id::Hid, obj_name::Ptr{UInt8}, link_loc_id::Hid, link_name::Ptr{UInt8}, lcpl_id::Hid, lapl_id::Hid)::Herr error("Error creating hard link ", link_name, " pointing to ", obj_name)
@bind h5l_create_soft(target_path::Ptr{UInt8}, link_loc_id::Hid, link_name::Ptr{UInt8}, lcpl_id::Hid, lapl_id::Hid)::Herr error("Error creating soft link ", link_name, " pointing to ", target_path)
@bind h5l_delete(obj_id::Hid, pathname::Ptr{UInt8}, lapl_id::Hid)::Herr error("Error deleting ", h5i_get_name(obj_id), "/", pathname)
@bind h5l_exists(loc_id::Hid, pathname::Ptr{UInt8}, lapl_id::Hid)::Htri error("Cannot determine whether ", pathname, " exists")
@bind h5l_get_info(link_loc_id::Hid, link_name::Ptr{UInt8}, link_buf::Ptr{H5LInfo}, lapl_id::Hid)::Herr error("Error getting info for link ", link_name)
@bind h5l_get_name_by_idx(loc_id::Hid, group_name::Ptr{UInt8}, index_field::Cint, order::Cint, n::Hsize, name::Ptr{UInt8}, size::Csize_t, lapl_id::Hid)::Cssize_t "Error getting object name"

###
### Object Interface
###

@bind h5o_close(object_id::Hid)::Herr "Error closing object"
@bind h5o_copy(src_loc_id::Hid, src_name::Ptr{UInt8}, dst_loc_id::Hid, dst_name::Ptr{UInt8}, ocpypl_id::Hid, lcpl_id::Hid)::Herr error("Error copying object ", h5i_get_name(src_loc_id), "/", src_name, " to ", h5i_get_name(dst_loc_id), "/", dst_name)
@bind h5o_get_info(object_id::Hid, buf::Ptr{H5Oinfo})::Herr "Error getting object info"
@bind h5o_open(loc_id::Hid, pathname::Ptr{UInt8}, lapl_id::Hid)::Hid error("Error opening object ", h5i_get_name(loc_id), "/", pathname)
@bind h5o_open_by_addr(loc_id::Hid, addr::Haddr)::Hid error("Error opening object by address")
@bind h5o_open_by_idx(loc_id::Hid, group_name::Ptr{UInt8}, index_type::Cint, order::Cint, n::Hsize, lapl_id::Hid)::Hid error("Error opening object of index ", n)

###
### Property Interface
###

@bind h5p_close(id::Hid)::Herr "Error closing property list"
@bind h5p_create(cls_id::Hid)::Hid "Error creating property list"
@bind h5p_get_alignment(plist_id::Hid, threshold::Ptr{Hsize}, alignment::Ptr{Hsize})::Herr "Error getting alignment"
@bind h5p_get_alloc_time(plist_id::Hid, alloc_time::Ptr{Cint})::Herr "Error getting allocation timing"
@bind h5p_get_chunk(plist_id::Hid, n_dims::Cint, dims::Ptr{Hsize})::Cint error("Error getting chunk size")
@bind h5p_get_driver(plist_id::Hid)::Hid "Error getting driver identifier"
@bind h5p_get_driver_info(plist_id::Hid)::Ptr{Cvoid} "Error getting driver info"
@bind h5p_get_dxpl_mpio(dxpl_id::Hid, xfer_mode::Ptr{Cint})::Herr "Error getting MPIO transfer mode"
@bind h5p_get_fapl_mpio32(fapl_id::Hid, comm::Ptr{Hmpih32}, info::Ptr{Hmpih32})::Herr "Error getting MPIO properties"
@bind h5p_get_fapl_mpio64(fapl_id::Hid, comm::Ptr{Hmpih64}, info::Ptr{Hmpih64})::Herr "Error getting MPIO properties"
@bind h5p_get_fclose_degree(plist_id::Hid, fc_degree::Ptr{Cint})::Herr "Error getting close degree"
@bind h5p_get_layout(plist_id::Hid)::Cint error("Error getting layout")
@bind h5p_get_userblock(plist_id::Hid, len::Ptr{Hsize})::Herr "Error getting userblock"
@bind h5p_set_alignment(plist_id::Hid, threshold::Hsize, alignment::Hsize)::Herr "Error setting alignment"
@bind h5p_set_alloc_time(plist_id::Hid, alloc_time::Cint)::Herr "Error setting allocation timing"
@bind h5p_set_char_encoding(plist_id::Hid, encoding::Cint)::Herr "Error setting char encoding"
@bind h5p_set_chunk(plist_id::Hid, ndims::Cint, dims::Ptr{Hsize})::Herr "Error setting chunk size"
@bind h5p_set_create_intermediate_group(plist_id::Hid, setting::Cuint)::Herr "Error setting create intermediate group"
@bind h5p_set_deflate(plist_id::Hid, setting::Cuint)::Herr "Error setting compression method and level (deflate)"
@bind h5p_set_dxpl_mpio(dxpl_id::Hid, xfer_mode::Cint)::Herr "Error setting MPIO transfer mode"
@bind h5p_set_external(plist_id::Hid, name::Ptr{UInt8}, offset::Int, size::Csize_t)::Herr "Error setting external property"
@bind h5p_set_fapl_mpio32(fapl_id::Hid, comm::Hmpih32, info::Hmpih32)::Herr "Error setting MPIO properties"
@bind h5p_set_fapl_mpio64(fapl_id::Hid, comm::Hmpih64, info::Hmpih64)::Herr "Error setting MPIO properties"
@bind h5p_set_fclose_degree(plist_id::Hid, fc_degree::Cint)::Herr "Error setting close degree"
@bind h5p_set_layout(plist_id::Hid, setting::Cint)::Herr "Error setting layout"
@bind h5p_set_libver_bounds(fapl_id::Hid, libver_low::Cint, libver_high::Cint)::Herr "Error setting library version bounds"
@bind h5p_set_local_heap_size_hint(fapl_id::Hid, size_hint::Cuint)::Herr "Error setting local heap size hint"
@bind h5p_set_obj_track_times(plist_id::Hid, track_times::UInt8)::Herr "Error setting object time tracking"
@bind h5p_set_shuffle(plist_id::Hid)::Herr "Error enabling shuffle filter"
@bind h5p_set_userblock(plist_id::Hid, len::Hsize)::Herr "Error setting userblock"

###
### Reference Interface
###

@bind h5r_create(ref::Ptr{HDF5ReferenceObj}, loc_id::Hid, pathname::Ptr{UInt8}, ref_type::Cint, space_id::Hid)::Herr error("Error creating reference to object ", hi5_get_name(loc_id), "/", pathname)
@bind h5r_get_obj_type(loc_id::Hid, ref_type::Cint, ref::Ptr{Cvoid}, obj_type::Ptr{Cint})::Herr "Error getting object type"
@bind h5r_get_region(loc_id::Hid, ref_type::Cint, ref::Ptr{Cvoid})::Hid "Error getting region from reference"

###
### Dataspace Interface
###

@bind h5s_close(space_id::Hid)::Herr "Error closing dataspace"
@bind h5s_copy(space_id::Hid)::Hid "Error copying dataspace"
@bind h5s_create(class::Cint)::Hid "Error creating dataspace"
@bind h5s_create_simple(rank::Cint, current_dims::Ptr{Hsize}, maximum_dims::Ptr{Hsize})::Hid "Error creating simple dataspace"
@bind h5s_get_simple_extent_dims(space_id::Hid, dims::Ptr{Hsize}, maxdims::Ptr{Hsize})::Cint "Error getting the dimensions for a dataspace"
@bind h5s_get_simple_extent_ndims(space_id::Hid)::Cint "Error getting the number of dimensions for a dataspace"
@bind h5s_get_simple_extent_type(space_id::Hid)::Cint "Error getting the dataspace type"
@bind h5s_is_simple(space_id::Hid)::Htri "Error determining whether dataspace is simple"
@bind h5s_select_hyperslab(dspace_id::Hid, seloper::Cint, start::Ptr{Hsize}, stride::Ptr{Hsize}, count::Ptr{Hsize}, block::Ptr{Hsize})::Herr "Error selecting hyperslab"

###
### Datatype Interface
###

@bind h5t_array_create(basetype_id::Hid, ndims::Cuint, sz::Ptr{Hsize})::Hid error("Error creating H5T_ARRAY of id ", basetype_id, " and size ", sz)
@bind h5t_close(dtype_id::Hid)::Herr "Error closing datatype"
@bind h5t_committed(dtype_id::Hid)::Htri error("Error determining whether datatype is committed")
@bind h5t_commit(loc_id::Hid, name::Ptr{UInt8}, dtype_id::Hid, lcpl_id::Hid, tcpl_id::Hid, tapl_id::Hid)::Herr "Error committing type"
@bind h5t_copy(dtype_id::Hid)::Hid "Error copying datatype"
@bind h5t_create(class_id::Cint, sz::Csize_t)::Hid error("Error creating datatype of id ", class_id)
@bind h5t_equal(dtype_id1::Hid, dtype_id2::Hid)::Hid "Error checking datatype equality"
@bind h5t_get_array_dims(dtype_id::Hid, dims::Ptr{Hsize})::Cint "Error getting dimensions of array"
@bind h5t_get_array_ndims(dtype_id::Hid)::Cint "Error getting ndims of array"
@bind h5t_get_class(dtype_id::Hid)::Cint "Error getting class"
@bind h5t_get_cset(dtype_id::Hid)::Cint "Error getting character set encoding"
@bind h5t_get_member_class(dtype_id::Hid, index::Cuint)::Cint error("Error getting class of compound datatype member #", index)
@bind h5t_get_member_index(dtype_id::Hid, membername::Ptr{UInt8})::Cint error("Error getting index of compound datatype member \"", membername, "\"")
@bind h5t_get_member_offset(dtype_id::Hid, index::Cuint)::Csize_t error("Error getting offset of compound datatype member #", index)
@bind h5t_get_member_type(dtype_id::Hid, index::Cuint)::Hid error("Error getting type of compound datatype member #", index)
@bind h5t_get_native_type(dtype_id::Hid, direction::Cint)::Hid "Error getting native type"
@bind h5t_get_nmembers(dtype_id::Hid)::Cint "Error getting the number of members"
@bind h5t_get_sign(dtype_id::Hid)::Cint "Error getting sign"
@bind h5t_get_size(dtype_id::Hid)::Csize_t "Error getting size"
@bind h5t_get_strpad(dtype_id::Hid)::Cint "Error getting string padding"
@bind h5t_get_super(dtype_id::Hid)::Hid "Error getting super type"
@bind h5t_insert(dtype_id::Hid, fieldname::Ptr{UInt8}, offset::Csize_t, field_id::Hid)::Herr error("Error adding field ", fieldname, " to compound datatype")
@bind h5t_is_variable_str(type_id::Hid)::Htri "Error determining whether string is of variable length"
@bind h5t_open(loc_id::Hid, name::Ptr{UInt8}, tapl_id::Hid)::Hid error("Error opening type ", h5i_get_name(loc_id), "/", name)
@bind h5t_set_cset(dtype_id::Hid, cset::Cint)::Herr "Error setting character set in datatype"
@bind h5t_set_precision(dtype_id::Hid, sz::Csize_t)::Herr "Error setting precision of datatype"
@bind h5t_set_size(dtype_id::Hid, sz::Csize_t)::Herr "Error setting size of datatype"
@bind h5t_set_strpad(dtype_id::Hid, sz::Cint)::Herr "Error setting size of datatype"
@bind h5t_vlen_create(base_type_id::Hid)::Hid "Error creating vlen type"

###
### Optimized Functions Interface
###

@bind h5do_append(dset_id::Hid, dxpl_id::Hid, index::Cuint, num_elem::Hsize, memtype::Hid, buffer::Ptr{Cvoid})::Herr "error appending"
@bind h5do_write_chunk(dset_id::Hid, dxpl_id::Hid, filter_mask::Int32, offset::Ptr{Hsize}, bufsize::Csize_t, buf::Ptr{Cvoid})::Herr "Error writing chunk"

###
### Table Interface
###

@bind h5tb_get_field_info(loc_id::Hid, table_name::Ptr{UInt8}, field_names::Ptr{Ptr{UInt8}}, field_sizes::Ptr{UInt8}, field_offsets::Ptr{UInt8}, type_size::Ptr{UInt8})::Herr "Error getting field information"
