using Random, Test, HDF5

@testset "BlockRange" begin
    br = HDF5.BlockRange(2)
    @test length(br) == 1
    @test range(br) == 2:2

    br = HDF5.BlockRange(Base.OneTo(3))
    @test length(br) == 3
    @test range(br) == 1:3

    br = HDF5.BlockRange(2:7)
    @test length(br) == 6
    @test range(br) == 2:7

    br = HDF5.BlockRange(1:2:7)
    @test length(br) == 4
    @test range(br) == 1:2:7

    br = HDF5.BlockRange(; start=2, stride=8, block=2, count=3)
    @test length(br) == 6
    @test_throws Exception range(br)
end

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
