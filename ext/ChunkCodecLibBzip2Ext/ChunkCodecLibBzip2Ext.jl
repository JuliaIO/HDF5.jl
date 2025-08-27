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
module ChunkCodecLibBzip2Ext

using ChunkCodecLibBzip2:
    BZ2Codec,
    BZ2EncodeOptions
using ChunkCodecLibBzip2.ChunkCodecCore:
    try_resize_decode!,
    encode_bound,
    try_encode!
using HDF5.API
import HDF5.Filters:
    Filter, filterid, register_filter, filtername, filter_func, filter_cfunc, UnsafeBuffer

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
    dst = UnsafeBuffer()
    outdatalen::Csize_t = Csize_t(0)
    try
        src = UnsafeBuffer(unsafe_load(buf), nbytes)
        if flags & API.H5Z_FLAG_REVERSE != 0
            # Decompress
            outbuflen = Int64(nbytes) * 3 + 1
            resize!(dst, outbuflen)
            outdatalen = Int64(try_resize_decode!(BZ2Codec(), dst, src, typemax(Int64)))
        else
            # Compress data
            blockSize100k = 9
            # Get compression blocksize if present
            if cd_nelmts > 0
                blockSize100k = unsafe_load(cd_values)
            end
            encoder = BZ2EncodeOptions(;blockSize100k)
            # Prepare the output buffer
            resize!(dst, encode_bound(encoder, Int64(nbytes)))
            outdatalen = Int64(try_encode!(encoder, dst, src))
        end # if flags & API.H5Z_FLAG_REVERSE != 0
        resize!(src, Int64(0))
        unsafe_store!(buf, dst.p)
        unsafe_store!(buf_size, dst.size)
    catch err
        #  "In the case of failure, the return value is 0 (zero) and all pointer arguments are left unchanged."
        outdatalen = Csize_t(0)
        resize!(dst, Int64(0))
        @error "H5Zbzip2.jl Non-Fatal ERROR: " err
        display(stacktrace(catch_backtrace()))
    end # try - catch

    return outdatalen
end # function H5Z_filter_bzip2

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

end # module CodecBzip2Ext
