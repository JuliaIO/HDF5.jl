#==

Julia code wrapping the bitshuffle filter for HDF5. A rough translation of
bshuf_h5filter.c by Kiyoshi Masui, see
https://github.com/kiyo-masui/bitshuffle.

==#
module H5Zbitshuffle

using bitshuffle_jll

using HDF5.API
import HDF5.Filters: Filter, filterid, register_filter, filtername, filter_func, filter_cfunc

const H5Z_FILTER_BITSHUFFLE = API.H5Z_filter_t(32008)

# From bshuf_h5filter.h

const BSHUF_H5_COMPRESS_LZ4 = 2
const BSHUF_H5_COMPRESS_ZSTD = 3

const bitshuffle_name = "HDF5 bitshuffle filter; see http://www.hdfgroup.org/services/contributions.html"

function H5Z_filter_bitshuffle(flags::Cuint, cd_nelmts::Csize_t,
                               cd_values::Ptr{Cuint}, nbytes::Csize_t,
                               buf_size::Ptr{Csize_t}, buf::Ptr{Ptr{Cvoid}})::Csize_t


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
        
        elem_size = unsafe_load(cd_values,3)
        comp_lvl = unsafe_load(cd_values,6)
        compress_flag = unsafe_load(cd_values,5)
        
        if cd_nelmts > 3
            block_size = unsafe_load(cd_values,4)
        end

        if block_size == 0
            block_size = ccall((:bshuf_default_block_size,libbitshuffle),Cuint,(Cuint,),elem_size)
        end
        
        major = unsafe_load(cd_values,1)
        minor = unsafe_load(cd_values,2)

        @debug "Major,minor:" major minor
        @debug "element size, compress_level, compress_flag" elem_size comp_lvl compress_flag

        # Work out buffer sizes
        
        if cd_nelmts > 4 && (compress_flag in (BSHUF_H5_COMPRESS_LZ4, BSHUF_H5_COMPRESS_ZSTD))

            # Use compression
            
            if(flags & API.H5Z_FLAG_REVERSE) != 0 # unshuffle and decompress

                # First 8 bytes is number of uncompressed bytes
                nbytes_uncomp = ccall((:bshuf_read_uint64_BE,libbitshuffle),Cuint,(Ptr{Cvoid},),in_buf)
                # Next 4 bytes are the block size
                
                block_size = ccall((:bshuf_read_uint32_BE,libbitshuffle),Cuint,(Ptr{Cvoid},),in_buf+8)/elem_size

                in_buf += 12
                buf_size_out = nbytes_uncomp
                
            else #shuffle and compress

                nbytes_uncomp = nbytes
                if compress_flag == BSHUF_H5_COMPRESS_LZ4
                    buf_size_out = ccall((:bshuf_compress_lz4_bound,libbitshuffle),Cuint,(Cuint,Cuint,Cuint),
                                         nbytes_uncomp/elem_size,elem_size,block_size) + 12
                elseif compress_flag == BSHUF_H5_COMPRESS_ZSTD
                    buf_size_out = ccall((:bshuf_compress_zstd_bound,libbitshuffle),Cuint,(Cuint,Cuint,Cuint),
                                         nbytes_uncomp/elem_size,elem_size,block_size)+12
                end
            end
            
        else  # No compression required
            nbytes_uncomp = nbytes
            buf_size_out = nbytes
        end
        
        if nbytes_uncomp % elem_size != 0
            error("bitshuffle_h5plugin: Uncompressed size $nbytes_uncomp is not a multiple of $elem_size")
        end

        size = nbytes_uncomp/elem_size
        out_buf = Libc.malloc(buf_size_out)
        if out_buf == C_NULL
            error("bitshuffle_h5plugin: Cannot allocate memory for outbuf during decompression")
        end

        # Now perform the decompression

        if cd_nelmts > 4 && (compress_flag in (BSHUF_H5_COMPRESS_LZ4, BSHUF_H5_COMPRESS_ZSTD))
            if flags & API.H5Z_FLAG_REVERSE != 0 #unshuffle and decompress
                if compress_flag == BSHUF_H5_COMPRESS_LZ4
                    err = ccall((:bshuf_decompress_lz4,libbitshuffle),Cint,
                                (Ptr{Cvoid},Ptr{Cvoid},Cuint,Cuint,Cuint),
                                in_buf,out_buf,size,elem_size,block_size)
                elseif compress_flag == BSHUF_H5_COMPRESS_ZSTD
                    err = ccall((:bshuf_decompress_zstd,libbitshuffle),Cint,
                                (Ptr{Cvoid},Ptr{Cvoid},Cuint,Cuint,Cuint),
                                in_buf,out_buf,size,elem_size,block_size)
                end
                nbytes_out = nbytes_uncomp
                
            else  #shuffle and compress
                
                ccall((:bshuf_write_uint64_BE,libbitshuffle),Cvoid,(Ptr{Cvoid},Cuint),out_buf,nbytes_uncomp)
                ccall((:bshuf_write_uint32_BE,libbitshuffle),Cvoid,(Ptr{Cvoid},Cuint),out_buf+8,block_size*elem_size)
                
                if compress_flag == BSHUF_H5_COMPRESS_LZ4
                    err = ccall((:bshuf_compress_lz4,libbitshuffle),Cint,
                                (Ptr{Cvoid},Ptr{Cvoid},Cuint,Cuint,Cuint),
                                in_buf,out_buf+12,size,elem_size,block_size)
                else
                    err = ccall((:bshuf_compress_zstd,libbitshuffle),Cint,
                                (Ptr{Cvoid},Ptr{Cvoid},Cuint,Cuint,Cuint),
                                in_buf,out_buf+12,size,elem_size,block_size)
                end
                
                nbytes_out = err + 12
            end
        else # just the shuffle thanks
            
            if flags & H5Z_FLAG_REVERSE != 0
                err = ccall((:bshuf_bitunshuffle,libbitshuffle),Cint,
                            (Ptr{Cvoid},Ptr{Cvoid},Cuint,Cuint,Cuint),
                            in_buf,out_buf,size,elem_size,block_size)
            else
                err = ccall((:bshuf_bitshuffle,libbitshuffle),Cint,
                            (Ptr{Cvoid},Ptr{Cvoid},Cuint,Cuint,Cuint),
                            in_buf,out_buf,size,elem_size,block_size)
            end
            
            nbytes_out = nbytes
        end
        
        # And wrap it up

        if err < 0
            error("h5plugin_bitshuffle: Error in bitshuffle with code $err")
        end
        
        Libc.free(unsafe_load(buf))
        unsafe_store!(buf,out_buf)
        unsafe_store!(buf_size,Csize_t(buf_size_out))
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

struct BitshuffleFilter <: Filter end

filterid(::Type{BitshuffleFilter}) = H5Z_FILTER_BITSHUFFLE
filtername(::Type{BitshuffleFilter}) = bitshuffle_name
filterfunc(::Type{BitshuffleFilter}) = H5Z_filter_bitshuffle
filter_cfunc(::Type{BitshuffleFilter}) =  @cfunction(H5Z_filter_bitshuffle, Csize_t,
                                             (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                                              Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))

function __init__()
    register_filter(BitshuffleFilter)
end

end # module
