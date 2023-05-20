# Ensure that objects haven't been closed
Base.isvalid(obj::Union{File,Datatype,Dataspace}) = obj.id != -1 && API.h5i_is_valid(obj)
Base.isvalid(obj::Union{Group,Dataset,Attribute}) =
    obj.id != -1 && obj.file.id != -1 && API.h5i_is_valid(obj)
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Close functions

# Close functions that should first check that the file is still open. The common case is a
# file that has been closed with CLOSE_STRONG but there are still finalizers that have not run
# for the datasets, etc, in the file.

function Base.close(obj::Union{Group,Dataset})
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            API.h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

# Object (group, named datatype, or dataset) open
function h5object(obj_id::API.hid_t, parent)
    obj_type = API.h5i_get_type(obj_id)
    if obj_type == API.H5I_GROUP
        Group(obj_id, file(parent))
    elseif obj_type == API.H5I_DATATYPE
        Datatype(obj_id, file(parent))
    elseif obj_type == API.H5I_DATASET
        Dataset(obj_id, file(parent))
    else
        error("Invalid object type for path ", path)
    end
end

open_object(parent, path::AbstractString) =
    h5object(API.h5o_open(checkvalid(parent), path, API.H5P_DEFAULT), parent)

function gettype(parent, path::AbstractString)
    obj_id = API.h5o_open(checkvalid(parent), path, API.H5P_DEFAULT)
    obj_type = API.h5i_get_type(obj_id)
    API.h5o_close(obj_id)
    return obj_type
end

# Copy objects
"""
    copy_object(src_parent::Union{File,Group}, src_path::AbstractString, dst_parent::Union{File,Group}, dst_path::AbstractString)

Copy data from `src_parent[src_path]` to `dst_parent[dst_path]`.

# Examples
```julia
f = h5open("f.h5", "r")
g = h5open("g.h5", "cw")
copy_object(f, "Group1", g, "GroupA")
copy_object(f["Group1"], "data1", g, "DataSet/data_1")
```
"""
copy_object(
    src_parent::Union{File,Group},
    src_path::AbstractString,
    dst_parent::Union{File,Group},
    dst_path::AbstractString
) = API.h5o_copy(
    checkvalid(src_parent),
    src_path,
    checkvalid(dst_parent),
    dst_path,
    API.H5P_DEFAULT,
    _link_properties(dst_path)
)
"""
    copy_object(src_obj::Object, dst_parent::Union{File,Group}, dst_path::AbstractString)

# Examples
```julia
copy_object(f["Group1"], g, "GroupA")
copy_object(f["Group1/data1"], g, "DataSet/data_1")
```
"""
copy_object(src_obj::Object, dst_parent::Union{File,Group}, dst_path::AbstractString) =
    API.h5o_copy(
        checkvalid(src_obj),
        ".",
        checkvalid(dst_parent),
        dst_path,
        API.H5P_DEFAULT,
        _link_properties(dst_path)
    )
