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

function h5_is_library_threadsafe()
    is_ts = Ref{Cuint}()
    h5_is_library_threadsafe(is_ts)
    return is_ts[] > 0
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

# libhdf5 supports proper closure environments, so we use that support rather than
# emulating it with the less desirable form of creating closure handles directly in
# `@cfunction` with `$f`.
# This helper translates between the two preferred forms for each respective language.
function h5a_iterate_helper(loc_id::hid_t, attr_name::Ptr{Cchar}, ainfo::Ptr{H5A_info_t}, @nospecialize(f::Any))::herr_t
    return f(loc_id, attr_name, ainfo)
end
"""
    h5a_iterate(f, loc_id, idx_type, order, idx = 0) -> HDF5.hsize_t

Executes [`h5a_iterate`](@ref h5a_iterate(::hid_t, ::Cint, ::Cint, ::Ptr{hsize_t}, ::Ptr{Cvoid}, ::Ptr{Cvoid}))
with the user-provided callback function `f`, returning the index where iteration ends.

The callback function must correspond to the signature
```
    f(loc::HDF5.hid_t, name::Ptr{Cchar}, info::Ptr{HDF5.H5A_info_t}) -> HDF5.herr_t
```
where a negative return value halts iteration abnormally, a positive value halts iteration
successfully, and zero continues iteration.

# Examples
```julia-repl
julia> HDF5.h5a_iterate(obj, HDF5.H5_INDEX_NAME, HDF5.H5_ITER_INC) do loc, name, info
           println(unsafe_string(name))
           return HDF5.herr_t(0)
       end
```
"""
function h5a_iterate(@nospecialize(f), obj_id, idx_type, order, idx = 0)
    idxref = Ref{hsize_t}(idx)
    fptr = @cfunction(h5a_iterate_helper, herr_t, (hid_t, Ptr{Cchar}, Ptr{H5A_info_t}, Any))
    h5a_iterate(obj_id, idx_type, order, idxref, fptr, f)
    return idxref[]
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

function h5e_get_auto(estack_id)
    func = Ref{Ptr{Cvoid}}()
    client_data = Ref{Ptr{Cvoid}}()
    h5e_get_auto(estack_id, func, client_data)
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
    ginfo = Ref{H5G_info_t}()
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
    info = Ref{H5L_info_t}()
    h5l_get_info(link_loc_id, link_name, info, lapl_id)
    return info[]
end

function h5l_get_name_by_idx(loc_id, group_name, idx_type, order, idx, lapl_id)
    len = h5l_get_name_by_idx(loc_id, group_name, idx_type, order, idx, C_NULL, 0, lapl_id)
    buf = StringVector(len)
    h5l_get_name_by_idx(loc_id, group_name, idx_type, order, idx, buf, len + 1, lapl_id)
    return String(buf)
end

# See explanation for h5a_iterate above.
function h5l_iterate_helper(group::hid_t, name::Ptr{Cchar}, info::Ptr{H5L_info_t}, @nospecialize(f::Any))::herr_t
    return f(group, name, info)
end
"""
    h5l_iterate(f, group_id, idx_type, order, idx = 0) -> HDF5.hsize_t

Executes [`h5l_iterate`](@ref h5l_iterate(::hid_t, ::Cint, ::Cint, ::Ptr{hsize_t}, ::Ptr{Cvoid}, ::Ptr{Cvoid}))
with the user-provided callback function `f`, returning the index where iteration ends.

The callback function must correspond to the signature
```
    f(group::HDF5.hid_t, name::Ptr{Cchar}, info::Ptr{HDF5.H5L_info_t}) -> HDF5.herr_t
```
where a negative return value halts iteration abnormally, a positive value halts iteration
successfully, and zero continues iteration.

# Examples
```julia-repl
julia> HDF5.h5l_iterate(hfile, HDF5.H5_INDEX_NAME, HDF5.H5_ITER_INC) do group, name, info
           println(unsafe_string(name))
           return HDF5.herr_t(0)
       end
```
"""
function h5l_iterate(@nospecialize(f), group_id, idx_type, order, idx = 0)
    idxref = Ref{hsize_t}(idx)
    fptr = @cfunction(h5l_iterate_helper, herr_t, (hid_t, Ptr{Cchar}, Ptr{H5L_info_t}, Any))
    h5l_iterate(group_id, idx_type, order, idxref, fptr, f)
    return idxref[]
end

###
### Object Interface
###

function h5o_get_info(loc_id)
    oinfo = Ref{H5O_info_t}()
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


h5p_set_fapl_mpio(fapl_id, comm::Hmpih32, info::Hmpih32) =
    h5p_set_fapl_mpio32(fapl_id, comm, info)
h5p_set_fapl_mpio(fapl_id, comm::Hmpih64, info::Hmpih64) =
    h5p_set_fapl_mpio64(fapl_id, comm, info)

function h5p_get_fapl_mpio(fapl_id, ::Type{Hmpih32})
    comm, info = Ref{Hmpih32}(), Ref{Hmpih32}()
    h5p_get_fapl_mpio32(fapl_id, comm, info)
    comm[], info[]
