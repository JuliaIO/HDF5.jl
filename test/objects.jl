using Test
using HDF5
using HDF5.API

@testset "Object API" begin
    fn = tempname()

    # Write some data
    h5open(fn, "w") do h5f
        h5f["data"] = 5
        h5f["lore"] = 9.0
        attrs(h5f["lore"])["evil"] = true
    end

    # Read the data
    h5open(fn, "r") do h5f
        @test API.h5o_exists_by_name(h5f, "data")
        @test API.h5o_exists_by_name(h5f, "lore")
        @test_throws API.H5Error API.h5o_exists_by_name(h5f, "noonian")

        loc_id = API.h5o_open(h5f, "data", API.H5P_DEFAULT)
        try
            @test loc_id > 0
            oinfo = API.h5o_get_info(loc_id)
            @test oinfo.num_attrs == 0
            @test oinfo.type == API.H5O_TYPE_DATASET

            oinfo1 = API.h5o_get_info1(loc_id)
            @test oinfo1.num_attrs == 0
            @test oinfo1.type == API.H5O_TYPE_DATASET

            @static if HDF5.API.h5_get_libversion() >= v"1.12.0"
                oninfo = API.h5o_get_native_info(loc_id)
                @test oninfo.hdr.version > 0
                @test oninfo.hdr.nmesgs > 0
                @test oninfo.hdr.nchunks > 0
                @test oninfo.hdr.flags > 0
                @test oninfo.hdr.space.total > 0
                @test oninfo.hdr.space.meta > 0
                @test oninfo.hdr.space.mesg > 0
                @test oninfo.hdr.space.free > 0
                @test oninfo.hdr.mesg.present > 0
            end
        finally
            API.h5o_close(loc_id)
        end

        oinfo = API.h5o_get_info_by_name(h5f, ".")
        @test oinfo.type == API.H5O_TYPE_GROUP

        oinfo = API.h5o_get_info_by_name(h5f, "lore")
        @test oinfo.num_attrs == 1

        @static if HDF5.API.h5_get_libversion() >= v"1.12.0"
            oninfo = API.h5o_get_native_info_by_name(h5f, "lore")
            @test oninfo.hdr.version > 0
            @test oninfo.hdr.nmesgs > 0
            @test oninfo.hdr.nchunks > 0
            @test oninfo.hdr.flags > 0
            @test oninfo.hdr.space.total > 0
            @test oninfo.hdr.space.meta > 0
            @test oninfo.hdr.space.mesg > 0
            @test oninfo.hdr.space.free > 0
            @test oninfo.hdr.mesg.present > 0
        end

        oinfo = API.h5o_get_info_by_idx(h5f, ".", API.H5_INDEX_NAME, API.H5_ITER_INC, 0)
        @test oinfo.num_attrs == 0

        @static if HDF5.API.h5_get_libversion() >= v"1.12.0"
            oninfo = API.h5o_get_native_info_by_idx(
                h5f, ".", API.H5_INDEX_NAME, API.H5_ITER_INC, 1
            )
            @test oninfo.hdr.version > 0
            @test oninfo.hdr.nmesgs > 0
            @test oninfo.hdr.nchunks > 0
            @test oninfo.hdr.flags > 0
            @test oninfo.hdr.space.total > 0
            @test oninfo.hdr.space.meta > 0
            @test oninfo.hdr.space.mesg > 0
            @test oninfo.hdr.space.free > 0
            @test oninfo.hdr.mesg.present > 0
        end
    end
end
