```@raw html
<!-- This file is auto-generated and should not be manually editted. To update, run the
gen/gen_wrappers.jl script -->
```
```@meta
CurrentModule = HDF5.API
```

# Low-level library bindings

At the lowest level, `HDF5.jl` operates by calling the public API of the HDF5 shared
library through a set of `ccall` wrapper functions.
This page documents the function names and nominal C argument types of the API which
have bindings in this package.
Note that in many cases, high-level data types are valid arguments through automatic
`ccall` conversions.
For instance, `HDF5.Datatype` objects will be automatically converted to their `hid_t` ID
by Julia's `cconvert`+`unsafe_convert` `ccall` rules.

There are additional helper wrappers (often for out-argument functions) which are not
documented here.

---

## [`H5`](https://portal.hdfgroup.org/display/HDF5/Library) — General Library Functions
- [`h5_close`](@ref h5_close)
- [`h5_dont_atexit`](@ref h5_dont_atexit)
- [`h5_free_memory`](@ref h5_free_memory)
- [`h5_garbage_collect`](@ref h5_garbage_collect)
- [`h5_get_libversion`](@ref h5_get_libversion)
- [`h5_is_library_threadsafe`](@ref h5_is_library_threadsafe)
- [`h5_open`](@ref h5_open)
- [`h5_set_free_list_limits`](@ref h5_set_free_list_limits)
```@docs
h5_close
h5_dont_atexit
h5_free_memory
h5_garbage_collect
h5_get_libversion
h5_is_library_threadsafe
h5_open
h5_set_free_list_limits
```

---

## [`H5A`](https://portal.hdfgroup.org/display/HDF5/Attributes) — Attribute Interface
- [`h5a_close`](@ref h5a_close)
- [`h5a_create`](@ref h5a_create)
- [`h5a_create_by_name`](@ref h5a_create_by_name)
- [`h5a_delete`](@ref h5a_delete)
- [`h5a_delete_by_idx`](@ref h5a_delete_by_idx)
- [`h5a_delete_by_name`](@ref h5a_delete_by_name)
- [`h5a_exists`](@ref h5a_exists)
- [`h5a_exists_by_name`](@ref h5a_exists_by_name)
- [`h5a_get_create_plist`](@ref h5a_get_create_plist)
- [`h5a_get_name`](@ref h5a_get_name)
- [`h5a_get_name_by_idx`](@ref h5a_get_name_by_idx)
- [`h5a_get_space`](@ref h5a_get_space)
- [`h5a_get_type`](@ref h5a_get_type)
- [`h5a_iterate`](@ref h5a_iterate)
- [`h5a_open`](@ref h5a_open)
- [`h5a_read`](@ref h5a_read)
- [`h5a_write`](@ref h5a_write)
```@docs
h5a_close
h5a_create
h5a_create_by_name
h5a_delete
h5a_delete_by_idx
h5a_delete_by_name
h5a_exists
h5a_exists_by_name
h5a_get_create_plist
h5a_get_name
h5a_get_name_by_idx
h5a_get_space
h5a_get_type
h5a_iterate
h5a_open
h5a_read
h5a_write
```

---

