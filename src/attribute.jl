mutable struct Attribute
    id::hid_t
    file::File

    function Attribute(id, file)
        attr = new(id, file)
        finalizer(close, attr)
        attr
    end
end
Base.cconvert(::Type{hid_t}, attr::Attribute) = attr.id

function Base.close(obj::Attribute)
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            h5a_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Attribute) = obj.id != -1 && obj.file.id != -1 && h5i_is_valid(obj)

get_create_properties(a::Attribute) = Properties(h5a_get_create_plist(a), H5P_ATTRIBUTE_CREATE)


file(o::Attribute) = o.file

struct Attributes
    parent::Union{File,Object}
end
attributes(p::Union{File,Object}) = Attributes(p)
Base.isvalid(obj::Attributes) = isvalid(obj.parent)

function Base.getindex(x::Attributes, name::AbstractString)
    haskey(x, name) || throw(KeyError(name))
    open_attribute(x.parent, name)
end

open_attribute(parent::Union{File,Object}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Attribute(h5a_open(checkvalid(parent), name, apl), file(parent))


function create_attribute(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace)
    attrid = h5a_create(checkvalid(parent), name, dtype, dspace, _attr_properties(name), H5P_DEFAULT)
    return Attribute(attrid, file(parent))
end
# Delete objects
delete_attribute(parent::Union{File,Object}, path::AbstractString) = h5a_delete(checkvalid(parent), path)

Base.setindex!(dset::Dataset, val, name::AbstractString) = write_attribute(dset, name, val)
Base.setindex!(x::Attributes, val, name::AbstractString) = write_attribute(x.parent, name, val)

Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) = h5a_exists(checkvalid(dset), path)
Base.haskey(attr::Attributes, path::AbstractString) = h5a_exists(checkvalid(attr.parent), path)

Base.length(x::Attributes) = Int(object_info(x.parent).num_attrs)
function Base.keys(x::Attributes)
    checkvalid(x.parent)
    children = sizehint!(String[], length(x))
    h5a_iterate(x.parent, H5_INDEX_NAME, H5_ITER_INC) do _, attr_name, _
        push!(children, unsafe_string(attr_name))
        return herr_t(0)
    end
    return children
end



name(attr::Attribute) = h5a_get_name(attr)
Base.eltype(attr::Attribute) = get_jl_type(attr)


# Get the dataspace of an attribute
dataspace(attr::Attribute) = Dataspace(h5a_get_space(checkvalid(attr)))
# Get the datatype of an attribute
datatype(dset::Attribute) = Datatype(h5a_get_type(checkvalid(dset)), file(dset))

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


# default behavior
read_attribute(attr::Attribute, memtype::Datatype, buf) = h5a_read(attr, memtype, buf)
write_attribute(attr::Attribute, memtype::Datatype, x) = h5a_write(attr, memtype, x)

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


