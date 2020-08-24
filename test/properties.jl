using HDF5
using Test

@testset "properties" begin

fn = tempname()
h5open(fn, "w") do hfile
    # generic
    g = g_create(hfile, "group")
    d = d_create(g, "dataset", datatype(Int), dataspace((1,1)))
    attrs(d)["metadata"] = "test"

    # datasets for allocation time tests
    d_create(hfile, "alloc_default", datatype(Int), dataspace((1,1)))
    d_create(hfile, "alloc_early",   datatype(Int), dataspace((1,1)),
             alloc_time = HDF5.H5D_ALLOC_TIME_EARLY)
end

h5open(fn, "r") do hfile
    # Retrievability of properties
    @test isvalid(get_create_properties(hfile))
    @test isvalid(get_create_properties(hfile["group"]))
    @test isvalid(get_create_properties(hfile["group"]["dataset"]))
    @test isvalid(get_create_properties(attrs(hfile["group"]["dataset"])["metadata"]))

    ## Test specific dataset creation properties
    @test HDF5.get_alloc_time(get_create_properties(hfile["alloc_default"])) == HDF5.H5D_ALLOC_TIME_LATE
    @test HDF5.get_alloc_time(get_create_properties(hfile["alloc_early"]))   == HDF5.H5D_ALLOC_TIME_EARLY
end

rm(fn, force=true)

end
