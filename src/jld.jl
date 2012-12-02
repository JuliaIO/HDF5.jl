###############################################
## Reading and writing Julia data .jld files ##
###############################################

load("hdf5.jl")
module JLD
using HDF5
# Add methods to...
import HDF5.close, HDF5.read, HDF5.write

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
a_write    = HDF5.a_write
attrs      = HDF5.attrs
h5d_create = HDF5.h5d_create
h5f_close  = HDF5.h5f_close
h5f_create = HDF5.h5f_create
h5f_open   = HDF5.h5f_open
writearray = HDF5.writearray
hdf5_to_julia = HDF5.hdf5_to_julia

const magic_base = "Julia data file (HDF5), version "
const version_current = "0.0.0"
const pathrefs = "/_refs"
const pathtypes = "/_types"
const name_type_attr = "julia type"

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
    nrefs::Array{Int}

    function JldFile(id, filename, version, toclose::Bool, writeheader::Bool)
        f = new(id, filename, version, toclose, writeheader, [0])
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
            tmp = strcat(magic_base, f.version)
            magic[1:length(tmp)] = tmp.data
            rawfid = open(f.filename, "r+")
            write(rawfid, magic)
            close(rawfid)
        end
        f.toclose = false
    end
    nothing
end

function jldopen(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool)
    local f
    if ff && !wr
        error("Cannot append to a write-only file")
    end
    if !cr && !isfile(filename)
        error("File ", filename, " cannot be found")
    end
    pa = p_create(H5P_FILE_ACCESS)
    pa["fclose_degree"] = H5F_CLOSE_STRONG
    version = version_current
    if cr && (tr || !isfile(filename))
        # We're truncating, so we don't have to check the format of an existing file
        # Set the user block to 512 bytes, to save room for the header
        p = p_create(H5P_FILE_CREATE)
        p["userblock"] = 512
        f = h5f_create(filename, H5F_ACC_TRUNC, p.id, pa.id)
        return JldFile(f, filename, version, true, true)
    else
        # Test whether this is a jld file
        sz = filesize(filename)
        if sz < 512
            error("File size indicates this cannot be a Julia data file")
        end
        magic = Array(Uint8, 512)
        rawfid = open(filename, "r")
        magic = read(rawfid, magic)
        close(rawfid)
        local fj
        if magic[1:length(magic_base)] == magic_base.data
            f = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY, pa.id)
            version = bytestring(convert(Ptr{Uint8}, magic) + length(magic_base))
            close(pa)
            fj = JldFile(f, filename, version, true, true)
        else
            if ishdf5(filename)
                println("This is an HDF5 file, but it is not a recognized Julia data file. Opening anyway.")
                close(pa)
                fj = JldFile(f, filename, version_current, true, false)
            else
                error("This does not seem to be a Julia data or HDF5 file")
            end
        end
        if exists(fj, pathrefs)
            fj.nrefs[1] = length(fj[pathrefs])
        end
        return fj
    end
end

function jldopen(fname::String, mode::String)
    mode == "r"  ? jldopen(fname, true , false, false, false, false) :
    mode == "r+" ? jldopen(fname, true , true , false, false, false) :
    mode == "w"  ? jldopen(fname, false, true , true , true , false) :
    mode == "w+" ? jldopen(fname, true , true , true , true , false) :
    mode == "a"  ? jldopen(fname, false, true , true , false, true ) :
    mode == "a+" ? jldopen(fname, true , true , true , false, true ) :
    error("invalid open mode: ", mode)
end
jldopen(fname::String) = jldopen(fname, "r")

### Julia data file format implementation ###


## Read
function read(obj::Union(HDF5Group{JldFile}, HDF5Dataset{JldFile}))
    if !exists(attrs(obj), name_type_attr)
        # Fallback to plain read
        return read(plain(obj))
    end
    # Read the type
    typename = a_read(obj, name_type_attr)
    # Convert to Julia type
    T = julia_type(typename)
    if T == CompositeKind
        # Use type information in the file to ensure we find the right module
        typename = a_read(obj, "CompositeKind")
        try
            gtypes = root(obj)[pathtypes]
            objtype = gtypes[typename]
            n = read(objtype)
            modnames = a_read(plain(objtype), "Module")
            mod = Main
            for mname in modnames
                mod = eval(mod, symbol(mname))
            end
            T = eval(mod, symbol(typename))
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
    # Convert to Julia type
    T = julia_type(typename)
    local ret
    if T == CompositeKind
        # Read as a dict
        typename = a_read(obj, "CompositeKind")
        gtypes = root(obj)[pathtypes]
        objtype = gtypes[typename]
        n = read(objtype)
        v = getrefs(obj, Any)
        ret = Dict(n, v)
    else
        ret = read(obj, T)
    end
    ret
end
function readsafely(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString)
    obj = parent[name]
    ret = readsafely(obj)
    close(obj)
    return ret
