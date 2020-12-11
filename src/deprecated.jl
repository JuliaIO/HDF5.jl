import Base: @deprecate, @deprecate_binding, depwarn

### Changed in PR#629
# - HDF5.Dataset.xfer from ::hid_t to ::HDF5.Properties
# - PR#723 deprecates these functions completely, so deprecations are not emitted here ---
#   just pass through to those deprecations to avoid double warnings.
function h5d_read(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::Properties)
    h5d_read(dataset_id, memtype_id, buf, xfer.id)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::Properties)
    h5d_write(dataset_id, memtype_id, buf, xfer.id)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, str::AbstractString, xfer::Properties)
    h5d_write(dataset_id, memtype_id, str, xfer.id)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, x::T, xfer::Properties) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    h5d_write(dataset_id, memtype_id, x, xfer.id)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, strs::Array{S}, xfer::Properties) where {S<:AbstractString}
    h5d_write(dataset_id, memtype_id, strs, xfer.id)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, v::VLen{T}, xfer::Properties) where {T<:Union{ScalarType,CharType}}
    h5d_write(dataset_id, memtype_id, v, xfer.id)
end
# - create_property lost toclose argument
@deprecate p_create(class, toclose::Bool, pv...) create_property(class, pv...)

### Changed in PR#632
# - using symbols instead of strings for property keys
import Base: setindex!
@deprecate setindex!(p::Properties, val, name::AbstractString) setindex!(p, val, Symbol(name))