## [`H5D`](https://portal.hdfgroup.org/display/HDF5/Datasets) — Dataset Interface
- [`h5d_close`](@ref h5d_close)
- [`h5d_create`](@ref h5d_create)
- [`h5d_extend`](@ref h5d_extend)
- [`h5d_fill`](@ref h5d_fill)
- [`h5d_flush`](@ref h5d_flush)
- [`h5d_gather`](@ref h5d_gather)
- [`h5d_get_access_plist`](@ref h5d_get_access_plist)
- [`h5d_get_chunk_info`](@ref h5d_get_chunk_info)
- [`h5d_get_chunk_info_by_coord`](@ref h5d_get_chunk_info_by_coord)
- [`h5d_get_chunk_storage_size`](@ref h5d_get_chunk_storage_size)
- [`h5d_get_create_plist`](@ref h5d_get_create_plist)
- [`h5d_get_num_chunks`](@ref h5d_get_num_chunks)
- [`h5d_get_offset`](@ref h5d_get_offset)
- [`h5d_get_space`](@ref h5d_get_space)
- [`h5d_get_space_status`](@ref h5d_get_space_status)
- [`h5d_get_storage_size`](@ref h5d_get_storage_size)
- [`h5d_get_type`](@ref h5d_get_type)
- [`h5d_iterate`](@ref h5d_iterate)
- [`h5d_open`](@ref h5d_open)
- [`h5d_read`](@ref h5d_read)
- [`h5d_read_chunk`](@ref h5d_read_chunk)
- [`h5d_refresh`](@ref h5d_refresh)
- [`h5d_scatter`](@ref h5d_scatter)
- [`h5d_set_extent`](@ref h5d_set_extent)
- [`h5d_vlen_get_buf_size`](@ref h5d_vlen_get_buf_size)
- [`h5d_vlen_reclaim`](@ref h5d_vlen_reclaim)
- [`h5d_write`](@ref h5d_write)
- [`h5d_write_chunk`](@ref h5d_write_chunk)
```@docs
h5d_close
h5d_create
h5d_extend
h5d_fill
h5d_flush
h5d_gather
h5d_get_access_plist
h5d_get_chunk_info
h5d_get_chunk_info_by_coord
h5d_get_chunk_storage_size
h5d_get_create_plist
h5d_get_num_chunks
h5d_get_offset
h5d_get_space
h5d_get_space_status
h5d_get_storage_size
h5d_get_type
h5d_iterate
h5d_open
h5d_read
h5d_read_chunk
h5d_refresh
h5d_scatter
h5d_set_extent
h5d_vlen_get_buf_size
h5d_vlen_reclaim
h5d_write
h5d_write_chunk
```

---

## [`H5E`](https://portal.hdfgroup.org/display/HDF5/Error+Handling) — Error Interface
- [`h5e_close_stack`](@ref h5e_close_stack)
- [`h5e_get_auto`](@ref h5e_get_auto)
- [`h5e_get_current_stack`](@ref h5e_get_current_stack)
- [`h5e_get_msg`](@ref h5e_get_msg)
- [`h5e_get_num`](@ref h5e_get_num)
- [`h5e_set_auto`](@ref h5e_set_auto)
- [`h5e_walk`](@ref h5e_walk)
```@docs
h5e_close_stack
h5e_get_auto
h5e_get_current_stack
h5e_get_msg
h5e_get_num
h5e_set_auto
h5e_walk
```

---

## [`H5F`](https://portal.hdfgroup.org/display/HDF5/Files) — File Interface
- [`h5f_close`](@ref h5f_close)
- [`h5f_create`](@ref h5f_create)
- [`h5f_flush`](@ref h5f_flush)
- [`h5f_get_access_plist`](@ref h5f_get_access_plist)
- [`h5f_get_create_plist`](@ref h5f_get_create_plist)
- [`h5f_get_intent`](@ref h5f_get_intent)
- [`h5f_get_name`](@ref h5f_get_name)
- [`h5f_get_obj_count`](@ref h5f_get_obj_count)
- [`h5f_get_obj_ids`](@ref h5f_get_obj_ids)
- [`h5f_get_vfd_handle`](@ref h5f_get_vfd_handle)
- [`h5f_is_hdf5`](@ref h5f_is_hdf5)
- [`h5f_open`](@ref h5f_open)
- [`h5f_start_swmr_write`](@ref h5f_start_swmr_write)
```@docs
h5f_close
h5f_create
h5f_flush
h5f_get_access_plist
h5f_get_create_plist
h5f_get_intent
h5f_get_name
h5f_get_obj_count
h5f_get_obj_ids
h5f_get_vfd_handle
h5f_is_hdf5
h5f_open
h5f_start_swmr_write
```

---

