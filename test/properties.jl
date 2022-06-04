using HDF5
using Test

@testset "properties" begin

fn = tempname()
h5open(fn, "w";
       userblock = 1024,
       alignment = (0, sizeof(Int)),
       libver_bounds = (:earliest, :latest),
       meta_block_size = 1024,
       strategy = :fsm_aggr,
       persist = 1,
       threshold = 2,
       file_space_page_size = 0x800
      ) do hfile
    # generic
    g = create_group(hfile, "group")
    if HDF5.API.h5_get_libversion() >= v"1.10.5"
      kwargs = (:no_attrs_hint => true,)
    else
      kwargs = ()
    end
    d = create_dataset(g, "dataset", datatype(Int), dataspace((500,50));
                 alloc_time = HDF5.API.H5D_ALLOC_TIME_EARLY,
                 chunk = (5, 10),
                 fill_value = 1,
                 fill_time = :never,
                 obj_track_times = false,
                 kwargs...)
    attrs(d)["metadata"] = "test"

    flush(hfile)

    fcpl = HDF5.get_create_properties(hfile)
    fapl = HDF5.get_access_properties(hfile)
    gcpl = HDF5.get_create_properties(hfile["group"])
    dcpl = HDF5.get_create_properties(hfile["group/dataset"])
    acpl = HDF5.get_create_properties(open_attribute(hfile["group/dataset"], "metadata"))

    # Retrievability of properties
    @test isvalid(fcpl)
    @test isvalid(fapl)
    @test isvalid(gcpl)
    @test isvalid(dcpl)
    @test isvalid(acpl)

    # Retrieving property values:
    @test fcpl.userblock == 1024
    @test fcpl.obj_track_times
    @test fcpl.file_space_page_size == 0x800
    @test fcpl.strategy == :fsm_aggr
    @test fcpl.persist == 1
    @test fcpl.threshold == 2

    @test fapl.alignment == (0, sizeof(Int))
    @test fapl.driver == Drivers.POSIX()
    @test_throws HDF5.API.H5Error fapl.driver_info
    @test fapl.fclose_degree == :strong
    @test fapl.libver_bounds == (:earliest, Base.thisminor(HDF5.libversion))
    @test fapl.meta_block_size == 1024

    @test gcpl.local_heap_size_hint == 0
    @test gcpl.obj_track_times

    @test HDF5.UTF8_LINK_PROPERTIES.char_encoding == :utf8
    @test HDF5.UTF8_LINK_PROPERTIES.create_intermediate_group

    @test dcpl.alloc_time == :early
    @test dcpl.chunk == (5, 10)
    @test dcpl.layout == :chunked
    @test !dcpl.obj_track_times
    @test dcpl.fill_time == :never
    @test dcpl.fill_value == 1.0
    if HDF5.API.h5_get_libversion() >= v"1.10.5"
      @test dcpl.no_attrs_hint == true
    end

    @test acpl.char_encoding == :utf8

    nothing
end

rm(fn, force=true)

end
