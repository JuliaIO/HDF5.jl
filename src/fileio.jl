import .FileIO
import .OrderedCollections: OrderedDict

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

_change_iteration_order(kwargs) = if get(kwargs, :track_order, false)
    prev = IDX_TYPE[]
    IDX_TYPE[] = HDF5.API.H5_INDEX_CRT_ORDER  # index (iterate) on creation order
    true, prev
else
    false, nothing
end

_restore_iteration_order(restore, prev) = (restore && (IDX_TYPE[] = prev); nothing)

# load with just a filename returns a flat dictionary containing all the variables
function fileio_load(f::FileIO.File{FileIO.format"HDF5"}; kwargs...)
    kwargs = Dict{Symbol,Any}(kwargs)  # mutate `kwargs`
    d = pop!(kwargs, :dict, Dict{String,Any}())

    # infer `track_order` from Dict type
    if (track_order = isa(d, OrderedDict))
        get!(kwargs, :track_order, track_order)
    end

    saved = _change_iteration_order(kwargs)
    out = h5open(FileIO.filename(f), "r"; kwargs...) do file
        loadtodict!(d, file)
    end
    _restore_iteration_order(saved...)
    out
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
    if (track_order = isa(dict, OrderedDict))
        kwargs = Dict{Symbol,Any}(kwargs)
        get!(kwargs, :track_order, track_order)
    end
    h5open(FileIO.filename(f), "w"; kwargs...) do file
        for (k, v) in dict
            isa(k, AbstractString) || throw(ArgumentError("keys must be strings (the names of variables), got $k"))
            write(file, String(k), v)
        end
    end
end
