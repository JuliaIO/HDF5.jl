###############################################
## Reading and writing Julia data .jld files ##
###############################################

module JLD
using HDF5
# Add methods to...
import HDF5: close, dump, exists, file, getindex, setindex!, g_create, g_open, o_delete, name, names, read, size, write,
             HDF5ReferenceObj, HDF5BitsKind, ismmappable, readmmap
import Base: length, endof, show, done, next, start, delete!

if !isdefined(:setfield!)
    const setfield! = setfield
end
if !isdefined(:read!)
    const read! = read
end

const magic_base = "Julia data file (HDF5), version "
const version_current = "0.0.2"
const pathrefs = "/_refs"
const pathtypes = "/_types"
const pathrequire = "/_require"
const name_type_attr = "julia type"

typealias BitsKindOrByteString Union(HDF5BitsKind, ByteString)

### Dummy types used for converting attribute strings to Julia types
type UnsupportedType; end
type UnconvertedType; end
type CompositeKind; end   # here this means "a type with fields"

immutable JldDatatype
    dtype::HDF5Datatype
    index::Int
end

# The Julia Data file type
# Purpose of the nrefs field:
# length(group) only returns the number of _completed_ items in a group. Since
# we'll write recursively, we need to keep track of the number of reference
# objects _started_.
type JldFile <: HDF5.DataFile
    plain::HDF5File
    version::String
    toclose::Bool
    writeheader::Bool
    mmaparrays::Bool
    h5jltype::Dict{Int,Type}
    jlh5type::Dict{Type,JldDatatype}
    h5ref::WeakKeyDict{Any,HDF5ReferenceObj}
    jlref::Dict{HDF5ReferenceObj,WeakRef}
    nrefs::Int

    function JldFile(plain::HDF5File, version::String=version_current, toclose::Bool=true,
                     writeheader::Bool=false, mmaparrays::Bool=false)
        f = new(plain, version, toclose, writeheader, mmaparrays,
                Dict{HDF5Datatype,Type}(), Dict{Type,HDF5Datatype}(),
                WeakKeyDict{Any,HDF5ReferenceObj}(), Dict{HDF5ReferenceObj,Any}(), 0)
        if toclose
            finalizer(f, close)
        end
        f
    end
end

immutable JldGroup
    plain::HDF5Group
    file::JldFile
end

immutable JldDataset
    plain::HDF5Dataset
    file::JldFile
end

immutable PointerException <: Exception; end
show(io::IO, ::PointerException) = print(io, "Cannot write a pointer to JLD file")

# Wrapper for associative keys
# We write this instead of the associative to avoid dependence on the
# Julia hash function
immutable AssociativeWrapper{K,V,T<:Associative}
    keys::Vector{K}
    values::Vector{V}
end

include("jld_types.jl")

file(x::JldFile) = x
file(x::Union(JldGroup, JldDataset)) = x.file

function close(f::JldFile)
    if f.toclose
        close(f.plain)
        if f.writeheader
            magic = zeros(Uint8, 512)
            tmp = string(magic_base, f.version)
            magic[1:length(tmp)] = tmp.data
            rawfid = open(f.plain.filename, "r+")
            write(rawfid, magic)
            close(rawfid)
        end
        f.toclose = false
    end
    nothing
end
close(g::Union(JldGroup, JldDataset)) = close(g.plain)
show(io::IO, fid::JldFile) = isvalid(fid.plain) ? print(io, "Julia data file version ", fid.version, ": ", fid.plain.filename) : print(io, "Julia data file (closed): ", fid.plain.filename)

