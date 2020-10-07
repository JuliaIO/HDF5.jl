import Base: @deprecate, @deprecate_binding, depwarn

### Changed in PR#629
# - HDF5.Dataset.xfer from ::hid_t to ::HDF5.Properties
@deprecate h5d_read(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::Properties) h5d_read(dataset_id, memtype_id, buf, xfer.id) false
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::Properties) h5d_write(dataset_id, memtype_id, buf, xfer.id) false
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, str::String, xfer::Properties) h5d_write(dataset_id, memtype_id, str, xfer.id) false
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, x::T, xfer::Properties) where {T<:Union{ScalarType, Complex{<:ScalarType}}} h5d_write(dataset_id, memtype_id, x, xfer.id) false
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, strs::Array{S}, xfer::Properties) where {S<:String} h5d_write(dataset_id, memtype_id, strs, xfer.id) false
@deprecate h5d_write(dataset_id::hid_t, memtype_id::hid_t, v::VLen{T}, xfer::Properties) where {T<:Union{ScalarType,CharType}} h5d_write(dataset_id, memtype_id, v, xfer.id) false
# - p_create lost toclose argument
@deprecate p_create(class, toclose::Bool, pv...) p_create(class, pv...)

### Changed in PR#632
# - using symbols instead of strings for property keys
@deprecate setindex!(p::Properties, val, name::String) setindex!(p, val, Symbol(name))

