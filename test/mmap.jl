using HDF5
using Test

@testset "mmap" begin

    # Create a new file
    fn = tempname()
    f = h5open(fn, "w")
    @test isopen(f)

    # Create two datasets, one with late allocation (the default for contiguous
    # datasets) and the other with explicit early allocation.
    hdf5_A = create_dataset(f, "A", datatype(Int64), dataspace(3, 3))
    hdf5_B = create_dataset(
        f, "B", datatype(Float64), dataspace(3, 3); alloc_time=HDF5.API.H5D_ALLOC_TIME_EARLY
    )
    # The late case cannot be mapped yet.
    @test_throws ErrorException("Error getting offset") HDF5.readmmap(f["A"])
    # Then write and fill dataset A, making it mappable. B was filled with 0.0 at
    # creation.
    A = rand(Int64, 3, 3)
    hdf5_A[:, :] = A
    flush(f)
    close(f)
    # Read HDF5 file & MMAP
    f = h5open(fn, "r")
    A_mmaped = HDF5.readmmap(f["A"])
    @test all(A .== A_mmaped)
    @test all(iszero, HDF5.readmmap(f["B"]))
    # Check that it is read only
    @test_throws ReadOnlyMemoryError A_mmaped[1, 1] = 33
    close(f)
    # Now check if we can write
    f = h5open(fn, "r+")
    A_mmaped = HDF5.readmmap(f["A"])
    A_mmaped[1, 1] = 33
    close(f)

    # issue #863 - fix mmapping complex arrays
    fn = tempname()
    f = h5open(fn, "w")
    A = rand(ComplexF32, 5, 5)
    f["A"] = A
    close(f)
    f = h5open(fn, "r+")
    complex_support = HDF5.COMPLEX_SUPPORT[]
    # Complex arrays can be mmapped when complex support is enabled
    complex_support || HDF5.enable_complex_support()
    @test A == read(f["A"])
    @test A == HDF5.readmmap(f["A"])
    # But mmapping should throw an error when support is disabled
    HDF5.disable_complex_support()
    At = [(r=real(c), i=imag(c)) for c in A]
    @test read(f["A"]) == At # readable as array of NamedTuples
    @test_throws ErrorException("Cannot mmap datasets of type $(eltype(At))") HDF5.readmmap(
        f["A"]
    )
    close(f)
    # Restore complex support state
    complex_support && HDF5.enable_complex_support()
end # testset
