using HDF5
using Test
using LinearAlgebra: norm

@testset "readremote" begin

# check that we can read the official HDF5 example files

# download and save test file via:
# urlbase = "https://support.hdfgroup.org/ftp/HDF5/examples/files/exbyapi/"
test_files = joinpath(@__DIR__, "test_files")
# if !isdir(test_files)
#     mkdir(test_files)
# end
# function joinpath(test_files, name)
#     file = joinpath(test_files, name)
#     if !isfile(file)
#         file = download(urlbase*name, file)
#     end
#     file
# end

fcmp = [0 1 2 3 4 5 6;
    2 1.66667 2.4 3.28571 4.22222 5.18182 6.15385;
    4 2.33333 2.8 3.57143 4.44444 5.36364 6.30769;
    6 3 3.2 3.85714 4.66667 5.54545 6.46154]'
icmp = [0 -1 -2 -3 -4 -5 -6;
    0 0 0 0 0 0 0;
    0 1 2 3 4 5 6;
    0 2 4 6 8 10 12]'
SOLID, LIQUID, GAS, PLASMA = 0, 1, 2, 3
ecmp = [SOLID SOLID SOLID SOLID SOLID SOLID SOLID;
        SOLID LIQUID GAS PLASMA SOLID LIQUID GAS;
        SOLID GAS SOLID GAS SOLID GAS SOLID;
        SOLID PLASMA GAS LIQUID SOLID PLASMA GAS]'
scmp = ["Parting", "is such", "sweet", "sorrow."]
vicmp = Array{Int32}[[3, 2, 1],[1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144]]
opq = Array{UInt8}[[0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x30],
                   [0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x31],
                   [0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x32],
                   [0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x33]]
# For H5T_ARRAY
AA = Array{Int,2}[
    [0   0   0;
     0  -1  -2;
     0  -2  -4;
     0  -3  -6;
     0  -4  -8],
    [0   1   2;
     1   1   1;
     2   1   0;
     3   1  -1;
     4   1  -2],
    [0   2   4;
     2   3   4;
     4   4   4;
     6   5   4;
     8   6   4],
    [0   3   6;
     3   5   7;
     6   7   8;
     9   9   9;
     12  11  10]]


file = joinpath(test_files, "h5ex_t_floatatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
@test norm(a - fcmp) < 1.5e-5
close(fid)

file = joinpath(test_files, "h5ex_t_float.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@test norm(d - fcmp) < 1.5e-5
close(fid)

file = joinpath(test_files, "h5ex_t_intatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
@test a == icmp
close(fid)

file = joinpath(test_files, "h5ex_t_int.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@test d == icmp
close(fid)

if HDF5.API.h5_get_libversion() >= v"1.8.11"
  file = joinpath(test_files, "h5ex_t_enumatt.h5")
  fid = h5open(file, "r")
  dset = fid["DS1"]
  a = read_attribute(dset, "A1")
  @test a == ecmp
  close(fid)

  file = joinpath(test_files, "h5ex_t_enum.h5")
  fid = h5open(file, "r")
  d = read(fid, "DS1")
  @test d == ecmp
  close(fid)
end

file = joinpath(test_files, "h5ex_t_objrefatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
g = fid[a[1]]
@test isa(g, HDF5.Group)
ds2 = fid[a[2]]
ds2v = read(ds2)
@test isa(ds2v, HDF5.EmptyArray{Int32})
@test isempty(ds2v)
close(fid)

file = joinpath(test_files, "h5ex_t_objref.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
g = fid[d[1]]
@test isa(g, HDF5.Group)
ds2 = fid[d[2]]
ds2v = read(ds2)
@test isa(ds2v, HDF5.EmptyArray{Int32})
@test isempty(ds2v)
close(fid)

file = joinpath(test_files, "h5ex_t_stringatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
@test a == scmp
close(fid)

file = joinpath(test_files, "h5ex_t_string.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@test d == scmp
close(fid)

file = joinpath(test_files, "h5ex_t_vlenatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
@test a == vicmp
close(fid)

file = joinpath(test_files, "h5ex_t_vlen.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@test d == vicmp
close(fid)

file = joinpath(test_files, "h5ex_t_vlstringatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
@test a == scmp
close(fid)

file = joinpath(test_files, "h5ex_t_vlstring.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@test d == scmp
close(fid)

file = joinpath(test_files, "h5ex_t_opaqueatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = read_attribute(dset, "A1")
@test a.tag == "Character array"
@test a.data == opq
close(fid)

file = joinpath(test_files, "h5ex_t_opaque.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@test d.tag == "Character array"
@test d.data == opq
close(fid)

file = joinpath(test_files, "h5ex_t_array.h5")
fid = h5open(file, "r")
A = read(fid, "DS1")
@test A == AA
close(fid)

end # testset readremote
