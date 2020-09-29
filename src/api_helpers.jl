# This file is a companion to `src/api.jl` --- it defines the raw ccall wrappers, while
# here small normalizations are made to make the calls more Julian.
# For instance, many property getters return values through pointer output arguments,
# so the methods here handle making the appropriate `Ref`s and return them (as tuples).

###
### HDF5 General library functions
###

function h5_get_libversion()
    majnum, minnum, relnum = Ref{Cuint}(), Ref{Cuint}(), Ref{Cuint}()
    h5_get_libversion(majnum, minnum, relnum)
    VersionNumber(majnum[], minnum[], relnum[])
end

###
### Attribute Interface
###

function h5a_get_name(attr_id)
    len = h5a_get_name(attr_id, 0, C_NULL)
    buf = StringVector(len)
    h5a_get_name(attr_id, len+1, buf)
    return String(buf)
end

function h5a_get_name_by_idx(loc_id, obj_name, idx_type, order, idx, lapl_id)
    len = h5a_get_name_by_idx(loc_id, obj_name, idx_type, order, idx, C_NULL, 0, lapl_id)
    buf = StringVector(len)
    h5a_get_name_by_idx(loc_id, obj_name, idx_type, order, idx, buf, len + 1, lapl_id)
    return String(buf)
end

###
### Dataset Interface
###

function h5d_vlen_get_buf_size(dataset_id, type_id, space_id)
    sz = Ref{hsize_t}()
    h5d_vlen_get_buf_size(dataset_id, type_id, space_id, sz)
    return sz[]
end

###
### Error Interface
###

function h5e_get_auto(error_stack)
    func = Ref{Ptr{Cvoid}}()
    client_data = Ref{Ptr{Cvoid}}()
    h5e_get_auto(error_stack, func, client_data)
    return func[], client_data[]
end

###
### File Interface
###

function h5f_get_intent(file_id)
    intent = Ref{Cuint}()
    h5f_get_intent(file_id, intent)
    return intent[]
end

function h5f_get_name(loc_id)
    len = h5f_get_name(loc_id, C_NULL, 0)
    buf = StringVector(len)
    h5f_get_name(loc_id, buf, len+1)
    return String(buf)
end

function h5f_get_obj_ids(file_id, types)
    sz = h5f_get_obj_count(file_id, types)
    hids = Vector{hid_t}(undef, sz)
    sz2 = h5f_get_obj_ids(file_id, types, sz, hids)
    sz2 != sz && resize!(hids, sz2)
    return hids
end

function h5f_get_vfd_handle(file_id, fapl)
    file_handle = Ref{Ptr{Cvoid}}()
    h5f_get_vfd_handle(file_id, fapl, file_handle)
    return file_handle[]
end

###
### Group Interface
###

function h5g_get_info(loc_id)
    ginfo = Ref{H5Ginfo}()
    h5g_get_info(loc_id, ginfo)
    return ginfo[]
end

function h5g_get_num_objs(loc_id)
    num_objs = Ref{hsize_t}()
    h5g_get_num_objs(loc_id, num_objs)
    return num_objs[]
end

###
### Identifier Interface
###

function h5i_get_name(loc_id)
    len = h5i_get_name(loc_id, C_NULL, 0)
    buf = StringVector(len)
    h5i_get_name(loc_id, buf, len+1)
    return String(buf)
end

###
### Link Interface
###

function h5l_get_info(link_loc_id, link_name, lapl_id)
    info = Ref{H5LInfo}()
    h5l_get_info(link_loc_id, link_name, info, lapl_id)
    return info[]
end

function h5l_get_name_by_idx(loc_id, group_name, idx_type, order, idx, lapl_id)
    len = h5l_get_name_by_idx(loc_id, group_name, idx_type, order, idx, C_NULL, 0, lapl_id)
    buf = StringVector(len)
    h5l_get_name_by_idx(loc_id, group_name, idx_type, order, idx, buf, len + 1, lapl_id)
    return String(buf)
end

###
### Object Interface
###

function h5o_get_info(loc_id)
    oinfo = Ref{H5Oinfo}()
    h5o_get_info(loc_id, oinfo)
    return oinfo[]
end

###
### Property Interface
###

function h5p_get_alignment(fapl_id)
    threshold = Ref{hsize_t}()
    alignment = Ref{hsize_t}()
    h5p_get_alignment(fapl_id, threshold, alignment)
    return threshold[], alignment[]
