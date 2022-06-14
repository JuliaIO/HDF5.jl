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

# Attribute defined in attributes.jl

# High-level reference handler
struct Reference
  r::API.hobj_ref_t
end
Reference() = Reference(API.HOBJ_REF_T_NULL) # NULL reference to compare to
Base.cconvert(::Type{Ptr{T}}, ref::Reference) where {T<:Union{Reference,API.hobj_ref_t,Cvoid}} = Ref(ref)
Base.:(==)(a::Reference, b::Reference) = a.r == b.r
Base.hash(x::Reference, h::UInt) = hash(x.r, h)

function Reference(parent::Union{File,Group,Dataset}, name::AbstractString)
  ref = Ref{API.hobj_ref_t}()
  API.h5r_create(ref, checkvalid(parent), name, API.H5R_OBJECT, -1)
  return Reference(ref[])
end

const BitsType = Union{Bool,Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Float32,Float64}
const ScalarType = Union{BitsType,Reference}

# Define an H5O Object type
const Object = Union{Group,Dataset,Datatype}
