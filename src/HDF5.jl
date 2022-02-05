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
create_attribute, open_attribute, read_attribute, write_attribute, delete_attribute, attributes,
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
include("properties.jl")

### Generic H5DataStore interface ###

# Common methods that could be applicable to any interface for reading/writing variables from a file, e.g. HDF5, JLD, or MAT files.
# Types inheriting from H5DataStore should have names, read, and write methods.
# Supertype of HDF5.File, HDF5.Group, JldFile, JldGroup, Matlabv5File, and MatlabHDF5File.
abstract type H5DataStore end

# Convenience macros
macro read(fid, sym)
    !isa(sym, Symbol) && error("Second input to @read must be a symbol (i.e., a variable)")
    esc(:($sym = read($fid, $(string(sym)))))
end
macro write(fid, sym)
    !isa(sym, Symbol) && error("Second input to @write must be a symbol (i.e., a variable)")
    esc(:(write($fid, $(string(sym)), $sym)))
end

# Read a list of variables, read(parent, "A", "B", "x", ...)
function Base.read(parent::H5DataStore, name::AbstractString...)
    tuple((read(parent, x) for x in name)...)
end

# Read every variable in the file
function Base.read(f::H5DataStore)
    vars = keys(f)
    vals = Vector{Any}(undef,length(vars))
    for i = 1:length(vars)
        vals[i] = read(f, vars[i])
    end
    Dict(zip(vars, vals))
end


## HDF5 uses a plain integer to refer to each file, group, or
## dataset. These are wrapped into special types in order to allow
## method dispatch.

# Note re finalizers: we use them to ensure that objects passed back
# to the user will eventually be cleaned up properly. However, since
# finalizers don't run on a predictable schedule, we also call close
# directly on function exit. (This avoids certain problems, like those
# that occur when passing a freshly-created file to some other
# application).

# This defines an "unformatted" HDF5 data file. Formatted files are defined in separate modules.
mutable struct File <: H5DataStore
    id::API.hid_t
    filename::String

    function File(id, filename, toclose::Bool=true)
        f = new(id, filename)
        if toclose
            finalizer(close, f)
        end
        f
    end
end
Base.cconvert(::Type{API.hid_t}, f::File) = f.id

mutable struct Group <: H5DataStore
    id::API.hid_t
    file::File         # the parent file

    function Group(id, file)
        g = new(id, file)
        finalizer(close, g)
        g
    end
end
Base.cconvert(::Type{API.hid_t}, g::Group) = g.id

mutable struct Dataset
    id::API.hid_t
    file::File
    xfer::DatasetTransferProperties

    function Dataset(id, file, xfer = DatasetTransferProperties())
        dset = new(id, file, xfer)
        finalizer(close, dset)
        dset
    end
end
Base.cconvert(::Type{API.hid_t}, dset::Dataset) = dset.id

mutable struct Datatype
    id::API.hid_t
    toclose::Bool
    file::File

    function Datatype(id, toclose::Bool=true)
        nt = new(id, toclose)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
    function Datatype(id, file::File, toclose::Bool=true)
        nt = new(id, toclose, file)
        if toclose
            finalizer(close, nt)
        end
        nt
    end
end
Base.cconvert(::Type{API.hid_t}, dtype::Datatype) = dtype.id
Base.hash(dtype::Datatype, h::UInt) = hash(dtype.id, hash(Datatype, h))
Base.:(==)(dt1::Datatype, dt2::Datatype) = API.h5t_equal(dt1, dt2)

# Define an H5O Object type
const Object = Union{Group,Dataset,Datatype}

mutable struct Dataspace
    id::API.hid_t

    function Dataspace(id)
        dspace = new(id)
        finalizer(close, dspace)
        dspace
    end
end
Base.cconvert(::Type{API.hid_t}, dspace::Dataspace) = dspace.id
Base.:(==)(dspace1::Dataspace, dspace2::Dataspace) = API.h5s_extent_equal(checkvalid(dspace1), checkvalid(dspace2))
Base.hash(dspace::Dataspace, h::UInt) = hash(dspace.id, hash(Dataspace, h))
Base.copy(dspace::Dataspace) = Dataspace(API.h5s_copy(checkvalid(dspace)))

mutable struct Attribute
    id::API.hid_t
    file::File

    function Attribute(id, file)
        dset = new(id, file)
        finalizer(close, dset)
        dset
    end
end
Base.cconvert(::Type{API.hid_t}, attr::Attribute) = attr.id

struct Attributes
    parent::Union{File,Object}
end
attributes(p::Union{File,Object}) = Attributes(p)

include("typeconversions.jl")
include("show.jl")

# heuristic chunk layout (return empty array to disable chunking)
function heuristic_chunk(T, shape)
    Ts = sizeof(T)
    sz = prod(shape)
    sz == 0 && return Int[] # never return a zero-size chunk
    chunk = [shape...]
    nd = length(chunk)
    # simplification of ugly heuristic target chunk size from PyTables/h5py:
    target = min(1500000, max(12000, floor(Int, 300*cbrt(Ts*sz))))
    Ts > target && return ones(chunk)
    # divide last non-unit dimension by 2 until we get <= target
    # (since Julia default to column-major, favor contiguous first dimension)
    while Ts*prod(chunk) > target
        i = nd
        while chunk[i] == 1
            i -= 1
        end
        chunk[i] >>= 1
    end
    return chunk
end
heuristic_chunk(T, ::Tuple{}) = Int[]
heuristic_chunk(A::AbstractArray{T}) where {T} = heuristic_chunk(T, size(A))
heuristic_chunk(x) = Int[]
# (strings are saved as scalars, and hence cannot be chunked)

### High-level interface ###

"""
    h5open(filename::AbstractString, mode::AbstractString="r"; swmr=false, pv...)

Open or create an HDF5 file where `mode` is one of:
 - "r"  read only
 - "r+" read and write
 - "cw" read and write, create file if not existing, do not truncate
 - "w"  read and write, create a new file (destroys any existing contents)

Pass `swmr=true` to enable (Single Writer Multiple Reader) SWMR write access for "w" and
"r+", or SWMR read access for "r".
"""
function h5open(filename::AbstractString, mode::AbstractString, fapl::FileAccessProperties, fcpl::FileCreateProperties=FileCreateProperties(); swmr::Bool = false)
    rd, wr, cr, tr, ff =
        mode == "r"  ? (true,  false, false, false, false) :
        mode == "r+" ? (true,  true,  false, false, true ) :
        mode == "cw" ? (false, true,  true,  false, true ) :
        mode == "w"  ? (false, true,  true,  true,  false) :
        # mode == "w+" ? (true,  true,  true,  true,  false) :
        # mode == "a"  ? (true,  true,  true,  true,  true ) :
        error("invalid open mode: ", mode)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end

    if cr && (tr || !isfile(filename))
        flag = swmr ? API.H5F_ACC_TRUNC|API.H5F_ACC_SWMR_WRITE : API.H5F_ACC_TRUNC
        fid = API.h5f_create(filename, flag, fcpl, fapl)
    else
        ishdf5(filename) || error("unable to determine if $filename is accessible in the HDF5 format (file may not exist)")
        if wr
            flag = swmr ? API.H5F_ACC_RDWR|API.H5F_ACC_SWMR_WRITE : API.H5F_ACC_RDWR
        else
            flag = swmr ? API.H5F_ACC_RDONLY|API.H5F_ACC_SWMR_READ : API.H5F_ACC_RDONLY
        end
        fid = API.h5f_open(filename, flag, fapl)
    end
    return File(fid, filename)
