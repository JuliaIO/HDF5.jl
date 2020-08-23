# This file is used to generate `api.jl`
# To warp additional HDF5 API include them in the list below then run this file to generate the new wrappers, as follows:
# julia> using HDF5; @eval HDF5 include("wrapper.jl")

io = open("api.jl", "w")
write_func(io, ex_func) = write(io, string(Base.remove_linenums!(ex_func)), '\n', '\n')



### Utilities for generating ccall wrapper functions programmatically ###

function ccallexpr(lib, ccallsym::Symbol, outtype, argtypes::Tuple, argsyms::Tuple)
    ccallargs = Any[Expr(:tuple, Expr(:quote, ccallsym), lib), outtype, Expr(:tuple, argtypes...)]
    ccallargs = ccallsyms(ccallargs, length(argtypes), argsyms)
    :(ccall($(ccallargs...)))
end

function ccallsyms(ccallargs, n, argsyms)
    if n > 0
        if length(argsyms) == n
            ccallargs = Any[ccallargs..., argsyms...]
        else
            for i = 1:length(argsyms)-1
                push!(ccallargs, argsyms[i])
            end
            for i = 1:n-length(argsyms)+1
                push!(ccallargs, Expr(:getindex, argsyms[end], i))
            end
        end
    end
    ccallargs
end

function funcdecexpr(funcsym, n::Int, argsyms)
    if length(argsyms) == n
        return Expr(:call, funcsym, argsyms...)
    else
        exargs = Any[funcsym, argsyms[1:end-1]...]
        push!(exargs, Expr(:..., argsyms[end]))
        return Expr(:call, exargs...)
    end
end


### ccall wrappers ###

# Note: use alphabetical order

