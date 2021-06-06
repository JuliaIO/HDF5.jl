abstract type PropertyClass end

"""
    Properties{PC}

A Julia object corresponding to a HDF5 property list. `PC` is an abstract subtype of
`PropertyClass`: this determines the class and inheritance of the property list.
"""
mutable struct Properties{PC <: PropertyClass}
    id::API.hid_t
    class::API.hid_t
    function Properties{PC}(id, class = classid(PC)) where {PC}
        p = new{PC}(id, class)
        finalizer(close, p) # Essential, otherwise we get a memory leak, since closing file with CLOSE_STRONG is not doing it for us
        p
    end
end

Base.cconvert(::Type{API.hid_t}, p::Properties) = p.id

function Base.close(obj::Properties)
    if obj.id != -1
        if isvalid(obj)
            API.h5p_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Properties) = obj.id != -1 && API.h5i_is_valid(obj)

# the identifier of the property class
classid(::Type{PropertyClass}) = API.H5P_DEFAULT

function init!(prop::Properties)
    if !isvalid(prop)
        prop.id = API.h5p_create(prop.class)
    end
    return prop
end

function Properties{PC}(;kwargs...) where {PC}
    prop = Properties{PC}(API.H5P_DEFAULT)
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
        return setfield!(p, :id, API.hid_t(val))
    elseif name === :class
        return setfield!(p, :class, API.hid_t(val))
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
    @enum_property(name, sym1 => enumvalue1, sym2 => enumvalue2, ...)

Wrap an API getter/setter function that operates on enum values to use symbol instead.
"""
macro enum_property(property, pairs...)
    get_property = Symbol(:get_,property)
    set_property! = Symbol(:set_,property,:!)
    api_get_property = :(API.$(Symbol(:h5p_get_,property)))
    api_set_property = :(API.$(Symbol(:h5p_set_,property)))

    get_expr = :(error("Unknown $property value $enum"))
    set_expr = :(throw(ArgumentError("Invalid $property $val")))
    
    for pair in reverse(pairs)
        @assert pair isa Expr && pair.head == :call && pair.args[1] == :(=>)
        _, val, enum = pair.args
        get_expr = :(enum == $enum ? $val : $get_expr)
        set_expr = :(val == $val ? $enum : $set_expr)
    end
    quote
        function $(esc(get_property))(p::Properties)
            property = $(QuoteNode(property))
            enum = $api_get_property(p)
            return $get_expr
        end
        function $(esc(set_property!))(p::Properties, val)
            property = $(QuoteNode(property))
            enum = $set_expr
            return $api_set_property(p, enum)
        end
        function $(esc(set_property!))(p::Properties, enum::Integer)
            # deprecate?
            return $api_set_property(p, enum)
        end
    end
end

"""
    @bool_property(name)

Wrap an API getter/setter function that returns boolean values
"""
macro bool_property(property)
    get_property = Symbol(:get_,property)
    set_property! = Symbol(:set_,property,:!)
    api_get_property = :(API.$(Symbol(:h5p_get_,property)))
    api_set_property = :(API.$(Symbol(:h5p_set_,property)))
    quote
        function $(esc(get_property))(p::Properties)
            return $api_get_property(p) != 0
        end
        function $(esc(set_property!))(p::Properties, val)
            return $api_set_property(p, val)
        end
    end
end


"""
    ObjectCreateProperties(;kws...)

Properties used when creating a new object. Available options:

- `track_times :: Bool`: governs the recording of times associated with an object. If set to `true`,
  time data will be recorded. See $(h5doc("H5P_SET_OBJ_TRACK_TIMES")).

"""
@propertyclass(ObjectCreate, API.H5P_OBJECT_CREATE)

@bool_property(obj_track_times)

_propertynames(::Type{ObjectCreatePropertyClass}) = (:track_times,)
function _getproperty(::Type{ObjectCreatePropertyClass}, p::Properties, name::Symbol)
    name === :track_times ? get_obj_track_times(p) :
    _getproperty(supertype(ObjectCreatePropertyClass), p, name)
end
function _setproperty!(::Type{ObjectCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :track_times ? set_obj_track_times!(p, val) :
    _setproperty!(supertype(ObjectCreatePropertyClass), p, name, val)
end

"""
    GroupCreateProperties(;kws...)

