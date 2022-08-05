"""
    module FilterTestUtils

This module contains utilities for evaluating and debugging HDF5 Filters.
"""
module FilterTestUtils

import HDF5.API
import H5Zlz4: H5Z_filter_lz4
import H5Zzstd: H5Z_filter_zstd
import H5Zbzip2: H5Z_filter_bzip2
using Test

export test_filter

function test_filter_init(; cd_values=Cuint[], data=ones(UInt8, 1024))
    flags = Cuint(0)
    nbytes = sizeof(data)
    buf_size = Ref(Csize_t(sizeof(data)))
    databuf = Libc.malloc(sizeof(data))
    data = reinterpret(UInt8, data)
    unsafe_copyto!(Ptr{UInt8}(databuf), pointer(data), sizeof(data))
    buf = Ref(Ptr{Cvoid}(databuf))
    return flags, cd_values, nbytes, buf_size, buf
end

function test_filter_compress!(
    filter_func,
    flags::Cuint,
    cd_values::Vector{Cuint},
    nbytes::Integer,
    buf_size::Ref{Csize_t},
    buf::Ref{Ptr{Cvoid}}
)
    nbytes = Csize_t(nbytes)
    cd_nelmts = Csize_t(length(cd_values))
    GC.@preserve flags cd_nelmts cd_values nbytes buf_size buf begin
        ret_code = filter_func(
            flags,
            cd_nelmts,
            pointer(cd_values),
            Csize_t(nbytes),
            Base.unsafe_convert(Ptr{Csize_t}, buf_size),
            Base.unsafe_convert(Ptr{Ptr{Cvoid}}, buf)
        )
        @debug "Compression:" ret_code buf_size[]
        if ret_code <= 0
            error("Test compression failed: $ret_code.")
        end
    end
    return ret_code
end

function test_filter_decompress!(
    filter_func,
    flags::Cuint,
    cd_values::Vector{Cuint},
    nbytes::Integer,
    buf_size::Ref{Csize_t},
    buf::Ref{Ptr{Cvoid}}
)
    nbytes = Csize_t(nbytes)
    cd_nelmts = Csize_t(length(cd_values))
    flags |= UInt32(API.H5Z_FLAG_REVERSE)
    GC.@preserve flags cd_nelmts cd_values nbytes buf_size buf begin
        ret_code = filter_func(
            flags,
            cd_nelmts,
            pointer(cd_values),
            Csize_t(nbytes),
            Base.unsafe_convert(Ptr{Csize_t}, buf_size),
            Base.unsafe_convert(Ptr{Ptr{Cvoid}}, buf)
        )
        @debug "Decompression:" ret_code buf_size[]
    end
    return ret_code
end

function test_filter_cleanup!(buf::Ref{Ptr{Cvoid}})
    Libc.free(buf[])
end

function test_filter(filter_func; cd_values::Vector{Cuint}=Cuint[], data=ones(UInt8, 1024))
    flags, cd_values, nbytes, buf_size, buf = test_filter_init(;
        cd_values=cd_values, data=data
    )
    nbytes_compressed, nbytes_decompressed = 0, 0
    try
        nbytes_compressed = test_filter_compress!(
            filter_func, flags, cd_values, nbytes, buf_size, buf
        )
        nbytes_decompressed = test_filter_decompress!(
            filter_func, flags, cd_values, nbytes_compressed, buf_size, buf
        )
        if nbytes_decompressed > 0
            # ret_code is the number of bytes out
            round_trip_data = unsafe_wrap(Array, Ptr{UInt8}(buf[]), nbytes_decompressed)
            @debug "Is the data the same after a roundtrip?" data == round_trip_data
        end
    catch err
        rethrow(err)
    finally
        test_filter_cleanup!(buf)
    end
    @debug "Compression Ratio" nbytes_compressed / nbytes_decompressed
    return nbytes_compressed, nbytes_decompressed
end

function test_bzip2_filter(data=ones(UInt8, 1024))
    cd_values = Cuint[8]
    test_filter(H5Z_filter_bzip2; cd_values=cd_values, data=data)
end

function test_lz4_filter(data=ones(UInt8, 1024))
    cd_values = Cuint[1024]
    test_filter(H5Z_filter_lz4; cd_values=cd_values, data=data)
end

function test_zstd_filter(data=ones(UInt8, 1024))
    cd_values = Cuint[3] # aggression
    test_filter(H5Z_filter_zstd; cd_values=cd_values, data=data)
end

function __init__()
    @testset "Compression Filter Unit Tests" begin
        @test argmin(test_bzip2_filter()) == 1
        @test argmin(test_lz4_filter()) == 1
        @test argmin(test_zstd_filter()) == 1
        str = codeunits(repeat("foobar", 1000))
        @test argmin(test_bzip2_filter(str)) == 1
        @test argmin(test_lz4_filter(str)) == 1
        @test argmin(test_zstd_filter(str)) == 1
    end
end

end