function jldopen(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool; mmaparrays::Bool=false)
    local fj
    if ff && !wr
        error("Cannot append to a write-only file")
    end
    if !cr && !isfile(filename)
        error("File ", filename, " cannot be found")
    end
    version = version_current
    pa = p_create(HDF5.H5P_FILE_ACCESS)
    try
        pa["fclose_degree"] = HDF5.H5F_CLOSE_STRONG
        if cr && (tr || !isfile(filename))
            # We're truncating, so we don't have to check the format of an existing file
            # Set the user block to 512 bytes, to save room for the header
            p = p_create(HDF5.H5P_FILE_CREATE)
            local f
            try
                p["userblock"] = 512
                f = HDF5.h5f_create(filename, HDF5.H5F_ACC_TRUNC, p.id, pa.id)
            finally
                close(p)
            end
            fj = JldFile(HDF5File(f, filename), version, true, true, mmaparrays)
            # initialize empty require list
            write(fj, pathrequire, ByteString[])
        else
            # Test whether this is a jld file
            sz = filesize(filename)
            if sz < 512
                error("File size indicates $filename cannot be a Julia data file")
            end
            magic = Array(Uint8, 512)
            rawfid = open(filename, "r")
            try
                magic = read!(rawfid, magic)
            finally
                close(rawfid)
            end
            if beginswith(magic, magic_base.data)
                f = HDF5.h5f_open(filename, wr ? HDF5.H5F_ACC_RDWR : HDF5.H5F_ACC_RDONLY, pa.id)
                version = bytestring(convert(Ptr{Uint8}, magic) + length(magic_base))
                fj = JldFile(HDF5File(f, filename), version, true, true, mmaparrays)
                # Load any required files/packages
                if exists(fj, pathrequire)
                    r = read(fj, pathrequire)
                    for fn in r
                        require(fn)
                    end
                end
            else
                if ishdf5(filename)
                    println("$filename is an HDF5 file, but it is not a recognized Julia data file. Opening anyway.")
                    fj = JldFile(h5open(filename, rd, wr, cr, tr, ff), version_current, true, false, mmaparrays)
                else
                    error("$filename does not seem to be a Julia data or HDF5 file")
                end
            end
        end
    finally
        close(pa)
    end
    return fj
end

function jldopen(fname::String, mode::String="r"; mmaparrays::Bool=false)
    mode == "r"  ? jldopen(fname, true , false, false, false, false, mmaparrays=mmaparrays) :
    mode == "r+" ? jldopen(fname, true , true , false, false, false, mmaparrays=mmaparrays) :
    mode == "w"  ? jldopen(fname, false, true , true , true , false, mmaparrays=mmaparrays) :
#     mode == "w+" ? jldopen(fname, true , true , true , true , false) :
#     mode == "a"  ? jldopen(fname, false, true , true , false, true ) :
#     mode == "a+" ? jldopen(fname, true , true , true , false, true ) :
    error("invalid open mode: ", mode)
end

function jldopen(f::Function, args...)
    jld = jldopen(args...)
    try
        f(jld)
    finally
        close(jld)
    end
end

function jldobject(obj_id::HDF5.Hid, parent)
    obj_type = HDF5.h5i_get_type(obj_id)
    obj_type == HDF5.H5I_GROUP ? JldGroup(HDF5Group(obj_id, file(parent.plain)), file(parent)) :
    obj_type == HDF5.H5I_DATATYPE ? HDF5Datatype(obj_id) :
    obj_type == HDF5.H5I_DATASET ? JldDataset(HDF5Dataset(obj_id, file(parent.plain)), file(parent)) :
    error("Invalid object type for path ", path)
end

getindex(parent::Union(JldFile, JldGroup), path::ByteString) =
    jldobject(HDF5.h5o_open(parent.plain.id, path), parent)

function getindex(parent::Union(JldFile, JldGroup, JldDataset), r::HDF5ReferenceObj)
    if r == HDF5.HDF5ReferenceObj_NULL; error("Reference is null"); end
    obj_id = HDF5.h5r_dereference(parent.plain.id, HDF5.H5R_OBJECT, r)
    jldobject(obj_id, parent)
end