Properties used when creating a new `Group`. Inherits from
[`ObjectCreateProperties`](@ref), with additional options:

- `local_heap_size_hint :: Integer`: the anticipated maximum local heap size in bytes. See
  $(h5doc("H5P_SET_LOCAL_HEAP_SIZE_HINT")).

"""
@propertyclass(GroupCreate, API.H5P_GROUP_CREATE, ObjectCreate)
_propertynames(::Type{GroupCreatePropertyClass}) = (:local_heap_size_hint,)
function _getproperty(::Type{GroupCreatePropertyClass}, p::Properties, name::Symbol)
    name === :local_heap_size_hint ? API.h5p_get_local_heap_size_hint(p) :
    _getproperty(supertype(GroupCreatePropertyClass), p, name)
end
function _setproperty!(::Type{GroupCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :local_heap_size_hint ? API.h5p_set_local_heap_size_hint(p, val...) :
    _setproperty!(supertype(GroupCreatePropertyClass), p, name, val)
end

"""
    FileCreateProperties(;kws...)

Properties used when creating a new `Group`. Inherits from [`GroupCreateProperties`](@ref),  with additional properties:

- `userblock :: Integer`: user block size in bytes. The default user block size is 0; it
  may be set to any power of 2 equal to 512 or greater (512, 1024, 2048,
  etc.). See $(h5doc("H5P_SET_USERBLOCK")).

"""
@propertyclass(FileCreate, API.H5P_FILE_CREATE, GroupCreate)
_propertynames(::Type{FileCreatePropertyClass}) = (:userblock,)
function _getproperty(::Type{FileCreatePropertyClass}, p::Properties, name::Symbol)
    name === :userblock   ? API.h5p_get_userblock(p) :
    _getproperty(supertype(FileCreatePropertyClass), p, name)
end
function _setproperty!(::Type{FileCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :userblock   ? API.h5p_set_userblock(p, val...) :
    _setproperty!(supertype(FileCreatePropertyClass), p, name, val)
end

@propertyclass(DatatypeCreate, API.H5P_DATATYPE_CREATE, ObjectCreate)

"""
    DatasetCreateProperties(;kws...)

Properties used when creating a new `Dataset`. Inherits from [`ObjectCreateProperties`](@ref), with additional properties:

- `alloc_time`: the timing for the allocation of storage space for a dataset's raw data;
  one of:
   - `:default`

   - `:early`: allocate all space when the dataset is created

   - `:incremental`: Allocate space incrementally, as data is  written to the dataset

   - `:late`: Allocate all space when data is first written to the dataset.
   
  See $(h5doc("H5P_SET_ALLOC_TIME")).

