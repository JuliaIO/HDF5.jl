import Base: @deprecate, depwarn

### Changed in PR#629
# - HDF5Dataset.xfer from ::Hid to ::HDF5Properties
@deprecate h5d_read(dataset_id::Hid, memtype_id::Hid, buf::AbstractArray, xfer::HDF5Properties) h5d_read(dataset_id, memtype_id, buf, xfer.id)
@deprecate h5d_write(dataset_id::Hid, memtype_id::Hid, buf::AbstractArray, xfer::HDF5Properties) h5d_write(dataset_id, memtype_id, buf, xfer.id)
@deprecate h5d_write(dataset_id::Hid, memtype_id::Hid, str::String, xfer::HDF5Properties) h5d_write(dataset_id, memtype_id, str, xfer.id)
@deprecate h5d_write(dataset_id::Hid, memtype_id::Hid, x::T, xfer::HDF5Properties) where {T<:Union{HDF5Scalar, Complex{<:HDF5Scalar}}} h5d_write(dataset_id, memtype_id, x, xfer.id)
@deprecate h5d_write(dataset_id::Hid, memtype_id::Hid, strs::Array{S}, xfer::HDF5Properties) where {S<:String} h5d_write(dataset_id, memtype_id, strs, xfer.id)
@deprecate h5d_write(dataset_id::Hid, memtype_id::Hid, v::HDF5Vlen{T}, xfer::HDF5Properties) where {T<:Union{HDF5Scalar,CharType}} h5d_write(dataset_id, memtype_id, v, xfer.id)
# - p_create lost toclose argument
@deprecate p_create(class, toclose::Bool, pv...) p_create(class, pv...)
