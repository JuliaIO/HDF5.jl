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
include("typeconversions.jl")
include("dataspaces.jl")
include("datasets.jl")
include("attributes.jl")
include("readwrite.jl")
include("references.jl")
include("show.jl")

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

Properties can be specified as keywords for [`FileAccessProperties`](@ref) and [`FileCreateProperties`](@ref).

Also the keywords `fapl` and `fcpl` can be used to provide default instances of these property lists. Property
lists passed in via keyword will be closed. This is useful to set properties not currently defined by HDF5.jl.

Note that `h5open` uses `fclose_degree = :strong` by default, but this can be overriden by the `fapl` keyword.
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


function h5open(filename::AbstractString, mode::AbstractString = "r";
    swmr::Bool = false,
    # With garbage collection, the other modes don't make sense
    fapl = FileAccessProperties(; fclose_degree = :strong),
    fcpl = FileCreateProperties(),
    pv...
)
    try
        pv = setproperties!(fapl, fcpl; pv...)
        isempty(pv) || error("invalid keyword options $pv")
        file = h5open(filename, mode, fapl, fcpl; swmr=swmr)
        return file
    finally
        close(fapl)
        close(fcpl)
    end
end


"""
    function h5open(f::Function, args...; swmr=false, pv...)

Apply the function f to the result of `h5open(args...; kwargs...)` and close the resulting
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


# Ensure that objects haven't been closed
Base.isvalid(obj::Union{File,Datatype,Dataspace}) = obj.id != -1 && API.h5i_is_valid(obj)
Base.isvalid(obj::Union{Group,Dataset,Attribute}) = obj.id != -1 && obj.file.id != -1 && API.h5i_is_valid(obj)
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

function Base.close(obj::Datatype)
    if obj.toclose && obj.id != -1
        if (!isdefined(obj, :file) || obj.file.id != -1) && isvalid(obj)
            API.h5o_close(obj)
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
open_datatype(parent::Union{File,Group}, name::AbstractString, tapl::DatatypeAccessProperties=DatatypeAccessProperties()) =
    Datatype(API.h5t_open(checkvalid(parent), name, tapl), file(parent))

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
                  gcpl::GroupCreateProperties=GroupCreateProperties();
                  pv...)
    haskey(parent, path) && error("cannot create group: object \"", path, "\" already exists at ", name(parent))
    pv = setproperties!(gcpl; pv...)
    isempty(pv) || error("invalid keyword options $pv")
    Group(API.h5g_create(parent, path, lcpl, gcpl, API.H5P_DEFAULT), file(parent))
end

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


# Delete objects
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
Base.haskey(dset::Union{Dataset,Datatype}, path::AbstractString) = API.h5a_exists(checkvalid(dset), path)

# Querying items in the file
group_info(obj::Union{Group,File}) = API.h5g_get_info(checkvalid(obj))
object_info(obj::Union{File,Object}) = API.h5o_get_info(checkvalid(obj))

Base.length(obj::Union{Group,File}) = Int(API.h5g_get_num_objs(checkvalid(obj)))

Base.isempty(x::Union{Group,File}) = length(x) == 0
Base.eltype(dset::Union{Dataset,Attribute}) = get_jl_type(dset)

# filename and name
filename(obj::Union{File,Group,Dataset,Attribute,Datatype}) = API.h5f_get_name(checkvalid(obj))
name(obj::Union{File,Group,Dataset,Datatype}) = API.h5i_get_name(checkvalid(obj))
function Base.keys(x::Union{Group,File})
    checkvalid(x)
    children = sizehint!(String[], length(x))
    API.h5l_iterate(x, IDX_TYPE[], ORDER[]) do _, name, _
        push!(children, unsafe_string(name))
        return API.herr_t(0)
    end
    return children
end


# iteration by objects
function Base.iterate(parent::Union{File,Group}, iter = (1,nothing))
    n, prev_obj = iter
    prev_obj ≢ nothing && close(prev_obj)
    n > length(parent) && return nothing
    obj = h5object(API.h5o_open_by_idx(checkvalid(parent), ".", IDX_TYPE[], ORDER[], n-1, API.H5P_DEFAULT), parent)
    return (obj, (n+1,obj))
end

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

# The datatype of a Datatype is the Datatype
datatype(dt::Datatype) = dt

Base.sizeof(dtype::Datatype) = Int(API.h5t_get_size(dtype))


"""
    start_swmr_write(h5::HDF5.File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://portal.hdfgroup.org/display/HDF5/Single+Writer+Multiple+Reader++-+SWMR).
"""
start_swmr_write(h5::File) = API.h5f_start_swmr_write(h5)


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


# end of high-level interface


include("api_midlevel.jl")


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
