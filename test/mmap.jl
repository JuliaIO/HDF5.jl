using HDF5
using Test

@testset "mmap" begin

# Create a new file
fn = tempname()
f = h5open(fn, "w")
@test isopen(f)

# Write  HDF5 file
hdf5_A = d_create(f,"A",datatype(Int64),dataspace(3,3));
A = rand(Int64,3,3)
hdf5_A[:,:] = A
flush(f)
close(f)
# Read HDF5 file & MMAP
f = h5open(fn,"r")
A_mmaped = readmmap(f["A"])
@test all(A .== A_mmaped)
# Check that it is read only
@test_throws ReadOnlyMemoryError A_mmaped[1,1] = 33
close(f)
# Now check if we can write
f = h5open(fn,"r+")
A_mmaped = readmmap(f["A"])
A_mmaped[1,1] = 33
close(f)

end
