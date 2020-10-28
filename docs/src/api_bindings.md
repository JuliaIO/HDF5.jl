```@raw html
<!-- This file is auto-generated and should not be manually editted. To update, run the
gen/gen_wrappers.jl script -->
```
# Low-level library bindings

At the lowest level, `HDF5.jl` operates by calling the public API of the HDF5 shared
library through a set of `ccall` wrapper functions.
This page documents the function names and nominal C argument types of the API which
have bindings in this package.
Note that in many cases, high-level data types are valid arguments through automatic
`ccall` conversions.
For instance, `HDF5Datatype` objects will be automatically converted to their `hid_t` ID
by Julia's `cconvert`+`unsafe_convert` `ccall` rules.

There are additional helper wrappers (often for out-argument functions) which are not
documented here.

## [`H5`](https://portal.hdfgroup.org/display/HDF5/Library) — General Library Functions
```julia
h5_close()
h5_dont_atexit()
h5_free_memory(buf::Ptr{Cvoid})
h5_garbage_collect()
h5_get_libversion(majnum::Ref{Cuint}, minnum::Ref{Cuint}, relnum::Ref{Cuint})
h5_is_library_threadsafe(is_ts::Ref{Cuint})
h5_open()
h5_set_free_list_limits(reg_global_lim::Cint, reg_list_lim::Cint, arr_global_lim::Cint, arr_list_lim::Cint, blk_global_lim::Cint, blk_list_lim::Cint)
```

## [`H5A`](https://portal.hdfgroup.org/display/HDF5/Attributes) — Attribute Interface
```julia
h5a_close(id::hid_t)
h5a_create(loc_id::hid_t, pathname::Ptr{UInt8}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t)
h5a_create_by_name(loc_id::hid_t, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t, lapl_id::hid_t)
h5a_delete(loc_id::hid_t, attr_name::Ptr{UInt8})
h5a_delete_by_idx(loc_id::hid_t, obj_name::Ptr{UInt8}, idx_type::Cint, order::Cint, n::hsize_t, lapl_id::hid_t)
h5a_delete_by_name(loc_id::hid_t, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, lapl_id::hid_t)
h5a_exists(obj_id::hid_t, attr_name::Ptr{UInt8})
h5a_exists_by_name(loc_id::hid_t, obj_name::Ptr{UInt8}, attr_name::Ptr{UInt8}, lapl_id::hid_t)
h5a_get_create_plist(attr_id::hid_t)
h5a_get_name(attr_id::hid_t, buf_size::Csize_t, buf::Ptr{UInt8})
h5a_get_name_by_idx(loc_id::hid_t, obj_name::Cstring, index_type::Cint, order::Cint, idx::hsize_t, name::Ptr{UInt8}, size::Csize_t, lapl_id::hid_t)
h5a_get_space(attr_id::hid_t)
h5a_get_type(attr_id::hid_t)
h5a_open(obj_id::hid_t, pathname::Ptr{UInt8}, aapl_id::hid_t)
h5a_read(attr_id::hid_t, mem_type_id::hid_t, buf::Ptr{Cvoid})
h5a_write(attr_hid::hid_t, mem_type_id::hid_t, buf::Ptr{Cvoid})
```

## [`H5D`](https://portal.hdfgroup.org/display/HDF5/Datasets) — Dataset Interface
```julia
h5d_close(dataset_id::hid_t)
h5d_create(loc_id::hid_t, pathname::Ptr{UInt8}, dtype_id::hid_t, space_id::hid_t, lcpl_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t)
h5d_flush(dataset_id::hid_t)
h5d_get_access_plist(dataset_id::hid_t)
h5d_get_create_plist(dataset_id::hid_t)
h5d_get_offset(dataset_id::hid_t)
h5d_get_space(dataset_id::hid_t)
h5d_get_type(dataset_id::hid_t)
h5d_open(loc_id::hid_t, pathname::Ptr{UInt8}, dapl_id::hid_t)
h5d_read(dataset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, xfer_plist_id::hid_t, buf::Ptr{Cvoid})
h5d_refresh(dataset_id::hid_t)
h5d_set_extent(dataset_id::hid_t, new_dims::Ptr{hsize_t})
h5d_vlen_get_buf_size(dset_id::hid_t, type_id::hid_t, space_id::hid_t, buf::Ptr{hsize_t})
h5d_vlen_reclaim(type_id::hid_t, space_id::hid_t, plist_id::hid_t, buf::Ptr{Cvoid})
h5d_write(dataset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, xfer_plist_id::hid_t, buf::Ptr{Cvoid})
```

## [`H5E`](https://portal.hdfgroup.org/display/HDF5/Error+Handling) — Error Interface
```julia
h5e_get_auto(estack_id::hid_t, func::Ref{Ptr{Cvoid}}, client_data::Ref{Ptr{Cvoid}})
h5e_set_auto(estack_id::hid_t, func::Ptr{Cvoid}, client_data::Ptr{Cvoid})
```