## [`H5G`](https://portal.hdfgroup.org/display/HDF5/Groups) — Group Interface
- [`h5g_close`](@ref h5g_close)
- [`h5g_create`](@ref h5g_create)
- [`h5g_get_create_plist`](@ref h5g_get_create_plist)
- [`h5g_get_info`](@ref h5g_get_info)
- [`h5g_get_num_objs`](@ref h5g_get_num_objs)
- [`h5g_get_objname_by_idx`](@ref h5g_get_objname_by_idx)
- [`h5g_open`](@ref h5g_open)
```@docs
h5g_close
h5g_create
h5g_get_create_plist
h5g_get_info
h5g_get_num_objs
h5g_get_objname_by_idx
h5g_open
```

---

## [`H5I`](https://portal.hdfgroup.org/display/HDF5/Identifiers) — Identifier Interface
- [`h5i_dec_ref`](@ref h5i_dec_ref)
- [`h5i_get_file_id`](@ref h5i_get_file_id)
- [`h5i_get_name`](@ref h5i_get_name)
- [`h5i_get_ref`](@ref h5i_get_ref)
- [`h5i_get_type`](@ref h5i_get_type)
- [`h5i_inc_ref`](@ref h5i_inc_ref)
- [`h5i_is_valid`](@ref h5i_is_valid)
```@docs
h5i_dec_ref
h5i_get_file_id
h5i_get_name
h5i_get_ref
h5i_get_type
h5i_inc_ref
h5i_is_valid
```

---

## [`H5L`](https://portal.hdfgroup.org/display/HDF5/Links) — Link Interface
- [`h5l_create_external`](@ref h5l_create_external)
- [`h5l_create_hard`](@ref h5l_create_hard)
- [`h5l_create_soft`](@ref h5l_create_soft)
- [`h5l_delete`](@ref h5l_delete)
- [`h5l_exists`](@ref h5l_exists)
- [`h5l_get_info`](@ref h5l_get_info)
- [`h5l_get_name_by_idx`](@ref h5l_get_name_by_idx)
- [`h5l_iterate`](@ref h5l_iterate)
```@docs
h5l_create_external
h5l_create_hard
h5l_create_soft
h5l_delete
h5l_exists
h5l_get_info
h5l_get_name_by_idx
h5l_iterate
```

---

## [`H5O`](https://portal.hdfgroup.org/display/HDF5/Objects) — Object Interface
- [`h5o_close`](@ref h5o_close)
- [`h5o_copy`](@ref h5o_copy)
- [`h5o_get_info`](@ref h5o_get_info)
- [`h5o_open`](@ref h5o_open)
- [`h5o_open_by_addr`](@ref h5o_open_by_addr)
- [`h5o_open_by_idx`](@ref h5o_open_by_idx)
```@docs
h5o_close
h5o_copy
h5o_get_info
h5o_open
h5o_open_by_addr
h5o_open_by_idx
```

---

