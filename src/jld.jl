###############################################
## Reading and writing Julia data .jld files ##
###############################################

module JLD
using HDF5
# Add methods to...
import HDF5: close, dump, exists, file, getindex, g_create, g_open, name, names, read, size, write
import Base.show

# Debugging: comment this block out if you un-modulize hdf5.jl
# Types
Hid = HDF5.Hid
HDF5ReferenceObj = HDF5.HDF5ReferenceObj
HDF5BitsKind = HDF5.HDF5BitsKind
# Constants
H5F_ACC_RDONLY = HDF5.H5F_ACC_RDONLY
H5F_ACC_RDWR = HDF5.H5F_ACC_RDWR
H5F_ACC_TRUNC = HDF5.H5F_ACC_TRUNC
H5F_CLOSE_STRONG = HDF5.H5F_CLOSE_STRONG
H5P_DEFAULT = HDF5.H5P_DEFAULT
H5P_FILE_ACCESS = HDF5.H5P_FILE_ACCESS
H5P_FILE_CREATE = HDF5.H5P_FILE_CREATE
# Functions
h5d_create = HDF5.h5d_create
h5f_close  = HDF5.h5f_close
h5f_create = HDF5.h5f_create
h5f_open   = HDF5.h5f_open
writearray = HDF5.writearray
hdf5_to_julia = HDF5.hdf5_to_julia

const magic_base = "Julia data file (HDF5), version "
const version_current = "0.0.1"
const pathrefs = "/_refs"
const pathtypes = "/_types"
const pathrequire = "/_require"
const name_type_attr = "julia type"

### Dummy types used for converting attribute strings to Julia types
type UnsupportedType; end
type UnconvertedType; end
type CompositeKind; end   # here this means "a type with fields"

# The Julia Data file type
# Purpose of the nrefs field:
# length(group) only returns the number of _completed_ items in a group. Since
# we'll write recursively, we need to keep track of the number of reference
# objects _started_.
type JldFile
    plain::HDF5File
    version::String
    toclose::Bool
    writeheader::Bool
    mmaparrays::Bool

    function JldFile(plain::HDF5File, version::String=version_current, toclose::Bool=true,
                     writeheader::Bool=false, mmaparrays::Bool=false)
        f = new(plain, version, toclose, writeheader, mmaparrays)
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
    pa = p_create(H5P_FILE_ACCESS)
    try
        pa["fclose_degree"] = H5F_CLOSE_STRONG
        if cr && (tr || !isfile(filename))
            # We're truncating, so we don't have to check the format of an existing file
            # Set the user block to 512 bytes, to save room for the header
            p = p_create(H5P_FILE_CREATE)
            local f
            try
                p["userblock"] = 512
                f = h5f_create(filename, H5F_ACC_TRUNC, p.id, pa.id)
            finally
                close(p)
            end
            fj = JldFile(HDF5File(f, filename), version, true, true, mmaparrays)
            # initialize empty require list
            write(fj, pathrequire, ASCIIString[])
        else
            # Test whether this is a jld file
            sz = filesize(filename)
            if sz < 512
                error("File size indicates this cannot be a Julia data file")
            end
            magic = Array(Uint8, 512)
            rawfid = open(filename, "r")
            try
                magic = read(rawfid, magic)
            finally
                close(rawfid)
            end
            if beginswith(magic, magic_base.data)
                f = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY, pa.id)
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
                    println("This is an HDF5 file, but it is not a recognized Julia data file. Opening anyway.")
                    fj = JldFile(h5open(filename, rd, wr, cr, tr, ff), version_current, true, false, mmaparrays)
                else
                    error("This does not seem to be a Julia data or HDF5 file")
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

function jldobject(obj_id::Hid, parent)
    obj_type = HDF5.h5i_get_type(obj_id)
    obj_type == HDF5.H5I_GROUP ? JldGroup(HDF5Group(obj_id, file(parent.plain)), file(parent)) :
    obj_type == HDF5.H5I_DATATYPE ? HDF5Datatype(obj_id) :
    obj_type == HDF5.H5I_DATASET ? JldDataset(HDF5Dataset(obj_id, file(parent.plain)), file(parent)) :
    error("Invalid object type for path ", path)
