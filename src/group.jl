mutable struct Group <: H5DataStore
    id::hid_t
    file::File         # the parent file

    function Group(id, file)
        g = new(id, file)
        finalizer(close, g)
        g
    end
end
Base.cconvert(::Type{hid_t}, g::Group) = g.id

# Close functions that should first check that the file is still open. The common case is a
# file that has been closed with CLOSE_STRONG but there are still finalizers that have not run
# for the datasets, etc, in the file.
function Base.close(obj::Group)
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Group) = obj.id != -1 && obj.file.id != -1 && h5i_is_valid(obj)

get_create_properties(g::Group)     = GroupCreateProperties(h5g_get_create_plist(g))


# Get the root group
root(h5file::File) = open_group(h5file, "/")
root(obj) = open_group(file(obj), "/")

function Base.getindex(parent::Union{File,Group}, path::AbstractString; pv...)
    haskey(parent, path) || throw(KeyError(path))
    # Faster than below if defaults are OK
    isempty(pv) && return open_object(parent, path)
    obj_type = gettype(parent, path)
    if obj_type == H5I_DATASET
        dapl = DatasetAccessProperties()
        dxpl = DatasetTransferProperties()
        setproperties!((dapl, dxpl); pv...)
        return open_dataset(parent, path, dapl, dxpl)
    elseif obj_type == H5I_GROUP
        gapl = GroupAccessProperties(;pv...)
        return open_group(parent, path, gapl)
    else#if obj_type == H5I_DATATYPE # only remaining choice
        tapl = DatatypeAccessProperties(;pv...)
        return open_datatype(parent, path, tapl)
    end
end

# Assign syntax: obj[path] = value
# Creates a dataset unless obj is a dataset, in which case it creates an attribute
# Create a dataset with properties: obj[path, prop = val, ...] = val

# properties that require chunks in order to work (e.g. any filter)
# values do not matter -- just needed to form a NamedTuple with the desired keys
const chunked_props = (; compress=nothing, deflate=nothing, blosc=nothing, shuffle=nothing)


function Base.setindex!(parent::Union{File,Group}, val, path::AbstractString; pv...)
    need_chunks = any(k in keys(chunked_props) for k in keys(pv))
    have_chunks = any(k == :chunk for k in keys(pv))

    chunk = need_chunks ? heuristic_chunk(val) : Int[]

    # ignore chunked_props (== compression) for empty datasets (issue #246):
    discard_chunks = need_chunks && isempty(chunk)
    if discard_chunks
        pv = pairs(Base.structdiff((; pv...), chunked_props))
    else
        if need_chunks && !have_chunks
            pv = pairs((; chunk = chunk, pv...))
        end
    end
    write(parent, path, val; pv...)
end


# Path manipulation
# Check existence
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
    checkvalid(parent)
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !h5l_exists(parent, first, lapl)
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

Base.length(obj::Union{Group,File}) = Int(h5g_get_num_objs(checkvalid(obj)))
Base.isempty(x::Union{Group,File}) = length(x) == 0

# iteration by objects
function Base.iterate(parent::Union{File,Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(h5o_open_by_idx(checkvalid(parent), ".", H5_INDEX_NAME, H5_ITER_INC, n-1, H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
end

function Base.keys(x::Union{Group,File})
    checkvalid(x)
    children = sizehint!(String[], length(x))
    h5l_iterate(x, H5_INDEX_NAME, H5_ITER_INC) do _, name, _
        push!(children, unsafe_string(name))
        return herr_t(0)
    end
    return children
end


function create_group(parent::Union{File,Group}, path::AbstractString,
                      lcpl::LinkCreateProperties=_link_properties(path),
                      gcpl::GroupCreateProperties=GroupCreateProperties(),
                      gapl::GroupAccessProperties=GroupAccessProperties(),
                      )
    haskey(parent, path) && error("cannot create group: object \"", path, "\" already exists at ", name(parent))
    Group(h5g_create(parent, path, lcpl, gcpl, gapl), file(parent))
end


open_group(parent::Union{File,Group}, name::AbstractString, gapl::GroupAccessProperties=GroupAccessProperties()) =
    Group(h5g_open(checkvalid(parent), name, gapl), file(parent))

group_info(obj::Union{Group,File}) = h5g_get_info(checkvalid(obj))