end


function h5open(filename::AbstractString, mode::AbstractString = "r"; swmr::Bool = false, pv...)
    # With garbage collection, the other modes don't make sense
    fapl = FileAccessProperties(; fclose_degree = :strong)
    fcpl = FileCreateProperties()
    pv = setproperties!(fapl, fcpl; pv...)
    isempty(pv) || error("invalid keyword options $pv")
    file = h5open(filename, mode, fapl, fcpl; swmr=swmr)
    close(fapl)
    close(fcpl)
    return file
end


"""
    function h5open(f::Function, args...; swmr=false, pv...)

Apply the function f to the result of `h5open(args...;kwargs...)` and close the resulting
`HDF5.File` upon completion. For example with a `do` block:

    h5open("foo.h5","w") do h5
        h5["foo"]=[1,2,3]
    end

"""
function h5open(f::Function, args...; swmr=false, pv...)
    file = h5open(args...; swmr=swmr, pv...)
    try
        f(file)
    finally
        close(file)
    end
end

function h5rewrite(f::Function, filename::AbstractString, args...)
    tmppath,tmpio = mktemp(dirname(filename))
    close(tmpio)

    try
        val = h5open(f, tmppath, "w", args...)
        Base.Filesystem.rename(tmppath, filename)
        return val
    catch
        Base.Filesystem.unlink(tmppath)
        rethrow()
    end
end

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

function h5writeattr(filename, name::AbstractString, data::Dict)
    file = h5open(filename, "r+")
    try
        obj = file[name]
        attrs = attributes(obj)
        for x in keys(data)
            attrs[x] = data[x]
        end
        close(obj)
    finally
        close(file)
    end
end

function h5readattr(filename, name::AbstractString)
    local dat
    file = h5open(filename,"r")
    try
        obj = file[name]
        a = attributes(obj)
        dat = Dict(x => read(a[x]) for x in keys(a))
        close(obj)
    finally
        close(file)
    end
    dat
end

# Ensure that objects haven't been closed
Base.isvalid(obj::Union{File,Datatype,Dataspace}) = obj.id != -1 && API.h5i_is_valid(obj)
Base.isvalid(obj::Union{Group,Dataset,Attribute}) = obj.id != -1 && obj.file.id != -1 && API.h5i_is_valid(obj)
Base.isvalid(obj::Attributes) = isvalid(obj.parent)
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Close functions

# Close functions that should try calling close regardless
function Base.close(obj::File)
    if obj.id != -1
        API.h5f_close(obj)
        obj.id = -1
    end
    nothing
end

"""
    isopen(obj::HDF5.File)

Returns `true` if `obj` has not been closed, `false` if it has been closed.
"""
Base.isopen(obj::File) = obj.id != -1


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

function Base.close(obj::Attribute)
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            API.h5a_close(obj)
        end
        obj.id = -1
    end
    nothing
end

function Base.close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            API.h5o_close(obj)
        end
        obj.id = -1
    end
    nothing
end

function Base.close(obj::Dataspace)
    if obj.id != -1
        if isvalid(obj)
            API.h5s_close(obj)
        end
        obj.id = -1
    end
    nothing
end

"""
    ishdf5(name::AbstractString)

Returns `true` if the file specified by `name` is in the HDF5 format, and `false` otherwise.
"""
function ishdf5(name::AbstractString)
    isfile(name) || return false # fastpath in case the file is non-existant
    # TODO: v1.12 use the more robust API.h5f_is_accesible
    try
        # docs falsely claim API.h5f_is_hdf5 doesn't error, but it does
        return API.h5f_is_hdf5(name)
    catch
        return false
    end
end

# Extract the file
file(f::File) = f
file(o::Union{Object,Attribute}) = o.file
fd(obj::Object) = API.h5i_get_file_id(checkvalid(obj))

# Flush buffers
Base.flush(f::Union{Object,Attribute,Datatype,File}, scope = API.H5F_SCOPE_GLOBAL) = API.h5f_flush(checkvalid(f), scope)

# Open objects
open_group(parent::Union{File,Group}, name::AbstractString, gapl::GroupAccessProperties=GroupAccessProperties()) =
    Group(API.h5g_open(checkvalid(parent), name, gapl), file(parent))
open_dataset(parent::Union{File,Group}, name::AbstractString,
    dapl::DatasetAccessProperties=DatasetAccessProperties(), dxpl::DatasetTransferProperties=DatasetTransferProperties()) =
    Dataset(API.h5d_open(checkvalid(parent), name, dapl), file(parent), dxpl)
open_datatype(parent::Union{File,Group}, name::AbstractString, tapl::DatatypeAccessProperties=DatatypeAccessProperties()) =
    Datatype(API.h5t_open(checkvalid(parent), name, tapl), file(parent))
open_attribute(parent::Union{File,Object}, name::AbstractString, aapl::AttributeAccessProperties=AttributeAccessProperties()) =
    Attribute(API.h5a_open(checkvalid(parent), name, aapl), file(parent))
# Object (group, named datatype, or dataset) open
function h5object(obj_id::API.hid_t, parent)
    obj_type = API.h5i_get_type(obj_id)
    obj_type == API.H5I_GROUP ? Group(obj_id, file(parent)) :
    obj_type == API.H5I_DATATYPE ? Datatype(obj_id, file(parent)) :
    obj_type == API.H5I_DATASET ? Dataset(obj_id, file(parent)) :
    error("Invalid object type for path ", path)
end
open_object(parent, path::AbstractString) = h5object(API.h5o_open(checkvalid(parent), path, API.H5P_DEFAULT), parent)
function gettype(parent, path::AbstractString)
    obj_id = API.h5o_open(checkvalid(parent), path, API.H5P_DEFAULT)
    obj_type = API.h5i_get_type(obj_id)
    API.h5o_close(obj_id)
    return obj_type
end
# Get the root group
root(h5file::File) = open_group(h5file, "/")
root(obj::Union{Group,Dataset}) = open_group(file(obj), "/")

function Base.getindex(dset::Dataset, name::AbstractString)
    haskey(dset, name) || throw(KeyError(name))
    open_attribute(dset, name)
