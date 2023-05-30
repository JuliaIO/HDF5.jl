using HDF5
using Test

@testset "Raw Chunk I/O" begin
    fn = tempname()

    # Direct chunk write is no longer dependent on HL library
    # Test direct chunk writing Cartesian index
    h5open(fn, "w") do f
        d = create_dataset(f, "dataset", datatype(Int), dataspace(4, 5); chunk=(2, 2))
        HDF5.API.h5d_extend(d, HDF5.API.hsize_t[3, 3]) # should do nothing (deprecated call)
        HDF5.API.h5d_extend(d, HDF5.API.hsize_t[4, 4]) # should do nothing (deprecated call)
        raw = HDF5.ChunkStorage(d)
        raw[1, 1] = 0, collect(reinterpret(UInt8, [1, 2, 5, 6]))
        raw[3, 1] = 0, collect(reinterpret(UInt8, [3, 4, 7, 8]))
        raw[1, 3] = 0, collect(reinterpret(UInt8, [9, 10, 13, 14]))
        raw[3, 3] = 0, collect(reinterpret(UInt8, [11, 12, 15, 16]))
        raw[1, 5] = 0, collect(reinterpret(UInt8, [17, 18, 21, 22]))
        raw[3, 5] = 0, collect(reinterpret(UInt8, [19, 20, 23, 24]))
    end

    # Test read back
    @test h5open(fn, "r") do f
        vec(f["dataset"][:, :])
    end == collect(1:20)

    # Test reading direct chunks via linear indexing
    h5open(fn, "r") do f
        d = f["dataset"]
        raw = HDF5.ChunkStorage{IndexLinear}(d)
        @test size(raw) == (6,)
        @test length(raw) == 6
        @test axes(raw) == (Base.OneTo(6),)
        @test prod(HDF5.get_num_chunks_per_dim(d)) == HDF5.get_num_chunks(d)
        if v"1.10.5" ≤ HDF5.API._libhdf5_build_ver
            @test HDF5.get_chunk_length(d) == HDF5.API.h5d_get_chunk_info(d, 1)[:size]
        end
        @test reinterpret(Int, raw[1][2]) == [1, 2, 5, 6]
        @test reinterpret(Int, raw[2][2]) == [3, 4, 7, 8]
        @test reinterpret(Int, raw[3][2]) == [9, 10, 13, 14]
        @test reinterpret(Int, raw[4][2]) == [11, 12, 15, 16]
        @test reinterpret(Int, raw[5][2])[1:2] == [17, 18]
        @test reinterpret(Int, raw[6][2])[1:2] == [19, 20]
        # Test 0-based indexed API
        @test HDF5.get_chunk_offset(d, 0) == (0, 0)
        @test HDF5.get_chunk_offset(d, 1) == (2, 0)
        @test HDF5.get_chunk_offset(d, 2) == (0, 2)
        @test HDF5.get_chunk_offset(d, 3) == (2, 2)
        @test HDF5.get_chunk_offset(d, 4) == (0, 4)
        @test HDF5.get_chunk_offset(d, 5) == (2, 4)
        # Test reverse look up of index from coords
        @test HDF5.get_chunk_index(d, (0, 0)) == 0
        @test HDF5.get_chunk_index(d, (2, 0)) == 1
        @test HDF5.get_chunk_index(d, (0, 2)) == 2
        @test HDF5.get_chunk_index(d, (2, 2)) == 3
        @test HDF5.get_chunk_index(d, (0, 4)) == 4
        @test HDF5.get_chunk_index(d, (2, 4)) == 5
        # Test internal coordinates
        @test HDF5.get_chunk_index(d, (0, 1)) == 0
        @test HDF5.get_chunk_index(d, (1, 0)) == 0
        @test HDF5.get_chunk_index(d, (1, 1)) == 0
        @test HDF5.get_chunk_index(d, (3, 1)) == 1
        @test HDF5.get_chunk_index(d, (1, 3)) == 2
        @test HDF5.get_chunk_index(d, (3, 3)) == 3
        @test HDF5.get_chunk_index(d, (1, 5)) == 4
        @test HDF5.get_chunk_index(d, (2, 5)) == 5
        @test HDF5.get_chunk_index(d, (3, 4)) == 5
        @test HDF5.get_chunk_index(d, (3, 5)) == 5
        # Test chunk iter
        if v"1.12.3" ≤ HDF5.API._libhdf5_build_ver
            infos = HDF5.get_chunk_info_all(d)
            offsets = [info.offset for info in infos]
            addrs = [info.addr for info in infos]
            filter_masks = [info.filter_mask for info in infos]
            sizes = [info.size for info in infos]
            @test isempty(
                setdiff(offsets, [(0, 0), (2, 0), (0, 2), (2, 2), (0, 4), (2, 4)])
            )
            @test length(unique(addrs)) == 6
            @test only(unique(filter_masks)) === UInt32(0)
            @test only(unique(sizes)) == 4 * sizeof(Int)
        end
    end

    # Test direct write chunk writing via linear indexing
    h5open(fn, "w") do f
        d = create_dataset(f, "dataset", datatype(Int64), dataspace(4, 5); chunk=(2, 3))
        raw = HDF5.ChunkStorage{IndexLinear}(d)
        raw[1] = 0, collect(reinterpret(UInt8, Int64[1, 2, 5, 6, 9, 10]))
        raw[2] = 0, collect(reinterpret(UInt8, Int64[3, 4, 7, 8, 11, 12]))
        raw[3] = 0, collect(reinterpret(UInt8, Int64[13, 14, 17, 18, 21, 22]))
        raw[4] = 0, collect(reinterpret(UInt8, Int64[15, 16, 19, 20, 23, 24]))
    end

    @test h5open(fn, "r") do f
        f["dataset"][:, :]
    end == reshape(1:20, 4, 5)

    h5open(fn, "r") do f
        d = f["dataset"]
        raw = HDF5.ChunkStorage(d)
        chunk = HDF5.get_chunk(d)
        extent = HDF5.get_extent_dims(d)[1]

        @test chunk == (2, 3)
        @test extent == (4, 5)
        @test size(raw) == (2, 2)
        @test length(raw) == 4
        @test axes(raw) == (1:2:4, 1:3:5)
        @test prod(HDF5.get_num_chunks_per_dim(d)) == HDF5.get_num_chunks(d)

        # Test 0-based indexed API
        @test HDF5.get_chunk_offset(d, 0) == (0, 0)
        @test HDF5.get_chunk_offset(d, 1) == (2, 0)
        @test HDF5.get_chunk_offset(d, 2) == (0, 3)
        @test HDF5.get_chunk_offset(d, 3) == (2, 3)
        # Test reverse look up of index from coords
        @test HDF5.get_chunk_index(d, (0, 0)) == 0
        @test HDF5.get_chunk_index(d, (2, 0)) == 1
        @test HDF5.get_chunk_index(d, (0, 3)) == 2
        @test HDF5.get_chunk_index(d, (2, 3)) == 3
        # Test internal coordinates
        @test HDF5.get_chunk_index(d, (0, 1)) == 0
        @test HDF5.get_chunk_index(d, (0, 2)) == 0
        @test HDF5.get_chunk_index(d, (1, 0)) == 0
        @test HDF5.get_chunk_index(d, (1, 1)) == 0
        @test HDF5.get_chunk_index(d, (1, 2)) == 0
        @test HDF5.get_chunk_index(d, (3, 1)) == 1
        @test HDF5.get_chunk_index(d, (1, 4)) == 2
        @test HDF5.get_chunk_index(d, (2, 4)) == 3
        @test HDF5.get_chunk_index(d, (2, 5)) == 3
        @test HDF5.get_chunk_index(d, (3, 3)) == 3
        @test HDF5.get_chunk_index(d, (3, 4)) == 3
        @test HDF5.get_chunk_index(d, (3, 5)) == 3

        if v"1.10.5" ≤ HDF5.API._libhdf5_build_ver
            chunk_length = HDF5.get_chunk_length(d)
            origin = HDF5.API.h5d_get_chunk_info(d, 0)
            @test chunk_length == origin[:size]
            chunk_info = HDF5.API.h5d_get_chunk_info_by_coord(d, HDF5.API.hsize_t[0, 1])
            @test chunk_info[:filter_mask] == 0
            @test chunk_info[:size] == chunk_length

            # Test HDF5.get_chunk_offset equivalence to h5d_get_chunk_info information
            @test all(
                reverse(HDF5.API.h5d_get_chunk_info(d, 3)[:offset]) .==
                HDF5.get_chunk_offset(d, 3)
            )

            # Test HDF5.get_chunk_index equivalence to h5d_get_chunk_info_by_coord information
            offset = HDF5.API.hsize_t[2, 3]
            chunk_info = HDF5.API.h5d_get_chunk_info_by_coord(d, reverse(offset))
            @test HDF5.get_chunk_index(d, offset) ==
                fld(chunk_info[:addr] - origin[:addr], chunk_info[:size])

            @test HDF5.API.h5d_get_chunk_storage_size(d, HDF5.API.hsize_t[0, 1]) ==
                chunk_length
            @test HDF5.API.h5d_get_storage_size(d) == sizeof(Int64) * 24
            if v"1.12.2" ≤ HDF5.API._libhdf5_build_ver
                @test HDF5.API.h5d_get_space_status(d) ==
                    HDF5.API.H5D_SPACE_STATUS_ALLOCATED
            else
                @test HDF5.API.h5d_get_space_status(d) ==
                    HDF5.API.H5D_SPACE_STATUS_PART_ALLOCATED
            end
        end

        # Manually reconstruct matrix
        A = Matrix{Int}(undef, extent)
        for (r1, c1) in Iterators.product(axes(raw)...)
            r2 = min(extent[1], r1 + chunk[1] - 1)
            c2 = min(extent[2], c1 + chunk[2] - 1)
            dims = (r2 - r1 + 1, c2 - c1 + 1)
            bytes = 8 * prod(dims)
            A[r1:r2, c1:c2] .= reshape(reinterpret(Int64, raw[r1, c1][2][1:bytes]), dims)
        end
        @test A == reshape(1:20, extent)
    end

    @static if VERSION >= v"1.6"
        # CartesianIndices does not accept StepRange

        h5open(fn, "w") do f
            d = create_dataset(f, "dataset", datatype(Int), dataspace(4, 5); chunk=(2, 3))
            raw = HDF5.ChunkStorage(d)
            data = permutedims(reshape(1:24, 2, 2, 3, 2), (1, 3, 2, 4))
            ci = CartesianIndices(raw)
            for ind in eachindex(ci)
                raw[ci[ind]] = data[:, :, ind]
            end
        end

        @test h5open(fn, "r") do f
            f["dataset"][:, :]
        end == reshape(1:20, 4, 5)
    end

    # Test direct write chunk writing via linear indexing, using views and without filter flag
    h5open(fn, "w") do f
        d = create_dataset(f, "dataset", datatype(Int), dataspace(4, 5); chunk=(2, 3))
        raw = HDF5.ChunkStorage{IndexLinear}(d)
        data = permutedims(reshape(1:24, 2, 2, 3, 2), (1, 3, 2, 4))
        chunks = Iterators.partition(data, 6)
        i = 1
        for c in chunks
            raw[i] = c
            i += 1
        end
    end

    @test h5open(fn, "r") do f
        f["dataset"][:, :]
    end == reshape(1:20, 4, 5)

    # Test chunk info retrieval method performance
    h5open(fn, "w") do f
        d = create_dataset(
            f,
            "dataset",
            datatype(UInt8),
            dataspace(256, 256);
            chunk=(16, 16),
            alloc_time=:early
        )
        if v"1.10.5" ≤ HDF5.API._libhdf5_build_ver
            HDF5._get_chunk_info_all_by_index(d)
            index_time = @elapsed infos_by_index = HDF5._get_chunk_info_all_by_index(d)
            @test length(infos_by_index) == 256
            iob = IOBuffer()
            show(iob, MIME"text/plain"(), infos_by_index)
            seekstart(iob)
            @test length(readlines(iob)) == 259
            if v"1.12.3" ≤ HDF5.API._libhdf5_build_ver
                HDF5._get_chunk_info_all_by_iter(d)
                iter_time = @elapsed infos_by_iter = HDF5._get_chunk_info_all_by_iter(d)
                @test infos_by_iter == infos_by_index
                @test iter_time < index_time
            end
        end
    end
    rm(fn)
end # testset "Raw Chunk I/O"