### "Inherited" behaviors
g_create(parent::Union(JldFile, JldGroup), args...) = JldGroup(g_create(parent.plain, args...), file(parent))
function g_create(f::Function, parent::Union(JldFile, JldGroup), args...)
    g = JldGroup(g_create(parent.plain, args...), file(parent))
    try
        f(g)
    finally
        close(g)
    end
end
g_open(parent::Union(JldFile, JldGroup), args...) = JldGroup(g_open(parent.plain, args...), file(parent))
name(p::Union(JldFile, JldGroup, JldDataset)) = name(p.plain)
exists(p::Union(JldFile, JldGroup, JldDataset), path::ByteString) = exists(p.plain, path)
root(p::Union(JldFile, JldGroup, JldDataset)) = g_open(file(p), "/")
o_delete(parent::Union(JldFile, JldGroup), args...) = o_delete(parent.plain, args...)
function ensurepathsafe(path::ByteString)
    if any([beginswith(path, s) for s in (pathrefs,pathtypes,pathrequire)]) 
        error("$name is internal to the JLD format, use o_delete if you really want to delete it") 
    end
end
function delete!(o::JldDataset)
    fullpath = name(o)
    ensurepathsafe(fullpath)
    o_delete(o.file, fullpath)
    refspath = joinpath(pathrefs, fullpath[2:end])
    exists(o.file, refspath) && o_delete(o.file, refspath)
end
function delete!(g::JldGroup)
    fullpath = name(g)
    ensurepathsafe(fullpath)
    for o in g typeof(o) == JldDataset && delete!(o) end
    o_delete(g.file,name(g))
end
function delete!(parent::Union(JldFile, JldGroup), path::ByteString)
    exists(parent, path) || error("$path does not exist in $parent")
    delete!(parent[path])
end
delete!(parent::Union(JldFile, JldGroup), args::(ByteString...)) = for a in args delete!(parent,a) end
ismmappable(obj::JldDataset) = ismmappable(obj.plain)
readmmap(obj::JldDataset, args...) = readmmap(obj.plain, args...)
setindex!(parent::Union(JldFile, JldGroup), val, path::ASCIIString) = write(parent, path, val)

start(parent::Union(JldFile, JldGroup)) = (names(parent), 1)
done(parent::Union(JldFile, JldGroup), state) = state[2] > length(state[1])
next(parent::Union(JldFile, JldGroup), state) = parent[state[1][state[2]]], (state[1], state[2]+1)


### Julia data file format implementation ###


### Read ###

function read(parent::Union(JldFile, JldGroup), name::ByteString)
    local val
    obj = parent[name]
    try
        val = read(obj)
    finally
        close(obj)
    end
    val
end
read(parent::Union(JldFile,JldGroup), name::Symbol) = read(parent,bytestring(string(name)))

# read and readsafely differ only in how they handle CompositeKind
function read(obj::JldDataset)
    dtype = datatype(obj.plain)
    dspace_id = HDF5.h5d_get_space(obj.plain)
    extent_type = HDF5.h5s_get_simple_extent_type(dspace_id)
    try
        if extent_type == HDF5.H5S_SCALAR
            # Scalar value
            return read_scalar(obj, dtype, jldatatype(file(obj), dtype))
        elseif extent_type == HDF5.H5S_SIMPLE
            # Array of values
            if HDF5.h5t_get_class(dtype) == HDF5.H5T_REFERENCE
                typename = a_read(obj.plain, "julia eltype")
                T2 = julia_type(typename)
                T2 == UnsupportedType && error("type $typename does not exist in namespace")
                return getrefs(obj, T2)
            else
                return read_array(obj, dtype, jldatatype(file(obj), dtype), dspace_id)
            end
        elseif extent_type == HDF5.H5S_NULL
            # Empty array
            if HDF5.h5t_get_class(dtype) == HDF5.H5T_REFERENCE
                typename = a_read(obj.plain, "julia eltype")
                T3 = julia_type(typename)
                T3 == UnsupportedType && error("type $typename does not exist in namespace")
            else
                T3 = jldatatype(file(obj), dtype)
            end
            if exists(obj, "dims")
                dims = a_read(obj.plain, "dims")
                return Array(T3, dims...)
            else
                return T3[]
            end
        end
    finally
        HDF5.h5s_close(dspace_id)
    end
