abstract type PropertyClass end

"""
    Properties{PC}

A HDF5 _property list_: a collection of name/value pairs which can be passed to
various other HDF5 functions to control features that are typically unimportant or whose
default values are usually used. Values may be get and set `getproperty`/`setproperty!`.

`PC` is an abstract subtype of `PropertyClass`: this determines the class and inheritance
of the property list.
"""
mutable struct Properties{PC <: PropertyClass}
    id::hid_t
    class::hid_t
    function Properties{PC}(id, class = classid(PC)) where {PC}
        p = new{PC}(id, class)
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

# the identifier of the property class
classid(::Type{PropertyClass}) = H5P_DEFAULT

function init!(prop::Properties)
    prop.id = h5p_create(prop.class)
    return prop
end

function Properties{PC}(;kwargs...) where {PC}
    prop = Properties{PC}(H5P_DEFAULT)
    for (k, v) in kwargs
        setproperty!(prop, k, v)
    end
    return prop
end

Base.propertynames(p::Properties{PC}) where {PC<:PropertyClass} = (_all_propertynames(PC)..., :id, :class)
# definable properties for the class including inherited ones
_all_propertynames(::Properties{PC}) where {PC} = _all_propertynames(PC)
_all_propertynames(::Type{PropertyClass}) = ()
_all_propertynames(::Type{PC}) where {PC<:PropertyClass} = (_propertynames(PC)..., _all_propertynames(supertype(PC))...)
# definable properties for the class excluding inherited ones
_propertynames(::Type{PC}) where {PC<:PropertyClass} = ()

function Base.getproperty(p::Properties{PC}, name::Symbol) where {PC<:PropertyClass}
    name === :id    ? getfield(p, :id) :
    name === :class ? getfield(p, :class) :
    _getproperty(PC, p, name)
end
# default definition
function _getproperty(::Type{PC}, p::Properties, name::Symbol) where {PC<:PropertyClass}
    _getproperty(supertype(PC), p, name)
end
# final definition
function _getproperty(::Type{PropertyClass}, p::Properties, name::Symbol)
    error("$p has no property $name")
end

function Base.setproperty!(p::Properties{PC}, name::Symbol, val) where {PC<:PropertyClass}
    if name === :id
        return setfield!(p, :id, val)
    elseif name === :class
        return setfield!(p, :class, val)
    end
    if !isvalid(p)
        init!(p)
    end
    _setproperty!(PC, p, name, val)
end
# default definition
function _setproperty!(::Type{PC}, p::Properties, name::Symbol, val) where {PC<:PropertyClass}
    _setproperty!(supertype(PC), p, name, val)
end
# final definition
function _setproperty!(::Type{PropertyClass}, p::Properties, name::Symbol, val)
    error("$p has no property $name")
end

# for initializing multiple Properties from a set of keyword arguments
function setproperties!((prop1,prop2)::Tuple{Properties,Properties}; kwargs...)
    for (k,v) in kwargs
        if k in _all_propertynames(prop1)
            setproperty!(prop1,k,v)
        elseif k in _all_propertynames(prop2)
            setproperty!(prop2,k,v)
        else
            error("invalid property name $k")
        end
    end    
end
function setproperties!((prop1,prop2,prop3)::Tuple{Properties,Properties,Properties}; kwargs...)
    for (k,v) in kwargs
        if k in _all_propertynames(prop1)
            setproperty!(prop1,k,v)
        elseif k in _all_propertynames(prop2)
            setproperty!(prop2,k,v)
        elseif k in _all_propertynames(prop3)
            setproperty!(prop3,k,v)
        else
            error("invalid property name $k")
        end
    end    
end



# Property Classes
macro propertyclass(name, classid, supername=nothing)
    classname = Symbol(name,:PropertyClass)
    superclassname = isnothing(supername) ? :PropertyClass : Symbol(supername, :PropertyClass)
    propname = Symbol(name,:Properties)
    esc(quote
        abstract type $classname <: $superclassname end
        Core.@__doc__ const $propname = Properties{$classname}
        classid(::Type{$classname}) = $classid
        end)
