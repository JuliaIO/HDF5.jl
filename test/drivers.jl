using HDF5
import HDF5.Drivers
using Test

@testset "Drivers" begin
    fn = tempname()
    A = rand(UInt8, 256, 128)
    h5open(fn, "w"; driver=Drivers.Core()) do f
        ds = write_dataset(f, "core_dataset", A)
    end
    @test isfile(fn)
    h5open(fn, "r") do f
        @test f["core_dataset"][] == A
    end

    fn = tempname()
    file_image = h5open(fn, "w"; driver=Drivers.Core(; backing_store=false)) do f
        ds = write_dataset(f, "core_dataset", A)
        Vector{UInt8}(f)
    end
    @test !isfile(fn)

    h5open(file_image) do f
        @test f["core_dataset"][] == A
    end

    fn = tempname()
    h5open(fn, "r"; driver=Drivers.Core(; backing_store=false), file_image) do f
        @test f["core_dataset"][] == A
    end
end
