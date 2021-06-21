import .FileIO

function loadtodict!(d::Dict, g::Union{File,Group}, prefix::String="")
    for k in keys(g)
        v = g[k]
        if v isa Group
            loadtodict!(d, v, prefix * k * "/")
        else
            d[prefix * k] = read(g, k)
        end
    end
    return d
end

# load with just a filename returns a flat dictionary containing all the variables
function fileio_load(f::FileIO.File{FileIO.format"HDF5"}; kwargs...)
    h5open(FileIO.filename(f), "r"; kwargs...) do file
        loadtodict!(Dict{String,Any}(), file)
    end
end

# when called with explicitly requested variable names, return each one
function fileio_load(f::FileIO.File{FileIO.format"HDF5"}, varname::AbstractString; kwargs...)
    h5open(FileIO.filename(f), "r"; kwargs...) do file
        read(file, varname)
    end
end

function fileio_load(f::FileIO.File{FileIO.format"HDF5"}, varnames::AbstractString...; kwargs...)
    h5open(FileIO.filename(f), "r"; kwargs...) do file
        map(var -> read(file, var), varnames)
    end
end

# save all the key-value pairs in the dict as top-level variables
function fileio_save(f::FileIO.File{FileIO.format"HDF5"}, dict::AbstractDict; kwargs...)
    h5open(FileIO.filename(f), "w"; kwargs...) do file
        for (k,v) in dict
            if !isa(k, AbstractString)
                throw(ArgumentError("keys must be strings (the names of variables), got $k"))
            end
            write(file, String(k), v)
        end
    end
end