## [`H5F`](https://portal.hdfgroup.org/display/HDF5/Files) — File Interface
```julia
h5f_close(file_id::hid_t)
h5f_create(pathname::Ptr{UInt8}, flags::Cuint, fcpl_id::hid_t, fapl_id::hid_t)
h5f_flush(object_id::hid_t, scope::Cint)
h5f_get_access_plist(file_id::hid_t)
h5f_get_create_plist(file_id::hid_t)
h5f_get_intent(file_id::hid_t, intent::Ptr{Cuint})
h5f_get_name(obj_id::hid_t, buf::Ptr{UInt8}, buf_size::Csize_t)
h5f_get_obj_count(file_id::hid_t, types::Cuint)
h5f_get_obj_ids(file_id::hid_t, types::Cuint, max_objs::Csize_t, obj_id_list::Ptr{hid_t})
h5f_get_vfd_handle(file_id::hid_t, fapl_id::hid_t, file_handle::Ref{Ptr{Cvoid}})
h5f_is_hdf5(pathname::Cstring)
h5f_open(pathname::Cstring, flags::Cuint, fapl_id::hid_t)
h5f_start_swmr_write(id::hid_t)
```

## [`H5G`](https://portal.hdfgroup.org/display/HDF5/Groups) — Group Interface
```julia
h5g_close(group_id::hid_t)
h5g_create(loc_id::hid_t, pathname::Ptr{UInt8}, lcpl_id::hid_t, gcpl_id::hid_t, gapl_id::hid_t)
h5g_get_create_plist(group_id::hid_t)
h5g_get_info(group_id::hid_t, buf::Ptr{H5G_info_t})
h5g_get_num_objs(loc_id::hid_t, num_obj::Ptr{hsize_t})
h5g_get_objname_by_idx(loc_id::hid_t, idx::hsize_t, pathname::Ptr{UInt8}, size::Csize_t)
h5g_open(loc_id::hid_t, pathname::Ptr{UInt8}, gapl_id::hid_t)
```

## [`H5I`](https://portal.hdfgroup.org/display/HDF5/Identifiers) — Identifier Interface
```julia
h5i_dec_ref(obj_id::hid_t)
h5i_get_file_id(obj_id::hid_t)
h5i_get_name(obj_id::hid_t, buf::Ptr{UInt8}, buf_size::Csize_t)
h5i_get_ref(obj_id::hid_t)
h5i_get_type(obj_id::hid_t)
h5i_inc_ref(obj_id::hid_t)
h5i_is_valid(obj_id::hid_t)
```

## [`H5L`](https://portal.hdfgroup.org/display/HDF5/Links) — Link Interface
```julia
h5l_create_external(target_file_name::Ptr{UInt8}, target_obj_name::Ptr{UInt8}, link_loc_id::hid_t, link_name::Ptr{UInt8}, lcpl_id::hid_t, lapl_id::hid_t)
h5l_create_hard(obj_loc_id::hid_t, obj_name::Ptr{UInt8}, link_loc_id::hid_t, link_name::Ptr{UInt8}, lcpl_id::hid_t, lapl_id::hid_t)
h5l_create_soft(target_path::Ptr{UInt8}, link_loc_id::hid_t, link_name::Ptr{UInt8}, lcpl_id::hid_t, lapl_id::hid_t)
h5l_delete(obj_id::hid_t, pathname::Ptr{UInt8}, lapl_id::hid_t)
h5l_exists(loc_id::hid_t, pathname::Ptr{UInt8}, lapl_id::hid_t)
h5l_get_info(link_loc_id::hid_t, link_name::Ptr{UInt8}, link_buf::Ptr{H5L_info_t}, lapl_id::hid_t)
h5l_get_name_by_idx(loc_id::hid_t, group_name::Ptr{UInt8}, index_field::Cint, order::Cint, n::hsize_t, name::Ptr{UInt8}, size::Csize_t, lapl_id::hid_t)
```

## [`H5O`](https://portal.hdfgroup.org/display/HDF5/Objects) — Object Interface
```julia
h5o_close(object_id::hid_t)
h5o_copy(src_loc_id::hid_t, src_name::Ptr{UInt8}, dst_loc_id::hid_t, dst_name::Ptr{UInt8}, ocpypl_id::hid_t, lcpl_id::hid_t)
h5o_get_info(object_id::hid_t, buf::Ptr{H5O_info_t})
h5o_open(loc_id::hid_t, pathname::Ptr{UInt8}, lapl_id::hid_t)
h5o_open_by_addr(loc_id::hid_t, addr::haddr_t)
h5o_open_by_idx(loc_id::hid_t, group_name::Ptr{UInt8}, index_type::Cint, order::Cint, n::hsize_t, lapl_id::hid_t)
```

