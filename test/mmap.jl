using HDF5
using Test

@testset "mmap" begin

# Create a new file
fn = tempname()
f = h5open(fn, "w")
@test isopen(f)

# Create two datasets, one with late allocation (the default for contiguous
# datasets) and the other with explicit early allocation.
hdf5_A = d_create(f, "A", datatype(Int64), dataspace(3,3))
hdf5_B = d_create(f, "B", datatype(Float64), dataspace(3,3);
                  alloc_time = HDF5.H5D_ALLOC_TIME_EARLY)
# The late case cannot be mapped yet.
@test_throws ErrorException("Error getting offset") readmmap(f["A"])
# Then write and fill dataset A, making it mappable. B was filled with 0.0 at
# creation.
A = rand(Int64,3,3)
hdf5_A[:,:] = A
flush(f)
close(f)
# Read HDF5 file & MMAP
f = h5open(fn,"r")
A_mmaped = readmmap(f["A"])
@test all(A .== A_mmaped)
@test all(iszero, readmmap(f["B"]))
# Check that it is read only
@test_throws ReadOnlyMemoryError A_mmaped[1,1] = 33
close(f)
# Now check if we can write
f = h5open(fn,"r+")
A_mmaped = readmmap(f["A"])
A_mmaped[1,1] = 33
close(f)

end