end

getindex(parent::Union(JldFile, JldGroup), path::ASCIIString) =
    jldobject(HDF5.h5o_open(parent.plain.id, path), parent)

function getindex(parent::Union(JldFile, JldGroup, JldDataset), r::HDF5ReferenceObj)
    if r == HDF5.HDF5ReferenceObj_NULL; error("Reference is null"); end
    obj_id = HDF5.h5r_dereference(parent.plain.id, HDF5.H5R_OBJECT, r)
    jldobject(obj_id, parent)
end

### "Inherited" behaviors
g_create(parent::Union(JldFile, JldGroup), args...) = JldGroup(g_create(parent.plain, args...), file(parent))
g_open(parent::Union(JldFile, JldGroup), args...) = JldGroup(g_open(parent.plain, args...), file(parent))
name(p::Union(JldFile, JldGroup, JldDataset)) = name(p.plain)
exists(p::Union(JldFile, JldGroup, JldDataset), path::ASCIIString) = exists(p.plain, path)
root(p::Union(JldFile, JldGroup, JldDataset)) = g_open(file(p), "/")

### Julia data file format implementation ###


### Read ###

function read(parent::Union(JldFile, JldDataset), name::ASCIIString)
    local val
    obj = parent[name]
    try
        val = read(obj)
    finally
        close(obj)
    end
    val
end

# read and readsafely differ only in how they handle CompositeKind
function read(obj::Union(JldFile, JldDataset))
    if !exists(attrs(obj.plain), name_type_attr)
        # Fallback to plain read
        return read(obj.plain)
    end
    # Read the type
    typename = a_read(obj.plain, name_type_attr)
    if typename == "Tuple"
        return read_tuple(obj)
    end
    # Convert to Julia type
    T = julia_type(typename)
    if T == CompositeKind
        # Use type information in the file to ensure we find the right module
        typename = a_read(obj.plain, "CompositeKind")
        try
            gtypes = root(obj)[pathtypes]
            try
                objtype = gtypes[typename]
                try
                    modnames = a_read(objtype.plain, "Module")
                    mod = Main
                    for mname in modnames
                        mod = eval(mod, symbol(mname))
                    end
                    T = eval(mod, symbol(typename))
                finally
                    close(objtype)
                end
            finally
                close(gtypes)
            end
        catch
            error("Type ", typename, " is not recognized. As a fallback, you can load ", name(obj), " with readsafely().")
        end
    end
    read(obj, T)
end
function readsafely(obj::Union(JldFile, JldDataset))
    if !exists(attrs(obj.plain), name_type_attr)
        # Fallback to plain read
        return read(obj.plain)
    end
    # Read the type
    typename = a_read(obj.plain, name_type_attr)
    if typename == "Tuple"
        return read_tuple(obj)
    end
    # Convert to Julia type
    T = julia_type(typename)
    local ret
    if T == CompositeKind
        # Read as a dict
        typename = a_read(obj.plain, "CompositeKind")
        gtypes = root(obj)[pathtypes]
        try
            objtype = gtypes[typename]
            try
                n = read(objtype)
                v = getrefs(obj, Any)
                ret = Dict(n[1,:], v)
            finally
                close(objtype)
            end
        finally
            close(gtypes)
        end
    else
        ret = read(obj, T)
    end
    ret
end
function readsafely(parent::Union(JldFile, JldGroup), name::ASCIIString)
    local ret
    obj = parent[name]
    try
        ret = readsafely(JldDataset(obj))
    finally
        close(obj)
    end
    return ret
end

# Basic types
typealias BitsKindOrByteString Union(HDF5BitsKind, ByteString)
read{T<:BitsKindOrByteString}(obj::JldDataset, ::Type{T}) = read(obj.plain, T)
read{T<:HDF5BitsKind}(obj::JldDataset, ::Type{Array{T}}) =
    obj.file.mmaparrays && HDF5.iscontiguous(obj.plain) ? readmmap(obj.plain, Array{T}) : read(obj.plain, Array{T})