end

read_scalar{T<:BitsKindOrByteString}(obj::JldDataset, dtype::HDF5Datatype, ::Type{T}) =
    read(obj.plain, T)
function read_scalar(obj::JldDataset, dtype::HDF5Datatype, T::Type)
    buf = Array(Uint8, sizeof(dtype))
    HDF5.readarray(obj.plain, dtype.id, buf)
    return after_read(jlconvert(T, file(obj), pointer(buf)))
end

read_array{T<:HDF5BitsKind}(obj::JldDataset, dtype::HDF5Datatype, ::Type{Array{T}}, dspace_id::HDF5.Hid) =
    obj.file.mmaparrays && HDF5.iscontiguous(obj.plain) ? readmmap(obj.plain, Array{T}) : read(obj.plain, Array{T})
function read_array(obj::JldDataset, dtype::HDF5Datatype, T::Type, dspace_id::HDF5.Hid)
    dims = map(int, HDF5.h5s_get_simple_extent_dims(dspace_id)[1])
    n = prod(dims)
    h5sz = sizeof(dtype)
    out = Array(T, dims)

    # Read from file
    buf = Array(Uint8, h5sz*n)
    HDF5.readarray(obj.plain, dtype.id, buf)

    f = file(obj)
    h5offset = pointer(buf)
    if T.pointerfree
        jloffset = pointer(out)
        jlsz = T.size

        # Perform conversion in buffer
        for i = 1:n
            jlconvert!(jloffset, T, f, h5offset)
            jloffset += jlsz
            h5offset += h5sz
        end
    else
        # Convert each item individually
        for i = 1:n
            out[i] = jlconvert(T, f, h5offset)
            h5offset += h5sz
        end
    end
    out
end

after_read(x) = x

# Special case for associative, to rehash keys
function after_read{K,V,T}(x::AssociativeWrapper{K,V,T})
    ret = T()
    keys = x.keys
    values = x.values
    n = length(keys)
    if applicable(sizehint, (ret, n))
        sizehint(ret, n)
    end
    for i = 1:n
        ret[keys[i]] = values[i]
    end
    ret
end

# Read a reference
function read_ref(f::JldFile, ref::HDF5ReferenceObj)
    dset = f[ref]
    try
        return read(dset)
    finally
        close(dset)
    end
end
function getrefs{T}(obj::JldDataset, ::Type{T})
    refs = read(obj.plain, Array{HDF5ReferenceObj})
    out = Array(T, size(refs))
    f = file(obj)
    for i = 1:length(refs)
        if refs[i] != HDF5.HDF5ReferenceObj_NULL
            out[i] = read_ref(f, refs[i])
        end
    end
    return out
end
function getrefs{T}(obj::JldDataset, ::Type{T}, indices::Union(Integer, AbstractVector)...)
    refs = read(obj.plain, Array{HDF5ReferenceObj})
    refs = refs[indices...]
    f = file(obj)
    local out
    if isa(refs, HDF5ReferenceObj)
        # This is a scalar, not an array
        ref = f[refs]
        try
            out = read(ref)
        finally
            close(ref)
        end
    else
        out = Array(T, size(refs))
        for i = 1:length(refs)
            ref = f[refs[i]]
            try
                out[i] = read(ref)
            finally
                close(ref)
            end
        end
    end
    return out
end

### Writing ###

