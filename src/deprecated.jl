import Base: @deprecate, @deprecate_binding, depwarn

###
### v0.15 deprecations
###

### Add empty exists method for JLD,MAT to extend to smooth over deprecation process PR#790
export exists
function exists end

### Changed in PR#776
@deprecate create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace,
    lcpl::Properties, dcpl::Properties, dapl::Properties, dxpl::Properties) HDF5.Dataset(HDF5.API.h5d_create(parent, path, dtype, dspace, lcpl, dcpl, dapl), HDF5.file(parent), dxpl) false

### Changed in PR#798
@deprecate get_dims(dspace::Union{Dataspace,Dataset,Attribute}) get_extent_dims(dspace) false
@deprecate set_dims!(dset::Dataspace) set_extent_dims(dset) false

### Changed in PR #844
@deprecate silence_errors(f::Function) f()

### Changed in PR #845
@deprecate h5d_read_chunk(dataset_id, offset, buf::Vector{UInt8} = Vector{UInt8}(undef, get_chunk_length(dataset_id)); kwargs...) read_chunk(dataset_id, offset, buf; kwargs...) false
@deprecate h5d_read_chunk(dataset_id, dxpl_id, offset) read_chunk(dataset_id, offset; dxpl_id = dxpl_id) false
@deprecate h5d_read_chunk(dataset_id, dxpl_id, offset, buf::Vector{UInt8}) read_chunk(dataset_id, offset, buf; dxpl_id = dxpl_id) false

@deprecate h5d_read_chunk(dataset_id, index::Integer, buf::Vector{UInt8} = Vector{UInt8}(undef, get_chunk_length(dataset_id)); kwargs...) read_chunk(dataset_id, index, buf; kwargs...) false
@deprecate h5d_read_chunk(dataset_id, dxpl_id, index::Integer) read_chunk(dataset_id, index; dxpl_id = dxpl_id) false
@deprecate h5d_read_chunk(dataset_id, dxpl_id, index::Integer, buf::Vector{UInt8}) read_chunk(dataset_id, index, buf; dxpl_id = dxpl_id) false

@deprecate h5d_write_chunk(dataset_id, offset, buf::Vector{UInt8}; kwargs...) write_chunk(dataset_id, offset, buf; kwargs...) false
@deprecate h5d_write_chunk(dataset_id, dxpl_id, filter_mask, offset, buf::Vector{UInt8}) write_chunk(dataset_id, offset, buf; dxpl_id = dxpl_id, filter_mask = filter_mask) false

@deprecate h5d_write_chunk(dataset_id, index::Integer, buf::Vector{UInt8}; kwargs...) write_chunk(dataset_id, index, buf; kwargs...)  false
@deprecate h5d_write_chunk(dataset_id, dxpl_id, filter_mask, index::Integer, buf::Vector{UInt8}) write_chunk(dataset_id, index, buf; dxpl_id = dxpl_id, filter_mask = filter_mask) false

for name in names(API; all=true)
    if name ∉ names(HDF5; all=true) && startswith(uppercase(String(name)), "H")
        depmsg = ", use HDF5.API.$name instead."
        @eval Base.@deprecate_binding $name API.$name false $depmsg
    end
end
