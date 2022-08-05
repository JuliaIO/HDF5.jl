#==
Julia code wrapping the bitshuffle filter for HDF5. A rough translation of
bshuf_h5filter.c by Kiyoshi Masui, see
https://github.com/kiyo-masui/bitshuffle.
==#
"""
The bitshuffle filter for HDF5. See https://portal.hdfgroup.org/display/support/Filters#Filters-32008
and https://github.com/kiyo-masui/bitshuffle for details.
"""
module H5Zbitshuffle

using bitshuffle_jll

using HDF5.API
import HDF5.Filters:
    Filter,
    filterid,
    register_filter,
    filtername,
    filter_func,
    filter_cfunc,
    set_local_func,
    set_local_cfunc

export BSHUF_H5_COMPRESS_LZ4,
    BSHUF_H5_COMPRESS_ZSTD, BitshuffleFilter, H5Z_filter_bitshuffle

# From bshuf_h5filter.h

const BSHUF_H5_COMPRESS_LZ4 = 2
const BSHUF_H5_COMPRESS_ZSTD = 3
const H5Z_FILTER_BITSHUFFLE = API.H5Z_filter_t(32008)

const BSHUF_VERSION_MAJOR = 0
const BSHUF_VERSION_MINOR = 4
const BSHUF_VERSION_POINT = 2

const bitshuffle_name = "HDF5 bitshuffle filter; see https://github.com/kiyo-masui/bitshuffle"

# Set filter arguments

function bitshuffle_set_local(dcpl::API.hid_t, htype::API.hid_t, space::API.hid_t)

    # Sanity check of provided values and set element size

    bs_flags = Ref{Cuint}()
    bs_values = Vector{Cuint}(undef, 8)
    bs_nelements = Ref{Csize_t}(length(bs_values))

    API.h5p_get_filter_by_id(
        dcpl, H5Z_FILTER_BITSHUFFLE, bs_flags, bs_nelements, bs_values, 0, C_NULL, C_NULL
    )

    @debug "Initial filter info" bs_flags bs_values bs_nelements

    flags = bs_flags[]

    # set values

    bs_values[1] = BSHUF_VERSION_MAJOR
    bs_values[2] = BSHUF_VERSION_MINOR

    elem_size = API.h5t_get_size(htype)

    @debug "Element size for $htype reported as $elem_size"

    if elem_size <= 0
        return API.herr_t(-1)
    end

    bs_values[3] = elem_size
    nelements = bs_nelements[]

    # check user-supplied values

    if nelements > 3
        if bs_values[4] % 8 != 0 || bs_values[4] < 0
            return API.herr_t(-1)
        end
    end

    if nelements > 4
        if !(bs_values[5] in (0, BSHUF_H5_COMPRESS_LZ4, BSHUF_H5_COMPRESS_ZSTD))
            return API.herr_t(-1)
        end
    end

    @debug "Final values" bs_values

    API.h5p_modify_filter(dcpl, H5Z_FILTER_BITSHUFFLE, bs_flags[], nelements, bs_values)

    return API.herr_t(1)
end

