using HDF5
using Base.Test
using Compat

@testset "cartesian_range" begin 

filename = "$(tempname()).h5"

h5write(filename, "main", Array(1:10))
@test h5read(filename, "main", CartesianRange((3:5,))) == [3:5;]
f = h5open(filename,"r+")
dset = f["main"]
# setindex of cartesian range
dset[CartesianRange((3:5,))] = [3:5;]
@test dset[CartesianRange((3:5,))] == [3:5;]

close(f)
rm(filename)

end # end of testset
