
# Link to bytes in an external file
# If you need to link to multiple segments, use low-level interface
function create_external_dataset(parent::Union{File,Group}, name::AbstractString, filepath::AbstractString, t, sz::Dims, offset::Integer=0)
    checkvalid(parent)
    dcpl_external  = (filepath, offset, prod(sz)*sizeof(t)) # TODO: allow H5F_UNLIMITED
    create_dataset(parent, name, datatype(t), dataspace(sz); external=dcpl_external)
end

function do_write_chunk(dataset::Dataset, offset, chunk_bytes::Vector{UInt8}, filter_mask=0)
    checkvalid(dataset)
    offs = collect(API.hsize_t, reverse(offset)) .- 1
    API.h5do_write_chunk(dataset, API.H5P_DEFAULT, UInt32(filter_mask), offs, length(chunk_bytes), chunk_bytes)
end

struct ChunkStorage
    dataset::Dataset
end

function Base.setindex!(chunk_storage::ChunkStorage, v::Tuple{<:Integer,Vector{UInt8}}, index::Integer...)
    do_write_chunk(chunk_storage.dataset, API.hsize_t.(index), v[2], UInt32(v[1]))
end