end

function h5p_get_alloc_time(plist_id)
    alloc_time = Ref{Cint}()
    h5p_get_alloc_time(plist_id, alloc_time)
    return alloc_time[]
end

function h5p_get_char_encoding(plist_id)
    encoding = Ref{Cint}()
    h5p_get_char_encoding(plist_id, encoding)
    return encoding[]
end

function h5p_get_chunk(plist_id)
    n = h5p_get_chunk(plist_id, 0, C_NULL)
    cdims = Vector{hsize_t}(undef, n)
    h5p_get_chunk(plist_id, n, cdims)
    return cdims
end

function h5p_get_create_intermediate_group(plist_id)
    cig = Ref{Cuint}()
    h5p_get_create_intermediate_group(plist_id, cig)
    return cig[]
end

function h5p_get_dxpl_mpio(dxpl_id)
    xfer_mode = Ref{Cint}()
    h5p_get_dxpl_mpio(dxpl_id, xfer_mode)
    return xfer_mode[]
end

function h5p_get_fclose_degree(fapl_id)
    out = Ref{Cint}()
    h5p_get_fclose_degree(fapl_id, out)
    return out[]
end

function h5p_get_libver_bounds(plist_id)
    low = Ref{Cint}()
    high = Ref{Cint}()
    h5p_get_libver_bounds(plist_id, low, high)
    return low[], high[]
end

function h5p_get_local_heap_size_hint(plist_id)
    size_hint = Ref{Csize_t}()
    h5p_get_local_heap_size_hint(plist_id, size_hint)
    return size_hint[]
end

function h5p_get_obj_track_times(plist_id)
    track_times = Ref{UInt8}()
    h5p_get_obj_track_times(plist_id, track_times)
    return track_times[] != 0x0
end

function h5p_get_userblock(plist_id)
    len = Ref{hsize_t}()
    h5p_get_userblock(plist_id, len)
    return len[]
end

###
### Reference Interface
###

###
### Dataspace Interface
###

function h5s_get_simple_extent_dims(space_id)
    n = h5s_get_simple_extent_ndims(space_id)
    dims = Vector{hsize_t}(undef, n)
    maxdims = Vector{hsize_t}(undef, n)
    h5s_get_simple_extent_dims(space_id, dims, maxdims)
    return dims, maxdims
end


###
### Datatype Interface
###

function h5t_get_array_dims(type_id)
    nd = h5t_get_array_ndims(type_id)
    dims = Vector{hsize_t}(undef, nd)
    h5t_get_array_dims(type_id, dims)
    return dims
end

# Note: The following two functions implement direct ccalls because the binding generator
# cannot (yet) do the string wrapping and memory freeing.
function h5t_get_member_name(type_id, index)
    pn = ccall((:H5Tget_member_name, libhdf5), Ptr{UInt8}, (hid_t, Cuint), type_id, index)
    if pn == C_NULL
        error("Error getting name of compound datatype member #", index)
    end
    s = unsafe_string(pn)
    h5_free_memory(pn)
    return s
end

function h5t_get_tag(type_id)
    pc = ccall((:H5Tget_tag, libhdf5), Ptr{UInt8}, (hid_t,), type_id)
    if pc == C_NULL
        error("Error getting opaque tag")
    end
    s = unsafe_string(pc)
    h5_free_memory(pc)
    return s
end

###
### Optimized Functions Interface
###

###
### HDF5 Lite Interface
###

function h5lt_dtype_to_text(dtype_id)
    # Note we can't use h5i_is_valid to check if dtype is valid because
    # ref counts aren't incremented for basic atomic types (e.g. H5T_NATIVE_INT).
    # Instead just temporarily turn off error printing and try call to probe if dtype is valid.
    old_func, old_client_data = h5e_get_auto(H5E_DEFAULT)
    h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)
    try
        len = Ref{Csize_t}()
        h5lt_dtype_to_text(dtype_id, C_NULL, 0, len)
        buf = StringVector(len[] - 1)
        h5lt_dtype_to_text(dtype_id, buf, 0, len)
        return String(buf)
    catch
        return "(invalid)"
    finally
        h5e_set_auto(H5E_DEFAULT, old_func, old_client_data)
    end
end

###
### Table Interface
###

###
### Filter Interface
###