## [`H5P`](https://portal.hdfgroup.org/display/HDF5/Property+Lists) — Property Interface
- [`h5p_close`](@ref h5p_close)
- [`h5p_create`](@ref h5p_create)
- [`h5p_get_alignment`](@ref h5p_get_alignment)
- [`h5p_get_alloc_time`](@ref h5p_get_alloc_time)
- [`h5p_get_char_encoding`](@ref h5p_get_char_encoding)
- [`h5p_get_chunk`](@ref h5p_get_chunk)
- [`h5p_get_class_name`](@ref h5p_get_class_name)
- [`h5p_get_create_intermediate_group`](@ref h5p_get_create_intermediate_group)
- [`h5p_get_driver`](@ref h5p_get_driver)
- [`h5p_get_driver_info`](@ref h5p_get_driver_info)
- [`h5p_get_dxpl_mpio`](@ref h5p_get_dxpl_mpio)
- [`h5p_get_fapl_mpio32`](@ref h5p_get_fapl_mpio32)
- [`h5p_get_fapl_mpio64`](@ref h5p_get_fapl_mpio64)
- [`h5p_get_fclose_degree`](@ref h5p_get_fclose_degree)
- [`h5p_get_filter`](@ref h5p_get_filter)
- [`h5p_get_filter_by_id`](@ref h5p_get_filter_by_id)
- [`h5p_get_layout`](@ref h5p_get_layout)
- [`h5p_get_libver_bounds`](@ref h5p_get_libver_bounds)
- [`h5p_get_local_heap_size_hint`](@ref h5p_get_local_heap_size_hint)
- [`h5p_get_nfilters`](@ref h5p_get_nfilters)
- [`h5p_get_obj_track_times`](@ref h5p_get_obj_track_times)
- [`h5p_get_userblock`](@ref h5p_get_userblock)
- [`h5p_modify_filter`](@ref h5p_modify_filter)
- [`h5p_remove_filter`](@ref h5p_remove_filter)
- [`h5p_set_alignment`](@ref h5p_set_alignment)
- [`h5p_set_alloc_time`](@ref h5p_set_alloc_time)
- [`h5p_set_char_encoding`](@ref h5p_set_char_encoding)
- [`h5p_set_chunk`](@ref h5p_set_chunk)
- [`h5p_set_chunk_cache`](@ref h5p_set_chunk_cache)
- [`h5p_set_create_intermediate_group`](@ref h5p_set_create_intermediate_group)
- [`h5p_set_deflate`](@ref h5p_set_deflate)
- [`h5p_set_dxpl_mpio`](@ref h5p_set_dxpl_mpio)
- [`h5p_set_external`](@ref h5p_set_external)
- [`h5p_set_fapl_mpio32`](@ref h5p_set_fapl_mpio32)
- [`h5p_set_fapl_mpio64`](@ref h5p_set_fapl_mpio64)
- [`h5p_set_fapl_sec2`](@ref h5p_set_fapl_sec2)
- [`h5p_set_fclose_degree`](@ref h5p_set_fclose_degree)
- [`h5p_set_filter`](@ref h5p_set_filter)
- [`h5p_set_fletcher32`](@ref h5p_set_fletcher32)
- [`h5p_set_layout`](@ref h5p_set_layout)
- [`h5p_set_libver_bounds`](@ref h5p_set_libver_bounds)
- [`h5p_set_local_heap_size_hint`](@ref h5p_set_local_heap_size_hint)
- [`h5p_set_nbit`](@ref h5p_set_nbit)
- [`h5p_set_obj_track_times`](@ref h5p_set_obj_track_times)
- [`h5p_set_scaleoffset`](@ref h5p_set_scaleoffset)
- [`h5p_set_shuffle`](@ref h5p_set_shuffle)
- [`h5p_set_szip`](@ref h5p_set_szip)
- [`h5p_set_userblock`](@ref h5p_set_userblock)
- [`h5p_set_virtual`](@ref h5p_set_virtual)
```@docs
h5p_close
h5p_create
h5p_get_alignment
h5p_get_alloc_time
h5p_get_char_encoding
h5p_get_chunk
h5p_get_class_name
h5p_get_create_intermediate_group
h5p_get_driver
h5p_get_driver_info
h5p_get_dxpl_mpio
h5p_get_fapl_mpio32
h5p_get_fapl_mpio64
h5p_get_fclose_degree
h5p_get_filter
h5p_get_filter_by_id
h5p_get_layout
h5p_get_libver_bounds
h5p_get_local_heap_size_hint
h5p_get_nfilters
h5p_get_obj_track_times
h5p_get_userblock
h5p_modify_filter
h5p_remove_filter
h5p_set_alignment
h5p_set_alloc_time
h5p_set_char_encoding
h5p_set_chunk
h5p_set_chunk_cache
h5p_set_create_intermediate_group
h5p_set_deflate
h5p_set_dxpl_mpio
h5p_set_external
h5p_set_fapl_mpio32
h5p_set_fapl_mpio64
h5p_set_fapl_sec2
h5p_set_fclose_degree
h5p_set_filter
h5p_set_fletcher32
h5p_set_layout
h5p_set_libver_bounds
h5p_set_local_heap_size_hint
h5p_set_nbit
h5p_set_obj_track_times
h5p_set_scaleoffset
h5p_set_shuffle
h5p_set_szip
h5p_set_userblock
h5p_set_virtual
```

---

