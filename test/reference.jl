using Random, Test, HDF5

@testset "reference" begin
    data = rand(100)

    fn = tempname()

    f = h5open(fn, "w")
    f["data"] = data
    f["group_data"] = data
    f["attr_data"] = data
    # reference attached to file
    f["file_ref"] = HDF5.Reference(f, "data")
    # reference attached to group
    g = create_group(f, "sub")
    g["group_ref"] = HDF5.Reference(f, "group_data")
    # reference attached to dataset
    f["data"]["attr_ref"] = HDF5.Reference(f, "attr_data")

    close(f)

    f = h5open(fn, "r")
    # read back file-attached reference
    ref = read(f["file_ref"])
    @test ref isa HDF5.Reference
    @test data == read(f[ref])
    # read back group-attached reference
    gref = read(f["sub"]["group_ref"])
    @test gref isa HDF5.Reference
    @test data == read(f["sub"][gref])
    # read back dataset-attached reference
    aref = read(f["data"]["attr_ref"])
    @test aref isa HDF5.Reference
    @test data == read(f["data"][aref])

    close(f)
    rm(fn)
end
