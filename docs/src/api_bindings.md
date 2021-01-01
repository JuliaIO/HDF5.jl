```@raw html
<!-- This file is auto-generated and should not be manually editted. To update, run the
gen/gen_wrappers.jl script -->
```
```@meta
CurrentModule = HDF5
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

---

## [`H5`](https://portal.hdfgroup.org/display/HDF5/Library) — General Library Functions
- [`h5_close`](@ref HDF5.h5_close)
- [`h5_dont_atexit`](@ref HDF5.h5_dont_atexit)
- [`h5_free_memory`](@ref HDF5.h5_free_memory)
- [`h5_garbage_collect`](@ref HDF5.h5_garbage_collect)
- [`h5_get_libversion`](@ref HDF5.h5_get_libversion)
- [`h5_is_library_threadsafe`](@ref HDF5.h5_is_library_threadsafe)
- [`h5_open`](@ref HDF5.h5_open)
- [`h5_set_free_list_limits`](@ref HDF5.h5_set_free_list_limits)
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
- [`h5a_close`](@ref HDF5.h5a_close)
- [`h5a_create`](@ref HDF5.h5a_create)
- [`h5a_create_by_name`](@ref HDF5.h5a_create_by_name)
- [`h5a_delete`](@ref HDF5.h5a_delete)
- [`h5a_delete_by_idx`](@ref HDF5.h5a_delete_by_idx)
- [`h5a_delete_by_name`](@ref HDF5.h5a_delete_by_name)
- [`h5a_exists`](@ref HDF5.h5a_exists)
- [`h5a_exists_by_name`](@ref HDF5.h5a_exists_by_name)
- [`h5a_get_create_plist`](@ref HDF5.h5a_get_create_plist)
- [`h5a_get_name`](@ref HDF5.h5a_get_name)
- [`h5a_get_name_by_idx`](@ref HDF5.h5a_get_name_by_idx)
- [`h5a_get_space`](@ref HDF5.h5a_get_space)
- [`h5a_get_type`](@ref HDF5.h5a_get_type)
- [`h5a_iterate`](@ref HDF5.h5a_iterate)
- [`h5a_open`](@ref HDF5.h5a_open)
- [`h5a_read`](@ref HDF5.h5a_read)
- [`h5a_write`](@ref HDF5.h5a_write)
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
- [`h5d_close`](@ref HDF5.h5d_close)
- [`h5d_create`](@ref HDF5.h5d_create)
- [`h5d_flush`](@ref HDF5.h5d_flush)
- [`h5d_get_access_plist`](@ref HDF5.h5d_get_access_plist)
- [`h5d_get_create_plist`](@ref HDF5.h5d_get_create_plist)
- [`h5d_get_offset`](@ref HDF5.h5d_get_offset)
- [`h5d_get_space`](@ref HDF5.h5d_get_space)
- [`h5d_get_type`](@ref HDF5.h5d_get_type)
- [`h5d_open`](@ref HDF5.h5d_open)
- [`h5d_read`](@ref HDF5.h5d_read)
- [`h5d_refresh`](@ref HDF5.h5d_refresh)
- [`h5d_set_extent`](@ref HDF5.h5d_set_extent)
- [`h5d_vlen_get_buf_size`](@ref HDF5.h5d_vlen_get_buf_size)
- [`h5d_vlen_reclaim`](@ref HDF5.h5d_vlen_reclaim)
- [`h5d_write`](@ref HDF5.h5d_write)
```@docs
h5d_close
h5d_create
h5d_flush
h5d_get_access_plist
h5d_get_create_plist
h5d_get_offset
h5d_get_space
h5d_get_type
h5d_open
h5d_read
h5d_refresh
h5d_set_extent
h5d_vlen_get_buf_size
h5d_vlen_reclaim
h5d_write
```

---

## [`H5E`](https://portal.hdfgroup.org/display/HDF5/Error+Handling) — Error Interface
- [`h5e_get_auto`](@ref HDF5.h5e_get_auto)
- [`h5e_get_current_stack`](@ref HDF5.h5e_get_current_stack)
- [`h5e_set_auto`](@ref HDF5.h5e_set_auto)
```@docs
h5e_get_auto
h5e_get_current_stack
h5e_set_auto
```

---

## [`H5F`](https://portal.hdfgroup.org/display/HDF5/Files) — File Interface
- [`h5f_close`](@ref HDF5.h5f_close)
- [`h5f_create`](@ref HDF5.h5f_create)
- [`h5f_flush`](@ref HDF5.h5f_flush)
- [`h5f_get_access_plist`](@ref HDF5.h5f_get_access_plist)
- [`h5f_get_create_plist`](@ref HDF5.h5f_get_create_plist)
- [`h5f_get_intent`](@ref HDF5.h5f_get_intent)
- [`h5f_get_name`](@ref HDF5.h5f_get_name)
- [`h5f_get_obj_count`](@ref HDF5.h5f_get_obj_count)
- [`h5f_get_obj_ids`](@ref HDF5.h5f_get_obj_ids)
- [`h5f_get_vfd_handle`](@ref HDF5.h5f_get_vfd_handle)
- [`h5f_is_hdf5`](@ref HDF5.h5f_is_hdf5)
- [`h5f_open`](@ref HDF5.h5f_open)
- [`h5f_start_swmr_write`](@ref HDF5.h5f_start_swmr_write)
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
- [`h5g_close`](@ref HDF5.h5g_close)
- [`h5g_create`](@ref HDF5.h5g_create)
- [`h5g_get_create_plist`](@ref HDF5.h5g_get_create_plist)
- [`h5g_get_info`](@ref HDF5.h5g_get_info)
- [`h5g_get_num_objs`](@ref HDF5.h5g_get_num_objs)
- [`h5g_get_objname_by_idx`](@ref HDF5.h5g_get_objname_by_idx)
- [`h5g_open`](@ref HDF5.h5g_open)
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
- [`h5i_dec_ref`](@ref HDF5.h5i_dec_ref)
- [`h5i_get_file_id`](@ref HDF5.h5i_get_file_id)
- [`h5i_get_name`](@ref HDF5.h5i_get_name)
- [`h5i_get_ref`](@ref HDF5.h5i_get_ref)
- [`h5i_get_type`](@ref HDF5.h5i_get_type)
- [`h5i_inc_ref`](@ref HDF5.h5i_inc_ref)
- [`h5i_is_valid`](@ref HDF5.h5i_is_valid)
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
- [`h5l_create_external`](@ref HDF5.h5l_create_external)
- [`h5l_create_hard`](@ref HDF5.h5l_create_hard)
- [`h5l_create_soft`](@ref HDF5.h5l_create_soft)
- [`h5l_delete`](@ref HDF5.h5l_delete)
- [`h5l_exists`](@ref HDF5.h5l_exists)
- [`h5l_get_info`](@ref HDF5.h5l_get_info)
- [`h5l_get_name_by_idx`](@ref HDF5.h5l_get_name_by_idx)
- [`h5l_iterate`](@ref HDF5.h5l_iterate)
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
- [`h5o_close`](@ref HDF5.h5o_close)
- [`h5o_copy`](@ref HDF5.h5o_copy)
- [`h5o_get_info`](@ref HDF5.h5o_get_info)
- [`h5o_open`](@ref HDF5.h5o_open)
- [`h5o_open_by_addr`](@ref HDF5.h5o_open_by_addr)
- [`h5o_open_by_idx`](@ref HDF5.h5o_open_by_idx)
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
- [`h5p_close`](@ref HDF5.h5p_close)
- [`h5p_create`](@ref HDF5.h5p_create)
- [`h5p_get_alignment`](@ref HDF5.h5p_get_alignment)
- [`h5p_get_alloc_time`](@ref HDF5.h5p_get_alloc_time)
- [`h5p_get_char_encoding`](@ref HDF5.h5p_get_char_encoding)
- [`h5p_get_chunk`](@ref HDF5.h5p_get_chunk)
- [`h5p_get_class_name`](@ref HDF5.h5p_get_class_name)
- [`h5p_get_create_intermediate_group`](@ref HDF5.h5p_get_create_intermediate_group)
- [`h5p_get_driver`](@ref HDF5.h5p_get_driver)
- [`h5p_get_driver_info`](@ref HDF5.h5p_get_driver_info)
- [`h5p_get_dxpl_mpio`](@ref HDF5.h5p_get_dxpl_mpio)
- [`h5p_get_fapl_mpio32`](@ref HDF5.h5p_get_fapl_mpio32)
- [`h5p_get_fapl_mpio64`](@ref HDF5.h5p_get_fapl_mpio64)
- [`h5p_get_fclose_degree`](@ref HDF5.h5p_get_fclose_degree)
- [`h5p_get_filter_by_id`](@ref HDF5.h5p_get_filter_by_id)
- [`h5p_get_layout`](@ref HDF5.h5p_get_layout)
- [`h5p_get_libver_bounds`](@ref HDF5.h5p_get_libver_bounds)
- [`h5p_get_local_heap_size_hint`](@ref HDF5.h5p_get_local_heap_size_hint)
- [`h5p_get_obj_track_times`](@ref HDF5.h5p_get_obj_track_times)
- [`h5p_get_userblock`](@ref HDF5.h5p_get_userblock)
- [`h5p_modify_filter`](@ref HDF5.h5p_modify_filter)
- [`h5p_set_alignment`](@ref HDF5.h5p_set_alignment)
- [`h5p_set_alloc_time`](@ref HDF5.h5p_set_alloc_time)
- [`h5p_set_char_encoding`](@ref HDF5.h5p_set_char_encoding)
- [`h5p_set_chunk`](@ref HDF5.h5p_set_chunk)
- [`h5p_set_chunk_cache`](@ref HDF5.h5p_set_chunk_cache)
- [`h5p_set_create_intermediate_group`](@ref HDF5.h5p_set_create_intermediate_group)
- [`h5p_set_deflate`](@ref HDF5.h5p_set_deflate)
- [`h5p_set_dxpl_mpio`](@ref HDF5.h5p_set_dxpl_mpio)
- [`h5p_set_external`](@ref HDF5.h5p_set_external)
- [`h5p_set_fapl_mpio32`](@ref HDF5.h5p_set_fapl_mpio32)
- [`h5p_set_fapl_mpio64`](@ref HDF5.h5p_set_fapl_mpio64)
- [`h5p_set_fclose_degree`](@ref HDF5.h5p_set_fclose_degree)
- [`h5p_set_filter`](@ref HDF5.h5p_set_filter)
- [`h5p_set_layout`](@ref HDF5.h5p_set_layout)
- [`h5p_set_libver_bounds`](@ref HDF5.h5p_set_libver_bounds)
- [`h5p_set_local_heap_size_hint`](@ref HDF5.h5p_set_local_heap_size_hint)
- [`h5p_set_obj_track_times`](@ref HDF5.h5p_set_obj_track_times)
- [`h5p_set_shuffle`](@ref HDF5.h5p_set_shuffle)
- [`h5p_set_userblock`](@ref HDF5.h5p_set_userblock)
- [`h5p_set_virtual`](@ref HDF5.h5p_set_virtual)
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
h5p_get_filter_by_id
h5p_get_layout
h5p_get_libver_bounds
h5p_get_local_heap_size_hint
h5p_get_obj_track_times
h5p_get_userblock
h5p_modify_filter
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
h5p_set_fclose_degree
h5p_set_filter
h5p_set_layout
h5p_set_libver_bounds
h5p_set_local_heap_size_hint
h5p_set_obj_track_times
h5p_set_shuffle
h5p_set_userblock
h5p_set_virtual
```

