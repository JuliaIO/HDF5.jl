using HDF5
using HDF5.Filters
using Test
using H5Zblosc, H5Zlz4, H5Zbzip2, H5Zzstd, H5Zbitshuffle

using HDF5.Filters: ExternalFilter, isavailable, isencoderenabled, isdecoderenabled

@testset "filter" begin

# Create a new file
fn = tempname()

# Create test data
data = rand(1000, 1000)

# Open temp file for writing
f = h5open(fn, "w")

# Create datasets
dsdeflate = create_dataset(f, "deflate", datatype(data), dataspace(data),
                           chunk=(100, 100), deflate=3)

dsshufdef = create_dataset(f, "shufdef", datatype(data), dataspace(data),
                           chunk=(100, 100), shuffle=true, deflate=3)

dsfiltdef = create_dataset(f, "filtdef", datatype(data), dataspace(data),
                           chunk=(100, 100), filters=Filters.Deflate(3))

dsfiltshufdef = create_dataset(f, "filtshufdef", datatype(data), dataspace(data),
                               chunk=(100, 100), filters=[Filters.Shuffle(), Filters.Deflate(3)])


# Write data
write(dsdeflate, data)
write(dsshufdef, data)
write(dsfiltdef, data)
write(dsfiltshufdef, data)

# Test compression filters

compressionFilters = Dict(
    "blosc" => BloscFilter,
    "bzip2" => Bzip2Filter,
    "lz4" => Lz4Filter,
    "zstd" => ZstdFilter,
)

for (name, filter) in compressionFilters

    ds = create_dataset(
        f, name, datatype(data), dataspace(data),
        chunk=(100,100), filters=filter()
    )
    write(ds, data)

    ds = create_dataset(
        f, "shuffle+"*name, datatype(data), dataspace(data),
        chunk=(100,100), filters=[Filters.Shuffle(), filter()]
    )
    write(ds, data)

end

ds = create_dataset(
    f, "blosc_bitshuffle", datatype(data), dataspace(data),
    chunk=(100,100), filters=BloscFilter(shuffle=H5Zblosc.BITSHUFFLE)
)
write(ds, data)

ds = create_dataset(
    f, "bitshuffle_lz4", datatype(data), dataspace(data),
    chunk=(100,100), filters=BitshuffleFilter(compressor="lz4")
)
write(ds, data)

ds = create_dataset(
    f, "bitshuffle_zstd", datatype(data), dataspace(data),
    chunk=(100,100), filters=BitshuffleFilter(compressor="zstd",comp_level=5)
)
    
write(ds, data)

ds = create_dataset(
    f, "bitshuffle_plain", datatype(data), dataspace(data),
    chunk=(100,100), filters=BitshuffleFilter()
)
    
write(ds, data)

    
# Close and re-open file for reading
close(f)
f = h5open(fn)

# Read datasets and test for equality
for name in keys(f)
    ds = f[name]
    @testset "$name" begin
        @debug "Filter Dataset" HDF5.name(ds)
        @test ds[] == data
        filters = HDF5.get_create_properties(ds).filters
        if startswith(name, "shuffle+")
            @test filters[1] isa Shuffle
            @test filters[2] isa compressionFilters[name[9:end]]
        elseif haskey(compressionFilters, name) || name == "blosc_bitshuffle"
            name = replace(name, r"_.*"=>"")
            @test filters[1] isa compressionFilters[name]
        end
    end
end

close(f)

# Issue #896 and https://github.com/JuliaIO/HDF5.jl/issues/285#issuecomment-1002243321
# Create an ExternalFilter from a Tuple
h5open(fn, "w") do f
    data = rand(UInt8, 512, 16, 512)
    # Tuple of integers should become an Unknown Filter
    ds, dt = create_dataset(f, "data", data, chunk=(256,1,256), filter=(H5Z_FILTER_BZIP2, 0))
    # Tuple of Filters should get pushed into the pipeline one by one
    dsfiltshufdef = create_dataset(f, "filtshufdef", datatype(data), dataspace(data),
                               chunk=(128, 4, 128), filters=(Filters.Shuffle(), Filters.Deflate(3)))
    write(ds, data)
    close(ds)
    write(dsfiltshufdef, data)
    close(dsfiltshufdef)
end

h5open(fn, "r") do f
    @test f["data"][] == data
    @test f["filtshufdef"][] == data
end

# Filter Pipeline test for ExternalFilter
FILTERS_backup = copy(HDF5.Filters.FILTERS)
empty!(HDF5.Filters.FILTERS)
h5open(fn, "w") do f
    data = collect(1:128)
    filter = ExternalFilter(H5Z_FILTER_LZ4, 0, Cuint[0, 2, 4, 6, 8, 10], "Unknown LZ4", 0)
    ds, dt = create_dataset(f, "data", data, chunk=(32,), filters=filter)
    dcpl = HDF5.get_create_properties(ds)
    pipeline = HDF5.Filters.FilterPipeline(dcpl)
    @test pipeline[1].data == filter.data
end
merge!(HDF5.Filters.FILTERS, FILTERS_backup)

@test HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_DEFLATE)
@test HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_FLETCHER32)
@test HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_NBIT)
@test HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_SCALEOFFSET)
@test HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_SHUFFLE)
@static if Sys.iswindows() || VERSION ≤ v"1.6"
    @test HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_SZIP)
else
    # These are missing in the macOS and Linux JLLs
    @test_broken HDF5.API.h5z_filter_avail(HDF5.API.H5Z_FILTER_SZIP)
end
@test HDF5.API.h5z_filter_avail(H5Z_FILTER_BZIP2)
@test HDF5.API.h5z_filter_avail(H5Z_FILTER_LZ4)
@test HDF5.API.h5z_filter_avail(H5Z_FILTER_ZSTD)
@test HDF5.API.h5z_filter_avail(H5Z_FILTER_BLOSC)
HDF5.API.h5z_unregister(H5Z_FILTER_LZ4)
HDF5.Filters.register_filter(H5Zlz4.Lz4Filter)
@test isavailable(H5Z_FILTER_LZ4)
@test isavailable(Lz4Filter)
@test isencoderenabled(H5Z_FILTER_LZ4)
@test isdecoderenabled(H5Z_FILTER_LZ4)
@test isencoderenabled(Lz4Filter)
@test isdecoderenabled(Lz4Filter)

end # @testset "filter"
