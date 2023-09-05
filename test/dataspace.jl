using HDF5
using Test

@testset "null dataspace" begin
    ds_null = HDF5.Dataspace()

    @test isvalid(ds_null)
    @test HDF5.isnull(ds_null)
    @test isempty(ds_null)

    @test length(ds_null) === 0
    @test ndims(ds_null) === 0
    @test size(ds_null) === ()
    @test size(ds_null, 5) === 1

    @test HDF5.get_extent_dims(ds_null) === ((), ())

    @test Dataspace() == ds_null
    @test dataspace(nothing) == ds_null
    @test dataspace(HDF5.EmptyArray{Bool}()) == ds_null

    @test repr(ds_null) == "HDF5.Dataspace(): null dataspace"
end

@testset "scalar dataspace" begin
    ds_scalar = HDF5.Dataspace(())

    @test isvalid(ds_scalar)
    @test !HDF5.isnull(ds_scalar)
    @test !isempty(ds_scalar)

    @test length(ds_scalar) === 1
    @test ndims(ds_scalar) === 0
    @test size(ds_scalar) === ()
    @test size(ds_scalar, 5) === 1

    @test HDF5.get_extent_dims(ds_scalar) === ((), ())

    @test Dataspace() != ds_scalar
    @test Dataspace(()) == ds_scalar

    @test dataspace(fill(1.0)) == ds_scalar
    @test dataspace(1) == ds_scalar
    @test dataspace(1 + 1im) == ds_scalar
    @test dataspace("string") == ds_scalar

    @test repr(ds_scalar) == "HDF5.Dataspace(()): scalar dataspace"
end

