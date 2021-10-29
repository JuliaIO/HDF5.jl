abstract type Properties end

include("filters/filters.jl")
include("drivers/drivers.jl")

Base.cconvert(::Type{API.hid_t}, obj::Properties) = obj
Base.unsafe_convert(::Type{API.hid_t}, obj::Properties) = obj.id

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

# By default, properties objects are only initialized lazily
function init!(prop::P) where {P<:Properties}
    if !isvalid(prop)
        prop.id = API.h5p_create(classid(P))
    end
    return prop
end

function (::Type{P})(;kwargs...) where {P <: Properties}
    obj = P(API.H5P_DEFAULT)
    for (k, v) in kwargs
        setproperty!(obj, k, v)
    end
    return obj
end

function Base.getproperty(p::P, name::Symbol) where {P <: Properties}
    name === :id    ? getfield(p, :id) :
    class_getproperty(P, p, name)
end

function Base.setproperty!(p::P, name::Symbol, val) where {P<:Properties}
    if name === :id
        return setfield!(p, :id, API.hid_t(val))
    end
    init!(p)
    class_setproperty!(P, p, name, val)
end

Base.propertynames(p::P) where {P<:Properties} = (all_propertynames(P)..., :id)
all_propertynames(::Type{P}) where {P<:Properties} = (class_propertynames(P)..., all_propertynames(superclass(P))...,)

# defaults: refer to super class
class_getproperty(::Type{P}, props, name) where {P<:Properties} =
    class_getproperty(superclass(P), props, name)
class_setproperty!(::Type{P}, p, name, val) where {P<:Properties} =
    class_setproperty!(superclass(P), p, name, val)
class_propertynames(::Type{P}) where {P<:Properties} = ()



"""
    @propertyclass P classid

Define a new subtype of `P <: Properties` corresponding to a HDF5 property list
with class identifier `classid`.

Once defined, the following interfaces can be defined:

    superclass(::Type{P})

This should return the type from which `P` inherits. If not defined, it will
inherit from `GenericProperties`.

    class_propertynames(::Type{P})

This should return a `Tuple` of `Symbol`s, being the names of the properties
associated with `P`.

    class_getproperty(::Type{P}, p::Properties, name::Symbol)

If `name` is an associated property of type `P`, this should return the value of
the propery, otherwise call `class_getproperty(superclass(P), p, name)`.

    class_setproperty!(::Type{P}, p::Properties, name::Symbol, val)

If `name` is an associated property of type `P`, this should set the value of
the propery, otherwise call `class_setproperty!(superclass(P), p, name, val)`.
"""
macro propertyclass(name, classid)
    expr = quote
        Core.@__doc__ mutable struct $name <: Properties
            id::API.hid_t
            function $name(id)
                obj = new(id)
                finalizer(close, obj)
                obj
            end
        end
        classid(::Type{$name}) = $classid
    end
    return esc(expr)
end


@propertyclass GenericProperties API.H5P_DEFAULT

superclass(::Type{P}) where {P<:Properties} = GenericProperties

class_getproperty(::Type{GenericProperties}, props, name) =
    error("$(typeof(props)) has no property $name")
class_setproperty!(::Type{GenericProperties}, props, name, val) =
    error("$(typeof(props)) has no property $name")
all_propertynames(::Type{GenericProperties}) = ()


# for initializing multiple Properties from a set of keyword arguments
"""
    setproperties!(props::Properties...; kwargs...)

For each `(key, value)` pair in `kwargs`, set the corresponding properties in
each `Properties` object in `props`. Returns a `Dict` of any pairs which didn't
match properties in `props`.
"""
function setproperties!(props::Properties...; kwargs...)
    filter(kwargs) do (k,v)
        found = false
        for prop in props
            if k in all_propertynames(typeof(prop))
                setproperty!(prop,k,v)
                found = true
            end
        end
        return !found
    end
end



###
### Convenience macros for defining getter/setter functions
###

"""
    @tuple_property(name)
"""
macro tuple_property(property)
    get_property = Symbol(:get_,property)
    set_property! = Symbol(:set_,property,:!)
    api_get_property = :(API.$(Symbol(:h5p_get_,property)))
    api_set_property = :(API.$(Symbol(:h5p_set_,property)))
    quote
        function $(esc(get_property))(p::Properties)
            return $api_get_property(p)
        end
        function $(esc(set_property!))(p::Properties, val::Tuple)
            return $api_set_property(p, val...)
        end
    end
end

