### DiskArrays.jl interface for HDF5.Dataset ###

function DiskArrays.readblock!(dset::Dataset{T,N}, aout, r::Vararg{AbstractUnitRange,N}) where {T,N}
    if N == 0
        aout[] = read(dset)
    else
        dtype = datatype(dset)
        try
            # `T` (Dataset's type parameter) is the *normalized* return type (e.g.
            # `String` for a `Cstring`-backed dataset); `generic_read` needs the raw
            # memory-compatible type (e.g. `Cstring`) to know how to lay out/interpret
            # the read buffer, and itself returns already-normalized values.
            memtype = get_jl_type(dtype)
            aout .= generic_read(dset, dtype, memtype, r...)
        finally
            close(dtype)
        end
    end
    return aout
end

function DiskArrays.writeblock!(dset::Dataset{T,N}, ain, r::Vararg{AbstractUnitRange,N}) where {T,N}
    if N == 0
        write(dset, ain[])
    else
        # DiskArrays' generic scalar-fill `setindex!` sugar can pass an `ain` smaller
        # than `length.(r)` (e.g. size (1,1,...,1) for `dset[:, :, :] = scalar`) and
        # expect it to be broadcast up to the target block size; a regularly-sized
        # `ain` is passed through unchanged (the broadcast assignment is a no-op copy).
        dims = length.(r)
        X = size(ain) == dims ? Array(ain) : (Array{T}(undef, dims) .= ain)
        _setindex!(dset, X, r...)
    end
    return ain
end

DiskArrays.haschunks(dset::Dataset) = ischunked(dset) ? DiskArrays.Chunked() : DiskArrays.Unchunked()

function DiskArrays.eachchunk(dset::Dataset)
    if ischunked(dset)
        chunk = get_chunk(dset)
        return DiskArrays.GridChunks(size(dset), chunk)
    else
        # `get_chunk`/`H5Pget_chunk` only applies to chunked storage layouts; fall back
        # to DiskArrays' own generic chunk-size estimate for contiguous/compact datasets.
        return DiskArrays.estimate_chunksize(dset)
    end
end