function H5Z_filter_bitshuffle(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    in_buf = unsafe_load(buf)  #in_buf is *void
    out_buf = C_NULL
    nbytes_out = 0
    block_size = 0

    try    #mop up errors at end
        @debug "nelmts" cd_nelmts

        if cd_nelmts < 3
            error("bitshuffle_h5plugin: Not enough elements provided to bitshuffle filter")
        end

        # Get needed information

        major = unsafe_load(cd_values, 1)
        minor = unsafe_load(cd_values, 2)
        elem_size = unsafe_load(cd_values, 3)
        comp_lvl = unsafe_load(cd_values, 6)
        compress_flag = unsafe_load(cd_values, 5)

        if cd_nelmts > 3
            block_size = unsafe_load(cd_values, 4)
        end

        @debug "Major,minor:" major minor
        @debug "element size, compress_level, compress_flag" elem_size comp_lvl compress_flag

        if block_size == 0
            block_size = ccall(
                (:bshuf_default_block_size, libbitshuffle), Csize_t, (Csize_t,), elem_size
            )
        end

        # Work out buffer sizes

        if cd_nelmts > 4 &&
            (compress_flag in (BSHUF_H5_COMPRESS_LZ4, BSHUF_H5_COMPRESS_ZSTD))

            # Use compression

            if (flags & API.H5Z_FLAG_REVERSE) != 0 # unshuffle and decompress

                # First 8 bytes is number of uncompressed bytes
                nbytes_uncomp = ccall(
                    (:bshuf_read_uint64_BE, libbitshuffle), UInt64, (Ptr{Cvoid},), in_buf
                )
                # Next 4 bytes are the block size

                block_size =
                    ccall(
                        (:bshuf_read_uint32_BE, libbitshuffle),
                        UInt32,
                        (Ptr{Cvoid},),
                        in_buf + 8
                    ) ÷ elem_size

                in_buf += 12
                buf_size_out = nbytes_uncomp

            else #shuffle and compress
                nbytes_uncomp = nbytes
                if compress_flag == BSHUF_H5_COMPRESS_LZ4
                    buf_size_out =
                        ccall(
                            (:bshuf_compress_lz4_bound, libbitshuffle),
                            Csize_t,
                            (Csize_t, Csize_t, Csize_t),
                            nbytes_uncomp ÷ elem_size,
                            elem_size,
                            block_size
                        ) + 12
                elseif compress_flag == BSHUF_H5_COMPRESS_ZSTD
                    buf_size_out =
                        ccall(
                            (:bshuf_compress_zstd_bound, libbitshuffle),
                            Csize_t,
                            (Csize_t, Csize_t, Csize_t),
                            nbytes_uncomp ÷ elem_size,
                            elem_size,
                            block_size
                        ) + 12
                end
            end

        else  # No compression required
            nbytes_uncomp = nbytes
            buf_size_out = nbytes
        end

        if nbytes_uncomp % elem_size != 0
            error(
                "bitshuffle_h5plugin: Uncompressed size $nbytes_uncomp is not a multiple of $elem_size"
            )
        end

        size = nbytes_uncomp ÷ elem_size
        out_buf = Libc.malloc(buf_size_out)
        if out_buf == C_NULL
            error(
                "bitshuffle_h5plugin: Cannot allocate memory for outbuf during decompression"
            )
        end

        # Now perform the decompression

        if cd_nelmts > 4 &&
            (compress_flag in (BSHUF_H5_COMPRESS_LZ4, BSHUF_H5_COMPRESS_ZSTD))
            if flags & API.H5Z_FLAG_REVERSE != 0 #unshuffle and decompress
                if compress_flag == BSHUF_H5_COMPRESS_LZ4
                    err = ccall(
                        (:bshuf_decompress_lz4, libbitshuffle),
                        Int64,
                        (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Csize_t, Csize_t),
                        in_buf,
                        out_buf,
                        size,
                        elem_size,
                        block_size
                    )
                elseif compress_flag == BSHUF_H5_COMPRESS_ZSTD
                    err = ccall(
                        (:bshuf_decompress_zstd, libbitshuffle),
                        Int64,
                        (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Csize_t, Csize_t),
                        in_buf,
                        out_buf,
                        size,
                        elem_size,
                        block_size
                    )
                end
                nbytes_out = nbytes_uncomp

            else  #shuffle and compress
                ccall(
                    (:bshuf_write_uint64_BE, libbitshuffle),
                    Cvoid,
                    (Ptr{Cvoid}, UInt64),
                    out_buf,
                    nbytes_uncomp
                )
                ccall(
                    (:bshuf_write_uint32_BE, libbitshuffle),
                    Cvoid,
                    (Ptr{Cvoid}, UInt32),
                    out_buf + 8,
                    block_size * elem_size
                )

                if compress_flag == BSHUF_H5_COMPRESS_LZ4
                    err = ccall(
                        (:bshuf_compress_lz4, libbitshuffle),
                        Int64,
                        (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Csize_t, Csize_t),
                        in_buf,
                        out_buf + 12,
                        size,
                        elem_size,
                        block_size
                    )
                else
                    err = ccall(
                        (:bshuf_compress_zstd, libbitshuffle),
                        Int64,
                        (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Csize_t, Csize_t),
                        in_buf,
                        out_buf + 12,
                        size,
                        elem_size,
                        block_size
                    )
                end

                nbytes_out = err + 12
            end
        else # just the shuffle thanks
            if flags & API.H5Z_FLAG_REVERSE != 0
                err = ccall(
                    (:bshuf_bitunshuffle, libbitshuffle),
                    Int64,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Csize_t, Csize_t),
                    in_buf,
                    out_buf,
                    size,
                    elem_size,
                    block_size
                )
            else
                err = ccall(
                    (:bshuf_bitshuffle, libbitshuffle),
                    Int64,
                    (Ptr{Cvoid}, Ptr{Cvoid}, Csize_t, Csize_t, Csize_t),
                    in_buf,
                    out_buf,
                    size,
                    elem_size,
                    block_size
                )
            end

            nbytes_out = nbytes
        end

        # And wrap it up

        if err < 0
            error("h5plugin_bitshuffle: Error in bitshuffle with code $err")
        end

        Libc.free(unsafe_load(buf))
        unsafe_store!(buf, out_buf)
        unsafe_store!(buf_size, Csize_t(buf_size_out))
        out_buf = C_NULL

    catch e

        # On failure, return 0 and change no arguments

        nbytes_out = Csize_t(0)
        @error "Non-fatal H5 bitshuffle plugin error: " e
        display(stacktrace(catch_backtrace()))

    finally
        if out_buf != C_NULL
            Libc.free(out_buf)
        end
    end

    return Csize_t(nbytes_out)
