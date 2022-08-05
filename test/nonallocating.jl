using HDF5
using Test

@testset "non-allocating methods" begin
    fn = tempname()

    data = rand(UInt16, 16, 16)

    h5open(fn, "w") do h5f
        h5f["data"] = data
    end

    h5open(fn, "r") do h5f
        buffer = similar(h5f["data"])
        copyto!(buffer, h5f["data"])
        @test isequal(buffer, data)

        # Consider making this a view later
        v = h5f["data"][1:4, 1:4]

        buffer = similar(v)
        @test size(buffer) == (4, 4)
        copyto!(buffer, v)
        @test isequal(buffer, @view(data[1:4, 1:4]))

        @test size(similar(h5f["data"], Int16)) == size(h5f["data"])
        @test size(similar(h5f["data"], 5, 6)) == (5, 6)
        @test size(similar(h5f["data"], Int16, 8, 7)) == (8, 7)
        @test size(similar(h5f["data"], Int16, 8, 7; normalize=false)) == (8, 7)
        @test_broken size(similar(h5f["data"], Int8, 8, 7)) == (8, 7)

        @test size(similar(h5f["data"], (5, 6))) == (5, 6)
        @test size(similar(h5f["data"], Int16, (8, 7))) == (8, 7)
        @test size(similar(h5f["data"], Int16, (8, 7); normalize=false)) == (8, 7)
        @test size(similar(h5f["data"], Int16, 0x8, 0x7; normalize=false)) == (8, 7)
    end

    rm(fn)
end
