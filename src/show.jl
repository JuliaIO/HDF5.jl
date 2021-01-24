function Base.show(io::IO, fid::File)
    if isvalid(fid)
        intent = h5f_get_intent(fid)
        RW_MASK   = H5F_ACC_RDONLY | H5F_ACC_RDWR
        SWMR_MASK = H5F_ACC_SWMR_READ | H5F_ACC_SWMR_WRITE
        rw = (intent & RW_MASK) == H5F_ACC_RDONLY ? "(read-only" : "(read-write"
        swmr = (intent & SWMR_MASK) != 0 ? ", swmr) " : ") "
        print(io, "HDF5.File: ", rw, swmr, fid.filename)
    else
        print(io, "HDF5.File: (closed) ", fid.filename)
    end
end

function Base.show(io::IO, g::Group)
    if isvalid(g)
        print(io, "HDF5.Group: ", name(g), " (file: ", g.file.filename, ")")
    else
        print(io, "HDF5.Group: (invalid)")
    end
end

function Base.show(io::IO, prop::Properties)
    if prop.class == H5P_DEFAULT
        print(io, "HDF5.Properties: default class")
    elseif isvalid(prop)
        print(io, "HDF5.Properties: ", h5p_get_class_name(prop.class), " class")
    else
        print(io, "HDF5.Properties: (invalid)")
    end
end

function Base.show(io::IO, dset::Dataset)
    if isvalid(dset)
        print(io, "HDF5.Dataset: ", name(dset), " (file: ", dset.file.filename, " xfer_mode: ", dset.xfer.id, ")")
    else
        print(io, "HDF5.Dataset: (invalid)")
    end
end

function Base.show(io::IO, attr::Attribute)
    if isvalid(attr)
        print(io, "HDF5.Attribute: ", name(attr))
    else
        print(io, "HDF5.Attribute: (invalid)")
    end
end
function Base.show(io::IO, attr::Attributes)
    print(io, "Attributes of ", attr.parent)
end

function Base.show(io::IO, dtype::Datatype)
    print(io, "HDF5.Datatype: ")
    if isvalid(dtype)
        h5t_committed(dtype) && print(io, name(dtype), " ")
        print(io, h5lt_dtype_to_text(dtype))
    else
        # Note that h5i_is_valid returns `false` on the built-in datatypes (e.g. H5T_NATIVE_INT),
        # apparently because they have refcounts of 0 yet are always valid. Just temporarily turn
        # off error printing and try the call to probe if dtype is valid since H5LTdtype_to_text
        # special-cases all of the built-in types internally.
        local text
        try
            text = silence_errors(() -> h5lt_dtype_to_text(dtype))
        catch
            text = "(invalid)"
        end
        print(io, text)
    end
end

function Base.show(io::IO, dspace::Dataspace)
    if !isvalid(dspace)
        print(io, "HDF5.Dataspace: (invalid)")
        return
    end
    print(io, "HDF5.Dataspace: ")
    type = h5s_get_simple_extent_type(dspace)
    if type == H5S_NULL
        print(io, "H5S_NULL")
        return
    elseif type == H5S_SCALAR
        print(io, "H5S_SCALAR")
        return
    end
    # otherwise type == H5S_SIMPLE
    sz, maxsz = get_extent_dims(dspace)
    sel = h5s_get_select_type(dspace)
    if sel == H5S_SEL_HYPERSLABS && h5s_is_regular_hyperslab(dspace)
        start, stride, count, _ = get_regular_hyperslab(dspace)
        ndims = length(start)
        print(io, "(")
        for ii in 1:ndims
            s, d, l = start[ii], stride[ii], count[ii]
            print(io, range(s + 1, length = l, step = d == 1 ? nothing : d))
            ii != ndims && print(io, ", ")
        end
        print(io, ") / (")
        for ii in 1:ndims
            print(io, 1:maxsz[ii])
            ii != ndims && print(io, ", ")
        end
        print(io, ")")
    else
        print(io, sz)
        if maxsz != sz
            print(io, " / ", maxsz)
        end
        if sel != H5S_SEL_ALL
            print(io, " [irregular selection]")
        end
    end
end

"""
    SHOW_TREE_ICONS = Ref{Bool}(true)

Configurable option to control whether emoji icons (`true`) or a plain-text annotation
(`false`) is used to indicate the object type by `show_tree`.
"""
const SHOW_TREE_ICONS = Ref{Bool}(true)