end


"""
    ObjectCreateProperties(;kws...)

Properties used when creating a new object.

- `track_times`: governs the recording of times associated with an object. If set to 1,
  time data will be recorded. If set to 0, time data will not be recorded.

"""
@propertyclass(ObjectCreate, H5P_OBJECT_CREATE)
_propertynames(::Type{ObjectCreatePropertyClass}) = (:track_times,)
function _getproperty(::Type{ObjectCreatePropertyClass}, p::Properties, name::Symbol)
    name === :track_times ? h5p_get_obj_track_times(p) :
    _getproperty(supertype(ObjectCreatePropertyClass), p, name)
end
function _setproperty!(::Type{ObjectCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :track_times ? h5p_set_obj_track_times(p, val...) :
    _setproperty!(supertype(ObjectCreatePropertyClass), p, name, val)
end

"""
    GroupCreateProperties(;kws...)

Properties used when creating a new `Group`. Inherits from [`ObjectCreateProperties`](@ref).

- `local_heap_size_hint :: Integer`:  the anticipated maximum local heap size in bytes.

"""
@propertyclass(GroupCreate, H5P_GROUP_CREATE, ObjectCreate)
_propertynames(::Type{GroupCreatePropertyClass}) = (:local_heap_size_hint,)
function _getproperty(::Type{GroupCreatePropertyClass}, p::Properties, name::Symbol)
    name === :local_heap_size_hint ? h5p_get_local_heap_size_hint(p) :
    _getproperty(supertype(GroupCreatePropertyClass), p, name)
end
function _setproperty!(::Type{GroupCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :local_heap_size_hint ? h5p_set_local_heap_size_hint(p, val...) :
    _setproperty!(supertype(GroupCreatePropertyClass), p, name, val)
end

"""
    FileCreateProperties(;kws...)

Properties used when creating a new `Group`. Inherits from [`GroupCreateProperties`](@ref).

- `userblock` :: Integer`: user block size in bytes. The default user block size is 0; it
  may be set to any power of 2 equal to 512 or greater (512, 1024, 2048, etc.).

"""
@propertyclass(FileCreate, H5P_FILE_CREATE, GroupCreate)
_propertynames(::Type{FileCreatePropertyClass}) = (:userblock,)
function _getproperty(::Type{FileCreatePropertyClass}, p::Properties, name::Symbol)
    name === :userblock   ? h5p_get_userblock(p) :
    _getproperty(supertype(FileCreatePropertyClass), p, name)
end
function _setproperty!(::Type{FileCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :userblock   ? h5p_set_userblock(p, val...) :
    _setproperty!(supertype(FileCreatePropertyClass), p, name, val)
end

@propertyclass(DatatypeCreate, H5P_DATATYPE_CREATE, ObjectCreate)

"""
    DatasetCreateProperties(;kws...)

Properties used when creating a new `Dataset`. Inherits from [`ObjectCreateProperties`](@ref).

- `alloc_time`: the timing for the allocation of storage space for a dataset's raw data;
  one of `H5D_ALLOC_TIME_DEFAULT`, `H5D_ALLOC_TIME_EARLY` (Allocate all space when the
  dataset is created), `H5D_ALLOC_TIME_INCR` (Allocate space incrementally, as data is
  written to the dataset), `H5D_ALLOC_TIME_LATE` (Allocate all space when data is first
  written to the dataset)

- `blosc`: the level of the Blosc filter

- `chunk`: a tuple containing the size of the chunks to store each dimension. This uses Julia's column-major ordering.

- `compress`

- `deflate`

- `external`

- `layout`

- `shuffle`
"""
@propertyclass(DatasetCreate, H5P_DATASET_CREATE, ObjectCreate)
_propertynames(::Type{DatasetCreatePropertyClass}) = (:alloc_time,
                                                      :blosc,
                                                      :chunk,
                                                      :compress,
                                                      :deflate,
                                                      :external,
                                                      :layout,
                                                      :shuffle,
                                                      )

# reverse indices
get_chunk(p::Properties) = tuple(convert(Vector{Int}, reverse(h5p_get_chunk(p)))...)
set_chunk(p::Properties, dims...) = h5p_set_chunk(p, length(dims), hsize_t[reverse(dims)...])

function _getproperty(::Type{DatasetCreatePropertyClass}, p::Properties, name::Symbol)
    name === :alloc_time  ? h5p_get_alloc_time(p) :
    name === :chunk       ? get_chunk(p) :
    #name === :external    ? h5p_get_external(p) :
    name === :layout      ? h5p_get_layout(p) :
    _getproperty(supertype(DatasetCreatePropertyClass), p, name)
end
function _setproperty!(::Type{DatasetCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :alloc_time  ? h5p_set_alloc_time(p, val...) :
    name === :blosc       ? h5p_set_blosc(p, val...) :
    name === :chunk       ? set_chunk(p, val...) :
    name === :compress    ? h5p_set_deflate(p, val...) :
    name === :deflate     ? h5p_set_deflate(p, val...) :
    name === :external    ? h5p_set_external(p, val...) :
    name === :layout      ? h5p_set_layout(p, val...) :
    name === :shuffle     ? h5p_set_shuffle(p, val...) :
    _setproperty!(supertype(DatasetCreatePropertyClass), p, name, val)
end

"""
    StringCreateProperties(;kws...)

Properties used when creating strings.

- `char_encoding`: the character enconding, either `H5T_CSET_ASCII` or `H5T_CSET_UTF8`.
"""
@propertyclass(StringCreate, H5P_STRING_CREATE)
_propertynames(::Type{StringCreatePropertyClass}) = (:char_encoding,)
function _getproperty(::Type{StringCreatePropertyClass}, p::Properties, name::Symbol)
    name === :char_encoding ? h5p_get_char_encoding(p) :
    _getproperty(supertype(StringCreatePropertyClass), p, name)
end
function _setproperty!(::Type{StringCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :char_encoding ? h5p_set_char_encoding(p, val...) :
    _setproperty!(supertype(StringCreatePropertyClass), p, name, val)
end

"""
    LinkCreateProperties(;kws...)

Properties used when creating links. Inherits from [`StringCreateProperties`](@ref)

- `create_intermediate_group :: Integer`: If positive, missing intermediate groups will be created.
"""
@propertyclass(LinkCreate, H5P_LINK_CREATE, StringCreate)
_propertynames(::Type{LinkCreatePropertyClass}) = (:create_intermediate_group,)
function _getproperty(::Type{LinkCreatePropertyClass}, p::Properties, name::Symbol)
    name === :create_intermediate_group ? h5p_get_create_intermediate_group(p) :
    _getproperty(supertype(LinkCreatePropertyClass), p, name)
end
function _setproperty!(::Type{LinkCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :create_intermediate_group ? h5p_set_create_intermediate_group(p, val...) :
    _setproperty!(supertype(LinkCreatePropertyClass), p, name, val)
end

"""
    AttributeCreateProperties(;kws...)

Properties used when creating attributes. Inherits from [`StringCreateProperties`](@ref)
"""
@propertyclass(AttributeCreate, H5P_ATTRIBUTE_CREATE, StringCreate)


"""
    FileAccessProperties(;kws...)

Properties used when accessing files.

- `alignment :: Tuple{Integer, Integer}`: a `(threshold, alignment)` pair: any file object
  greater than or equal in size to threshold bytes will be aligned on an address which is
  a multiple of alignment. Default values are 1, implying no alignment.

- `driver` (get only)

- `driver_info` (get only)

- `fapl_mpio :: Tuple{MPI.Comm, MPI.Info}`: Set the MPI communicator and info object to
  use for parallel I/O.

- `fclose_degree`: file close degree property. One of: `H5F_CLOSE_WEAK`, `H5F_CLOSE_SEMI`,
  `H5F_CLOSE_STRONG` or `H5F_CLOSE_DEFAULT`.

- `libver_bounds`: a `(low, high)` pair: `low` sets the earliest possible format versions
  that the library will use when creating objects in the file;`high` sets the latest
  format versions that the library will be allowed to use when creating objects in the
  file. Possible values are `H5F_LIBVER_EARLIEST`, `H5F_LIBVER_V18`, `H5F_LIBVER_V110`,
  `H5F_LIBVER_NBOUNDS`.

"""
@propertyclass(FileAccess, H5P_FILE_ACCESS)
_propertynames(::Type{FileAccessPropertyClass}) = (:alignment,
                                                   :driver,
                                                   :driver_info,
                                                   :fapl_mpio,
                                                   :fclose_degree,
                                                   :libver_bounds,)
function _getproperty(::Type{FileAccessPropertyClass}, p::Properties, name::Symbol)
    name === :alignment     ? h5p_get_alignment(p) :
    name === :driver        ? h5p_get_driver(p) :
    name === :driver_info   ? h5p_get_driver_info(p) :
    name === :fapl_mpio     ? h5p_get_fapl_mpio(p) :
    name === :fclose_degree ? h5p_get_fclose_degree(p) :
    name === :libver_bounds ? h5p_get_libver_bounds(p) :
    _getproperty(supertype(FileAccessPropertyClass), p, name)
end
function _setproperty!(::Type{FileAccessPropertyClass}, p::Properties, name::Symbol, val)
    name === :alignment     ? h5p_set_alignment(p, val...) :
    name === :fapl_mpio     ? h5p_set_fapl_mpio(p, val...) :
    name === :fclose_degree ? h5p_set_fclose_degree(p, val...) :
    name === :libver_bounds ? h5p_set_libver_bounds(p, val...) :
    _setproperty!(supertype(FileAccessPropertyClass), p, name, val)
end


@propertyclass(LinkAccess, H5P_LINK_ACCESS)
@propertyclass(GroupAccess, H5P_GROUP_ACCESS, LinkAccess)
@propertyclass(DatatypeAccess, H5P_DATATYPE_ACCESS, LinkAccess)
@propertyclass(DatasetAccess, H5P_DATASET_ACCESS, LinkAccess)
@propertyclass(AttributeAccess, H5P_ATTRIBUTE_ACCESS, LinkAccess)

"""
    DatasetTransferProperties(;kws...)

Properties used when transferring data to/from datasets

- `dxpl_mpio`: MPI transfer mode: `H5FD_MPIO_INDEPENDENT` Use independent I/O access (default), `H5FD_MPIO_COLLECTIVE` Use collective I/O access,
"""
@propertyclass(DatasetTransfer, H5P_DATASET_XFER)
_propertynames(::Type{DatasetTransferPropertyClass}) = (:dxpl_mpio,)
function _getproperty(::Type{DatasetTransferPropertyClass}, p::Properties, name::Symbol)
    name === :dxpl_mpio  ? h5p_get_dxpl_mpio(p) :
    _getproperty(supertype(DatasetTransferPropertyClass), p, name)
end
function _setproperty!(::Type{DatasetTransferPropertyClass}, p::Properties, name::Symbol, val)
    name === :dxpl_mpio  ? h5p_set_dxpl_mpio(p, val...) :
    _setproperty!(supertype(DatasetTransferPropertyClass), p, name, val)
end
@propertyclass(FileMount, H5P_FILE_MOUNT)
@propertyclass(ObjectCopy, H5P_OBJECT_COPY)


# Across initializations of the library, the id of various properties
# will change. So don't hard-code the id (important for precompilation)
const UTF8_LINK_PROPERTIES = Ref{LinkCreateProperties}()
_link_properties(::AbstractString) = UTF8_LINK_PROPERTIES[]
const UTF8_ATTRIBUTE_PROPERTIES = Ref{AttributeCreateProperties}()
_attr_properties(::AbstractString) = UTF8_ATTRIBUTE_PROPERTIES[]
const ASCII_LINK_PROPERTIES = Ref{LinkCreateProperties}()
const ASCII_ATTRIBUTE_PROPERTIES = Ref{AttributeCreateProperties}()