# Write "basic" types
function write{T<:Union(HDF5BitsKind, ByteString)}(parent::Union(JldFile, JldGroup), name::ByteString,
                                                   data::Union(T, Array{T}))
    # Create the dataset
    dset, dtype = d_create(parent.plain, name, data)
    try
        # Write the attribute
        isa(data, Array) && isempty(data) && a_write(dset, "dims", [size(data)...])
        # Write the data
        HDF5.writearray(dset, dtype.id, data)
    finally
        close(dset)
        close(dtype)
    end
end

# General array types
function write{T}(parent::Union(JldFile, JldGroup), path::ByteString, data::Array{T})
    f = file(parent)
    dtype = h5fieldtype(f, T)
    if dtype == JLD_REF_TYPE
        # Write as references
        refs = Array(HDF5ReferenceObj, size(data))
        for i = 1:length(data)
            if isdefined(data, i)
                refs[i] = write_ref(f, data[i])
            else
                refs[i] = HDF5.HDF5ReferenceObj_NULL
            end
        end
        dset, reftype = d_create(parent.plain, path, refs)
        a_write(dset, "julia eltype", full_typename(T))
        try
            if isempty(data)
                a_write(dset, "dims", [size(data)...])
            else
                HDF5.writearray(dset, reftype.id, refs)
            end
        finally
            close(reftype)
            close(dset)
        end
    else
        # Write as individual values
        # Split into a separate function to avoid dynamic dispatch
        # because h5convert! may be defined by h5fieldtype
        write_vals(parent, path, data, dtype)
    end
end

function write_vals{T}(parent::Union(JldFile, JldGroup), path::ByteString, data::Array{T}, dtype::JldDatatype)
    f = file(parent)
    persist = {}
    sz = HDF5.h5t_get_size(dtype)
    n = length(data)
    buf = Array(Uint8, sz*n)
    offset = pointer(buf)
    for i = 1:n
        h5convert!(offset, f, data[i], persist)
        offset += sz
    end

    dims = convert(Array{HDF5.Hsize, 1}, [reverse(size(data))...])
    dspace = dataspace(data)
    try
        dset = d_create(parent.plain, path, dtype.dtype, dspace)
        try
            if isempty(data)
                a_write(dset, "dims", [size(data)...])
            else
                HDF5.writearray(dset, dtype.dtype.id, buf)
            end
        finally
            close(dset)
        end
    finally
        close(dspace)
    end
end

# Write a reference to a JLD file
function write_ref(parent::JldFile, data)
    # Check whether we have already written this object
    ref = get!(parent.h5ref, data, HDF5.HDF5ReferenceObj_NULL)
    ref != HDF5.HDF5ReferenceObj_NULL && return ref

    # Write an new reference
    if !exists(parent, pathrefs)
        gref = g_create(parent, pathrefs)
    else
        gref = parent[pathrefs]
    end
    name = @sprintf "%08d" (parent.nrefs += 1)
    write(gref, name, data)

    # Add reference to reference list
    ref = HDF5ReferenceObj(gref.plain, name)
    if !isa(data, Tuple) && typeof(data).mutable
        parent.jlref[ref] = WeakRef(data)
        parent.h5ref[data] = ref
    end
    ref
end
write_ref(parent::JldGroup, data) = write_ref(file(parent), data)

# Special case for associative, to rehash keys
function write(parent::Union(JldFile, JldGroup), name::ByteString, d::Associative)
    tn = full_typename(typeof(d))
    if tn == "DataFrame"
        return write_compound(parent, name, d)
    end
    n = length(d)
    K, V = eltype(d)
    ks = Array(K, n)
    vs = Array(V, n)
    i = 0
    for (k,v) in d
        ks[i+=1] = k
        vs[i] = v
    end
    write(parent, name, AssociativeWrapper{K,V,typeof(d)}(ks, vs))
end

