using HDF5, Test

function test_attrs(o::Union{HDF5.File,HDF5.Object})
    @test attrs(o) isa HDF5.AttributeDict

    attrs(o)["a"] = 1
    @test haskey(attrs(o), "a")
    @test attrs(o)["a"] == 1

    attrs(o)["b"] = [2, 3]
    @test attrs(o)["b"] == [2, 3]
    @test haskey(attrs(o), "a")
    @test length(attrs(o)) == 2
    @test sort(keys(attrs(o))) == ["a", "b"]

    @test !haskey(attrs(o), "c")

    # overwrite: same type
    attrs(o)["a"] = 4
    @test attrs(o)["a"] == 4
    @test get(attrs(o), "a", nothing) == 4
    @test length(attrs(o)) == 2
    @test sort(keys(attrs(o))) == ["a", "b"]

    # overwrite: different size
    attrs(o)["b"] = [4, 5, 6]
    @test attrs(o)["b"] == [4, 5, 6]
    @test length(attrs(o)) == 2
    @test sort(keys(attrs(o))) == ["a", "b"]

    # overwrite: different type
    attrs(o)["b"] = "a string"
    @test attrs(o)["b"] == "a string"
    @test length(attrs(o)) == 2
    @test sort(keys(attrs(o))) == ["a", "b"]

    # delete a key
    delete!(attrs(o), "a")
    @test !haskey(attrs(o), "a")
    @test length(attrs(o)) == 1
    @test sort(keys(attrs(o))) == ["b"]

    @test_throws KeyError attrs(o)["a"]
    @test isnothing(get(attrs(o), "a", nothing))
end

@testset "attrs interface" begin
    filename = tempname()
    f = h5open(filename, "w")

    try
        # Test attrs on a HDF5.File
        test_attrs(f)

        # Test attrs on a HDF5.Group
        g = create_group(f, "group_foo")
        test_attrs(g)

        # Test attrs on a HDF5.Dataset
        d = create_dataset(g, "dataset_bar", Int, (32, 32))
        test_attrs(d)

        # Test attrs on a HDF5.Datatype
        t = commit_datatype(
            g, "datatype_int16", HDF5.Datatype(HDF5.API.h5t_copy(HDF5.API.H5T_NATIVE_INT16))
        )
        test_attrs(t)
    finally
        close(f)
    end
end

@testset "variable length strings" begin
    filename = tempname()
    h5open(filename, "w") do f
        # https://github.com/JuliaIO/HDF5.jl/issues/1129
        attr = create_attribute(f, "attr-name", datatype(String), dataspace(String))
        write_attribute(attr, datatype(String), "attr-value")
        @test attrs(f)["attr-name"] == "attr-value"
    end
end