read{T<:ByteString}(obj::JldDataset, ::Type{Array{T}}) = read(obj.plain, Array{T})
read{T<:BitsKindOrByteString,N}(obj::JldDataset, ::Type{Array{T,N}}) = read(obj, Array{T})

# Nothing
read(obj::JldDataset, ::Type{Nothing}) = nothing
read(obj::JldDataset, ::Type{Bool}) = bool(read(obj, Uint8))

# Types
read{T}(obj::JldDataset, ::Type{Type{T}}) = T

# Bool
function read{N}(obj::JldDataset, ::Type{Array{Bool,N}})
    format = a_read(obj.plain, "julia_format")
    if format == "EachUint8"
        bool(read(obj.plain, Array{Uint8}))
    else
        error("bool format not recognized")
    end
end

# Complex
typealias ComplexTypes Union(Complex64, Complex128)
function read{T<:ComplexTypes}(obj::JldDataset, ::Type{T})
    a = read(obj.plain, Array{realtype(T)})
    a[1]+a[2]*im
end
function read{T<:ComplexTypes,N}(obj::JldDataset, ::Type{Array{T,N}})
    A = read(obj, Array{realtype(T)})
    reinterpret(T, A, ntuple(ndims(A)-1, i->size(A, i+1)))
end

# Symbol
read(obj::JldDataset, ::Type{Symbol}) = symbol(read(obj.plain, ASCIIString))
read{N}(obj::JldDataset, ::Type{Array{Symbol,N}}) = map(symbol, read(obj.plain, Array{ASCIIString}))

# Char
read(obj::JldDataset, ::Type{Char}) = char(read(obj.plain, Uint32))

# General arrays
read{T,N}(obj::JldDataset, t::Type{Array{T,N}}) = getrefs(obj, T)

# Tuple
function read_tuple(obj::JldDataset)
    t = read(obj, Array{Any, 1})
    return tuple(t...)
end
function read_tuple(obj::JldDataset, indices::AbstractVector)
    t = read(obj, Array{Any, 1})
    return tuple(t...)
end

# Dict
function read{T<:Associative}(obj::JldDataset, ::Type{T})
    kv = getrefs(obj, Any)
    ret = T()
    for (cn, c) in zip(kv[1], kv[2])
        ret[cn] = c
    end
    ret
end

# Expressions
function read(obj::JldDataset, ::Type{Expr})
    a = getrefs(obj, Any)
    Expr(a[1], a[2])
end

# CompositeKind
function read(obj::JldDataset, T::DataType)
    local x
    # Add the parameters
    params = a_read(obj.plain, "TypeParameters")
    p = Array(Any, length(params))
    for i = 1:length(params)
        p[i] = eval(parse(params[i]))
    end
    T = T{p...}
    v = getrefs(obj, Any)
    if length(v) == 0
        x = ccall(:jl_new_struct, Any, (Any,Any...), T)
    else
        n = T.names
        if length(v) != length(n)
            error("Wrong number of fields")
        end
        if !T.mutable
            x = ccall(:jl_new_structv, Any, (Any,Ptr{Void},Uint32), T, v, length(T.names))
        else
            x = ccall(:jl_new_struct_uninit, Any, (Any,), T)
            for i = 1:length(v)
                if isdefined(v, i)
                    setfield(x, n[i], v[i])
                end
            end
        end
    end
    x
end

# Read an array of references
function getrefs{T}(obj::JldDataset, ::Type{T})
    refs = read(obj.plain, Array{HDF5ReferenceObj})
    out = Array(T, size(refs))
    f = file(obj)
    for i = 1:length(refs)
        if refs[i] != HDF5.HDF5ReferenceObj_NULL
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

