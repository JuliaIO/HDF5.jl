mutable struct Datatype
    id::API.hid_t
    toclose::Bool
    file::File

    function Datatype(id, toclose::Bool=true)
        nt = new(id, toclose)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
    function Datatype(id, file::File, toclose::Bool=true)
        nt = new(id, toclose, file)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
end
Base.cconvert(::Type{API.hid_t}, dtype::Datatype) = dtype
Base.unsafe_convert(::Type{API.hid_t}, dtype::Datatype) = dtype.id

function Base.close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            API.h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Datatype) = obj.id != -1 && API.h5i_is_valid(obj)

Base.hash(dtype::Datatype, h::UInt) = hash(dtype.id, hash(Datatype, h))
Base.:(==)(dt1::Datatype, dt2::Datatype) = API.h5t_equal(dt1, dt2)

open_datatype(parent::Union{File,Group}, name::AbstractString, apl::DatatypeAccessProperties=DatatypeAccessProperties()) =
    Datatype(API.h5t_open(checkvalid(parent), name, apl), file(parent))

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
create_datatype(class_id, sz) = Datatype(API.h5t_create(class_id, sz))
function commit_datatype(parent::Union{File,Group}, path::AbstractString, dtype::Datatype,
                         lcpl::LinkCreateProperties=LinkCreateProperties(),
                         tcpl::DatatypeCreateProperties=DatatypeCreateProperties(),
                         tapl::DatatypeAccessProperties=DatatypeAccessProperties())
    lcpl.char_encoding = cset(typeof(path))
    API.h5t_commit(checkvalid(parent), path, dtype, lcpl, tcpl, tapl)
    dtype.file = file(parent)
    return dtype
end


Base.sizeof(dtype::Datatype) = Int(API.h5t_get_size(dtype))
