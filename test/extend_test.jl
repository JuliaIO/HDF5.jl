using HDF5

fn = joinpath(tempdir(),"test.h5")

fid = h5open(fn, "w")
g = g_create(fid, "shoe")
d = d_create(g, "foo", datatype(Float64), ((10,20),(100,200)), "chunk", (1,1))
#println("d is size current $(map(int,HDF5.get_dims(d)[1])) max $(map(int,HDF5.get_dims(d)[2]))")
dims, max_dims = HDF5.get_dims(d)
ui64(n) = @compat UInt64(n)
@assert dims==(ui64(10),ui64(20))
@assert max_dims == (ui64(100),ui64(200))
set_dims!(d, (100,150))
dims, max_dims = HDF5.get_dims(d)
@assert dims==(ui64(100),ui64(150))
@assert max_dims == (ui64(100),ui64(200))
d[1,1:5]=[1.1231,1.313,5.123,2.231,4.1231]
set_dims!(d, (1,5))
@assert size(d) == (1,5)
#println("d is size current $(map(int,HDF5.get_dims(d)[1])) max $(map(int,HDF5.get_dims(d)[2]))")
b = d_create(fid, "b", Int, ((1000,),(-1,)), "chunk", (100,)) #-1 is equivalent to typemax(Hsize) as far as I can tell
#println("b is size current $(map(int,HDF5.get_dims(b)[1])) max $(map(int,HDF5.get_dims(b)[2]))")
b[1:200] = ones(200)
dims, max_dims = HDF5.get_dims(b)
@assert dims == (ui64(1000),)
@assert max_dims == (HDF5.MAXIMUM_DIM,)
set_dims!(b, (10000,))
dims, max_dims = HDF5.get_dims(b)
@assert dims == (ui64(10000),)
@assert max_dims == (HDF5.MAXIMUM_DIM,)
#println("b is size current $(map(int,HDF5.get_dims(b)[1])) max $(map(int,HDF5.get_dims(b)[2]))")
# b[:] = [1:10000] # gave error no method endof(HDF5Dataset{PlainHDF5File},),
# so I defined endof(dset::HDF5Dataset) = length(dset), and exported endof
# but that didn't fix the error, despite the endof function working
# d[1] produces error ERROR: Wrong number of indices supplied, should datasets support linear indexing?
b[1:10000] = [1:10000;]
#println(b[1:100])

close(fid)

fid = h5open(fn, "r")
d_again = fid["shoe/foo"]
dims, max_dims = HDF5.get_dims(d_again)
@assert dims==(ui64(1),ui64(5))
@assert max_dims == (ui64(100),ui64(200))
@assert (sum(d_again[1,1:5])-sum([1.1231,1.313,5.123,2.231,4.1231])) == 0
#println("d is size current $(map(int,HDF5.get_dims(re_d)[1])) max $(map(int,HDF5.get_dims(re_d)[2]))")
@assert fid["b"][1:10000] == [1:10000;]
b_again = fid["b"]
dims, max_dims = HDF5.get_dims(b_again)
@assert dims == (ui64(10000),)
@assert max_dims == (HDF5.MAXIMUM_DIM,)
#println("b is size current $(map(int,HDF5.get_dims(b)[1])) max $(map(int,HDF5.get_dims(b)[2]))")


close(fid)
