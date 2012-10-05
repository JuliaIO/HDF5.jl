###########################################
## Reading and writing MATLAB .mat files ##
###########################################

require("hdf5.jl")
module MatIO
import Base.*
import HDF5
import HDF5.*

# Debugging: comment this block out if you un-modulize hdf5.jl
# Types
Hid = HDF5.Hid
HDF5ReferenceObj = HDF5.HDF5ReferenceObj
HDF5ReferenceObjArray = HDF5.HDF5ReferenceObjArray
HDF5BitsKind = HDF5.HDF5BitsKind
# Constants
H5P_FILE_CREATE = HDF5.H5P_FILE_CREATE
H5F_ACC_TRUNC = HDF5.H5F_ACC_TRUNC
H5P_DEFAULT = HDF5.H5P_DEFAULT
H5F_ACC_RDWR = HDF5.H5F_ACC_RDWR
H5F_ACC_RDONLY = HDF5.H5F_ACC_RDONLY
# Functions
h5f_close  = HDF5.h5f_close
h5f_create = HDF5.h5f_create
writearray = HDF5.writearray

type MatlabHDF5File <: HDF5File
    id::Hid
    filename::String
    toclose::Bool
    writeheader::Bool

    function MatlabHDF5File(id, filename, toclose::Bool, writeheader::Bool)
        f = new(id, filename, toclose, writeheader)
        if toclose
            finalizer(f, close)
        end
        f
    end
end
MatlabHDF5File(id, filename, toclose) = MatlabHDF5File(id, filename, toclose, false)
MatlabHDF5File(id, filename) = MatlabHDF5File(id, filename, true, false)
function close(f::MatlabHDF5File)
    if f.toclose
        h5f_close(f.id)
        if f.writeheader
            magic = zeros(Uint8, 512)
            const identifier = "MATLAB 7.3 MAT-file" # minimal but sufficient
            magic[1:length(identifier)] = identifier.data
            magic[126] = 0x02
            magic[127] = 0x49
            magic[128] = 0x4d
            rawfid = open(f.filename, "r+")
            write(rawfid, magic)
            close(rawfid)
        end
        f.toclose = false
    end
    nothing
end

function matopen(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool)
    local f
    if ff && !wr
        error("Cannot append to a write-only file")
    end
    if !cr && !isfile(filename)
        error("File ", filename, " cannot be found")
    end
    if cr && (tr || !isfile(filename))
        # We're truncating, so we don't have to check the format of an existing file
        # Set the user block to 512 bytes, to save room for the header
        p = p_create(H5P_FILE_CREATE)
        p["userblock"] = 512
        f = h5f_create(filename, H5F_ACC_TRUNC, p.id, H5P_DEFAULT)
        writeheader = true
    else
        # Test whether this is a MAT file
        sz = filesize(filename)
        magic_matlab = "MATLAB"
        magic_hdf5 = "MATLAB 7.3 MAT-file"
        local magic
        if sz >= length(magic_hdf5)
            magic = Array(Uint8, length(magic_hdf5))
        else
            error("File size indicates this cannot be a MAT file")
        end
        rawfid = open(filename, "r")
        magic = read(rawfid, magic)
        close(rawfid)
        if magic == magic_hdf5.data
            f = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY)
        elseif magic[1:length(magic_matlab)] .== magic_matlab.data
            error("This seems to be a MAT file, but it's not a version 7.3 MAT-file. Not (yet) supported.")
        else
            error("This does not seem to be a MAT file")
        end
    end
    MatlabHDF5File(f, filename, true, true)
end

function matopen(fname::String, mode::String)
    mode == "r"  ? matopen(fname, true , false, false, false, false) :
    mode == "r+" ? matopen(fname, true , true , false, false, false) :
    mode == "w"  ? matopen(fname, false, true , true , true , false) :
    mode == "w+" ? matopen(fname, true , true , true , true , false) :
    mode == "a"  ? matopen(fname, false, true , true , false, true ) :
    mode == "a+" ? matopen(fname, true , true , true , false, true ) :
    error("invalid open mode: ", mode)
end


### Matlab file format specification ###

const name_type_attr_matlab = "MATLAB_class"

function read(dset::HDF5Dataset{MatlabHDF5File})
    # Read the MATLAB class
    mattype = a_read(dset, name_type_attr_matlab)
    # Convert to Julia type
    T = str2type_matlab[mattype]
    # Read the dataset
    if mattype == "cell"
        # Represented as an array of refs
        refs = read(plain(dset), Array{HDF5ReferenceObj})
        out = Array(Any, size(refs))
        f = file(dset)
        for i = 1:numel(refs)
            out[i] = read(f[refs[i]])
        end
        return out
    end
    read(plain(dset), T)