end
function h5p_get_fapl_mpio(fapl_id, ::Type{Hmpih64})
    comm, info = Ref{Hmpih64}(), Ref{Hmpih64}()
    h5p_get_fapl_mpio64(fapl_id, comm, info)
    comm[], info[]
end


# Note: The following function(s) implement direct ccalls because the binding generator
# cannot (yet) do the string wrapping and memory freeing.

"""
    h5p_get_class_name(pcid::hid_t) -> String

See `libhdf5` documentation for [`H5Oopen`](https://portal.hdfgroup.org/display/HDF5/H5P_GET_CLASS_NAME).
"""
function h5p_get_class_name(pcid)
    pc = ccall((:H5Pget_class_name, libhdf5), Ptr{UInt8}, (hid_t,), pcid)
    if pc == C_NULL
        error("Error getting class name")
    end
    s = unsafe_string(pc)
    h5_free_memory(pc)
    return s
end

###
### Reference Interface
###

###
### Dataspace Interface
###

function h5s_get_regular_hyperslab(space_id)
    n = h5s_get_simple_extent_ndims(space_id)
    start  = Vector{hsize_t}(undef, n)
    stride = Vector{hsize_t}(undef, n)
    count  = Vector{hsize_t}(undef, n)
    block  = Vector{hsize_t}(undef, n)
    h5s_get_regular_hyperslab(space_id, start, stride, count, block)
    return start, stride, count, block
end

function h5s_get_simple_extent_dims(space_id)
    n = h5s_get_simple_extent_ndims(space_id)
    dims = Vector{hsize_t}(undef, n)
    maxdims = Vector{hsize_t}(undef, n)
    h5s_get_simple_extent_dims(space_id, dims, maxdims)
    return dims, maxdims
end
function h5s_get_simple_extent_dims(space_id, ::Nothing)
    n = h5s_get_simple_extent_ndims(space_id)
    dims = Vector{hsize_t}(undef, n)
    h5s_get_simple_extent_dims(space_id, dims, C_NULL)
    return dims
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

function h5t_get_fields(type_id)
    spos = Ref{Csize_t}()
    epos = Ref{Csize_t}()
    esize = Ref{Csize_t}()
    mpos = Ref{Csize_t}()
    msize = Ref{Csize_t}()
    h5t_get_fields(type_id, spos, epos, esize, mpos, msize)
    return (spos[], epos[], esize[], mpos[], msize[])
end

h5t_get_native_type(type_id) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)

# Note: The following two functions implement direct ccalls because the binding generator
# cannot (yet) do the string wrapping and memory freeing.
"""
    h5t_get_member_name(type_id::hid_t, index::Cuint) -> String

See `libhdf5` documentation for [`H5Oopen`](https://portal.hdfgroup.org/display/HDF5/H5T_GET_MEMBER_NAME).
"""
function h5t_get_member_name(type_id, index)
    pn = ccall((:H5Tget_member_name, libhdf5), Ptr{UInt8}, (hid_t, Cuint), type_id, index)
    if pn == C_NULL
        error("Error getting name of compound datatype member #", index)
    end
    s = unsafe_string(pn)
    h5_free_memory(pn)
    return s
end

"""
    h5t_get_tag(type_id::hid_t) -> String

See `libhdf5` documentation for [`H5Oopen`](https://portal.hdfgroup.org/display/HDF5/H5T_GET_TAG).
"""
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
    len = Ref{Csize_t}()
    h5lt_dtype_to_text(dtype_id, C_NULL, 0, len)
    buf = StringVector(len[] - 1)
    h5lt_dtype_to_text(dtype_id, buf, 0, len)
    return String(buf)
end

###
### Table Interface
###

function h5tb_get_table_info(loc_id, table_name)
    nfields = Ref{hsize_t}()
    nrecords = Ref{hsize_t}()
    h5tb_get_table_info(loc_id, table_name, nfields, nrecords)
    return nfields[], nrecords[]
end

function h5tb_get_field_info(loc_id, table_name)
    nfields, = h5tb_get_table_info(loc_id, table_name)
    field_sizes = Vector{Csize_t}(undef, nfields)
    field_offsets = Vector{Csize_t}(undef, nfields)
    type_size = Ref{Csize_t}()
    # pass C_NULL to field_names argument since libhdf5 does not provide a way to determine if the
    # allocated buffer is the correct length, which is thus susceptible to a buffer overflow if
    # an incorrect buffer length is passed. Instead, we manually compute the column names using the
    # same calls that h5tb_get_field_info internally uses.
    h5tb_get_field_info(loc_id, table_name, C_NULL, field_sizes, field_offsets, type_size)
    did = h5d_open(loc_id, table_name, H5P_DEFAULT)
    tid = h5d_get_type(did)
    h5d_close(did)
    field_names = [h5t_get_member_name(tid, i-1) for i in 1:nfields]
    h5t_close(tid)
    return field_names, field_sizes, field_offsets, type_size[]
end

###
### Filter Interface
###
