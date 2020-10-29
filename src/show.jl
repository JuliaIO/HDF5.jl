_tree_icon(obj) = obj isa Attribute ? "🏷️ " :
                  obj isa Group ? "📂 " :
                  obj isa Dataset ? "🔢 " :
                  obj isa Datatype ? "📑 " :
                  obj isa File ? "🗃️ " :
                  "❓ "

_tree_head(io::IO, obj::Union{File, Group, Dataset, Attribute}) = println(io, _tree_icon(obj), obj)
_tree_head(io::IO, obj::Datatype) = println(io, _tree_icon(obj), "HDF5 Datatype: ", name(obj))
_tree_head(io::IO, obj::Attributes) = println(io, _tree_icon(obj.parent), "Attributes of ", obj.parent)

function _tree_children(parent::Union{File, Group}, attributes::Bool)
    names = keys(parent)
    objs  = Union{Object, Attribute}[parent[n] for n in names]
    if attributes
        attrn = keys(attrs(parent))
        attro = Union{Object, Attribute}[attrs(parent)[n] for n in attrn]
        names = append!(attrn, names)
        objs  = append!(attro, objs)
    end
    return (names, objs)
end
function _tree_children(parent::Dataset, attributes::Bool)
    names = String[]
    objs = Union{Object, Attribute}[parent[n] for n in names]
    if attributes
        attrn = keys(attrs(parent))
        attro = Union{Object, Attribute}[attrs(parent)[n] for n in attrn]
        names = append!(attrn, names)
        objs  = append!(attro, objs)
    end
    return (names, objs)
end
function _tree_children(parent::Attributes, attributes::Bool)
    names = keys(parent)
    objs  = Union{Object,Attribute}[parent[n] for n in names]
    return (names, objs)
end
function _tree_children(parent::Union{Attribute, Datatype}, attributes::Bool)
    # TODO: add our own implementation of much of what h5lt_dtype_to_text() does?
    return (String[], Union{Object, Attribute}[])
end

function show_tree(io::IO, obj::Union{File,Group,Dataset,Datatype,Attributes,Attribute}, indent::String="";
                   attributes::Bool = true)
    isempty(indent) && _tree_head(io, obj)
    !isvalid(obj) && return

    names, children = _tree_children(obj, attributes)
    nchildren = length(children)
    for ii in 1:nchildren
        name = names[ii]
        child  = children[ii]

        islast = ii == nchildren
        icon = _tree_icon(child)
        println(io, indent, islast ? "└─ " : "├─ ", icon, name)

        nextindent = indent * (islast ? "   " : "│  ")
        show_tree(io, child, nextindent; attributes = attributes)
    end
    return nothing
end
show_tree(obj; kws...) = show_tree(stdout, obj; kws...)
