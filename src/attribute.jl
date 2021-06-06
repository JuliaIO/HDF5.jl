mutable struct Attribute
    id::API.hid_t
    file::File

    function Attribute(id, file)
        attr = new(id, file)
        finalizer(close, attr)
        attr
    end
end
Base.cconvert(::Type{API.hid_t}, attr::Attribute) = attr
Base.unsafe_convert(::Type{API.hid_t}, attr::Attribute) = attr.id

function Base.close(obj::Attribute)
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            API.h5a_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Attribute) = obj.id != -1 && obj.file.id != -1 && API.h5i_is_valid(obj)

get_create_properties(a::Attribute) = AttributeCreateProperties(API.h5a_get_create_plist(a))

file(o::Attribute) = o.file


name(attr::Attribute) = API.h5a_get_name(attr)
Base.eltype(attr::Attribute) = get_jl_type(attr)






# Get the dataspace of an attribute
dataspace(attr::Attribute) = Dataspace(API.h5a_get_space(checkvalid(attr)))
# Get the datatype of an attribute
datatype(dset::Attribute) = Datatype(API.h5a_get_type(checkvalid(dset)), file(dset))

Base.ndims(obj::Attribute) =
    dataspace(dspace -> Base.ndims(dspace), obj)
Base.size(obj::Attribute) =
    dataspace(dspace -> Base.size(dspace), obj)
Base.size(obj::Attribute, d::Integer) =
    dataspace(dspace -> Base.size(dspace, d), obj)
Base.length(obj::Attribute) =
    dataspace(dspace -> Base.length(dspace), obj)
Base.isempty(obj::Attribute) =
    dataspace(dspace -> Base.isempty(dspace), obj)
isnull(obj::Attribute) =
    dataspace(dspace -> isnull(dspace), obj)


"""
    HDF5.open_attribute(object, name::AbstractString)

Open an existing attribute `name` attached to `object`, returning an `Attribute` object.
"""
open_attribute(parent::Union{File,Object}, name::AbstractString, aapl::AttributeAccessProperties=AttributeAccessProperties()) =
    Attribute(API.h5a_open(checkvalid(parent), name, aapl), file(parent))

read_attribute(attr::Attribute, memtype::Datatype, buf) =
    API.h5a_read(attr, memtype, buf)
function read_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)
    local ret
    obj = open_attribute(parent, name)
    try
        ret = read(obj)
    finally
        close(obj)
    end
    ret
end

"""
    HDF5.delete_attribute(object, name::AbstractString)

Delete an existing attibute `name` attached to `object`, returning an `Attribute` object.    
"""
delete_attribute(parent::Union{File,Object}, path::AbstractString) = API.h5a_delete(checkvalid(parent), path)

"""
    HDF5.create_attribute(object, name::AbstractString, dtype::Datatype, dspace::Dataspace)

Create a new attribute `name` attached to `object`, specified by `dtype` and `dspace`.
"""
function create_attribute(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace)
    attrid = API.h5a_create(checkvalid(parent), name, dtype, dspace, _attr_properties(name), API.H5P_DEFAULT)
    return Attribute(attrid, file(parent))
end

function create_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        create_attribute(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end


write_attribute(attr::Attribute, memtype::Datatype, x) = API.h5a_write(attr, memtype, x)

function write_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    obj, dtype = create_attribute(parent, name, data; pv...)
    try
        write_attribute(obj, dtype, data)
    catch exc
        delete_attribute(parent, name)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end







"""
    Attributes(object)

A dict-like object for accessing the attributes of a HDF5 object.
"""
struct Attributes
    parent::Union{File,Object}
end
attributes(p::Union{File,Object}) = Attributes(p)
Base.isvalid(obj::Attributes) = isvalid(obj.parent)

function Base.getindex(x::Attributes, name::AbstractString)
    haskey(x, name) || throw(KeyError(name))
    open_attribute(x.parent, name)
end
Base.setindex!(x::Attributes, val, name::AbstractString) = write_attribute(x.parent, name, val)

Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) = API.h5a_exists(checkvalid(dset), path)
Base.haskey(attr::Attributes, path::AbstractString) = API.h5a_exists(checkvalid(attr.parent), path)

Base.length(x::Attributes) = Int(object_info(x.parent).num_attrs)
function Base.keys(x::Attributes)
    checkvalid(x.parent)
    children = sizehint!(String[], length(x))
    API.h5a_iterate(x.parent, API.H5_INDEX_NAME, API.H5_ITER_INC) do _, attr_name, _
        push!(children, unsafe_string(attr_name))
        return API.herr_t(0)
    end
    return children
end

