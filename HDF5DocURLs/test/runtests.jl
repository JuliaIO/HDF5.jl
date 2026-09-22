using HDF5DocURLs
using Test

@testset "HDF5DocURLs" begin
    @testset "func_url" begin
        @test func_url("H5Fopen") ==
            "https://support.hdfgroup.org/documentation/hdf5/latest/group___h5_f.html#gaa3f4f877b9bb591f3880423ed2bf44bc"
        @test startswith(func_url("H5Fopen"), "https://")
        @test func_url("NotARealFunctionName") == HDF5DocURLs.DEFAULT_URL
        @test func_url("NotARealFunctionName"; default="") == ""
    end

    @testset "group_url" begin
        @test startswith(group_url("H5F"), "https://")
        @test group_url("NotARealGroupName") == HDF5DocURLs.DEFAULT_URL
        @test group_url("NotARealGroupName"; default="") == ""
    end

    @testset "data loaded" begin
        @test length(HDF5DocURLs.FUNC_URLS) > 1000
        @test length(HDF5DocURLs.GROUP_URLS) > 100
    end

    @testset "compatibility-macro aliases resolve to a function-specific URL" begin
        # These bare, unnumbered C API names are the ones HDF5.jl binds directly for
        # pre-split libhdf5 releases (see the version tuples in gen/api_defs.jl); the
        # vendored tag file only documents their numbered successors as real functions.
        for (alias, target) in (
            "H5Dread_chunk" => "H5Dread_chunk1",
            "H5Lget_info" => "H5Lget_info1",
            "H5Literate" => "H5Literate1"
        )
            @test func_url(alias) == func_url(target)
            @test func_url(alias) != HDF5DocURLs.DEFAULT_URL
        end
    end
end