# dset[3:5, ...] syntax
# function getindex(dset::HDF5Dataset{JldFile}, indices::RangeIndex...)
#     typename = a_read(dset, name_type_attr)
#     # Convert to Julia type
#     T = julia_type(typename)
#     if !(T <: AbstractArray)
#         error("Ref syntax only works for arrays")
#     end
#     HDF5._getindex(plain(dset), eltype(T), indices...)
# end



### Writing ###

# Write "basic" types
function write{T<:Union(HDF5BitsKind, ByteString)}(parent::Union(JldFile, JldGroup), name::ASCIIString,
                                                   data::Union(T, Array{T}), astype::ByteString)
    # Create the dataset
    dset, dtype = d_create(parent.plain, name, data)
    try
        # Write the attribute
        a_write(dset, name_type_attr, astype)
        # Write the data
        writearray(dset, dtype.id, data)
    finally
        close(dset)
        close(dtype)
    end
end
write{T<:Union(HDF5BitsKind, ByteString)}(parent::Union(JldFile, JldGroup), name::ASCIIString, data::data::Union(T, Array{T})) =
    write(parent, name, data, full_typename(typeof(data)))

# Write nothing
function write(parent::Union(JldFile, JldGroup), name::ASCIIString, n::Nothing, astype::ASCIIString)
    local dset
    try
        dset = HDF5Dataset(h5d_create(parent.plain.id, name, HDF5.H5T_NATIVE_UINT8, dataspace(nothing).id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT), file(parent.plain))
        a_write(dset, name_type_attr, astype)
    finally
        close(dset)
    end
end
write(parent::Union(JldFile, JldGroup), name::ASCIIString, n::Nothing) = write(parent, name, n, "Nothing")

# Types
# the first is needed to avoid an ambiguity warning
write{T<:Top}(parent::Union(JldFile, JldGroup), name::ASCIIString, t::(Type{T}...)) = write(parent, name, Any[t...], "Tuple")
write{T}(parent::Union(JldFile, JldGroup), name::ASCIIString, t::Type{T}) = write(parent, name, nothing, string("Type{", full_typename(t), "}"))

# Bools
write(parent::Union(JldFile, JldGroup), name::ASCIIString, tf::Bool) = write(parent, name, uint8(tf), "Bool")
function write(parent::Union(JldFile, JldGroup), name::ASCIIString, tf::Array{Bool})
    write(parent, name, uint8(tf), full_typename(typeof(tf)))
    a_write(parent[name].plain, "julia_format", "EachUint8")
end

# Complex
realtype(::Type{Complex64}) = Float32
realtype(::Type{Complex128}) = Float64
function write(parent::Union(JldFile, JldGroup), name::ASCIIString, c::Complex)
    reim = [real(c), imag(c)]
    write(parent, name, reim, full_typename(typeof(c)))
end
function write{T<:Complex}(parent::Union(JldFile, JldGroup), name::ASCIIString, C::Array{T})
    reim = reinterpret(realtype(T), C, ntuple(ndims(C)+1, i->i==1?2:size(C,i-1)))
    write(parent, name, reim, full_typename(typeof(C)))
end

# Int128/Uint128

# Symbols
write(parent::Union(JldFile, JldGroup), name::ASCIIString, sym::Symbol) = write(parent, name, string(sym), "Symbol")
write(parent::Union(JldFile, JldGroup), name::ASCIIString, syms::Array{Symbol}) = write(parent, name, map(string, syms), full_typename(typeof(syms)))

# Char
write(parent::Union(JldFile, JldGroup), name::ASCIIString, char::Char) = write(parent, name, uint32(char), "Char")

