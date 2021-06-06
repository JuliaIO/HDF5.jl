# Define an H5O Object type
const Object = Union{Group,Dataset,Datatype}


# Extract the file
file(f::File) = f
file(o::Object) = o.file
fd(obj::Object) = h5i_get_file_id(checkvalid(obj))


delete_object(parent::Union{File,Group}, path::AbstractString, lapl::LinkAccessProperties=LinkAccessProperties()) =
    API.h5l_delete(checkvalid(parent), path, lapl)

delete_object(obj::Object) = delete_object(parent(obj), ascii(split(name(obj),"/")[end])) # FIXME: remove ascii?


# Copy objects
copy_object(src_parent::Union{File,Group}, src_path::AbstractString, dst_parent::Union{File,Group}, dst_path::AbstractString,
            ocpypl::ObjectCopyProperties=ObjectCopyProperties(), lcpl::LinkCreateProperties=_link_properties(dst_path)) =
    API.h5o_copy(checkvalid(src_parent), src_path, checkvalid(dst_parent), dst_path, ocpypl, lcpl)

copy_object(src_obj::Object, dst_parent::Union{File,Group}, dst_path::AbstractString,
            ocpypl::ObjectCopyProperties=ObjectCopyProperties(), lcpl::LinkCreateProperties=_link_properties(dst_path)) =
    API.h5o_copy(checkvalid(src_obj), ".", checkvalid(dst_parent), dst_path, ocpypl, lcpl)

object_info(obj::Union{File,Object}) = API.h5o_get_info(checkvalid(obj))

# Open objects
# Object (group, named datatype, or dataset) open
function h5object(obj_id::API.hid_t, parent)
    obj_type = API.h5i_get_type(obj_id)
    obj_type == API.H5I_GROUP ? Group(obj_id, file(parent)) :
    obj_type == API.H5I_DATATYPE ? Datatype(obj_id, file(parent)) :
    obj_type == API.H5I_DATASET ? Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
open_object(parent, path::AbstractString, lapl::LinkAccessProperties=LinkAccessProperties()) =
    h5object(API.h5o_open(checkvalid(parent), path, lapl), parent)

function gettype(parent, path::AbstractString)
    obj_id = API.h5o_open(checkvalid(parent), path, API.H5P_DEFAULT)
    obj_type = API.h5i_get_type(obj_id)
    API.h5o_close(obj_id)
    return obj_type
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
