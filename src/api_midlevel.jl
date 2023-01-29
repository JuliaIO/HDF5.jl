# This file defines midlevel api wrappers. We include name normalization for methods that are
# applicable to different hdf5 api-layers. We still try to adhere close proximity to the underlying
# method name in the hdf5-library.

"""
    HDF5.set_extent_dims(dset::HDF5.Dataset, new_dims::Dims)

Change the current dimensions of a dataset to `new_dims`, limited by
`max_dims = get_extent_dims(dset)[2]`. Reduction is possible and leads to loss of truncated data.
"""
function set_extent_dims(dset::Dataset, size::Dims)
    checkvalid(dset)
    API.h5d_set_extent(dset, API.hsize_t[reverse(size)...])
end

"""
    HDF5.set_extent_dims(dspace::HDF5.Dataspace, new_dims::Dims, max_dims::Union{Dims,Nothing} = nothing)

Change the dimensions of a dataspace `dspace` to `new_dims`, optionally with the maximum possible
dimensions `max_dims` different from the active size `new_dims`. If not given, `max_dims` is set equal
to `new_dims`.
"""
function set_extent_dims(
    dspace::Dataspace, size::Dims, max_dims::Union{Dims,Nothing}=nothing
)
    checkvalid(dspace)
    rank = length(size)
    current_size = API.hsize_t[reverse(size)...]
    maximum_size = isnothing(max_dims) ? C_NULL : [reverse(max_dims .% API.hsize_t)...]
    API.h5s_set_extent_simple(dspace, rank, current_size, maximum_size)
    return nothing
end

