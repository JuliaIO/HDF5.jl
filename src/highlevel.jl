### High-level interface ###

function h5write(filename, name::AbstractString, data; pv...)
    file = h5open(filename, "cw"; pv...)
    try
        write(file, name, data)
    finally
        close(file)
    end
end

function h5read(filename, name::AbstractString; pv...)
    local dat, file
    fapl = FileAccessProperties(; fclose_degree=:strong)
    pv = setproperties!(fapl; pv...)
    try
        file = h5open(filename, "r", fapl)
    finally
        close(fapl)
    end
    try
        obj = getindex(file, name; pv...)
        dat = read(obj)
        close(obj)
    finally
        close(file)
    end
    dat
end

function h5read(filename, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    local dat, file
    fapl = FileAccessProperties(; fclose_degree=:strong)
    pv = setproperties!(fapl; pv...)
    try
        file = h5open(filename, "r", fapl)
    finally
        close(fapl)
    end
    try
        obj = getindex(file, name_type_pair[1]; pv...)
        dat = read(obj, name_type_pair[2])
        close(obj)
    finally
        close(file)
    end
    dat
end

function h5read(
    filename,
    name::AbstractString,
    indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}};
    pv...
)
    local dat, file
    fapl = FileAccessProperties(; fclose_degree=:strong)
    pv = setproperties!(fapl; pv...)
    try
        file = h5open(filename, "r", fapl)
    finally
        close(fapl)
    end
    try
        dset = getindex(file, name; pv...)
        dat = dset[indices...]
        close(dset)
    finally
        close(file)
    end
    dat
end

function Base.getindex(parent::Union{File,Group}, path::AbstractString; pv...)
    haskey(parent, path) || throw(KeyError(path))
    # Faster than below if defaults are OK
    isempty(pv) && return open_object(parent, path)
    obj_type = gettype(parent, path)
    if obj_type == API.H5I_DATASET
        return open_dataset(parent, path; pv...)
    elseif obj_type == API.H5I_GROUP
        return open_group(parent, path; pv...)
    else#if obj_type == API.H5I_DATATYPE # only remaining choice
        return open_datatype(parent, path; pv...)
    end
end

# Assign syntax: obj[path] = value
# Create a dataset with properties: obj[path, prop = val, ...] = val
function Base.setindex!(
    parent::Union{File,Group}, val, path::Union{AbstractString,Nothing}; pv...
)
    need_chunks = any(k in keys(chunked_props) for k in keys(pv))
    have_chunks = any(k == :chunk for k in keys(pv))

    chunk = need_chunks ? heuristic_chunk(val) : Int[]

    # ignore chunked_props (== compression) for empty datasets (issue #246):
    discard_chunks = need_chunks && isempty(chunk)
    if discard_chunks
        pv = pairs(Base.structdiff((; pv...), chunked_props))
    else
        if need_chunks && !have_chunks
            pv = pairs((; chunk=chunk, pv...))
        end
    end
    write(parent, path, val; pv...)
end

### Property manipulation ###
get_access_properties(d::Dataset)   = DatasetAccessProperties(API.h5d_get_access_plist(d))
get_access_properties(f::File)      = FileAccessProperties(API.h5f_get_access_plist(f))
get_create_properties(d::Dataset)   = DatasetCreateProperties(API.h5d_get_create_plist(d))
get_create_properties(g::Group)     = GroupCreateProperties(API.h5g_get_create_plist(g))
get_create_properties(f::File)      = FileCreateProperties(API.h5f_get_create_plist(f))
get_create_properties(a::Attribute) = AttributeCreateProperties(API.h5a_get_create_plist(a))
