using HDF5
using Test

@testset "Raw Chunk I/O" begin

fn = tempname()

# Direct chunk write is no longer dependent on HL library
# Test direct chunk writing Cartesian index
h5open(fn, "w") do f
    d = create_dataset(f, "dataset", datatype(Int), dataspace(4, 4), chunk=(2, 2))
    HDF5.API.h5d_extend(d, HDF5.API.hsize_t[3,3]) # should do nothing (deprecated call)
    HDF5.API.h5d_extend(d, HDF5.API.hsize_t[4,4]) # should do nothing (deprecated call)
    raw = HDF5.ChunkStorage(d)
    raw[1,1] = 0, collect(reinterpret(UInt8, [1,2,5,6]))
    raw[3,1] = 0, collect(reinterpret(UInt8, [3,4,7,8]))
    raw[1,3] = 0, collect(reinterpret(UInt8, [9,10,13,14]))
    raw[3,3] = 0, collect(reinterpret(UInt8, [11,12,15,16]))
end

# Test read back
@test h5open(fn, "r") do f
    vec(f["dataset"][:,:])
end == collect(1:16)

# Test reading direct chunks via linear indexing
h5open(fn, "r") do f
    d = f["dataset"]
    raw = HDF5.ChunkStorage{IndexLinear}(d)
    @test size(raw) == (4,)
    @test length(raw) == 4
    @test axes(raw) == (Base.OneTo(4),)
    @test prod(HDF5.get_num_chunks_per_dim(d)) == HDF5.get_num_chunks(d)
    if v"1.10.5" ≤ HDF5.API._libhdf5_build_ver
        @test HDF5.get_chunk_length(d) == HDF5.API.h5d_get_chunk_info(d,1)[:size]
    end
    @test reinterpret(Int, raw[1][2]) == [1,2,5,6]
    @test reinterpret(Int, raw[2][2]) == [3,4,7,8]
    @test reinterpret(Int, raw[3][2]) == [9,10,13,14]
    @test reinterpret(Int, raw[4][2]) == [11,12,15,16]
    # Test 0-based indexed API
    @test HDF5.get_chunk_offset(d, 0) == (0, 0)
    @test HDF5.get_chunk_offset(d, 1) == (2, 0)
    @test HDF5.get_chunk_offset(d, 2) == (0, 2)
    @test HDF5.get_chunk_offset(d, 3) == (2, 2)
    # Test reverse look up of index from coords
    @test HDF5.get_chunk_index(d, (0, 0)) == 0
    @test HDF5.get_chunk_index(d, (2, 0)) == 1
    @test HDF5.get_chunk_index(d, (0, 2)) == 2
    @test HDF5.get_chunk_index(d, (2, 2)) == 3
    # Test internal coordinates
    @test HDF5.get_chunk_index(d, (1, 1)) == 0
    @test HDF5.get_chunk_index(d, (3, 1)) == 1
    @test HDF5.get_chunk_index(d, (1, 3)) == 2
    @test HDF5.get_chunk_index(d, (3, 3)) == 3
end

# Test direct write chunk writing via linear indexing
h5open(fn, "w") do f
    d = create_dataset(f, "dataset", datatype(Int64), dataspace(4, 6), chunk=(2, 3))
    raw = HDF5.ChunkStorage{IndexLinear}(d)
    raw[1] = 0, collect(reinterpret(UInt8, Int64[1,2,5,6, 9,10]))
    raw[2] = 0, collect(reinterpret(UInt8, Int64[3,4,7,8,11,12]))
    raw[3] = 0, collect(reinterpret(UInt8, Int64[13,14,17,18,21,22]))
    raw[4] = 0, collect(reinterpret(UInt8, Int64[15,16,19,20,23,24]))
end

@test h5open(fn, "r") do f
    f["dataset"][:,:]
end == reshape(1:24, 4, 6)

h5open(fn, "r") do f
    d = f["dataset"]
    raw = HDF5.ChunkStorage(d)
    chunk = HDF5.get_chunk(d)
    extent = HDF5.get_extent_dims(d)[1]

    @test chunk == (2, 3)
    @test extent == (4, 6)
    @test size(raw) == (2, 2)
    @test length(raw) == 4
    @test axes(raw) == (1:2:4, 1:3:6)
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
    @test HDF5.get_chunk_index(d, (1, 1)) == 0
    @test HDF5.get_chunk_index(d, (3, 1)) == 1
    @test HDF5.get_chunk_index(d, (1, 4)) == 2
    @test HDF5.get_chunk_index(d, (3, 4)) == 3

    if v"1.10.5" ≤ HDF5.API._libhdf5_build_ver
        chunk_length = HDF5.get_chunk_length(d)
        origin = HDF5.API.h5d_get_chunk_info(d, 0)
        @test chunk_length == origin[:size]
        chunk_info = HDF5.API.h5d_get_chunk_info_by_coord(d, HDF5.API.hsize_t[0, 1])
        @test chunk_info[:filter_mask] == 0
        @test chunk_info[:size] == chunk_length

        # Test HDF5.get_chunk_offset equivalence to h5d_get_chunk_info information
        @test all(reverse(HDF5.API.h5d_get_chunk_info(d, 3)[:offset]) .== HDF5.get_chunk_offset(d, 3))

        # Test HDF5.get_chunk_index equivalence to h5d_get_chunk_info_by_coord information
        offset = HDF5.API.hsize_t[2,3]
        chunk_info = HDF5.API.h5d_get_chunk_info_by_coord(d, reverse(offset))
        @test HDF5.get_chunk_index(d, offset) == (chunk_info[:addr] - origin[:addr]) ÷ chunk_info[:size]

        @test HDF5.API.h5d_get_chunk_storage_size(d, HDF5.API.hsize_t[0, 1]) == chunk_length
        @test HDF5.API.h5d_get_storage_size(d) == sizeof(Int64)*24
        @test HDF5.API.h5d_get_space_status(d) == HDF5.API.H5D_SPACE_STATUS_ALLOCATED
    end

    # Manually reconstruct matrix
    A = Matrix{Int}(undef, extent)
    for (r,c) in Iterators.product(axes(raw)...)
        A[r:r+chunk[1]-1, c:c+chunk[2]-1] .= reshape( reinterpret(Int64, raw[r,c][2]), chunk)
    end
    @test A == reshape(1:24, extent)

end

h5open(fn, "w") do f
    d = create_dataset(f, "dataset", datatype(Int64), dataspace(4, 6), chunk=(2, 3))
    raw = HDF5.ChunkStorage(d)
    data = permutedims(reshape(1:24, 2, 2, 3, 2), (1,3,2,4))
    ci = CartesianIndices(raw)
    for ind in eachindex(ci)
        raw[ci[ind]] = data[:,:,ind]
    end
end

@test h5open(fn, "r") do f
    f["dataset"][:,:]
end == reshape(1:24, 4, 6)

# Test direct write chunk writing via linear indexing, using views and without filter flag
h5open(fn, "w") do f
    d = create_dataset(f, "dataset", datatype(Int64), dataspace(4, 6), chunk=(2, 3))
    raw = HDF5.ChunkStorage{IndexLinear}(d)
    data = permutedims(reshape(1:24, 2, 2, 3, 2), (1,3,2,4))
    chunks = Iterators.partition(data, 6)
    i = 1
    for c in chunks
        raw[i] = c
        i += 1
    end
end

@test h5open(fn, "r") do f
    f["dataset"][:,:]
end == reshape(1:24, 4, 6)

rm(fn)

end # testset "Raw Chunk I/O"
