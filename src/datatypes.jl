function Base.close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            API.h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

# The datatype of a Datatype is the Datatype
datatype(dt::Datatype) = dt

open_datatype(
    parent::Union{File,Group}, name::AbstractString, tapl::DatatypeAccessProperties
) = Datatype(API.h5t_open(checkvalid(parent), name, tapl), file(parent))

"""
    open_datatype(parent::Union{File,Group}, path::AbstractString; properties...)

Open an existing [`Datatype`](@ref) at `path` under the `parent` object.

Optional keyword arguments include any keywords that that belong to
[`DatatypeAccessProperties`](@ref).
"""
function open_datatype(parent::Union{File,Group}, name::AbstractString; pv...)
    tapl = DatatypeAccessProperties(; pv...)
    return open_datatype(parent, name, tapl)
end

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
create_datatype(class_id, sz) = Datatype(API.h5t_create(class_id, sz))

function commit_datatype(
    parent::Union{File,Group},
    path::AbstractString,
    dtype::Datatype,
    lcpl::LinkCreateProperties=LinkCreateProperties(),
    tcpl::DatatypeCreateProperties=DatatypeCreateProperties(),
    tapl::DatatypeAccessProperties=DatatypeAccessProperties()
)
    lcpl.char_encoding = cset(typeof(path))
    API.h5t_commit(checkvalid(parent), path, dtype, lcpl, tcpl, tapl)
    dtype.file = file(parent)
    return dtype
end

Base.sizeof(dtype::Datatype) = Int(API.h5t_get_size(dtype))