## [`H5R`](https://portal.hdfgroup.org/display/HDF5/References) — Reference Interface
- [`h5r_create`](@ref h5r_create)
- [`h5r_dereference`](@ref h5r_dereference)
- [`h5r_get_obj_type`](@ref h5r_get_obj_type)
- [`h5r_get_region`](@ref h5r_get_region)
```@docs
h5r_create
h5r_dereference
h5r_get_obj_type
h5r_get_region
```

---

## [`H5S`](https://portal.hdfgroup.org/display/HDF5/Dataspaces) — Dataspace Interface
- [`h5s_close`](@ref h5s_close)
- [`h5s_combine_select`](@ref h5s_combine_select)
- [`h5s_copy`](@ref h5s_copy)
- [`h5s_create`](@ref h5s_create)
- [`h5s_create_simple`](@ref h5s_create_simple)
- [`h5s_extent_equal`](@ref h5s_extent_equal)
- [`h5s_get_regular_hyperslab`](@ref h5s_get_regular_hyperslab)
- [`h5s_get_select_hyper_nblocks`](@ref h5s_get_select_hyper_nblocks)
- [`h5s_get_select_npoints`](@ref h5s_get_select_npoints)
- [`h5s_get_select_type`](@ref h5s_get_select_type)
- [`h5s_get_simple_extent_dims`](@ref h5s_get_simple_extent_dims)
- [`h5s_get_simple_extent_ndims`](@ref h5s_get_simple_extent_ndims)
- [`h5s_get_simple_extent_type`](@ref h5s_get_simple_extent_type)
- [`h5s_is_regular_hyperslab`](@ref h5s_is_regular_hyperslab)
- [`h5s_is_simple`](@ref h5s_is_simple)
- [`h5s_select_hyperslab`](@ref h5s_select_hyperslab)
- [`h5s_set_extent_simple`](@ref h5s_set_extent_simple)
```@docs
h5s_close
h5s_combine_select
h5s_copy
h5s_create
h5s_create_simple
h5s_extent_equal
h5s_get_regular_hyperslab
h5s_get_select_hyper_nblocks
h5s_get_select_npoints
h5s_get_select_type
h5s_get_simple_extent_dims
h5s_get_simple_extent_ndims
h5s_get_simple_extent_type
h5s_is_regular_hyperslab
h5s_is_simple
h5s_select_hyperslab
h5s_set_extent_simple
```

---

## [`H5T`](https://portal.hdfgroup.org/display/HDF5/Datatypes) — Datatype Interface
- [`h5t_array_create`](@ref h5t_array_create)
- [`h5t_close`](@ref h5t_close)
- [`h5t_commit`](@ref h5t_commit)
- [`h5t_committed`](@ref h5t_committed)
- [`h5t_copy`](@ref h5t_copy)
- [`h5t_create`](@ref h5t_create)
- [`h5t_enum_insert`](@ref h5t_enum_insert)
- [`h5t_equal`](@ref h5t_equal)
- [`h5t_get_array_dims`](@ref h5t_get_array_dims)
- [`h5t_get_array_ndims`](@ref h5t_get_array_ndims)
- [`h5t_get_class`](@ref h5t_get_class)
- [`h5t_get_cset`](@ref h5t_get_cset)
- [`h5t_get_ebias`](@ref h5t_get_ebias)
- [`h5t_get_fields`](@ref h5t_get_fields)
- [`h5t_get_member_class`](@ref h5t_get_member_class)
- [`h5t_get_member_index`](@ref h5t_get_member_index)
- [`h5t_get_member_name`](@ref h5t_get_member_name)
- [`h5t_get_member_offset`](@ref h5t_get_member_offset)
- [`h5t_get_member_type`](@ref h5t_get_member_type)
- [`h5t_get_native_type`](@ref h5t_get_native_type)
- [`h5t_get_nmembers`](@ref h5t_get_nmembers)
- [`h5t_get_sign`](@ref h5t_get_sign)
- [`h5t_get_size`](@ref h5t_get_size)
- [`h5t_get_strpad`](@ref h5t_get_strpad)
- [`h5t_get_super`](@ref h5t_get_super)
- [`h5t_get_tag`](@ref h5t_get_tag)
- [`h5t_insert`](@ref h5t_insert)
- [`h5t_is_variable_str`](@ref h5t_is_variable_str)
- [`h5t_lock`](@ref h5t_lock)
- [`h5t_open`](@ref h5t_open)
- [`h5t_set_cset`](@ref h5t_set_cset)
- [`h5t_set_ebias`](@ref h5t_set_ebias)
- [`h5t_set_fields`](@ref h5t_set_fields)
- [`h5t_set_precision`](@ref h5t_set_precision)
- [`h5t_set_size`](@ref h5t_set_size)
- [`h5t_set_strpad`](@ref h5t_set_strpad)
- [`h5t_set_tag`](@ref h5t_set_tag)
- [`h5t_vlen_create`](@ref h5t_vlen_create)
```@docs
h5t_array_create
h5t_close
h5t_commit
h5t_committed
h5t_copy
h5t_create
h5t_enum_insert
h5t_equal
h5t_get_array_dims
h5t_get_array_ndims
h5t_get_class
h5t_get_cset
h5t_get_ebias
h5t_get_fields
h5t_get_member_class
h5t_get_member_index
h5t_get_member_name
h5t_get_member_offset
h5t_get_member_type
h5t_get_native_type
h5t_get_nmembers
h5t_get_sign
h5t_get_size
h5t_get_strpad
h5t_get_super
h5t_get_tag
h5t_insert
h5t_is_variable_str
h5t_lock
h5t_open
h5t_set_cset
h5t_set_ebias
h5t_set_fields
h5t_set_precision
h5t_set_size
h5t_set_strpad
h5t_set_tag
h5t_vlen_create
```