## [`H5P`](https://portal.hdfgroup.org/display/HDF5/Property+Lists) — Property Interface
```julia
h5p_close(id::hid_t)
h5p_create(cls_id::hid_t)
h5p_get_alignment(fapl_id::hid_t, threshold::Ref{hsize_t}, alignment::Ref{hsize_t})
h5p_get_alloc_time(plist_id::hid_t, alloc_time::Ptr{Cint})
h5p_get_char_encoding(plist_id::hid_t, encoding::Ref{Cint})
h5p_get_chunk(plist_id::hid_t, n_dims::Cint, dims::Ptr{hsize_t})
h5p_get_class_name(pcid::hid_t)
h5p_get_create_intermediate_group(lcpl_id::hid_t, crt_intermed_group::Ref{Cuint})
h5p_get_driver(plist_id::hid_t)
h5p_get_driver_info(plist_id::hid_t)
h5p_get_dxpl_mpio(dxpl_id::hid_t, xfer_mode::Ptr{Cint})
h5p_get_fapl_mpio32(fapl_id::hid_t, comm::Ptr{Hmpih32}, info::Ptr{Hmpih32})
h5p_get_fapl_mpio64(fapl_id::hid_t, comm::Ptr{Hmpih64}, info::Ptr{Hmpih64})
h5p_get_fclose_degree(fapl_id::hid_t, fc_degree::Ref{Cint})
h5p_get_filter_by_id(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Ref{Cuint}, cd_nelmts::Ref{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{UInt8}, filter_config::Ptr{Cuint})
h5p_get_layout(plist_id::hid_t)
h5p_get_libver_bounds(fapl_id::hid_t, low::Ref{Cint}, high::Ref{Cint})
h5p_get_local_heap_size_hint(plist_id::hid_t, size_hint::Ref{Csize_t})
h5p_get_obj_track_times(plist_id::hid_t, track_times::Ref{UInt8})
h5p_get_userblock(plist_id::hid_t, len::Ptr{hsize_t})
h5p_modify_filter(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})
h5p_set_alignment(plist_id::hid_t, threshold::hsize_t, alignment::hsize_t)
h5p_set_alloc_time(plist_id::hid_t, alloc_time::Cint)
h5p_set_char_encoding(plist_id::hid_t, encoding::Cint)
h5p_set_chunk(plist_id::hid_t, ndims::Cint, dims::Ptr{hsize_t})
h5p_set_chunk_cache(dapl_id::hid_t, rdcc_nslots::Csize_t, rdcc_nbytes::Csize_t, rdcc_w0::Cdouble)
h5p_set_create_intermediate_group(plist_id::hid_t, setting::Cuint)
h5p_set_deflate(plist_id::hid_t, setting::Cuint)
h5p_set_dxpl_mpio(dxpl_id::hid_t, xfer_mode::Cint)
h5p_set_external(plist_id::hid_t, name::Ptr{UInt8}, offset::Int, size::Csize_t)
h5p_set_fapl_mpio32(fapl_id::hid_t, comm::Hmpih32, info::Hmpih32)
h5p_set_fapl_mpio64(fapl_id::hid_t, comm::Hmpih64, info::Hmpih64)
h5p_set_fclose_degree(plist_id::hid_t, fc_degree::Cint)
h5p_set_filter(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})
h5p_set_layout(plist_id::hid_t, setting::Cint)
h5p_set_libver_bounds(fapl_id::hid_t, low::Cint, high::Cint)
h5p_set_local_heap_size_hint(plist_id::hid_t, size_hint::Csize_t)
h5p_set_obj_track_times(plist_id::hid_t, track_times::UInt8)
h5p_set_shuffle(plist_id::hid_t)
h5p_set_userblock(plist_id::hid_t, len::hsize_t)
h5p_set_virtual(dcpl_id::hid_t, vspace_id::hid_t, src_file_name::Ptr{UInt8}, src_dset_name::Ptr{UInt8}, src_space_id::hid_t)
```

## [`H5R`](https://portal.hdfgroup.org/display/HDF5/References) — Reference Interface
```julia
h5r_create(ref::Ptr{Cvoid}, loc_id::hid_t, pathname::Ptr{UInt8}, ref_type::Cint, space_id::hid_t)
h5r_dereference(obj_id::hid_t, oapl_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid})
h5r_get_obj_type(loc_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid}, obj_type::Ptr{Cint})
h5r_get_region(loc_id::hid_t, ref_type::Cint, ref::Ptr{Cvoid})
```

