using MPI
using HDF5
using Test

@testset "mpio" begin
    HDF5.FileAccessProperties() do fapl
        Drivers.set_driver!(fapl, Drivers.Core())
    end

    MPI.Init()

    comm = MPI.COMM_WORLD

    if !HDF5.has_parallel()
        @test_throws ErrorException(
            "HDF5.jl has no parallel support. Make sure that you're using MPI-enabled HDF5 libraries, and that MPI was loaded before HDF5. See HDF5.jl docs for details."
        ) HDF5.FileAccessProperties(driver=HDF5.Drivers.MPIO(comm))
    else
        nprocs = MPI.Comm_size(comm)
        myrank = MPI.Comm_rank(comm)

        # Check that serial drivers are still there after loading MPI (#928)
        @test Drivers.Core ∈ values(Drivers.DRIVERS)
        @test Drivers.POSIX ∈ values(Drivers.DRIVERS)

        let fileprop = HDF5.FileAccessProperties()
            fileprop.driver = HDF5.Drivers.MPIO(comm)
            driver = fileprop.driver
            h5comm = driver.comm
            h5info = driver.info

            # check that the two communicators point to the same group
            if isdefined(MPI, :Comm_compare)  # requires recent MPI.jl version
                @test MPI.Comm_compare(comm, h5comm) == MPI.CONGRUENT
            end
            HDF5.close(fileprop)
        end

        # open file in parallel and write dataset
        fn = MPI.bcast(tempname(), 0, comm)
        A = [myrank + i for i in 1:10]
        h5open(fn, "w", comm) do f
            @test isopen(f)
            g = create_group(f, "mygroup")
            dset = create_dataset(
                g,
                "B",
                datatype(Int64),
                dataspace(10, nprocs);
                chunk=(10, 1),
                dxpl_mpio=:collective
            )
            dset[:, myrank + 1] = A
        end

        MPI.Barrier(comm)
        h5open(fn, comm) do f  # default: opened in read mode, with default MPI.Info()
            @test isopen(f)
            @test keys(f) == ["mygroup"]

            B = read(f, "mygroup/B"; dxpl_mpio=:collective)
            @test !isempty(B)
            @test A == vec(B[:, myrank + 1])

            B = f["mygroup/B", dxpl_mpio=:collective]
            @test !isempty(B)
            @test A == vec(B[:, myrank + 1])
        end

        MPI.Barrier(comm)

        B = h5read(fn, "mygroup/B"; driver=HDF5.Drivers.MPIO(comm), dxpl_mpio=:collective)
        @test A == vec(B[:, myrank + 1])

        MPI.Barrier(comm)

        B = h5read(
            fn,
            "mygroup/B",
            (:, myrank + 1);
            driver=HDF5.Drivers.MPIO(comm),
            dxpl_mpio=:collective
        )
        @test A == vec(B)
    end

    MPI.Finalize()
end # testset mpio
