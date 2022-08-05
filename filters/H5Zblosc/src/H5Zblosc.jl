module H5Zblosc
# port of https://github.com/Blosc/c-blosc/blob/3a668dcc9f61ad22b5c0a0ab45fe8dad387277fd/hdf5/blosc_filter.c (copyright 2010 Francesc Alted, license: MIT/expat)

import Blosc
using HDF5.API
import HDF5.Filters: Filter, FilterPipeline
import HDF5.Filters:
    filterid,
    register_filter,
    filtername,
    filter_func,
    filter_cfunc,
    set_local_func,
    set_local_cfunc
import HDF5.Filters.Shuffle

export H5Z_FILTER_BLOSC, blosc_filter, BloscFilter

# Import Blosc shuffle constants
import Blosc: NOSHUFFLE, SHUFFLE, BITSHUFFLE

const H5Z_FILTER_BLOSC = API.H5Z_filter_t(32001) # Filter ID registered with the HDF Group for Blosc
const FILTER_BLOSC_VERSION = 2
const blosc_name = "blosc"

function blosc_set_local(dcpl::API.hid_t, htype::API.hid_t, space::API.hid_t)
    blosc_flags = Ref{Cuint}()
    blosc_values = Vector{Cuint}(undef, 8)
    blosc_nelements = Ref{Csize_t}(length(blosc_values))
    blosc_chunkdims = Vector{API.hsize_t}(undef, 32)

    API.h5p_get_filter_by_id(
        dcpl,
        H5Z_FILTER_BLOSC,
        blosc_flags,
        blosc_nelements,
        blosc_values,
        0,
        C_NULL,
        C_NULL
    )
    flags = blosc_flags[]

    nelements = max(blosc_nelements[], 4) # First 4 slots reserved

    # Set Blosc info in first two slots
    blosc_values[1] = FILTER_BLOSC_VERSION
    blosc_values[2] = Blosc.VERSION_FORMAT

    ndims = API.h5p_get_chunk(dcpl, 32, blosc_chunkdims)
    chunksize = prod(resize!(blosc_chunkdims, ndims))
    if ndims < 0 || ndims > 32 || chunksize > Blosc.MAX_BUFFERSIZE
        return API.herr_t(-1)
    end

    htypesize = API.h5t_get_size(htype)
    if API.h5t_get_class(htype) == API.H5T_ARRAY
        hsuper = API.h5t_get_super(htype)
        basetypesize = API.h5t_get_size(hsuper)
        API.h5t_close(hsuper)
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

    API.h5p_modify_filter(dcpl, H5Z_FILTER_BLOSC, flags, nelements, blosc_values)

    return API.herr_t(1)
end

function blosc_filter(
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)
    typesize = unsafe_load(cd_values, 3) # The datatype size
    outbuf_size = unsafe_load(cd_values, 4)
    # Compression level:
    clevel = cd_nelmts >= 5 ? unsafe_load(cd_values, 5) : Cuint(5)
    # Do shuffle:
    doshuffle = cd_nelmts >= 6 ? unsafe_load(cd_values, 6) : SHUFFLE

    if (flags & API.H5Z_FLAG_REVERSE) == 0 # compressing
        # Allocate an output buffer exactly as long as the input data; if
        # the result is larger, we simply return 0. The filter is flagged
        # as optional, so HDF5 marks the chunk as uncompressed and proceeds.
        outbuf_size = unsafe_load(buf_size)
        outbuf = Libc.malloc(outbuf_size)
        outbuf == C_NULL && return Csize_t(0)

        compname = if cd_nelmts >= 7
            compcode = unsafe_load(cd_values, 7)
            Blosc.compname(compcode)
        else
            "blosclz"
        end
        Blosc.set_compressor(compname)
        status = Blosc.blosc_compress(
            clevel, doshuffle, typesize, nbytes, unsafe_load(buf), outbuf, nbytes
        )
        status < 0 && (Libc.free(outbuf); return Csize_t(0))
    else # decompressing
        # Extract the exact outbuf_size from the buffer header.
        #
        # NOTE: the guess value got from "cd_values" corresponds to the
        # uncompressed chunk size but it should not be used in a general
        # cases since other filters in the pipeline can modify the buffer
        # size.
        in = unsafe_load(buf)
        # See https://github.com/JuliaLang/julia/issues/43402
        # Resolved in https://github.com/JuliaLang/julia/pull/43408
        outbuf_size, cbytes, blocksize = Blosc.cbuffer_sizes(in)
        outbuf = Libc.malloc(outbuf_size)
        outbuf == C_NULL && return Csize_t(0)
        status = Blosc.blosc_decompress(in, outbuf, outbuf_size)
        status <= 0 && (Libc.free(outbuf); return Csize_t(0))
    end

    if status != 0
        Libc.free(unsafe_load(buf))
        unsafe_store!(buf, outbuf)
        unsafe_store!(buf_size, outbuf_size)
        return Csize_t(status) # size of compressed/decompressed data
    end
    Libc.free(outbuf)
    return Csize_t(0)
