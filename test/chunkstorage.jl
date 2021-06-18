using HDF5
using CRC32c
using Test

@testset "Raw Chunk I/O" begin

fn = tempname()

# Direct chunk write is no longer dependent on HL library
# Test direct chunk writing Cartesian index
h5open(fn, "w") do f
    d = create_dataset(f, "dataset", datatype(Int), dataspace(4, 4), chunk=(2, 2))
    HDF5.h5d_extend(d, HDF5.hsize_t[3,3]) # should do nothing (deprecated call)
    HDF5.h5d_extend(d, HDF5.hsize_t[4,4]) # should do nothing (deprecated call)
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
    @test HDF5.h5d_get_num_chunks(d) == HDF5.get_num_chunks(d)
    if v"1.10.5" ≤ HDF5._libhdf5_build_ver
        @test HDF5.get_chunk_length(d) == HDF5.h5d_get_chunk_info(d,1)[:size]
    end
    @test reinterpret(Int, raw[1][2]) == [1,2,5,6]
    @test reinterpret(Int, raw[2][2]) == [3,4,7,8]
    @test reinterpret(Int, raw[3][2]) == [9,10,13,14]
    @test reinterpret(Int, raw[4][2]) == [11,12,15,16]
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
    @test HDF5.h5d_get_num_chunks(d) == HDF5.get_num_chunks(d)
    if v"1.10.5" ≤ HDF5._libhdf5_build_ver
        chunk_length = HDF5.get_chunk_length(d)
        @test chunk_length == HDF5.h5d_get_chunk_info(d,1)[:size]
        chunk_info = HDF5.h5d_get_chunk_info_by_coord(d, HDF5.hsize_t[0, 1])
        @test chunk_info[:filter_mask] == 0
        @test chunk_info[:size] == chunk_length
        @test HDF5.h5d_get_chunk_storage_size(d, HDF5.hsize_t[0, 1]) == chunk_length
        @test HDF5.h5d_get_storage_size(d) == sizeof(Int64)*24
        @test HDF5.h5d_get_space_status(d) == HDF5.H5D_SPACE_STATUS_ALLOCATED
    end

    # Manually reconstruct matrix
    A = Matrix{Int}(undef, extent)
    for (r,c) in Iterators.product(axes(raw)...)
        A[r:r+chunk[1]-1, c:c+chunk[2]-1] .= reshape( reinterpret(Int64, raw[r,c][2]), chunk)
    end
    @test A == reshape(1:24, extent)

end

rm(fn)

end # testset "Raw Chunk I/O"

