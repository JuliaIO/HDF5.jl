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
Attribute # defined in types.jl

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
open_attribute(
    parent::Union{File,Object},
    name::AbstractString,
    aapl::AttributeAccessProperties=AttributeAccessProperties()
) = Attribute(API.h5a_open(checkvalid(parent), name, aapl), file(parent))

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
function create_attribute(
    parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace
)
    attrid = API.h5a_create(
        checkvalid(parent), name, dtype, dspace, _attr_properties(name), API.H5P_DEFAULT
    )
    return Attribute(attrid, file(parent))
end

# generic method
function write_attribute(attr::Attribute, memtype::Datatype, x::T) where {T}
    if isbitstype(T)
        API.h5a_write(attr, memtype, x)
    else
        jl_type = get_mem_compatible_jl_type(memtype)
        try
            x_mem = convert(jl_type, x)
            API.h5a_write(attr, memtype, Ref(x_mem))
        catch err
            if err isa MethodError
                throw(
                    ArgumentError(
                        "Could not convert non-bitstype $T to $jl_type for writing to HDF5. Consider implementing `convert(::Type{$jl_type}, ::$T)`"
                    )
                )
            else
                rethrow()
            end
        end
    end
end
function write_attribute(attr::Attribute, memtype::Datatype, x::Ref{T}) where {T}
    if isbitstype(T)
        API.h5a_write(attr, memtype, x)
    else
        jl_type = get_mem_compatible_jl_type(memtype)
        try
            x_mem = convert(Ref{jl_type}, x[])
            API.h5a_write(attr, memtype, x_mem)
        catch err
            if err isa MethodError
                throw(
                    ArgumentError(
                        "Could not convert non-bitstype $T to $jl_type for writing to HDF5. Consider implementing `convert(::Type{$jl_type}, ::$T)`"
                    )
                )
            else
                rethrow()
            end
        end
    end
end

# specific methods
write_attribute(attr::Attribute, memtype::Datatype, x::VLen) =
    API.h5a_write(attr, memtype, x)
function write_attribute(attr::Attribute, memtype::Datatype, x::AbstractArray{T}) where {T}
    length(x) == length(attr) || throw(
        ArgumentError(
            "Invalid length: $(length(x)) != $(length(attr)), for attribute \"$(name(attr))\""
        )
    )
    if isbitstype(T)
        API.h5a_write(attr, memtype, x)
    else
        jl_type = get_mem_compatible_jl_type(memtype)
        try
            x_mem = convert(Array{jl_type}, x)
            API.h5a_write(attr, memtype, x_mem)
        catch err
            if err isa MethodError
                throw(
                    ArgumentError(
                        "Could not convert non-bitstype $T to $jl_type for writing to HDF5. Consider implementing `convert(::Type{$jl_type}, ::$T)`"
                    )
                )
            else
                rethrow()
            end
        end
    end
end
function write_attribute(attr::Attribute, memtype::Datatype, str::AbstractString)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        if API.h5t_is_variable_str(memtype)
            ptr = Base.unsafe_convert(Cstring, strbuf)
            write_attribute(attr, memtype, Ref(ptr))
        else
            ptr = Base.unsafe_convert(Ptr{UInt8}, strbuf)
            write_attribute(attr, memtype, ptr)
        end
    end
end
function write_attribute(
    attr::Attribute, memtype::Datatype, x::T
) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    write_attribute(attr, memtype, tmp)
end
function write_attribute(attr::Attribute, memtype::Datatype, strs::Array{<:AbstractString})
    p = Ref{Cstring}(strs)
    write_attribute(attr, memtype, p)
end
write_attribute(attr::Attribute, memtype::Datatype, ::EmptyArray) = nothing

"""
    write_attribute(parent::Union{File,Object}, name::AbstractString, data)

Write `data` as an [`Attribute`](@ref) named `name` on the object `parent`.
"""
function write_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    attr, dtype = create_attribute(parent, name, data; pv...)
    try
        write_attribute(attr, dtype, data)
    catch exc
        delete_attribute(parent, name)
        rethrow(exc)
    finally
        close(attr)
        close(dtype)
    end
    nothing
end

"""
    rename_attribute(parent::Union{File,Object}, oldname::AbstractString, newname::AbstractString)

Rename the [`Attribute`](@ref) of the object `parent` named `oldname` to `newname`.
"""
rename_attribute(
    parent::Union{File,Object}, oldname::AbstractString, newname::AbstractString
) = API.h5a_rename(checkvalid(parent), oldname, newname)

"""
    delete_attribute(parent::Union{File,Object}, name::AbstractString)

Delete the [`Attribute`](@ref) named `name` on the object `parent`.
"""
delete_attribute(parent::Union{File,Object}, name::AbstractString) =
    API.h5a_delete(checkvalid(parent), name)

"""
    h5writeattr(filename, name::AbstractString, data::Dict)

Write `data` as attributes to the object at `name` in the HDF5 file `filename`.
"""
function h5writeattr(filename, name::AbstractString, data::Dict)
    file = h5open(filename, "r+")
    try
        obj = file[name]
        merge!(attrs(obj), data)
        close(obj)
    finally
        close(file)
    end
