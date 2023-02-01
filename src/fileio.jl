import .FileIO

function loadtodict!(d::AbstractDict, g::Union{File,Group}, prefix::String="")
    for k in keys(g)
        if (v = g[k]) isa Group
            loadtodict!(d, v, prefix * k * "/")
        else
            d[prefix * k] = read(g, k)
        end
    end
    return d
end

_infer_track_order(track_order::Union{Nothing,Bool}, dict::AbstractDict) =
    something(track_order, false)

@require OrderedCollections = "bac558e1-5e72-5ebc-8fee-abe8a469f55d" begin
    _infer_track_order(
        track_order::Union{Nothing,Bool}, dict::OrderedCollections.OrderedDict
    ) = something(track_order, true)
end

# load with just a filename returns a flat dictionary containing all the variables
function fileio_load(
    f::FileIO.File{FileIO.format"HDF5"};
    dict=Dict{String,Any}(),
    track_order::Union{Nothing,Bool}=nothing,
    kwargs...
)
    h5open(
        FileIO.filename(f),
        "r";
        track_order=_infer_track_order(track_order, dict),
        kwargs...
    ) do file
        loadtodict!(dict, file)
    end
end

# when called with explicitly requested variable names, return each one
function fileio_load(
    f::FileIO.File{FileIO.format"HDF5"}, varname::AbstractString; kwargs...
)
    h5open(FileIO.filename(f), "r"; kwargs...) do file
        read(file, varname)
    end
end

function fileio_load(
    f::FileIO.File{FileIO.format"HDF5"}, varnames::AbstractString...; kwargs...
)
    h5open(FileIO.filename(f), "r"; kwargs...) do file
        map(var -> read(file, var), varnames)
    end
end

# save all the key-value pairs in the dict as top-level variables
function fileio_save(
    f::FileIO.File{FileIO.format"HDF5"},
    dict::AbstractDict;
    track_order::Union{Nothing,Bool}=nothing,
    kwargs...
)
    h5open(
        FileIO.filename(f),
        "w";
        track_order=_infer_track_order(track_order, dict),
        kwargs...
    ) do file
        for (k, v) in dict
            isa(k, AbstractString) || throw(
                ArgumentError("keys must be strings (the names of variables), got $k")
            )
            write(file, String(k), v)
        end
    end
end
