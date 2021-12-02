using HDF5
using HDF5.Filters
using Test
import Blosc, CodecLz4, CodecBzip2, CodecZstd

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
    "blosc" => Filters.BloscFilter,
    "bzip2" => Filters.Bzip2Filter,
    "lz4" => Filters.Lz4Filter,
    "zstd" => Filters.ZstdFilter
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
        elseif haskey(compressionFilters, name)
            @test filters[1] isa compressionFilters[name]
        end
    end
end

close(f)

end # @testset "filter"