# Expressions
function write(parent::Union(JldFile, JldGroup), name::ByteString, ex::Expr)
    args = ex.args
    # Discard "line" expressions
    keep = trues(length(args))
    for i = 1:length(args)
        if isa(args[i], Expr) && args[i].head == :line
            keep[i] = false
        end
    end
    newex = Expr(ex.head)
    newex.args = args[keep]
    close(write_compound(parent, name, newex))
end

# Generic (tuples, immutables, and compound types)
write(parent::Union(JldFile, JldGroup), name::ByteString, s) =
    close(write_compound(parent, name, s))

function write_compound(parent::Union(JldFile, JldGroup), name::ByteString, s)
    T = typeof(s)
    dtype = h5datatype(parent, s)
    buf = Array(Uint8, HDF5.h5t_get_size(dtype))
    persist = {}
    h5convert!(pointer(buf), file(parent), s, persist)

    dspace = HDF5Dataspace(HDF5.h5s_create(HDF5.H5S_SCALAR))
    try
        dset = HDF5.d_create(parent.plain, name, dtype.dtype, dspace)
        try
            #HDF5.h5d_write(dset.id, dtype, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, buf)
            HDF5.writearray(dset, dtype.dtype.id, buf)
        catch
            close(dset)
        end
        return dset
    finally
        close(dspace)
    end
end

### Size, length, etc ###
function size(dset::JldDataset)
    if !exists(attrs(dset.plain), name_type_attr)
        return size(dset.plain)
    end
    # Read the type
    typename = a_read(dset.plain, name_type_attr)
    if typename == "Tuple"
        return size(dset.plain)
    end
    # Convert to Julia type
    T = julia_type(typename)
    if T == CompositeKind || T <: Associative || T == Expr
        return ()
    elseif T <: Complex
        return ()
    elseif isarraycomplex(T)
        sz = size(dset.plain)
        return sz[2:end]
    end
    size(dset.plain)
end
length(dset::JldDataset) = prod(size(dset))
endof(dset::JldDataset) = length(dset)

isarraycomplex{T<:Complex, N}(::Type{Array{T, N}}) = true
isarraycomplex(t) = false

### Read/write via getindex/setindex! ###
function getindex(dset::JldDataset, indices::Union(Integer, RangeIndex)...)
    if !exists(attrs(dset.plain), name_type_attr)
        # Fallback to plain read
        return getindex(dset.plain, indices...)
    end
    # Read the type
    typename = a_read(dset.plain, name_type_attr)
    if typename == "Tuple"
        return read_tuple(dset, indices...)
    end
    # Convert to Julia type
    T = julia_type(typename)
    _getindex(dset, T, indices...)
end

_getindex{T<:HDF5BitsKind,N}(dset::JldDataset, ::Type{Array{T,N}}, indices::RangeIndex...) = HDF5._getindex(dset.plain, T, indices...)
function _getindex{T<:Complex,N}(dset::JldDataset, ::Type{Array{T,N}}, indices::RangeIndex...)
    reinterpret(T, HDF5._getindex(dset.plain, realtype(T), 1:2, indices...), ntuple(length(indices), i->length(indices[i])))
end
function _getindex{N}(dset::JldDataset, ::Type{Array{Bool,N}}, indices::RangeIndex...)
    tf = HDF5._getindex(dset.plain, Uint8, indices...)
    bool(tf)
end
_getindex{T,N}(dset::JldDataset, ::Type{Array{T,N}}, indices::Union(Integer, RangeIndex)...) = getrefs(dset, T, indices...)
function setindex!(dset::JldDataset, X::Array, indices::RangeIndex...)
    if !exists(attrs(dset.plain), name_type_attr)
        # Fallback to plain read
        return setindex!(dset.plain, X, indices...)
    end
    # Read the type
    typename = a_read(dset.plain, name_type_attr)
    if typename == "Tuple"
        return read_tuple(dset, indices...)
    end
    # Convert to Julia type
    T = julia_type(typename)
    HDF5._setindex!(dset, T, X, indices...)
end

length(x::Union(JldFile, JldGroup)) = length(names(x))

