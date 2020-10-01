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
    end
end
