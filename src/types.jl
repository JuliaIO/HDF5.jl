### Generic H5DataStore interface ###

# Common methods that could be applicable to any interface for reading/writing variables from a file, e.g. HDF5, JLD, or MAT files.
# Types inheriting from H5DataStore should have names, read, and write methods.
# Supertype of HDF5.File, HDF5.Group, JldFile, JldGroup, Matlabv5File, and MatlabHDF5File.
#
# H5DataStore is `<: AbstractDict{String,Any}` so that Julia's REPL dict-key completion
# (which requires `isa(obj, AbstractDict)`, see `REPLCompletions.dict_eval`) works natively
# for `store["path<TAB>"]`. The generic fallback/safety-net methods below apply to every
# H5DataStore implementor that supplies none of its own more-specific `AbstractDict` methods
# (e.g. MAT.jl's `Matlabv5File`/`MatlabHDF5File`, which only define `keys`/`haskey`),
# expressed only in terms of the already-required `read`/`keys` contract or Julia builtins
# (`===`/`objectid`), so they need no type-specific internals.
#
# Caveat: this does NOT retroactively fix implementors that already define their OWN
# more-specific, non-conforming method that overrides one of these fallbacks by dispatch.
# As of this writing, JLD.jl defines `Base.iterate(::Union{JldFile,JldGroup})` that yields
# bare stored objects rather than `key => value` pairs -- since that method is more specific
# than the fallback below, `isa(x, AbstractDict)` becomes `true` for JLD.jl's types without
# their iteration actually conforming to the `AbstractDict` contract (so generic operations
# built on `iterate`, e.g. `Dict(jldfile)`/`==`/`pairs`, would misbehave for JLD.jl objects).
# Fixing this requires a coordinated change in JLD.jl itself, not something achievable from
# HDF5.jl's side alone.
abstract type H5DataStore <: AbstractDict{String,Any} end

"""
    read(parent::H5DataStore)
    read(parent::H5DataStore, names...)

Read a list of variables, `read(parent, "A", "B", "x", ...)`.
If no variables are specified, read every variable in the file.
"""
function Base.read(parent::H5DataStore, name::AbstractString...)
    tuple((read(parent, x) for x in name)...)
end

# Read every variable in the file
function Base.read(f::H5DataStore)
    vars = keys(f)
    vals = Vector{Any}(undef, length(vars))
    for i in 1:length(vars)
        vals[i] = read(f, vars[i])
    end
    Dict(zip(vars, vals))
end

# Generic AbstractDict data-access fallbacks, in terms of the already-required read/keys
# contract. Gives implementors that don't define their own `getindex`/`length`/`iterate`
# (e.g. MAT.jl's `Matlabv5File`/`MatlabHDF5File`, which only define `keys`/`haskey`) full
# `AbstractDict` conformance for free. HDF5.jl's own `File`/`Group` define more specific,
# more efficient versions of these that take precedence by dispatch (see groups.jl).
Base.getindex(store::H5DataStore, name::AbstractString) = read(store, name)
Base.length(store::H5DataStore) = length(keys(store))
# Advance `keys(store)` via Julia's iterator protocol rather than assuming it supports
# integer indexing: e.g. MAT.jl's `Matlabv4File`/`Matlabv5File` return a `KeySet` (from
# `keys(getvarnames(matfile))`), which has no `getindex` method.
function Base.iterate(store::H5DataStore, state=nothing)
    ks, kstate = state === nothing ? (keys(store), nothing) : state
    it = kstate === nothing ? iterate(ks) : iterate(ks, kstate)
    it === nothing && return nothing
    k, next_kstate = it
    return k => store[k], (ks, next_kstate)
end

# `get(d, k, default)`: Base provides no generic `AbstractDict` fallback for this (verified;
# only concrete dict types like `Dict`/`IdDict` define their own), so without this method
# `get`/`==`/`in` (which call `get` internally) would `MethodError`.
Base.get(store::H5DataStore, path::AbstractString, default) = haskey(store, path) ? store[path] : default

# `copy`: the generic `AbstractDict` fallback `copy(a) = merge!(empty(a), a)` succeeds
# silently, eagerly opening every child object into a throwaway plain `Dict` — this collides
# with the semantically different `copy_object` in this codebase and is a dangerous silent
# behavior for large stores. Guard against it explicitly.
Base.copy(store::H5DataStore) = throw(
    ArgumentError(
        "`copy` is not defined for $(typeof(store)); use `copy_object` to copy an HDF5 object, " *
        "or `Dict(store)` to materialize its immediate children",
    ),
)
Base.empty(store::H5DataStore, ::Type=String, ::Type=Any) =
    throw(ArgumentError("`empty` is not defined for $(typeof(store))"))