end

# Basic types
for typ in (HDF5BitsKind, ByteString)
    @eval begin
        function read{T<:$typ}(obj::HDF5Dataset{JldFile}, ::Type{T})
            read(plain(obj), T)
        end
        function read{T<:$typ}(obj::HDF5Dataset{JldFile}, ::Type{Array{T}})
            read(plain(obj), Array{T})
        end
        function read{T<:$typ,N}(obj::HDF5Dataset{JldFile}, ::Type{Array{T,N}})
            read(plain(obj), Array{T})
        end
    end
end

read(obj::HDF5Dataset{JldFile}, ::Type{Nothing}) = nothing
read(obj::HDF5Dataset{JldFile}, ::Type{Bool}) = bool(read(obj, Uint8))
function read(obj::HDF5Dataset{JldFile}, ::Type{Array{Bool}})
    format = a_read(obj, "BoolFormat")
    if format == "EachUint8"
        bool(read(obj, Array{Uint8}))
    else
        error("bool format not recognized")
    end
end

# General arrays
function read{T,N}(obj::HDF5Dataset{JldFile}, ::Type{Array{T,N}})
    # Represented as an array of refs
    refs = read(plain(obj), Array{HDF5ReferenceObj})
    out = Array(T, size(refs))
    f = file(obj)
    for i = 1:numel(refs)
        out[i] = read(f[refs[i]])
    end
    return out
end

# CompositeKind
function read(obj::HDF5Dataset{JldFile}, T::CompositeKind)
    v = getrefs(obj, Any)
    t = ntuple(length(v), i->v[i])
    ccall(:jl_new_structt, Any, (Any,Any), T, t)
end

# Read an array of references
function getrefs{T}(obj::HDF5Dataset{JldFile}, ::Type{T})
    refs = read(plain(obj), Array{HDF5ReferenceObj})
    out = Array(T, size(refs))
    f = file(obj)
    for i = 1:numel(refs)
        out[i] = read(f[refs[i]])
    end
    return out
end


## Writing

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
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, n::Nothing)
    local dset
    try
        dset = HDF5Dataset(h5d_create(parent.id, name, HDF5.H5T_NATIVE_UINT8, dataspace(nothing).id, H5P_DEFAULT, H5P_DEFAULT, H5P_DEFAULT), file(parent))
        a_write(plain(dset), name_type_attr, "Nothing")
    finally
        close(dset)
    end
end

# Bools
write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, tf::Bool) = write(parent, name, uint8(tf), "Bool")
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, tf::Array{Bool})
    write(parent, name, uint8(tf), string(typeof(tf)))
    a_write(parent[name], "BoolFormat", "EachUint8")
end

# General array types (as arrays of references)
function write{T}(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, data::Array{T}, astype::String)
    local g
    local refs
    if !exists(file(parent), pathrefs)
        g = g_create(file(parent), pathrefs)
    else
        g = parent[pathrefs]
    end
    try
        # Write the items to the reference group
        refs = HDF5ReferenceObjArray(size(data)...)
        nrefs = file(parent).nrefs
        for i = 1:length(data)
            nrefs[1] += 1
            itemname = string(nrefs[1])
            write(g, itemname, data[i])
            # Extract references
            tmp = g[itemname]
            refs[i] = (tmp, pathrefs*"/"*itemname)
            close(tmp)
        end
    finally
        close(g)
    end
    # Write the references as the chosen variable
    cset, ctype = d_create(plain(parent), name, refs)
    try
        writearray(cset, ctype.id, refs.r)
        a_write(cset, name_type_attr, astype)
    finally
        close(ctype)
        close(cset)
    end
end
write{T}(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, data::Array{T}) = write(parent, name, data, string(typeof(data)))

# CompositeKind
function write(parent::Union(JldFile, HDF5Group{JldFile}), name::ASCIIString, s)
    T = typeof(s)
    if !isa(T, CompositeKind)
        error("This is the write function for CompositeKind, but the input is of type ", T)
    end
    Tname = string(T)
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
            nstr = Array(ASCIIString, length(n))
            for i = 1:length(n)
                nstr[i] = string(n[i])
            end
            write(gtypes, Tname, nstr)
            # Write the module name as an attribute
            mod = Base.full_name(T.name.module)
            modnames = [map(string, mod)...]
            a_write(plain(gtypes[Tname]), "Module", modnames)
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
    close(obj)
end


### Converting strings to Julia types
type UnsupportedType
end

is_valid_type_ex(s::Symbol) = true
is_valid_type_ex(x::Int) = true
is_valid_type_ex(e::Expr) = (e.head == :curly || e.head == :tuple) && all(map(is_valid_type_ex, e.args))


function julia_type(s::String)
    e = parse(s)[1]
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
    close,
    jldopen,
    read,
    readsafely,
    write

end
