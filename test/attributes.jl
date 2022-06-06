using HDF5, Test

@testset "attrs interface" begin
    filename = tempname()
    f = h5open(filename, "w")

    @test attrs(f) isa HDF5.AttributeDict

    attrs(f)["a"] = 1
    @test haskey(attrs(f), "a")
    @test attrs(f)["a"] == 1

    attrs(f)["b"] = [2,3]
    @test attrs(f)["b"] == [2,3]
    @test haskey(attrs(f), "a")
    @test length(attrs(f)) == 2
    @test sort(keys(attrs(f))) == ["a", "b"]

    @test !haskey(attrs(f), "c")

    # overwrite: same type
    attrs(f)["a"] = 4
    @test attrs(f)["a"] == 4
    @test get(attrs(f), "a", nothing) == 4
    @test length(attrs(f)) == 2
    @test sort(keys(attrs(f))) == ["a", "b"]

    # overwrite: different size
    attrs(f)["b"] = [4,5,6]
    @test attrs(f)["b"] == [4,5,6]
    @test length(attrs(f)) == 2
    @test sort(keys(attrs(f))) == ["a", "b"]

    # overwrite: different type
    attrs(f)["b"] = "a string"
    @test attrs(f)["b"] == "a string"
    @test length(attrs(f)) == 2
    @test sort(keys(attrs(f))) == ["a", "b"]

    # delete a key
    delete!(attrs(f), "a")
    @test !haskey(attrs(f), "a")
    @test length(attrs(f)) == 1
    @test sort(keys(attrs(f))) == ["b"]

    @test_throws KeyError attrs(f)["a"]
    @test isnothing(get(attrs(f), "a", nothing))
end