### Dump ###
function dump(io::IO, parent::Union(JldFile, JldGroup), n::Int, indent)
    nms = names(parent)
    println(io, typeof(parent), " len ", length(nms))
    if n > 0
        i = 1
        for k in nms
            print(io, indent, "  ", k, ": ")
            v = parent[k]
            if isa(v, HDF5Group)
                dump(io, v, n-1, string(indent, "  "))
            else
                if exists(attrs(v.plain), name_type_attr)
                    typename = a_read(v.plain, name_type_attr)
                    if length(typename) >= 5 && (typename[1:5] == "Array" || typename[1:5] == "Tuple")
                        println(io, typename, " ", size(v))
                    else
                        println(io, typename)
                    end
                else
                    dump(io, v, 1, indent)
                end
            end
            close(v)
            if i > n
                println(io, indent, "  ...")
                break
            end
            i += 1
        end
    end
end



### Converting attribute strings to Julia types

is_valid_type_ex(s::Symbol) = true
is_valid_type_ex(s::QuoteNode) = true
is_valid_type_ex(x::Int) = true
is_valid_type_ex(e::Expr) = ((e.head == :curly || e.head == :tuple || e.head == :.) && all(map(is_valid_type_ex, e.args))) ||
                            (e.head == :call && (e.args[1] == :Union || e.args[1] == :TypeVar))

_typedict = Dict{String, Type}()
function julia_type(s::String)
    typ = get(_typedict, s, UnconvertedType)
    if typ == UnconvertedType
        typ = julia_type(parse(s))
        if typ != UnsupportedType
            _typedict[s] = typ
        end
    end
    typ
end

function julia_type(e::Union(Symbol, Expr))
    if is_valid_type_ex(e)
        try     # try needed to catch undefined symbols
            typ = eval(Main, e)
            isa(typ, Type) && return typ
        end
    end
    return UnsupportedType
end

### Converting Julia types to fully qualified names
full_typename(jltype::UnionType) = @sprintf "Union(%s)" join(map(full_typename, jltype.types), ",")
function full_typename(tv::TypeVar)
    if is(tv.lb, None) && is(tv.ub, Any)
        "TypeVar(:$(tv.name))" 
    elseif is(tv.lb, None)
        "TypeVar(:$(tv.name),$(full_typename(tv.ub)))"
    else
        "TypeVar(:$(tv.name),$(full_typename(tv.lb)),$(full_typename(tv.ub)))"
    end
end
full_typename(jltype::(Type...)) = length(jltype) == 1 ? @sprintf("(%s,)", full_typename(jltype[1])) :
                                   @sprintf("(%s)", join(map(full_typename, jltype), ","))
full_typename(x) = string(x)
function full_typename(jltype::DataType)
    #tname = "$(jltype.name.module).$(jltype.name)"
    tname = string(jltype.name.module, ".", jltype.name.name)  # NOTE: performance bottleneck
    if isempty(jltype.parameters)
        tname
    else
        @sprintf "%s{%s}" tname join([full_typename(x) for x in jltype.parameters], ",")
    end
end

### Version number utilities
versionnum(v::String) = map(int, split(v, '.'))
versionstring(v::Array{Int}) = join(v, '.')
function isversionless(l::Array{Int}, r::Array{Int})
    len = min(length(l), length(r))
    for i = 1:len
        if l[i] < r[i]
            return true
        end
    end
    if length(r) > len
        for i = len+1:length(r)
            if r[i] > 0
                return true
            end
        end
    end
    false
end

function names(parent::Union(JldFile, JldGroup))
    n = names(parent.plain)
    keep = trues(length(n))
    const reserved = [pathrefs[2:end], pathtypes[2:end], pathrequire[2:end]]
    for i = 1:length(n)
        if in(n[i], reserved)
            keep[i] = false
        end
    end
    n[keep]
end

