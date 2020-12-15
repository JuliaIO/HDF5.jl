using HDF5
using Test

@testset "properties" begin

fn = tempname()
h5open(fn, "w";
       userblock = 1024,
       alignment = (0, sizeof(Int)),
       libver_bounds = (HDF5.H5F_LIBVER_EARLIEST, HDF5.H5F_LIBVER_LATEST),
      ) do hfile
    # generic
    g = create_group(hfile, "group")
    d = create_dataset(g, "dataset", datatype(Int), dataspace((500,500)),
                 alloc_time = HDF5.H5D_ALLOC_TIME_EARLY,
                 chunk = (5, 10),
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
    @test fcpl[:userblock] == 1024
    @test fcpl[:track_times] == true

    @test fapl[:alignment] == (0, sizeof(Int))
    # value is H5FD_SEC2, but "constant" is runtime value not loadable by _read_const()
    @test HDF5.h5i_get_type(fapl[:driver]) == HDF5.H5I_VFL
    # Docs say h5p_get_driver_info() doesn't error, but it does print an error message...
    #   https://portal.hdfgroup.org/display/HDF5/H5P_GET_DRIVER_INFO
    HDF5.silence_errors() do
        @test fapl[:driver_info] == C_NULL
    end
    @test fapl[:fclose_degree] == HDF5.H5F_CLOSE_STRONG
    @test fapl[:libver_bounds] == (HDF5.H5F_LIBVER_EARLIEST, HDF5.H5F_LIBVER_LATEST)

    @test gcpl[:local_heap_size_hint] == 0
    @test gcpl[:track_times] == true

    @test HDF5.UTF8_LINK_PROPERTIES[][:char_encoding] == HDF5.H5T_CSET_UTF8
    @test HDF5.UTF8_LINK_PROPERTIES[][:create_intermediate_group] == 1

    @test dcpl[:alloc_time] == HDF5.H5D_ALLOC_TIME_EARLY
    @test dcpl[:chunk] == (5, 10)
    @test dcpl[:layout] == HDF5.H5D_CHUNKED
    @test dcpl[:track_times] == false

    @test acpl[:char_encoding] == HDF5.H5T_CSET_UTF8

    nothing
end

rm(fn, force=true)

end
