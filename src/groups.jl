"""
    HDF5.Group

An object representing a [HDF5
group](https://docs.hdfgroup.org/hdf5/develop/_h5_d_m__u_g.html#subsubsec_data_model_abstract_group).
A group is analagous to a file system directory, in that, except for the root
group, every object must be a member of at least one group.

# See also

- [`create_group`](@ref)
- [`open_group`](@ref)
"""
Group

"""
    create_group(parent::Union{File,Group}, path::AbstractString; properties...)

Create a new [`Group`](@ref) at `path` under the `parent` object. Optional keyword
arguments include any keywords that that belong to
[`LinkCreateProperties`](@ref) or [`GroupCreateProperties`](@ref).
"""
function create_group(
    parent::Union{File,Group},
    path::AbstractString,
    lcpl::LinkCreateProperties,
    gcpl::GroupCreateProperties;
    pv...
)
    if !isempty(pv)
        depwarn(
            "Passing properties as positional and keyword arguments in the same call is deprecated.",
            :create_group
        )
        setproperties!(gcpl; pv...)
    end
    return Group(API.h5g_create(parent, path, lcpl, gcpl, API.H5P_DEFAULT), file(parent))
end
function create_group(parent::Union{File,Group}, path::AbstractString; pv...)
    lcpl = _link_properties(path)
    gcpl = GroupCreateProperties()
    try
        pv = setproperties!(lcpl, gcpl; pv...)
        isempty(pv) || error("invalid keyword options $pv")
        return create_group(parent, path, lcpl, gcpl)
    finally
        close(lcpl)
        close(gcpl)
    end
end

"""
    open_group(parent::Union{File,Group}, path::AbstractString; properties...)

Open an existing [`Group`](@ref) at `path` under the `parent` object.

Optional keyword arguments include any keywords that that belong to
[`GroupAccessProperties`](@ref).
"""
function open_group(
    parent::Union{File,Group}, name::AbstractString, gapl::GroupAccessProperties
)
    return Group(API.h5g_open(checkvalid(parent), name, gapl), file(parent))
end
function open_group(parent::Union{File,Group}, name::AbstractString; pv...)
    gapl = GroupAccessProperties(; pv...)
    return open_group(parent, name, gapl)
end

# Get the root group
root(h5file::File) = open_group(h5file, "/")
root(obj::Union{Group,Dataset}) = open_group(file(obj), "/")

group_info(obj::Union{Group,File}) = API.h5g_get_info(checkvalid(obj))
Base.length(obj::Union{Group,File}) = Int(API.h5g_get_num_objs(checkvalid(obj)))
Base.isempty(x::Union{Group,File}) = length(x) == 0

# filename and name
name(obj::Union{File,Group,Dataset,Datatype}) = API.h5i_get_name(checkvalid(obj))

# iteration by objects
function Base.iterate(parent::Union{File,Group}, iter=(1, nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(
        API.h5o_open_by_idx(
            checkvalid(parent), ".", idx_type(parent), order(parent), n - 1, API.H5P_DEFAULT
        ),
        parent
    )
    return (obj, (n + 1, obj))
end

function Base.parent(obj::Union{File,Group,Dataset})
    f = file(obj)
    path = name(obj)
    if length(path) == 1
        return f
    end
    parentname = dirname(path)
    if !isempty(parentname)
        return open_object(f, dirname(path))
    else
        return root(f)
    end
end

# Path manipulation
function split1(path::AbstractString)
    ind = findfirst('/', path)
    isnothing(ind) && return path, ""
    if ind == 1 # matches root group
        return "/", path[2:end]
    else
        indm1, indp1 = prevind(path, ind), nextind(path, ind)
        return path[1:indm1], path[indp1:end] # better to use begin:indm1, but only available on v1.5
    end
end

function Base.haskey(
    parent::Union{File,Group},
    path::AbstractString,
    lapl::LinkAccessProperties=LinkAccessProperties()
)
    # recursively check each step of the path exists
    # see https://portal.hdfgroup.org/display/HDF5/H5L_EXISTS
    checkvalid(parent)
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !API.h5l_exists(parent, first, lapl)
        return false
    end
    exists = true
    if !isempty(rest)
        obj = parent[first]
        exists = haskey(obj, rest, lapl)
        close(obj)
    end
    return exists
end
function Base.keys(x::Union{Group,File})
    checkvalid(x)
    children = sizehint!(String[], length(x))
    API.h5l_iterate(x, idx_type(x), order(x)) do _, name, _
        push!(children, unsafe_string(name))
        return API.herr_t(0)
    end
    return children
end

"""
    delete_object(parent::Union{File,Group}, path::AbstractString)

Delete the object at `parent[path]`.

# Examples
```julia
f = h5open("f.h5", "r+")
delete_object(f, "Group1")
```
"""
delete_object(
    parent::Union{File,Group},
    path::AbstractString,
    lapl::LinkAccessProperties=LinkAccessProperties()
) = API.h5l_delete(checkvalid(parent), path, lapl)
delete_object(obj::Object) = delete_object(parent(obj), ascii(split(name(obj), "/")[end])) # FIXME: remove ascii?

# Move links
move_link(
    src::Union{File,Group},
    src_name::AbstractString,
    dest::Union{File,Group},
    dest_name::AbstractString=src_name,
    lapl::LinkAccessProperties=LinkAccessProperties(),
    lcpl::LinkCreateProperties=LinkCreateProperties()
) = API.h5l_move(checkvalid(src), src_name, checkvalid(dest), dest_name, lcpl, lapl)
move_link(
    parent::Union{File,Group},
    src_name::AbstractString,
    dest_name::AbstractString,
    lapl::LinkAccessProperties=LinkAccessProperties(),
    lcpl::LinkCreateProperties=LinkCreateProperties()
) = API.h5l_move(checkvalid(parent), src_name, parent, dest_name, lcpl, lapl)

"""
    create_external(source::Union{HDF5.File, HDF5.Group}, source_relpath, target_filename, target_path;
                    lcpl_id=HDF5.API.H5P_DEFAULT, lapl_id=HDF5.H5P.DEFAULT)

Create an external link such that `source[source_relpath]` points to `target_path` within the file
with path `target_filename`.

# See also
[`API.h5l_create_external`](@ref)
"""
function create_external(
    source::Union{File,Group},
    source_relpath,
    target_filename,
    target_path;
    lcpl_id=API.H5P_DEFAULT,
    lapl_id=API.H5P_DEFAULT
)
    API.h5l_create_external(
        target_filename, target_path, source, source_relpath, lcpl_id, lapl_id
    )
    nothing
end