"""
    @enum_property(name, sym1 => enumvalue1, sym2 => enumvalue2, ...)

Wrap property getter/setter API functions that use enum values to use symbol instead.
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

Wrap property getter/setter API functions that use `0`/`1` to use `Bool` values
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


###
### Define Properties types
###

"""
    ObjectCreateProperties(;kws...)

Properties used when creating a new object. Available options:

- `obj_track_times :: Bool`: governs the recording of times associated with an
  object. If set to `true`, time data will be recorded. See
  $(h5doc("H5P_SET_OBJ_TRACK_TIMES")).

"""
@propertyclass ObjectCreateProperties API.H5P_OBJECT_CREATE

@bool_property(obj_track_times)

class_propertynames(::Type{ObjectCreateProperties}) = (
    :obj_track_times,
    :track_times,
    )
function class_getproperty(::Type{ObjectCreateProperties}, p::Properties, name::Symbol)
    name === :obj_track_times ? get_obj_track_times(p) :
    # deprecated
    name === :track_times ? (depwarn("`track_times` property is deprecated, use `obj_track_times` instead",:track_times); get_obj_track_times(p)) :
    class_getproperty(superclass(ObjectCreateProperties), p, name)
end
function class_setproperty!(::Type{ObjectCreateProperties}, p::Properties, name::Symbol, val)
    name === :obj_track_times ? set_obj_track_times!(p, val) :
    # deprecated
    name === :track_times ? (depwarn("`track_times=$val` keyword option is deprecated, use `obj_track_times=$val` instead",:track_times); set_obj_track_times!(p, val)) :
    class_setproperty!(superclass(ObjectCreateProperties), p, name, val)
end

"""
    GroupCreateProperties(;kws...)

Properties used when creating a new `Group`. Inherits from
[`ObjectCreateProperties`](@ref), with additional options:

- `local_heap_size_hint :: Integer`: the anticipated maximum local heap size in
  bytes. See $(h5doc("H5P_SET_LOCAL_HEAP_SIZE_HINT")).

"""
@propertyclass GroupCreateProperties API.H5P_GROUP_CREATE
superclass(::Type{GroupCreateProperties}) = ObjectCreateProperties

class_propertynames(::Type{GroupCreateProperties}) = (
    :local_heap_size_hint,
    )
function class_getproperty(::Type{GroupCreateProperties}, p::Properties, name::Symbol)
    name === :local_heap_size_hint ? API.h5p_get_local_heap_size_hint(p) :
    class_getproperty(superclass(GroupCreateProperties), p, name)
end
function class_setproperty!(::Type{GroupCreateProperties}, p::Properties, name::Symbol, val)
    name === :local_heap_size_hint ? API.h5p_set_local_heap_size_hint(p, val) :
    class_setproperty!(superclass(GroupCreateProperties), p, name, val)
end

"""
    FileCreateProperties(;kws...)

Properties used when creating a new `Group`. Inherits from
[`GroupCreateProperties`](@ref),  with additional properties:

- `userblock :: Integer`: user block size in bytes. The default user block size
  is 0; it may be set to any power of 2 equal to 512 or greater (512, 1024,
  2048, etc.). See $(h5doc("H5P_SET_USERBLOCK")).

"""
@propertyclass FileCreateProperties API.H5P_FILE_CREATE
superclass(::Type{FileCreateProperties}) = ObjectCreateProperties


class_propertynames(::Type{FileCreateProperties}) = (
    :userblock,
    )
function class_getproperty(::Type{FileCreateProperties}, p::Properties, name::Symbol)
    name === :userblock   ? API.h5p_get_userblock(p) :
    class_getproperty(superclass(FileCreateProperties), p, name)
end
function class_setproperty!(::Type{FileCreateProperties}, p::Properties, name::Symbol, val)
    name === :userblock   ? API.h5p_set_userblock(p, val) :
    class_setproperty!(superclass(FileCreateProperties), p, name, val)
end


"""
    DatatypeCreateProperties(;kws...)

"""
@propertyclass DatatypeCreateProperties API.H5P_DATATYPE_CREATE
superclass(::Type{DatatypeCreateProperties}) = ObjectCreateProperties

"""
    DatasetCreateProperties(;kws...)

Properties used when creating a new `Dataset`. Inherits from
[`ObjectCreateProperties`](@ref), with additional properties:

- `alloc_time`: the timing for the allocation of storage space for a dataset's
  raw data; one of:
   - `:default`

   - `:early`: allocate all space when the dataset is created

   - `:incremental`: Allocate space incrementally, as data is  written to the
     dataset

   - `:late`: Allocate all space when data is first written to the dataset.

  See $(h5doc("H5P_SET_ALLOC_TIME")).

- `chunk`: a tuple containing the size of the chunks to store each dimension.
  See $(h5doc("H5P_SET_CHUNK")) (note that this uses Julia's column-major
  ordering).

- `external`: A tuple of `(name,offset,size)`, See $(h5doc("H5P_SET_EXTERNAL")).

- `filters` (only valid when `layout=:chunked`): a filter or vector of filters
  that are applied to applied to each chunk of a dataset, see [Filters](@ref).
  When accessed, will return a [`Filters.FilterPipeline`](@ref) object that can
  be modified in-place.

- `layout`: the type of storage used to store the raw data for a dataset. Can be
  one of:

   - `:compact`: Store raw data in the dataset object header in file. This
     should only be used for datasets with small amounts of raw data.

   - `:contiguous`: Store raw data separately from the object header in one
     large chunk in the file.

   - `:chunked`: Store raw data separately from the object header as chunks of
     data in separate locations in the file.

   - `:virtual`:  Draw raw data from multiple datasets in different files.

  See $(h5doc("H5P_SET_LAYOUT")).


The following options are shortcuts for the various filters, and are set-only.
They will be appended to the filter pipeline in the order in which they appear

- `blosc = true | level`: set the [`Filters.BloscFilter`](@ref) compression
  filter; argument can be either `true`, or the compression level.

- `deflate = true | level`: set the [`Filters.Deflate`](@ref) compression
  filter; argument can be either `true`, or the compression level.

- `fletcher32 = true`: set the [`Filters.Fletcher32`](@ref) checksum filter.

- `shuffle = true`: set the [`Filters.Shuffle`](@ref) filter.

"""
@propertyclass DatasetCreateProperties API.H5P_DATASET_CREATE
superclass(::Type{DatasetCreateProperties}) = ObjectCreateProperties

@enum_property(alloc_time,
    :default     => API.H5D_ALLOC_TIME_DEFAULT,
    :early       => API.H5D_ALLOC_TIME_EARLY,
    :incremental => API.H5D_ALLOC_TIME_INCR,
    :late        => API.H5D_ALLOC_TIME_LATE)

# reverse indices
function get_chunk(p::Properties)
    dims, N = API.h5p_get_chunk(p)
    ntuple(i -> Int(dims[N-i+1]), N)
end
set_chunk!(p::Properties, dims) = API.h5p_set_chunk(p, length(dims), API.hsize_t[reverse(dims)...])

@enum_property(layout,
    :compact    => API.H5D_COMPACT,
    :contiguous => API.H5D_CONTIGUOUS,
    :chunked    => API.H5D_CHUNKED,
    :virtual    => API.H5D_VIRTUAL)


# filters getters/setters
get_filters(p::Properties) = Filters.FilterPipeline(p)
set_filters!(p::Properties, val::Filters.Filter) = push!(empty!(Filters.FilterPipeline(p)), val)
set_filters!(p::Properties, vals::Union{Tuple, AbstractVector}) = append!(empty!(Filters.FilterPipeline(p)), vals)

# convenience
set_deflate!(p::Properties, val::Bool) = val && push!(Filters.FilterPipeline(p), Filters.Deflate())
set_deflate!(p::Properties, level::Integer) = push!(Filters.FilterPipeline(p), Filters.Deflate(level=level))
set_shuffle!(p::Properties, val::Bool) = val && push!(Filters.FilterPipeline(p), Filters.Shuffle())
set_fletcher32!(p::Properties, val::Bool) = val && push!(Filters.FilterPipeline(p), Filters.Fletcher32())
set_blosc!(p::Properties, val::Bool) = val && push!(Filters.FilterPipeline(p), Filters.BloscFilter())
set_blosc!(p::Properties, level::Integer) = push!(Filters.FilterPipeline(p), Filters.BloscFilter(level=level))


class_propertynames(::Type{DatasetCreateProperties}) = (
    :alloc_time,
    :chunk,
    :external,
    :filters,
    :layout,
    # convenience
    :blosc,
    :deflate,
    :fletcher32,
    :shuffle,
    # deprecated
    :compress,
    )


function class_getproperty(::Type{DatasetCreateProperties}, p::Properties, name::Symbol)
    name === :alloc_time  ? get_alloc_time(p) :
    name === :chunk       ? get_chunk(p) :
    #name === :external    ? API.h5p_get_external(p) :
    name === :filters     ? get_filters(p) :
    name === :layout      ? get_layout(p) :
    class_getproperty(superclass(DatasetCreateProperties), p, name)
end
function class_setproperty!(::Type{DatasetCreateProperties}, p::Properties, name::Symbol, val)
    name === :alloc_time  ? set_alloc_time!(p, val) :
    name === :chunk       ? set_chunk!(p, val) :
    name === :external    ? API.h5p_set_external(p, val...) :
    name === :filters     ? set_filters!(p, val) :
    name === :layout      ? set_layout!(p, val) :
    # set-only for convenience
    name === :blosc       ? set_blosc!(p, val) :
    name === :deflate     ? set_deflate!(p, val) :
    name === :fletcher32  ? set_fletcher32!(p, val) :
    name === :shuffle     ? set_shuffle!(p, val) :
    # deprecated
    name === :compress    ? (depwarn("`compress=$val` keyword option is deprecated, use `deflate=$val` instead",:class_setproperty!); set_deflate!(p, val)) :
    class_setproperty!(superclass(DatasetCreateProperties), p, name, val)
end

"""
    StringCreateProperties(;kws...)