# General array types (as arrays of references)
function write{T}(parent::Union(JldFile, JldGroup), path::ASCIIString, data::Array{T}, astype::String)
    local gref  # a group, inside /_refs, for all the elements in data
    local refs
    # Determine whether parent already exists in /_refs, so we can avoid group/dataset conflict
    pname = name(parent)
    if beginswith(pname, pathrefs)
        gref = g_create(parent, path*"g")
    else
        pathr = HDF5.joinpathh5(pathrefs, pname, path)
        if exists(file(parent), pathr)
            gref = g_open(file(parent), pathr)
        else
            gref = g_create(file(parent), pathr)
        end
    end
    grefname = name(gref)
    try
        # Write the items to the reference group
        refs = Array(HDF5ReferenceObj, size(data)...)
        # pad with zeros to keep in order
        nd = ndigits(length(data))
        z = "0"
        z = z[ones(Int, nd-1)]
        nd = 1
        for i = 1:length(data)
            if isdefined(data, i)
                if ndigits(i) > nd
                    nd = ndigits(i)
                    z = z[1:end-1]
                end
                itemname = z*string(i)
                write(gref, itemname, data[i])
                # Extract references
                tmp = gref[itemname]
                refs[i] = HDF5ReferenceObj(tmp.plain, grefname*"/"*itemname)
                close(tmp)
            else
                refs[i] = HDF5.HDF5ReferenceObj_NULL
            end
        end
    finally
        close(gref)
    end
    # Write the references as the chosen variable
    cset, ctype = d_create(parent.plain, path, refs)
    try
        writearray(cset, ctype.id, refs)
        a_write(cset, name_type_attr, astype)
    finally
        close(ctype)
        close(cset)
    end
end
write{T}(parent::Union(JldFile, JldGroup), path::ASCIIString, data::Array{T}) = write(parent, path, data, full_typename(typeof(data)))

# Tuple
write(parent::Union(JldFile, JldGroup), name::ASCIIString, t::Tuple) = write(parent, name, Any[t...], "Tuple")

# Associative (Dict)
function write(parent::Union(JldFile, JldGroup), name::ASCIIString, d::Associative)
    tn = full_typename(typeof(d))
    if tn == "DataFrame"
        return write_composite(parent, name, d)
    end
    n = length(d)
    T = eltype(d)
    ks = Array(T[1], n)
    vs = Array(T[2], n)
    i = 0
    for (k,v) in d
        ks[i+=1] = k
        vs[i] = v
    end
    da = Any[ks, vs]
    write(parent, name, da, tn)
end

# Expressions
function write(parent::Union(JldFile, JldGroup), name::ASCIIString, ex::Expr)
    args = ex.args
    # Discard "line" expressions
    keep = trues(length(args))
    for i = 1:length(args)
        if isa(args[i], Expr) && args[i].head == :line
            keep[i] = false
        end
    end
    args = args[keep]
    a = Any[ex.head, args]
    write(parent, name, a, "Expr")
end

# CompositeKind
write(parent::Union(JldFile, JldGroup), name::ASCIIString, s) = write_composite(parent, name, s)

function write_composite(parent::Union(JldFile, JldGroup), name::ASCIIString, s)
    T = typeof(s)
    if isempty(T.names)
        error("This is the write function for CompositeKind, but the input is of type ", T)
    end
    Tname = string(T.name.name)
    n = T.names
    local gtypes
    if !exists(file(parent), pathtypes)
        gtypes = g_create(file(parent), pathtypes)
    else
        gtypes = parent[pathtypes]
    end
    try
        if !exists(gtypes, Tname)
            # Write names to a dataset, so that other languages reading this file can
            # at least create a sensible dict
            nametype = Array(ASCIIString, 2, length(n))
            t = T.types
            for i = 1:length(n)
                nametype[1, i] = string(n[i])
                nametype[2, i] = string(t[i])
            end
            write(gtypes.plain, Tname, nametype)
            obj = gtypes[Tname]
            # Write the module name as an attribute
            mod = Base.fullname(T.name.module)
            modnames = [map(string, mod)...]
            a_write(obj.plain, "Module", modnames)
            close(obj)
        end
    finally
        close(gtypes)
    end
    # Write the data
    v = Array(Any, length(n))
    for i = 1:length(v)
        if isdefined(s, n[i])
            v[i] = getfield(s, n[i])
        end
    end
    write(parent, name, v, "CompositeKind")
    obj = parent[name]
    a_write(obj.plain, "CompositeKind", Tname)
    params = [map(full_typename, T.parameters)...]
    a_write(obj.plain, "TypeParameters", params)
    close(obj)
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

