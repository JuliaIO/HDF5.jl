Reference() = Reference(API.HOBJ_REF_T_NULL) # NULL reference to compare to
Base.:(==)(a::Reference, b::Reference) = a.r == b.r
Base.hash(x::Reference, h::UInt) = hash(x.r, h)

function Reference(parent::Union{File,Group,Dataset}, name::AbstractString)
    ref = Ref{API.hobj_ref_t}()
    API.h5r_create(ref, checkvalid(parent), name, API.H5R_OBJECT, -1)
    return Reference(ref[])
end

# Dereference
function _deref(parent, r::Reference)
    r == Reference() && error("Reference is null")
    obj_id = API.h5r_dereference(checkvalid(parent), API.H5P_DEFAULT, API.H5R_OBJECT, r)
    h5object(obj_id, parent)
end
Base.getindex(parent::Union{File,Group}, r::Reference) = _deref(parent, r)
Base.getindex(parent::Dataset, r::Reference) = _deref(parent, r) # defined separately to resolve ambiguity
