import .FileIO
import .OrderedCollections: OrderedDict

function loadtodict!(d::AbstractDict, g::Union{File,Group}, prefix::String="")
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

_set_track_order(kwargs) = if get(kwargs, :track_order, false)
    prev = IDX_TYPE[]
    IDX_TYPE[] = HDF5.API.H5_INDEX_CRT_ORDER
    true, prev
else
    false, nothing
end

_restore_track_order(restore, prev) = (restore && (IDX_TYPE[] = prev); nothing)

# load with just a filename returns a flat dictionary containing all the variables
function fileio_load(f::FileIO.File{FileIO.format"HDF5"}; _kwargs...)
    kwargs = Dict{Symbol,Any}(_kwargs)  # mutate `_kwargs`
    d = pop!(kwargs, :dict, Dict{String,Any}())

    # infer `track_order` from Dict type
    (track_order = isa(d, OrderedDict)) && get!(kwargs, :track_order, track_order)

    saved = _set_track_order(kwargs)
    out = h5open(FileIO.filename(f), "r"; kwargs...) do file
        loadtodict!(d, file)
    end
    _restore_track_order(saved...)
    out
end

# when called with explicitly requested variable names, return each one
function fileio_load(f::FileIO.File{FileIO.format"HDF5"}, varname::AbstractString; kwargs...)
    saved = _set_track_order(kwargs)
    out = h5open(FileIO.filename(f), "r"; kwargs...) do file
        read(file, varname)
    end
    _restore_track_order(saved...)
    out
end

function fileio_load(f::FileIO.File{FileIO.format"HDF5"}, varnames::AbstractString...; kwargs...)
    saved = _set_track_order(kwargs)
    out = h5open(FileIO.filename(f), "r"; kwargs...) do file
        map(var -> read(file, var), varnames)
    end
    _restore_track_order(saved...)
    out
end

# save all the key-value pairs in the dict as top-level variables
function fileio_save(f::FileIO.File{FileIO.format"HDF5"}, dict::AbstractDict; kwargs...)
    h5open(FileIO.filename(f), "w"; kwargs...) do file
        for (k, v) in dict
            if !isa(k, AbstractString)
                throw(ArgumentError("keys must be strings (the names of variables), got $k"))
            end
            write(file, String(k), v)
        end
    end
end