isarraycomplex{T<:Complex, N}(::Type{Array{T, N}}) = true
isarraycomplex(t) = false

### Read via getindex ###
function getindex(dset::JldDataset, indices::Union(Integer, RangeIndex)...)
    if !exists(attrs(dset.plain), name_type_attr)
        # Fallback to plain read
        return read(dset.plain)
    end
    # Read the type
    typename = a_read(dset.plain, name_type_attr)
    if typename == "Tuple"
        return read_tuple(dset, indices...)
    end
    # Convert to Julia type
    T = julia_type(typename)
    if !(T <: AbstractArray)
        error("Ref syntax only works for arrays")
    end
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


### Dump ###
function dump(io::IO, parent::Union(JldFile, JldGroup), n::Int, indent)
    println(io, typeof(parent), " len ", length(parent))
    if n > 0
        i = 1
        for k in names(parent)
            if k == "_refs" || k == "_types"
                continue
            end
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

_typedict = Dict{String, DataType}()
function julia_type(s::String)
    typ = get(_typedict, s, UnconvertedType)
    if typ == UnconvertedType
        e = parse(s)
        typ = UnsupportedType
        if is_valid_type_ex(e)
            try     # try needed to catch undefined symbols
                typ = eval(e)
                if !isa(typ, Type)
                    typ = UnsupportedType
                end
            catch
                try
                    typ = eval(Main, e)
                catch
                    typ = UnsupportedType
                    if !isa(typ, Type)
                        typ = UnsupportedType
                    end
                end
            end
        else
            typ = UnsupportedType
        end
        if typ != UnsupportedType
            _typedict[s] = typ
        end
    end
    typ
end

### Converting Julia types to fully qualified names
full_typename(jltype::UnionType) = @sprintf "Union(%s)" join(map(full_typename, jltype.types), ",")
function full_typename(tv::TypeVar)
    if is(tv.lb, None) && is(tv.ub, Any)
        "TypeVar(:$(tv.name))" 
    elseif is(tv.lb, None)
        "TypeVar(:$(tv.name),$(tv.ub))"
    else
        "TypeVar(:$(tv.name),$(tv.lb),$(tv.ub))"
    end
end
full_typename(jltype::(Type...)) = @sprintf "(%s)" join(map(full_typename, jltype), ",")
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

function load(filename, varnames::Array)
    vars = Array(Any, length(varnames))
    f = jldopen(filename)
    for i = 1:length(varnames)
        vars[i] = read(f, varnames[i])
    end
    close(f)
    tuple(vars...)
end

macro save(filename, vars...)
    if isempty(vars)
        # Save all variables in the current module
        writeexprs = Array(Expr, 0)
        m = current_module()
        for vname in names(m)
            v = eval(m, vname)
            if !isa(v, Module)
                push!(writeexprs, :(write(f, $(string(vname)), $(esc(vname)))))
            end
        end
    else
        writeexprs = Array(Expr, length(vars))
        for i = 1:length(vars)
            writeexprs[i] = :(write(f, $(string(vars[i])), $(esc(vars[i]))))
        end
    end
    Expr(:block, :(local f = jldopen($(esc(filename)), "w")), writeexprs..., :(close(f)))
end

macro load(filename, vars...)
    if isempty(vars)
        # Load all variables in the top level of the file
        readexprs = Array(Expr, 0)
        f = jldopen(filename)
        nms = names(f)
        for n in nms
            obj = f[n]
            if isa(obj, HDF5Dataset)
                sym = symbol(n)
                push!(readexprs, :($(esc(sym)) = read($f, $n)))
            end
        end
        return Expr(:block, readexprs..., :(close($f)))
    else
        readexprs = Array(Expr, length(vars))
        for i = 1:length(vars)
            readexprs[i] = :($(esc(vars[i])) = read(f, $(string(vars[i]))))
        end
        return Expr(:block, :(local f = jldopen($(esc(filename)))), readexprs..., :(close(f)))
    end
end

export
    jldopen,
    plain,
    readsafely,
    @load,
    @save

end
