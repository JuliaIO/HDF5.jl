using Random, Test, HDF5

@testset "reference" begin
    data = rand(100)

    fn = tempname()

    f = h5open(fn, "w")
    f["data"] = data
    f["data_ref"] = HDF5.Reference(f, "data")
    close(f)

    f = h5open(fn, "r")
    ref = read(f["data_ref"])
    dset = f[ref]
    data_read = read(dset)
    @test data == data_read
    close(f)

    rm(fn)
end