## [`H5S`](https://portal.hdfgroup.org/display/HDF5/Dataspaces) — Dataspace Interface
```julia
h5s_close(space_id::hid_t)
h5s_copy(space_id::hid_t)
h5s_create(class::Cint)
h5s_create_simple(rank::Cint, current_dims::Ptr{hsize_t}, maximum_dims::Ptr{hsize_t})
h5s_get_simple_extent_dims(space_id::hid_t, dims::Ptr{hsize_t}, maxdims::Ptr{hsize_t})
h5s_get_simple_extent_ndims(space_id::hid_t)
h5s_get_simple_extent_type(space_id::hid_t)
h5s_is_simple(space_id::hid_t)
h5s_select_hyperslab(dspace_id::hid_t, seloper::Cint, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})
```

## [`H5T`](https://portal.hdfgroup.org/display/HDF5/Datatypes) — Datatype Interface
```julia
h5t_array_create(basetype_id::hid_t, ndims::Cuint, sz::Ptr{hsize_t})
h5t_close(dtype_id::hid_t)
h5t_commit(loc_id::hid_t, name::Ptr{UInt8}, dtype_id::hid_t, lcpl_id::hid_t, tcpl_id::hid_t, tapl_id::hid_t)
h5t_committed(dtype_id::hid_t)
h5t_copy(dtype_id::hid_t)
h5t_create(class_id::Cint, sz::Csize_t)
h5t_equal(dtype_id1::hid_t, dtype_id2::hid_t)
h5t_get_array_dims(dtype_id::hid_t, dims::Ptr{hsize_t})
h5t_get_array_ndims(dtype_id::hid_t)
h5t_get_class(dtype_id::hid_t)
h5t_get_cset(dtype_id::hid_t)
h5t_get_ebias(dtype_id::hid_t)
h5t_get_fields(dtype_id::hid_t, spos::Ref{Csize_t}, epos::Ref{Csize_t}, esize::Ref{Csize_t}, mpos::Ref{Csize_t}, msize::Ref{Csize_t})
h5t_get_member_class(dtype_id::hid_t, index::Cuint)
h5t_get_member_index(dtype_id::hid_t, membername::Ptr{UInt8})
h5t_get_member_name(type_id::hid_t, index::Cuint)
h5t_get_member_offset(dtype_id::hid_t, index::Cuint)
h5t_get_member_type(dtype_id::hid_t, index::Cuint)
h5t_get_native_type(dtype_id::hid_t, direction::Cint)
h5t_get_nmembers(dtype_id::hid_t)
h5t_get_sign(dtype_id::hid_t)
h5t_get_size(dtype_id::hid_t)
h5t_get_strpad(dtype_id::hid_t)
h5t_get_super(dtype_id::hid_t)
h5t_get_tag(type_id::hid_t)
h5t_insert(dtype_id::hid_t, fieldname::Ptr{UInt8}, offset::Csize_t, field_id::hid_t)
h5t_is_variable_str(type_id::hid_t)
h5t_lock(type_id::hid_t)
h5t_open(loc_id::hid_t, name::Ptr{UInt8}, tapl_id::hid_t)
h5t_set_cset(dtype_id::hid_t, cset::Cint)
h5t_set_ebias(dtype_id::hid_t, ebias::Csize_t)
h5t_set_fields(dtype_id::hid_t, spos::Csize_t, epos::Csize_t, esize::Csize_t, mpos::Csize_t, msize::Csize_t)
h5t_set_precision(dtype_id::hid_t, sz::Csize_t)
h5t_set_size(dtype_id::hid_t, sz::Csize_t)
h5t_set_strpad(dtype_id::hid_t, sz::Cint)
h5t_vlen_create(base_type_id::hid_t)
```

## [`H5Z`](https://portal.hdfgroup.org/display/HDF5/Filters) — Filter Interface
```julia
h5z_register(filter_class::Ref{H5Z_class_t})
```

## [`H5DO`](https://portal.hdfgroup.org/display/HDF5/Optimizations) — Optimized Functions Interface
```julia
h5do_append(dset_id::hid_t, dxpl_id::hid_t, index::Cuint, num_elem::hsize_t, memtype::hid_t, buffer::Ptr{Cvoid})
h5do_write_chunk(dset_id::hid_t, dxpl_id::hid_t, filter_mask::Int32, offset::Ptr{hsize_t}, bufsize::Csize_t, buf::Ptr{Cvoid})
```

## [`H5LT`](https://portal.hdfgroup.org/display/HDF5/Lite) — Lite Interface
```julia
h5lt_dtype_to_text(datatype::hid_t, str::Ptr{UInt8}, lang_type::Cint, len::Ref{Csize_t})
```

## [`H5TB`](https://portal.hdfgroup.org/display/HDF5/Tables) — Table Interface
```julia
h5tb_get_field_info(loc_id::hid_t, table_name::Ptr{UInt8}, field_names::Ptr{Ptr{UInt8}}, field_sizes::Ptr{UInt8}, field_offsets::Ptr{UInt8}, type_size::Ptr{UInt8})
```


