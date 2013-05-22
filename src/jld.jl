###############################################
## Reading and writing Julia data .jld files ##
###############################################

module JLD
using HDF5
# Add methods to...
import HDF5.a_write, HDF5.close, HDF5.dump, HDF5.read, HDF5.getindex, Base.show, HDF5.size, HDF5.write

# Debugging: comment this block out if you un-modulize hdf5.jl
# Types
Hid = HDF5.Hid
HDF5ReferenceObj = HDF5.HDF5ReferenceObj
HDF5ReferenceObjArray = HDF5.HDF5ReferenceObjArray
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
type CompositeKind; end   # here this means "a type with fields"

# The Julia Data file type
# Purpose of the nrefs field:
# length(group) only returns the number of _completed_ items in a group. Since
# we'll write recursively, we need to keep track of the number of reference
# objects _started_.
type JldFile <: HDF5File
    id::Hid
    filename::String
    version::String
    toclose::Bool
    writeheader::Bool

    function JldFile(id, filename, version, toclose::Bool, writeheader::Bool)
        f = new(id, filename, version, toclose, writeheader)
        if toclose
            finalizer(f, close)
        end
        f
    end
end
JldFile(id, filename, version, toclose) = JldFile(id, filename, version, toclose, false)
JldFile(id, filename, version) = JldFile(id, filename, version, true, false)
JldFile(id, filename) = JldFile(id, filename, version_current, true, false)
function close(f::JldFile)
    if f.toclose
        h5f_close(f.id)
        if f.writeheader
            magic = zeros(Uint8, 512)
            tmp = string(magic_base, f.version)
            magic[1:length(tmp)] = tmp.data
            rawfid = open(f.filename, "r+")
            write(rawfid, magic)
            close(rawfid)
        end
        f.toclose = false
    end
    nothing
end
show(io::IO, fid::JldFile) = isvalid(fid) ? print(io, "Julia data file version ", fid.version, ": ", fid.filename) : print(io, "Julia data file (closed): ", fid.filename)

function jldopen(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool)
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
            fj = JldFile(f, filename, version, true, true)
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
                fj = JldFile(f, filename, version, true, true)
                # Load any required files/packages
                if has(fj, pathrequire)
                    r = read(fj, pathrequire)
                    for fn in r
                        require(fn)
                    end
                end
            else
                if ishdf5(filename)
                    println("This is an HDF5 file, but it is not a recognized Julia data file. Opening anyway.")
                    fj = JldFile(f, filename, version_current, true, false)
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

function jldopen(fname::String, mode::String)
    mode == "r"  ? jldopen(fname, true , false, false, false, false) :
    mode == "r+" ? jldopen(fname, true , true , false, false, false) :
    mode == "w"  ? jldopen(fname, false, true , true , true , false) :
#     mode == "w+" ? jldopen(fname, true , true , true , true , false) :
#     mode == "a"  ? jldopen(fname, false, true , true , false, true ) :
#     mode == "a+" ? jldopen(fname, true , true , true , false, true ) :
    error("invalid open mode: ", mode)
end
jldopen(fname::String) = jldopen(fname, "r")

### "Inherited" behaviors
a_write(parent::Union(HDF5Group{JldFile}, HDF5Dataset{JldFile}), name::ASCIIString, data) = a_write(plain(parent), name, data)

### Julia data file format implementation ###


### Read ###

# read and readsafely differ only in how they handle CompositeKind
function read(obj::Union(HDF5Group{JldFile}, HDF5Dataset{JldFile}))
    if !exists(attrs(obj), name_type_attr)
        # Fallback to plain read
        return read(plain(obj))
    end
    # Read the type
    typename = a_read(obj, name_type_attr)
    if typename == "Tuple"
        return read_tuple(obj)
    end
    # Convert to Julia type
    T = julia_type(typename)
    if T == CompositeKind
        # Use type information in the file to ensure we find the right module
        typename = a_read(obj, "CompositeKind")
        try
            gtypes = root(obj)[pathtypes]
            try
                objtype = gtypes[typename]
                try
                    modnames = a_read(plain(objtype), "Module")
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
function readsafely(obj::Union(HDF5Group{JldFile}, HDF5Dataset{JldFile}))
    if !exists(attrs(obj), name_type_attr)
        # Fallback to plain read
        return read(plain(obj))
    end
    # Read the type
    typename = a_read(obj, name_type_attr)
    if typename == "Tuple"
        return read_tuple(obj)
    end
    # Convert to Julia type
    T = julia_type(typename)
    local ret
    if T == CompositeKind
        # Read as a dict
        typename = a_read(obj, "CompositeKind")
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
function readsafely(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString)
    local ret
    obj = parent[name]
    try
        ret = readsafely(obj)
    finally
        close(obj)
    end
    return ret
