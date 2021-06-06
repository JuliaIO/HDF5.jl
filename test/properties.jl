using HDF5
using Test

@testset "properties" begin

fn = tempname()
h5open(fn, "w";
       userblock = 1024,
       alignment = (0, sizeof(Int)),
       libver_bounds = (:earliest, :latest)
      ) do hfile
    # generic
    g = create_group(hfile, "group")
    d = create_dataset(g, "dataset", datatype(Int), dataspace((500,500)),
                 alloc_time = :early,
                 chunk = (5, 10),
                 deflate = 7,
                 track_times = false)
    attributes(d)["metadata"] = "test"

    flush(hfile)

    fcpl = HDF5.get_create_properties(hfile)
    fapl = HDF5.get_access_properties(hfile)
    gcpl = HDF5.get_create_properties(hfile["group"])
    dcpl = HDF5.get_create_properties(hfile["group/dataset"])
    acpl = HDF5.get_create_properties(attributes(hfile["group/dataset"])["metadata"])

    # Retrievability of properties
    @test isvalid(fcpl)
    @test isvalid(fapl)
    @test isvalid(gcpl)
    @test isvalid(dcpl)
    @test isvalid(acpl)

    # Retrieving property values:
    @test fcpl.userblock == 1024
    @test fcpl.track_times

    @test fapl.alignment == (0, sizeof(Int))
    @test fapl.driver == HDF5.Drivers.POSIX()
    # Docs say h5p_get_driver_info() doesn't error, but it does print an error message...
    #   https://portal.hdfgroup.org/display/HDF5/H5P_GET_DRIVER_INFO
    HDF5.silence_errors() do
        @test fapl.driver_info == C_NULL
    end
    @test fapl.fclose_degree == :strong
    @test fapl.libver_bounds == (:earliest, Base.thisminor(HDF5.libversion))

    @test gcpl.local_heap_size_hint == 0
    @test gcpl.track_times == true

    @test HDF5.UTF8_LINK_PROPERTIES[].char_encoding == :utf8
    @test HDF5.UTF8_LINK_PROPERTIES[].create_intermediate_group

    @test dcpl.alloc_time == :early
    @test dcpl.chunk == (5, 10)
    @test dcpl.layout == :chunked
    @test dcpl.track_times == false
    @test length(dcpl.filters) == 1
    @test dcpl.filters[1] == HDF5.Filters.Deflate(level=7)
          
    @test acpl.char_encoding == :utf8

    nothing
end

rm(fn, force=true)

end
