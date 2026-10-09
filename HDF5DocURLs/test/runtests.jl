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

    @testset "anchor_url" begin
        @test anchor_url("subsec_dataspace_select") ==
            "https://support.hdfgroup.org/documentation/hdf5/latest/_h5_s__u_g.html#subsec_dataspace_select"
        @test anchor_url("not_an_anchor") == HDF5DocURLs.DEFAULT_URL
        @test anchor_url("not_an_anchor"; default="") == ""
        @test length(HDF5DocURLs.ANCHOR_URLS) > 1000
        # whole pages come from group_url
        @test endswith(group_url("IntroParHDF5"), "_intro_par_h_d_f5.html")
        @test endswith(group_url("SWMRTN"), "_s_w_m_r_t_n.html")
    end

    @testset "filter_url / filter_name" begin
        @test filter_url(307) == HDF5DocURLs.REGISTRY_URL * "#bzip2"
        @test filter_url(32001) == HDF5DocURLs.REGISTRY_URL * "#blosc"
        @test filter_url(UInt16(32004)) == HDF5DocURLs.REGISTRY_URL * "#lz4"
        @test filter_url(32008) == HDF5DocURLs.REGISTRY_URL * "#bitshuffle"
        @test filter_url(32015) == HDF5DocURLs.REGISTRY_URL * "#zstandard"
        @test filter_url(1) == func_url("H5Pset_deflate")
        @test filter_url(2) == func_url("H5Pset_shuffle")
        @test filter_url(999999) == HDF5DocURLs.REGISTRY_URL
        @test filter_url(999999; default="") == ""
        @test filter_name(307) == "BZIP2"
        @test filter_name(1) == "deflate"
        @test filter_name(999999) === nothing
        @test length(HDF5DocURLs.FILTERS) > 30
    end

    @testset "external_url" begin
        @test external_url(:registered_filters) == HDF5DocURLs.REGISTRY_URL
        @test startswith(external_url(:plugins_repo), "https://github.com/HDFGroup/")
        @test_throws ArgumentError external_url(:nonexistent)
    end
end
