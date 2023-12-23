using Random, Test, HDF5

@testset "hyperslab" begin
    N = 10
    v = [randstring(rand(5:10)) for i in 1:N, j in 1:N]

    fn = tempname()
    h5open(fn, "w") do f
        f["data"] = v
    end

    h5open(fn, "r") do f
        dset = f["data"]
        indices = (1, 1)
        @test dset[indices...] == v[indices...]

        indices = (1:10, 1)
        @test dset[indices...] == v[indices...]

        indices = (1, 1:10)
        @test dset[indices...] == v[indices...]

        indices = (1:2:10, 1:3:10)
        @test dset[indices...] == v[indices...]

        indices = (
            HDF5.BlockRange(1:2; stride=4, count=2), HDF5.BlockRange(1; stride=5, count=2)
        )
        @test dset[indices...] == vcat(v[1:2, 1:5:6], v[5:6, 1:5:6])
    end
end

@testset "read 0-length arrays: issue #859" begin
    fname = tempname()
    dsetname = "foo"

    h5open(fname, "w") do fid
        create_dataset(fid, dsetname, datatype(Float32), ((0,), (-1,)); chunk=(100,))
    end

    h5open(fname, "r") do fid
        fid[dsetname][:]
    end
end
