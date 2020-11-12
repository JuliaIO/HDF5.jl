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

let fileprop = create_property(HDF5.H5P_FILE_ACCESS)
    HDF5.h5p_set_fapl_mpio(fileprop, comm, info)
    h5comm, h5info = HDF5.h5p_get_fapl_mpio(fileprop)

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
    dset = create_dataset(g, "B", datatype(Int64), dataspace(10, nprocs), chunk=(10, 1), dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE)
    dset[:, myrank + 1] = A
end

MPI.Barrier(comm)
h5open(fn, comm) do f  # default: opened in read mode, with default MPI.Info()
    @test isopen(f)
    @test keys(f) == ["mygroup"]

    B = read(f, "mygroup/B", dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE)
    @test !isempty(B)
    @test A == vec(B[:, myrank + 1])

    B = f["mygroup/B", dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE]
    @test !isempty(B)
    @test A == vec(B[:, myrank + 1])
end

MPI.Barrier(comm)

B = h5read(fn, "mygroup/B", fapl_mpio=(comm, info), dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE)
@test A == vec(B[:, myrank + 1])

MPI.Barrier(comm)

B = h5read(fn, "mygroup/B", (:, myrank + 1), fapl_mpio=(comm, info), dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE)
@test A == vec(B)

# we need to close HDF5 and finalize the info object before finalizing MPI
finalize(info)
HDF5.h5_close()

MPI.Barrier(MPI.COMM_WORLD)

MPI.Finalize()

end # testset mpio
