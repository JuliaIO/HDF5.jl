import Blosc

# port of https://github.com/Blosc/c-blosc/blob/3a668dcc9f61ad22b5c0a0ab45fe8dad387277fd/hdf5/blosc_filter.c (copyright 2010 Francesc Alted, license: MIT/expat)

typealias H5T_class_t Cint # C enum

# The following definitions mirror those in H5Zpublic.h for HDF5 1.8.x:
const H5Z_FLAG_REVERSE = 0x0100
const H5Z_FLAG_OPTIONAL = 0x0001
const H5Z_CLASS_T_VERS = 1
typealias H5Z_filter_t Cint
immutable H5Z_class2_t
    version::Cint # = H5Z_CLASS_T_VERS
    id::H5Z_filter_t # Filter ID number
    encoder_present::Cuint # Does this filter have an encoder?
    decoder_present::Cuint # Does this filter have a decoder?
    name::Ptr{Uint8} # Comment for debugging
    can_apply::Ptr{Void} # The "can apply" callback
    set_local::Ptr{Void} # The "set local" callback
    filter::Ptr{Void} # The filter callback
end

const FILTER_BLOSC_VERSION = 2
const FILTER_BLOSC = 32001 # Filter ID registered with the HDF Group for Blosc
const blosc_name = "blosc"

const blosc_flags_ = Array(Cuint, 1)
const blosc_nelements_ = Array(Csize_t, 1)
const blosc_values = Array(Cuint, 8)
const blosc_chunkdims = Array(Hsize, 32)
function blosc_set_local(dcpl::Hid, htype::Hid, space::Hid)
    blosc_nelements_[1] = 8
    if ccall((:H5Pget_filter_by_id2,libhdf5), Herr,
             (Hid, H5Z_filter_t, Ptr{Cuint}, Ptr{Csize_t}, Ptr{Cuint},
              Csize_t, Ptr{Uint8}, Ptr{Cuint}),
             dcpl, FILTER_BLOSC, blosc_flags_, blosc_nelements_, blosc_values,
             0, C_NULL, C_NULL) < 0
        return convert(Herr, -1)
    end
    flags = blosc_flags_[1]
    nelements = max(blosc_nelements_[1], 4)
    # Set Blosc info in first two slots
    blosc_values[1] = FILTER_BLOSC_VERSION;
    blosc_values[2] = Blosc.VERSION_FORMAT;
    ndims = ccall((:H5Pget_chunk,libhdf5), Cint, (Hid, Cint, Ptr{Hsize}),
                  dcpl, 32, blosc_chunkdims);
    chunksize = prod(resize!(blosc_chunkdims, ndims))
    if ndims < 0 || ndims > 32 || chunksize > Blosc.MAX_BUFFERSIZE
        return convert(Herr, -1)
    end
    htypesize = ccall((:H5Tget_size,libhdf5), Csize_t, (Hid,), htype)
    htypesize == 0 && returnconvert(Herr, -1)
    if ccall((:H5Tget_class,libhdf5),H5T_class_t,(Hid,),htype) == H5T_ARRAY
        hsuper = ccall((:H5Tget_super,libhdf5), Hid, (Hid,), htype)
        basetypesize = ccall((:H5Tget_size,libhdf5),Csize_t,(Hid,), hsuper)
        ccall((:H5Tclose,libhdf5), Herr, (Hid,), hsuper)
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
    if ccall((:H5Pmodify_filter,libhdf5), Herr, 
             (Hid, H5Z_filter_t, Cuint, Csize_t, Ptr{Cuint}),
             dcpl, FILTER_BLOSC, flags, nelements, blosc_values) < 0
        return convert(Herr, -1)
        end
    return convert(Herr, 1)
end
const c_blosc_set_local = cfunction(blosc_set_local, Herr, (Hid,Hid,Hid))

function blosc_filter(flags::Cuint, cd_nelmts::Csize_t,
                      cd_values::Ptr{Cuint}, nbytes::Csize_t,
                      buf_size::Ptr{Csize_t}, buf::Ptr{Ptr{Void}})
    typesize = unsafe_load(cd_values, 3) # The datatype size
    outbuf_size = unsafe_load(cd_values, 4)
    # Compression level:
    clevel = cd_nelmts >= 5 ? unsafe_load(cd_values, 5) : convert(Cuint, 5)
    # Do shuffle:
    doshuffle = cd_nelmts >= 6 ? Bool(unsafe_load(cd_values, 6)) : true
    # to do: set compressor based on compcode in unsafe_load(cd_values, 7)?

    if (flags & H5Z_FLAG_REVERSE) == 0 # compressing
        # Allocate an output buffer exactly as long as the input data; if
        # the result is larger, we simply return 0. The filter is flagged
        # as optional, so HDF5 marks the chunk as uncompressed and proceeds.
        outbuf_size = unsafe_load(buf_size)
        outbuf = c_malloc(outbuf_size)
        outbuf == C_NULL && return convert(Csize_t, 0)
        status = Blosc.blosc_compress(clevel, doshuffle, typesize, nbytes,
                                      unsafe_load(buf), outbuf, nbytes)
        status < 0 && (c_free(outbuf); return convert(Csize_t, 0))
    else # decompressing
        # Extract the exact outbuf_size from the buffer header.
        #
        # NOTE: the guess value got from "cd_values" corresponds to the
        # uncompressed chunk size but it should not be used in a general
        # cases since other filters in the pipeline can modify the buffer
        # size.
        outbuf_size, cbytes, blocksize = Blosc.cbuffer_sizes(unsafe_load(buf))
        outbuf = c_malloc(outbuf_size)
        outbuf == C_NULL && return convert(Csize_t, 0)
        status = Blosc.blosc_decompress(unsafe_load(buf), outbuf, outbuf_size)
        status <= 0 && (c_free(outbuf); return convert(Csize_t, 0))
    end
    
    if status != 0
        c_free(unsafe_load(buf));
        unsafe_store!(buf, outbuf)
        unsafe_store!(buf_size, outbuf_size)
        return convert(Csize_t, status) # size of compressed/decompressed data
    end
    c_free(outbuf); return convert(Csize_t, 0)
end
const c_blosc_filter = cfunction(blosc_filter, Csize_t,
                                 (Cuint, Csize_t, Ptr{Cuint}, Csize_t,
                                  Ptr{Csize_t}, Ptr{Ptr{Void}}))

# register the Blosc filter function with HDF5
function register_blosc()
    if ccall((:H5Zregister, libhdf5), Herr, (Ptr{H5Z_class2_t},),
             &H5Z_class2_t(H5Z_CLASS_T_VERS,
                           FILTER_BLOSC,
                           1, 1,
                           pointer(blosc_name),
                           C_NULL,
                           c_blosc_set_local,
                           c_blosc_filter)) < 0
        error("can't register Blosc filter")
    end
end

const _set_blosc_values = Cuint[0,0,0,0, 5,1,0]
function h5p_set_blosc(p::HDF5Properties, level::Integer=5)
    0 <= level <= 9 || throw(ArgumentError("blosc compression $level not in [0,9]"))
    _set_blosc_values[5] = level
    ccall((:H5Pset_filter,libhdf5), Herr,
          (Hid, H5Z_filter_t, Cuint, Csize_t, Ptr{Cuint}),
          p.id, FILTER_BLOSC, H5Z_FLAG_OPTIONAL, 7, _set_blosc_values)
end
