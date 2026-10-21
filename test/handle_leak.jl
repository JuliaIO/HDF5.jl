using HDF5
using Test

# Number of open datatype identifiers across all files
n_open_datatypes() = HDF5.API.h5f_get_obj_count(HDF5.API.H5F_OBJ_ALL, HDF5.API.H5F_OBJ_DATATYPE)

@testset "handle leak" begin
    # Disable GC so that finalizers cannot hide a leaked identifier
    GC.enable(false)
    try
        fn = tempname()
        x = rand(10)

        @testset "read_dataset/write_dataset keep no handles open" begin
            h5open(fn, "w") do f
                dset, dtype = create_dataset(f, "x", x)
                before = n_open_datatypes()
                for _ in 1:100
                    HDF5.write_dataset(dset, dtype, x)
                    HDF5.read_dataset(dset, dtype, similar(x))
                end
                @test n_open_datatypes() == before
                close(dtype)
                close(dset)
            end
        end

        @testset "no handles leak across closed files" begin
            before = n_open_datatypes()
            for i in 1:20
                h5open(fn, "w") do f
                    write_dataset(f, "x", x)
                    @test read(f, "x") == x
                end
            end
            @test n_open_datatypes() == before
        end

        rm(fn; force=true)
    finally
        GC.enable(true)
    end
end
