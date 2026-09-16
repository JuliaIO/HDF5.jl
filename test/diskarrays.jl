using HDF5
using Test
import DiskArrays

@testset "DiskArrays" begin
    fn = tempname()

    @testset "type identity" begin
        h5open(fn, "w") do f
            d = create_dataset(f, "int_chunked", datatype(Int), (4, 5); chunk=(2, 2))
            @test d isa DiskArrays.AbstractDiskArray{Int,2}
            @test d isa AbstractArray{Int,2}
            @test eltype(d) === Int
            @test ndims(d) == 2

            d2 = create_dataset(f, "float_contig", datatype(Float64), (3,))
            @test eltype(d2) === Float64
            @test ndims(d2) == 1

            f["str"] = "hello"
            # `eltype` reflects the *normalized* return type (what `read`/`getindex`
            # actually produce), not the raw memory-compatible type (`Cstring`).
            @test eltype(f["str"]) === String
        end
    end

    @testset "round-trip read/write, chunked and contiguous" begin
        h5open(fn, "w") do f
            data = reshape(1:20, 4, 5)
            d = create_dataset(f, "chunked", datatype(Int), (4, 5); chunk=(2, 2))
            d[:, :] = data
            @test d[:, :] == data
            @test d[1:2, 1:2] == data[1:2, 1:2]

            d2 = create_dataset(f, "contig", datatype(Float64), (10,))
            d2[:] = collect(1.0:10.0)
            @test d2[:] == collect(1.0:10.0)

            d3 = create_dataset(f, "compact", datatype(Int), (5,); layout=:compact)
            d3[:] = collect(1:5)
            @test d3[:] == collect(1:5)
        end
    end

    @testset "eachchunk / haschunks" begin
        h5open(fn, "r") do f
            d = f["chunked"]
            @test DiskArrays.haschunks(d) isa DiskArrays.Chunked
            ec = DiskArrays.eachchunk(d)
            @test size(ec) == HDF5.get_num_chunks_per_dim(d)

            d2 = f["contig"]
            @test DiskArrays.haschunks(d2) isa DiskArrays.Unchunked
        end
    end

    @testset "fancy indexing (new capability)" begin
        h5open(fn, "r") do f
            d = f["chunked"]
            mask = falses(4, 5)
            mask[1, 1] = true
            mask[3, 4] = true
            @test sort(d[mask]) == sort([d[1, 1], d[3, 4]])

            idxs = [CartesianIndex(1, 1), CartesianIndex(2, 2)]
            @test d[idxs] == [d[1, 1], d[2, 2]]

            v = view(d, 1:2, :)
            @test v == d[1:2, :]
        end
    end

    @testset "broadcasting / mapreduce" begin
        h5open(fn, "r") do f
            d = f["chunked"]
            @test sum(d) == sum(1:20)
        end
        h5open(fn, "r+") do f
            d = f["contig"]
            d[:] .= 2.0
            @test all(==(2.0), d[:])
        end
    end

    @testset "scalar-fill assignment (regression)" begin
        h5open(fn, "r+") do f
            d = create_dataset(f, "fillme", datatype(Int), (5,))
            d[1:3] = 5
            @test d[1:3] == [5, 5, 5]
            d[4:5] = 7
            @test d[:] == [5, 5, 5, 7, 7]
        end
    end

    @testset "show output unchanged" begin
        h5open(fn, "r") do f
            d = f["chunked"]
            str = sprint(show, MIME("text/plain"), d)
            @test occursin("HDF5.Dataset", str)
        end
    end

    @testset "null/scalar dataspace edge cases" begin
        h5open(fn, "r+") do f
            f["scalar"] = 42
            d = f["scalar"]
            @test size(d) == ()
            @test ndims(d) == 0
            @test eltype(d) === Int
            @test read(d) == 42
        end
    end

    @testset "ambiguity check" begin
        ambs = Test.detect_ambiguities(HDF5; recursive=true)
        # Filter out a pre-existing, unrelated ambiguity between two `@deprecate`d
        # `append!(::Filters.FilterPipeline, ...)` methods (src/deprecated.jl,
        # src/filters/filters.jl) that predates and is unrelated to the DiskArrays.jl
        # integration in this file.
        new_ambs = filter(((m1, m2),) -> !(m1.name === :append! && m2.name === :append!), ambs)
        @test isempty(new_ambs)
    end
end