end

# Basic types
typealias BitsKindOrByteString Union(HDF5BitsKind, ByteString)
function read{T<:BitsKindOrByteString}(obj::HDF5Dataset{JldFile}, ::Type{T})
    read(plain(obj), T)
end
function read{T<:BitsKindOrByteString}(obj::HDF5Dataset{JldFile}, ::Type{Array{T}})
    read(plain(obj), Array{T})
end
function read{T<:BitsKindOrByteString,N}(obj::HDF5Dataset{JldFile}, ::Type{Array{T,N}})
    read(plain(obj), Array{T})
end

# Nothing
read(obj::HDF5Dataset{JldFile}, ::Type{Nothing}) = nothing
read(obj::HDF5Dataset{JldFile}, ::Type{Bool}) = bool(read(obj, Uint8))

# Types
read{T}(obj::HDF5Dataset{JldFile}, ::Type{Type{T}}) = T

# Bool
function read{N}(obj::HDF5Dataset{JldFile}, ::Type{Array{Bool,N}})
    format = a_read(obj, "julia_format")
    if format == "EachUint8"
        bool(read(plain(obj), Array{Uint8}))
    else
        error("bool format not recognized")
    end
end

# Complex
typealias ComplexTypes Union(Complex64, Complex128)
function read{T<:ComplexTypes}(obj::HDF5Dataset{JldFile}, ::Type{T})
    a = read(plain(obj), Array{realtype(T)})
    a[1]+a[2]*im
end
function read{T<:ComplexTypes,N}(obj::HDF5Dataset{JldFile}, ::Type{Array{T,N}})
    A = read(plain(obj), Array{realtype(T)})
    reinterpret(T, A, ntuple(ndims(A)-1, i->size(A, i+1)))
end

# Symbol
read(obj::HDF5Dataset{JldFile}, ::Type{Symbol}) = symbol(read(plain(obj), ASCIIString))
read{N}(obj::HDF5Dataset{JldFile}, ::Type{Array{Symbol,N}}) = map(symbol, read(plain(obj), Array{ASCIIString}))

# Char
read(obj::HDF5Dataset{JldFile}, ::Type{Char}) = char(read(plain(obj), Uint32))

# General arrays
read{T,N}(obj::HDF5Dataset{JldFile}, t::Type{Array{T,N}}) = getrefs(obj, T)

# Tuple
function read_tuple(obj::HDF5Dataset{JldFile})
    t = read(obj, Array{Any, 1})
    return tuple(t...)
end
function read_tuple(obj::HDF5Dataset{JldFile}, indices::AbstractVector)
    t = read(obj, Array{Any, 1})
    return tuple(t...)
end

# Dict
function read{T<:Associative}(obj::HDF5Dataset{JldFile}, ::Type{T})
    kv = getrefs(obj, Any)
    T(kv[1], kv[2])
end

# Expressions
function read(obj::HDF5Dataset{JldFile}, ::Type{Expr})
    a = getrefs(obj, Any)
    Expr(a[1], a[2])
end

# CompositeKind
function read(obj::HDF5Dataset{JldFile}, T::DataType)
    local x
    # Add the parameters
    params = a_read(obj, "TypeParameters")
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
        x = ccall(:jl_new_struct_uninit, Any, (Any,), T)
        for i = 1:length(v)
            setfield(x, n[i], v[i])
        end
    end
    x
end

# Read an array of references
function getrefs{T}(obj::HDF5Dataset{JldFile}, ::Type{T})
    refs = read(plain(obj), Array{HDF5ReferenceObj})
    out = Array(T, size(refs))
    f = file(obj)
    for i = 1:length(refs)
        out[i] = read(f[refs[i]])
    end
    return out
