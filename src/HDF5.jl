module HDF5

using Base: unsafe_convert
using Requires: @require
# needed for filter(f, tuple) in julia 1.3
using Compat

import Mmap

### PUBLIC API ###

export
@read, @write,
h5open, h5read, h5write, h5rewrite, h5writeattr, h5readattr,
create_attribute, open_attribute, read_attribute, write_attribute, delete_attribute, rename_attribute, attributes, attrs,
create_dataset, open_dataset, read_dataset, write_dataset,
create_group, open_group,
copy_object, open_object, delete_object, move_link,
create_datatype, commit_datatype, open_datatype,
create_property,
group_info, object_info,
dataspace, datatype,
Filters, Drivers

### The following require module scoping ###

# file, filename, name,
# get_chunk, get_datasets,
# get_access_properties, get_create_properties,
# root, readmmap,
# iscontiguous, iscompact, ischunked,
# ishdf5, ismmappable,
# refresh
# start_swmr_write
# create_external, create_external_dataset

### Types
# H5DataStore, Attribute, File, Group, Dataset, Datatype, Opaque,
# Dataspace, Object, Properties, VLen, ChunkStorage, Reference

h5doc(name) = "[`$name`](https://portal.hdfgroup.org/display/HDF5/$(name))"

include("api/api.jl")

const IDX_TYPE = Ref(API.H5_INDEX_NAME)
const ORDER = Ref(API.H5_ITER_INC)

include("properties.jl")
include("types.jl")
include("file.jl")
include("objects.jl")
include("groups.jl")
include("datatypes.jl")
include("typeconversions.jl")
include("dataspaces.jl")
include("datasets.jl")
include("attributes.jl")
include("readwrite.jl")
include("references.jl")
include("show.jl")

### High-level interface ###

function h5write(filename, name::AbstractString, data; pv...)
    file = h5open(filename, "cw"; pv...)
    try
        write(file, name, data)
    finally
        close(file)
    end
end

function h5read(filename, name::AbstractString; pv...)
    local dat
    fapl = FileAccessProperties(; fclose_degree = :strong)
    pv = setproperties!(fapl; pv...)
    file = h5open(filename, "r", fapl)
    try
        obj = getindex(file, name; pv...)
        dat = read(obj)
        close(obj)
    finally
        close(file)
    end
    dat
end

function h5read(filename, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    local dat
    fapl = FileAccessProperties(; fclose_degree = :strong)
    pv = setproperties!(fapl; pv...)
    file = h5open(filename, "r", fapl)
    try
        obj = getindex(file, name_type_pair[1]; pv...)
        dat = read(obj, name_type_pair[2])
        close(obj)
    finally
        close(file)
    end
    dat
end

function h5read(filename, name::AbstractString, indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}}; pv...)
    local dat
    fapl = FileAccessProperties(; fclose_degree = :strong)
    pv = setproperties!(fapl; pv...)
    file = h5open(filename, "r", fapl)
    try
        dset = getindex(file, name; pv...)
        dat = dset[indices...]
        close(dset)
    finally
        close(file)
    end
    dat
end



function Base.getindex(parent::Union{File,Group}, path::AbstractString; pv...)
    haskey(parent, path) || throw(KeyError(path))
    # Faster than below if defaults are OK
    isempty(pv) && return open_object(parent, path)
    obj_type = gettype(parent, path)
    if obj_type == API.H5I_DATASET
        dapl = DatasetAccessProperties()
        dxpl = DatasetTransferProperties()
        pv = setproperties!(dapl, dxpl; pv...)
        isempty(pv) || error("invalid keyword options $pv")
        return open_dataset(parent, path, dapl, dxpl)
    elseif obj_type == API.H5I_GROUP
        gapl = GroupAccessProperties(; pv...)
        return open_group(parent, path, gapl)
    else#if obj_type == API.H5I_DATATYPE # only remaining choice
        tapl = DatatypeAccessProperties(; pv...)
        return open_datatype(parent, path, tapl)
    end
end

# Assign syntax: obj[path] = value
# Create a dataset with properties: obj[path, prop = val, ...] = val
function Base.setindex!(parent::Union{File,Group}, val, path::Union{AbstractString,Nothing}; pv...)
    need_chunks = any(k in keys(chunked_props) for k in keys(pv))
    have_chunks = any(k == :chunk for k in keys(pv))

    chunk = need_chunks ? heuristic_chunk(val) : Int[]

    # ignore chunked_props (== compression) for empty datasets (issue #246):
    discard_chunks = need_chunks && isempty(chunk)
    if discard_chunks
        pv = pairs(Base.structdiff((; pv...), chunked_props))
    else
        if need_chunks && !have_chunks
            pv = pairs((; chunk = chunk, pv...))
        end
    end
    write(parent, path, val; pv...)
end


# end of high-level interface

include("api_midlevel.jl")


#API.h5s_get_simple_extent_ndims(space_id::API.hid_t) = API.h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)

# Functions that require special handling

const libversion = API.h5_get_libversion()

### Property manipulation ###
get_access_properties(d::Dataset)   = DatasetAccessProperties(API.h5d_get_access_plist(d))
get_access_properties(f::File)      = FileAccessProperties(API.h5f_get_access_plist(f))
get_create_properties(d::Dataset)   = DatasetCreateProperties(API.h5d_get_create_plist(d))
get_create_properties(g::Group)     = GroupCreateProperties(API.h5g_get_create_plist(g))
get_create_properties(f::File)      = FileCreateProperties(API.h5f_get_create_plist(f))
get_create_properties(a::Attribute) = AttributeCreateProperties(API.h5a_get_create_plist(a))


const HAS_PARALLEL = Ref(false)

"""
    has_parallel()

Returns `true` if the HDF5 libraries were compiled with parallel support,
and if parallel functionality was loaded into HDF5.jl.

For the second condition to be true, MPI.jl must be imported before HDF5.jl.
"""
has_parallel() = HAS_PARALLEL[]

function __init__()
    # HDF5.API.__init__() is run first
    #
    # initialize default properties
    ASCII_LINK_PROPERTIES.char_encoding = :ascii
    ASCII_LINK_PROPERTIES.create_intermediate_group = true
    UTF8_LINK_PROPERTIES.char_encoding = :utf8
    UTF8_LINK_PROPERTIES.create_intermediate_group = true
    ASCII_ATTRIBUTE_PROPERTIES.char_encoding = :ascii
    UTF8_ATTRIBUTE_PROPERTIES.char_encoding = :utf8

    @require FileIO="5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" begin
        @require OrderedCollections="bac558e1-5e72-5ebc-8fee-abe8a469f55d" include("fileio.jl")
    end
    @require H5Zblosc="c8ec2601-a99c-407f-b158-e79c03c2f5f7" begin
        set_blosc!(p::Properties, val::Bool) = val && push!(Filters.FilterPipeline(p), H5Zblosc.BloscFilter())
        set_blosc!(p::Properties, level::Integer) = push!(Filters.FilterPipeline(p), H5Zblosc.BloscFilter(level=level))
    end

    return nothing
end

include("deprecated.jl")

end  # module
