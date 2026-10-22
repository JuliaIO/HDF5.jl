"""
    H5ZChunkCodecZstd

The Zstandard HDF5 filter (id 32015) implemented with
[ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl).

This is an alternative to `H5Zzstd`. The data written is compatible with that package, and
both can be loaded at the same time; see [`HDF5.Filters.set_priority!`](@ref) and the
`filter_priority` preference of HDF5.jl for choosing which one libhdf5 uses.
The provider name of this package is `:H5ZChunkCodecZstd`.
"""
module H5ZChunkCodecZstd

using ChunkCodecCore: encode, decode
using ChunkCodecLibZstd: ZstdCodec, ZstdEncodeOptions
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export ChunkCodecZstdFilter, H5Z_filter_chunkcodec_zstd

const H5Z_FILTER_ZSTD = API.H5Z_filter_t(32015)
const zstd_name = "Zstandard compression: http://www.zstd.net"

# cd_values: the first optional value is the compression level. Like the C plugin, it is
# stored as an unsigned integer, so negative levels are recovered by `% Cint`.
function H5Z_filter_chunkcodec_zstd(
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
            decode(ZstdCodec(), src)
        else
            clevel = cd_nelmts > 0 ? unsafe_load(cd_values) % Cint : 0 # 0 is the default
            encode(ZstdEncodeOptions(; compressionLevel=clevel), src)
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
        @async @error "H5ZChunkCodecZstd Non-Fatal ERROR: " exception = (
            e, catch_backtrace()
        )
        return Csize_t(0)
    finally
        outbuf == C_NULL || Libc.free(outbuf)
    end
end

"""
    ChunkCodecZstdFilter(clevel)

Zstandard compression filter (filter id 32015) implemented with ChunkCodecLibZstd.
Uses the same `cd_values` as `H5Zzstd.ZstdFilter`, so data is interchangeable.
`clevel` is the compression level; negative levels are faster at the cost of compression.
"""
struct ChunkCodecZstdFilter <: Filter
    clevel::Cuint
    ChunkCodecZstdFilter(clevel::Integer) = new(clevel % Cuint)
end
ChunkCodecZstdFilter() = ChunkCodecZstdFilter(3)
Base.show(io::IO, f::ChunkCodecZstdFilter) =
    print(io, "ChunkCodecZstdFilter(", f.clevel % Cint, ")")

filterid(::Type{ChunkCodecZstdFilter}) = H5Z_FILTER_ZSTD
filtername(::Type{ChunkCodecZstdFilter}) = zstd_name
filter_func(::Type{ChunkCodecZstdFilter}) = H5Z_filter_chunkcodec_zstd
filter_cfunc(::Type{ChunkCodecZstdFilter}) = @cfunction(
    H5Z_filter_chunkcodec_zstd,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function __init__()
    register_filter(ChunkCodecZstdFilter)
end

end # module H5ZChunkCodecZstd