end

for (fsym, dsym) in
    ((:(write{T<:HDF5BitsKind}), :T),
     (:(write{T<:HDF5BitsKind}), :(Array{T})))
    @eval begin
        function ($fsym)(parent::Union(MatlabHDF5File, HDF5Group{MatlabHDF5File}), name::ByteString, data::$dsym)
            local typename
            # Determine the Matlab type
            if has(type2str_matlab, T)
                typename = type2str_matlab[T]
            else
                error("Type ", T, " is not (yet) supported")
            end
            # Everything in Matlab is an array
            if !isa(data, Array)
                data = [data]
            end
            # Create the dataset
            dset, dtype = d_create(plain(parent), name, data)
            try
                # Write the attribute
                a_write(dset, name_type_attr_matlab, typename)
                # Write the data
                writearray(dset, dtype.id, data)
            catch err
                close(dset)
                close(dtype)
                throw(err)
            end
            close(dset)
            close(dtype)
        end
    end
end

# Write cell arrays
function write{T}(parent::Union(MatlabHDF5File, HDF5Group{MatlabHDF5File}), name::ByteString, data::Array{T})
    pathrefs = "/#refs#"
    local g
    local refs
    if !exists(parent, pathrefs)
        g = g_create(file(parent), pathrefs)
    else
        g = parent[pathrefs]
    end
#    try
        # If needed, create the "empty" item
        if !exists(g, "a/MATLAB_empty")
            if exists(g, "a")
                error("Must create the empty item, with name a, first")
            end
            pg = plain(g)
            edata = zeros(Uint64, 2)
            eset, etype = d_create(pg, "a", edata)
#              try
                writearray(eset, etype.id, edata)
                a_write(eset, name_type_attr_matlab, "canonical empty")
                a_write(eset, "MATLAB_empty", uint8(0))
#              catch err
#                  close(etype)
#                  close(eset)
#                  throw(err)
#              end
            close(etype)
            close(eset)
        end
        # Write the items to the reference group
        refs = HDF5ReferenceObjArray(size(data)...)
        l = length(g)-1
        for i = 1:length(data)
            itemname = string(l+i)
            write(g, itemname, data[i])
            # Extract references
            tmp = g[itemname]
            refs[i] = (tmp, pathrefs*"/"*itemname)
            close(tmp)
        end
#      catch err
#          close(g)
#          throw(err)
#      end
    close(g)
    # Write the references as the chosen variable
    cset, ctype = d_create(plain(parent), name, refs)
#          try
        writearray(cset, ctype.id, refs.r)
        a_write(cset, name_type_attr_matlab, "cell")
#          catch err
#              close(ctype)
#              close(cset)
#              throw(err)
#          end
    close(ctype)
    close(cset)
end


## Type conversion operations ##

type MatlabString; end

const str2type_matlab = {
    "canonical empty" => nothing,
    "int8"    => Array{Int8},
    "uint8"   => Array{Uint8},
    "int16"   => Array{Int16},
    "uint16"  => Array{Uint16},
    "int32"   => Array{Int64},
    "uint64"  => Array{Uint64},
    "single"  => Array{Int32},
    "uint32"  => Array{Uint32},
    "int64"   => Array{Float32},
    "double"  => Array{Float64},
    "cell"    => Array{Any},
    "char"    => MatlabString,
}
# These operate on the element type rather than the whole type
const type2str_matlab = {
    Int8    => "int8",
    Uint8   => "uint8",
    Int16   => "int16",
    Uint16  => "uint16",
    Int32   => "int32",
    Uint32  => "uint32",
    Int64   => "int64",
    Uint64  => "uint64",
    Float32 => "single",
    Float64 => "double",
}


#  function read(obj::HDF5.HDF5Object, ::Type{MatlabString})
function read(obj::HDF5Object, ::Type{MatlabString})
    T = HDF5Mod.hdf5_to_julia(obj)
    data = read(obj, T)
    if size(data, 1) == 1
        sz = size(data)
        data = reshape(data, sz[2:end])
    end
    if ndims(data) == 1
        return CharString(data)
    else
        return Char(data)
    end
end


export
    close,
    matopen,
    read,
    write
    
end