---

## [`H5R`](https://portal.hdfgroup.org/display/HDF5/References) — Reference Interface
- [`h5r_create`](@ref HDF5.h5r_create)
- [`h5r_dereference`](@ref HDF5.h5r_dereference)
- [`h5r_get_obj_type`](@ref HDF5.h5r_get_obj_type)
- [`h5r_get_region`](@ref HDF5.h5r_get_region)
```@docs
h5r_create
h5r_dereference
h5r_get_obj_type
h5r_get_region
```

---

## [`H5S`](https://portal.hdfgroup.org/display/HDF5/Dataspaces) — Dataspace Interface
- [`h5s_close`](@ref HDF5.h5s_close)
- [`h5s_combine_select`](@ref HDF5.h5s_combine_select)
- [`h5s_copy`](@ref HDF5.h5s_copy)
- [`h5s_create`](@ref HDF5.h5s_create)
- [`h5s_create_simple`](@ref HDF5.h5s_create_simple)
- [`h5s_extent_equal`](@ref HDF5.h5s_extent_equal)
- [`h5s_get_regular_hyperslab`](@ref HDF5.h5s_get_regular_hyperslab)
- [`h5s_get_select_hyper_nblocks`](@ref HDF5.h5s_get_select_hyper_nblocks)
- [`h5s_get_select_npoints`](@ref HDF5.h5s_get_select_npoints)
- [`h5s_get_select_type`](@ref HDF5.h5s_get_select_type)
- [`h5s_get_simple_extent_dims`](@ref HDF5.h5s_get_simple_extent_dims)
- [`h5s_get_simple_extent_ndims`](@ref HDF5.h5s_get_simple_extent_ndims)
- [`h5s_get_simple_extent_type`](@ref HDF5.h5s_get_simple_extent_type)
- [`h5s_is_regular_hyperslab`](@ref HDF5.h5s_is_regular_hyperslab)
- [`h5s_is_simple`](@ref HDF5.h5s_is_simple)
- [`h5s_select_hyperslab`](@ref HDF5.h5s_select_hyperslab)
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
```

---

## [`H5T`](https://portal.hdfgroup.org/display/HDF5/Datatypes) — Datatype Interface
- [`h5t_array_create`](@ref HDF5.h5t_array_create)
- [`h5t_close`](@ref HDF5.h5t_close)
- [`h5t_commit`](@ref HDF5.h5t_commit)
- [`h5t_committed`](@ref HDF5.h5t_committed)
- [`h5t_copy`](@ref HDF5.h5t_copy)
- [`h5t_create`](@ref HDF5.h5t_create)
- [`h5t_enum_insert`](@ref HDF5.h5t_enum_insert)
- [`h5t_equal`](@ref HDF5.h5t_equal)
- [`h5t_get_array_dims`](@ref HDF5.h5t_get_array_dims)
- [`h5t_get_array_ndims`](@ref HDF5.h5t_get_array_ndims)
- [`h5t_get_class`](@ref HDF5.h5t_get_class)
- [`h5t_get_cset`](@ref HDF5.h5t_get_cset)
- [`h5t_get_ebias`](@ref HDF5.h5t_get_ebias)
- [`h5t_get_fields`](@ref HDF5.h5t_get_fields)
- [`h5t_get_member_class`](@ref HDF5.h5t_get_member_class)
- [`h5t_get_member_index`](@ref HDF5.h5t_get_member_index)
- [`h5t_get_member_name`](@ref HDF5.h5t_get_member_name)
- [`h5t_get_member_offset`](@ref HDF5.h5t_get_member_offset)
- [`h5t_get_member_type`](@ref HDF5.h5t_get_member_type)
- [`h5t_get_native_type`](@ref HDF5.h5t_get_native_type)
- [`h5t_get_nmembers`](@ref HDF5.h5t_get_nmembers)
- [`h5t_get_sign`](@ref HDF5.h5t_get_sign)
- [`h5t_get_size`](@ref HDF5.h5t_get_size)
- [`h5t_get_strpad`](@ref HDF5.h5t_get_strpad)
- [`h5t_get_super`](@ref HDF5.h5t_get_super)
- [`h5t_get_tag`](@ref HDF5.h5t_get_tag)
- [`h5t_insert`](@ref HDF5.h5t_insert)
- [`h5t_is_variable_str`](@ref HDF5.h5t_is_variable_str)
- [`h5t_lock`](@ref HDF5.h5t_lock)
- [`h5t_open`](@ref HDF5.h5t_open)
- [`h5t_set_cset`](@ref HDF5.h5t_set_cset)
- [`h5t_set_ebias`](@ref HDF5.h5t_set_ebias)
- [`h5t_set_fields`](@ref HDF5.h5t_set_fields)
- [`h5t_set_precision`](@ref HDF5.h5t_set_precision)
- [`h5t_set_size`](@ref HDF5.h5t_set_size)
- [`h5t_set_strpad`](@ref HDF5.h5t_set_strpad)
- [`h5t_set_tag`](@ref HDF5.h5t_set_tag)
- [`h5t_vlen_create`](@ref HDF5.h5t_vlen_create)
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
- [`h5z_register`](@ref HDF5.h5z_register)
```@docs
h5z_register
```

---

## [`H5DO`](https://portal.hdfgroup.org/display/HDF5/Optimizations) — Optimized Functions Interface
- [`h5do_append`](@ref HDF5.h5do_append)
- [`h5do_write_chunk`](@ref HDF5.h5do_write_chunk)
```@docs
h5do_append
h5do_write_chunk
```

---

## [`H5DS`](https://portal.hdfgroup.org/display/HDF5/Dimension+Scales) — Dimension Scale Interface
- [`h5ds_attach_scale`](@ref HDF5.h5ds_attach_scale)
- [`h5ds_detach_scale`](@ref HDF5.h5ds_detach_scale)
- [`h5ds_get_label`](@ref HDF5.h5ds_get_label)
- [`h5ds_get_num_scales`](@ref HDF5.h5ds_get_num_scales)
- [`h5ds_get_scale_name`](@ref HDF5.h5ds_get_scale_name)
- [`h5ds_is_attached`](@ref HDF5.h5ds_is_attached)
- [`h5ds_is_scale`](@ref HDF5.h5ds_is_scale)
- [`h5ds_set_label`](@ref HDF5.h5ds_set_label)
- [`h5ds_set_scale`](@ref HDF5.h5ds_set_scale)
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
- [`h5lt_dtype_to_text`](@ref HDF5.h5lt_dtype_to_text)
```@docs
h5lt_dtype_to_text
```

---

## [`H5TB`](https://portal.hdfgroup.org/display/HDF5/Tables) — Table Interface
- [`h5tb_append_records`](@ref HDF5.h5tb_append_records)
- [`h5tb_get_field_info`](@ref HDF5.h5tb_get_field_info)
- [`h5tb_get_table_info`](@ref HDF5.h5tb_get_table_info)
- [`h5tb_make_table`](@ref HDF5.h5tb_make_table)
- [`h5tb_read_records`](@ref HDF5.h5tb_read_records)
- [`h5tb_read_table`](@ref HDF5.h5tb_read_table)
- [`h5tb_write_records`](@ref HDF5.h5tb_write_records)
```@docs
h5tb_append_records
h5tb_get_field_info
h5tb_get_table_info
h5tb_make_table
h5tb_read_records
h5tb_read_table
h5tb_write_records
```


