using HDF5
using Test

@testset "external" begin

# roughly following https://www.hdfgroup.org/ftp/HDF5/current/src/unpacked/examples/h5_extlink.c
fn1 = tempname()
fn2 = tempname()

source_file = h5open(fn1, "w")
agroup = g_create(source_file, "agroup")
target_file = h5open(fn2, "w")
target_group = g_create(target_file, "target_group")
target_group["abc"] = "abc"
target_group["1"] = 1
target_group["1.1"] = 1.1
close(target_file)

# create external link such that source_file["ext_link"] points to target_file["target_group"]
# test both an HDF5File and an HDF5Group for first argument
HDF5.create_external(source_file, "ext_link", target_file.filename, "target_group")
HDF5.create_external(agroup, "ext_link", target_file.filename, "target_group")
# write some things via the external link
new_group = g_create(source_file["ext_link"], "new_group")
new_group["abc"] = "abc"
new_group["1"] = 1
new_group["1.1"] = 1.1

# read things from target_group via exernal link created with HDF5File argument
group = source_file["ext_link"]
@test read(group["abc"]) == "abc"
@test read(group["1"]) == 1
@test read(group["1.1"]) == 1.1
# read things from target_group via the external link created with HDF5Group argument
groupalt = source_file["agroup/ext_link"]
@test read(groupalt["abc"]) == "abc"
@test read(groupalt["1"]) == 1
@test read(groupalt["1.1"]) == 1.1
close(source_file)

##### tests that should be included but don't work
# when ggggggggg restarts julia and keeps track of target_file.filename,
# these tests succeed
# reopening the target_file crashes due to "file close degree doesn't match"
# target_file = h5open(target_file.filename, "r")
# group2 = target_file["target_group"]["new_group"]
# @test read(group2["abc"])=="abc"
# @test read(group2["1"])==1
# @test read(group2["1.1"])==1.1

rm(fn1)
# rm(fn2)

end # testset external
