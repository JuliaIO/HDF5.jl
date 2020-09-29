# This file is a companion to `src/api.jl` --- it defines the raw ccall wrappers, while
# here small normalizations are made to make the calls more Julian.
# For instance, many property getters return values through pointer output arguments,
# so the methods here handle making the appropriate `Ref`s and return them (as tuples).

# Some things to keep in mind when adding a wrapper:
#   - The low-level ccall wrappers all have untyped arguments, so these function should
#     generally as well; instead, these methods are (typically) distinguished only by
#     having fewer arguments.

###
### HDF5 General library functions
###

###
### Attribute Interface
###

###
### Dataset Interface
###

###
### Error Interface
###

###
### File Interface
###

###
### Group Interface
###

###
### Identifier Interface
###

###
### Link Interface
###

###
### Object Interface
###

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

function h5p_get_dxpl_mpio(dxpl_id::hid_t)
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

###
### Datatype Interface
###

###
### Optimized Functions Interface
###

###
### HDF5 Lite Interface
###

###
### Table Interface
###

###
### Filter Interface
###

