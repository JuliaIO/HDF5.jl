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

## [[`H5`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5.html) — General Library Functions](@id H5)
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

## [[`H5A`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_a.html) — Attribute Interface](@id H5A)
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
- [`h5a_open_by_idx`](@ref h5a_open_by_idx)
- [`h5a_read`](@ref h5a_read)
- [`h5a_rename`](@ref h5a_rename)
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
h5a_open_by_idx
h5a_read
h5a_rename
h5a_write
```

---

## [[`H5D`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_d.html) — Dataset Interface](@id H5D)
- [`h5d_chunk_iter`](@ref h5d_chunk_iter)
- [`h5d_close`](@ref h5d_close)
- [`h5d_create`](@ref h5d_create)
- [`h5d_create_anon`](@ref h5d_create_anon)
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
h5d_chunk_iter
h5d_close
h5d_create
h5d_create_anon
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

## [[`H5E`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_e.html) — Error Interface](@id H5E)
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

## [[`H5F`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_f.html) — File Interface](@id H5F)
- [`h5f_clear_elink_file_cache`](@ref h5f_clear_elink_file_cache)
- [`h5f_close`](@ref h5f_close)
- [`h5f_create`](@ref h5f_create)
- [`h5f_delete`](@ref h5f_delete)
- [`h5f_flush`](@ref h5f_flush)
- [`h5f_format_convert`](@ref h5f_format_convert)
- [`h5f_get_access_plist`](@ref h5f_get_access_plist)
- [`h5f_get_create_plist`](@ref h5f_get_create_plist)
- [`h5f_get_dset_no_attrs_hint`](@ref h5f_get_dset_no_attrs_hint)
- [`h5f_get_eoa`](@ref h5f_get_eoa)
- [`h5f_get_file_image`](@ref h5f_get_file_image)
- [`h5f_get_fileno`](@ref h5f_get_fileno)
- [`h5f_get_filesize`](@ref h5f_get_filesize)
- [`h5f_get_free_sections`](@ref h5f_get_free_sections)
- [`h5f_get_freespace`](@ref h5f_get_freespace)
- [`h5f_get_info`](@ref h5f_get_info)
- [`h5f_get_intent`](@ref h5f_get_intent)
- [`h5f_get_mdc_config`](@ref h5f_get_mdc_config)
- [`h5f_get_mdc_hit_rate`](@ref h5f_get_mdc_hit_rate)
- [`h5f_get_mdc_image_info`](@ref h5f_get_mdc_image_info)
- [`h5f_get_mdc_logging_status`](@ref h5f_get_mdc_logging_status)
- [`h5f_get_mdc_size`](@ref h5f_get_mdc_size)
- [`h5f_get_metadata_read_retry_info`](@ref h5f_get_metadata_read_retry_info)
- [`h5f_get_mpi_atomicity`](@ref h5f_get_mpi_atomicity)
- [`h5f_get_name`](@ref h5f_get_name)
- [`h5f_get_obj_count`](@ref h5f_get_obj_count)
- [`h5f_get_obj_ids`](@ref h5f_get_obj_ids)
- [`h5f_get_page_buffering_stats`](@ref h5f_get_page_buffering_stats)
- [`h5f_get_vfd_handle`](@ref h5f_get_vfd_handle)
- [`h5f_increment_filesize`](@ref h5f_increment_filesize)
- [`h5f_is_accessible`](@ref h5f_is_accessible)
- [`h5f_is_hdf5`](@ref h5f_is_hdf5)
- [`h5f_mount`](@ref h5f_mount)
- [`h5f_open`](@ref h5f_open)
- [`h5f_reopen`](@ref h5f_reopen)
- [`h5f_reset_mdc_hit_rate_stats`](@ref h5f_reset_mdc_hit_rate_stats)
- [`h5f_reset_page_buffering_stats`](@ref h5f_reset_page_buffering_stats)
- [`h5f_set_dset_no_attrs_hint`](@ref h5f_set_dset_no_attrs_hint)
- [`h5f_set_libver_bounds`](@ref h5f_set_libver_bounds)
- [`h5f_set_mdc_config`](@ref h5f_set_mdc_config)
- [`h5f_set_mpi_atomicity`](@ref h5f_set_mpi_atomicity)
- [`h5f_start_mdc_logging`](@ref h5f_start_mdc_logging)
- [`h5f_start_swmr_write`](@ref h5f_start_swmr_write)
- [`h5f_stop_mdc_logging`](@ref h5f_stop_mdc_logging)
- [`h5f_unmount`](@ref h5f_unmount)
```@docs
h5f_clear_elink_file_cache
h5f_close
h5f_create
h5f_delete
h5f_flush
h5f_format_convert
h5f_get_access_plist
h5f_get_create_plist
h5f_get_dset_no_attrs_hint
h5f_get_eoa
h5f_get_file_image
h5f_get_fileno
h5f_get_filesize
h5f_get_free_sections
h5f_get_freespace
h5f_get_info
h5f_get_intent
h5f_get_mdc_config
h5f_get_mdc_hit_rate
h5f_get_mdc_image_info
h5f_get_mdc_logging_status
h5f_get_mdc_size
h5f_get_metadata_read_retry_info
h5f_get_mpi_atomicity
h5f_get_name
h5f_get_obj_count
h5f_get_obj_ids
h5f_get_page_buffering_stats
h5f_get_vfd_handle
h5f_increment_filesize
h5f_is_accessible
h5f_is_hdf5
h5f_mount
h5f_open
h5f_reopen
h5f_reset_mdc_hit_rate_stats
h5f_reset_page_buffering_stats
h5f_set_dset_no_attrs_hint
h5f_set_libver_bounds
h5f_set_mdc_config
h5f_set_mpi_atomicity
h5f_start_mdc_logging
h5f_start_swmr_write
h5f_stop_mdc_logging
h5f_unmount
```

---

## [[`H5G`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_g.html) — Group Interface](@id H5G)
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

## [[`H5I`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_i.html) — Identifier Interface](@id H5I)
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

## [[`H5L`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_l.html) — Link Interface](@id H5L)
- [`h5l_create_external`](@ref h5l_create_external)
- [`h5l_create_hard`](@ref h5l_create_hard)
- [`h5l_create_soft`](@ref h5l_create_soft)
- [`h5l_delete`](@ref h5l_delete)
- [`h5l_exists`](@ref h5l_exists)
- [`h5l_get_info`](@ref h5l_get_info)
- [`h5l_get_name_by_idx`](@ref h5l_get_name_by_idx)
- [`h5l_iterate`](@ref h5l_iterate)
- [`h5l_move`](@ref h5l_move)
```@docs
h5l_create_external
h5l_create_hard
h5l_create_soft
h5l_delete
h5l_exists
h5l_get_info
h5l_get_name_by_idx
h5l_iterate
h5l_move
```

---

## [[`H5O`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_o.html) — Object Interface](@id H5O)
- [`h5o_are_mdc_flushes_disabled`](@ref h5o_are_mdc_flushes_disabled)
- [`h5o_close`](@ref h5o_close)
- [`h5o_copy`](@ref h5o_copy)
- [`h5o_decr_refcount`](@ref h5o_decr_refcount)
- [`h5o_disable_mdc_flushes`](@ref h5o_disable_mdc_flushes)
- [`h5o_enable_mdc_flushes`](@ref h5o_enable_mdc_flushes)
- [`h5o_exists_by_name`](@ref h5o_exists_by_name)
- [`h5o_flush`](@ref h5o_flush)
- [`h5o_get_comment`](@ref h5o_get_comment)
- [`h5o_get_comment_by_name`](@ref h5o_get_comment_by_name)
- [`h5o_get_info`](@ref h5o_get_info)
- [`h5o_get_info1`](@ref h5o_get_info1)
- [`h5o_get_info_by_idx`](@ref h5o_get_info_by_idx)
- [`h5o_get_info_by_name`](@ref h5o_get_info_by_name)
- [`h5o_get_native_info`](@ref h5o_get_native_info)
- [`h5o_get_native_info_by_idx`](@ref h5o_get_native_info_by_idx)
- [`h5o_get_native_info_by_name`](@ref h5o_get_native_info_by_name)
- [`h5o_incr_refcount`](@ref h5o_incr_refcount)
- [`h5o_link`](@ref h5o_link)
- [`h5o_open`](@ref h5o_open)
- [`h5o_open_by_addr`](@ref h5o_open_by_addr)
- [`h5o_open_by_idx`](@ref h5o_open_by_idx)
- [`h5o_refresh`](@ref h5o_refresh)
- [`h5o_set_comment`](@ref h5o_set_comment)
- [`h5o_set_comment_by_name`](@ref h5o_set_comment_by_name)
- [`h5o_token_cmp`](@ref h5o_token_cmp)
- [`h5o_token_from_str`](@ref h5o_token_from_str)
- [`h5o_token_to_str`](@ref h5o_token_to_str)
- [`h5o_visit`](@ref h5o_visit)
- [`h5o_visit_by_name`](@ref h5o_visit_by_name)
```@docs
h5o_are_mdc_flushes_disabled
h5o_close
h5o_copy
h5o_decr_refcount
h5o_disable_mdc_flushes
h5o_enable_mdc_flushes
h5o_exists_by_name
h5o_flush
h5o_get_comment
h5o_get_comment_by_name
h5o_get_info
h5o_get_info1
h5o_get_info_by_idx
h5o_get_info_by_name
h5o_get_native_info
h5o_get_native_info_by_idx
h5o_get_native_info_by_name
h5o_incr_refcount
h5o_link
h5o_open
h5o_open_by_addr
h5o_open_by_idx
h5o_refresh
h5o_set_comment
h5o_set_comment_by_name
h5o_token_cmp
h5o_token_from_str
h5o_token_to_str
h5o_visit
h5o_visit_by_name
```

---

## [[`H5PL`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_p_l.html) — Plugin Interface](@id H5PL)
- [`h5pl_append`](@ref h5pl_append)
- [`h5pl_get`](@ref h5pl_get)
- [`h5pl_get_loading_state`](@ref h5pl_get_loading_state)
- [`h5pl_insert`](@ref h5pl_insert)
- [`h5pl_prepend`](@ref h5pl_prepend)
- [`h5pl_remove`](@ref h5pl_remove)
- [`h5pl_replace`](@ref h5pl_replace)
- [`h5pl_set_loading_state`](@ref h5pl_set_loading_state)
- [`h5pl_size`](@ref h5pl_size)
```@docs
h5pl_append
h5pl_get
h5pl_get_loading_state
h5pl_insert
h5pl_prepend
h5pl_remove
h5pl_replace
h5pl_set_loading_state
h5pl_size
```

---

## [[`H5P`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_p.html) — Property Interface](@id H5P)
- [`h5p_add_merge_committed_dtype_path`](@ref h5p_add_merge_committed_dtype_path)
- [`h5p_all_filters_avail`](@ref h5p_all_filters_avail)
- [`h5p_close`](@ref h5p_close)
- [`h5p_close_class`](@ref h5p_close_class)
- [`h5p_copy`](@ref h5p_copy)
- [`h5p_copy_prop`](@ref h5p_copy_prop)
- [`h5p_create`](@ref h5p_create)
- [`h5p_create_class`](@ref h5p_create_class)
- [`h5p_decode`](@ref h5p_decode)
- [`h5p_encode`](@ref h5p_encode)
- [`h5p_equal`](@ref h5p_equal)
- [`h5p_exist`](@ref h5p_exist)
- [`h5p_fill_value_defined`](@ref h5p_fill_value_defined)
- [`h5p_free_merge_committed_dtype_paths`](@ref h5p_free_merge_committed_dtype_paths)
- [`h5p_get`](@ref h5p_get)
- [`h5p_get_alignment`](@ref h5p_get_alignment)
- [`h5p_get_alloc_time`](@ref h5p_get_alloc_time)
- [`h5p_get_append_flush`](@ref h5p_get_append_flush)
- [`h5p_get_attr_creation_order`](@ref h5p_get_attr_creation_order)
- [`h5p_get_attr_phase_change`](@ref h5p_get_attr_phase_change)
- [`h5p_get_btree_ratios`](@ref h5p_get_btree_ratios)
- [`h5p_get_buffer`](@ref h5p_get_buffer)
- [`h5p_get_cache`](@ref h5p_get_cache)
- [`h5p_get_char_encoding`](@ref h5p_get_char_encoding)
- [`h5p_get_chunk`](@ref h5p_get_chunk)
- [`h5p_get_chunk_cache`](@ref h5p_get_chunk_cache)
- [`h5p_get_chunk_opts`](@ref h5p_get_chunk_opts)
- [`h5p_get_class`](@ref h5p_get_class)
- [`h5p_get_class_name`](@ref h5p_get_class_name)
- [`h5p_get_class_parent`](@ref h5p_get_class_parent)
- [`h5p_get_copy_object`](@ref h5p_get_copy_object)
- [`h5p_get_core_write_tracking`](@ref h5p_get_core_write_tracking)
- [`h5p_get_create_intermediate_group`](@ref h5p_get_create_intermediate_group)
- [`h5p_get_data_transform`](@ref h5p_get_data_transform)
- [`h5p_get_driver`](@ref h5p_get_driver)
- [`h5p_get_driver_info`](@ref h5p_get_driver_info)
- [`h5p_get_dset_no_attrs_hint`](@ref h5p_get_dset_no_attrs_hint)
- [`h5p_get_dxpl_mpio`](@ref h5p_get_dxpl_mpio)
- [`h5p_get_edc_check`](@ref h5p_get_edc_check)
- [`h5p_get_efile_prefix`](@ref h5p_get_efile_prefix)
- [`h5p_get_elink_acc_flags`](@ref h5p_get_elink_acc_flags)
- [`h5p_get_elink_cb`](@ref h5p_get_elink_cb)
- [`h5p_get_elink_fapl`](@ref h5p_get_elink_fapl)
- [`h5p_get_elink_file_cache_size`](@ref h5p_get_elink_file_cache_size)
- [`h5p_get_elink_prefix`](@ref h5p_get_elink_prefix)
- [`h5p_get_est_link_info`](@ref h5p_get_est_link_info)
- [`h5p_get_evict_on_close`](@ref h5p_get_evict_on_close)
- [`h5p_get_external`](@ref h5p_get_external)
- [`h5p_get_external_count`](@ref h5p_get_external_count)
- [`h5p_get_family_offset`](@ref h5p_get_family_offset)
- [`h5p_get_fapl_core`](@ref h5p_get_fapl_core)
- [`h5p_get_fapl_family`](@ref h5p_get_fapl_family)
- [`h5p_get_fapl_hdfs`](@ref h5p_get_fapl_hdfs)
- [`h5p_get_fapl_mpio`](@ref h5p_get_fapl_mpio)
- [`h5p_get_fapl_multi`](@ref h5p_get_fapl_multi)
- [`h5p_get_fapl_ros3`](@ref h5p_get_fapl_ros3)
- [`h5p_get_fapl_splitter`](@ref h5p_get_fapl_splitter)
- [`h5p_get_fclose_degree`](@ref h5p_get_fclose_degree)
- [`h5p_get_file_image`](@ref h5p_get_file_image)
- [`h5p_get_file_image_callbacks`](@ref h5p_get_file_image_callbacks)
- [`h5p_get_file_locking`](@ref h5p_get_file_locking)
- [`h5p_get_file_space`](@ref h5p_get_file_space)
- [`h5p_get_file_space_page_size`](@ref h5p_get_file_space_page_size)
- [`h5p_get_file_space_strategy`](@ref h5p_get_file_space_strategy)
- [`h5p_get_fill_time`](@ref h5p_get_fill_time)
- [`h5p_get_fill_value`](@ref h5p_get_fill_value)
- [`h5p_get_filter`](@ref h5p_get_filter)
- [`h5p_get_filter_by_id`](@ref h5p_get_filter_by_id)
- [`h5p_get_gc_references`](@ref h5p_get_gc_references)
- [`h5p_get_hyper_vector_size`](@ref h5p_get_hyper_vector_size)
- [`h5p_get_istore_k`](@ref h5p_get_istore_k)
- [`h5p_get_layout`](@ref h5p_get_layout)
- [`h5p_get_libver_bounds`](@ref h5p_get_libver_bounds)
- [`h5p_get_link_creation_order`](@ref h5p_get_link_creation_order)
- [`h5p_get_link_phase_change`](@ref h5p_get_link_phase_change)
- [`h5p_get_local_heap_size_hint`](@ref h5p_get_local_heap_size_hint)
- [`h5p_get_mcdt_search_cb`](@ref h5p_get_mcdt_search_cb)
- [`h5p_get_mdc_config`](@ref h5p_get_mdc_config)
- [`h5p_get_mdc_image_config`](@ref h5p_get_mdc_image_config)
- [`h5p_get_mdc_log_options`](@ref h5p_get_mdc_log_options)
- [`h5p_get_meta_block_size`](@ref h5p_get_meta_block_size)
- [`h5p_get_metadata_read_attempts`](@ref h5p_get_metadata_read_attempts)
- [`h5p_get_multi_type`](@ref h5p_get_multi_type)
- [`h5p_get_nfilters`](@ref h5p_get_nfilters)
- [`h5p_get_nlinks`](@ref h5p_get_nlinks)
- [`h5p_get_nprops`](@ref h5p_get_nprops)
- [`h5p_get_obj_track_times`](@ref h5p_get_obj_track_times)
- [`h5p_get_object_flush_cb`](@ref h5p_get_object_flush_cb)
- [`h5p_get_page_buffer_size`](@ref h5p_get_page_buffer_size)
- [`h5p_get_preserve`](@ref h5p_get_preserve)
- [`h5p_get_shared_mesg_index`](@ref h5p_get_shared_mesg_index)
- [`h5p_get_shared_mesg_nindexes`](@ref h5p_get_shared_mesg_nindexes)
- [`h5p_get_shared_mesg_phase_change`](@ref h5p_get_shared_mesg_phase_change)
- [`h5p_get_sieve_buf_size`](@ref h5p_get_sieve_buf_size)
- [`h5p_get_size`](@ref h5p_get_size)
- [`h5p_get_sizes`](@ref h5p_get_sizes)
- [`h5p_get_small_data_block_size`](@ref h5p_get_small_data_block_size)
- [`h5p_get_sym_k`](@ref h5p_get_sym_k)
- [`h5p_get_type_conv_cb`](@ref h5p_get_type_conv_cb)
- [`h5p_get_userblock`](@ref h5p_get_userblock)
- [`h5p_get_version`](@ref h5p_get_version)
- [`h5p_get_virtual_count`](@ref h5p_get_virtual_count)
- [`h5p_get_virtual_dsetname`](@ref h5p_get_virtual_dsetname)
- [`h5p_get_virtual_filename`](@ref h5p_get_virtual_filename)
- [`h5p_get_virtual_prefix`](@ref h5p_get_virtual_prefix)
- [`h5p_get_virtual_printf_gap`](@ref h5p_get_virtual_printf_gap)
- [`h5p_get_virtual_srcspace`](@ref h5p_get_virtual_srcspace)
- [`h5p_get_virtual_view`](@ref h5p_get_virtual_view)
- [`h5p_get_virtual_vspace`](@ref h5p_get_virtual_vspace)
- [`h5p_get_vlen_mem_manager`](@ref h5p_get_vlen_mem_manager)
- [`h5p_get_vol_id`](@ref h5p_get_vol_id)
- [`h5p_get_vol_info`](@ref h5p_get_vol_info)
- [`h5p_insert`](@ref h5p_insert)
- [`h5p_isa_class`](@ref h5p_isa_class)
- [`h5p_iterate`](@ref h5p_iterate)
- [`h5p_modify_filter`](@ref h5p_modify_filter)
- [`h5p_register`](@ref h5p_register)
- [`h5p_remove`](@ref h5p_remove)
- [`h5p_remove_filter`](@ref h5p_remove_filter)
- [`h5p_set`](@ref h5p_set)
- [`h5p_set_alignment`](@ref h5p_set_alignment)
- [`h5p_set_alloc_time`](@ref h5p_set_alloc_time)
- [`h5p_set_append_flush`](@ref h5p_set_append_flush)
- [`h5p_set_attr_creation_order`](@ref h5p_set_attr_creation_order)
- [`h5p_set_attr_phase_change`](@ref h5p_set_attr_phase_change)
- [`h5p_set_btree_ratios`](@ref h5p_set_btree_ratios)
- [`h5p_set_buffer`](@ref h5p_set_buffer)
- [`h5p_set_cache`](@ref h5p_set_cache)
- [`h5p_set_char_encoding`](@ref h5p_set_char_encoding)
- [`h5p_set_chunk`](@ref h5p_set_chunk)
- [`h5p_set_chunk_cache`](@ref h5p_set_chunk_cache)
- [`h5p_set_chunk_opts`](@ref h5p_set_chunk_opts)
- [`h5p_set_copy_object`](@ref h5p_set_copy_object)
- [`h5p_set_core_write_tracking`](@ref h5p_set_core_write_tracking)
- [`h5p_set_create_intermediate_group`](@ref h5p_set_create_intermediate_group)
- [`h5p_set_data_transform`](@ref h5p_set_data_transform)
- [`h5p_set_deflate`](@ref h5p_set_deflate)
- [`h5p_set_driver`](@ref h5p_set_driver)
- [`h5p_set_dset_no_attrs_hint`](@ref h5p_set_dset_no_attrs_hint)
- [`h5p_set_dxpl_mpio`](@ref h5p_set_dxpl_mpio)
- [`h5p_set_edc_check`](@ref h5p_set_edc_check)
- [`h5p_set_efile_prefix`](@ref h5p_set_efile_prefix)
- [`h5p_set_elink_acc_flags`](@ref h5p_set_elink_acc_flags)
- [`h5p_set_elink_cb`](@ref h5p_set_elink_cb)
- [`h5p_set_elink_fapl`](@ref h5p_set_elink_fapl)
- [`h5p_set_elink_file_cache_size`](@ref h5p_set_elink_file_cache_size)
- [`h5p_set_elink_prefix`](@ref h5p_set_elink_prefix)
- [`h5p_set_est_link_info`](@ref h5p_set_est_link_info)
- [`h5p_set_evict_on_close`](@ref h5p_set_evict_on_close)
- [`h5p_set_external`](@ref h5p_set_external)
- [`h5p_set_family_offset`](@ref h5p_set_family_offset)
- [`h5p_set_fapl_core`](@ref h5p_set_fapl_core)
- [`h5p_set_fapl_family`](@ref h5p_set_fapl_family)
- [`h5p_set_fapl_hdfs`](@ref h5p_set_fapl_hdfs)
- [`h5p_set_fapl_log`](@ref h5p_set_fapl_log)
- [`h5p_set_fapl_mpio`](@ref h5p_set_fapl_mpio)
- [`h5p_set_fapl_multi`](@ref h5p_set_fapl_multi)
- [`h5p_set_fapl_ros3`](@ref h5p_set_fapl_ros3)
- [`h5p_set_fapl_sec2`](@ref h5p_set_fapl_sec2)
- [`h5p_set_fapl_split`](@ref h5p_set_fapl_split)
- [`h5p_set_fapl_splitter`](@ref h5p_set_fapl_splitter)
- [`h5p_set_fapl_stdio`](@ref h5p_set_fapl_stdio)
- [`h5p_set_fapl_windows`](@ref h5p_set_fapl_windows)
- [`h5p_set_fclose_degree`](@ref h5p_set_fclose_degree)
- [`h5p_set_file_image`](@ref h5p_set_file_image)
- [`h5p_set_file_image_callbacks`](@ref h5p_set_file_image_callbacks)
- [`h5p_set_file_locking`](@ref h5p_set_file_locking)
- [`h5p_set_file_space`](@ref h5p_set_file_space)
- [`h5p_set_file_space_page_size`](@ref h5p_set_file_space_page_size)
- [`h5p_set_file_space_strategy`](@ref h5p_set_file_space_strategy)
- [`h5p_set_fill_time`](@ref h5p_set_fill_time)
- [`h5p_set_fill_value`](@ref h5p_set_fill_value)
- [`h5p_set_filter`](@ref h5p_set_filter)
- [`h5p_set_filter_callback`](@ref h5p_set_filter_callback)
- [`h5p_set_fletcher32`](@ref h5p_set_fletcher32)
- [`h5p_set_gc_references`](@ref h5p_set_gc_references)
- [`h5p_set_hyper_vector_size`](@ref h5p_set_hyper_vector_size)
- [`h5p_set_istore_k`](@ref h5p_set_istore_k)
- [`h5p_set_layout`](@ref h5p_set_layout)
- [`h5p_set_libver_bounds`](@ref h5p_set_libver_bounds)
- [`h5p_set_link_creation_order`](@ref h5p_set_link_creation_order)
- [`h5p_set_link_phase_change`](@ref h5p_set_link_phase_change)
- [`h5p_set_local_heap_size_hint`](@ref h5p_set_local_heap_size_hint)
- [`h5p_set_mcdt_search_cb`](@ref h5p_set_mcdt_search_cb)
- [`h5p_set_mdc_config`](@ref h5p_set_mdc_config)
- [`h5p_set_mdc_image_config`](@ref h5p_set_mdc_image_config)
- [`h5p_set_mdc_log_options`](@ref h5p_set_mdc_log_options)
- [`h5p_set_meta_block_size`](@ref h5p_set_meta_block_size)
- [`h5p_set_metadata_read_attempts`](@ref h5p_set_metadata_read_attempts)
- [`h5p_set_multi_type`](@ref h5p_set_multi_type)
- [`h5p_set_nbit`](@ref h5p_set_nbit)
- [`h5p_set_nlinks`](@ref h5p_set_nlinks)
- [`h5p_set_obj_track_times`](@ref h5p_set_obj_track_times)
- [`h5p_set_object_flush_cb`](@ref h5p_set_object_flush_cb)
- [`h5p_set_page_buffer_size`](@ref h5p_set_page_buffer_size)
- [`h5p_set_preserve`](@ref h5p_set_preserve)
- [`h5p_set_scaleoffset`](@ref h5p_set_scaleoffset)
- [`h5p_set_shared_mesg_index`](@ref h5p_set_shared_mesg_index)
- [`h5p_set_shared_mesg_nindexes`](@ref h5p_set_shared_mesg_nindexes)
- [`h5p_set_shared_mesg_phase_change`](@ref h5p_set_shared_mesg_phase_change)
- [`h5p_set_shuffle`](@ref h5p_set_shuffle)
- [`h5p_set_sieve_buf_size`](@ref h5p_set_sieve_buf_size)
- [`h5p_set_sizes`](@ref h5p_set_sizes)
- [`h5p_set_small_data_block_size`](@ref h5p_set_small_data_block_size)
- [`h5p_set_sym_k`](@ref h5p_set_sym_k)
- [`h5p_set_szip`](@ref h5p_set_szip)
- [`h5p_set_type_conv_cb`](@ref h5p_set_type_conv_cb)
- [`h5p_set_userblock`](@ref h5p_set_userblock)
- [`h5p_set_virtual`](@ref h5p_set_virtual)
- [`h5p_set_virtual_prefix`](@ref h5p_set_virtual_prefix)
- [`h5p_set_virtual_printf_gap`](@ref h5p_set_virtual_printf_gap)
- [`h5p_set_virtual_view`](@ref h5p_set_virtual_view)
- [`h5p_set_vlen_mem_manager`](@ref h5p_set_vlen_mem_manager)
- [`h5p_set_vol`](@ref h5p_set_vol)
- [`h5p_unregister`](@ref h5p_unregister)
```@docs
h5p_add_merge_committed_dtype_path
h5p_all_filters_avail
h5p_close
h5p_close_class
h5p_copy
h5p_copy_prop
h5p_create
h5p_create_class
h5p_decode
h5p_encode
h5p_equal
h5p_exist
h5p_fill_value_defined
h5p_free_merge_committed_dtype_paths
h5p_get
h5p_get_alignment
h5p_get_alloc_time
h5p_get_append_flush
h5p_get_attr_creation_order
h5p_get_attr_phase_change
h5p_get_btree_ratios
h5p_get_buffer
h5p_get_cache
h5p_get_char_encoding
h5p_get_chunk
h5p_get_chunk_cache
h5p_get_chunk_opts
h5p_get_class
h5p_get_class_name
h5p_get_class_parent
h5p_get_copy_object
h5p_get_core_write_tracking
h5p_get_create_intermediate_group
h5p_get_data_transform
h5p_get_driver
h5p_get_driver_info
h5p_get_dset_no_attrs_hint
h5p_get_dxpl_mpio
h5p_get_edc_check
h5p_get_efile_prefix
h5p_get_elink_acc_flags
h5p_get_elink_cb
h5p_get_elink_fapl
h5p_get_elink_file_cache_size
h5p_get_elink_prefix
h5p_get_est_link_info
h5p_get_evict_on_close
h5p_get_external
h5p_get_external_count
h5p_get_family_offset
h5p_get_fapl_core
h5p_get_fapl_family
h5p_get_fapl_hdfs
h5p_get_fapl_mpio
h5p_get_fapl_multi
h5p_get_fapl_ros3
h5p_get_fapl_splitter
h5p_get_fclose_degree
h5p_get_file_image
h5p_get_file_image_callbacks
h5p_get_file_locking
h5p_get_file_space
h5p_get_file_space_page_size
h5p_get_file_space_strategy
h5p_get_fill_time
h5p_get_fill_value
h5p_get_filter
h5p_get_filter_by_id
h5p_get_gc_references
h5p_get_hyper_vector_size
h5p_get_istore_k
h5p_get_layout
h5p_get_libver_bounds
h5p_get_link_creation_order
h5p_get_link_phase_change
h5p_get_local_heap_size_hint
h5p_get_mcdt_search_cb
h5p_get_mdc_config
h5p_get_mdc_image_config
h5p_get_mdc_log_options
h5p_get_meta_block_size
h5p_get_metadata_read_attempts
h5p_get_multi_type
h5p_get_nfilters
h5p_get_nlinks
h5p_get_nprops
h5p_get_obj_track_times
h5p_get_object_flush_cb
h5p_get_page_buffer_size
h5p_get_preserve
h5p_get_shared_mesg_index
h5p_get_shared_mesg_nindexes
h5p_get_shared_mesg_phase_change
h5p_get_sieve_buf_size
h5p_get_size
h5p_get_sizes
h5p_get_small_data_block_size
h5p_get_sym_k
h5p_get_type_conv_cb
h5p_get_userblock
h5p_get_version
h5p_get_virtual_count
h5p_get_virtual_dsetname
h5p_get_virtual_filename
h5p_get_virtual_prefix
h5p_get_virtual_printf_gap
h5p_get_virtual_srcspace
h5p_get_virtual_view
h5p_get_virtual_vspace
h5p_get_vlen_mem_manager
h5p_get_vol_id
h5p_get_vol_info
h5p_insert
h5p_isa_class
h5p_iterate
h5p_modify_filter
h5p_register
h5p_remove
h5p_remove_filter
h5p_set
h5p_set_alignment
h5p_set_alloc_time
h5p_set_append_flush
h5p_set_attr_creation_order
h5p_set_attr_phase_change
h5p_set_btree_ratios
h5p_set_buffer
h5p_set_cache
h5p_set_char_encoding
h5p_set_chunk
h5p_set_chunk_cache
h5p_set_chunk_opts
h5p_set_copy_object
h5p_set_core_write_tracking
h5p_set_create_intermediate_group
h5p_set_data_transform
h5p_set_deflate
h5p_set_driver
h5p_set_dset_no_attrs_hint
h5p_set_dxpl_mpio
h5p_set_edc_check
h5p_set_efile_prefix
h5p_set_elink_acc_flags
h5p_set_elink_cb
h5p_set_elink_fapl
h5p_set_elink_file_cache_size
h5p_set_elink_prefix
h5p_set_est_link_info
h5p_set_evict_on_close
h5p_set_external
h5p_set_family_offset
h5p_set_fapl_core
h5p_set_fapl_family
h5p_set_fapl_hdfs
h5p_set_fapl_log
h5p_set_fapl_mpio
h5p_set_fapl_multi
h5p_set_fapl_ros3
h5p_set_fapl_sec2
h5p_set_fapl_split
h5p_set_fapl_splitter
h5p_set_fapl_stdio
h5p_set_fapl_windows
h5p_set_fclose_degree
h5p_set_file_image
h5p_set_file_image_callbacks
h5p_set_file_locking
h5p_set_file_space
h5p_set_file_space_page_size
h5p_set_file_space_strategy
h5p_set_fill_time
h5p_set_fill_value
h5p_set_filter
h5p_set_filter_callback
h5p_set_fletcher32
h5p_set_gc_references
h5p_set_hyper_vector_size
h5p_set_istore_k
h5p_set_layout
h5p_set_libver_bounds
h5p_set_link_creation_order
h5p_set_link_phase_change
h5p_set_local_heap_size_hint
h5p_set_mcdt_search_cb
h5p_set_mdc_config
h5p_set_mdc_image_config
h5p_set_mdc_log_options
h5p_set_meta_block_size
h5p_set_metadata_read_attempts
h5p_set_multi_type
h5p_set_nbit
h5p_set_nlinks
h5p_set_obj_track_times
h5p_set_object_flush_cb
h5p_set_page_buffer_size
h5p_set_preserve
h5p_set_scaleoffset
h5p_set_shared_mesg_index
h5p_set_shared_mesg_nindexes
h5p_set_shared_mesg_phase_change
h5p_set_shuffle
h5p_set_sieve_buf_size
h5p_set_sizes
h5p_set_small_data_block_size
h5p_set_sym_k
h5p_set_szip
h5p_set_type_conv_cb
h5p_set_userblock
h5p_set_virtual
h5p_set_virtual_prefix
h5p_set_virtual_printf_gap
h5p_set_virtual_view
h5p_set_vlen_mem_manager
h5p_set_vol
h5p_unregister
```

---

## [[`H5R`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_r.html) — Reference Interface](@id H5R)
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

## [[`H5S`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_s.html) — Dataspace Interface](@id H5S)
- [`h5s_close`](@ref h5s_close)
- [`h5s_combine_hyperslab`](@ref h5s_combine_hyperslab)
- [`h5s_combine_select`](@ref h5s_combine_select)
- [`h5s_copy`](@ref h5s_copy)
- [`h5s_create`](@ref h5s_create)
- [`h5s_create_simple`](@ref h5s_create_simple)
- [`h5s_extent_copy`](@ref h5s_extent_copy)
- [`h5s_extent_equal`](@ref h5s_extent_equal)
- [`h5s_get_regular_hyperslab`](@ref h5s_get_regular_hyperslab)
- [`h5s_get_select_bounds`](@ref h5s_get_select_bounds)
- [`h5s_get_select_elem_npoints`](@ref h5s_get_select_elem_npoints)
- [`h5s_get_select_elem_pointlist`](@ref h5s_get_select_elem_pointlist)
- [`h5s_get_select_hyper_blocklist`](@ref h5s_get_select_hyper_blocklist)
- [`h5s_get_select_hyper_nblocks`](@ref h5s_get_select_hyper_nblocks)
- [`h5s_get_select_npoints`](@ref h5s_get_select_npoints)
- [`h5s_get_select_type`](@ref h5s_get_select_type)
- [`h5s_get_simple_extent_dims`](@ref h5s_get_simple_extent_dims)
- [`h5s_get_simple_extent_ndims`](@ref h5s_get_simple_extent_ndims)
- [`h5s_get_simple_extent_type`](@ref h5s_get_simple_extent_type)
- [`h5s_is_regular_hyperslab`](@ref h5s_is_regular_hyperslab)
- [`h5s_is_simple`](@ref h5s_is_simple)
- [`h5s_modify_select`](@ref h5s_modify_select)
- [`h5s_offset_simple`](@ref h5s_offset_simple)
- [`h5s_select_adjust`](@ref h5s_select_adjust)
- [`h5s_select_all`](@ref h5s_select_all)
- [`h5s_select_copy`](@ref h5s_select_copy)
- [`h5s_select_elements`](@ref h5s_select_elements)
- [`h5s_select_hyperslab`](@ref h5s_select_hyperslab)
- [`h5s_select_intersect_block`](@ref h5s_select_intersect_block)
- [`h5s_select_shape_same`](@ref h5s_select_shape_same)
- [`h5s_select_valid`](@ref h5s_select_valid)
- [`h5s_set_extent_none`](@ref h5s_set_extent_none)
- [`h5s_set_extent_simple`](@ref h5s_set_extent_simple)
```@docs
h5s_close
h5s_combine_hyperslab
h5s_combine_select
h5s_copy
h5s_create
h5s_create_simple
h5s_extent_copy
h5s_extent_equal
h5s_get_regular_hyperslab
h5s_get_select_bounds
h5s_get_select_elem_npoints
h5s_get_select_elem_pointlist
h5s_get_select_hyper_blocklist
h5s_get_select_hyper_nblocks
h5s_get_select_npoints
h5s_get_select_type
h5s_get_simple_extent_dims
h5s_get_simple_extent_ndims
h5s_get_simple_extent_type
h5s_is_regular_hyperslab
h5s_is_simple
h5s_modify_select
h5s_offset_simple
h5s_select_adjust
h5s_select_all
h5s_select_copy
h5s_select_elements
h5s_select_hyperslab
h5s_select_intersect_block
h5s_select_shape_same
h5s_select_valid
h5s_set_extent_none
h5s_set_extent_simple
```

---

## [[`H5T`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_t.html) — Datatype Interface](@id H5T)
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
- [`h5t_get_offset`](@ref h5t_get_offset)
- [`h5t_get_order`](@ref h5t_get_order)
- [`h5t_get_precision`](@ref h5t_get_precision)
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
- [`h5t_set_offset`](@ref h5t_set_offset)
- [`h5t_set_order`](@ref h5t_set_order)
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
h5t_get_offset
h5t_get_order
h5t_get_precision
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
h5t_set_offset
h5t_set_order
h5t_set_precision
h5t_set_size
h5t_set_strpad
h5t_set_tag
h5t_vlen_create
```

