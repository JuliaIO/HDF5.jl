###########################################
## Reading and writing MATLAB .mat files ##
###########################################

require("hdf5.jl")
module MATIOMod
import Base.*
import HDF5Mod
import HDF5Mod.*

function matopen(filename::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool)
    if ff && !wr
        error("Cannot append to a write-only file")
    end
    if !cr && !isfile(filename)
        error("File ", filename, " cannot be found")
    end
    if cr && (tr || !isfile(filename))
        # We're truncating, so we don't have to check the format of an existing file
        magic = Array(Uint8, 512)
        identifier = "MATLAB 7.3 MAT-file"
        magic[1:length(identifier)] = identifier.data
        rawfid = open(filename, false, true, true, true, false)
        write(rawfid, magic)
        close(rawfid)
        return h5open(filename, true, wr, cr, tr, true, :FORMAT_MATLAB_V73)
    else
        # Test to see whether this is a MAT file
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
            return h5open(filename, rd, wr, cr, tr, ff, :FORMAT_MATLAB_V73)
        elseif magic[1:length(magic_matlab)] .== magic_matlab.data
            error("This seems to be a MAT file, but it's not a version 7.3 MAT-file. Not (yet) supported.")
        else
            error("This does not seem to be a MAT file")
        end
    end
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

type MatlabString; end
type MatlabCell; end

rawtypes_matlab = {
    "canonical empty"    => nothing,
    "int8"    => Array{Int8},
    "uint8"   => Array{Uint8},
    "int16"   => Array{Int16},
    "uint16"  => Array{Uint16},
    "int32"   => Array{Int32},
    "uint32"  => Array{Uint32},
    "int64"   => Array{Int64},
    "uint64"  => Array{Uint64},
    "single"  => Array{Float32},
    "double"  => Array{Float64},
    "cell"    => Array{Any},
    "char"    => MatlabString,
}

function read(obj::HDF5Mod.HDF5Object, ::Type{MatlabString})
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

#  function read(obj::HDF5Mod.HDF5Object, ::Type{MatlabCell})
#      T = HDF5Mod.hdf5_to_julia(obj)
#      println("We're back with ", T)
#      data = read(obj, T)
#      println("Here's data: ", data)
#      error("stop")
#      ret = CharString(data)
#      println(ret)
#      ret
#  end


str2type_matlab(str::ByteString) = rawtypes_matlab[str]

HDF5Mod.f2attr_typename[:FORMAT_MATLAB_V73] = "MATLAB_class"
HDF5Mod.f2typefunction[:FORMAT_MATLAB_V73] = str2type_matlab

export matopen
end