end
function Base.getindex(x::Attributes, name::AbstractString)
    haskey(x, name) || throw(KeyError(name))
    open_attribute(x.parent, name)
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

# Path manipulation
function split1(path::AbstractString)
    ind = findfirst('/', path)
    isnothing(ind) && return path, ""
    if ind == 1 # matches root group
        return "/", path[2:end]
    else
        indm1, indp1 = prevind(path, ind), nextind(path, ind)
        return path[1:indm1], path[indp1:end] # better to use begin:indm1, but only available on v1.5
    end
end

function create_group(parent::Union{File,Group}, path::AbstractString,
                  lcpl::LinkCreateProperties=_link_properties(path),
                  gcpl::GroupCreateProperties=GroupCreateProperties())
    haskey(parent, path) && error("cannot create group: object \"", path, "\" already exists at ", name(parent))
    Group(API.h5g_create(parent, path, lcpl, gcpl, API.H5P_DEFAULT), file(parent))
end

# Setting dset creation properties with name/value pairs
"""
    create_dataset(parent, path, datatype, dataspace; properties...)

# Arguments
* `parent` - `File` or `Group`
* `path` - String describing the path of the dataset within the HDF5 file
* `datatype` - `Datatype` or `Type` or the dataset
* `dataspace` - `Dataspace` or `Dims` of the dataset
* `properties` - keyword name-value pairs set properties of the dataset

# Keywords

There are many keyword properties that can be set. Below are a few select keywords.
* `chunk` - `Dims` describing the size of a chunk. Needed to apply filters.
* `filters` - `AbstractVector{<: Filters.Filter}` describing the order of the filters to apply to the data. See [`Filters`](@ref)
* `external` - `Tuple{AbstractString, Intger, Integer}` `(filepath, offset, filesize)` External dataset file location, data offset, and file size. See [`API.h5p_set_external`](@ref).

See also
* [`H5P`](@ref H5P)
* [`DatasetCreateProperties`](@ref)
* [`DatasetTransferProperties`](@ref)
* [`DatasetAccessProperties`](@ref)
"""
function create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace; pv...)
    haskey(parent, path) && error("cannot create dataset: object \"", path, "\" already exists at ", name(parent))
    dcpl = DatasetCreateProperties()
    dxpl = DatasetTransferProperties()
    dapl = DatasetAccessProperties()
    pv = setproperties!(dcpl,dxpl,dapl; pv...)
    isempty(pv) || error("invalid keyword options")
    Dataset(API.h5d_create(parent, path, dtype, dspace, _link_properties(path), dcpl, dapl), file(parent), dxpl)
end
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Dims; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims); pv...)
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Type, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)

# Note that H5Tcreate is very different; H5Tcommit is the analog of these others
create_datatype(class_id, sz) = Datatype(API.h5t_create(class_id, sz))
function commit_datatype(parent::Union{File,Group}, path::AbstractString, dtype::Datatype,
                  lcpl::LinkCreateProperties=LinkCreateProperties(),
                  tcpl::DatatypeCreateProperties=DatatypeCreateProperties(),
                  tapl::DatatypeAccessProperties=DatatypeAccessProperties())
    lcpl.char_encoding = cset(typeof(path))
    API.h5t_commit(checkvalid(parent), path, dtype, lcpl, tcpl, tapl)
    dtype.file = file(parent)
    return dtype
end

function create_attribute(parent::Union{File,Object}, name::AbstractString, dtype::Datatype, dspace::Dataspace)
    attrid = API.h5a_create(checkvalid(parent), name, dtype, dspace, _attr_properties(name), API.H5P_DEFAULT)
    return Attribute(attrid, file(parent))
end

# Delete objects
delete_attribute(parent::Union{File,Object}, path::AbstractString) = API.h5a_delete(checkvalid(parent), path)
delete_object(parent::Union{File,Group}, path::AbstractString, lapl::LinkAccessProperties=LinkAccessProperties()) =
    API.h5l_delete(checkvalid(parent), path, lapl)
delete_object(obj::Object) = delete_object(parent(obj), ascii(split(name(obj),"/")[end])) # FIXME: remove ascii?

# Copy objects
copy_object(src_parent::Union{File,Group}, src_path::AbstractString, dst_parent::Union{File,Group}, dst_path::AbstractString) = API.h5o_copy(checkvalid(src_parent), src_path, checkvalid(dst_parent), dst_path, API.H5P_DEFAULT, _link_properties(dst_path))
copy_object(src_obj::Object, dst_parent::Union{File,Group}, dst_path::AbstractString) = API.h5o_copy(checkvalid(src_obj), ".", checkvalid(dst_parent), dst_path, API.H5P_DEFAULT, _link_properties(dst_path))

# Move links
move_link(src::Union{File,Group}, src_name::AbstractString, dest::Union{File,Group}, dest_name::AbstractString=src_name, lapl::LinkAccessProperties = LinkAccessProperties(), lcpl::LinkCreateProperties = LinkCreateProperties()) =
    API.h5l_move(checkvalid(src), src_name, checkvalid(dest), dest_name, lcpl, lapl)

move_link(parent::Union{File,Group}, src_name::AbstractString, dest_name::AbstractString, lapl::LinkAccessProperties = LinkAccessProperties(), lcpl::LinkCreateProperties = LinkCreateProperties())  =
    API.h5l_move(checkvalid(parent), src_name, parent, dest_name, lcpl, lapl)

# Assign syntax: obj[path] = value
# Creates a dataset unless obj is a dataset, in which case it creates an attribute
Base.setindex!(dset::Dataset, val, name::AbstractString) = write_attribute(dset, name, val)
Base.setindex!(x::Attributes, val, name::AbstractString) = write_attribute(x.parent, name, val)
# Create a dataset with properties: obj[path, prop = val, ...] = val
function Base.setindex!(parent::Union{File,Group}, val, path::AbstractString; pv...)
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

# Check existence
function Base.haskey(parent::Union{File,Group}, path::AbstractString, lapl::LinkAccessProperties = LinkAccessProperties())
    checkvalid(parent)
    first, rest = split1(path)
    if first == "/"
        parent = root(parent)
    elseif !API.h5l_exists(parent, first, lapl)
        return false
    end
    exists = true
    if !isempty(rest)
        obj = parent[first]
        exists = haskey(obj, rest, lapl)
        close(obj)
    end
    return exists
end
Base.haskey(attr::Attributes, path::AbstractString) = API.h5a_exists(checkvalid(attr.parent), path)
Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) = API.h5a_exists(checkvalid(dset), path)

# Querying items in the file
group_info(obj::Union{Group,File}) = API.h5g_get_info(checkvalid(obj))
object_info(obj::Union{File,Object}) = API.h5o_get_info(checkvalid(obj))

Base.length(obj::Union{Group,File}) = Int(API.h5g_get_num_objs(checkvalid(obj)))
Base.length(x::Attributes) = Int(object_info(x.parent).num_attrs)

