#=
Derived from https://github.com/aparamon/HDF5Plugin-Zstandard, zstd_h5plugin.c
Licensed under Apache License Version 2.0, see licenses/H5Zzstd_LICENSE.txt

The following license applies to the Julia port.
Copyright (c) 2021 Mark Kittisopikul and Howard Hughes Medical Institute. License MIT, see LICENSE.txt
=#
module H5Zzstd

using CodecZstd
import CodecZstd.LibZstd
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filterid, filtername, filter_func, filter_cfunc

const H5Z_FILTER_ZSTD = API.H5Z_filter_t(32015)
const zstd_name = "Zstandard compression: http://www.zstd.net"

export H5Z_filter_zstd, H5Z_FILTER_ZSTD, ZstdFilter

# cd_values First optional value is the compressor aggression
#           Default is CodecZstd.LibZstd.ZSTD_CLEVEL_DEFAULT
function H5Z_filter_zstd(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    inbuf = unsafe_load(buf)
    outbuf = C_NULL
    origSize = nbytes
    ret_value = Csize_t(0)

    try
        if flags & API.H5Z_FLAG_REVERSE != 0
            #decompresssion

            decompSize = LibZstd.ZSTD_getDecompressedSize(inbuf, origSize)
            outbuf = Libc.malloc(decompSize)
            if outbuf == C_NULL
                error(
                    "zstd_h5plugin: Cannot allocate memory for outbuf during decompression."
                )
            end
            decompSize = LibZstd.ZSTD_decompress(outbuf, decompSize, inbuf, origSize)
            Libc.free(inbuf)
            unsafe_store!(buf, outbuf)
            outbuf = C_NULL
            ret_value = Csize_t(decompSize)
        else
            # compression

            if cd_nelmts > 0
                aggression = Cint(unsafe_load(cd_values))
            else
                aggression = CodecZstd.LibZstd.ZSTD_CLEVEL_DEFAULT
            end

            if aggression < 1
                aggression = 1 # ZSTD_minCLevel()
            elseif aggression > LibZstd.ZSTD_maxCLevel()
                aggression = LibZstd.ZSTD_maxCLevel()
            end

            compSize = LibZstd.ZSTD_compressBound(origSize)
            outbuf = Libc.malloc(compSize)
            if outbuf == C_NULL
                error(
                    "zstd_h5plugin: Cannot allocate memory for outbuf during compression."
                )
            end

            compSize = LibZstd.ZSTD_compress(outbuf, compSize, inbuf, origSize, aggression)

            Libc.free(unsafe_load(buf))
            unsafe_store!(buf, outbuf)
            unsafe_store!(buf_size, compSize)
            outbuf = C_NULL
            ret_value = compSize
        end
    catch e
        #  "In the case of failure, the return value is 0 (zero) and all pointer arguments are left unchanged."
        ret_value = Csize_t(0)
        @error "H5Zzstd Non-Fatal ERROR: " err
        display(stacktrace(catch_backtrace()))
    finally
        if outbuf != C_NULL
            free(outbuf)
        end
    end # try catch finally
    return Csize_t(ret_value)
end

# Filters Module

"""
    ZstdFilter(clevel)

Zstandard compression filter. `clevel` determines the compression level.

# External Links
* [Zstandard HDF5 Filter ID 32015](https://portal.hdfgroup.org/display/support/Filters#Filters-32015)
* [Zstandard HDF5 Plugin Repository (C code)](https://github.com/aparamon/HDF5Plugin-Zstandard)
"""
struct ZstdFilter <: Filter
    clevel::Cuint
end
ZstdFilter() = ZstdFilter(CodecZstd.LibZstd.ZSTD_CLEVEL_DEFAULT)

filterid(::Type{ZstdFilter}) = H5Z_FILTER_ZSTD
filtername(::Type{ZstdFilter}) = zstd_name
filter_func(::Type{ZstdFilter}) = H5Z_filter_zstd
filter_cfunc(::Type{ZstdFilter}) = @cfunction(
    H5Z_filter_zstd,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function __init__()
    register_filter(ZstdFilter)
end

end # module H5Zzstd