---

## [[`H5Z`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_z.html) — Filter Interface](@id H5Z)
- [`h5z_filter_avail`](@ref h5z_filter_avail)
- [`h5z_get_filter_info`](@ref h5z_get_filter_info)
- [`h5z_register`](@ref h5z_register)
- [`h5z_unregister`](@ref h5z_unregister)
```@docs
h5z_filter_avail
h5z_get_filter_info
h5z_register
h5z_unregister
```

---

## [[`H5FD`](https://docs.hdfgroup.org/hdf5/v1_14/_v_f_l.html) — File Drivers](@id H5FD)
- [`h5fd_core_init`](@ref h5fd_core_init)
- [`h5fd_family_init`](@ref h5fd_family_init)
- [`h5fd_log_init`](@ref h5fd_log_init)
- [`h5fd_mpio_init`](@ref h5fd_mpio_init)
- [`h5fd_multi_init`](@ref h5fd_multi_init)
- [`h5fd_sec2_init`](@ref h5fd_sec2_init)
- [`h5fd_stdio_init`](@ref h5fd_stdio_init)
```@docs
h5fd_core_init
h5fd_family_init
h5fd_log_init
h5fd_mpio_init
h5fd_multi_init
h5fd_sec2_init
h5fd_stdio_init
```

---

## [[`H5DO`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_d_o.html) — Optimized Functions Interface](@id H5DO)
- [`h5do_append`](@ref h5do_append)
- [`h5do_write_chunk`](@ref h5do_write_chunk)
```@docs
h5do_append
h5do_write_chunk
```

---

## [[`H5DS`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_d_s.html) — Dimension Scale Interface](@id H5DS)
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

## [[`H5LT`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_l_t.html) — Lite Interface](@id H5LT)
- [`h5lt_dtype_to_text`](@ref h5lt_dtype_to_text)
```@docs
h5lt_dtype_to_text
```

---

## [[`H5TB`](https://docs.hdfgroup.org/hdf5/v1_14/group___h5_t_b.html) — Table Interface](@id H5TB)
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