# `==`/`isequal`/`hash`: identity-based via `===`/`objectid`, using only Julia builtins (no
# field assumptions about the concrete subtype). This is a behavioral no-op for JLD.jl/MAT.jl
# (neither has a custom `==` today, so Julia's default already is `===` for mutable structs);
# it just prevents `AbstractDict`'s generic *content*-based `==`/`hash` (which would
# recursively open and compare every child) from silently taking over.
#
# Must cover H5DataStore-vs-AbstractDict comparisons explicitly, not just same-concrete-type
# pairs: a same-type-only method (`::T, ::T where {T<:H5DataStore}`) leaves e.g. `File ==
# Group` or `File == Dict()` to fall through to `AbstractDict`'s generic *content*-based `==`,
# which could compare `true` for two empty stores of different types while `hash` (below)
# differs for them — violating the `==`/`hash` contract.
Base.:(==)(a::H5DataStore, b::H5DataStore) = a === b
Base.:(==)(a::H5DataStore, b::AbstractDict) = false
Base.:(==)(a::AbstractDict, b::H5DataStore) = false
Base.isequal(a::H5DataStore, b::H5DataStore) = a === b
Base.isequal(a::H5DataStore, b::AbstractDict) = false
Base.isequal(a::AbstractDict, b::H5DataStore) = false
Base.hash(a::H5DataStore, h::UInt) = hash(objectid(a), h)

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
            finalizer(API.try_close_finalizer, f)
        end
        f
    end
end
Base.cconvert(::Type{API.hid_t}, f::File) = f
Base.unsafe_convert(::Type{API.hid_t}, f::File) = f.id

mutable struct Group <: H5DataStore
    id::API.hid_t
    file::File         # the parent file

    function Group(id, file)
        g = new(id, file)
        finalizer(API.try_close_finalizer, g)
        g
    end
end
Base.cconvert(::Type{API.hid_t}, g::Group) = g
Base.unsafe_convert(::Type{API.hid_t}, g::Group) = g.id

# NOTE: unlike Datatype/Dataspace, File/Group deliberately do NOT get an `.id`-based `==`/
# `hash` override here. Re-opening the same path (e.g. `h5f["G"]` called twice) mints a
# fresh HDF5 identifier each time (H5Gopen/H5Oopen don't return a cached id), so `.id`
# equality would not actually make "two handles to the same group" compare equal in the
# common case - it would only match the trivial case of the exact same Julia object, which
# the generic `H5DataStore`-level `===`-based fallback (above, in this file) already
# provides correctly and unsurprisingly.

"""
    HDF5.Dataset

A mutable wrapper for a HDF5 Dataset `HDF5.API.hid_t`.
"""
mutable struct Dataset
    id::API.hid_t
    file::File
    xfer::DatasetTransferProperties

    function Dataset(id, file, xfer=DatasetTransferProperties())
        dset = new(id, file, xfer)
        finalizer(API.try_close_finalizer, dset)
        dset
    end
end
Base.cconvert(::Type{API.hid_t}, dset::Dataset) = dset
Base.unsafe_convert(::Type{API.hid_t}, dset::Dataset) = dset.id

"""
    HDF5.Datatype(id, toclose = true)

Wrapper for a HDF5 datatype id. If `toclose` is true, the finalizer will close
the datatype.
"""
mutable struct Datatype
    id::API.hid_t
    toclose::Bool
    file::File

    function Datatype(id, toclose::Bool=true)
        nt = new(id, toclose)
        if toclose
            finalizer(API.try_close_finalizer, nt)
        end
        nt
    end
    function Datatype(id, file::File, toclose::Bool=true)
        nt = new(id, toclose, file)
        if toclose
            finalizer(API.try_close_finalizer, nt)
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
        finalizer(API.try_close_finalizer, dspace)
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
        finalizer(API.try_close_finalizer, dset)
        dset
    end
end
Base.cconvert(::Type{API.hid_t}, attr::Attribute) = attr
Base.unsafe_convert(::Type{API.hid_t}, attr::Attribute) = attr.id

# High-level reference handler
struct Reference
    r::API.hobj_ref_t
end
Base.cconvert(
    ::Type{Ptr{T}}, ref::Reference
) where {T<:Union{Reference,API.hobj_ref_t,Cvoid}} = Ref(ref)

const hdf5_supports_Float16 = API.H5T_NATIVE_FLOAT16 != API.hid_t(-1)
const BitsType = Union{
    Bool,
    Int8,
    UInt8,
    Int16,
    UInt16,
    Int32,
    UInt32,
    Int64,
    UInt64,
    Float32,
    Float64,
    (hdf5_supports_Float16 ? Float16 : Union{})
}
const ScalarType = Union{BitsType,Reference}

# Define an H5O Object type
const Object = Union{Group,Dataset,Datatype}

idx_type(obj::File) =
    if get_context_property(:file_create).track_order ||
        get_create_properties(obj).track_order
        API.H5_INDEX_CRT_ORDER
    else
        API.H5_INDEX_NAME
    end
idx_type(obj::Group) =
    if get_context_property(:group_create).track_order ||
        get_create_properties(obj).track_order
        API.H5_INDEX_CRT_ORDER
    else
        API.H5_INDEX_NAME
    end
idx_type(obj) = API.H5_INDEX_NAME

# TODO: implement alternative iteration order ?
order(obj) = API.H5_ITER_INC