function Base.getindex(parent::Union{File,Group}, path::AbstractString, prop1::AbstractString, val1, pv...)
    depwarn("getindex(::Union{HDF5.File, HDF5.Group}, path, props...) with string key and value argument pairs is deprecated. Use keywords instead.", :getindex)
    props = (prop1, val1, pv...)
    return getindex(parent, path; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function Base.setindex!(parent::Union{File,Group}, val, path::AbstractString, prop1::AbstractString, val1, pv...)
    depwarn("setindex!(::Union{HDF5.File, HDF5.Group}, val, path, props...) with string key and value argument pairs is deprecated. Use keywords instead.", :setindex!)
    props = (prop1, val1, pv...)
    return setindex!(parent, val, path; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end

function h5open(filename::AbstractString, mode::AbstractString, pv...; kws...)
    depwarn("h5open with string key and value argument pairs is deprecated. Use keywords instead.", :h5open)
    return h5open(filename, mode; kws..., [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function h5write(filename, name::AbstractString, data, pv...)
    depwarn("h5write with string key and value argument pairs is deprecated. Use keywords instead.", :h5write)
    return h5write(filename, name, data; [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function h5read(filename, name::AbstractString, pv...)
    depwarn("h5read with string key and value argument pairs is deprecated. Use keywords instead.", :h5read)
    return h5read(filename, name; [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function h5read(filename, name::AbstractString, indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}}, pv...)
    depwarn("h5read with string key and value argument pairs is deprecated. Use keywords instead.", :h5read)
    return h5read(filename, name, indices; [Symbol(pv[i]) => pv[i+1] for i in 1:2:length(pv)]...)
end
function d_create(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::D, prop1::AbstractString, val1, pv...) where D <: Union{Dataspace, Dims, Tuple{Dims,Dims}}
    depwarn("d_create with string key and value argument pairs is deprecated. Use create_dataset with keywords instead.", :d_create)
    props = (prop1, val1, pv...)
    return create_dataset(parent, path, dtype, dspace; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function d_create(parent::Union{File,Group}, path::AbstractString, dtype::Type, dspace, prop1::AbstractString, val1, pv...)
    depwarn("d_create with string key and value argument pairs is deprecated. Use create_dataset with keywords instead.", :create_dataset)
    props = (prop1, val1, pv...)
    return create_dataset(parent, path, dtype, dspace; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end
function p_create(class, prop1::AbstractString, val1, pv...)
    depwarn("p_create with string key and value argument pairs is deprecated. Use create_property keywords instead.", :create_property)
    props = (prop1, val1, pv...)
    return create_property(class; [Symbol(props[i]) => props[i+1] for i in 1:2:length(props)]...)
end

### Changed in PR#652
# - read takes array element type, not Array with eltype
import Base: read
@deprecate read(obj::DatasetOrAttribute, ::Type{A}, I...) where {A<:Array} read(obj, eltype(A), I...)

### Changed in PR#657
# - using keywords instead of HDF5Properties objects

# deprecation helpers to avoid having default values on the equivalent low-level
# constructors in HDF5.jl
function __d_create(parent::Union{File, Group}, path::AbstractString, dtype::Datatype,
                   dspace::Dataspace, lcpl::Properties,
                   dcpl::Properties = DEFAULT_PROPERTIES,
                   dapl::Properties = DEFAULT_PROPERTIES,
                   dxpl::Properties = DEFAULT_PROPERTIES)
    create_dataset(parent, path, dtype, dspace, lcpl, dcpl, dapl, dxpl)
end
# create_attribute doesn't take property lists, so just bind the helper name directly
const __a_create = create_attribute

for (fsym, fnewsym, ptype) in ((:d_create, :create_dataset, Union{File, Group}),
                      (:a_create, :create_attribute, Union{File, Object}),
                     )
    chainsym = Symbol(:__, fsym)
    depsig = "$fsym(parent::$ptype, name::AbstractString, data, plists::HDF5Properties...)"
    usesig = "$fnewsym(parent::$ptype, name::AbstractString, data; properties...)"
    warnstr = "`$depsig` with property lists is deprecated, use `$usesig` with keywords instead"
    @eval begin
        function ($fsym)(parent::$ptype, name::AbstractString, data,
                         prop1::Properties, plists::Properties...)
            depwarn($warnstr, $(QuoteNode(fsym)))
            dtype = datatype(data)
            dspace = dataspace(data)
            obj = try
                ($chainsym)(parent, name, dtype, dspace, prop1, plists...)
            finally
                close(dspace)
            end
            return obj, dtype
        end
    end
end
for (fsym, fnewsym, ptype) in ((:d_write, :write_dataset, Union{File,Group}),
                      (:a_write, :write_attribute, Union{File,Object}),
                     )
    crsym = Symbol(:__, replace(string(fsym), "write" => "create"))
    depsig = "$fsym(parent::$ptype, name::AbstractString, data, plists::HDF5Properties...)"
    usesig = "$fnewsym(parent::$ptype, name::AbstractString, data; properties...)"
    warnstr = "`$depsig` with property lists is deprecated, use `$usesig` with keywords instead"
    @eval begin
        function ($fsym)(parent::$ptype, name::AbstractString, data,
                         prop1::Properties, plists::Properties...)
            depwarn($warnstr, $(QuoteNode(fsym)))
            dtype = datatype(data)
            obj = ($crsym)(parent, name, dtype, dataspace(data), prop1, plists...)
            try
                $fsym(obj, dtype, data)
            catch exc
                delete_object(obj)
                rethrow(exc)
            finally
                close(obj)
                close(dtype)
            end
        end
    end
end
function Base.write(parent::Union{File,Group}, name::AbstractString, data::Union{T,AbstractArray{T}},
                    prop1::Properties, plists::Properties...) where {T<:Union{ScalarType,<:AbstractString,Complex{<:ScalarType}}}
    depwarn("`write(parent::Union{HDF5.File, HDF5.Group}, name::AbstractString, data, plists::HDF5Properties...)` " *
            "with property lists is deprecated, use " *
            "`write(parent::Union{HDF5.File, HDF5.Group}, name::AbstractString, data; properties...)` " *
            "with keywords instead.", :write)
    # We avoid using the write_dataset method to prevent double deprecation warnings.
    dtype = datatype(data)
    obj = __d_create(parent, name, dtype, dataspace(data), prop1, plists...)
    try
        write_dataset(obj, dtype, data)
    catch exc
        delete_object(obj)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
end
function Base.write(parent::Dataset, name::AbstractString, data::Union{T,AbstractArray{T}},
                    prop1::Properties, plists::Properties...) where {T<:Union{ScalarType,<:AbstractString}}
    depwarn("`write(parent::HDF5Dataset, name::AbstractString, data, plists::HDF5Properties...)` " *
            "with property lists is deprecated, use " *
            "`write(parent::HDF5Dataset, name::AbstractString, data; properties...)` " *
            "with keywords instead.", :write)
    # We avoid using the write_attribute method to prevent double deprecation warnings.
    dtype = datatype(data)
    obj = __a_create(parent, name, dtype, dataspace(data), prop1, plists...)
    try
        create__attribute(obj, dtype.id, data)
    catch exc
        delete_object(obj)
        rethrow(exc)
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
import Base: names
@deprecate names(x::Union{Group,File,Attributes}) keys(x) false

### Changed in PR#694
@deprecate has(parent::Union{File,Group,Dataset}, path::AbstractString) Base.haskey(parent, path)
@deprecate exists(parent::Union{File,Group,Dataset,Datatype,Attributes}, path::AbstractString) Base.haskey(parent, path)

### Changed in PR#723
# - Move type-based specializations of low-level h5(a|d)_(read|write) methods to be methods
#   of the middle-level (a|d)_(read|write) API.
#
# PRs #710 & #714 removed the argument type restrictions; deprecate just that form
# explicitly since they were only forms to exist in last release.
function h5a_create(parent_id::hid_t, name, dtype_id::hid_t, dspace_id::hid_t)
    depwarn("`h5a_create(parent.id, name, dtype.id, dspace.id)` is deprecated, use `create_attribute(parent, name, dtype, dspace)` instead", :h5a_create)
    h5a_create(parent_id, name, dtype_id, dspace_id, HDF5._attr_properties(name), HDF5.H5P_DEFAULT)
end
function h5a_open(parent_id::hid_t, name)
    depwarn("`h5a_open(parent.id, name)` is deprecated, use `open_attribute(parent, name)` instead", :h5a_open)
    h5a_open(parent_id, name, HDF5.H5P_DEFAULT)
end
function h5d_create(parent_id::hid_t, name, dtype_id::hid_t, dspace_id::hid_t)
    depwarn("`h5d_create(parent.id, name, dtype.id, dspace.id)` is deprecated, use `create_dataset(parent, name, dtype, dspace)` instead", :h5d_create)
    h5d_create(parent_id, name, dtype_id, dspace_id, HDF5._link_properties(path), HDF5.H5P_DEFAULT, HDF5.H5P_DEFAULT)
end
function h5d_open(parent_id::hid_t, name)
    depwarn("`h5d_open(parent.id, name)` is deprecated, use `open_dataset(parent, name)` instead", :h5d_open)
    h5d_open(parent_id, name, HDF5.H5P_DEFAULT)
end
function h5g_create(parent_id::hid_t, name)
    depwarn("`h5g_create(parent.id, name)` is deprecated, use `create_group(parent, name)` instead", :h5g_create)
    h5g_create(parent_id, name, HDF5._link_properties(name), HDF5.H5P_DEFAULT, HDF5.H5P_DEFAULT)
end
function h5g_create(parent_id::hid_t, name, lcpl_id::hid_t, gcpl_id::hid_t)
    depwarn("`h5g_create(parent.id, name, lcpl.id, gcpl.id)` is deprecated, use `create_group(parent, name, lcpl, gcpl)` instead", :h5g_create)
    h5g_create(parent_id, name, lcpl_id, gcpl_id, HDF5.H5P_DEFAULT)
end
function h5g_open(parent_id::hid_t, name)
    depwarn("`h5g_open(parent.id, name)` is deprecated, use `open_group(parent, name)` instead", :h5g_open)
    h5g_open(parent_id, name, HDF5.H5P_DEFAULT)
end
function h5o_open(parent_id::hid_t, name)
    depwarn("`h5o_open(parent.id, name)` is deprecated, use `open_object(parent, name)` instead", :h5o_open)
    h5o_open(parent_id, name, HDF5.H5P_DEFAULT)
end

function h5a_write(attr_id::hid_t, memtype_id::hid_t, str::AbstractString)
    depwarn("`h5a_write(attr.id, memtype.id, str)` is deprecated, use `write_attribute(attr, memtype, str)` instead")
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        buf = Base.unsafe_convert(Ptr{UInt8}, strbuf)
        h5a_write(attr_id, memtype_id, buf)
    end
end
function h5a_write(attr_id::hid_t, memtype_id::hid_t, x::T) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    depwarn("`h5a_write(attr.id, memtype.id, x)` is deprecated, use `write_attribute(attr, memtype, x)` instead")
    tmp = Ref{T}(x)
    h5a_write(attr_id, memtype_id, tmp)
end
function h5a_write(attr_id::hid_t, memtype_id::hid_t, strs::Array{<:AbstractString})
    depwarn("`h5a_write(attr.id, memtype.id, strs)` is deprecated, use `write_attribute(attr, memtype, strs)` instead")
    p = Ref{Cstring}(strs)
    h5a_write(attr_id, memtype_id, p)
end

function h5d_read(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::hid_t=H5P_DEFAULT)
    depwarn("`h5d_read(dataset.id, memtype.id, buf[, xfer.id])` is deprecated, use `read_dataset(dataset, memtype, buf[, xfer])` instead")
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot read arrays with a different stride than `Array`"))
    h5d_read(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, buf::AbstractArray, xfer::hid_t=H5P_DEFAULT)
    depwarn("`h5d_write(dataset.id, memtype.id, buf[, xfer.id])` is deprecated, use `write_dataset(dataset, memtype, buf[, xfer])` instead")
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, str::AbstractString, xfer::hid_t=H5P_DEFAULT)
    depwarn("`h5d_write(dataset.id, memtype.id, str[, xfer.id])` is deprecated, use `write_dataset(dataset, memtype, str[, xfer])` instead")
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        # unsafe_convert(Cstring, strbuf) is responsible for enforcing the no-'\0' policy,
        # but then need explicit convert to Ptr{UInt8} since Ptr{Cstring} -> Ptr{Cvoid} is
        # not automatic.
        buf = convert(Ptr{UInt8}, Base.unsafe_convert(Cstring, strbuf))
        h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, buf)
    end
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, x::T, xfer::hid_t=H5P_DEFAULT) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    depwarn("`h5d_write(dataset.id, memtype.id, x[, xfer.id])` is deprecated, use `write_dataset(dataset, memtype, x[, xfer])` instead")
    tmp = Ref{T}(x)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, tmp)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, strs::Array{<:AbstractString}, xfer::hid_t=H5P_DEFAULT)
    depwarn("`h5d_write(dataset.id, memtype.id, strs[, xfer.id])` is deprecated, use `write_dataset(dataset, memtype, strs[, xfer])` instead")
    p = Ref{Cstring}(strs)
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, p)
end
function h5d_write(dataset_id::hid_t, memtype_id::hid_t, v::VLen, xfer::hid_t=H5P_DEFAULT)
    depwarn("`h5d_write(dataset.id, memtype.id, v[, xfer.id])` is deprecated, use `write_dataset(dataset, memtype, v[, xfer])` instead")
    h5d_write(dataset_id, memtype_id, H5S_ALL, H5S_ALL, xfer, v)
end

function writearray(attr::Attribute, dtype_id::hid_t, x)
    depwarn("`writearray(attr, dtype.id, x)` is deprecated, use `write_attribute(attr, dtype, x)` instead", :writearray)
    dtype = Datatype(dtype_id, false)
    write_attribute(attr, dtype, x)
end
function writearray(dset::Dataset, dtype_id::hid_t, x)
    depwarn("`writearray(dset, dtype.id, x)` is deprecated, use `write_dataset(dset, dtype, x)` instead", :writearray)
    dtype = Datatype(dtype_id, false)
    write_dataset(dset, dtype, x)
end
function readarray(obj::Attribute, dtype_id::hid_t, buf)
    depwarn("`readarray(attr, dtype.id, buf)` is deprecated, use `read_attribute(attr, dtype, buf)` instead", :readarray)
    dtype = Datatype(dtype_id, false)
    read_attribute(attr, dtype, buf)
end
function readarray(dset::Dataset, dtype_id::hid_t, buf)
    depwarn("`readarray(dset, dtype.id, buf)` is deprecated, use `read_dataset(dset, dtype, buf)` instead", :readarray)
    dtype = Datatype(dtype_id, false)
    read_dataset(dset, dtype, buf)
end
@deprecate h5f_create(pathname) h5f_create(pathname, HDF5.H5F_ACC_TRUNC, HDF5.H5P_DEFAULT, HDF5.H5P_DEFAULT) false
@deprecate h5f_open(pathname, flags) h5f_open(pathname, flags, HDF5.H5P_DEFAULT) false
@deprecate h5l_exists(parent_id, name) h5l_exists(parent_id, name, HDF5.H5P_DEFAULT) false

### Changed in PR#724
@deprecate_binding DataFile HDF5.H5DataStore false
function Base.read(f::Base.Callable, parent::H5DataStore, name::AbstractString...)
    depwarn("Base.read(f::Base.Callable, parent::H5DataType, name::AbstractString...) is deprecated. Directly call `f` on the output from `read(parent, name...)`", :read)
    f(read(parent, name...)...)
end

function g_create(f::Function, parent::Union{File,Group}, args...)
    depwarn("g_create(f::Function, parent::Union{File,Group}, args...) is deprecated. Directly call `f` on the output from `create_group(parent, name...)` followed by closing the group", :g_create)
    g = create_group(parent, args...)
    try
        f(g)
    finally
        close(g)
    end
end


### Changed in PR#732
# - Removed hdf5_to_julia{,_eltype}(obj); using get_jl_type(obj) instead.
@deprecate hdf5_to_julia_eltype(obj) get_jl_type(obj) false
function hdf5_to_julia(obj::Union{Dataset, Attribute})
    depwarn("`hdf5_to_julia(obj)` is deprecated. Use `get_jl_type(obj)` to get the [element] type instead.", :hdf5_to_julia)
    local T
    objtype = datatype(obj)
    try
        T = get_jl_type(objtype)
    finally
        close(objtype)
    end
    T <: VLen && return T
    objspace = dataspace(obj)
    try
        stype = h5s_get_simple_extent_type(objspace)
        return stype == H5S_SIMPLE ? (return Array{T}) :
               stype == H5S_NULL ? (return EmptyArray{T}) :
               return T
    finally
        close(objspace)
    end
end
function ismmappable(::Type{Array{T}}) where {T <: ScalarType}
    depwarn("`ismmappable(obj, ::Type{A} where {A <: Array}` is deprecated. Pass the array element type instead.", :ismmappable)
    return true
end
function readmmap(obj::Dataset, ::Type{Array{T}}) where {T <: ScalarType}
    depwarn("`readmmap(obj, ::Type{A}) where {A <: Array}` is deprecated. Pass the array element type instead.", :readmmap)
    return readmmap(obj::Dataset, T)
end


### Changed in PR#696

@deprecate info(obj::Union{Group,File}) group_info(obj)
@deprecate objinfo(obj::Union{File,Object}) object_info(obj)

# - rename bindings
@deprecate a_open    open_attribute
@deprecate a_read    read_attribute
@deprecate a_write   write_attribute
@deprecate a_create  create_attribute
@deprecate a_delete  delete_attribute
@deprecate attrs     attributes

@deprecate d_open            open_dataset
@deprecate d_read            read_dataset
@deprecate d_write           write_dataset
@deprecate d_create          create_dataset
@deprecate d_create_external HDF5.create_external_dataset

@deprecate g_open   open_group
@deprecate g_create create_group

@deprecate o_open   open_object
@deprecate o_copy   copy_object
@deprecate o_delete delete_object

@deprecate p_create create_property

@deprecate t_create create_datatype
@deprecate t_open   open_datatype
@deprecate t_commit commit_datatype


###
### v0.15 deprecations
###

### Changed in PR#776
@deprecate create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace,
lcpl::Properties, dcpl::Properties,
dapl::Properties, dxpl::Properties) HDF5.Dataset(
        HDF5.h5d_create(parent, path, dtype, dspace, lcpl, dcpl, dapl), HDF5.file(parent), dxpl)) false