@testset "simple dataspaces" begin
    # Reference objects without using high-level API
    ds_zerosz = HDF5.Dataspace((0,))
    ds_vector = HDF5.Dataspace((5,))
    ds_matrix = HDF5.Dataspace((5, 7))
    ds_maxdim = HDF5.Dataspace((5, 7); max_dims=(20, 20))
    ds_unlim  = HDF5.Dataspace((1,); max_dims=(HDF5.UNLIMITED,))

    # Testing basic property accessors of dataspaces
    @test isvalid(ds_zerosz)
    @test isvalid(ds_vector)
    @test isvalid(ds_matrix)
    @test isvalid(ds_maxdim)
    @test isvalid(ds_unlim)

    @test ndims(ds_zerosz) === 1
    @test ndims(ds_vector) === 1
    @test ndims(ds_matrix) === 2
    @test ndims(ds_maxdim) === 2
    @test ndims(ds_unlim) === 1

    # Test that properties of existing datasets can be extracted.
    # Note: Julia reverses the order of dimensions when using the high-level API versus
    #       the dimensions used above to create the reference objects.
    @test size(ds_zerosz) === (0,)
    @test size(ds_vector) === (5,)
    @test size(ds_matrix) === (5, 7)
    @test size(ds_maxdim) === (5, 7)
    @test size(ds_unlim) === (1,)

    @test size(ds_zerosz, 1) === 0
    @test size(ds_vector, 1) === 5
    @test size(ds_matrix, 1) === 5
    @test size(ds_maxdim, 1) === 5
    @test size(ds_unlim, 1) === 1

    @test size(ds_zerosz, 2) === 1
    @test size(ds_vector, 2) === 1
    @test size(ds_matrix, 2) === 7
    @test size(ds_maxdim, 2) === 7
    @test size(ds_unlim, 2) === 1

    @test size(ds_zerosz, 5) === 1
    @test size(ds_vector, 5) === 1
    @test size(ds_matrix, 5) === 1
    @test size(ds_maxdim, 5) === 1
    @test size(ds_unlim, 5) === 1

    @test_throws ArgumentError("invalid dimension d; must be positive integer") size(
        ds_zerosz, 0
    )
    @test_throws ArgumentError("invalid dimension d; must be positive integer") size(
        ds_zerosz, -1
    )

    @test length(ds_zerosz) === 0
    @test length(ds_vector) === 5
    @test length(ds_matrix) === 35
    @test length(ds_maxdim) === 35
    @test length(ds_unlim) === 1

    @test isempty(ds_zerosz)
    @test !isempty(ds_vector)
    @test !isempty(ds_matrix)
    @test !isempty(ds_maxdim)
    @test !isempty(ds_unlim)

    @test !HDF5.isnull(ds_zerosz)
    @test !HDF5.isnull(ds_vector)
    @test !HDF5.isnull(ds_matrix)
    @test !HDF5.isnull(ds_maxdim)
    @test !HDF5.isnull(ds_unlim)

    @test HDF5.get_extent_dims(ds_zerosz) === ((0,), (0,))
    @test HDF5.get_extent_dims(ds_vector) === ((5,), (5,))
    @test HDF5.get_extent_dims(ds_matrix) === ((5, 7), (5, 7))
    @test HDF5.get_extent_dims(ds_maxdim) === ((5, 7), (20, 20))
    @test HDF5.get_extent_dims(ds_unlim) === ((1,), (HDF5.UNLIMITED,))

    @test repr(ds_zerosz) == "HDF5.Dataspace((0,)): 1-dimensional dataspace"
    @test repr(ds_vector) == "HDF5.Dataspace((5,)): 1-dimensional dataspace"
    @test repr(ds_matrix) == "HDF5.Dataspace((5, 7)): 2-dimensional dataspace"
    @test repr(ds_maxdim) ==
        "HDF5.Dataspace((5, 7); max_dims=(20, 20)): 2-dimensional dataspace"
    @test repr(ds_unlim) ==
        "HDF5.Dataspace((1,); max_dims=(HDF5.UNLIMITED,)): 1-dimensional dataspace"

    # Can create new copies
    ds_tmp  = copy(ds_maxdim)
    ds_tmp2 = HDF5.Dataspace(ds_tmp.id) # copy of ID, but new Julia object
    @test ds_tmp.id === ds_tmp2.id !== ds_maxdim.id

    # Equality and hashing
    @test ds_tmp == ds_maxdim
    @test ds_tmp !== ds_maxdim
    @test hash(ds_tmp) != hash(ds_maxdim)
    @test ds_tmp == ds_tmp2
    @test ds_tmp !== ds_tmp2
    @test hash(ds_tmp) == hash(ds_tmp2)

    # Behavior of closing dataspace objects
    close(ds_tmp)
    @test ds_tmp.id == -1
    @test !isvalid(ds_tmp)
    @test !isvalid(ds_tmp2)

    # Validity checking in high-level operations
    @test_throws ErrorException("File or object has been closed") copy(ds_tmp)
    @test_throws ErrorException("File or object has been closed") ndims(ds_tmp)
    @test_throws ErrorException("File or object has been closed") size(ds_tmp)
    @test_throws ErrorException("File or object has been closed") size(ds_tmp, 1)
    @test_throws ErrorException("File or object has been closed") length(ds_tmp)
    @test_throws ErrorException("File or object has been closed") ds_tmp == ds_tmp2
    @test close(ds_tmp) === nothing # no error

    # Test ability to create explicitly-sized dataspaces
    @test Dataspace((5,)) == ds_vector
    @test Dataspace((5, 7)) == ds_matrix != ds_maxdim
    @test Dataspace((5, 7); max_dims=(20, 20)) == ds_maxdim != ds_matrix
    @test Dataspace((1,); max_dims=(HDF5.UNLIMITED,)) == ds_unlim

    # Test dataspaces derived from data
    @test dataspace(zeros(0)) == ds_zerosz
    @test dataspace(zeros(0, 0)) != ds_zerosz
    @test dataspace(zeros(5, 7)) == ds_matrix
    @test dataspace(HDF5.VLen([[1]])) == dataspace((1,))
    @test dataspace(HDF5.VLen([[1], [2]])) == dataspace((2,))

    # Constructing dataspace for/from HDF5 dataset or attribute

    mktemp() do path, io
        close(io)
        h5open(path, "w") do hid
            dset = create_dataset(hid, "dset", datatype(Int), ds_matrix)
            attr = create_attribute(dset, "attr", datatype(Bool), ds_vector)
            @test dataspace(dset) == ds_matrix
            @test dataspace(dset) !== ds_matrix
            @test dataspace(attr) == ds_vector
            @test dataspace(attr) !== ds_vector
            close(dset)
            close(attr)
            @test_throws ErrorException("File or object has been closed") dataspace(dset)
            @test_throws ErrorException("File or object has been closed") dataspace(attr)
        end
    end

    # Test mid-level routines: set/get_extent_dims

    dspace_norm = dataspace((100, 4))
    @test HDF5.get_extent_dims(dspace_norm)[1] ==
        HDF5.get_extent_dims(dspace_norm)[2] ==
        (100, 4)
    HDF5.set_extent_dims(dspace_norm, (8, 2))
    @test HDF5.get_extent_dims(dspace_norm)[1] ==
        HDF5.get_extent_dims(dspace_norm)[2] ==
        (8, 2)

    dspace_maxd = dataspace((100, 4); max_dims=(256, 5))
    @test HDF5.get_extent_dims(dspace_maxd)[1] == (100, 4)
    @test HDF5.get_extent_dims(dspace_maxd)[2] == (256, 5)
    HDF5.set_extent_dims(dspace_maxd, (8, 2))
    @test HDF5.get_extent_dims(dspace_maxd)[1] == (8, 2)
    HDF5.set_extent_dims(dspace_maxd, (3, 1), (4, 2))
    @test HDF5.get_extent_dims(dspace_maxd)[1] == (3, 1)
    @test HDF5.get_extent_dims(dspace_maxd)[2] == (4, 2)
    HDF5.set_extent_dims(dspace_maxd, (3, 1), (-1, -1)) # unlimited max size
    @test HDF5.get_extent_dims(dspace_maxd)[1] == (3, 1)
    @test HDF5.get_extent_dims(dspace_maxd)[2] == (-1, -1)
end