- `chunk`: a tuple containing the size of the chunks to store each dimension. See
  $(h5doc("H5P_SET_CHUNK")) (note that this uses Julia's column-major ordering).

- `external`: A tuple of `(name,offset,size)`, See $(h5doc("H5P_SET_EXTERNAL")).

- `filters` (only valid when `layout=:chunked`): a filter or vector of filters that are
  applied to applied to each chunk of a dataset, see [Filters](@ref). When accessed, will
  return a [`Filters.FilterPipeline`](@ref) object that can be modified in-place.

- `layout`: the type of storage used to store the raw data for a dataset. Can be one of:

   - `:compact`: Store raw data in the dataset object header in file. This should only
     be used for datasets with small amounts of raw data.

   - `:contiguous`: Store raw data separately from the object header in one large chunk
     in the file.

   - `:chunked`: Store raw data separately from the object header as chunks of data in
     separate locations in the file.

   - `:virtual`:  Draw raw data from multiple datasets in different files.

  See $(h5doc("H5P_SET_LAYOUT")).


The following options are shortcuts for the various filters, and are set-only. They will
be appended to the filter pipeline in the order in which they appear

- `blosc = true | level`: set the [`Filters.BloscFilter`](ref) compression filter;
  argument can be either `true`, or the compression level.

- `deflate = true | level`: set the [`Filters.Deflate`](@ref) compression filter; argument
  can be either `true`, or the compression level.

- `fletcher32 = true`: set the [`Filters.Fletcher32`](@ref) checksum filter.

- `shuffle = true`: set the [`Filters.Shuffle`](@ref) filter.

"""
@propertyclass(DatasetCreate, API.H5P_DATASET_CREATE, ObjectCreate)
_propertynames(::Type{DatasetCreatePropertyClass}) = (:alloc_time,
                                                      :blosc,
                                                      :chunk,
                                                      :compress,
                                                      :deflate,
                                                      :external,
                                                      :layout,
                                                      :shuffle,
                                                      )

@enum_property(alloc_time,
               :default     => API.H5D_ALLOC_TIME_DEFAULT,
               :early       => API.H5D_ALLOC_TIME_EARLY,
               :incremental => API.H5D_ALLOC_TIME_INCR,
               :late        => API.H5D_ALLOC_TIME_LATE)



# reverse indices
get_chunk(p::Properties) = tuple(convert(Vector{Int}, reverse(API.h5p_get_chunk(p)))...)
set_chunk!(p::Properties, dims) = API.h5p_set_chunk(p, length(dims), API.hsize_t[reverse(dims)...])

@enum_property(layout,
               :compact    => API.H5D_COMPACT,
               :contiguous => API.H5D_CONTIGUOUS,
               :chunked    => API.H5D_CHUNKED,
               :virtual    => API.H5D_VIRTUAL)


function _getproperty(::Type{DatasetCreatePropertyClass}, p::Properties, name::Symbol)
    name === :alloc_time  ? get_alloc_time(p) :
    name === :chunk       ? get_chunk(p) :
    #name === :external    ? API.h5p_get_external(p) :
    name === :filters     ? Filters.get_filters(p) :
    name === :layout      ? get_layout(p) :
    _getproperty(supertype(DatasetCreatePropertyClass), p, name)
end
function _setproperty!(::Type{DatasetCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :alloc_time  ? set_alloc_time!(p, val) :
    name === :chunk       ? set_chunk!(p, val) :
    name === :external    ? API.h5p_set_external(p, val...) :
    name === :filters     ? Filters.set_filters!(p, val) :
    name === :layout      ? set_layout!(p, val) :
    # set-only
    name === :blosc       ? Filters.set_blosc!(p, val) :
    name === :deflate     ? Filters.set_deflate!(p, val) :
    name === :fletcher32  ? Filters.set_fletcher32!(p, val) :
    name === :shuffle     ? Filters.set_shuffle!(p, val) :    
    # deprecated
    name === :compress    ? (depwarn("`compress=$val` keyword option is deprecated, use `deflate=$val` instead",:compress); Filters.set_deflate!(p, val)) :
    _setproperty!(supertype(DatasetCreatePropertyClass), p, name, val)
end

@propertyclass(StringCreate, API.H5P_STRING_CREATE)
@enum_property(char_encoding,
               :ascii => API.H5T_CSET_ASCII,
               :utf8  => API.H5T_CSET_UTF8)
    

_propertynames(::Type{StringCreatePropertyClass}) = (:char_encoding,)
function _getproperty(::Type{StringCreatePropertyClass}, p::Properties, name::Symbol)
    name === :char_encoding ? get_char_encoding(p) :
    _getproperty(supertype(StringCreatePropertyClass), p, name)
end
function _setproperty!(::Type{StringCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :char_encoding ? set_char_encoding!(p, val) :
    _setproperty!(supertype(StringCreatePropertyClass), p, name, val)
end

"""
    LinkCreateProperties(;kws...)

Properties used when creating links.

- `char_encoding`: the character enconding, either `:ascii` or `:utf8`.
- `create_intermediate_group :: Bool`: if `true`, will create missing intermediate groups
"""
@propertyclass(LinkCreate, API.H5P_LINK_CREATE, StringCreate)

@bool_property(create_intermediate_group)

_propertynames(::Type{LinkCreatePropertyClass}) = (:create_intermediate_group,)
function _getproperty(::Type{LinkCreatePropertyClass}, p::Properties, name::Symbol)
    name === :create_intermediate_group ? get_create_intermediate_group(p) :
    _getproperty(supertype(LinkCreatePropertyClass), p, name)
end
function _setproperty!(::Type{LinkCreatePropertyClass}, p::Properties, name::Symbol, val)
    name === :create_intermediate_group ? set_create_intermediate_group!(p, val) :
    _setproperty!(supertype(LinkCreatePropertyClass), p, name, val)
end

"""
    AttributeCreateProperties(;kws...)

Properties used when creating attributes.

- `char_encoding`: the character enconding, either `:ascii` or `:utf8`.
"""
@propertyclass(AttributeCreate, API.H5P_ATTRIBUTE_CREATE, StringCreate)


"""
    FileAccessProperties(;kws...)

Properties used when accessing files.

- `alignment :: Tuple{Integer, Integer}`: a `(threshold, alignment)` pair: any file object
  greater than or equal in size to threshold bytes will be aligned on an address which is
  a multiple of alignment. Default values are 1, implying no alignment.

- `driver`: the file driver used to access the file. See [Drivers](@ref).

- `driver_info` (get only)

- `fclose_degree`: file close degree property. One of:

  - `:weak`
  - `:semi`
  - `:strong`
  - `:default`

- `libver_bounds`: a `(low, high)` pair: `low` sets the earliest possible format versions
  that the library will use when creating objects in the file; `high` sets the latest
  format versions that the library will be allowed to use when creating objects in the
  file. Possible values are:

  - `:earliest`
  - `v"1.8"`
  - `v"1.10"`
  - `v"1.12"`
  - `:latest` (an alias for the latest version)

  See $(h5doc("H5P_SET_LIBVER_BOUNDS"))

"""
@propertyclass(FileAccess, API.H5P_FILE_ACCESS)


@enum_property(fclose_degree,
               :weak    => API.H5F_CLOSE_WEAK,
               :semi    => API.H5F_CLOSE_SEMI,
               :strong  => API.H5F_CLOSE_STRONG,
               :default => API.H5F_CLOSE_DEFAULT)


libver_bound_to_enum(val::Integer) = val
function libver_bound_to_enum(val::VersionNumber)
    val >= v"1.12"   ? API.H5F_LIBVER_V112 :
    val >= v"1.10"   ? API.H5F_LIBVER_V110 :
    val >= v"1.8"    ? API.H5F_LIBVER_V18 :
    throw(ArgumentError("libver_bound must be >= v\"1.8\"."))
end
function libver_bound_to_enum(val::Symbol)
    val == :earliest ? API.H5F_LIBVER_EARLIEST :
    val == :latest   ? libver_bound_to_enum(libversion) :
    throw(ArgumentError("Invalid libver_bound $val."))
end
function libver_bound_from_enum(enum)
    enum == API.H5F_LIBVER_EARLIEST ? :earliest :
    enum == API.H5F_LIBVER_V18      ? v"1.8" :
    enum == API.H5F_LIBVER_V110     ? v"1.10" :
    enum == API.H5F_LIBVER_V112     ? v"1.12" :
    error("Unknown libver_bound value $enum")
end

function get_libver_bounds(p::Properties)
    low, high = API.h5p_get_libver_bounds(p)
    return libver_bound_from_enum(low), libver_bound_from_enum(high)
end
function set_libver_bounds!(p::Properties, (low, high)::Tuple{Any,Any})
    API.h5p_set_libver_bounds(p, libver_bound_to_enum(low), libver_bound_to_enum(high))
end
function set_libver_bounds!(p::Properties, val)
    API.h5p_set_libver_bounds(p, libver_bound_to_enum(val), libver_bound_to_enum(val))
end

_propertynames(::Type{FileAccessPropertyClass}) = (:alignment,
                                                   :driver,
                                                   :driver_info,
                                                   :fapl_mpio,
                                                   :fclose_degree,
                                                   :libver_bounds,)

function _getproperty(::Type{FileAccessPropertyClass}, p::Properties, name::Symbol)
    name === :alignment     ? API.h5p_get_alignment(p) :
    name === :driver        ? Drivers.get_driver(p) :
    name === :driver_info   ? API.h5p_get_driver_info(p) :
    name === :fclose_degree ? get_fclose_degree(p) :
    name === :libver_bounds ? get_libver_bounds(p) :
    # deprecated
    name === :fapl_mpio     ? (depwarn("The `fapl_mpio=...` property is deprecated, use `driver=HDF5.Drivers.MPIO(...)` instead.", :fapl_mpio); drv = get_driver(p, MPIO); (drv.comm, drv.info)) :
    _getproperty(supertype(FileAccessPropertyClass), p, name)
end
function _setproperty!(::Type{FileAccessPropertyClass}, p::Properties, name::Symbol, val)
    name === :alignment     ? API.h5p_set_alignment(p, val...) :
    name === :fclose_degree ? set_fclose_degree!(p, val) :
    name === :libver_bounds ? set_libver_bounds!(p, val) :
    # deprecated
    name === :fapl_mpio     ? (depwarn("The `fapl_mpio=...` property is deprecated, use `driver=HDF5.Drivers.MPIO(...)` instead.", :fapl_mpio); p.driver = Drivers.MPIO(val...)) :    
    _setproperty!(supertype(FileAccessPropertyClass), p, name, val)
end


@propertyclass(LinkAccess, API.H5P_LINK_ACCESS)
@propertyclass(GroupAccess, API.H5P_GROUP_ACCESS, LinkAccess)
@propertyclass(DatatypeAccess, API.H5P_DATATYPE_ACCESS, LinkAccess)
@propertyclass(DatasetAccess, API.H5P_DATASET_ACCESS, LinkAccess)
@propertyclass(AttributeAccess, API.H5P_ATTRIBUTE_ACCESS, LinkAccess)

"""
    DatasetTransferProperties(;kws...)

Properties used when transferring data to/from datasets

- `dxpl_mpio`: MPI transfer mode: 
   - `:independent`: use independent I/O access (default),
   - `:collective`: use collective I/O access.
"""
@propertyclass(DatasetTransfer, API.H5P_DATASET_XFER)

@enum_property(dxpl_mpio,
               :independent => API.H5FD_MPIO_INDEPENDENT,
               :collective  => API.H5FD_MPIO_COLLECTIVE)

_propertynames(::Type{DatasetTransferPropertyClass}) = (:dxpl_mpio,)
function _getproperty(::Type{DatasetTransferPropertyClass}, p::Properties, name::Symbol)
    name === :dxpl_mpio  ? API.h5p_get_dxpl_mpio(p) :
    _getproperty(supertype(DatasetTransferPropertyClass), p, name)
end
function _setproperty!(::Type{DatasetTransferPropertyClass}, p::Properties, name::Symbol, val)
    name === :dxpl_mpio  ? API.h5p_set_dxpl_mpio(p, val...) :
    _setproperty!(supertype(DatasetTransferPropertyClass), p, name, val)
end
@propertyclass(FileMount, API.H5P_FILE_MOUNT)
@propertyclass(ObjectCopy, API.H5P_OBJECT_COPY)


# Across initializations of the library, the id of various properties
# will change. So don't hard-code the id (important for precompilation)
const UTF8_LINK_PROPERTIES = Ref{LinkCreateProperties}()
_link_properties(::AbstractString) = UTF8_LINK_PROPERTIES[]
const UTF8_ATTRIBUTE_PROPERTIES = Ref{AttributeCreateProperties}()
_attr_properties(::AbstractString) = UTF8_ATTRIBUTE_PROPERTIES[]
const ASCII_LINK_PROPERTIES = Ref{LinkCreateProperties}()
const ASCII_ATTRIBUTE_PROPERTIES = Ref{AttributeCreateProperties}()