---

## [`H5Z`](https://portal.hdfgroup.org/display/HDF5/Filters) — Filter Interface
- [`h5z_register`](@ref h5z_register)
```@docs
h5z_register
```

---

## [`H5DO`](https://portal.hdfgroup.org/display/HDF5/Optimizations) — Optimized Functions Interface
- [`h5do_append`](@ref h5do_append)
- [`h5do_write_chunk`](@ref h5do_write_chunk)
```@docs
h5do_append
h5do_write_chunk
```

---

## [`H5DS`](https://portal.hdfgroup.org/display/HDF5/Dimension+Scales) — Dimension Scale Interface
- [`h5ds_attach_scale`](@ref h5ds_attach_scale)
- [`h5ds_detach_scale`](@ref h5ds_detach_scale)
- [`h5ds_get_label`](@ref h5ds_get_label)
- [`h5ds_get_num_scales`](@ref h5ds_get_num_scales)
- [`h5ds_get_scale_name`](@ref h5ds_get_scale_name)
- [`h5ds_is_attached`](@ref h5ds_is_attached)
- [`h5ds_is_scale`](@ref h5ds_is_scale)
- [`h5ds_set_label`](@ref h5ds_set_label)
- [`h5ds_set_scale`](@ref h5ds_set_scale)
```@docs
h5ds_attach_scale
h5ds_detach_scale
h5ds_get_label
h5ds_get_num_scales
h5ds_get_scale_name
h5ds_is_attached
h5ds_is_scale
h5ds_set_label
h5ds_set_scale
```

---

## [`H5LT`](https://portal.hdfgroup.org/display/HDF5/Lite) — Lite Interface
- [`h5lt_dtype_to_text`](@ref h5lt_dtype_to_text)
```@docs
h5lt_dtype_to_text
```

---

## [`H5TB`](https://portal.hdfgroup.org/display/HDF5/Tables) — Table Interface
- [`h5tb_append_records`](@ref h5tb_append_records)
- [`h5tb_get_field_info`](@ref h5tb_get_field_info)
- [`h5tb_get_table_info`](@ref h5tb_get_table_info)
- [`h5tb_make_table`](@ref h5tb_make_table)
- [`h5tb_read_records`](@ref h5tb_read_records)
- [`h5tb_read_table`](@ref h5tb_read_table)
- [`h5tb_write_records`](@ref h5tb_write_records)
```@docs
h5tb_append_records
h5tb_get_field_info
h5tb_get_table_info
h5tb_make_table
h5tb_read_records
h5tb_read_table
h5tb_write_records
```


