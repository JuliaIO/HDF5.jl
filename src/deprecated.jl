import Base: @deprecate, @deprecate_binding, depwarn

### Changed in PR#629
# - HDF5Dataset.xfer from ::hid_t to ::HDF5Properties
@deprecate h5d_read(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::HDF5Properties) h5d_read(dataset_id, memtype_id, buf, xfer.id)
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::HDF5Properties) h5d_write(dataset_id, memtype_id, buf, xfer.id)
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, str::String, xfer::HDF5Properties) h5d_write(dataset_id, memtype_id, str, xfer.id)
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, x::T, xfer::HDF5Properties) where {T<:Union{HDF5Scalar, Complex{<:HDF5Scalar}}} h5d_write(dataset_id, memtype_id, x, xfer.id)
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, strs::Array{S}, xfer::HDF5Properties) where {S<:String} h5d_write(dataset_id, memtype_id, strs, xfer.id)
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, v::HDF5Vlen{T}, xfer::HDF5Properties) where {T<:Union{HDF5Scalar,CharType}} h5d_write(dataset_id, memtype_id, v, xfer.id)
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

### Changed in PR#652
# - read takes array element type, not Array with eltype
@deprecate read(obj::DatasetOrAttribute, ::Type{A}, I...) where {A<:Array} read(obj, eltype(A), I...)

### Changed in PR#657
# - using keywords instead of HDF5Properties objects

# deprecation helpers to avoid having default values on the equivalent low-level
# constructors in HDF5.jl
function __d_create(parent::Union{HDF5File, HDF5Group}, path::String, dtype::HDF5Datatype,
                   dspace::HDF5Dataspace, lcpl::HDF5Properties,
                   dcpl::HDF5Properties = DEFAULT_PROPERTIES,
                   dapl::HDF5Properties = DEFAULT_PROPERTIES,
                   dxpl::HDF5Properties = DEFAULT_PROPERTIES)
    d_create(parent, path, dtype, dspace, lcpl, dcpl, dapl, dxpl)
end
# a_create doesn't take property lists, so just bind the helper name directly
const __a_create = a_create

for (fsym, ptype) in ((:d_create, Union{HDF5File, HDF5Group}),
                      (:a_create, Union{HDF5File, HDF5Object}),
                     )
    privsym = Symbol(:_, fsym)
    chainsym = Symbol(:__, fsym)
    depsig = "$fsym(parent::$ptype, name::String, data, plists::HDF5Properties...)"
    usesig = "$fsym(parent::$ptype, name::String, data; properties...)"
    warnstr = "`$depsig` with property lists is deprecated, use `$usesig` with keywords instead"
    @eval begin
        function ($privsym)(parent::$ptype, name::String, data, plists::HDF5Properties...)
            depwarn($warnstr, $(QuoteNode(fsym)))
            local obj
            dtype = datatype(data)
            dspace = dataspace(data)
            try
                obj = ($chainsym)(parent, name, dtype, dspace, plists...)
            finally
                close(dspace)
            end
            return obj, dtype
        end
        ($fsym)(parent::$ptype, name::String, data::Union{T, AbstractArray{T}},
                plists::HDF5Properties...) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}} =
            ($privsym)(parent, name, data, plists...)
        ($fsym)(parent::$ptype, name::String, data::HDF5Vlen{T},
                plists::HDF5Properties...) where {T<:Union{HDF5Scalar,CharType}} =
            ($privsym)(parent, name, data, plists...)
    end
end
for (fsym, ptype) in ((:d_write, Union{HDF5File, HDF5Group}),
                      (:a_write, Union{HDF5File, HDF5Object}),
                     )
    privsym = Symbol(:_, fsym)
    crsym = Symbol(:__, replace(string(fsym), "write" => "create"))
    depsig = "$fsym(parent::$ptype, name::String, data, plists::HDF5Properties...)"
    usesig = "$fsym(parent::$ptype, name::String, data; properties...)"
    warnstr = "`$depsig` with property lists is deprecated, use `$usesig` with keywords instead"
    @eval begin
        function ($privsym)(parent::$ptype, name::String, data, plists::HDF5Properties...)
            depwarn($warnstr, $(QuoteNode(fsym)))
            dtype = datatype(data)
            obj = ($crsym)(parent, name, dtype, dataspace(data), plists...)
            try
                writearray(obj, dtype.id, data)
            finally
                close(obj)
                close(dtype)
            end
        end
        ($fsym)(parent::$ptype, name::String, data::Union{T, AbstractArray{T}},
                plists::HDF5Properties...) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}} =
            ($privsym)(parent, name, data, plists...)
        ($fsym)(parent::$ptype, name::String, data::HDF5Vlen{T},
                plists::HDF5Properties...) where {T<:Union{HDF5Scalar,CharType}} =
            ($privsym)(parent, name, data, plists...)
    end
end
function write(parent::Union{HDF5File, HDF5Group}, name::String, data::Union{T, AbstractArray{T}},
               plists::HDF5Properties...) where {T<:Union{ScalarOrString, Complex{<:HDF5Scalar}}}
    depwarn("`write(parent::Union{HDF5File, HDF5Group}, name::String, data, plists::HDF5Properties...)` " *
            "with property lists is deprecated, use " *
            "`write(parent::Union{HDF5File, HDF5Group}, name::String, data; properties...)` " *
            "with keywords instead.", :write)
    # We avoid using the d_write method to prevent double deprecation warnings.
    dtype = datatype(data)
    obj = __d_create(parent, name, dtype, dataspace(data), plists...)
    try
        writearray(obj, dtype.id, data)
    finally
        close(obj)
        close(dtype)
    end
end
function write(parent::HDF5Dataset, name::String, data::Union{T, AbstractArray{T}},
               plists::HDF5Properties...) where {T<:ScalarOrString}
    depwarn("`write(parent::HDF5Dataset, name::String, data, plists::HDF5Properties...)` " *
            "with property lists is deprecated, use " *
            "`write(parent::HDF5Dataset, name::String, data; properties...)` " *
            "with keywords instead.", :write)
    # We avoid using the a_write method to prevent double deprecation warnings.
    dtype = datatype(data)
    obj = __a_create(parent, name, dtype, dataspace(data), plists...)
    try
        writearray(obj, dtype.id, data)
    finally
        close(obj)
        close(dtype)
    end
end

### Changed in PR#664
# - normalized naming of C function wrappers
@deprecate_binding h5f_get_intend h5f_get_intent
@deprecate_binding hf5start_swmr_write h5f_start_swmr_write
@deprecate_binding h5d_oappend h5do_append

### Changed in PR#678
# - normalized constants names to C definitions
@deprecate_binding Haddr haddr_t
@deprecate_binding Herr herr_t
@deprecate_binding Hid hid_t
@deprecate_binding Hsize hsize_t
@deprecate_binding Hssize hssize_t
@deprecate_binding Htri htri_t
@deprecate_binding Hvl_t hvl_t

### Changed in PR#688
# - normalized more C type names
@deprecate_binding H5Oinfo H5O_info_t
