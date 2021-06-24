using HDF5
using Test

@testset "filter" begin

H5Z_FILTER_DEFLATE = 1
H5Z_FILTER_SHUFFLE = 2

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

# Close and re-open file for reading
close(f)
f = h5open(fn)

# Read dataseta
datadeflate = f["deflate"][]
datashufdef = f["shufdef"][]
datafiltdef = f["filtdef"][]
datafiltshufdef = f["filtshufdef"][]

close(f)

# Test for equality
@test datadeflate == data
@test datashufdef == data
@test datafiltdef == data
@test datafiltshufdef == data

end # @testset "filter"
