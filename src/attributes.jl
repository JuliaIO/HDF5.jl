"""
    HDF5.Attribute

A HDF5 attribute: this is a piece of metadata attached to an HDF5 `Group` or
`Dataset`. It acts like a `Dataset`, in that it has a defined datatype and
dataspace, and can `read` and `write` data to it.

See also
- [`open_attribute`](@ref)
- [`create_attribute`](@ref)
- [`read_attribute`](@ref)
- [`write_attribute`](@ref)
- [`delete_attribute`](@ref)
"""
mutable struct Attribute
    id::API.hid_t
    file::File

    function Attribute(id, file)
        dset = new(id, file)
        finalizer(close, dset)
        dset
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
name(attr::Attribute) = API.h5a_get_name(attr)


datatype(dset::Attribute) = Datatype(API.h5a_get_type(checkvalid(dset)), file(dset))
dataspace(attr::Attribute) = Dataspace(API.h5a_get_space(checkvalid(attr)))

function Base.write(obj::Attribute, x)
    dtype = datatype(x)
    try
        write_attribute(obj, dtype, x)
    finally
        close(dtype)
    end
end

"""
    read_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)

Read the value of the named attribute on the parent object.

# Example
```julia-repl
julia> HDF5.read_attribute(g, "time")
2.45
```
"""
function read_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)
    obj = open_attribute(parent, name)
    try
        return read(obj)
    finally
        close(obj)
    end
end
read_attribute(attr::Attribute, memtype::Datatype, buf) = API.h5a_read(attr, memtype, buf)

"""
    open_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)

Open the [`Attribute`](@ref) named `name` on the object `parent`.
"""
open_attribute(parent::Union{File,Object}, name::AbstractString, aapl::AttributeAccessProperties=AttributeAccessProperties()) =
    Attribute(API.h5a_open(checkvalid(parent), name, aapl), file(parent))


"""
    create_attribute(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, space::Dataspace)
    create_attribute(parent::Union{File,Object}, name::AbstractString, data)

Create a new [`Attribute`](@ref) object named `name` on the object `parent`,
either by specifying the `Datatype` and `Dataspace` of the attribute, or by
providing the data. Note that no data will be written: use
[`write_attribute`](@ref) to write the data.
"""
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
function create_attribute(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace)
    attrid = API.h5a_create(checkvalid(parent), name, dtype, dspace, _attr_properties(name), API.H5P_DEFAULT)
    return Attribute(attrid, file(parent))
end


function write_attribute(attr::Attribute, memtype::Datatype, str::AbstractString)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        buf = Base.unsafe_convert(Ptr{UInt8}, strbuf)
        API.h5a_write(attr, memtype, buf)
    end
end
function write_attribute(attr::Attribute, memtype::Datatype, x::T) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    API.h5a_write(attr, memtype, tmp)
end
function write_attribute(attr::Attribute, memtype::Datatype, strs::Array{<:AbstractString})
    p = Ref{Cstring}(strs)
    API.h5a_write(attr, memtype, p)
end
write_attribute(attr::Attribute, memtype::Datatype, ::EmptyArray) = nothing
write_attribute(attr::Attribute, memtype::Datatype, x) = API.h5a_write(attr, memtype, x)

"""
    write_attribute(parent::Union{File,Object}, name::AbstractString, data)

Write `data` as an [`Attribute`](@ref) named `name` on the object `parent`.
"""
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
    delete_attribute(parent::Union{File,Object}, name::AbstractString)

Delete the [`Attribute`](@ref) named `name` on the object `parent`.
"""
delete_attribute(parent::Union{File,Object}, path::AbstractString) = API.h5a_delete(checkvalid(parent), path)


"""
    h5writeattr(filename, name::AbstractString, data::Dict)

Write `data` as attributes to the object at `name` in the HDF5 file `filename`.
"""
function h5writeattr(filename, name::AbstractString, data::Dict)
    file = h5open(filename, "r+")
    try
        obj = file[name]
        attrs = attributes(obj)
        for x in keys(data)
            attrs[x] = data[x]
        end
        close(obj)
    finally
        close(file)
    end
end

"""
    h5readattr(filename, name::AbstractString, data::Dict)

Read the attributes of the object at `name` in the HDF5 file `filename`, returning a `Dict`.
"""
function h5readattr(filename, name::AbstractString)
    local dat
    file = h5open(filename,"r")
    try
        obj = file[name]
        a = attributes(obj)
        dat = Dict(x => read(a[x]) for x in keys(a))
        close(obj)
    finally
        close(file)
    end
    dat
end


struct Attributes
    parent::Union{File,Object}
end

"""
    attributes(object::Union{File,Object})

The attributes of a file or object: this returns an `Attributes` object, which
is `Dict`-like object for accessing the attributes of `object`: `getindex` will
return an [`Attribute`](@ref) object, and `setindex!` will call [`write_attribute`](@ref).
"""
attributes(p::Union{File,Object}) = Attributes(p)

Base.isvalid(obj::Attributes) = isvalid(obj.parent)

function Base.getindex(x::Attributes, name::AbstractString)
    haskey(x, name) || throw(KeyError(name))
    open_attribute(x.parent, name)
end
Base.setindex!(x::Attributes, val, name::AbstractString) = write_attribute(x.parent, name, val)
Base.haskey(attr::Attributes, path::AbstractString) = API.h5a_exists(checkvalid(attr.parent), path)
Base.length(x::Attributes) = Int(object_info(x.parent).num_attrs)

function Base.keys(x::Attributes)
    checkvalid(x.parent)
    children = sizehint!(String[], length(x))
    API.h5a_iterate(x.parent, IDX_TYPE[], ORDER[]) do _, attr_name, _
        push!(children, unsafe_string(attr_name))
        return API.herr_t(0)
    end
    return children
end
Base.read(attr::Attributes, name::AbstractString) = read_attribute(attr.parent, name)


# Datasets act like attributes
Base.write(parent::Dataset, name::AbstractString, data; pv...) = write_attribute(parent, name, data; pv...)
function Base.getindex(dset::Dataset, name::AbstractString)
    haskey(dset, name) || throw(KeyError(name))
    open_attribute(dset, name)
end
Base.setindex!(dset::Dataset, val, name::AbstractString) = write_attribute(dset, name, val)