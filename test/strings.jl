using Test
using HDF5

@testset "Strings" begin
    # Check creation of variable length string by passing String
    fn = tempname()
    h5open(fn, "w") do f
        ds = create_dataset(f, "strings", String, (4,))
        ds[1] = "Hello"
        ds[2] = "Hi"
        ds[3] = "Bonjour"
        ds[4] = GenericString("Hola")
    end
    h5open(fn, "r") do f
        ds = f["strings"]
        @test ds[1] == "Hello"
        @test ds[2] == "Hi"
        @test ds[3] == "Bonjour"
        @test ds[4] == "Hola"
    end
    rm(fn)

    # Check multiple assignment
    h5open(fn, "w") do f
        ds = create_dataset(f, "strings2", String, (3,))
        ds[:] = "Guten tag"
    end
    h5open(fn, "r") do f
        ds = f["strings2"]
        @test ds[1] == "Guten tag"
        @test ds[2] == "Guten tag"
        @test ds[3] == "Guten tag"
    end
    rm(fn)

    # Check assignment to a scalar dataset
    h5open(fn, "w") do f
        ds = write_dataset(f, "string", GenericString("Hi"))
    end
    h5open(fn) do f
        @test f["string"][] == "Hi"
    end
    rm(fn)
end
