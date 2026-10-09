"""
    H5ZChunkCodecBzip2

The Bzip2 HDF5 filter (id 307) implemented with
[ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl).

This is an alternative to `H5Zbzip2`. The data written is compatible with that package, and
both can be loaded at the same time; see [`HDF5.Filters.set_priority!`](@ref) and the
`filter_priority` preference of HDF5.jl for choosing which one libhdf5 uses.
The provider name of this package is `:H5ZChunkCodecBzip2`.
"""
module H5ZChunkCodecBzip2

using ChunkCodecCore: encode, decode
using ChunkCodecLibBzip2: BZ2Codec, BZ2EncodeOptions
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export ChunkCodecBzip2Filter, H5Z_filter_chunkcodec_bzip2

const H5Z_FILTER_BZIP2 = API.H5Z_filter_t(307)
const bzip2_name = "HDF5 bzip2 filter; see http://www.hdfgroup.org/services/contributions.html"

# cd_values: the first optional value is the block size in units of 100k, 1 to 9
function H5Z_filter_chunkcodec_bzip2(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    outbuf = Ptr{Cvoid}(C_NULL)
    try
        inbuf = unsafe_load(buf)
        # `nbytes` is the number of valid bytes in the buffer, which may be smaller
        # than the allocation `buf_size`.
        src = unsafe_wrap(Array, Ptr{UInt8}(inbuf), Int(nbytes); own=false)
        out = if flags & API.H5Z_FLAG_REVERSE != 0
            decode(BZ2Codec(), src)
        else
            blocksize = cd_nelmts > 0 ? unsafe_load(cd_values) : 9
            encode(BZ2EncodeOptions(; blockSize100k=blocksize), src)
        end::Vector{UInt8}
        n = length(out)
        outbuf = Libc.malloc(max(n, 1))
        outbuf == C_NULL && throw(OutOfMemoryError())
        GC.@preserve out unsafe_copyto!(Ptr{UInt8}(outbuf), pointer(out), n)
        Libc.free(inbuf)
        unsafe_store!(buf, outbuf)
        unsafe_store!(buf_size, max(n, 1))
        outbuf = C_NULL
        return Csize_t(n)
    catch e
        # "In the case of failure, the return value is 0 (zero) and all pointer
        # arguments are left unchanged." Output the error via async so we do not
        # task switch during the callback.
        @async @error "H5ZChunkCodecBzip2 Non-Fatal ERROR: " exception = (
            e, catch_backtrace()
        )
        return Csize_t(0)
    finally
        outbuf == C_NULL || Libc.free(outbuf)
    end
end

"""
    ChunkCodecBzip2Filter(blockSize100k)

Bzip2 compression filter (filter id 307) implemented with ChunkCodecLibBzip2.
Uses the same `cd_values` as `H5Zbzip2.Bzip2Filter`, so data is interchangeable.
"""
struct ChunkCodecBzip2Filter <: Filter
    blockSize100k::Cuint
end
ChunkCodecBzip2Filter() = ChunkCodecBzip2Filter(9)

filterid(::Type{ChunkCodecBzip2Filter}) = H5Z_FILTER_BZIP2
filtername(::Type{ChunkCodecBzip2Filter}) = bzip2_name
filter_func(::Type{ChunkCodecBzip2Filter}) = H5Z_filter_chunkcodec_bzip2
filter_cfunc(::Type{ChunkCodecBzip2Filter}) = @cfunction(
    H5Z_filter_chunkcodec_bzip2,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function __init__()
    register_filter(ChunkCodecBzip2Filter)
end

end # module H5ZChunkCodecBzip2
