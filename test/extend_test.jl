using HDF5
using Test

@testset "extend" begin

fn = tempname()

fid = h5open(fn, "w")
g = create_group(fid, "shoe")
d = create_dataset(g, "foo", datatype(Float64), ((10, 20), (100, 200)), chunk=(1, 1))
#println("d is size current $(map(int,HDF5.get_extent_dims(d)[1])) max $(map(int,HDF5.get_extent_dims(d)[2]))")
dims, max_dims = HDF5.get_extent_dims(d)
@test dims == (UInt64(10), UInt64(20))
@test max_dims == (UInt64(100), UInt64(200))
HDF5.set_extent_dims(d, (100, 150))
dims, max_dims = HDF5.get_extent_dims(d)
@test dims == (UInt64(100), UInt64(150))
@test max_dims == (UInt64(100), UInt64(200))
d[1, 1:5] = [1.1231, 1.313, 5.123, 2.231, 4.1231]
HDF5.set_extent_dims(d, (1, 5))
@test size(d) == (1, 5)

# Indexing returns correct array dimensions
@test d[1, end] ≈ 4.1231
@test d[:, end] ≈ [4.1231]
@test d[end, :] == [1.1231, 1.313, 5.123, 2.231, 4.1231]
@test d[:, :] == [1.1231 1.313 5.123 2.231 4.1231]

# Test all integer types work
@test d[UInt8(1), UInt16(1)] == 1.1231
@test d[UInt32(1), UInt128(1)] == 1.1231
@test d[Int8(1), Int16(1)] == 1.1231
@test d[Int32(1), Int128(1)] == 1.1231

# Test ranges work with steps
@test d[1, 1:2:5] == [1.1231, 5.123, 4.1231]
@test d[1:1, 2:2:4] == [1.313 2.231]

# Test Array constructor
Array(d) == [1.1231 1.313 5.123 2.231 4.1231]

#println("d is size current $(map(int,HDF5.get_extent_dims(d)[1])) max $(map(int,HDF5.get_extent_dims(d)[2]))")
b = create_dataset(fid, "b", Int, ((1000,), (-1,)), chunk=(100,)) #-1 is equivalent to typemax(hsize_t) as far as I can tell
#println("b is size current $(map(int,HDF5.get_extent_dims(b)[1])) max $(map(int,HDF5.get_extent_dims(b)[2]))")
b[1:200] = ones(200)
dims, max_dims = HDF5.get_extent_dims(b)
@test dims == (UInt64(1000),)
@test max_dims == (HDF5.API.H5S_UNLIMITED % Int,)
HDF5.set_extent_dims(b, (10000,))
dims, max_dims = HDF5.get_extent_dims(b)
@test dims == (UInt64(10000),)
@test max_dims == (HDF5.API.H5S_UNLIMITED % Int,)
#println("b is size current $(map(int,HDF5.get_extent_dims(b)[1])) max $(map(int,HDF5.get_extent_dims(b)[2]))")
# b[:] = [1:10000] # gave error no method lastindex(HDF5.Dataset{PlainHDF5File},),
# so I defined lastindex(dset::HDF5.Dataset) = length(dset), and exported lastindex
# but that didn't fix the error, despite the lastindex function working
# d[1] produces error ERROR: Wrong number of indices supplied, should datasets support linear indexing?
b[1:10000] = [1:10000;]
#println(b[1:100])

close(fid)

fid = h5open(fn, "r")
d_again = fid["shoe/foo"]
dims, max_dims = HDF5.get_extent_dims(d_again)
@test dims == (UInt64(1), UInt64(5))
@test max_dims == (UInt64(100), UInt64(200))
@test (sum(d_again[1, 1:5]) - sum([1.1231, 1.313, 5.123, 2.231, 4.1231])) == 0
#println("d is size current $(map(int,HDF5.get_extent_dims(re_d)[1])) max $(map(int,HDF5.get_extent_dims(re_d)[2]))")
@test fid["b"][1:10000] == [1:10000;]
b_again = fid["b"]
dims, max_dims = HDF5.get_extent_dims(b_again)
@test dims == (UInt64(10000),)
@test max_dims == (HDF5.API.H5S_UNLIMITED % Int,)
#println("b is size current $(map(int,HDF5.get_extent_dims(b)[1])) max $(map(int,HDF5.get_extent_dims(b)[2]))")

close(fid)
rm(fn)

end # testset extend_test