Base.isempty(x::Union{Group,File}) = length(x) == 0
Base.eltype(dset::Union{Dataset,Attribute}) = get_jl_type(dset)

# filename and name
filename(obj::Union{File,Group,Dataset,Attribute,Datatype}) = API.h5f_get_name(checkvalid(obj))
name(obj::Union{File,Group,Dataset,Datatype}) = API.h5i_get_name(checkvalid(obj))
name(attr::Attribute) = API.h5a_get_name(attr)
function Base.keys(x::Union{Group,File})
    checkvalid(x)
    children = sizehint!(String[], length(x))
    API.h5l_iterate(x, API.H5_INDEX_NAME, API.H5_ITER_INC) do _, name, _
        push!(children, unsafe_string(name))
        return API.herr_t(0)
    end
    return children
end

function Base.keys(x::Attributes)
    checkvalid(x.parent)
    children = sizehint!(String[], length(x))
    API.h5a_iterate(x.parent, API.H5_INDEX_NAME, API.H5_ITER_INC) do _, attr_name, _
        push!(children, unsafe_string(attr_name))
        return API.herr_t(0)
    end
    return children
end

# iteration by objects
function Base.iterate(parent::Union{File,Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(API.h5o_open_by_idx(checkvalid(parent), ".", API.H5_INDEX_NAME, API.H5_ITER_INC, n-1, API.H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
end

Base.lastindex(dset::Dataset) = length(dset)
Base.lastindex(dset::Dataset, d::Int) = size(dset, d)

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

# Get the datatype of a dataset
datatype(dset::Dataset) = Datatype(API.h5d_get_type(checkvalid(dset)), file(dset))
# Get the datatype of an attribute
datatype(dset::Attribute) = Datatype(API.h5a_get_type(checkvalid(dset)), file(dset))

Base.sizeof(dtype::Datatype) = Int(API.h5t_get_size(dtype))

# Get the dataspace of a dataset
dataspace(dset::Dataset) = Dataspace(API.h5d_get_space(checkvalid(dset)))
# Get the dataspace of an attribute
dataspace(attr::Attribute) = Dataspace(API.h5a_get_space(checkvalid(attr)))

# Create a dataspace from in-memory types
dataspace(x::Union{T, Complex{T}}) where {T<:ScalarType} = Dataspace(API.h5s_create(API.H5S_SCALAR))
dataspace(::AbstractString) = Dataspace(API.h5s_create(API.H5S_SCALAR))

function _dataspace(sz::Dims{N}, max_dims::Union{Dims{N}, Tuple{}}=()) where N
    dims = API.hsize_t[sz[i] for i in N:-1:1]
    if isempty(max_dims)
        maxd = dims
    else
        # This allows max_dims to be specified as -1 without triggering an overflow
        # exception due to the signed -> unsigned conversion.
        maxd = API.hsize_t[API.hssize_t(max_dims[i]) % API.hsize_t for i in N:-1:1]
    end
    return Dataspace(API.h5s_create_simple(length(dims), dims, maxd))
end
dataspace(A::AbstractArray{T,N}; max_dims::Union{Dims{N},Tuple{}} = ()) where {T,N} = _dataspace(size(A), max_dims)
# special array types
dataspace(v::VLen; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(size(v.data), max_dims)
dataspace(A::EmptyArray) = Dataspace(API.h5s_create(API.H5S_NULL))
dataspace(n::Nothing) = Dataspace(API.h5s_create(API.H5S_NULL))
# for giving sizes explicitly
dataspace(sz::Dims{N}; max_dims::Union{Dims{N},Tuple{}}=()) where {N} = _dataspace(sz, max_dims)
dataspace(sz1::Int, sz2::Int, sz3::Int...; max_dims::Union{Dims,Tuple{}}=()) = _dataspace(tuple(sz1, sz2, sz3...), max_dims)


function Base.ndims(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    ret = API.h5s_get_simple_extent_ndims(dspace)
    obj isa Dataspace || close(dspace)
    return ret
end
function Base.size(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    N = length(h5_dims)
    ret = ntuple(i -> @inbounds(Int(h5_dims[N-i+1])), N)
    obj isa Dataspace || close(dspace)
    return ret
end
function Base.size(obj::Union{Dataspace,Dataset,Attribute}, d::Integer)
    d > 0 || throw(ArgumentError("invalid dimension d; must be positive integer"))
    N = ndims(obj)
    d > N && return 1
    dspace = obj isa Dataspace ? obj : dataspace(obj)
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    ret = @inbounds Int(h5_dims[N - d + 1])
    obj isa Dataspace || close(dspace)
    return ret
end
function Base.length(obj::Union{Dataspace,Dataset,Attribute})
    isnull(obj) && return 0
    dspace = obj isa Dataspace ? obj : dataspace(obj)
    h5_dims = API.h5s_get_simple_extent_dims(dspace, nothing)
    ret = Int(prod(h5_dims))
    obj isa Dataspace || close(dspace)
    return ret
end
Base.isempty(dspace::Union{Dataspace,Dataset,Attribute}) = length(dspace) == 0

"""
    isnull(dspace::Union{HDF5.Dataspace, HDF5.Dataset, HDF5.Attribute})

Determines whether the given object has no size (consistent with the `API.H5S_NULL` dataspace).

# Examples
```julia-repl
julia> HDF5.isnull(dataspace(HDF5.EmptyArray{Float64}()))
true

julia> HDF5.isnull(dataspace((0,)))
false
```
"""
function isnull(obj::Union{Dataspace,Dataset,Attribute})
    dspace = obj isa Dataspace ? checkvalid(obj) : dataspace(obj)
    ret = API.h5s_get_simple_extent_type(dspace) == API.H5S_NULL
    obj isa Dataspace || close(dspace)
    return ret
end


function get_regular_hyperslab(dspace::Dataspace)
    start, stride, count, block = API.h5s_get_regular_hyperslab(dspace)
    N = length(start)
    @inline rev(v) = ntuple(i -> @inbounds(Int(v[N-i+1])), N)
    return rev(start), rev(stride), rev(count), rev(block)
end


"""
    start_swmr_write(h5::HDF5.File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://portal.hdfgroup.org/display/HDF5/Single+Writer+Multiple+Reader++-+SWMR).
"""
start_swmr_write(h5::File) = API.h5f_start_swmr_write(h5)

refresh(ds::Dataset) = API.h5d_refresh(checkvalid(ds))
Base.flush(ds::Dataset) = API.h5d_flush(checkvalid(ds))

# Generic read functions
# Generic read functions
function read_dataset(parent::Union{File,Group}, name::AbstractString)
    local ret
    obj = open_dataset(parent, name)
    try
        ret = read(obj)
    finally
        close(obj)
    end
    ret
end

"""
    read_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)

Read the value of the named attribute on the parent object.

# Example
```julia-repl
julia> HDF5.read_attribute(g, "time")
2.45
```
"""
function read_attribute(parent::Union{File,Group,Dataset,Datatype}, name::AbstractString)
    local ret
    obj = open_attribute(parent, name)
    try
        ret = read(obj)
    finally
        close(obj)
    end
    ret
end

function Base.read(parent::Union{File,Group}, name::AbstractString; pv...)
    obj = getindex(parent, name; pv...)
    val = read(obj)
    close(obj)
    val
end

function Base.read(parent::Union{File,Group}, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    obj = getindex(parent, name_type_pair[1]; pv...)
    val = read(obj, name_type_pair[2])
    close(obj)
    val
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5.Datatype. Specific file formats should provide their own read(dset).
const DatasetOrAttribute = Union{Dataset,Attribute}

function Base.read(obj::DatasetOrAttribute)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    val = generic_read(obj, dtype, T)
    close(dtype)
    return val
end

function Base.getindex(obj::DatasetOrAttribute, I...)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

function Base.read(obj::DatasetOrAttribute, ::Type{T}, I...) where T
    dtype = datatype(obj)
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

# `Type{String}` does not have a definite size, so the generic_read does not accept
# it even though it will return a `String`. This explicit overload allows that usage.
function Base.read(obj::DatasetOrAttribute, ::Type{String}, I...)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    T <: Union{Cstring, FixedString} || error(name(obj), " cannot be read as type `String`")
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

# Special handling for reading OPAQUE datasets and attributes
function generic_read(obj::DatasetOrAttribute, filetype::Datatype, ::Type{Opaque})
    sz  = size(obj)
    buf = Matrix{UInt8}(undef, sizeof(filetype), prod(sz))
    if obj isa Dataset
        read_dataset(obj, filetype, buf, obj.xfer)
    else
        read_attribute(obj, filetype, buf)
    end
    tag = API.h5t_get_tag(filetype)
    if isempty(sz)
        # scalar (only) result
        data = vec(buf)
    else
        # array of opaque objects
        data = reshape([buf[:,i] for i in 1:prod(sz)], sz...)
    end
    return Opaque(data, tag)
end

# generic read function
function generic_read(obj::DatasetOrAttribute, filetype::Datatype, ::Type{T}, I...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    !isempty(I) && obj isa Attribute && error("HDF5 attributes do not support hyperslab selections")

    memtype = Datatype(API.h5t_get_native_type(filetype))  # padded layout in memory

    if sizeof(T) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($T) = $(sizeof(T))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

    dspace = dataspace(obj)
    stype = API.h5s_get_simple_extent_type(dspace)
    stype == API.H5S_NULL && return EmptyArray{T}()

    if !isempty(I)
        indices = Base.to_indices(obj, I)
        dspace = hyperslab(dspace, indices...)
    end

    scalar = false
    if stype == API.H5S_SCALAR
        sz = (1,)
        scalar = true
    elseif isempty(I)
        sz = size(dspace)
    else
        sz = map(length, filter(i -> !isa(i, Int), indices))
        if isempty(sz)
            sz = (1,)
            scalar = true
        end
    end

    if do_normalize(T)
        # The entire dataset is read into in a buffer matrix where the first dimension at
        # any stage of normalization is the bytes for a single element of type `T`, and
        # the second dimension of the matrix runs through all elements.
        buf = Matrix{UInt8}(undef, sizeof(T), prod(sz))
    else
        buf = Array{T}(undef, sz...)
    end
    memspace = isempty(I) ? dspace : dataspace(sz)

    if obj isa Dataset
        API.h5d_read(obj, memtype, memspace, dspace, obj.xfer, buf)
    else
        API.h5a_read(obj, memtype, buf)
    end

    if do_normalize(T)
        out = reshape(normalize_types(T, buf), sz...)
    else
        out = buf
    end

    xfer_id = obj isa Dataset ? obj.xfer.id : API.H5P_DEFAULT
    do_reclaim(T) && API.h5d_vlen_reclaim(memtype, memspace, xfer_id, buf)

    close(memtype)
    close(memspace)
    close(dspace)

    if scalar
        return out[1]
    else
        return out
    end
end

# Array constructor for datasets
Array(x::Dataset) = read(x)

# Clean up string buffer according to padding mode
function unpad(s::String, pad::Integer)::String
    if pad == API.H5T_STR_NULLTERM # null-terminated
        ind = findfirst(isequal('\0'), s)
        isnothing(ind) ? s : s[1:prevind(s, ind)]
    elseif pad == API.H5T_STR_NULLPAD # padded with nulls
        rstrip(s, '\0')
    elseif pad == API.H5T_STR_SPACEPAD # padded with spaces
        rstrip(s, ' ')
    else
        error("Unrecognized string padding mode $pad")
    end
end
unpad(s, pad::Integer) = unpad(String(s), pad)

# Dereference
function _deref(parent, r::Reference)
    r == Reference() && error("Reference is null")
    obj_id = API.h5r_dereference(checkvalid(parent), API.H5P_DEFAULT, API.H5R_OBJECT, r)
    h5object(obj_id, parent)
end
Base.getindex(parent::Union{File,Group}, r::Reference) = _deref(parent, r)
Base.getindex(parent::Dataset, r::Reference) = _deref(parent, r) # defined separately to resolve ambiguity

Base.read(attr::Attributes, name::AbstractString) = read_attribute(attr.parent, name)

function iscompact(obj::Dataset)
    prop = API.h5d_get_create_plist(checkvalid(obj))
    try
        API.h5p_get_layout(prop) == API.H5D_COMPACT
    finally
        API.h5p_close(prop)
    end
end

function ischunked(obj::Dataset)
    prop = API.h5d_get_create_plist(checkvalid(obj))
    try
        API.h5p_get_layout(prop) == API.H5D_CHUNKED
    finally
        API.h5p_close(prop)
    end
end

function iscontiguous(obj::Dataset)
    prop = API.h5d_get_create_plist(checkvalid(obj))
    try
        API.h5p_get_layout(prop) == API.H5D_CONTIGUOUS
    finally
        API.h5p_close(prop)
    end
end

# Reading with mmap
ismmappable(::Type{<:ScalarType}) = true
ismmappable(::Type{Complex{T}}) where {T<:BitsType} = true
ismmappable(::Type) = false
ismmappable(obj::Dataset, ::Type{T}) where {T} = ismmappable(T) && iscontiguous(obj)
ismmappable(obj::Dataset) = ismmappable(obj, get_jl_type(obj))

function readmmap(obj::Dataset, ::Type{T}) where {T}
    dspace = dataspace(obj)
    stype = API.h5s_get_simple_extent_type(dspace)
    (stype != API.H5S_SIMPLE) && error("can only mmap simple dataspaces")
    dims = size(dspace)

    if isempty(dims)
        return T[]
    end
    if !Sys.iswindows()
        local fdint
        prop = API.h5d_get_access_plist(obj)
        try
            # TODO: Should check return value of API.h5f_get_driver()
            fdptr = API.h5f_get_vfd_handle(obj.file, prop)
            fdint = unsafe_load(convert(Ptr{Cint}, fdptr))
        finally
            API.h5p_close(prop)
        end
        fd = fdio(fdint)
    else
        # This is a workaround since the regular code path does not work on windows
        # (see #89 for background). The error is that "Mmap.mmap(fd, ...)" cannot
        # create create a valid file mapping. The question is if the handler
        # returned by "API.h5f_get_vfd_handle" has
        # the correct format as required by the "fdio" function. The former
        # calls
        # https://gitlabext.iag.uni-stuttgart.de/libs/hdf5/blob/develop/src/H5FDcore.c#L1209
        #
        # The workaround is to create a new file handle, which should actually
        # not make any problems. Since we need to know the permissions of the
        # original file handle, we first retrieve them using the "API.h5f_get_intent"
        # function

        # Check permissions
        intent = API.h5f_get_intent(obj.file)
        flag = intent == API.H5F_ACC_RDONLY ? "r" : "r+"
        fd = open(obj.file.filename, flag)
    end

    offset = API.h5d_get_offset(obj)
    if offset == -1 % API.haddr_t
        # note that API.h5d_get_offset may not actually raise an error, so we need to check it here
        error("Error getting offset")
    elseif offset % Base.datatype_alignment(T) == 0
        A = Mmap.mmap(fd, Array{T,length(dims)}, dims, offset)
    else
        Aflat = Mmap.mmap(fd, Vector{UInt8}, prod(dims)*sizeof(T), offset)
        A = reshape(reinterpret(T, Aflat), dims)
    end

    if Sys.iswindows()
        close(fd)
    end

    return A
end

function readmmap(obj::Dataset)
    T = get_jl_type(obj)
    ismmappable(T) || error("Cannot mmap datasets of type $T")
    iscontiguous(obj) || error("Cannot mmap discontiguous dataset")
    readmmap(obj, T)
end

# Generic write
function Base.write(parent::Union{File,Group}, name1::AbstractString, val1, name2::AbstractString, val2, nameval...) # FIXME: remove?
    if !iseven(length(nameval))
        error("name, value arguments must come in pairs")
    end
    write(parent, name1, val1)
    write(parent, name2, val2)
    for i = 1:2:length(nameval)
        thisname = nameval[i]
        if !isa(thisname, AbstractString)
            error("Argument ", i+5, " should be a string, but it's a ", typeof(thisname))
        end
        write(parent, thisname, nameval[i+1])
    end
end

# Plain dataset & attribute writes
# Due to method ambiguities we generate these explicitly

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = create_dataset(parent, name, data; properties...)

function create_dataset(parent::Union{File,Group}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        create_dataset(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end
function create_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        create_attribute(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end

# Create and write, closing the objects upon exit
function write_dataset(parent::Union{File,Group}, name::AbstractString, data; pv...)
    obj, dtype = create_dataset(parent, name, data; pv...)
    try
        write_dataset(obj, dtype, data)
    catch exc
        delete_object(obj)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end
function write_attribute(parent::Union{File,Object}, name::AbstractString, data; pv...)
    obj, dtype = create_attribute(parent, name, data; pv...)
    try
        write_attribute(obj, dtype, data)
    catch exc
        delete_attribute(parent, name)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end

# Write to already-created objects
function Base.write(obj::Attribute, x)
    dtype = datatype(x)
    try
        write_attribute(obj, dtype, x)
    finally
        close(dtype)
    end
end
function Base.write(obj::Dataset, x)
    dtype = datatype(x)
    try
        write_dataset(obj, dtype, x)
    finally
        close(dtype)
    end
end

# For plain files and groups, let "write(obj, name, val; properties...)" mean "write_dataset"
Base.write(parent::Union{File,Group}, name::AbstractString, data; pv...) = write_dataset(parent, name, data; pv...)
# For datasets, "write(dset, name, val; properties...)" means "write_attribute"
Base.write(parent::Dataset, name::AbstractString, data; pv...) = write_attribute(parent, name, data; pv...)


# Indexing

Base.eachindex(::IndexLinear, A::Dataset) = Base.OneTo(length(A))
Base.axes(dset::Dataset) = map(Base.OneTo, size(dset))

# Write to a subset of a dataset using array slices: dataset[:,:,10] = array

const IndexType = Union{AbstractRange{Int},Int,Colon}
function Base.setindex!(dset::Dataset, X::Array{T}, I::IndexType...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    U = get_jl_type(dset)

    # perform conversions for numeric types
    if (U <: Number) && (T <: Number) && U !== T
        X = convert(Array{U}, X)
    end

    filetype = datatype(dset)
    memtype = Datatype(API.h5t_get_native_type(filetype))  # padded layout in memory
    close(filetype)

    elT = eltype(X)
    if sizeof(elT) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($elT) = $(sizeof(elT))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

    dspace = dataspace(dset)
    stype = API.h5s_get_simple_extent_type(dspace)
    stype == API.H5S_NULL && error("attempting to write to null dataspace")

    indices = Base.to_indices(dset, I)
    dspace = hyperslab(dspace, indices...)

    memspace = dataspace(X)

    if API.h5s_get_select_npoints(dspace) != API.h5s_get_select_npoints(memspace)
        error("number of elements in src and dest arrays must be equal")
    end

    try
        API.h5d_write(dset, memtype, memspace, dspace, dset.xfer, X)
    finally
        close(memtype)
        close(memspace)
        close(dspace)
    end

    return X
end

function Base.setindex!(dset::Dataset, x::T, I::IndexType...) where T <: Number
    indices = Base.to_indices(dset, I)
    X = fill(x, map(length, indices))
    Base.setindex!(dset, X, indices...)
end

function Base.setindex!(dset::Dataset, X::AbstractArray, I::IndexType...)
    Base.setindex!(dset, Array(X), I...)
end

function hyperslab(dspace::Dataspace, I::Union{AbstractRange{Int},Int}...)
    local dsel_id
    try
        dims = size(dspace)
        n_dims = length(dims)
        if length(I) != n_dims
            error("Wrong number of indices supplied, supplied length $(length(I)) but expected $(n_dims).")
        end
        dsel_id = API.h5s_copy(dspace)
        dsel_start  = Vector{API.hsize_t}(undef,n_dims)
        dsel_stride = Vector{API.hsize_t}(undef,n_dims)
        dsel_count  = Vector{API.hsize_t}(undef,n_dims)
        for k = 1:n_dims
            index = I[n_dims-k+1]
            if isa(index, Integer)
                dsel_start[k] = index-1
                dsel_stride[k] = 1
                dsel_count[k] = 1
            elseif isa(index, AbstractRange)
                dsel_start[k] = first(index)-1
                dsel_stride[k] = step(index)
                dsel_count[k] = length(index)
            else
                error("index must be range or integer")
            end
            if dsel_start[k] < 0 || dsel_start[k]+(dsel_count[k]-1)*dsel_stride[k] >= dims[n_dims-k+1]
                println(dsel_start)
                println(dsel_stride)
                println(dsel_count)
                println(reverse(dims))
                error("index out of range")
            end
        end
        API.h5s_select_hyperslab(dsel_id, API.H5S_SELECT_SET, dsel_start, dsel_stride, dsel_count, C_NULL)
    finally
        close(dspace)
    end
    Dataspace(dsel_id)
end

function hyperslab(dset::Dataset, I::Union{AbstractRange{Int},Int}...)
    dspace = dataspace(dset)
    return hyperslab(dspace, I...)
end

# Link to bytes in an external file
# If you need to link to multiple segments, use low-level interface
function create_external_dataset(parent::Union{File,Group}, name::AbstractString, filepath::AbstractString, t, sz::Dims, offset::Integer=0)
    checkvalid(parent)
    create_dataset(parent, name, datatype(t), dataspace(sz); external=(filepath, offset, prod(sz)*sizeof(t)))
end

"""
    do_write_chunk(dataset::Dataset, offset, chunk_bytes::AbstractArray, filter_mask=0)

Write a raw chunk at a given offset.
`chunk_bytes` is an AbstractArray that can be converted to a pointer, Ptr{Cvoid}.
`offset` is a 1-based list of rank `ndims(dataset)` and must fall on a chunk boundary.
"""
function do_write_chunk(dataset::Dataset, offset, chunk_bytes::AbstractArray, filter_mask=0)
    checkvalid(dataset)
    offs = collect(API.hsize_t, reverse(offset)) .- 1
    write_chunk(dataset, offs, chunk_bytes; filter_mask=UInt32(filter_mask))
end

"""
    do_write_chunk(dataset::Dataset, index, chunk_bytes::AbstractArray, filter_mask=0)

Write a raw chunk at a given linear index.
`chunk_bytes` is an AbstractArray that can be converted to a pointer, Ptr{Cvoid}.
`index` is 1-based and consecutive up to the number of chunks.
"""
function do_write_chunk(dataset::Dataset, index::Integer, chunk_bytes::AbstractArray, filter_mask=0)
    checkvalid(dataset)
    index -= 1
    write_chunk(dataset, index, chunk_bytes; filter_mask=UInt32(filter_mask))
end

"""
    do_read_chunk(dataset::Dataset, offset)

Read a raw chunk at a given offset.
`offset` is a 1-based list of rank `ndims(dataset)` and must fall on a chunk boundary.
"""
function do_read_chunk(dataset::Dataset, offset)
    checkvalid(dataset)
    offs = collect(API.hsize_t, reverse(offset)) .- 1
    filters = Ref{UInt32}()
    buf = read_chunk(dataset, offs; filters = filters)
    return (filters[], buf)
end

"""
    do_read_chunk(dataset::Dataset, index::Integer)

Read a raw chunk at a given index.
`index` is 1-based and consecutive up to the number of chunks.
"""
function do_read_chunk(dataset::Dataset, index::Integer)
    checkvalid(dataset)
    index -= 1
    filters = Ref{UInt32}()
    buf = read_chunk(dataset, index; filters = filters)
    return (filters[], buf)
end

struct ChunkStorage{I<:IndexStyle,N} <: AbstractArray{Tuple{UInt32,Vector{UInt8}},N}
    dataset::Dataset
end
ChunkStorage{I,N}(dataset) where {I,N} = ChunkStorage{I,N}(dataset)
Base.IndexStyle(::ChunkStorage{I}) where {I<:IndexStyle} = I()

# ChunkStorage{IndexCartesian,N} (default)

function ChunkStorage(dataset)
    ChunkStorage{IndexCartesian, ndims(dataset)}(dataset)
end

Base.size(cs::ChunkStorage{IndexCartesian}) = get_num_chunks_per_dim(cs.dataset)


function Base.axes(cs::ChunkStorage{IndexCartesian})
    chunk = get_chunk(cs.dataset)
    extent = size(cs.dataset)
    ntuple(i -> 1:chunk[i]:extent[i], length(extent))
end

# Filter flags provided
function Base.setindex!(chunk_storage::ChunkStorage{IndexCartesian}, v::Tuple{<:Integer,AbstractArray}, index::Integer...)
    do_write_chunk(chunk_storage.dataset, index, v[2], v[1])
end

# Filter flags will default to 0
function Base.setindex!(chunk_storage::ChunkStorage{IndexCartesian}, v::AbstractArray, index::Integer...)
    do_write_chunk(chunk_storage.dataset, index, v)
end

function Base.getindex(chunk_storage::ChunkStorage{IndexCartesian}, index::Integer...)
    do_read_chunk(chunk_storage.dataset, API.hsize_t.(index))
end

# ChunkStorage{IndexLinear,1}

ChunkStorage{IndexLinear}(dataset) = ChunkStorage{IndexLinear,1}(dataset)
Base.size(cs::ChunkStorage{IndexLinear})   = (get_num_chunks(cs.dataset),)
Base.length(cs::ChunkStorage{IndexLinear}) =  get_num_chunks(cs.dataset)

function Base.setindex!(chunk_storage::ChunkStorage{IndexLinear}, v::Tuple{<:Integer,AbstractArray}, index::Integer)
    do_write_chunk(chunk_storage.dataset, index, v[2], v[1])
end

# Filter flags will default to 0
function Base.setindex!(chunk_storage::ChunkStorage{IndexLinear}, v::AbstractArray, index::Integer)
    do_write_chunk(chunk_storage.dataset, index, v)
end

function Base.getindex(chunk_storage::ChunkStorage{IndexLinear}, index::Integer)
    do_read_chunk(chunk_storage.dataset, index)
end

# TODO: Move to show.jl. May need to include show.jl after this line.
# ChunkStorage axes may be StepRanges, but this is not available until v"1.6.0"
# no method matching CartesianIndices(::Tuple{StepRange{Int64,Int64},UnitRange{Int64}}) until v"1.6.0"

function Base.show(io::IO, cs::ChunkStorage{IndexCartesian,N}) where N
    println(io, "HDF5.ChunkStorage{IndexCartesian,$N}")
    print(io, "Axes: ")
    println(io, axes(cs))
    print(io, cs.dataset)
end
Base.show(io::IO, ::MIME{Symbol("text/plain")}, cs::ChunkStorage{IndexCartesian,N}) where {N} = show(io, cs)




# end of high-level interface


include("api_midlevel.jl")


### HDF5 utilities ###


# default behavior
read_attribute(attr::Attribute, memtype::Datatype, buf) = API.h5a_read(attr, memtype, buf)
write_attribute(attr::Attribute, memtype::Datatype, x) = API.h5a_write(attr, memtype, x)
read_dataset(dset::Dataset, memtype::Datatype, buf, xfer::DatasetTransferProperties=dset.xfer) =
    API.h5d_read(dset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
write_dataset(dset::Dataset, memtype::Datatype, x, xfer::DatasetTransferProperties=dset.xfer) =
    API.h5d_write(dset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, x)

# type-specific behaviors
function write_attribute(attr::Attribute, memtype::Datatype, str::AbstractString)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        buf = Base.unsafe_convert(Ptr{UInt8}, strbuf)
        API.h5a_write(attr, memtype, buf)
    end
end
function write_attribute(attr::Attribute, memtype::Datatype, x::T) where {T<:Union{ScalarType,Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    API.h5a_write(attr, memtype, tmp)
end
function write_attribute(attr::Attribute, memtype::Datatype, strs::Array{<:AbstractString})
    p = Ref{Cstring}(strs)
    API.h5a_write(attr, memtype, p)
end
write_attribute(attr::Attribute, memtype::Datatype, ::EmptyArray) = nothing

function read_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::DatasetTransferProperties=dataset.xfer)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot read arrays with a different stride than `Array`"))
    API.h5d_read(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
end

function write_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::DatasetTransferProperties=dataset.xfer)
    stride(buf, 1) != 1 && throw(ArgumentError("Cannot write arrays with a different stride than `Array`"))
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
end
function write_dataset(dataset::Dataset, memtype::Datatype, str::AbstractString, xfer::DatasetTransferProperties=dataset.xfer)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        # unsafe_convert(Cstring, strbuf) is responsible for enforcing the no-'\0' policy,
        # but then need explicit convert to Ptr{UInt8} since Ptr{Cstring} -> Ptr{Cvoid} is
        # not automatic.
        buf = convert(Ptr{UInt8}, Base.unsafe_convert(Cstring, strbuf))
        API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
    end
end
function write_dataset(dataset::Dataset, memtype::Datatype, x::T, xfer::DatasetTransferProperties=dataset.xfer) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, tmp)
end
function write_dataset(dataset::Dataset, memtype::Datatype, strs::Array{<:AbstractString}, xfer::DatasetTransferProperties=dataset.xfer)
    p = Ref{Cstring}(strs)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, p)
end
write_dataset(dataset::Dataset, memtype::Datatype, ::EmptyArray, xfer::DatasetTransferProperties=dataset.xfer) = nothing

#API.h5s_get_simple_extent_ndims(space_id::API.hid_t) = API.h5s_get_simple_extent_ndims(space_id, C_NULL, C_NULL)


# Functions that require special handling

const libversion = API.h5_get_libversion()

vlen_get_buf_size(dset::Dataset, dtype::Datatype, dspace::Dataspace) = API.h5d_vlen_get_buf_size(dset, dtype, dspace)

### Property manipulation ###
get_access_properties(d::Dataset)   = DatasetAccessProperties(API.h5d_get_access_plist(d))
get_access_properties(f::File)      = FileAccessProperties(API.h5f_get_access_plist(f))
get_create_properties(d::Dataset)   = DatasetCreateProperties(API.h5d_get_create_plist(d))
get_create_properties(g::Group)     = GroupCreateProperties(API.h5g_get_create_plist(g))
get_create_properties(f::File)      = FileCreateProperties(API.h5f_get_create_plist(f))
get_create_properties(a::Attribute) = AttributeCreateProperties(API.h5a_get_create_plist(a))

function get_chunk(dset::Dataset)
    p = get_create_properties(dset)
    local ret
    try
        ret = get_chunk(p)
    finally
        close(p)
    end
    ret
end


"""
    get_datasets(file::HDF5.File) -> datasets::Vector{HDF5.Dataset}

Get all the datasets in an hdf5 file without loading the data.
"""
function get_datasets(file::File)
    list = Dataset[]
    get_datasets!(list, file)
    list
end
 function get_datasets!(list::Vector{Dataset}, node::Union{File,Group,Dataset})
    if isa(node, Dataset)
        push!(list, node)
    else
        for c in keys(node)
            get_datasets!(list, node[c])
        end
    end
end

# properties that require chunks in order to work (e.g. any filter)
# values do not matter -- just needed to form a NamedTuple with the desired keys
const chunked_props = (; compress=nothing, deflate=nothing, blosc=nothing, shuffle=nothing)

"""
    create_external(source::Union{HDF5.File, HDF5.Group}, source_relpath, target_filename, target_path;
                    lcpl_id=HDF5.API.H5P_DEFAULT, lapl_id=HDF5.H5P.DEFAULT)

Create an external link such that `source[source_relpath]` points to `target_path` within the file
with path `target_filename`; Calls `[H5Lcreate_external](https://www.hdfgroup.org/HDF5/doc/RM/RM_H5L.html#Link-CreateExternal)`.
"""
function create_external(source::Union{File,Group}, source_relpath, target_filename, target_path; lcpl_id=API.H5P_DEFAULT, lapl_id=API.H5P_DEFAULT)
    API.h5l_create_external(target_filename, target_path, source, source_relpath, lcpl_id, lapl_id)
    nothing
end

const HAS_PARALLEL = Ref(false)

"""
    has_parallel()

Returns `true` if the HDF5 libraries were compiled with parallel support,
and if parallel functionality was loaded into HDF5.jl.

For the second condition to be true, MPI.jl must be imported before HDF5.jl.
"""
has_parallel() = HAS_PARALLEL[]

function __init__()
    API.check_deps()

    # disable file locking as that can cause problems with mmap'ing
    if !haskey(ENV, "HDF5_USE_FILE_LOCKING")
        ENV["HDF5_USE_FILE_LOCKING"] = "FALSE"
    end

    # use our own error handling machinery (i.e. turn off automatic error printing)
    API.h5e_set_auto(API.H5E_DEFAULT, C_NULL, C_NULL)

    # initialize default properties
    ASCII_LINK_PROPERTIES.char_encoding = :ascii
    ASCII_LINK_PROPERTIES.create_intermediate_group = true
    UTF8_LINK_PROPERTIES.char_encoding = :utf8
    UTF8_LINK_PROPERTIES.create_intermediate_group = true
    ASCII_ATTRIBUTE_PROPERTIES.char_encoding = :ascii
    UTF8_ATTRIBUTE_PROPERTIES.char_encoding = :utf8

    @require FileIO="5789e2e9-d7fb-5bc7-8068-2c6fae9b9549" include("fileio.jl")
    @require H5Zblosc="c8ec2601-a99c-407f-b158-e79c03c2f5f7" begin
        set_blosc!(p::Properties, val::Bool) = val && push!(Filters.FilterPipeline(p), H5Zblosc.BloscFilter())
        set_blosc!(p::Properties, level::Integer) = push!(Filters.FilterPipeline(p), H5Zblosc.BloscFilter(level=level))
    end

    return nothing
end

include("deprecated.jl")

end  # module
