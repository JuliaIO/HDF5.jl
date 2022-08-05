#=
This is a port of H5Zlz4.c to Julia
https://github.com/HDFGroup/hdf5_plugins/blob/master/LZ4/src/H5Zlz4.c
https://github.com/nexusformat/HDF5-External-Filter-Plugins/blob/master/LZ4/src/H5Zlz4.c
https://github.com/silx-kit/hdf5plugin/blob/main/src/LZ4/H5Zlz4.c

H5Zlz4 is originally a copyright of HDF Group. License: licenses/H5Zlz4_LICENSE.txt

The following license applies to the Julia port.
Copyright (c) 2021 Mark Kittisopikul and Howard Hughes Medical Institute. License MIT, see LICENSE.txt
=#
module H5Zlz4

using CodecLz4
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

export H5Z_FILTER_LZ4, H5Z_filter_lz4, Lz4Filter

const H5Z_FILTER_LZ4 = API.H5Z_filter_t(32004)

const DEFAULT_BLOCK_SIZE = 1 << 30
const lz4_name = "HDF5 lz4 filter; see http://www.hdfgroup.org/services/contributions.html"

const LZ4_AGGRESSION = Ref(1)

# flags H5Z_FLAG_REVERSE or H5Z_FLAG_OPTIONAL
# cd_nelmts number of elements in cd_values (0 or 1)
# cd_values the first optional element must be the blockSize
# nbytes - number of valid bytes of data
# buf_size - total size of buffer
# buf - pointer to pointer of data
function H5Z_filter_lz4(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    outBuf = C_NULL
    ret_value = Csize_t(0)

    try
        if (flags & API.H5Z_FLAG_REVERSE) != 0 # reverse filter, decompressing
            #i32Buf = Ref{UInt32}()
            blockSize = UInt32(0)
            roBuf = Ref{UInt8}()
            rpos = Ptr{UInt8}(unsafe_load(buf))
            #i64Buf = Ptr{UInt64}(rpos)
            # Load the first 8 bytes from buffer as a big endian UInt64
            # This is the original size of the buffer
            origSize = ntoh(unsafe_load(Ptr{UInt64}(rpos)))
            rpos += 8 # advance the pointer

            # Next read the next four bytes from the buffer as a big endian UInt32
            # This is the blocksize
            #i32Buf[] = rpos
            blockSize = ntoh(unsafe_load(Ptr{UInt32}(rpos)))
            rpos += 4
            if blockSize > origSize
                blockSize = origSize
            end

            # malloc a byte buffer of origSize
            # outBuf = Vector{UInt8}(undef, origSize)
            @debug "OrigSize" origSize
            outBuf = Libc.malloc(origSize)
            # Julia should throw an error if it cannot allocate this
            roBuf = Ptr{UInt8}(outBuf)
            decompSize = 0
            # Start with the first blockSize
            while decompSize < origSize
                # compressedBlockSize = UInt32(0)
                if origSize - decompSize < blockSize # the last block can be smaller than block size
                    blockSize = origSize - decompSize
                end

                #i32Buf[] = rpos
                compressedBlockSize = ntoh(unsafe_load(Ptr{UInt32}(rpos)))
                rpos += 4

                if compressedBlockSize == blockSize
                    # There was no compression
                    # memcpy(roBuf, rpos, blockSize)
                    unsafe_copyto!(roBuf, rpos, blockSize)
                    decompressedBytes = blockSize
                else
                    # do the compression
                    # LZ4_decompress_fast, version number 10300 ?
                    @debug "decompress_safe" rpos roBuf compressedBlockSize (
                        origSize - decompSize
                    )
                    decompressedBytes = CodecLz4.LZ4_decompress_safe(
                        rpos, roBuf, compressedBlockSize, origSize - decompSize
                    )
                    @debug "decompressedBytes" decompressedBytes
                end

                rpos += compressedBlockSize
                roBuf += blockSize
                decompSize += decompressedBytes
            end
            Libc.free(unsafe_load(buf))
            unsafe_store!(buf, outBuf)
            outBuf = C_NULL
            ret_value = Csize_t(origSize)
        else
            # forward filter
            # compressing
            #i64Buf = Ref{UInt64}()
            #i32Buf = Ref{UInt32}()

            if nbytes > typemax(Int32)
                error("Can only compress chunks up to 2GB")
            end
            blockSize = unsafe_load(cd_values)
            if cd_nelmts > 0 && blockSize > 0
            else
                blockSize = DEFAULT_BLOCK_SIZE
            end
            if blockSize > nbytes
                blockSize = nbytes
            end
            nBlocks = (nbytes - 1) ÷ blockSize + 1
            maxDestSize =
                nBlocks * CodecLz4.LZ4_compressBound(blockSize) + 4 + 8 + nBlocks * 4
            outBuf = Libc.malloc(maxDestSize)

            rpos = Ptr{UInt8}(unsafe_load(buf))
            roBuf = Ptr{UInt8}(outBuf)

            # Header
            unsafe_store!(Ptr{UInt64}(roBuf), hton(UInt64(nbytes)))
            roBuf += 8

            unsafe_store!(Ptr{UInt32}(roBuf), hton(UInt32(blockSize)))
            roBuf += 4

            outSize = 12

            for block in 0:(nBlocks - 1)
                # compBlockSize::UInt32
                origWritten = Csize_t(block * blockSize)
                if nbytes - origWritten < blockSize # the last block may be < blockSize
                    blockSize = nbytes - origWritten
                end

                # aggression = 1 is the same LZ4_compress_default
                @debug "LZ4_compress_fast args" rpos outBuf roBuf roBuf + 4 blockSize nBlocks CodecLz4.LZ4_compressBound(
                    blockSize
                )
                compBlockSize = UInt32(
                    CodecLz4.LZ4_compress_fast(
                        rpos,
                        roBuf + 4,
                        blockSize,
                        CodecLz4.LZ4_compressBound(blockSize),
                        LZ4_AGGRESSION[]
                    )
                )
                @debug "Compressed block size" compBlockSize

                if compBlockSize == 0
                    error("Could not compress block $block")
                end

                if compBlockSize >= blockSize # compression did not save any space, do a memcpy instead
                    compBlockSize = blockSize
                    unsafe_copyto!(roBuf + 4, rpos, blockSize)
                end

                unsafe_store!(Ptr{UInt32}(roBuf), hton(UInt32(compBlockSize))) # write blocksize
                roBuf += 4

                rpos += blockSize
                roBuf += compBlockSize
                outSize += compBlockSize + 4
            end

            Libc.free(unsafe_load(buf))
            unsafe_store!(buf, outBuf)
            unsafe_store!(buf_size, outSize)
            outBuf = C_NULL
            ret_value = Csize_t(outSize)
        end # (flags & API.H5Z_FLAG_REVERSE) != 0

    catch err
        #  "In the case of failure, the return value is 0 (zero) and all pointer arguments are left unchanged."
        ret_value = Csize_t(0)
        @error "H5Zlz4.jl Non-Fatal ERROR: " err
        display(stacktrace(catch_backtrace()))
    finally
        if outBuf != C_NULL
            Libc.free(outBuf)
        end
    end
    return Csize_t(ret_value)
end

# Filters Module

"""
    Lz4Filter(blockSize)

Apply LZ4 compression. `blockSize` is the main argument. The filter id is $H5Z_FILTER_LZ4.

# External Links
* [LZ4 HDF5 Filter ID 32004](https://portal.hdfgroup.org/display/support/Filters#Filters-32004)
* [LZ4 HDF5 Plugin Repository (C code)](https://github.com/nexusformat/HDF5-External-Filter-Plugins/tree/master/LZ4)
"""
struct Lz4Filter <: Filter
    blockSize::Cuint
end
Lz4Filter() = Lz4Filter(DEFAULT_BLOCK_SIZE)

filterid(::Type{Lz4Filter}) = H5Z_FILTER_LZ4
filtername(::Type{Lz4Filter}) = lz4_name
filter_func(::Type{Lz4Filter}) = H5Z_filter_lz4
filter_cfunc(::Type{Lz4Filter}) = @cfunction(
    H5Z_filter_lz4,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function __init__()
    register_filter(Lz4Filter)
end

end