# Functions that return Herr, pass back nothing to Julia (as an output), with simple
# error messages
for (jlname, h5name, outtype, argtypes, argsyms, msg) in
    ((:h5_close, :H5close, Herr, (), (), "Error closing the HDF5 resources"),
     (:h5_dont_atexit, :H5dont_atexit, Herr, (), (), "Error calling dont_atexit"),
     (:h5_garbage_collect, :H5garbage_collect, Herr, (), (), "Error on garbage collect"),
     (:h5_open, :H5open, Herr, (), (), "Error initializing the HDF5 library"),
     (:h5_set_free_list_limits, :H5set_free_list_limits, Herr, (Cint, Cint, Cint, Cint, Cint, Cint), (:reg_global_lim, :reg_list_lim, :arr_global_lim, :arr_list_lim, :blk_global_lim, :blk_list_lim), "Error setting limits on free lists"),
     (:h5a_close, :H5Aclose, Herr, (Hid,), (:id,), "Error closing attribute"),
     (:h5a_write, :H5Awrite, Herr, (Hid, Hid, Ptr{Cvoid}), (:attr_hid, :mem_type_id, :buf), "Error writing attribute data"),
     (:h5d_close, :H5Dclose, Herr, (Hid,), (:dataset_id,), "Error closing dataset"),
     (:h5d_flush, :H5Dflush, Herr, (Hid,), (:dataset_id,), "Error flushing dataset"),
     (:h5d_oappend, :H5DOappend, Herr, (Hid, Hid, Cuint, Hsize, Hid, Ptr{Cvoid}) , (:dset_id, :dxpl_id, :index, :num_elem, :memtype, :buffer), "error appending"),
     (:h5do_write_chunk, :H5DOwrite_chunk, Herr, (Hid, Hid, Int32, Ptr{Hsize}, Csize_t, Ptr{Cvoid}), (:dset_id, :dxpl_id, :filter_mask, :offset, :bufsize, :buf), "Error writing chunk"),
     (:h5d_refresh, :H5Drefresh, Herr, (Hid,), (:dataset_id,), "Error refreshing dataset"),
     (:h5d_set_extent, :H5Dset_extent, Herr, (Hid, Ptr{Hsize}), (:dataset_id, :new_dims), "Error extending dataset dimensions"),
     (:h5d_vlen_get_buf_size, :H5Dvlen_get_buf_size, Herr, (Hid, Hid, Hid, Ptr{Hsize}), (:dset_id, :type_id, :space_id, :buf), "Error getting vlen buffer size"),
     (:h5d_vlen_reclaim, :H5Dvlen_reclaim, Herr, (Hid, Hid, Hid, Ptr{Cvoid}), (:type_id, :space_id, :plist_id, :buf), "Error reclaiming vlen buffer"),
     (:h5d_write, :H5Dwrite, Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Cvoid}), (:dataset_id, :mem_type_id, :mem_space_id, :file_space_id, :xfer_plist_id, :buf), "Error writing dataset"),
     (:h5e_set_auto, :H5Eset_auto2, Herr, (Hid, Ptr{Cvoid}, Ptr{Cvoid}), (:estack_id, :func, :client_data), "Error setting error reporting behavior"),  # FIXME callbacks, for now pass C_NULL for both pointers
     (:h5f_close, :H5Fclose, Herr, (Hid,), (:file_id,), "Error closing file"),
     (:h5f_flush, :H5Fflush, Herr, (Hid, Cint), (:object_id, :scope,), "Error flushing object to file"),
     (:hf5start_swmr_write, :H5Fstart_swmr_write, Herr, (Hid,), (:id,), "Error starting SWMR write"),
     (:h5f_get_vfd_handle, :H5Fget_vfd_handle, Herr, (Hid, Hid, Ptr{Ptr{Cint}}), (:file_id, :fapl_id, :file_handle), "Error getting VFD handle"),
     (:h5f_get_intend, :H5Fget_intent, Herr, (Hid, Ptr{Cuint}), (:file_id, :intent), "Error getting file intent"),
     (:h5g_close, :H5Gclose, Herr, (Hid,), (:group_id,), "Error closing group"),
     (:h5g_get_info, :H5Gget_info, Herr, (Hid, Ptr{H5Ginfo}), (:group_id, :buf), "Error getting group info"),
     (:h5o_get_info, :H5Oget_info1, Herr, (Hid, Ptr{H5Oinfo}), (:object_id, :buf), "Error getting object info"),
     (:h5o_close, :H5Oclose, Herr, (Hid,), (:object_id,), "Error closing object"),
     (:h5p_close, :H5Pclose, Herr, (Hid,), (:id,), "Error closing property list"),
     (:h5p_get_alloc_time, :H5Pget_alloc_time, Herr, (Hid, Ptr{Cint}), (:plist_id, :alloc_time), "Error getting allocation timing"),
     (:h5p_get_dxpl_mpio,   :H5Pget_dxpl_mpio, Herr, (Hid, Ptr{Cint}), (:dxpl_id, :xfer_mode), "Error getting MPIO transfer mode"),
     (:h5p_get_fapl_mpio32, :H5Pget_fapl_mpio, Herr, (Hid, Ptr{Hmpih32}, Ptr{Hmpih32}), (:fapl_id, :comm, :info), "Error getting MPIO properties"),
     (:h5p_get_fapl_mpio64, :H5Pget_fapl_mpio, Herr, (Hid, Ptr{Hmpih64}, Ptr{Hmpih64}), (:fapl_id, :comm, :info), "Error getting MPIO properties"),
     (:h5p_get_fclose_degree, :H5Pget_fclose_degree, Herr, (Hid, Ptr{Cint}), (:plist_id, :fc_degree), "Error getting close degree"),
     (:h5p_get_userblock, :H5Pget_userblock, Herr, (Hid, Ptr{Hsize}), (:plist_id, :len), "Error getting userblock"),
     (:h5p_set_alloc_time, :H5Pset_alloc_time, Herr, (Hid, Cint), (:plist_id, :alloc_time), "Error setting allocation timing"),
     (:h5p_set_char_encoding, :H5Pset_char_encoding, Herr, (Hid, Cint), (:plist_id, :encoding), "Error setting char encoding"),
     (:h5p_set_chunk, :H5Pset_chunk, Herr, (Hid, Cint, Ptr{Hsize}), (:plist_id, :ndims, :dims), "Error setting chunk size"),
     (:h5p_set_create_intermediate_group, :H5Pset_create_intermediate_group, Herr, (Hid, Cuint), (:plist_id, :setting), "Error setting create intermediate group"),
     (:h5p_set_external, :H5Pset_external, Herr, (Hid, Ptr{UInt8}, Int, Csize_t), (:plist_id, :name, :offset, :size), "Error setting external property"),
     (:h5p_set_dxpl_mpio,   :H5Pset_dxpl_mpio, Herr, (Hid, Cint ), (:dxpl_id, :xfer_mode), "Error setting MPIO transfer mode"),
     (:h5p_set_fapl_mpio32, :H5Pset_fapl_mpio, Herr, (Hid, Hmpih32, Hmpih32), (:fapl_id, :comm, :info), "Error setting MPIO properties"),
     (:h5p_set_fapl_mpio64, :H5Pset_fapl_mpio, Herr, (Hid, Hmpih64, Hmpih64), (:fapl_id, :comm, :info), "Error setting MPIO properties"),
     (:h5p_set_fclose_degree, :H5Pset_fclose_degree, Herr, (Hid, Cint), (:plist_id, :fc_degree), "Error setting close degree"),
     (:h5p_set_deflate, :H5Pset_deflate, Herr, (Hid, Cuint), (:plist_id, :setting), "Error setting compression method and level (deflate)"),
     (:h5p_set_layout, :H5Pset_layout, Herr, (Hid, Cint), (:plist_id, :setting), "Error setting layout"),
     (:h5p_set_libver_bounds, :H5Pset_libver_bounds, Herr, (Hid, Cint, Cint), (:fapl_id, :libver_low, :libver_high), "Error setting library version bounds"),
     (:h5p_set_local_heap_size_hint, :H5Pset_local_heap_size_hint, Herr, (Hid, Cuint), (:fapl_id, :size_hint), "Error setting local heap size hint"),
     (:h5p_set_shuffle, :H5Pset_shuffle, Herr, (Hid,), (:plist_id,), "Error enabling shuffle filter"),
     (:h5p_set_userblock, :H5Pset_userblock, Herr, (Hid, Hsize), (:plist_id, :len), "Error setting userblock"),
     (:h5p_set_obj_track_times, :H5Pset_obj_track_times, Herr, (Hid, UInt8), (:plist_id, :track_times), "Error setting object time tracking"),
     (:h5p_get_alignment, :H5Pget_alignment, Herr, (Hid, Ptr{Hsize}, Ptr{Hsize}), (:plist_id, :threshold, :alignment), "Error getting alignment"),
     (:h5p_set_alignment, :H5Pset_alignment, Herr, (Hid, Hsize, Hsize), (:plist_id, :threshold, :alignment), "Error setting alignment"),
     (:h5s_close, :H5Sclose, Herr, (Hid,), (:space_id,), "Error closing dataspace"),
     (:h5s_select_hyperslab, :H5Sselect_hyperslab, Herr, (Hid, Cint, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}, Ptr{Hsize}), (:dspace_id, :seloper, :start, :stride, :count, :block), "Error selecting hyperslab"),
     (:h5t_commit, :H5Tcommit2, Herr, (Hid, Ptr{UInt8}, Hid, Hid, Hid, Hid), (:loc_id, :name, :dtype_id, :lcpl_id, :tcpl_id, :tapl_id), "Error committing type"),
     (:h5t_close, :H5Tclose, Herr, (Hid,), (:dtype_id,), "Error closing datatype"),
     (:h5t_set_cset, :H5Tset_cset, Herr, (Hid, Cint), (:dtype_id, :cset), "Error setting character set in datatype"),
     (:h5t_set_size, :H5Tset_size, Herr, (Hid, Csize_t), (:dtype_id, :sz), "Error setting size of datatype"),
     (:h5t_set_strpad, :H5Tset_strpad, Herr, (Hid, Cint), (:dtype_id, :sz), "Error setting size of datatype"),
     (:h5t_set_precision, :H5Tset_precision, Herr, (Hid, Csize_t), (:dtype_id, :sz), "Error setting precision of datatype"),
    )

    ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
    library = startswith(string(h5name), "H5DO") ? :libhdf5_hl : :libhdf5
    ex_ccall = ccallexpr(library, h5name, outtype, argtypes, argsyms)
    ex_body = quote
        status = $ex_ccall
        if status < 0
            error($msg)
        end
    end
    ex_func = Expr(:function, ex_dec, ex_body)
    write_func(io, ex_func)
