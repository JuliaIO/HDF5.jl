### Generic H5DataStore interface ###

# Common methods that could be applicable to any interface for reading/writing variables from a file, e.g. HDF5, JLD, or MAT files.
# Types inheriting from H5DataStore should have names, read, and write methods.
# Supertype of HDF5.File, HDF5.Group, JldFile, JldGroup, Matlabv5File, and MatlabHDF5File.
abstract type H5DataStore end

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


### Base HDF5 structs ###

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
    fcpl::FileCreateProperties

    function File(id, filename, fcpl::FileCreateProperties=FileCreateProperties(), toclose::Bool=true)
        f = new(id, filename, fcpl)
        if toclose
            finalizer(close, f)
        end
        f
    end
end
Base.cconvert(::Type{API.hid_t}, f::File) = f
Base.unsafe_convert(::Type{API.hid_t}, f::File) = f.id

mutable struct Group <: H5DataStore
    id::API.hid_t
    file::File         # the parent file
    gcpl::GroupCreateProperties

    function Group(id, file, gcpl::GroupCreateProperties=GroupCreateProperties())
        g = new(id, file, gcpl)
        finalizer(close, g)
        g
    end
end
Base.cconvert(::Type{API.hid_t}, g::Group) = g
Base.unsafe_convert(::Type{API.hid_t}, g::Group) = g.id

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
Base.cconvert(::Type{API.hid_t}, dset::Dataset) = dset
Base.unsafe_convert(::Type{API.hid_t}, dset::Dataset) = dset.id

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
Base.cconvert(::Type{API.hid_t}, dtype::Datatype) = dtype
Base.unsafe_convert(::Type{API.hid_t}, dtype::Datatype) = dtype.id
Base.hash(dtype::Datatype, h::UInt) = hash(dtype.id, hash(Datatype, h))
Base.:(==)(dt1::Datatype, dt2::Datatype) = API.h5t_equal(dt1, dt2)

mutable struct Dataspace
    id::API.hid_t

    function Dataspace(id)
        dspace = new(id)
        finalizer(close, dspace)
        dspace
    end
end
Base.cconvert(::Type{API.hid_t}, dspace::Dataspace) = dspace
Base.unsafe_convert(::Type{API.hid_t}, dspace::Dataspace) = dspace.id

mutable struct Attribute
    id::API.hid_t
    file::File

    function Attribute(id, file)
        dset = new(id, file)
        finalizer(close, dset)
        dset
    end
end
Base.cconvert(::Type{API.hid_t}, attr::Attribute) = attr
Base.unsafe_convert(::Type{API.hid_t}, attr::Attribute) = attr.id

# High-level reference handler
struct Reference
  r::API.hobj_ref_t
end
Base.cconvert(::Type{Ptr{T}}, ref::Reference) where {T<:Union{Reference,API.hobj_ref_t,Cvoid}} = Ref(ref)

const BitsType = Union{Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64}
const ScalarType = Union{BitsType,Reference}

# Define an H5O Object type
const Object = Union{Group,Dataset,Datatype}

idx_type(obj::Union{File,Group}) = get_track_order(get_create_properties(obj)) ? API.H5_INDEX_CRT_ORDER : API.H5_INDEX_NAME
idx_type(obj::Any) = API.H5_INDEX_NAME

# TODO: implement alternative iteration order ?
order(obj::Any) = API.H5_ITER_INC
