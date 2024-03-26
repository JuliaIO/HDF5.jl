using Test, HDF5

@testset "virtual dataset" begin
    dirname = mktempdir()

    filename = joinpath(dirname, "main.hdf5")

    h5open(filename, "w") do f
        sub0 = joinpath(dirname, "sub-0.hdf5")
        f0 = h5open(sub0, "w")
        f0["x"] = fill(1.0, 3)
        close(f0)

        sub1 = joinpath(dirname, "sub-1.hdf5")
        f1 = h5open(sub1, "w")
        f1["x"] = fill(2.0, 3)
        close(f1)

        srcspace = dataspace((3,))
        vspace = dataspace((3, 2); max_dims=(3, -1))
        HDF5.select_hyperslab!(vspace, (1:3, HDF5.BlockRange(1; count=-1)))

        d = create_dataset(
            f,
            "x",
            datatype(Float64),
            vspace;
            virtual=[HDF5.VirtualMapping(vspace, "./sub-%b.hdf5", "x", srcspace)]
        )

        if Sys.iswindows()
            @test_broken size(d) == (3, 2)
            @test_broken read(d) == hcat(fill(1.0, 3), fill(2.0, 3))
        else
            @test size(d) == (3, 2)
            @test read(d) == hcat(fill(1.0, 3), fill(2.0, 3))
        end

        dcpl = HDF5.get_create_properties(d)

        @test dcpl.virtual isa HDF5.VirtualLayout
        @test length(dcpl.virtual) == 1
        @test dcpl.virtual[1] isa HDF5.VirtualMapping
    end
end