end

# Filter registration

# All information for the filter

struct BitshuffleFilter <: Filter
    major::Cuint
    minor::Cuint
    typesize::Cuint
    blocksize::Cuint
    compression::Cuint
    comp_level::Cuint #Zstd only
end

"""
    BitshuffleFilter(blocksize=0,compressor=:none,comp_level=0)

The Bitshuffle filter can optionally include compression :lz4 or :zstd. For :zstd
comp_level can be provided. This is ignored for :lz4 compression. If `blocksize`
is zero the default bitshuffle blocksize is used.
"""
function BitshuffleFilter(; blocksize=0, compressor=:none, comp_level=0)
    compressor in (:lz4, :zstd, :none) ||
        throw(ArgumentError("Invalid bitshuffle compression $compressor"))
    compcode = 0
    if compressor == :lz4
        compcode = BSHUF_H5_COMPRESS_LZ4
    elseif compressor == :zstd
        compcode = BSHUF_H5_COMPRESS_ZSTD
    end
    BitshuffleFilter(
        BSHUF_VERSION_MAJOR, BSHUF_VERSION_MINOR, 0, blocksize, compcode, comp_level
    )
end

filterid(::Type{BitshuffleFilter}) = H5Z_FILTER_BITSHUFFLE
filtername(::Type{BitshuffleFilter}) = bitshuffle_name
set_local_func(::Type{BitshuffleFilter}) = bitshuffle_set_local
set_local_cfunc(::Type{BitshuffleFilter}) =
    @cfunction(bitshuffle_set_local, API.herr_t, (API.hid_t, API.hid_t, API.hid_t))
filterfunc(::Type{BitshuffleFilter}) = H5Z_filter_bitshuffle
filter_cfunc(::Type{BitshuffleFilter}) = @cfunction(
    H5Z_filter_bitshuffle,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function __init__()
    register_filter(BitshuffleFilter)
end

end # module
