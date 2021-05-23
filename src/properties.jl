
mutable struct Properties
    id::hid_t
    class::hid_t
    function Properties(id = H5P_DEFAULT, class = H5P_DEFAULT)
        p = new(id, class)
        finalizer(close, p) # Essential, otherwise we get a memory leak, since closing file with CLOSE_STRONG is not doing it for us
        p
    end
end
Base.cconvert(::Type{hid_t}, p::Properties) = p.id

function Base.close(obj::Properties)
    if obj.id != -1
        if isvalid(obj)
            h5p_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Properties) = obj.id != -1 && h5i_is_valid(obj)


function _prop_get(p::Properties, name::Symbol)
    class = p.class

    if class == H5P_FILE_CREATE
        return name === :userblock   ? h5p_get_userblock(p) :
               name === :track_times ? h5p_get_obj_track_times(p) : # H5P_OBJECT_CREATE
               error("unknown file create property ", name)
    end

    if class == H5P_FILE_ACCESS
        return name === :alignment     ? h5p_get_alignment(p) :
               name === :driver        ? h5p_get_driver(p) :
               name === :driver_info   ? h5p_get_driver_info(p) :
               name === :fapl_mpio     ? h5p_get_fapl_mpio(p) :
               name === :fclose_degree ? h5p_get_fclose_degree(p) :
               name === :libver_bounds ? h5p_get_libver_bounds(p) :
               error("unknown file access property ", name)
    end

    if class == H5P_GROUP_CREATE
        return name === :local_heap_size_hint ? h5p_get_local_heap_size_hint(p) :
               name === :track_times ? h5p_get_obj_track_times(p) : # H5P_OBJECT_CREATE
               error("unknown group create property ", name)
    end

    if class == H5P_LINK_CREATE
        return name === :char_encoding ? h5p_get_char_encoding(p) :
               name === :create_intermediate_group ? h5p_get_create_intermediate_group(p) :
               error("unknown link create property ", name)
    end

    if class == H5P_DATASET_CREATE
        return name === :alloc_time  ? h5p_get_alloc_time(p) :
               name === :chunk       ? get_chunk(p) :
               #name === :external    ? h5p_get_external(p) :
               name === :layout      ? h5p_get_layout(p) :
               name === :track_times ? h5p_get_obj_track_times(p) : # H5P_OBJECT_CREATE
               error("unknown dataset create property ", name)
    end

    if class == H5P_DATASET_XFER
        return name === :dxpl_mpio  ? h5p_get_dxpl_mpio(p) :
               error("unknown dataset transfer property ", name)
    end

    if class == H5P_ATTRIBUTE_CREATE
        return name === :char_encoding ? h5p_get_char_encoding(p) :
               error("unknown attribute create property ", name)
    end

    error("unknown property class ", class)
end

function _prop_set!(p::Properties, name::Symbol, val, check::Bool = true)
    class = p.class

    if class == H5P_FILE_CREATE
        return name === :userblock   ? h5p_set_userblock(p, val...) :
               name === :track_times ? h5p_set_obj_track_times(p, val...) : # H5P_OBJECT_CREATE
               check ? error("unknown file create property ", name) : nothing
    end

    if class == H5P_FILE_ACCESS
        return name === :alignment     ? h5p_set_alignment(p, val...) :
               name === :fapl_mpio     ? h5p_set_fapl_mpio(p, val...) :
               name === :fclose_degree ? h5p_set_fclose_degree(p, val...) :
               name === :libver_bounds ? h5p_set_libver_bounds(p, val...) :
               check ? error("unknown file access property ", name) : nothing
    end

    if class == H5P_GROUP_CREATE
        return name === :local_heap_size_hint ? h5p_set_local_heap_size_hint(p, val...) :
               name === :track_times          ? h5p_set_obj_track_times(p, val...) : # H5P_OBJECT_CREATE
               check ? error("unknown group create property ", name) : nothing
    end

    if class == H5P_LINK_CREATE
        return name === :char_encoding ? h5p_set_char_encoding(p, val...) :
               name === :create_intermediate_group ? h5p_set_create_intermediate_group(p, val...) :
               check ? error("unknown link create property ", name) : nothing
    end

    if class == H5P_DATASET_CREATE
        return name === :alloc_time  ? h5p_set_alloc_time(p, val...) :
               name === :blosc       ? h5p_set_blosc(p, val...) :
               name === :chunk       ? set_chunk(p, val...) :
               name === :compress    ? h5p_set_deflate(p, val...) :
               name === :deflate     ? h5p_set_deflate(p, val...) :
               name === :external    ? h5p_set_external(p, val...) :
               name === :layout      ? h5p_set_layout(p, val...) :
               name === :shuffle     ? h5p_set_shuffle(p, val...) :
               name === :track_times ? h5p_set_obj_track_times(p, val...) : # H5P_OBJECT_CREATE
               check ? error("unknown dataset create property ", name) : nothing
    end

    if class == H5P_DATASET_XFER
        return name === :dxpl_mpio  ? h5p_set_dxpl_mpio(p, val...) :
               check ? error("unknown dataset transfer property ", name) : nothing
    end

    if class == H5P_ATTRIBUTE_CREATE
        return name === :char_encoding ? h5p_set_char_encoding(p, val...) :
               check ? error("unknown attribute create property ", name) : nothing
    end

    return check ? error("unknown property class ", class) : nothing
end

function create_property(class; pv...)
    p = Properties(h5p_create(class), class)
    for (k, v) in pairs(pv)
        _prop_set!(p, k, v, false)
    end
    return p
end

# Getting and setting properties: p[:chunk] = dims, p[:compress] = 6
Base.getindex(p::Properties, name::Symbol) = _prop_get(checkvalid(p), name)
function Base.setindex!(p::Properties, val, name::Symbol)
    _prop_set!(checkvalid(p), name, val, true)
    return p
end

### Property manipulation ###

get_chunk(p::Properties) = tuple(convert(Vector{Int}, reverse(h5p_get_chunk(p)))...)
set_chunk(p::Properties, dims...) = h5p_set_chunk(p, length(dims), hsize_t[reverse(dims)...])

get_alignment(p::Properties)     = h5p_get_alignment(checkvalid(p))
get_alloc_time(p::Properties)    = h5p_get_alloc_time(checkvalid(p))
get_userblock(p::Properties)     = h5p_get_userblock(checkvalid(p))
get_fclose_degree(p::Properties) = h5p_get_fclose_degree(checkvalid(p))
get_libver_bounds(p::Properties) = h5p_get_libver_bounds(checkvalid(p))

# Across initializations of the library, the id of various properties
# will change. So don't hard-code the id (important for precompilation)
const UTF8_LINK_PROPERTIES = Ref{Properties}()
_link_properties(::AbstractString) = UTF8_LINK_PROPERTIES[]
const UTF8_ATTRIBUTE_PROPERTIES = Ref{Properties}()
_attr_properties(::AbstractString) = UTF8_ATTRIBUTE_PROPERTIES[]
const ASCII_LINK_PROPERTIES = Ref{Properties}()
const ASCII_ATTRIBUTE_PROPERTIES = Ref{Properties}()

const DEFAULT_PROPERTIES = Properties()
