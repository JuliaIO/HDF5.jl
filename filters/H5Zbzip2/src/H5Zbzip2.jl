#=
The code below has been ported to Julia from the original C source:
https://github.com/nexusformat/HDF5-External-Filter-Plugins/blob/master/BZIP2/src/H5Zbzip2.c
The filter function  H5Z_filter_bzip2 was adopted from:
PyTables http://www.pytables.org.
The plugin can be used with the HDF5 library version 1.8.11+ to read HDF5 datasets compressed with bzip2 created by PyTables.
License: licenses/H5Zbzip2_LICENSE.txt

The following license applies to the Julia port.
Copyright (c) 2021 Mark Kittisopikul and Howard Hughes Medical Institute. License MIT, see LICENSE.txt
=#
module H5Zbzip2

using CodecBzip2
import CodecBzip2: libbzip2
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export H5Z_FILTER_BZIP2, H5Z_filter_bzip2, Bzip2Filter

const H5Z_FILTER_BZIP2 = API.H5Z_filter_t(307)
const bzip2_name = "HDF5 bzip2 filter; see http://www.hdfgroup.org/services/contributions.html"

function H5Z_filter_bzip2(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    outbuf = C_NULL
    outdatalen = Cuint(0)

    # Prepare the output buffer

    try
        if flags & API.H5Z_FLAG_REVERSE != 0
            # Decompress

            outbuflen = nbytes * 3 + 1
            outbuf = Libc.malloc(outbuflen)
            if outbuf == C_NULL
                error("H5Zbzip2: memory allocation failed for bzip2 decompression.")
            end

            stream = CodecBzip2.BZStream()
            # Just use default malloc and free
            stream.bzalloc = C_NULL
            stream.bzfree = C_NULL
            # BZ2_bzDecompressInit
            ret = CodecBzip2.decompress_init!(stream, 0, false)
            if ret != CodecBzip2.BZ_OK
                errror("H5Zbzip2: bzip2 decompress start failed with error $ret.")
            end

            stream.next_out = outbuf
            stream.avail_out = outbuflen
            stream.next_in = unsafe_load(buf)
            stream.avail_in = nbytes

            cont = true

            while cont
                # BZ2_bzDecompress
                ret = CodecBzip2.decompress!(stream)
                if ret < 0
                    error("H5Zbzip2: bzip2 decompression failed with error $ret.")
                end
                cont = ret != CodecBzip2.BZ_STREAM_END
                if cont && stream.avail_out == 0
                    # Grow the output buffer
                    newbuflen = outbuflen * 2
                    newbuf = Libc.realloc(outbuf, newbuflen)
                    if newbuf == C_NULL
                        error("H5Zbzip2: memory allocation failed for bzip2 decompression.")
                    end
                    stream.next_out = newbuf + outbuflen
                    stream.avail_out = outbuflen
                    outbuf = newbuf
                    outbuflen = newbuflen
                end
            end

            outdatalen = stream.total_out_lo32
            # BZ2_bzDecompressEnd
            ret = CodecBzip2.decompress_end!(stream)
            if ret != CodecBzip2.BZ_OK
                error("H5Zbzip2: bzip2 compression end failed with error $ret.")
            end
        else
            # Compress data

            # Maybe not the same size as outdatalen
            odatalen = Cuint(0)
            blockSize100k = 9

            # Get compression blocksize if present
            if cd_nelmts > 0
                blockSize100k = unsafe_load(cd_values)
                if blockSize100k < 1 || blockSize100k > 9
                    error("H5Zbzip2: Invalid compression blocksize: $blockSize100k")
                end
            end

            # Prepare the output buffer
            outbuflen = nbytes + nbytes ÷ 100 + 600 # worse case (bzip2 docs)
            outbuf = Libc.malloc(outbuflen)
            @debug "Allocated" outbuflen outbuf
            if outbuf == C_NULL
                error("H5Zbzip2: Memory allocation failed for bzip2 compression")
            end

            # Compress data
            odatalen = outbuflen
            r_odatalen = Ref{Cuint}(odatalen)
            ret = BZ2_bzBuffToBuffCompress(
                outbuf, r_odatalen, unsafe_load(buf), nbytes, blockSize100k, 0, 0
            )
            outdatalen = r_odatalen[]
            if ret != CodecBzip2.BZ_OK
                error("H5Zbzip2: bzip2 compression failed with error $ret.")
            end
        end # if flags & API.H5Z_FLAG_REVERSE != 0
        Libc.free(unsafe_load(buf))
        unsafe_store!(buf, outbuf)
        unsafe_store!(buf_size, outbuflen)

    catch err
        #  "In the case of failure, the return value is 0 (zero) and all pointer arguments are left unchanged."
        outdatalen = Csize_t(0)
        if outbuf != C_NULL
            Libc.free(outbuf)
        end
        @error "H5Zbzip2.jl Non-Fatal ERROR: " err
        display(stacktrace(catch_backtrace()))
    end # try - catch

    return Csize_t(outdatalen)
end # function H5Z_filter_bzip2

# Need stdcall for 32-bit Windows?
function BZ2_bzBuffToBuffCompress(
    dest, destLen, source, sourceLen, blockSize100k, verbosity, workFactor
)
    @static if CodecBzip2.WIN32
        return ccall(
            ("BZ2_bzBuffToBuffCompress@28", libbzip2),
            stdcall,
            Cint,
            (Ptr{Cchar}, Ptr{Cuint}, Ptr{Cchar}, Cuint, Cint, Cint, Cint),
            dest,
            destLen,
            source,
            sourceLen,
            blockSize100k,
            verbosity,
            workFactor
        )
    else
        return ccall(
            (:BZ2_bzBuffToBuffCompress, libbzip2),
            Cint,
            (Ptr{Cchar}, Ptr{Cuint}, Ptr{Cchar}, Cuint, Cint, Cint, Cint),
            dest,
            destLen,
            source,
            sourceLen,
            blockSize100k,
            verbosity,
            workFactor
        )
    end
end

function BZ2_bzBuffToBuffDecompress(dest, destLen, source, sourceLen, small, verbosity)
    @static if CodecBzip2.WIN32
        return ccall(
            ("BZ2_bzBuffToBuffDecompress@24", libbzip2),
            stdcall,
            Cint,
            (Ptr{Cchar}, Ptr{Cuint}, Ptr{Cchar}, Cuint, Cint, Cint),
            dest,
            destLen,
            source,
            sourceLen,
            small,
            verbosity
        )
    else
        return ccall(
            (:BZ2_bzBuffToBuffDecompress, libbzip2),
            Cint,
            (Ptr{Cchar}, Ptr{Cuint}, Ptr{Cchar}, Cuint, Cint, Cint),
            dest,
            destLen,
            source,
            sourceLen,
            small,
            verbosity
        )
    end
end

# Filters Module

"""
    Bzip2Filter(blockSize100k)

Apply Bzip2 compression. The filter id is $H5Z_FILTER_BZIP2.

# External Links
* [BZIP2 HDF5 Filter ID 307](https://portal.hdfgroup.org/display/support/Filters#Filters-307)
* [PyTables Repository (C code)](https://github.com/PyTables/PyTables)
"""
struct Bzip2Filter <: Filter
    blockSize100k::Cuint
end
Bzip2Filter() = Bzip2Filter(9)

filterid(::Type{Bzip2Filter}) = H5Z_FILTER_BZIP2
filtername(::Type{Bzip2Filter}) = bzip2_name
filter_func(::Type{Bzip2Filter}) = H5Z_filter_bzip2
filter_cfunc(::Type{Bzip2Filter}) = @cfunction(
    H5Z_filter_bzip2,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function __init__()
    register_filter(Bzip2Filter)
end

end # module H5Zbzip2
