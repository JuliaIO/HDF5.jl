###########################################
## Reading and writing MATLAB .mat files ##
###########################################

require("hdf5.jl")
#  module MATIO
#  import Base.*
#  import HDF5
#  import HDF5.*

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
            const identifier = "MATLAB 7.3 MAT-file"
#              identifier = "MATLAB 7.3 MAT-file, Platform: GLNXA64, Created on: Tue Oct  2 04:31:05 2012 HDF5 schema 1.00 .                     "
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
    read(plain(dset), T)
end

for (fsym, dsym) in
    ((:(write{T}), :T),
     (:(write{T}), :(Array{T})))
    @eval begin
        function ($fsym)(parent::Union(MatlabHDF5File, HDF5Group{MatlabHDF5File}), name::ByteString, data::$dsym)
            local typename
            # Determine the Matlab type
            println($dsym)
            println(T)
            if has(type2str_matlab, T)
                typename = type2str_matlab[T]
            else
                typename = "cell"
                error("Not (yet) supported")
            end
            println(typename)
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

#  function attr_to_type_matlab(dset::HDF5Dataset)
#      attr = a_open(dset, name_type_attr_matlab)
#  #      try
#          typename = read(attr, ByteString)
#          T = str2type_matlab[typename]
#  #      catch err
#  #          close(attr)
#  #          throw(err)
#  #      end
#      close(attr)
#  end
#  
#  function type_to_attr_matlab{T}(dset::HDF5Dataset, ::Type{T})
#      typename = string(T)
#      # Sanity check: will we be able to read this type back?
#      T2 = str_to_type_matlab(typename)
#      @assert T == T2
#      writeattr(dset, name_type_attr_matlab, typename)
#  end
#  
#  attr_to_type_map[:FORMAT_MATLAB_V73] = attr_to_type_matlab
#  type_to_attr_map[:FORMAT_MATLAB_V73] = type_to_attr_matlab

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

# Reads Array{T} where T is not a BitsKind. This is represented as an array of references to datasets
function read{T}(obj::HDF5Dataset, ::Type{Array{T}})
    refs = read(obj, Array{HDF5ReferenceObj})
    dimsref = size(refs)
    refsize = dimsref[1]
    dims = dimsref[2:end]
    data = Array(T, dims...)
    p = pointer(refs)
    for i = 1:numel(data)
        # while it's not guaranteed this is a reference to a dataset, we can do the following safely
        refobj = HDF5Dataset(h5r_dereference(obj.id, H5R_OBJECT, p), file(obj))
#          try
            # now check to make sure it's a reference to a dataset
            refobj_type = h5i_get_type(refobj.id)
            if refobj_type != H5I_DATASET
                error("When reading an Array{T}, each reference must be to a dataset")
            end
            data[i] = read(refobj)
#          catch err
#              close(refobj)
#              throw(err)
#          end
        close(refobj)
        p += refsize
    end
    data
end


#  export matopen
#  end
