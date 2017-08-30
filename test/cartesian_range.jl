using HDF5
using Base.Test
using Compat

@testset "cartesian_range" begin 

filename = "$(tempname()).h5"

h5write(filename, "1d", Array(1:10))
h5write(filename, "2d", reshape(Array(1:10),(5,2)))

@test h5read(filename, "1d", CartesianRange((3:5,))) == [3:5;]
@test h5read(filename, "2d", CartesianRange((1:2,1:2))) == [1 6; 2 7]

f = h5open(filename,"r+")
dset1d = f["1d"]
dset2d = f["2d"]

# setindex of cartesian range
dset1d[CartesianRange((3:5,))] = [4:6;]
dset2d[CartesianRange((1:2,1:2))] = [2 7; 3 8]

@test dset1d[CartesianRange((3:5,))] == [4:6;]
@test dset2d[CartesianRange((1:2,1:2))] == [2 7; 3 8]

close(f)
rm(filename)

end # end of testset