end

# Functions returning a single argument, and/or with more complex
# error messages
for (jlname, h5name, outtype, argtypes, argsyms, ex_error) in
    ((:h5a_create, :H5Acreate2, Hid, (Hid, Ptr{UInt8}, Hid, Hid, Hid, Hid), (:loc_id, :pathname, :type_id, :space_id, :acpl_id, :aapl_id), :(error("Error creating attribute ", h5a_get_name(loc_id), "/", pathname))),
     (:h5a_create_by_name, :H5Acreate_by_name, Hid, (Hid, Ptr{UInt8}, Ptr{UInt8}, Hid, Hid, Hid, Hid, Hid), (:loc_id, :obj_name, :attr_name, :type_id, :space_id, :acpl_id, :aapl_id, :lapl_id), :(error("Error creating attribute ", attr_name, " for object ", obj_name))),
     (:h5a_delete, :H5Adelete, Herr, (Hid, Ptr{UInt8}), (:loc_id, :attr_name), :(error("Error deleting attribute ", attr_name))),
     (:h5a_delete_by_idx, :H5delete_by_idx, Herr, (Hid, Ptr{UInt8}, Cint, Cint, Hsize, Hid), (:loc_id, :obj_name, :idx_type, :order, :n, :lapl_id), :(error("Error deleting attribute ", n, " from object ", obj_name))),
     (:h5a_delete_by_name, :H5delete_by_name, Herr, (Hid, Ptr{UInt8}, Ptr{UInt8}, Hid), (:loc_id, :obj_name, :attr_name, :lapl_id), :(error("Error removing attribute ", attr_name, " from object ", obj_name))),
     (:h5a_get_create_plist, :H5Aget_create_plist, Hid, (Hid,), (:attr_id,), :(error("Cannot get creation property list"))),
     (:h5a_get_name, :H5Aget_name, Cssize_t, (Hid, Csize_t, Ptr{UInt8}), (:attr_id, :buf_size, :buf), :(error("Error getting attribute name"))),
     (:h5a_get_name_by_idx, :H5Aget_name_by_idx, Cssize_t, (Hid, Ptr{UInt8}, Cint, Cint, Hsize, Ptr{UInt8}, Csize_t, Hid), (:loc_id, :obj_name, :index_type, :order, :idx, :name, :size, :lapl_id), :(error("Error getting attribute name"))),
     (:h5a_get_space, :H5Aget_space, Hid, (Hid,), (:attr_id,), :(error("Error getting attribute dataspace"))),
     (:h5a_get_type, :H5Aget_type, Hid, (Hid,), (:attr_id,), :(error("Error getting attribute type"))),
     (:h5a_open, :H5Aopen, Hid, (Hid, Ptr{UInt8}, Hid), (:obj_id, :pathname, :aapl_id), :(error("Error opening attribute ", h5i_get_name(obj_id), "/", pathname))),
     (:h5a_read, :H5Aread, Herr, (Hid, Hid, Ptr{Cvoid}), (:attr_id, :mem_type_id, :buf), :(error("Error reading attribute ", h5a_get_name(attr_id)))),
     (:h5d_create, :H5Dcreate2, Hid, (Hid, Ptr{UInt8}, Hid, Hid, Hid, Hid, Hid), (:loc_id, :pathname, :dtype_id, :space_id, :lcpl_id, :dcpl_id, :dapl_id), :(error("Error creating dataset ", h5i_get_name(loc_id), "/", pathname))),
     (:h5d_get_access_plist, :H5Dget_access_plist, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataset access property list"))),
     (:h5d_get_create_plist, :H5Dget_create_plist, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataset create property list"))),
     (:h5d_get_offset, :H5Dget_offset, Haddr, (Hid,), (:dataset_id,), :(error("Error getting offset"))),
     (:h5d_get_space, :H5Dget_space, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataspace"))),
     (:h5d_get_type, :H5Dget_type, Hid, (Hid,), (:dataset_id,), :(error("Error getting dataspace type"))),
     (:h5d_open, :H5Dopen2, Hid, (Hid, Ptr{UInt8}, Hid), (:loc_id, :pathname, :dapl_id), :(error("Error opening dataset ", h5i_get_name(loc_id), "/", pathname))),
     (:h5d_read, :H5Dread, Herr, (Hid, Hid, Hid, Hid, Hid, Ptr{Cvoid}), (:dataset_id, :mem_type_id, :mem_space_id, :file_space_id, :xfer_plist_id, :buf), :(error("Error reading dataset ", h5i_get_name(dataset_id)))),
     (:h5f_create, :H5Fcreate, Hid, (Ptr{UInt8}, Cuint, Hid, Hid), (:pathname, :flags, :fcpl_id, :fapl_id), :(error("Error creating file ", pathname))),
     (:h5f_get_access_plist, :H5Fget_access_plist, Hid, (Hid,), (:file_id,), :(error("Error getting file access property list"))),
     (:h5f_get_create_plist, :H5Fget_create_plist, Hid, (Hid,), (:file_id,), :(error("Error getting file create property list"))),
     (:h5f_get_name, :H5Fget_name, Cssize_t, (Hid, Ptr{UInt8}, Csize_t), (:obj_id, :buf, :buf_size), :(error("Error getting file name"))),
     (:h5f_open, :H5Fopen, Hid, (Cstring, Cuint, Hid), (:pathname, :flags, :fapl_id), :(error("Error opening file ", pathname))),
     (:h5g_create, :H5Gcreate2, Hid, (Hid, Ptr{UInt8}, Hid, Hid, Hid), (:loc_id, :pathname, :lcpl_id, :gcpl_id, :gapl_id), :(error("Error creating group ", h5i_get_name(loc_id), "/", pathname))),
     (:h5g_get_create_plist, :H5Gget_create_plist, Hid, (Hid,), (:group_id,), :(error("Error getting group create property list"))),
     (:h5g_get_objname_by_idx, :H5Gget_objname_by_idx, Cssize_t, (Hid, Hsize, Ptr{UInt8}, Csize_t), (:loc_id, :idx, :pathname, :size), :(error("Error getting group object name ", h5i_get_name(loc_id), "/", pathname))),
     (:h5g_get_num_objs, :H5Gget_num_objs, Hid, (Hid, Ptr{Hsize}), (:loc_id, :num_obj), :(error("Error getting group length"))),
     (:h5g_open, :H5Gopen2, Hid, (Hid, Ptr{UInt8}, Hid), (:loc_id, :pathname, :gapl_id), :(error("Error opening group ", h5i_get_name(loc_id), "/", pathname))),
     (:h5i_get_file_id, :H5Iget_file_id, Hid, (Hid,), (:obj_id,), :(error("Error getting file identifier"))),
     (:h5i_get_name, :H5Iget_name, Cssize_t, (Hid, Ptr{UInt8}, Csize_t), (:obj_id, :buf, :buf_size), :(error("Error getting object name"))),
     (:h5i_get_ref, :H5Iget_ref, Cint, (Hid,), (:obj_id,), :(error("Error getting reference count"))),
     (:h5i_get_type, :H5Iget_type, Cint, (Hid,), (:obj_id,), :(error("Error getting type"))),
     (:h5i_dec_ref, :H5Idec_ref, Cint, (Hid,), (:obj_id,), :(error("Error decementing reference"))),
     (:h5l_delete, :H5Ldelete, Herr, (Hid, Ptr{UInt8}, Hid), (:obj_id, :pathname, :lapl_id), :(error("Error deleting ", h5i_get_name(obj_id), "/", pathname))),
     (:h5l_create_external, :H5Lcreate_external, Herr, (Ptr{UInt8}, Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), (:target_file_name, :target_obj_name, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating external link ", link_name, " pointing to ", target_obj_name, " in file ", target_file_name))),
     (:h5l_create_hard, :H5Lcreate_hard, Herr, (Hid, Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), (:obj_loc_id, :obj_name, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating hard link ", link_name, " pointing to ", obj_name))),
     (:h5l_create_soft, :H5Lcreate_soft, Herr, (Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), (:target_path, :link_loc_id, :link_name, :lcpl_id, :lapl_id), :(error("Error creating soft link ", link_name, " pointing to ", target_path))),
     (:h5l_get_info, :H5Lget_info, Herr, (Hid, Ptr{UInt8}, Ptr{H5LInfo}, Hid), (:link_loc_id, :link_name, :link_buf, :lapl_id), :(error("Error getting info for link ", link_name))),
     (:h5o_open, :H5Oopen, Hid, (Hid, Ptr{UInt8}, Hid), (:loc_id, :pathname, :lapl_id), :(error("Error opening object ", h5i_get_name(loc_id), "/", pathname))),
     (:h5o_open_by_idx, :H5Oopen_by_idx, Hid, (Hid, Ptr{UInt8}, Cint, Cint, Hsize, Hid), (:loc_id, :group_name, :index_type, :order, :n, :lapl_id), :(error("Error opening object of index ", n))),
     (:h5o_open_by_addr, :H5Oopen_by_addr, Hid, (Hid, Haddr), (:loc_id, :addr), :(error("Error opening object by address"))),
     (:h5o_copy, :H5Ocopy, Herr, (Hid, Ptr{UInt8}, Hid, Ptr{UInt8}, Hid, Hid), (:src_loc_id, :src_name, :dst_loc_id, :dst_name, :ocpypl_id, :lcpl_id), :(error("Error copying object ", h5i_get_name(src_loc_id), "/", src_name, " to ", h5i_get_name(dst_loc_id), "/", dst_name))),
     (:h5p_create, :H5Pcreate, Hid, (Hid,), (:cls_id,), "Error creating property list"),
     (:h5p_get_chunk, :H5Pget_chunk, Cint, (Hid, Cint, Ptr{Hsize}), (:plist_id, :n_dims, :dims), :(error("Error getting chunk size"))),
     (:h5p_get_layout, :H5Pget_layout, Cint, (Hid,), (:plist_id,), :(error("Error getting layout"))),
     (:h5p_get_driver_info, :H5Pget_driver_info, Ptr{Cvoid}, (Hid,), (:plist_id,), "Error getting driver info"),
     (:h5p_get_driver, :H5Pget_driver, Hid, (Hid,), (:plist_id,), "Error getting driver identifier"),
     (:h5r_create, :H5Rcreate, Herr, (Ptr{HDF5ReferenceObj}, Hid, Ptr{UInt8}, Cint, Hid), (:ref, :loc_id, :pathname, :ref_type, :space_id), :(error("Error creating reference to object ", hi5_get_name(loc_id), "/", pathname))),
     (:h5r_get_obj_type, :H5Rget_obj_type2, Herr, (Hid, Cint, Ptr{Cvoid}, Ptr{Cint}), (:loc_id, :ref_type, :ref, :obj_type), :(error("Error getting object type"))),
     (:h5r_get_region, :H5Rget_region, Hid, (Hid, Cint, Ptr{Cvoid}), (:loc_id, :ref_type, :ref), :(error("Error getting region from reference"))),
     (:h5s_copy, :H5Scopy, Hid, (Hid,), (:space_id,), :(error("Error copying dataspace"))),
     (:h5s_create, :H5Screate, Hid, (Cint,), (:class,), :(error("Error creating dataspace"))),
     (:h5s_create_simple, :H5Screate_simple, Hid, (Cint, Ptr{Hsize}, Ptr{Hsize}), (:rank, :current_dims, :maximum_dims), :(error("Error creating simple dataspace"))),
     (:h5s_get_simple_extent_dims, :H5Sget_simple_extent_dims, Cint, (Hid, Ptr{Hsize}, Ptr{Hsize}), (:space_id, :dims, :maxdims), :(error("Error getting the dimensions for a dataspace"))),
     (:h5s_get_simple_extent_ndims, :H5Sget_simple_extent_ndims, Cint, (Hid,), (:space_id,), :(error("Error getting the number of dimensions for a dataspace"))),
     (:h5s_get_simple_extent_type, :H5Sget_simple_extent_type, Cint, (Hid,), (:space_id,), :(error("Error getting the dataspace type"))),
     (:h5t_array_create, :H5Tarray_create2, Hid, (Hid, Cuint, Ptr{Hsize}), (:basetype_id, :ndims, :sz), :(error("Error creating H5T_ARRAY of id ", basetype_id, " and size ", sz))),
     (:h5t_copy, :H5Tcopy, Hid, (Hid,), (:dtype_id,), :(error("Error copying datatype"))),
     (:h5t_create, :H5Tcreate, Hid, (Cint, Csize_t), (:class_id, :sz), :(error("Error creating datatype of id ", class_id))),
     (:h5t_equal, :H5Tequal, Hid, (Hid, Hid), (:dtype_id1, :dtype_id2), :(error("Error checking datatype equality"))),
     (:h5t_get_array_dims, :H5Tget_array_dims2, Cint, (Hid, Ptr{Hsize}), (:dtype_id, :dims), :(error("Error getting dimensions of array"))),
     (:h5t_get_array_ndims, :H5Tget_array_ndims, Cint, (Hid,), (:dtype_id,), :(error("Error getting ndims of array"))),
     (:h5t_get_class, :H5Tget_class, Cint, (Hid,), (:dtype_id,), :(error("Error getting class"))),
     (:h5t_get_cset, :H5Tget_cset, Cint, (Hid,), (:dtype_id,), :(error("Error getting character set encoding"))),
     (:h5t_get_member_class, :H5Tget_member_class, Cint, (Hid, Cuint), (:dtype_id, :index), :(error("Error getting class of compound datatype member #", index))),
     (:h5t_get_member_index, :H5Tget_member_index, Cint, (Hid, Ptr{UInt8}), (:dtype_id, :membername), :(error("Error getting index of compound datatype member \"", membername, "\""))),
     (:h5t_get_member_offset, :H5Tget_member_offset, Csize_t, (Hid, Cuint), (:dtype_id, :index), :(error("Error getting offset of compound datatype member #", index))),
     (:h5t_get_member_type, :H5Tget_member_type, Hid, (Hid, Cuint), (:dtype_id, :index), :(error("Error getting type of compound datatype member #", index))),
     (:h5t_get_native_type, :H5Tget_native_type, Hid, (Hid, Cint), (:dtype_id, :direction), :(error("Error getting native type"))),
     (:h5t_get_nmembers, :H5Tget_nmembers, Cint, (Hid,), (:dtype_id,), :(error("Error getting the number of members"))),
     (:h5t_get_sign, :H5Tget_sign, Cint, (Hid,), (:dtype_id,), :(error("Error getting sign"))),
     (:h5t_get_size, :H5Tget_size, Csize_t, (Hid,), (:dtype_id,), :(error("Error getting size"))),
     (:h5t_get_super, :H5Tget_super, Hid, (Hid,), (:dtype_id,), :(error("Error getting super type"))),
     (:h5t_get_strpad, :H5Tget_strpad, Cint, (Hid,), (:dtype_id,), :(error("Error getting string padding"))),
     (:h5t_insert, :H5Tinsert, Herr, (Hid, Ptr{UInt8}, Csize_t, Hid), (:dtype_id, :fieldname, :offset, :field_id), :(error("Error adding field ", fieldname, " to compound datatype"))),
     (:h5t_open, :H5Topen2, Hid, (Hid, Ptr{UInt8}, Hid), (:loc_id, :name, :tapl_id), :(error("Error opening type ", h5i_get_name(loc_id), "/", name))),
     (:h5t_vlen_create, :H5Tvlen_create, Hid, (Hid,), (:base_type_id,), :(error("Error creating vlen type"))),
     ## The following doesn't work because it's in libhdf5_hl.so.
     ## (:h5tb_get_field_info, :H5TBget_field_info, Herr, (Hid, Ptr{UInt8}, Ptr{Ptr{UInt8}}, Ptr{UInt8}, Ptr{UInt8}, Ptr{UInt8}), (:loc_id, :table_name, :field_names, :field_sizes, :field_offsets, :type_size), :(error("Error getting field information")))
)

    ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
    ex_ccall = ccallexpr(:libhdf5, h5name, outtype, argtypes, argsyms)
    ex_body = quote
        ret = $ex_ccall
        if ret < 0
            $ex_error
        end
        return ret
    end
    ex_func = Expr(:function, ex_dec, ex_body)
    write_func(io, ex_func)
end

# Functions like the above, returning a Julia boolean
for (jlname, h5name, outtype, argtypes, argsyms, ex_error) in
    ((:h5a_exists, :H5Aexists, Htri, (Hid, Ptr{UInt8}), (:obj_id, :attr_name), :(error("Error checking whether attribute ", attr_name, " exists"))),
     (:h5a_exists_by_name, :H5Aexists_by_name, Htri, (Hid, Ptr{UInt8}, Ptr{UInt8}, Hid), (:loc_id, :obj_name, :attr_name, :lapl_id), :(error("Error checking whether object ", obj_name, " has attribute ", attr_name))),
     (:h5f_is_hdf5, :H5Fis_hdf5, Htri, (Cstring,), (:pathname,), :(error("Cannot access file ", pathname))),
     (:h5i_is_valid, :H5Iis_valid, Htri, (Hid,), (:obj_id,), :(error("Cannot determine whether object is valid"))),
     (:h5l_exists, :H5Lexists, Htri, (Hid, Ptr{UInt8}, Hid), (:loc_id, :pathname, :lapl_id), :(error("Cannot determine whether ", pathname, " exists"))),
     (:h5s_is_simple, :H5Sis_simple, Htri, (Hid,), (:space_id,), :(error("Error determining whether dataspace is simple"))),
     (:h5t_is_variable_str, :H5Tis_variable_str, Htri, (Hid,), (:type_id,), :(error("Error determining whether string is of variable length"))),
     (:h5t_committed, :H5Tcommitted, Htri, (Hid,), (:dtype_id,), :(error("Error determining whether datatype is committed"))),
)
    ex_dec = funcdecexpr(jlname, length(argtypes), argsyms)
    ex_ccall = ccallexpr(:libhdf5, h5name, outtype, argtypes, argsyms)
    ex_body = quote
        ret = $ex_ccall
        if ret < 0
            $ex_error
        end
        return ret > 0
    end
    ex_func = Expr(:function, ex_dec, ex_body)
    write_func(io, ex_func)
end

close(io)