end

"""
    h5readattr(filename, name::AbstractString)

Read the attributes of the object at `name` in the HDF5 file `filename`, returning a `Dict`.
"""
function h5readattr(filename, name::AbstractString)
    local dat
    file = h5open(filename, "r")
    try
        obj = file[name]
        dat = Dict(attrs(obj))
        close(obj)
    finally
        close(file)
    end
    dat
end

"""
    num_attrs()

Retrieve the number of attributes from an object.

See [`API.h5o_get_info`](@ref).
"""
function num_attrs(obj)
    info = @static if API._libhdf5_build_ver < v"1.12.0"
        API.h5o_get_info(checkvalid(obj))
    else
        API.h5o_get_info(checkvalid(obj), API.H5O_INFO_NUM_ATTRS)
    end
    return Int(info.num_attrs)
end

struct AttributeDict <: AbstractDict{String,Any}
    parent::Object
end
AttributeDict(file::File) = AttributeDict(open_group(file, "."))

"""
    attrs(object::Union{File,Group,Dataset,Datatype})

The attributes dictionary of `object`. Returns an `AttributeDict`, a `Dict`-like
object for accessing the attributes of `object`.

```julia
attrs(object)["name"] = value  # create/overwrite an attribute
attr = attrs(object)["name"]   # read an attribute
delete!(attrs(object), "name") # delete an attribute
keys(attrs(object))            # list the attribute names
```
"""
function attrs(parent)
    return AttributeDict(parent)
end

Base.haskey(attrdict::AttributeDict, path::AbstractString) =
    API.h5a_exists(checkvalid(attrdict.parent), path)
Base.length(attrdict::AttributeDict) = num_attrs(attrdict.parent)

function Base.getindex(x::AttributeDict, name::AbstractString)
    haskey(x, name) || throw(KeyError(name))
    read_attribute(x.parent, name)
end
function Base.get(x::AttributeDict, name::AbstractString, default)
    haskey(x, name) || return default
    read_attribute(x.parent, name)
end
function Base.setindex!(attrdict::AttributeDict, val, name::AbstractString)
    if haskey(attrdict, name)
        # in case of an error, we write first to a temporary, then rename
        _name = name * "_hdf5jl_" * string(uuid4())
        haskey(attrdict, _name) && error("temp attribute name exists against all odds")
        try
            write_attribute(attrdict.parent, _name, val)
            delete_attribute(attrdict.parent, name)
            rename_attribute(attrdict.parent, _name, name)
        finally
            haskey(attrdict, _name) && delete_attribute(attrdict.parent, _name)
        end
    else
        write_attribute(attrdict.parent, name, val)
    end
end
Base.delete!(attrdict::AttributeDict, path::AbstractString) =
    delete_attribute(attrdict.parent, path)

function Base.keys(attrdict::AttributeDict)
    # faster than iteratively calling h5a_get_name_by_idx
    checkvalid(attrdict.parent)
    keyvec = sizehint!(String[], length(attrdict))
    API.h5a_iterate(
        attrdict.parent, idx_type(attrdict.parent), order(attrdict.parent)
    ) do _, attr_name, _
        push!(keyvec, unsafe_string(attr_name))
        return false
    end
    return keyvec
end

function Base.iterate(attrdict::AttributeDict)
    # constuct key vector, then iterate
    # faster than calling h5a_open_by_idx
    iterate(attrdict, (keys(attrdict), 1))
end
function Base.iterate(attrdict::AttributeDict, (keyvec, n))
    iter = iterate(keyvec, n)
    if isnothing(iter)
        return iter
    end
    key, nn = iter
    return (key => attrdict[key]), (keyvec, nn)
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
Base.setindex!(x::Attributes, val, name::AbstractString) =
    write_attribute(x.parent, name, val)
Base.haskey(attr::Attributes, path::AbstractString) =
    API.h5a_exists(checkvalid(attr.parent), path)
Base.length(x::Attributes) = num_attrs(x.parent)

function Base.keys(x::Attributes)
    checkvalid(x.parent)
    children = sizehint!(String[], length(x))
    API.h5a_iterate(x.parent, idx_type(x.parent), order(x.parent)) do _, attr_name, _
        push!(children, unsafe_string(attr_name))
        return API.herr_t(0)
    end
    return children
end
Base.read(attr::Attributes, name::AbstractString) = read_attribute(attr.parent, name)

# Dataset methods which act like attributes
Base.write(parent::Dataset, name::AbstractString, data; pv...) =
    write_attribute(parent, name, data; pv...)
function Base.getindex(dset::Dataset, name::AbstractString)
    haskey(dset, name) || throw(KeyError(name))
    open_attribute(dset, name)
end
Base.setindex!(dset::Dataset, val, name::AbstractString) = write_attribute(dset, name, val)
Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) =
    API.h5a_exists(checkvalid(dset), path)