function save_write(f, s, vname)
    if !isa(vname, Function)
        try
            write(f, s, vname)
        catch e
            if isa(e, PointerException)
                warn("Skipping $vname because it contains a pointer")
            end
        end
    end
end

macro save(filename, vars...)
    if isempty(vars)
        # Save all variables in the current module
        writeexprs = Array(Expr, 0)
        m = current_module()
        for vname in names(m)
            s = string(vname)
            if !ismatch(r"^_+[0-9]*$", s) # skip IJulia history vars
                v = eval(m, vname)
                if !isa(v, Module)
                    push!(writeexprs, :(save_write(f, $s, $(esc(vname)))))
                end
            end
        end
    else
        writeexprs = Array(Expr, length(vars))
        for i = 1:length(vars)
            writeexprs[i] = :(write(f, $(string(vars[i])), $(esc(vars[i]))))
        end
    end
    Expr(:block,
         :(local f = jldopen($(esc(filename)), "w")),
         Expr(:try, Expr(:block, writeexprs...), false, false,
              :(close(f))))
end

macro load(filename, vars...)
    if isempty(vars)
        if isa(filename, Expr)
            filename = eval(current_module(), filename)
        end
        # Load all variables in the top level of the file
        readexprs = Array(Expr, 0)
        vars = Array(Expr, 0)
        f = jldopen(filename)
        nms = names(f)
        for n in nms
            obj = f[n]
            if isa(obj, JldDataset)
                sym = esc(symbol(n))
                push!(readexprs, :($sym = read($f, $n)))
                push!(vars, sym)
            end
        end
        return Expr(:block, 
                    Expr(:global, vars...),
                    Expr(:try,  Expr(:block, readexprs...), false, false,
                         :(close($f))),
                    Symbol[v.args[1] for v in vars]) # "unescape" vars
    else
        readexprs = Array(Expr, length(vars))
        for i = 1:length(vars)
            readexprs[i] = :($(esc(vars[i])) = read(f, $(string(vars[i]))))
        end
        return Expr(:block, 
                    Expr(:global, map(esc, vars)...),
                    :(local f = jldopen($(esc(filename)))),
                    Expr(:try,  Expr(:block, readexprs...), false, false,
                         :(close(f))),
                    Symbol[v for v in vars]) # vars is a tuple
    end
end

# Save all the key-value pairs in the dict as top-level variables of the JLD
function save(filename::String, dict::Associative)
    jldopen(filename, "w") do file
        for (k,v) in dict
            write(file, bytestring(k), v)
        end
    end
end
# Or the names and values may be specified as alternating pairs
function save(filename::String, name::String, value, pairs...)
    if isodd(length(pairs)) || !isa(pairs[1:2:end], (String...)) 
        throw(ArgumentError("arguments must be in name-value pairs"))
    end
    jldopen(filename, "w") do file
        write(file, bytestring(name), value)
        for i=1:2:length(pairs)
            write(file, bytestring(pairs[i]), pairs[i+1])
        end
    end
end

# load with just a filename returns a dictionary containing all the variables
function load(filename::String)
    jldopen(filename, "r") do file
        (ByteString => Any)[var => read(file, var) for var in names(file)]
    end
end
# When called with explicitly requested variable names, return each one
function load(filename::String, varname::String)
    jldopen(filename, "r") do file
        read(file, varname)
    end
end
load(filename::String, varnames::String...) = load(filename, varnames)
function load(filename::String, varnames::(String...))
    jldopen(filename, "r") do file
        map((var)->read(file, var), varnames)
    end
end

function addrequire(file::JldFile, filename::String)
    files = read(file, pathrequire)
    push!(files, filename)
    o_delete(file, pathrequire)
    write(file, pathrequire, files)
end

export
    addrequire,
    ismmappable,
    jldopen,
    o_delete,
    plain,
    readmmap,
    readsafely,
    @load,
    @save,
    load,
    save

end
