using MPI
using HDF5
using Test

@testset "mpio" begin

MPI.Init()

info = MPI.Info()
comm = MPI.COMM_WORLD

nprocs = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)

@test HDF5.has_parallel()

let fileprop = HDF5.FileAccessProperties()
    fileprop.driver = HDF5.Drivers.MPIO(comm, info)
    driver = fileprop.driver
    h5comm = driver.comm
    h5info = driver.info

    # check that the two communicators point to the same group
    if isdefined(MPI, :Comm_compare)  # requires recent MPI.jl version
        @test MPI.Comm_compare(comm, h5comm) === MPI.CONGRUENT
    end
end

# open file in parallel and write dataset
fn = MPI.bcast(tempname(), 0, comm)
A = [myrank + i for i = 1:10]
h5open(fn, "w", comm, info) do f
    @test isopen(f)
    g = create_group(f, "mygroup")
    dset = create_dataset(g, "B", datatype(Int64), dataspace(10, nprocs), chunk=(10, 1), dxpl_mpio=:collective)
    dset[:, myrank + 1] = A
end

MPI.Barrier(comm)
h5open(fn, comm) do f  # default: opened in read mode, with default MPI.Info()
    @test isopen(f)
    @test keys(f) == ["mygroup"]

    B = read(f, "mygroup/B", dxpl_mpio=:collective)
    @test !isempty(B)
    @test A == vec(B[:, myrank + 1])

    B = f["mygroup/B", dxpl_mpio=:collective]
    @test !isempty(B)
    @test A == vec(B[:, myrank + 1])
end

MPI.Barrier(comm)

B = h5read(fn, "mygroup/B", driver = HDF5.Drivers.MPIO(comm, info), dxpl_mpio=:collective)
@test A == vec(B[:, myrank + 1])

MPI.Barrier(comm)

B = h5read(fn, "mygroup/B", (:, myrank + 1), driver=HDF5.Drivers.MPIO(comm, info), dxpl_mpio=:collective)
@test A == vec(B)

# we need to close HDF5 and finalize the info object before finalizing MPI
finalize(info)
HDF5.API.h5_close()

MPI.Barrier(MPI.COMM_WORLD)

MPI.Finalize()

end # testset mpio
