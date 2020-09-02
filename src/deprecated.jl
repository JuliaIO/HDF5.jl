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

### Changed in PR#632
# - using symbols instead of strings for property keys
@deprecate setindex!(p::HDF5Properties, val, name::String) setindex!(p, val, Symbol(name))

function getindex(parent::Union{HDF5File, HDF5Group}, path::String, prop1::String, val1, pv...)
    depwarn("getindex(::Union{HDF5File, HDF5Group}, path, props...) with string key and value argument pairs is deprecated. Use keywords instead.", :getindex)
    props = (prop1, val1, pv...)
    return getindex(parent, path; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function setindex!(parent::Union{HDF5File, HDF5Group}, val, path::String, prop1::String, val1, pv...)
    depwarn("setindex!(::Union{HDF5File, HDF5Group}, val, path, props...) with string key and value argument pairs is deprecated. Use keywords instead.", :setindex!)
    props = (prop1, val1, pv...)
    return setindex!(parent, val, path; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end

function h5open(filename::AbstractString, mode::AbstractString, pv...; kws...)
    depwarn("h5open with string key and value argument pairs is deprecated. Use keywords instead.", :h5open)
    return h5open(filename, mode; kws..., [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function h5write(filename, name::String, data, pv...)
    depwarn("h5write with string key and value argument pairs is deprecated. Use keywords instead.", :h5write)
    return h5write(filename, name, data; [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function h5read(filename, name::String, pv...)
    depwarn("h5read with string key and value argument pairs is deprecated. Use keywords instead.", :h5read)
    return h5read(filename, name; [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function h5read(filename, name::String, indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}}, pv...)
    depwarn("h5read with string key and value argument pairs is deprecated. Use keywords instead.", :h5read)
    return h5read(filename, name, indices; [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype, dspace::D, prop1::String, val1, pv...) where D <: Union{HDF5Dataspace, Dims, Tuple{Dims,Dims}}
    depwarn("d_create with string key and value argument pairs is deprecated. Use keywords instead.", :d_create)
    props = (prop1, val1, pv...)
    return d_create(parent, path, dtype, dspace; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::Type, dspace, prop1::String, val1, pv...)
    depwarn("d_create with string key and value argument pairs is deprecated. Use keywords instead.", :d_create)
    props = (prop1, val1, pv...)
    return d_create(parent, path, dtype, dspace; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function p_create(class, prop1::String, val1, pv...)
    depwarn("p_create with string key and value argument pairs is deprecated. Use keywords instead.", :p_create)
    props = (prop1, val1, pv...)
    return p_create(class; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
