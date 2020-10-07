import Blosc

# port of https://github.com/Blosc/c-blosc/blob/3a668dcc9f61ad22b5c0a0ab45fe8dad387277fd/hdf5/blosc_filter.c (copyright 2010 Francesc Alted, license: MIT/expat)

const FILTER_BLOSC_VERSION = 2
const FILTER_BLOSC = 32001 # Filter ID registered with the HDF Group for Blosc
const blosc_name = "blosc"

const blosc_flags = Ref{Cuint}()
const blosc_values = Vector{Cuint}(undef,8)
const blosc_nelements = Ref{Csize_t}(length(blosc_values))
const blosc_chunkdims = Vector{hsize_t}(undef,32)

function blosc_set_local(dcpl::hid_t, htype::hid_t, space::hid_t)
    h5p_get_filter_by_id(dcpl, FILTER_BLOSC, blosc_flags, blosc_nelements, blosc_values, 0, C_NULL, C_NULL)
    flags = blosc_flags[]

    nelements = max(blosc_nelements[], 4) # First 4 slots reserved

    # Set Blosc info in first two slots
    blosc_values[1] = FILTER_BLOSC_VERSION
    blosc_values[2] = Blosc.VERSION_FORMAT

    ndims = h5p_get_chunk(dcpl, 32, blosc_chunkdims)
    chunksize = prod(resize!(blosc_chunkdims, ndims))
    if ndims < 0 || ndims > 32 || chunksize > Blosc.MAX_BUFFERSIZE
        return herr_t(-1)
    end

    htypesize = h5t_get_size(htype)
    if h5t_get_class(htype) == H5T_ARRAY
        hsuper = h5t_get_super(htype)
        basetypesize = h5t_get_size(hsuper)
        h5t_close(hsuper)
    else
        basetypesize = htypesize
    end

    # Limit large typesizes (they are pretty inefficient to shuffle
    # and, in addition, Blosc does not handle typesizes larger than
    # blocksizes).
    if basetypesize > Blosc.MAX_TYPESIZE
        basetypesize = 1
    end
    blosc_values[3] = basetypesize
    blosc_values[4] = chunksize * htypesize # size of the chunk

    h5p_modify_filter(dcpl, FILTER_BLOSC, flags, nelements, blosc_values)

    return herr_t(1)
end

function blosc_filter(flags::Cuint, cd_nelmts::Csize_t,
                      cd_values::Ptr{Cuint}, nbytes::Csize_t,
                      buf_size::Ptr{Csize_t}, buf::Ptr{Ptr{Cvoid}})
    typesize = unsafe_load(cd_values, 3) # The datatype size
    outbuf_size = unsafe_load(cd_values, 4)
    # Compression level:
    clevel = cd_nelmts >= 5 ? unsafe_load(cd_values, 5) : Cuint(5)
    # Do shuffle:
    doshuffle = cd_nelmts >= 6 ? unsafe_load(cd_values, 6) != 0 : true
    # to do: set compressor based on compcode in unsafe_load(cd_values, 7)?

    if (flags & H5Z_FLAG_REVERSE) == 0 # compressing
        # Allocate an output buffer exactly as long as the input data; if
        # the result is larger, we simply return 0. The filter is flagged
        # as optional, so HDF5 marks the chunk as uncompressed and proceeds.
        outbuf_size = unsafe_load(buf_size)
        outbuf = Libc.malloc(outbuf_size)
        outbuf == C_NULL && return Csize_t(0)
        status = Blosc.blosc_compress(clevel, doshuffle, typesize, nbytes,
                                      unsafe_load(buf), outbuf, nbytes)
        status < 0 && (Libc.free(outbuf); return Csize_t(0))
    else # decompressing
        # Extract the exact outbuf_size from the buffer header.
        #
        # NOTE: the guess value got from "cd_values" corresponds to the
        # uncompressed chunk size but it should not be used in a general
        # cases since other filters in the pipeline can modify the buffer
        # size.
        outbuf_size, cbytes, blocksize = Blosc.cbuffer_sizes(unsafe_load(buf))
        outbuf = Libc.malloc(outbuf_size)
        outbuf == C_NULL && return Csize_t(0)
        status = Blosc.blosc_decompress(unsafe_load(buf), outbuf, outbuf_size)
        status <= 0 && (Libc.free(outbuf); return Csize_t(0))
    end

    if status != 0
        Libc.free(unsafe_load(buf))
        unsafe_store!(buf, outbuf)
        unsafe_store!(buf_size, outbuf_size)
        return Csize_t(status) # size of compressed/decompressed data
    end
    Libc.free(outbuf); return Csize_t(0)
end

# register the Blosc filter function with HDF5
function register_blosc()
    c_blosc_set_local = @cfunction(blosc_set_local, herr_t, (hid_t,hid_t,hid_t))
    c_blosc_filter = @cfunction(blosc_filter, Csize_t,
                                (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                                 Ptr{Csize_t}, Ptr{Ptr{Cvoid}}))
    h5z_register(H5Z_class_t(H5Z_CLASS_T_VERS, FILTER_BLOSC, 1, 1, pointer(blosc_name), C_NULL, c_blosc_set_local, c_blosc_filter))

    return nothing
end

const set_blosc_values = Cuint[0,0,0,0,5,1,0]
function h5p_set_blosc(p::Properties, level::Integer=5)
    0 <= level <= 9 || throw(ArgumentError("blosc compression $level not in [0,9]"))
    set_blosc_values[5] = level
    h5p_set_filter(p.id, FILTER_BLOSC, H5Z_FLAG_OPTIONAL, length(set_blosc_values), set_blosc_values)

    return nothing
end