end
function getrefs{T}(obj::HDF5Dataset{JldFile}, ::Type{T}, indices::Union(Integer, AbstractVector)...)
    refs = read(plain(obj), Array{HDF5ReferenceObj})
    refs = refs[indices...]
    f = file(obj)
    local out
    if isa(refs, HDF5.HDF5ObjPtr)
        # This is a scalar, not an array
        out = read(f[refs])
    else
        out = Array(T, size(refs))
        for i = 1:length(refs)
            out[i] = read(f[refs[i]])
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
for (fsym, dsym) in
    ((:(write{T<:HDF5BitsKind}), :T),
     (:(write{T<:HDF5BitsKind}), :(Array{T})),
     (:(write{S<:ByteString}), :S),
     (:(write{S<:ByteString}), :(Array{S}))
    )
    @eval begin
        function ($fsym)(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, data::$dsym, astype::ByteString)
            # Create the dataset
            dset, dtype = d_create(plain(parent), name, data)
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
        ($fsym)(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, data::$dsym) = write(parent, name, data, string(typeof(data)))
    end
end

# Write nothing
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, n::Nothing, astype::ASCIIString)
    local dset
    try
        dset = HDF5Dataset(h5d_create(parent.id, name, HDF5.H5T_NATIVE_UINT8, dataspace(nothing).id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT), file(parent))
        a_write(plain(dset), name_type_attr, astype)
    finally
        close(dset)
    end
end
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, n::Nothing) = write(parent, name, n, "Nothing")

# Types
# the first is needed to avoid an ambiguity warning
write{T<:Top}(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, t::(Type{T}...)) = write(parent, name, Any[t...], "Tuple")
write{T}(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, t::Type{T}) = write(parent, name, nothing, string("Type{", t, "}"))

# Bools
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, tf::Bool) = write(parent, name, uint8(tf), "Bool")
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, tf::Array{Bool})
    write(parent, name, uint8(tf), string(typeof(tf)))
    a_write(plain(parent[name]), "julia_format", "EachUint8")
end

# Complex
realtype(::Type{Complex64}) = Float32
realtype(::Type{Complex128}) = Float64
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, c::Complex)
    reim = [real(c), imag(c)]
    write(parent, name, reim, string(typeof(c)))
end
function write{T<:Complex}(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, C::Array{T})
    reim = reinterpret(realtype(T), C, ntuple(ndims(C)+1, i->i==1?2:size(C,i-1)))
    write(parent, name, reim, string(typeof(C)))
end

# Int128/Uint128

# Symbols
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, sym::Symbol) = write(parent, name, string(sym), "Symbol")
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, syms::Array{Symbol}) = write(parent, name, map(string, syms), string(typeof(syms)))

# Char
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, char::Char) = write(parent, name, uint32(char), "Char")

# General array types (as arrays of references)
function write{T}(parent::Union(JldFile, HDF5Group{JldFile}), path::ASCIIString, data::Array{T}, astype::String)
    local gref  # a group, inside /_refs, for all the elements in data
    local refs
    if !exists(file(parent), pathrefs)
        # If necessary, create /_refs
        grefbase = g_create(file(parent), pathrefs)
        gref = g_create(grefbase, path)
        close(grefbase)
    else
        # Determine whether the parent is already in /_refs
        pname = name(parent)
        if length(pname) >= length(pathrefs) && pname[1:length(pathrefs)] == pathrefs
            gref = g_create(parent, path*"g") # to avoid group/dataset conflict
        else
            gref = g_create(file(parent), pathrefs*pname*"/"*path)
        end
    end
    grefname = name(gref)
    try
        # Write the items to the reference group
        refs = HDF5ReferenceObjArray(size(data)...)
        # pad with zeros to keep in order
        nd = ndigits(length(data))
        z = "0"
        z = z[ones(Int, nd-1)]
        nd = 1
        for i = 1:length(data)
            if ndigits(i) > nd
                nd = ndigits(i)
                z = z[1:end-1]
            end
            itemname = z*string(i)
            write(gref, itemname, data[i])
            # Extract references
            tmp = gref[itemname]
            refs[i] = (tmp, grefname*"/"*itemname)
            close(tmp)
        end
    finally
        close(gref)
    end
    # Write the references as the chosen variable
    cset, ctype = d_create(plain(parent), path, refs)
    try
        writearray(cset, ctype.id, refs.r)
        a_write(cset, name_type_attr, astype)
    finally
        close(ctype)
        close(cset)
    end