"""
@propertyclass StringCreateProperties API.H5P_STRING_CREATE

@enum_property(char_encoding,
    :ascii => API.H5T_CSET_ASCII,
    :utf8  => API.H5T_CSET_UTF8)


class_propertynames(::Type{StringCreateProperties}) = (
    :char_encoding,
    )
function class_getproperty(::Type{StringCreateProperties}, p::Properties, name::Symbol)
    name === :char_encoding ? get_char_encoding(p) :
    class_getproperty(superclass(StringCreateProperties), p, name)
end
function class_setproperty!(::Type{StringCreateProperties}, p::Properties, name::Symbol, val)
    name === :char_encoding ? set_char_encoding!(p, val) :
    class_setproperty!(superclass(StringCreateProperties), p, name, val)
end

"""
    LinkCreateProperties(;kws...)

Properties used when creating links.

- `char_encoding`: the character enconding, either `:ascii` or `:utf8`.

- `create_intermediate_group :: Bool`: if `true`, will create missing
  intermediate groups.
"""
@propertyclass LinkCreateProperties API.H5P_LINK_CREATE
superclass(::Type{LinkCreateProperties}) = StringCreateProperties

@bool_property(create_intermediate_group)

class_propertynames(::Type{LinkCreateProperties}) = (
    :create_intermediate_group,
    )
function class_getproperty(::Type{LinkCreateProperties}, p::Properties, name::Symbol)
    name === :create_intermediate_group ? get_create_intermediate_group(p) :
    class_getproperty(superclass(LinkCreateProperties), p, name)
end
function class_setproperty!(::Type{LinkCreateProperties}, p::Properties, name::Symbol, val)
    name === :create_intermediate_group ? set_create_intermediate_group!(p, val) :
    class_setproperty!(superclass(LinkCreateProperties), p, name, val)
end

"""
    AttributeCreateProperties(;kws...)

Properties used when creating attributes.

- `char_encoding`: the character enconding, either `:ascii` or `:utf8`.
"""
@propertyclass AttributeCreateProperties API.H5P_ATTRIBUTE_CREATE
superclass(::Type{AttributeCreateProperties}) = StringCreateProperties


"""
    FileAccessProperties(;kws...)

Properties used when accessing files.

- `alignment :: Tuple{Integer, Integer}`: a `(threshold, alignment)` pair: any
  file object greater than or equal in size to threshold bytes will be aligned
  on an address which is a multiple of alignment. Default values are 1, implying
  no alignment.

- `driver`: the file driver used to access the file. See [Drivers](@ref).

- `driver_info` (get only)

- `fclose_degree`: file close degree property. One of:

  - `:weak`
  - `:semi`
  - `:strong`
  - `:default`

- `libver_bounds`: a `(low, high)` pair: `low` sets the earliest possible format
  versions that the library will use when creating objects in the file; `high`
  sets the latest format versions that the library will be allowed to use when
  creating objects in the file. Values can be a `VersionNumber` for the hdf5
  library, `:earliest`, or `:latest` . See $(h5doc("H5P_SET_LIBVER_BOUNDS"))

