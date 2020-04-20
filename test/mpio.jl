using MPI
using HDF5
using Test

@testset "mpio" begin

MPI.Init()
info = MPI.Info()

h = HDF5.mpihandles[sizeof(MPI.CComm)]
ccomm = reinterpret(h, MPI.CComm(MPI.COMM_WORLD))
cinfo = reinterpret(h, MPI.CInfo(info))

nprocs = MPI.Comm_size(MPI.COMM_WORLD)
myrank = MPI.Comm_rank(MPI.COMM_WORLD)

fileprop = p_create(HDF5.H5P_FILE_ACCESS)
HDF5.h5p_set_fapl_mpio(fileprop, ccomm, cinfo)
h5comm, h5info = HDF5.h5p_get_fapl_mpio(fileprop, h)

# compare the pointer in case of OpenMPI
if h == HDF5.Hmpih64
  c2 = unsafe_load(reinterpret(Ptr{Clong}, ccomm))
  c3 = unsafe_load(reinterpret(Ptr{Clong}, h5comm))
  #
  @test c2 == c3
end

# open file in parallel and write dataset
fn = String(MPI.bcast(collect(tempname()), 0, MPI.COMM_WORLD))
f = h5open(fn, "w", "fapl_mpio", (ccomm, cinfo) )
@test isopen(f)

g = g_create(f, "mygroup")
A = [ myrank + i for i = 1:10]
dset = d_create(g, "B", datatype(Int64), dataspace(10, nprocs), "chunk", (10, 1), "dxpl_mpio", HDF5.H5FD_MPIO_COLLECTIVE)
dset[:,myrank+1] = A
close(f)


MPI.Barrier(MPI.COMM_WORLD)
f = h5open(String(fn), "r", "fapl_mpio", (ccomm, cinfo))
@test isopen(f)
@test names(f) == ["mygroup"]
# read(f, name, pv...) is already taken by multi-dataset read, bool withargs is only dummy argument
B=read(f, "mygroup/B", true, "dxpl_mpio", HDF5.H5FD_MPIO_COLLECTIVE)
@test !isempty(B)
@test A == vec(B[:, myrank + 1])
B=f["mygroup/B", "dxpl_mpio", HDF5.H5FD_MPIO_COLLECTIVE]
@test !isempty(B)
@test A == vec(B[:, myrank + 1])
close(f)

MPI.Barrier(MPI.COMM_WORLD)
B = h5read(fn, "mygroup/B", "fapl_mpio", (ccomm, cinfo), "dxpl_mpio", HDF5.H5FD_MPIO_COLLECTIVE)
@test A == vec(B[:, myrank + 1])
MPI.Barrier(MPI.COMM_WORLD)
B = h5read(fn, "mygroup/B", (:, myrank + 1), "fapl_mpio", (ccomm, cinfo), "dxpl_mpio", HDF5.H5FD_MPIO_COLLECTIVE)
@test A == vec(B)

# we need to close HDF5 and finalize the info object before finalizing MPI
finalize(info)
HDF5.h5_close()
MPI.Barrier(MPI.COMM_WORLD)
MPI.Finalize()

end # testset mpio
