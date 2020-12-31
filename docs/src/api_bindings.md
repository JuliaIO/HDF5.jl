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

## [`H5`](https://portal.hdfgroup.org/display/HDF5/Library) — General Library Functions
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

## [`H5A`](https://portal.hdfgroup.org/display/HDF5/Attributes) — Attribute Interface
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

## [`H5D`](https://portal.hdfgroup.org/display/HDF5/Datasets) — Dataset Interface
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

## [`H5E`](https://portal.hdfgroup.org/display/HDF5/Error+Handling) — Error Interface
```@docs
h5e_get_auto
h5e_get_current_stack
h5e_set_auto
```

## [`H5F`](https://portal.hdfgroup.org/display/HDF5/Files) — File Interface
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

## [`H5G`](https://portal.hdfgroup.org/display/HDF5/Groups) — Group Interface
```@docs
h5g_close
h5g_create
h5g_get_create_plist
h5g_get_info
h5g_get_num_objs
h5g_get_objname_by_idx
h5g_open
```

## [`H5I`](https://portal.hdfgroup.org/display/HDF5/Identifiers) — Identifier Interface
```@docs
h5i_dec_ref
h5i_get_file_id
h5i_get_name
h5i_get_ref
h5i_get_type
h5i_inc_ref
h5i_is_valid
```

## [`H5L`](https://portal.hdfgroup.org/display/HDF5/Links) — Link Interface
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

## [`H5O`](https://portal.hdfgroup.org/display/HDF5/Objects) — Object Interface
```@docs
h5o_close
h5o_copy
h5o_get_info
h5o_open
h5o_open_by_addr
h5o_open_by_idx
```

## [`H5P`](https://portal.hdfgroup.org/display/HDF5/Property+Lists) — Property Interface
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

## [`H5R`](https://portal.hdfgroup.org/display/HDF5/References) — Reference Interface
```@docs
h5r_create
h5r_dereference
h5r_get_obj_type
h5r_get_region
```

## [`H5S`](https://portal.hdfgroup.org/display/HDF5/Dataspaces) — Dataspace Interface
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

## [`H5T`](https://portal.hdfgroup.org/display/HDF5/Datatypes) — Datatype Interface
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

## [`H5Z`](https://portal.hdfgroup.org/display/HDF5/Filters) — Filter Interface
```@docs
h5z_register
```

## [`H5DO`](https://portal.hdfgroup.org/display/HDF5/Optimizations) — Optimized Functions Interface
```@docs
h5do_append
h5do_write_chunk
```

## [`H5DS`](https://portal.hdfgroup.org/display/HDF5/Dimension+Scales) — Dimension Scale Interface
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

## [`H5LT`](https://portal.hdfgroup.org/display/HDF5/Lite) — Lite Interface
```@docs
h5lt_dtype_to_text
```

## [`H5TB`](https://portal.hdfgroup.org/display/HDF5/Tables) — Table Interface
```@docs
h5tb_append_records
h5tb_get_field_info
h5tb_get_table_info
h5tb_make_table
h5tb_read_records
h5tb_read_table
h5tb_write_records
```


