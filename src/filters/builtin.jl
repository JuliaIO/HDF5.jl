"""
    Deflate(level=5)

Deflate/ZLIB lossless compression filter. `level` is an integer between 0 and 9,
inclusive, denoting the compression level, with 0 being no compression, 9 being the
highest compression (but slowest speed).

# External links
- $(h5doc("H5P_SET_DEFLATE"))
- [_Deflate_ on Wikipedia](https://en.wikipedia.org/wiki/Deflate)
"""
struct Deflate <: Filter
    level::Cuint
end
Deflate(;level=5) = Deflate(level)
Base.show(io::IO, deflate::Deflate) = print(io, Deflate, "(level=", Int(deflate.level), ")")

filterid(::Type{Deflate}) = API.H5Z_FILTER_DEFLATE
FILTERS[API.H5Z_FILTER_DEFLATE] = Deflate

function Base.push!(f::FilterPipeline, deflate::Deflate)
    API.h5p_set_deflate(f.plist, deflate.level)
    return f
end

"""
    Shuffle()

The shuffle filter de-interlaces a block of data by reordering the bytes. All the bytes
from one consistent byte position of each data element are placed together in one block;
all bytes from a second consistent byte position of each data element are placed together
a second block; etc. For example, given three data elements of a 4-byte datatype stored as
012301230123, shuffling will re-order data as 000111222333. This can be a valuable step in
an effective compression algorithm because the bytes in each byte position are often
closely related to each other and putting them together can increase the compression
ratio.

As implied above, the primary value of the shuffle filter lies in its coordinated use with
a compression filter; it does not provide data compression when used alone. When the
shuffle filter is applied to a dataset immediately prior to the use of a compression
filter, the compression ratio achieved is often superior to that achieved by the use of a
compression filter without the shuffle filter.

# External links
- $(h5doc("H5P_SET_SHUFFLE"))
"""
struct Shuffle <: Filter
end
filterid(::Type{Shuffle}) = API.H5Z_FILTER_SHUFFLE
FILTERS[API.H5Z_FILTER_SHUFFLE] = Shuffle

function Base.push!(f::FilterPipeline, ::Shuffle)
    API.h5p_set_shuffle(f.plist)
    return f
end

"""
    Fletcher32()

The Fletcher32 checksum filter. This doesn't perform compression, but instead checks the validity of the stored data.

This should be applied _after_ any lossy filters have been applied.

# External links
- $(h5doc("H5P_SET_FLETCHER32"))
- [_Fletcher's checksum_ on Wikipedia](https://en.wikipedia.org/wiki/Fletcher's_checksum)
"""
struct Fletcher32 <: Filter
end
filterid(::Type{Fletcher32}) = API.H5Z_FILTER_FLETCHER32
FILTERS[API.H5Z_FILTER_FLETCHER32] = Fletcher32
function Base.push!(f::FilterPipeline, ::Fletcher32)
    API.h5p_set_fletcher32(f.plist)
    return f
end

"""
    Szip(coding=:nn, pixels_per_block=8)

Szip compression lossless filter. Options:

- `coding`: the coding method: either `:ec` (entropy coding) or `:nn` (nearest neighbors,
  default)
- `pixels_per_block`: The number of pixels or data elements in each data block (typically
  8, 10, 16, or 32)

# External links
- $(h5doc("H5P_SET_SZIP"))
- [Szip Compression in HDF Products](https://support.hdfgroup.org/doc_resource/SZIP/)
"""
struct Szip <: Filter
    options_mask::Cuint
    pixels_per_block::Cuint
end
function Szip(;coding=:nn, pixels_per_block=8)
    options_mask = Cuint(0)
    if coding == :ec
        options_mask |= API.H5_SZIP_EC_OPTION_MASK
    elseif coding == :nn
        options_mask |= API.H5_SZIP_NN_OPTION_MASK
    else
        error("invalid coding option")
    end
    Szip(options_mask, pixels_per_block)
end
function Base.show(io::IO, szip::Szip)
    print(io, Szip, "(")
    if szip.options_mask & API.H5_SZIP_EC_OPTION_MASK != 0
        print(io, "coding=:ec,")
    elseif szip.options_mask & API.H5_SZIP_NN_OPTION_MASK != 0
        print(io, "coding=:nn,")
    end
    print(io, "pixels_per_block=", Int(szip.pixels_per_block))
end

filterid(::Type{Szip}) = API.H5Z_FILTER_SZIP
FILTERS[API.H5Z_FILTER_SZIP] = Szip
function Base.push!(f::FilterPipeline, szip::Szip)
    API.h5p_set_szip(f.plist, szip.options_mask, szip.pixels_per_block)
    return f
end

"""
    NBit()

The N-Bit filter.

# External links
- $(h5doc("H5P_SET_NBIT"))
"""
struct NBit <: Filter
end
filterid(::Type{NBit}) = API.H5Z_FILTER_NBIT
FILTERS[API.H5Z_FILTER_NBIT] = NBit
function Base.push!(f::FilterPipeline, ::NBit)
    API.h5p_set_nbit(f.plist)
    return f
end

"""
    ScaleOffset(scale_type::Integer, scale_offset::Integer)

The scale-offset filter.

# External links
- $(h5doc("H5P_SET_SCALEOFFSET"))
"""
struct ScaleOffset <: Filter
    scale_type::Cint
    scale_factor::Cint
end

filterid(::Type{ScaleOffset}) = API.H5Z_FILTER_SCALEOFFSET
FILTERS[API.H5Z_FILTER_SCALEOFFSET] = ScaleOffset
function Base.push!(f::FilterPipeline, scaleoffset::ScaleOffset)
    API.h5p_set_scaleoffset(f.plist, scaleoffset.scale_type, scaleoffset.scale_factor)
    return f
end