end

"""
    BloscFilter(;level=5, shuffle=true, compressor="blosclz")

The Blosc compression filter, using [Blosc.jl](https://github.com/JuliaIO/Blosc.jl). Options:

 - `level`: compression level
 - `shuffle`: whether to shuffle data before compressing (this option should be used instead of the [`Shuffle`](@ref) filter)
 - `compressor`: the compression algorithm. Call `Blosc.compressors()` for the available compressors.

# External links
* [What Is Blosc?](https://www.blosc.org/pages/blosc-in-depth/)
* [Blosc HDF5 Filter ID 32001](https://portal.hdfgroup.org/display/support/Filters#Filters-32001)
* [Blosc HDF5 Plugin Repository (C code)](https://github.com/Blosc/hdf5-blosc)
"""
struct BloscFilter <: Filter
    blosc_version::Cuint
    version_format::Cuint
    typesize::Cuint
    bufsize::Cuint
    level::Cuint
    shuffle::Cuint
    compcode::Cuint
end

function BloscFilter(; level=5, shuffle=SHUFFLE, compressor="blosclz")
    Blosc.isvalidshuffle(shuffle) || throw(ArgumentError("invalid blosc shuffle $shuffle"))
    compcode = Blosc.compcode(compressor)
    BloscFilter(0, 0, 0, 0, level, shuffle, compcode)
end

filterid(::Type{BloscFilter}) = H5Z_FILTER_BLOSC
filtername(::Type{BloscFilter}) = blosc_name
set_local_func(::Type{BloscFilter}) = blosc_set_local
set_local_cfunc(::Type{BloscFilter}) =
    @cfunction(blosc_set_local, API.herr_t, (API.hid_t, API.hid_t, API.hid_t))
filter_func(::Type{BloscFilter}) = blosc_filter
filter_cfunc(::Type{BloscFilter}) = @cfunction(
    blosc_filter,
    Csize_t,
    (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
)

function Base.show(io::IO, blosc::BloscFilter)
    print(
        io,
        BloscFilter,
        "(level=",
        Int(blosc.level),
        ",shuffle=",
        blosc.shuffle == NOSHUFFLE  ? "NOSHUFFLE"  :
        blosc.shuffle == SHUFFLE    ? "SHUFFLE"    :
        blosc.shuffle == BITSHUFFLE ? "BITSHUFFLE" :
        "UNKNOWN",
        ",compressor=",
        Blosc.compname(blosc.compcode),
        ")"
    )
end

function Base.push!(f::FilterPipeline, blosc::BloscFilter)
    0 <= blosc.level <= 9 ||
        throw(ArgumentError("blosc compression $(blosc.level) not in [0,9]"))
    Blosc.isvalidshuffle(blosc.shuffle) ||
        throw(ArgumentError("invalid blosc shuffle $(blosc.shuffle)"))
    ref = Ref(blosc)
    GC.@preserve ref begin
        API.h5p_set_filter(
            f.plist,
            filterid(BloscFilter),
            API.H5Z_FLAG_OPTIONAL,
            div(sizeof(BloscFilter), sizeof(Cuint)),
            pointer_from_objref(ref)
        )
    end
    return f
end

function __init__()
    register_filter(BloscFilter)
end

end # module H5Zblosc
