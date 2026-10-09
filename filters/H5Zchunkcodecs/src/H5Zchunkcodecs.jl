"""
    H5Zchunkcodecs

HDF5 filters implemented with [ChunkCodecs.jl](https://github.com/JuliaIO/ChunkCodecs.jl).

This package provides alternative implementations of filters that are also provided by
other packages: Zstandard (id 32015, also implemented by `H5Zzstd`) and Bzip2 (id 307, also
implemented by `H5Zbzip2`). The data written is compatible with the other implementations.
All implementations of a filter can be loaded at the same time; see
[`HDF5.Filters.set_priority!`](@ref) and the `filter_priority` preference of HDF5.jl
for choosing which one libhdf5 uses. The provider name of this package is `:H5Zchunkcodecs`.
"""
module H5Zchunkcodecs

using ChunkCodecCore: ChunkCodecCore, encode, decode
using ChunkCodecLibZstd: ZstdCodec, ZstdEncodeOptions
using ChunkCodecLibBzip2: BZ2Codec, BZ2EncodeOptions
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export ChunkCodecZstdFilter,
    ChunkCodecBzip2Filter, H5Z_filter_chunkcodec_zstd, H5Z_filter_chunkcodec_bzip2

const H5Z_FILTER_ZSTD = API.H5Z_filter_t(32015)
const H5Z_FILTER_BZIP2 = API.H5Z_filter_t(307)
const zstd_name = "Zstandard compression: http://www.zstd.net"
const bzip2_name = "HDF5 bzip2 filter; see http://www.hdfgroup.org/services/contributions.html"

# Shared implementation of an HDF5 filter callback. `encode_fn(cd_values)` returns a
# function that compresses a `Vector{UInt8}`, `decode_fn` decompresses one.
# On failure "the return value is 0 (zero) and all pointer arguments are left unchanged."
function _chunkcodec_filter(
    name::String,
    encode_fn,
    decode_fn,
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
            decode_fn(src)
        else
            encode_fn(cd_nelmts > 0 ? unsafe_load(cd_values) : nothing, src)
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
        # Output Julia error via async so we do not task switch during callback
        @async @error "$name Non-Fatal ERROR: " exception = (e, catch_backtrace())
        return Csize_t(0)
    finally
        outbuf == C_NULL || Libc.free(outbuf)
    end
end

# cd_values: the first optional value is the compression level. Like the C plugin, it is
# stored as an unsigned integer, so negative levels are recovered by `% Cint`.
_zstd_encode(clevel, src) = encode(
    ZstdEncodeOptions(; compressionLevel=clevel === nothing ? 0 : clevel % Cint), src
)
_zstd_decode(src) = decode(ZstdCodec(), src)

function H5Z_filter_chunkcodec_zstd(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    return _chunkcodec_filter(
        "H5Zchunkcodecs zstd",
        _zstd_encode,
        _zstd_decode,
        flags,
        cd_nelmts,
        cd_values,
        nbytes,
        buf_size,
        buf
    )
end

# cd_values: the first optional value is the block size in units of 100k, 1 to 9
_bzip2_encode(blocksize, src) =
    encode(BZ2EncodeOptions(; blockSize100k=blocksize === nothing ? 9 : blocksize), src)
_bzip2_decode(src) = decode(BZ2Codec(), src)

function H5Z_filter_chunkcodec_bzip2(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    return _chunkcodec_filter(
        "H5Zchunkcodecs bzip2",
        _bzip2_encode,
        _bzip2_decode,
        flags,
        cd_nelmts,
        cd_values,
        nbytes,
        buf_size,
        buf
    )
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
    register_filter(ChunkCodecZstdFilter)
    register_filter(ChunkCodecBzip2Filter)
end

end # module H5Zchunkcodecs