"""
@propertyclass FileAccessProperties API.H5P_FILE_ACCESS

@tuple_property(alignment)

@enum_property(fclose_degree,
               :weak    => API.H5F_CLOSE_WEAK,
               :semi    => API.H5F_CLOSE_SEMI,
               :strong  => API.H5F_CLOSE_STRONG,
               :default => API.H5F_CLOSE_DEFAULT)

# getter/setter for libver_bounds
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


class_propertynames(::Type{FileAccessProperties}) = (
    :alignment,
    :driver,
    :driver_info,
    :fapl_mpio,
    :fclose_degree,
    :libver_bounds,
    )

function class_getproperty(::Type{FileAccessProperties}, p::Properties, name::Symbol)
    name === :alignment     ? get_alignment(p) :
    name === :driver        ? Drivers.get_driver(p) :
    name === :driver_info   ? API.h5p_get_driver_info(p) : # get only
    name === :fclose_degree ? get_fclose_degree(p) :
    name === :libver_bounds ? get_libver_bounds(p) :
    # deprecated
    name === :fapl_mpio     ? (depwarn("The `fapl_mpio` property is deprecated, use `driver=HDF5.Drivers.MPIO(...)` instead.", :fapl_mpio); drv = get_driver(p, MPIO); (drv.comm, drv.info)) :
    class_getproperty(superclass(FileAccessProperties), p, name)
end
function class_setproperty!(::Type{FileAccessProperties}, p::Properties, name::Symbol, val)
    name === :alignment     ? set_alignment!(p, val) :
    name === :driver        ? Drivers.set_driver!(p, val) :
    name === :fclose_degree ? set_fclose_degree!(p, val) :
    name === :libver_bounds ? set_libver_bounds!(p, val) :
    # deprecated
    name === :fapl_mpio     ? (depwarn("The `fapl_mpio` property is deprecated, use `driver=HDF5.Drivers.MPIO(...)` instead.", :fapl_mpio); p.driver = Drivers.MPIO(val...)) :
    class_setproperty!(superclass(FileAccessProperties), p, name, val)
end


@propertyclass LinkAccessProperties API.H5P_LINK_ACCESS

@propertyclass GroupAccessProperties API.H5P_GROUP_ACCESS
superclass(::Type{GroupAccessProperties}) = LinkAccessProperties

@propertyclass DatatypeAccessProperties API.H5P_DATATYPE_ACCESS
superclass(::Type{DatatypeAccessProperties}) = LinkAccessProperties

@propertyclass DatasetAccessProperties API.H5P_DATASET_ACCESS
superclass(::Type{DatasetAccessProperties}) = LinkAccessProperties

@propertyclass AttributeAccessProperties API.H5P_ATTRIBUTE_ACCESS
superclass(::Type{AttributeAccessProperties}) = LinkAccessProperties

"""
    DatasetTransferProperties(;kws...)

Properties used when transferring data to/from datasets

- `dxpl_mpio`: MPI transfer mode:
   - `:independent`: use independent I/O access (default),
   - `:collective`: use collective I/O access.
"""
@propertyclass DatasetTransferProperties API.H5P_DATASET_XFER

@enum_property(dxpl_mpio,
               :independent => API.H5FD_MPIO_INDEPENDENT,
               :collective  => API.H5FD_MPIO_COLLECTIVE)

class_propertynames(::Type{DatasetTransferProperties}) = (
    :dxpl_mpio,
    )
function class_getproperty(::Type{DatasetTransferProperties}, p::Properties, name::Symbol)
    name === :dxpl_mpio  ? get_dxpl_mpio(p) :
    class_getproperty(superclass(DatasetTransferProperties), p, name)
end
function class_setproperty!(::Type{DatasetTransferProperties}, p::Properties, name::Symbol, val)
    name === :dxpl_mpio  ? set_dxpl_mpio!(p, val) :
    class_setproperty!(superclass(DatasetTransferProperties), p, name, val)
end

@propertyclass FileMountProperties API.H5P_FILE_MOUNT
@propertyclass ObjectCopyProperties API.H5P_OBJECT_COPY


const DEFAULT_PROPERTIES = GenericProperties()
# These properties are initialized in __init__()
const ASCII_LINK_PROPERTIES = LinkCreateProperties()
const UTF8_LINK_PROPERTIES = LinkCreateProperties()
const ASCII_ATTRIBUTE_PROPERTIES = AttributeCreateProperties()
const UTF8_ATTRIBUTE_PROPERTIES = AttributeCreateProperties()

_link_properties(::AbstractString) = UTF8_LINK_PROPERTIES
_attr_properties(::AbstractString) = UTF8_ATTRIBUTE_PROPERTIES