"""
    HDF5.get_extent_dims(obj::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute}) -> dims, maxdims

Get the array dimensions from a dataspace, dataset, or attribute and return a tuple of `dims` and `maxdims`.
"""
function get_extent_dims(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    h5_dims, h5_maxdims = API.h5s_get_simple_extent_dims(dspace)
    # reverse dimensions since hdf5 uses C-style order
    N = length(h5_dims)
    dims = ntuple(i -> @inbounds(Int(h5_dims[N - i + 1])), N)
    maxdims = ntuple(i -> @inbounds(h5_maxdims[N - i + 1]) % Int, N) # allows max_dims to be specified as -1 without triggering an overflow
    obj isa Dataspace || close(dspace)
    return dims, maxdims
end

"""
    HDF5.get_chunk_offset(dataset_id, index)

Get 0-based offset of chunk from 0-based `index`. The offsets are returned in Julia's column-major order rather than hdf5 row-major order.
For a 1-based API, see `HDF5.ChunkStorage`.
"""
function get_chunk_offset(dataset_id, index)
    extent = size(dataset_id)
    chunk = get_chunk(dataset_id)
    chunk_indices = CartesianIndices(
        ntuple(i -> 0:(cld(extent[i], chunk[i]) - 1), length(extent))
    )
    offset = API.hsize_t.(chunk_indices[index + 1].I .* chunk)
    return offset
end

"""
    HDF5.get_chunk_index(dataset_id, offset)

Get 0-based index of chunk from 0-based `offset` returned in Julia's column-major order.
For a 1-based API, see `HDF5.ChunkStorage`.
"""
function get_chunk_index(dataset_id, offset)
    extent = size(dataset_id)
    chunk = get_chunk(dataset_id)
    chunk_indices = LinearIndices(
        ntuple(i -> 0:(cld(extent[i], chunk[i]) - 1), length(extent))
    )
    chunk_indices[(fld.(offset, chunk) .+ 1)...] - 1
end

"""
    HDF5.get_num_chunks_per_dim(dataset_id)

Get the number of chunks in each dimension in Julia's column-major order.
"""
function get_num_chunks_per_dim(dataset_id)
    extent = size(dataset_id)
    chunk = get_chunk(dataset_id)
    return cld.(extent, chunk)
end

"""
    HDF5.get_num_chunks(dataset_id)

Returns the number of chunks in a dataset. Equivalent to `API.h5d_get_num_chunks(dataset_id, HDF5.H5S_ALL)`.
"""
function get_num_chunks(dataset_id)
    @static if v"1.10.5" ≤ API._libhdf5_build_ver
        API.h5d_get_num_chunks(dataset_id)
    else
        prod(get_num_chunks_per_dim(dataset_id))
    end
end

"""
    HDF5.get_chunk_length(dataset_id)

Retrieves the chunk size in bytes. Equivalent to `API.h5d_get_chunk_info(dataset_id, index)[:size]`.
"""
function get_chunk_length(dataset_id)
    type = API.h5d_get_type(dataset_id)
    chunk = get_chunk(dataset_id)
    return Int(API.h5t_get_size(type) * prod(chunk))
end

vlen_get_buf_size(dset::Dataset, dtype::Datatype, dspace::Dataspace) =
    API.h5d_vlen_get_buf_size(dset, dtype, dspace)
function vlen_get_buf_size(dataset_id)
    type = API.h5d_get_type(dataset_id)
    space = API.h5d_get_space(dataset_id)
    API.h5d_vlen_get_buf_size(dataset_id, type, space)
end

"""
    HDF5.read_chunk(dataset_id, offset, [buf]; dxpl_id = HDF5.API.H5P_DEFAULT, filters = Ref{UInt32}())

Helper method to read chunks via 0-based offsets in a `Tuple`.

Argument `buf` is optional and defaults to a `Vector{UInt8}` of length determined by `HDF5.get_chunk_length`.
Argument `dxpl_id` can be supplied a keyword and defaults to `HDF5.API.H5P_DEFAULT`.
Argument `filters` can be retrieved by supplying a `Ref{UInt32}` value via a keyword argument.

This method returns `Vector{UInt8}`.
"""
function read_chunk(
    dataset_id,
    offset,
    buf::Vector{UInt8}=Vector{UInt8}(undef, get_chunk_length(dataset_id));
    dxpl_id=API.H5P_DEFAULT,
    filters=Ref{UInt32}()
)
    API.h5d_read_chunk(dataset_id, dxpl_id, offset, filters, buf)
    return buf
end

"""
    HDF5.read_chunk(dataset_id, index::Integer, [buf]; dxpl_id = HDF5.API.H5P_DEFAULT, filters = Ref{UInt32}())

Helper method to read chunks via 0-based integer `index`.

Argument `buf` is optional and defaults to a `Vector{UInt8}` of length determined by `HDF5.API.h5d_get_chunk_info`.
Argument `dxpl_id` can be supplied a keyword and defaults to `HDF5.API.H5P_DEFAULT`.
Argument `filters` can be retrieved by supplying a `Ref{UInt32}` value via a keyword argument.

This method returns `Vector{UInt8}`.
"""
function read_chunk(
    dataset_id,
    index::Integer,
    buf::Vector{UInt8}=Vector{UInt8}(undef, get_chunk_length(dataset_id));
    dxpl_id=API.H5P_DEFAULT,
    filters=Ref{UInt32}()
)
    offset = [reverse(get_chunk_offset(dataset_id, index))...]
    read_chunk(dataset_id, offset, buf; dxpl_id=dxpl_id, filters=filters)
end

"""
    HDF5.write_chunk(dataset_id, offset, buf::AbstractArray; dxpl_id = HDF5.API.H5P_DEFAULT, filter_mask = 0)

Helper method to write chunks via 0-based offsets `offset` as a `Tuple`.
"""
function write_chunk(
    dataset_id, offset, buf::AbstractArray; dxpl_id=API.H5P_DEFAULT, filter_mask=0
)
    # Borrowed from write_dataset stride detection
    stride(buf, 1) == 1 ||
        throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    API.h5d_write_chunk(dataset_id, dxpl_id, filter_mask, offset, sizeof(buf), buf)
end

function write_chunk(
    dataset_id,
    offset,
    buf::Union{DenseArray,Base.FastContiguousSubArray};
    dxpl_id=API.H5P_DEFAULT,
    filter_mask=0
)
    # We can bypass the need to check stride with Array and FastContiguousSubArray
    API.h5d_write_chunk(dataset_id, dxpl_id, filter_mask, offset, sizeof(buf), buf)
end

"""
    HDF5.write_chunk(dataset_id, index::Integer, buf::AbstractArray; dxpl_id = API.H5P_DEFAULT, filter_mask = 0)

Helper method to write chunks via 0-based integer `index`.
"""
function write_chunk(
    dataset_id, index::Integer, buf::AbstractArray; dxpl_id=API.H5P_DEFAULT, filter_mask=0
)
    offset = [reverse(get_chunk_offset(dataset_id, index))...]
    write_chunk(dataset_id, offset, buf; dxpl_id=dxpl_id, filter_mask=filter_mask)
end

# Avoid ambiguous method with offset based versions
function write_chunk(
    dataset_id,
    index::Integer,
    buf::Union{DenseArray,Base.FastContiguousSubArray};
    dxpl_id=API.H5P_DEFAULT,
    filter_mask=0
)
    # We can bypass the need to check stride with Array and FastContiguousSubArray
    offset = [reverse(get_chunk_offset(dataset_id, index))...]
    write_chunk(dataset_id, offset, buf; dxpl_id=dxpl_id, filter_mask=filter_mask)
end

function get_fill_value(plist_id, ::Type{T}) where {T}
    value = Ref{T}()
    API.h5p_get_fill_value(plist_id, datatype(T), value)
    return value[]
end

get_fill_value(plist_id) = get_fill_value(plist_id, Float64)

function set_fill_value!(plist_id, value)
    ref_value = Ref(value)
    API.h5p_set_fill_value(plist_id, datatype(value), ref_value)
    return plist_id
end
