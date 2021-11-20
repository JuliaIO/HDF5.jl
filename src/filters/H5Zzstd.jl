#=
Derived from https://github.com/aparamon/HDF5Plugin-Zstandard, zstd_h5plugin.c
Originally licensed under Apache License Version 2.0
See H5Zzstd_LICENSE.txt

The following copyright and license applies to the Julia port itself.
Copyright © 2021 Mark Kittisopikul and Howard Hughes Medical Institute
Licensed under MIT License, see LICENSE.txt
=#
module H5Zzstd

using ..API
using CodecZstd
import CodecZstd.LibZstd
import ..Filters: FILTERS, Filter, filterid, register_filter, FilterPipeline
import ..Filters: filterid, filtername, encoder_present, decoder_present
import ..Filters: set_local_func, set_local_cfunc, can_apply_func, can_apply_cfunc, filter_func, filter_cfunc


const H5Z_FILTER_ZSTD = API.H5Z_filter_t(32015)
const zstd_name = "Zstandard compression: http://www.zstd.net"

export H5Z_filter_zstd, H5Z_FILTER_ZSTD, ZstdFilter 

# cd_values First optional value is the compressor aggression
#           Default is CodecZstd.LibZstd.ZSTD_CLEVEL_DEFAULT
function H5Z_filter_zstd(flags::Cuint, cd_nelmts::Csize_t,
                        cd_values::Ptr{Cuint}, nbytes::Csize_t,
                        buf_size::Ptr{Csize_t}, buf::Ptr{Ptr{Cvoid}})::Csize_t
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
            error("zstd_h5plugin: Cannot allocate memory for outbuf during decompression.")
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
            error("zstd_h5plugin: Cannot allocate memory for outbuf during compression.")
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

function register_zstd()
    c_zstd_filter = @cfunction(H5Z_filter_zstd, Csize_t,
                              (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                               Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))
    API.h5z_register(API.H5Z_class_t(
        API.H5Z_CLASS_T_VERS,
        H5Z_FILTER_ZSTD,
        1,
        1,
        pointer(zstd_name),
        C_NULL,
        C_NULL,
        c_zstd_filter
    ))
    FILTERS[H5Z_FILTER_ZSTD] = ZstdFilter
    return nothing
end

# Filters Module

struct ZstdFilter <: Filter
    clevel::Cuint
end
ZstdFilter() = ZstdFilter(CodecZstd.LibZstd.ZSTD_CLEVEL_DEFAULT)
 
filterid(::Type{ZstdFilter}) = H5Z_FILTER_ZSTD
filtername(::Type{ZstdFilter}) = zstd_name
filter_func(::Type{ZstdFilter}) = H5Z_filter_zstd
filter_cfunc(::Type{ZstdFilter}) = @cfunction(H5Z_filter_zstd, Csize_t,
                                             (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                                             Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))
register_filter(::Type{ZstdFilter}) = register_zstd()
register_filter(::ZstdFilter) = register_zstd()

precompile(register_filter, (ZstdFilter,))
precompile(register_filter, (Type{ZstdFilter},))

end # module H5Zzstd