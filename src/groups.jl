"""
    create_group(parent, path[, lcpl, gcpl]; properties...)

# Arguments
* `parent` - `File` or `Group`
* `path` - `String` describing the path of the group within the HDF5 file
* `lcpl` - [`LinkCreateProperties`](@ref)
* `gcpl` - [`GroupCreateProperties`](@ref)
* `properties` - keyword name-value pairs set properties of the group

# Keywords

There are many keyword properties that can be set. Below are a few select keywords.
* `track_order` - `Bool` tracks the group creation order. 
        Currently this is only used with `FileIO` and `OrderedDict`.
        Files created with `track_order = true` 
        should create all subgroups with `track_order = true`.

See also
* [`H5P`](@ref H5P)
"""
function create_group(parent::Union{File,Group}, path::AbstractString,
                  lcpl::LinkCreateProperties=_link_properties(path),
                  gcpl::GroupCreateProperties=GroupCreateProperties();
                  pv...)
    haskey(parent, path) && error("cannot create group: object \"", path, "\" already exists at ", name(parent))
    pv = setproperties!(gcpl; pv...)
    isempty(pv) || error("invalid keyword options $pv")
    Group(API.h5g_create(parent, path, lcpl, gcpl, API.H5P_DEFAULT), file(parent))
end

open_group(parent::Union{File,Group}, name::AbstractString, gapl::GroupAccessProperties=GroupAccessProperties()) =
    Group(API.h5g_open(checkvalid(parent), name, gapl), file(parent))

# Get the root group
root(h5file::File) = open_group(h5file, "/")
root(obj::Union{Group,Dataset}) = open_group(file(obj), "/")

group_info(obj::Union{Group,File}) = API.h5g_get_info(checkvalid(obj))
Base.length(obj::Union{Group,File}) = Int(API.h5g_get_num_objs(checkvalid(obj)))
Base.isempty(x::Union{Group,File}) = length(x) == 0

# filename and name
name(obj::Union{File,Group,Dataset,Datatype}) = API.h5i_get_name(checkvalid(obj))

# iteration by objects
function Base.iterate(parent::Union{File,Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(API.h5o_open_by_idx(checkvalid(parent), ".", idx_type(parent), order(parent), n-1, API.H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
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

function Base.haskey(parent::Union{File,Group}, path::AbstractString, lapl::LinkAccessProperties = LinkAccessProperties())
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


delete_object(parent::Union{File,Group}, path::AbstractString, lapl::LinkAccessProperties=LinkAccessProperties()) =
    API.h5l_delete(checkvalid(parent), path, lapl)
delete_object(obj::Object) = delete_object(parent(obj), ascii(split(name(obj),"/")[end])) # FIXME: remove ascii?

# Move links
move_link(src::Union{File,Group}, src_name::AbstractString, dest::Union{File,Group}, dest_name::AbstractString=src_name, lapl::LinkAccessProperties = LinkAccessProperties(), lcpl::LinkCreateProperties = LinkCreateProperties()) =
    API.h5l_move(checkvalid(src), src_name, checkvalid(dest), dest_name, lcpl, lapl)
move_link(parent::Union{File,Group}, src_name::AbstractString, dest_name::AbstractString, lapl::LinkAccessProperties = LinkAccessProperties(), lcpl::LinkCreateProperties = LinkCreateProperties())  =
    API.h5l_move(checkvalid(parent), src_name, parent, dest_name, lcpl, lapl)

"""
    create_external(source::Union{HDF5.File, HDF5.Group}, source_relpath, target_filename, target_path;
                    lcpl_id=HDF5.API.H5P_DEFAULT, lapl_id=HDF5.H5P.DEFAULT)

Create an external link such that `source[source_relpath]` points to `target_path` within the file
with path `target_filename`; Calls `[H5Lcreate_external](https://www.hdfgroup.org/HDF5/doc/RM/RM_H5L.html#Link-CreateExternal)`.
"""
function create_external(source::Union{File,Group}, source_relpath, target_filename, target_path; lcpl_id=API.H5P_DEFAULT, lapl_id=API.H5P_DEFAULT)
    API.h5l_create_external(target_filename, target_path, source, source_relpath, lcpl_id, lapl_id)
    nothing
end
