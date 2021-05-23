mutable struct Datatype
    id::hid_t
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
Base.cconvert(::Type{hid_t}, dtype::Datatype) = dtype.id

function Base.close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Datatype) = obj.id != -1 && h5i_is_valid(obj)

Base.hash(dtype::Datatype, h::UInt) = hash(dtype.id, hash(Datatype, h))
Base.:(==)(dt1::Datatype, dt2::Datatype) = h5t_equal(dt1, dt2)

open_datatype(parent::Union{File,Group}, name::AbstractString, apl::Properties=DEFAULT_PROPERTIES) = Datatype(h5t_open(checkvalid(parent), name, apl), file(parent))

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
create_datatype(class_id, sz) = Datatype(h5t_create(class_id, sz))
function commit_datatype(parent::Union{File,Group}, path::AbstractString, dtype::Datatype,
                  lcpl::Properties=create_property(H5P_LINK_CREATE), tcpl::Properties=DEFAULT_PROPERTIES, tapl::Properties=DEFAULT_PROPERTIES)
    h5p_set_char_encoding(lcpl, cset(typeof(path)))
    h5t_commit(checkvalid(parent), path, dtype, lcpl, tcpl, tapl)
    dtype.file = file(parent)
    return dtype
end


Base.sizeof(dtype::Datatype) = Int(h5t_get_size(dtype))

h5t_get_native_type(type_id) = h5t_get_native_type(type_id, H5T_DIR_ASCEND)