"""
    SHOW_TREE_MAX_DEPTH = Ref{Int}(5)

Maximum recursive depth to descend during printing.
"""
const SHOW_TREE_MAX_DEPTH = Ref{Int}(5)

"""
    SHOW_TREE_MAX_CHILDREN = Ref{Int}(50)

Maximum number of children to show at each node.
"""
const SHOW_TREE_MAX_CHILDREN = Ref{Int}(50)

function Base.show(io::IO, ::MIME"text/plain", obj::Union{File,Group,Dataset,Attributes,Attribute})
    if get(io, :compact, false)::Bool
        show(io, obj)
    else
        show_tree(io, obj)
    end
end

_tree_icon(::Type{Attribute}) = SHOW_TREE_ICONS[] ? "🏷️" : "[A]"
_tree_icon(::Type{Group})     = SHOW_TREE_ICONS[] ? "📂" : "[G]"
_tree_icon(::Type{Dataset})   = SHOW_TREE_ICONS[] ? "🔢" : "[D]"
_tree_icon(::Type{Datatype})  = SHOW_TREE_ICONS[] ? "📄" : "[T]"
_tree_icon(::Type{File})      = SHOW_TREE_ICONS[] ? "🗂️" : "[F]"
_tree_icon(::Type)            = SHOW_TREE_ICONS[] ? "❓" : "[?]"
_tree_icon(obj) = _tree_icon(typeof(obj))
_tree_icon(obj::Attributes) = _tree_icon(obj.parent)

_tree_head(io::IO, obj) = print(io, _tree_icon(obj), " ", obj)
_tree_head(io::IO, obj::Datatype) = print(io, _tree_icon(obj), " HDF5.Datatype: ", name(obj))

_tree_count(parent::Union{File,Group}, attributes::Bool) =
    length(parent) + (attributes ? length(HDF5.attributes(parent)) : 0)
_tree_count(parent::Dataset, attributes::Bool) =
    attributes ? length(HDF5.attributes(parent)) : 0
_tree_count(parent::Attributes, _::Bool) = length(parent)
_tree_count(parent::Union{Attribute,Datatype}, _::Bool) = 0

function _show_tree(io::IO, obj::Union{File,Group,Dataset,Datatype,Attributes,Attribute}, indent::String="";
                    attributes::Bool = true, depth::Int = 1)
    isempty(indent) && _tree_head(io, obj)
    isvalid(obj) || return

    INDENT = "   "
    PIPE   = "│  "
    TEE    = "├─ "
    ELBOW  = "└─ "

    limit = get(io, :limit, false)::Bool
    counter = 0
    nchildren = _tree_count(obj, attributes)

    @inline function childstr(io, n, more=" ")
        print(io, "\n", indent, ELBOW * "(", n, more, n == 1 ? "child" : "children", ")")
    end
    @inline function depth_check()
        counter += 1
        if limit && counter > max(2, SHOW_TREE_MAX_CHILDREN[] ÷ depth)
            childstr(io, nchildren - counter + 1, " more ")
            return true
        end
        return false
    end

    if limit && nchildren > 0 && depth > SHOW_TREE_MAX_DEPTH[]
        childstr(io, nchildren)
        return nothing
    end

    if attributes && !isa(obj, Attribute)
        obj′ = obj isa Attributes ? obj.parent : obj
        h5a_iterate(obj′, H5_INDEX_NAME, H5_ITER_INC) do _, cname, _
            depth_check() && return herr_t(1)

            name = unsafe_string(cname)
            icon = _tree_icon(Attribute)
            islast = counter == nchildren
            print(io, "\n", indent, islast ? ELBOW : TEE, icon, " ", name)
            return herr_t(0)
        end
    end

    typeof(obj) <: Union{File, Group} || return nothing

    h5l_iterate(obj, H5_INDEX_NAME, H5_ITER_INC) do loc_id, cname, _
        depth_check() && return herr_t(1)

        name = unsafe_string(cname)
        child = obj[name]
        icon = _tree_icon(child)

        islast = counter == nchildren
        print(io, "\n", indent, islast ? ELBOW : TEE, icon, " ", name)
        nextindent = indent * (islast ? INDENT : PIPE)
        _show_tree(io, child, nextindent; attributes = attributes, depth = depth + 1)

        close(child)
        return herr_t(0)
    end
    return nothing
end

show_tree(obj; kws...) = show_tree(stdout, obj; kws...)
function show_tree(io::IO, obj; kws...)
    buf = IOBuffer()
    _show_tree(IOContext(buf, io), obj; kws...)
    print(io, String(take!(buf)))
end
