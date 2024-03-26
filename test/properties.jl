using HDF5
using Test

@testset "properties" begin
    fn = tempname()
    h5open(
        fn,
        "w";
        userblock=1024,
        alignment=(0, sizeof(Int)),
        libver_bounds=(:earliest, :latest),
        meta_block_size=1024,
        strategy=:fsm_aggr,
        persist=1,
        threshold=2,
        file_space_page_size=0x800
    ) do hfile
        # generic
        g = create_group(hfile, "group")
        if HDF5.API.h5_get_libversion() >= v"1.10.5"
            kwargs = (:no_attrs_hint => true,)
        else
            kwargs = ()
        end
        d = create_dataset(
            g,
            "dataset",
            datatype(Int),
            dataspace((500, 50));
            alloc_time=HDF5.API.H5D_ALLOC_TIME_EARLY,
            chunk=(5, 10),
            fill_value=1,
            fill_time=:never,
            obj_track_times=false,
            chunk_cache=(522, 0x200000, 0.80),
            efile_prefix=:origin,
            virtual_prefix="virtual",
            virtual_printf_gap=2,
            virtual_view=:last_available,
            kwargs...
        )
        attributes(d)["metadata"] = "test"

        flush(hfile)

        fcpl = HDF5.get_create_properties(hfile)
        fapl = HDF5.get_access_properties(hfile)
        gcpl = HDF5.get_create_properties(hfile["group"])
        dcpl = HDF5.get_create_properties(d)
        dapl = HDF5.get_access_properties(d)
        acpl = HDF5.get_create_properties(attributes(d)["metadata"])

        # Retrievability of properties
        @test isvalid(fcpl)
        @test isvalid(fapl)
        @test isvalid(gcpl)
        @test isvalid(dcpl)
        @test isvalid(dapl)
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
        @test fapl.libver_bounds ==
            (:earliest, HDF5.libver_bound_from_enum(HDF5.API.H5F_LIBVER_LATEST))
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

        @test dapl.chunk_cache.nslots == 522
        @test dapl.chunk_cache.nbytes == 0x200000
        @test dapl.chunk_cache.w0 == 0.8
        @test dapl.efile_prefix == raw"$ORIGIN"
        @test dapl.virtual_prefix == "virtual"
        # We probably need to actually use a virtual dataset
        @test_broken dapl.virtual_printf_gap == 2
        if HDF5.API.h5_get_libversion() >= v"1.14.0"
            @test dapl.virtual_view == :last_available
        else
            @test_broken dapl.virtual_view == :last_available
        end

        @test acpl.char_encoding == :utf8

        # Test auto-initialization of property lists on get
        dcpl2 = HDF5.DatasetCreateProperties() # uninitialized
        @test dcpl2.id < 1 # 0 or -1
        @test !isvalid(dcpl2)
        @test dcpl2.alloc_time == :late
        @test isvalid(dcpl2)

        # Test H5Pcopy
        dapl2 = copy(dapl)
        @test dapl2.id != dapl.id
        @test dapl2.virtual_prefix == dapl.virtual_prefix
        dapl2.virtual_prefix = "somewhere_else"
        @test dapl2.virtual_prefix != dapl.virtual_prefix

        nothing
    end

    file_image = read(fn)

    rm(fn; force=true)

    fapl = HDF5.FileAccessProperties()
    fapl.driver = HDF5.Drivers.Core(; backing_store=false)
    fapl.file_image = copy(file_image)
    @test fapl.file_image == file_image
    file_image2 = h5open(fn, "r"; fapl) do f
        @test haskey(f, "group")
        convert(Vector{UInt8}, f)
    end
    # file_image2 does not include user block
    @test file_image2 == @view(file_image[1025:end])

    rm(fn; force=true)
end