end
write{T}(parent::Union(JldFile, HDF5Group{JldFile}), path::ASCIIString, data::Array{T}) = write(parent, path, data, string(typeof(data)))

# Tuple
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, t::Tuple) = write(parent, name, Any[t...], "Tuple")

# Associative (Dict)
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, d::Associative)
    if string(typeof(d)) == "DataFrame"
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
    write(parent, name, da, string(typeof(d)))
end

# Expressions
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, ex::Expr)
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
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, s) = write_composite(parent, name, s)

function write_composite(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, s)
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
            write(plain(gtypes), Tname, nametype)
            obj = gtypes[Tname]
            # Write the module name as an attribute
            mod = Base.full_name(T.name.module)
            modnames = [map(string, mod)...]
            a_write(plain(obj), "Module", modnames)
            close(obj)
        end
    finally
        close(gtypes)
    end
    # Write the data
    v = Array(Any, length(n))
    for i = 1:length(v)
        v[i] = getfield(s, n[i])
    end
    write(parent, name, v, "CompositeKind")
    obj = parent[name]
    a_write(plain(obj), "CompositeKind", Tname)
    params = [map(string, T.parameters)...]
    a_write(plain(obj), "TypeParameters", params)
    close(obj)
end

### Size, length, etc ###
function size(dset::HDF5Dataset{JldFile})
    if !exists(attrs(dset), name_type_attr)
        return size(plain(dset))
    end
    # Read the type
    typename = a_read(dset, name_type_attr)
    if typename == "Tuple"
        return size(plain(dset))
    end
    # Convert to Julia type
    T = julia_type(typename)
    if T == CompositeKind || T <: Associative || T == Expr
        return ()
    elseif T <: Complex
        return ()
    elseif isarraycomplex(T)
        sz = size(plain(dset))
        return sz[2:end]
    end
    size(plain(dset))
end

isarraycomplex{T<:Complex, N}(::Type{Array{T, N}}) = true
isarraycomplex(t) = false

### Read via getindex ###
function getindex(dset::HDF5Dataset{JldFile}, indices::Union(Integer, RangeIndex)...)
    if !exists(attrs(dset), name_type_attr)
        # Fallback to plain read
        return read(plain(dset))
    end
    # Read the type
    typename = a_read(dset, name_type_attr)
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

_getindex{T<:HDF5BitsKind,N}(dset::HDF5Dataset{JldFile}, ::Type{Array{T,N}}, indices::RangeIndex...) = HDF5._getindex(plain(dset), T, indices...)
function _getindex{T<:Complex,N}(dset::HDF5Dataset{JldFile}, ::Type{Array{T,N}}, indices::RangeIndex...)
    reinterpret(T, HDF5._getindex(plain(dset), realtype(T), 1:2, indices...), ntuple(length(indices), i->length(indices[i])))
end
function _getindex{N}(dset::HDF5Dataset{JldFile}, ::Type{Array{Bool,N}}, indices::RangeIndex...)
    tf = HDF5._getindex(plain(dset), Uint8, indices...)
    bool(tf)
end
_getindex{T,N}(dset::HDF5Dataset{JldFile}, ::Type{Array{T,N}}, indices::Union(Integer, RangeIndex)...) = getrefs(dset, T, indices...)


### Dump ###
function dump(io::IO, parent::Union(JldFile, HDF5Group{JldFile}), n::Int, indent)
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
                if exists(attrs(v), name_type_attr)
                    typename = a_read(v, name_type_attr)
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
is_valid_type_ex(x::Int) = true
is_valid_type_ex(e::Expr) = ((e.head == :curly || e.head == :tuple) && all(map(is_valid_type_ex, e.args))) || (e.head == :call && e.args[1] == :Union)

function julia_type(s::String)
    e = parse(s)
    typ = UnsupportedType
    if is_valid_type_ex(e)
        try     # try needed to catch undefined symbols
            typ = eval(e)
            if !isa(typ, Type)
                typ = UnsupportedType
            end
        catch
            typ = UnsupportedType
        end
    else
        typ = UnsupportedType
    end
    typ
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

export
    jldopen,
    plain,
    readsafely

end
