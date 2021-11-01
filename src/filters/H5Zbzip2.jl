# The code below has been ported to Julia from the original C:
# https://github.com/nexusformat/HDF5-External-Filter-Plugins/blob/master/BZIP2/src/H5Zbzip2.c
# The filter function  H5Z_filter_bzip2 was adopted from
# PyTables http://www.pytables.org.
# The plugin can be used with the HDF5 library vesrion 1.8.11+ to read
# HDF5 datasets compressed with bzip2 created by PyTables.
# See H5Zbzip2_LICENSE.txt for the license.

# The following copyright and license applies to the Julia port itself.
# Copyright © 2021 Mark Kittisopikul, Howard Hughes Medical Institute
# Licensed under MIT License, see LICENSE
module H5Zbzip2

using ..API
using CodecBzip2
import CodecBzip2: libbzip2
import ..TestUtils: test_filter
import ..Filters: FILTERS, Filter, filterid

export H5Z_FILTER_BZIP2, H5Z_filter_bzip2, register_bzip2


const H5Z_FILTER_BZIP2 = API.H5Z_filter_t(307)
const bzip2_name = "HDF5 bzip2 filter; see http://www.hdfgroup.org/services/contributions.html"

function H5Z_filter_bzip2(flags::Cuint, cd_nelmts::Csize_t,
                        cd_values::Ptr{Cuint}, nbytes::Csize_t,
                        buf_size::Ptr{Csize_t}, buf::Ptr{Ptr{Cvoid}})
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
        ret = BZ2_bzBuffToBuffCompress(outbuf, r_odatalen, unsafe_load(buf), nbytes,
                                       blockSize100k, 0, 0)
        outdatalen = r_odatalen[]
        if ret != CodecBzip2.BZ_OK
            error("H5Zbzip2: bzip2 compression failed with error $ret.")
        end
    end # if flags & API.H5Z_FLAG_REVERSE != 0
    Libc.free(unsafe_load(buf))
    unsafe_store!(buf, outbuf)
    unsafe_store!(buf_size, outbuflen)

    catch err
        if outbuf != C_NULL
            Libc.free(outbuf)
        end
        rethrow(err)
        outdatalen = Csize_t(0)
    end # try - catch

    return Csize_t(outdatalen)
end # function H5Z_filter_bzip2

function register_bzip2()
    c_bzip2_filter = @cfunction(H5Z_filter_bzip2, Csize_t,
                              (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                               Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))
    API.h5z_register(API.H5Z_class_t(
        API.H5Z_CLASS_T_VERS,
        H5Z_FILTER_BZIP2,
        1,
        1,
        pointer(bzip2_name),
        C_NULL,
        C_NULL,
        c_bzip2_filter
    ))
    return nothing
end


# Need stdcall for 32-bit Windows?
function BZ2_bzBuffToBuffCompress(dest, destLen, source, sourceLen, blockSize100k, verbosity, workFactor)
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

function BZ2_bzBuffToBuffDecompress(dest, destLen, source, sourceLen, small, verbosity)
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

function test_bzip2_filter(data = ones(UInt8, 1024))
    cd_values = Cuint[8]
    test_filter(H5Z_filter_bzip2; cd_values = cd_values, data = data)
end

# Filters Module

struct Bzip2Filter <: Filter
    blockSize100k::Cuint
end
 
filterid(::Type{Bzip2Filter}) = H5Z_FILTER_BZIP2
FILTERS[H5Z_FILTER_BZIP2] = Bzip2Filter

end # module H5Zbzip2