function getindex(parent::Union{File,Group}, path::String, prop1::String, val1, pv...)
    depwarn("getindex(::Union{HDF5.File, HDF5.Group}, path, props...) with string key and value argument pairs is deprecated. Use keywords instead.", :getindex)
    props = (prop1, val1, pv...)
    return getindex(parent, path; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function setindex!(parent::Union{File,Group}, val, path::String, prop1::String, val1, pv...)
    depwarn("setindex!(::Union{HDF5.File, HDF5.Group}, val, path, props...) with string key and value argument pairs is deprecated. Use keywords instead.", :setindex!)
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
function d_create(parent::Union{File,Group}, path::String, dtype::Datatype, dspace::D, prop1::String, val1, pv...) where D <: Union{Dataspace, Dims, Tuple{Dims,Dims}}
    depwarn("d_create with string key and value argument pairs is deprecated. Use keywords instead.", :d_create)
    props = (prop1, val1, pv...)
    return d_create(parent, path, dtype, dspace; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function d_create(parent::Union{File,Group}, path::String, dtype::Type, dspace, prop1::String, val1, pv...)
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
function __d_create(parent::Union{File, Group}, path::String, dtype::Datatype,
                   dspace::Dataspace, lcpl::Properties,
                   dcpl::Properties = DEFAULT_PROPERTIES,
                   dapl::Properties = DEFAULT_PROPERTIES,
                   dxpl::Properties = DEFAULT_PROPERTIES)
    d_create(parent, path, dtype, dspace, lcpl, dcpl, dapl, dxpl)
end
# a_create doesn't take property lists, so just bind the helper name directly
const __a_create = a_create

for (fsym, ptype) in ((:d_create, Union{File, Group}),
                      (:a_create, Union{File, Object}),
                     )
    privsym = Symbol(:_, fsym)
    chainsym = Symbol(:__, fsym)
    depsig = "$fsym(parent::$ptype, name::String, data, plists::HDF5Properties...)"
    usesig = "$fsym(parent::$ptype, name::String, data; properties...)"
    warnstr = "`$depsig` with property lists is deprecated, use `$usesig` with keywords instead"
    @eval begin
        function ($privsym)(parent::$ptype, name::String, data, plists::Properties...)
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
        ($fsym)(parent::$ptype, name::String, data::Union{T,AbstractArray{T}},
                plists::Properties...) where {T<:Union{ScalarType,String,Complex{<:ScalarType}}} =
            ($privsym)(parent, name, data, plists...)
        ($fsym)(parent::$ptype, name::String, data::VLen{T},
                plists::Properties...) where {T<:Union{ScalarType,CharType}} =
            ($privsym)(parent, name, data, plists...)
    end
end
for (fsym, ptype) in ((:d_write, Union{File,Group}),
                      (:a_write, Union{File,Object}),
                     )
    privsym = Symbol(:_, fsym)
    crsym = Symbol(:__, replace(string(fsym), "write" => "create"))
    depsig = "$fsym(parent::$ptype, name::String, data, plists::HDF5Properties...)"
    usesig = "$fsym(parent::$ptype, name::String, data; properties...)"
    warnstr = "`$depsig` with property lists is deprecated, use `$usesig` with keywords instead"
    @eval begin
        function ($privsym)(parent::$ptype, name::String, data, plists::Properties...)
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
        ($fsym)(parent::$ptype, name::String, data::Union{T,AbstractArray{T}},
                plists::Properties...) where {T<:Union{ScalarType,String,Complex{<:ScalarType}}} =
            ($privsym)(parent, name, data, plists...)
        ($fsym)(parent::$ptype, name::String, data::VLen{T},
                plists::Properties...) where {T<:Union{ScalarType,CharType}} =
            ($privsym)(parent, name, data, plists...)
    end
end
function write(parent::Union{File,Group}, name::String, data::Union{T,AbstractArray{T}},
               plists::Properties...) where {T<:Union{ScalarType,String,Complex{<:ScalarType}}}
    depwarn("`write(parent::Union{HDF5.File, HDF5.Group}, name::String, data, plists::HDF5Properties...)` " *
            "with property lists is deprecated, use " *
            "`write(parent::Union{HDF5.File, HDF5.Group}, name::String, data; properties...)` " *
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
function write(parent::Dataset, name::String, data::Union{T,AbstractArray{T}},
               plists::Properties...) where {T<:ScalarType,String}
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
@deprecate_binding h5f_get_intend h5f_get_intent false
@deprecate_binding hf5start_swmr_write h5f_start_swmr_write false
@deprecate_binding h5d_oappend h5do_append false

### Changed in PR#678
# - normalized constants names to C definitions
@deprecate_binding Haddr haddr_t false
@deprecate_binding Herr herr_t false
@deprecate_binding Hid hid_t false
@deprecate_binding Hsize hsize_t false
@deprecate_binding Hssize hssize_t false
@deprecate_binding Htri htri_t false
@deprecate_binding Hvl_t hvl_t false

### Changed in PR#688
# - normalized more C type names
@deprecate_binding H5Ginfo H5G_info_t false
@deprecate_binding H5LInfo H5L_info_t false
@deprecate_binding H5Oinfo H5O_info_t false

### Changed in PR#689
# - switch from H5Rdereference1 to H5Rdereference2
@deprecate h5r_dereference(obj_id, ref_type, ref) h5r_dereference(obj_id, H5P_DEFAULT, ref_type, ref) false

### Changed in PR#690, PR#695
# - rename exported bindings
# - remove exports in > v0.14
@deprecate_binding HDF5Attribute HDF5.Attribute
@deprecate_binding HDF5File HDF5.File
@deprecate_binding HDF5Group HDF5.Group
@deprecate_binding HDF5Dataset HDF5.Dataset
@deprecate_binding HDF5Datatype HDF5.Datatype
@deprecate_binding HDF5Dataspace HDF5.Dataspace
@deprecate_binding HDF5Object HDF5.Object
@deprecate_binding HDF5Properties HDF5.Properties
@deprecate_binding HDF5Vlen HDF5.VLen
@deprecate_binding HDF5ChunkStorage HDF5.ChunkStorage
@deprecate_binding HDF5ReferenceObj HDF5.Reference false
@deprecate_binding HDF5Opaque HDF5.Opaque false

### Changed in PR#691
# - Make Reference() construct a null reference
@deprecate_binding HDF5ReferenceObj_NULL HDF5.Reference() false

### Changed in PR#693
@deprecate_binding ScalarOrString Union{ScalarType,String} false
@deprecate_binding HDF5Scalar ScalarType false
@deprecate_binding HDF5BitsKind BitsType false

### Changed in PR#695
@deprecate names(x::Union{Group,File,Attributes}) keys(x)

### Changed in PR#694
@deprecate has(parent::Union{File,Group,Dataset}, path::String) Base.haskey(parent, path)
@deprecate exists(parent::Union{File,Group,Dataset,Datatype,Attributes}, path::String) Base.haskey(parent, path) false
