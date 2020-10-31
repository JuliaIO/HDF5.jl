using HDF5
using CRC32c
using Test

@testset "plain" begin

# Create a new file
fn = tempname()
f = h5open(fn, "w")
@test isopen(f)
# Write scalars
f["Float64"] = 3.2
f["Int16"] = Int16(4)
# compression of empty array (issue #246)
f["compressedempty", shuffle=(), compress=4] = Int64[]
# compression of zero-dimensional array (pull request #445)
f["compressed_zerodim", shuffle=(), compress=4] = fill(Int32(42), ())
f["bloscempty", blosc=4] = Int64[]
# Create arrays of different types
A = randn(3, 5)
write(f, "Afloat64", convert(Matrix{Float64}, A))
write(f, "Afloat32", convert(Matrix{Float32}, A))
Ai = rand(1:20, 2, 4)
write(f, "Aint8", convert(Matrix{Int8}, Ai))
f["Aint16"] = convert(Matrix{Int16}, Ai)
write(f, "Aint32", convert(Matrix{Int32}, Ai))
write(f, "Aint64", convert(Matrix{Int64}, Ai))
write(f, "Auint8", convert(Matrix{UInt8}, Ai))
write(f, "Auint16", convert(Matrix{UInt16}, Ai))

# test writing multiple variable (issue #599)
write(f, "Auint32", convert(Matrix{UInt32}, Ai), "Auint64", convert(Matrix{UInt64}, Ai))

# Arrays of bools (pull request #540)
Abool = [false, true, false]
write(f, "Abool", Abool)

salut = "Hi there"
ucode = "uniçº∂e"
write(f, "salut", salut)
write(f, "ucode", ucode)
# Manually write a variable-length string (issue #187)
let
    dtype = HDF5.Datatype(HDF5.h5t_copy(HDF5.H5T_C_S1))
    HDF5.h5t_set_size(dtype.id, HDF5.H5T_VARIABLE)
    HDF5.h5t_set_cset(dtype.id, HDF5.cset(typeof(salut)))
    dspace = HDF5.dataspace(salut)
    dset = HDF5.d_create(f, "salut-vlen", dtype, dspace)
    GC.@preserve salut begin
        HDF5.h5d_write(dset, dtype, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, [pointer(salut)])
    end
end
# Arrays of strings
salut_split = ["Hi", "there"]
write(f, "salut_split", salut_split)
salut_2d = ["Hi" "there"; "Salut" "friend"]
write(f, "salut_2d", salut_2d)
# Arrays of strings as vlen
vlen = HDF5.VLen(salut_split)
d_write(f, "salut_vlen", vlen)
# Arrays of scalars as vlen
vlen_int = [[3], [1], [4]]
vleni = HDF5.VLen(vlen_int)
d_write(f, "int_vlen", vleni)
a_write(f["int_vlen"], "vlen_attr", vleni)
# Empty arrays
empty = UInt32[]
write(f, "empty", empty)
# Empty strings
empty_string = ""
write(f, "empty_string", empty_string)
# Empty array of strings
empty_string_array = String[]
write(f, "empty_string_array", empty_string_array)
# Array of empty string
empty_array_of_strings = [""]
write(f, "empty_array_of_strings", empty_array_of_strings)
# Attributes
species = [["N", "C"]; ["A", "B"]]
attrs(f)["species"] = species
C∞ = 42
attrs(f)["C∞"] = C∞
dset = f["salut"]
@test !isempty(dset)
label = "This is a string"
attrs(dset)["typeinfo"] = label
close(dset)
# Scalar reference values in attributes
attrs(f)["ref_test"] = HDF5.Reference(f, "empty_array_of_strings")
@test read(attrs(f)["ref_test"]) === HDF5.Reference(f, "empty_array_of_strings")
# Group
g = g_create(f, "mygroup")
# Test dataset with compression
R = rand(1:20, 20, 40);
g["CompressedA", chunk=(5, 6), shuffle=(), compress=9] = R
g["BloscA", chunk=(5, 6), shuffle=(), blosc=9] = R
close(g)
# Copy group containing dataset
o_copy(f, "mygroup", f, "mygroup2")
# Copy dataset
g = g_create(f, "mygroup3")
o_copy(f["mygroup/CompressedA"], g, "CompressedA")
o_copy(f["mygroup/BloscA"], g, "BloscA")
close(g)
# Writing hyperslabs
dset = d_create(f, "slab", datatype(Float64), dataspace(20, 20, 5), chunk=(5, 5, 1))
Xslab = randn(20, 20, 5)
for i = 1:5
    dset[:,:,i] = Xslab[:,:,i]
end
# More complex hyperslab and assignment with "incorrect" types (issue #34)
d = d_create(f, "slab2", datatype(Float64), ((10, 20), (100, 200)), chunk=(1, 1))
d[:,:] = 5
d[1,1] = 4
# 1d indexing
d = d_create(f, "slab3", datatype(Int), ((10,), (-1,)), chunk=(5,))
@test d[:] == zeros(Int, 10)
d[3:5] = 3:5
# Create a dataset designed to be deleted
f["deleteme"] = 17.2
close(f)
@test !isopen(f)
# Test the h5read/write interface, with attributes
W = copy(reshape(1:120, 15, 8))
Wa = Dict("a" => 1, "b" => 2)
h5write(fn, "newgroup/W", W)
h5writeattr(fn, "newgroup/W", Wa)

# Read the file back in
fr = h5open(fn)
x = read(fr, "Float64")
@test x == 3.2 && isa(x, Float64)
y = read(fr, "Int16")
@test y == 4 && isa(y, Int16)
zerodim = read(fr, "compressed_zerodim")
@test zerodim == 42 && isa(zerodim, Int32)
bloscempty = read(fr, "bloscempty")
@test bloscempty == Int64[] && isa(bloscempty, Vector{Int64})
Af32 = read(fr, "Afloat32")
@test convert(Matrix{Float32}, A) == Af32
@test eltype(Af32) == Float32
Af64 = read(fr, "Afloat64")
@test convert(Matrix{Float64}, A) == Af64
@test eltype(Af64) == Float64
@test eltype(fr["Afloat64"]) == Float64  # issue 167
Ai8 = read(fr, "Aint8")
@test Ai == Ai8
@test eltype(Ai8) == Int8
Ai16 = read(fr, "Aint16")
@test Ai == Ai16
@test eltype(Ai16) == Int16
Ai32 = read(fr, "Aint32")
@test Ai == Ai32
@test eltype(Ai32) == Int32
Ai64 = read(fr, "Aint64")
@test Ai == Ai64
@test eltype(Ai64) == Int64
Ai8 = read(fr, "Auint8")
@test Ai == Ai8
@test eltype(Ai8) == UInt8
Ai16 = read(fr, "Auint16")
@test Ai == Ai16
@test eltype(Ai16) == UInt16
Ai32 = read(fr, "Auint32")
@test Ai == Ai32
@test eltype(Ai32) == UInt32
Ai64 = read(fr, "Auint64")
@test Ai == Ai64
@test eltype(Ai64) == UInt64

Abool_read = read(fr, "Abool")
@test Abool_read == Abool
@test eltype(Abool_read) == Bool

salutr = read(fr, "salut")
@test salut == salutr
salutr = read(fr, "salut-vlen")
@test salut == salutr
ucoder = read(fr, "ucode")
@test ucode == ucoder
salut_splitr = read(fr, "salut_split")
@test salut_splitr == salut_split
salut_2dr = read(fr, "salut_2d")
@test salut_2d == salut_2dr
salut_vlenr = read(fr, "salut_vlen")
#@test salut_vlenr == salut_split
vlen_intr = read(fr, "int_vlen")
@test vlen_intr == vlen_int
vlen_attrr = read(fr["int_vlen"]["vlen_attr"])
@test vlen_attrr == vlen_int
Rr = read(fr, "mygroup/CompressedA")
@test Rr == R
Rr2 = read(fr, "mygroup2/CompressedA")
@test Rr2 == R
Rr3 = read(fr, "mygroup3/CompressedA")
@test Rr3 == R
Rr4 = read(fr, "mygroup/BloscA")
@test Rr4 == R
Rr5 = read(fr, "mygroup2/BloscA")
@test Rr5 == R
Rr6 = read(fr, "mygroup3/BloscA")
@test Rr6 == R
dset = fr["mygroup/CompressedA"]
@test get_chunk(dset) == (5, 6)
@test name(dset) == "/mygroup/CompressedA"
dset2 = fr["mygroup/BloscA"]
@test get_chunk(dset2) == (5, 6)
@test name(dset2) == "/mygroup/BloscA"
Xslabr = read(fr, "slab")
@test Xslabr == Xslab
Xslabr = h5read(fn, "slab", (:, :, :))  # issue #87
@test Xslabr == Xslab
Xslab2r = read(fr, "slab2")
target = fill(5, 10, 20)
target[1] = 4
@test Xslab2r == target
dset = fr["slab3"]
@test dset[3:5] == [3:5;]
emptyr = read(fr, "empty")
@test isempty(emptyr)
empty_stringr = read(fr, "empty_string")
@test empty_stringr == empty_string
empty_string_arrayr = read(fr, "empty_string_array")
@test empty_string_arrayr == empty_string_array
empty_array_of_stringsr = read(fr, "empty_array_of_strings")
@test empty_array_of_stringsr == empty_array_of_strings
@test a_read(fr, "species") == species
@test a_read(fr, "C∞") == C∞
dset = fr["salut"]
@test a_read(dset, "typeinfo") == label
close(dset)
# Test ref-based reading
Aref = fr["Afloat64"]
sel = (2:3, 1:2:5)
Asub = Aref[sel...]
@test Asub == A[sel...]
close(Aref)
# Test iteration, name, and parent
for obj in fr
    @test filename(obj) == fn
    n = name(obj)
    p = parent(obj)
end
# Test reading multiple vars at once
z = read(fr, "Float64", "Int16")
@test z == (3.2, 4)
@test typeof(z) == Tuple{Float64,Int16}
# Test reading entire file at once
z = read(fr)
@test z["Float64"] == 3.2
close(fr)

# Test object deletion
fr = h5open(fn, "r+")
@test haskey(fr, "deleteme")
o_delete(fr, "deleteme")
@test !haskey(fr, "deleteme")
close(fr)

# Test the h5read interface
Wr = h5read(fn, "newgroup/W")
@test Wr == W
rng = (2:3:15, 3:5)
Wr = h5read(fn, "newgroup/W", rng)
@test Wr == W[rng...]
War = h5readattr(fn, "newgroup/W")
@test War == Wa

# issue #618
# Test that invalid writes treat implicit creation as a transaction, cleaning up the partial
# operation
hid = h5open(fn, "w")
A = rand(3, 3)'
@test !haskey(hid, "A")
@test_throws ArgumentError write(hid, "A", A)
@test !haskey(hid, "A")
dset = d_create(hid, "attr", datatype(Int), dataspace(0))
@test !haskey(attrs(dset), "attr")
# broken test - writing attributes does not check that the stride is correct
@test_skip @test_throws ArgumentError write(dset, "attr", A)
@test !haskey(attrs(dset), "attr")
close(hid)

# more do syntax
h5open(fn, "w") do fid
    g_create(fid, "mygroup") do g
        write(g, "x", 3.2)
    end
end
fid = h5open(fn, "r")
@test keys(fid) == ["mygroup"]
g = fid["mygroup"]
@test keys(g) == ["x"]
close(g)
close(fid)
rm(fn)

# more do syntax: atomic rename version
tmpdir = mktempdir()
outfile = joinpath(tmpdir, "test.h5")

# create a new file
h5rewrite(outfile) do fid
    g_create(fid, "mygroup") do g
        write(g, "x", 3.3)
    end
end
@test length(readdir(tmpdir)) == 1
h5open(outfile, "r") do fid
    @test keys(fid) == ["mygroup"]
    @test keys(fid["mygroup"]) == ["x"]
end

# fail to overwrite
@test_throws ErrorException h5rewrite(outfile) do fid
    g_create(fid, "mygroup") do g
        write(g, "oops", 3.3)
    end
    error("failed")
end
@test length(readdir(tmpdir)) == 1
h5open(outfile, "r") do fid
    @test keys(fid) == ["mygroup"]
    @test keys(fid["mygroup"]) == ["x"]
end

# overwrite
h5rewrite(outfile) do fid
    g_create(fid, "mygroup") do g
        write(g, "y", 3.3)
    end
end
@test length(readdir(tmpdir)) == 1
h5open(outfile, "r") do fid
    @test keys(fid) == ["mygroup"]
    @test keys(fid["mygroup"]) == ["y"]
end
rm(tmpdir, recursive=true)

test_files = joinpath(@__DIR__, "test_files")

d = h5read(joinpath(test_files, "compound.h5"), "/data")
@test typeof(d[1]) == NamedTuple{(:wgt, :xyz, :uvw, :E), Tuple{Float64, Array{Float64, 1}, Array{Float64, 1}, Float64}}

# get-datasets
fn = tempname()
fd = h5open(fn, "w")
fd["level_0"] = [1,2,3]
grp = g_create(fd, "mygroup")
fd["mygroup/level_1"] = [4, 5]
grp2 = g_create(grp, "deep_group")
fd["mygroup/deep_group/level_2"] = [6.0, 7.0]
datasets = get_datasets(fd)
@test sort(map(name, datasets)) ==  sort(["/level_0", "/mygroup/deep_group/level_2", "/mygroup/level_1"])
close(fd)
rm(fn)

# File creation and access property lists
cpl = p_create(HDF5.H5P_FILE_CREATE)
cpl[:userblock] = 1024
apl = p_create(HDF5.H5P_FILE_ACCESS)
apl[:libver_bounds] = (HDF5.H5F_LIBVER_EARLIEST, HDF5.H5F_LIBVER_LATEST)
h5open(fn, false, true, true, true, false, cpl, apl) do fid
    write(fid, "intarray", [1, 2, 3])
end
h5open(fn, "r", libver_bounds=(HDF5.H5F_LIBVER_EARLIEST, HDF5.H5F_LIBVER_LATEST)) do fid
    intarray = read(fid, "intarray")
    @test intarray == [1, 2, 3]
end

# Test null terminated ASCII string (e.g. exported by h5py) #332
h5open(joinpath(test_files, "nullterm_ascii.h5"), "r") do fid
    str = read(fid["test"])
    @test str == "Hello World"
end

@test HDF5.unpad(UInt8[0x43, 0x43, 0x41], 1) == "CCA"

# Test the h5read/write interface with a filename as a first argument, when
# the file does not exist
rm(fn)
h5write(fn, "newgroup/W", W)
Wr = h5read(fn, "newgroup/W")
@test Wr == W
close(f)
rm(fn)

if !isempty(HDF5.libhdf5_hl)
    # Test direct chunk writing
    h5open(fn, "w") do f
      d = d_create(f, "dataset", datatype(Int), dataspace(4, 4), chunk=(2, 2))
      raw = HDF5.ChunkStorage(d)
      raw[1,1] = 0, collect(reinterpret(UInt8, [1,2,5,6]))
      raw[3,1] = 0, collect(reinterpret(UInt8, [3,4,7,8]))
      raw[1,3] = 0, collect(reinterpret(UInt8, [9,10,13,14]))
      raw[3,3] = 0, collect(reinterpret(UInt8, [11,12,15,16]))
    end

    @test h5open(fn, "r") do f
      vec(f["dataset"][:,:])
    end == collect(1:16)

    close(f)
    rm(fn)
end

# Test that switching time tracking off results in identical files
fn1 = tempname(); fn2 = tempname()
h5open(fn1, "w") do f
    f["x", track_times=false] = [1, 2, 3]
end
sleep(1)
h5open(fn2, "w") do f
    f["x", track_times=false] = [1, 2, 3]
end
@test open(crc32c, fn1) == open(crc32c, fn2)
rm(fn1); rm(fn2)

end # testset plain

@testset "complex" begin
  HDF5.enable_complex_support()

  fn = tempname()
  f = h5open(fn, "w")

  f["ComplexF64"] = 1.0 + 2.0im
  attrs(f["ComplexF64"])["ComplexInt64"] = 1im

  Acmplx = rand(ComplexF64, 3, 5)
  write(f, "Acmplx64", convert(Matrix{ComplexF64}, Acmplx))
  write(f, "Acmplx32", convert(Matrix{ComplexF32}, Acmplx))

  dset = d_create(f, "Acmplx64_hyperslab", datatype(Complex{Float64}), dataspace(Acmplx))
  for i in 1:size(Acmplx, 2)
    dset[:, i] = Acmplx[:,i]
  end

  HDF5.disable_complex_support()
  @test_throws ErrorException f["_ComplexF64"] = 1.0 + 2.0im
  @test_throws ErrorException write(f, "_Acmplx64", convert(Matrix{ComplexF64}, Acmplx))
  @test_throws ErrorException write(f, "_Acmplx32", convert(Matrix{ComplexF32}, Acmplx))
  HDF5.enable_complex_support()

  close(f)

  fr = h5open(fn)
  z = read(fr, "ComplexF64")
  @test z == 1.0 + 2.0im && isa(z, ComplexF64)
  z_attrs = attrs(fr["ComplexF64"])
  @test read(z_attrs["ComplexInt64"]) == 1im

  Acmplx32 = read(fr, "Acmplx32")
  @test convert(Matrix{ComplexF32}, Acmplx) == Acmplx32
  @test eltype(Acmplx32) == ComplexF32
  Acmplx64 = read(fr, "Acmplx64")
  @test convert(Matrix{ComplexF64}, Acmplx) == Acmplx64
  @test eltype(Acmplx64) == ComplexF64

  dset = fr["Acmplx64_hyperslab"]
  Acmplx64_hyperslab = zeros(eltype(dset), size(dset))
  for i in 1:size(dset, 2)
    Acmplx64_hyperslab[:,i] = dset[:,i]
  end
  @test convert(Matrix{ComplexF64}, Acmplx) == Acmplx64_hyperslab

  HDF5.disable_complex_support()
  z = read(fr, "ComplexF64")
  @test isa(z, NamedTuple{(:r, :i), Tuple{Float64, Float64}})

  Acmplx32 = read(fr, "Acmplx32")
  @test eltype(Acmplx32) == NamedTuple{(:r, :i), Tuple{Float32, Float32}}
  Acmplx64 = read(fr, "Acmplx64")
  @test eltype(Acmplx64) == NamedTuple{(:r, :i), Tuple{Float64, Float64}}

  close(fr)

  HDF5.enable_complex_support()
end

# test strings with null and undefined references
@testset "undefined and null" begin
fn = tempname()
f = h5open(fn, "w")

# don't silently truncate data
@test_throws ArgumentError write(f, "test", ["hello","there","\0"])
@test_throws ArgumentError write(f, "trunc1", "\0")
@test_throws ArgumentError write(f, "trunc2", "trunc\0ateme")

# test writing uninitialized string arrays
undefstrarr = similar(Vector(1:3), String) # strs = String[#undef, #undef, #undef]
@test_throws UndefRefError write(f, "undef", undefstrarr)

close(f)
rm(fn)

end # testset null and undefined

# test writing abstract arrays
@testset "abstract arrays" begin

# test writing reinterpreted data
fn = tempname()
try
    h5open(fn, "w") do f
        data = reinterpret(UInt8, [true, false, false])
        write(f, "reinterpret array", data)
    end

    @test h5open(fn, "r") do f
        read(f, "reinterpret array")
    end == UInt8[0x01, 0x00, 0x00]
finally
    rm(fn)
end

# don't silently fail for arrays with a different stride
fn = tempname()
try
    data = rand(UInt16, 2, 3);
    pdv_data = PermutedDimsArray(data, (2, 1))

    @test_throws ArgumentError h5write(fn, "pdv_data", pdv_data)
finally
    rm(fn)
end

# test alignment
fn = tempname()
h5open(fn, "w", alignment=(0, 8)) do fid
    fid["x"] = zeros(10, 10)
end

end # writing abstract arrays

# issue #705
@testset "empty and 0-size arrays" begin
fn = tempname()
hfile = h5open(fn, "w")

# Write datasets with various 0-sizes
write(hfile, "empty", HDF5.EmptyArray{Int64}()) # HDF5 empty
write(hfile, "zerodim", fill(1.0π))   # 0-dimensional
write(hfile, "zerovec", zeros(0))     # 1-dimensional, size 0
write(hfile, "zeromat", zeros(0, 0))  # 2-dimensional, size 0
write(hfile, "zeromat2", zeros(0, 1)) # 2-dimensional, size 0 with non-zero axis
dempty = hfile["empty"]
dzerodim = hfile["zerodim"]
dzerovec = hfile["zerovec"]
dzeromat = hfile["zeromat"]
dzeromat2 = hfile["zeromat2"]

# Test that eltype is preserved (especially for EmptyArray)
@test eltype(dempty) == Int64
@test eltype(dzerodim) == Float64
@test eltype(dzerovec) == Float64
@test eltype(dzeromat) == Float64
@test eltype(dzeromat2) == Float64
# Test sizes are as expected
@test size(dempty) == ()
@test size(dzerovec) == (0,)
@test size(dzeromat) == (0, 0)
@test size(dzeromat2) == (0, 1)
@test HDF5.isnull(dempty)
@test !HDF5.isnull(dzerovec)
@test !HDF5.isnull(dzeromat)
@test !HDF5.isnull(dzeromat2)
# Reading back must preserve emptiness
@test read(dempty) isa HDF5.EmptyArray
# but 0-dimensional Array{T,0} are stored as HDF5 scalar
@test size(dzerodim) == ()
@test !HDF5.isnull(dzerodim)
@test read(dzerodim) == 1.0π

# Similar tests for writing to attributes
write(dempty, "attr", HDF5.EmptyArray{Float64}())
write(dzerodim, "attr", fill(1.0ℯ))
write(dzerovec, "attr", zeros(Int64, 0))
write(dzeromat, "attr", zeros(Int64, 0, 0))
write(dzeromat2, "attr", zeros(Int64, 0, 1))
aempty = dempty["attr"]
azerodim = dzerodim["attr"]
azerovec = dzerovec["attr"]
azeromat = dzeromat["attr"]
azeromat2 = dzeromat2["attr"]
# Test that eltype is preserved (especially for EmptyArray)
@test eltype(aempty) == Float64
@test eltype(azerodim) == Float64
@test eltype(azerovec) == Int64
@test eltype(azeromat) == Int64
@test eltype(azeromat2) == Int64
# Test sizes are as expected
@test size(aempty) == ()
@test size(azerovec) == (0,)
@test size(azeromat) == (0, 0)
@test size(azeromat2) == (0, 1)
@test HDF5.isnull(aempty)
@test !HDF5.isnull(azerovec)
@test !HDF5.isnull(azeromat)
@test !HDF5.isnull(azeromat2)
# Reading back must preserve emptiness
@test read(aempty) isa HDF5.EmptyArray
# but 0-dimensional Array{T,0} are stored as HDF5 scalar
@test size(azerodim) == ()
@test !HDF5.isnull(azerodim)
@test read(azerodim) == 1.0ℯ

# Concatenation of EmptyArrays is not supported
x = HDF5.EmptyArray{Float64}()
@test_throws ErrorException [x x]
@test_throws ErrorException [x; x]
@test_throws ErrorException [x x; x x]

close(hfile)
rm(fn)

# check that printing EmptyArray doesn't error
buf = IOBuffer()
show(buf, HDF5.EmptyArray{Int64}())
@test String(take!(buf)) == "HDF5.EmptyArray{Int64}()"
show(buf, MIME"text/plain"(), HDF5.EmptyArray{Int64}())
@test String(take!(buf)) == "HDF5.EmptyArray{Int64}()"
end # empty and 0-size arrays

@testset "generic read of native types" begin
fn = tempname()
hfile = h5open(fn, "w")

dtype_varstring = HDF5.Datatype(HDF5.h5t_copy(HDF5.H5T_C_S1))
HDF5.h5t_set_size(dtype_varstring, HDF5.H5T_VARIABLE)

write(hfile, "uint8_array", UInt8[(1:8)...])
write(hfile, "bool_scalar", true)

fixstring = "fix"
varstring = "var"
write(hfile, "fixed_string", fixstring)
vardset = d_create(hfile, "variable_string", dtype_varstring, dataspace(varstring))
GC.@preserve varstring begin
    HDF5.h5d_write(vardset, dtype_varstring, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, [pointer(varstring)])
end
flush(hfile)
close(dtype_varstring)

# generic read() handles concrete types with definite sizes transparently
d = read(hfile["uint8_array"], UInt8)
@test d isa Vector{UInt8}
@test d == 1:8
d = read(hfile["bool_scalar"], Bool)
@test d isa Bool
@test d == true
d = read(hfile["fixed_string"], HDF5.FixedString{length(fixstring),0})
@test d isa String
@test d == fixstring
d = read(hfile["variable_string"], Cstring)
@test d isa String
@test d == varstring
# will also accept memory-compatible reinterpretations
d = read(hfile["uint8_array"], Int8)
@test d isa Vector{Int8}
@test d == 1:8
d = read(hfile["bool_scalar"], UInt8)
@test d isa UInt8
@test d == 0x1
# but should throw on non-compatible types
@test_throws ErrorException("""
                            Type size mismatch
                            sizeof(UInt16) = 2
                            sizeof($(sprint(show, datatype(UInt8)))) = 1
                            """) read(hfile["uint8_array"], UInt16)

# Strings are not fixed size, but generic read still handles them if given the correct
# underlying FixedString or Cstring type; a method overload makes String work, too.
d = read(hfile["fixed_string"], String)
@test d isa String
@test d == fixstring
d = read(hfile["variable_string"], String)
@test d isa String
@test d == varstring

close(hfile)
rm(fn)
end # generic read of native types

@testset "show" begin
fn = tempname()

# First create data objects and sure they print useful outputs

hfile = h5open(fn, "w")
@test sprint(show, hfile) == "HDF5 data file: $fn"

group = g_create(hfile, "group")
@test sprint(show, group) == "HDF5 group: /group (file: $fn)"

dset = d_create(group, "dset", datatype(Int), dataspace((1,)))
@test sprint(show, dset) == "HDF5 dataset: /group/dset (file: $fn xfer_mode: 0)"

meta = a_create(dset, "meta", datatype(Bool), dataspace((1,)))
@test sprint(show, meta) == "HDF5 attribute: meta"

prop = p_create(HDF5.H5P_DATASET_CREATE)
@test sprint(show, prop) == "HDF5 property: dataset create class"

dtype = HDF5.Datatype(HDF5.h5t_copy(HDF5.H5T_IEEE_F64LE))
@test sprint(show, dtype) == "HDF5 datatype: H5T_IEEE_F64LE"

dspace = dataspace((1,))
@test occursin(r"^HDF5.Dataspace\(\d+\)", sprint(show, dspace))

# Now test printing after closing each object

close(dspace)
@test sprint(show, dspace) == "HDF5.Dataspace(-1)"

close(dtype)
@test sprint(show, dtype) == "HDF5 datatype: (invalid)"

close(prop)
@test sprint(show, prop) == "HDF5 property (invalid)"

close(meta)
@test sprint(show, meta) == "HDF5 attribute (invalid)"

close(dset)
@test sprint(show, dset) == "HDF5 dataset (invalid)"

close(group)
@test sprint(show, group) == "HDF5 group (invalid)"

close(hfile)
@test sprint(show, hfile) == "HDF5 data file (closed): $fn"

rm(fn)
end # show tests

@testset "split1" begin

@test HDF5.split1("a") == ("a", nothing)
@test HDF5.split1("/a/b/c") == ("/", "a/b/c")
@test HDF5.split1("a/b/c") == ("a", "b/c")
@test HDF5.split1(GenericString("a")) == ("a", nothing)
@test HDF5.split1(GenericString("/a/b/c")) == ("/", "a/b/c")
@test HDF5.split1(GenericString("a/b/c")) == ("a", "b/c")

# The following two paths have the same graphemes but different code unit structures:
# the first one is
#     <latin small letter a with circumflex> "/" <greek small leter alpha>
# while the second one is
#     "a" <combining circumflex accent> "/" <greek small letter alpha>
circa = "â" # <latin small leter a with circumflex>
acomb = "â" # "a" + <combining circumflex accent>
path1 = circa * "/α"
path2 = acomb * "/α"
# Sanity checks that the two strings are different but equivalent under normalization
@test path1 != path2
@test Base.Unicode.normalize(path1, :NFC) == Base.Unicode.normalize(path2, :NFC)
# Check split1 operates correctly
@test HDF5.split1(path1) == (circa, "α")
@test HDF5.split1(path2) == (acomb, "α")
@test HDF5.split1("/" * path1) == ("/", path1)
@test HDF5.split1("/" * path2) == ("/", path2)

end # split1 tests


# Also tests AbstractString interface
@testset "haskey" begin
fn = tempname()
hfile = h5open(fn, "w")

group1 = g_create(hfile, "group1")
group2 = g_create(group1, "group2")

@test haskey(hfile, GenericString("group1"))
@test !haskey(hfile, GenericString("groupna"))
@test haskey(hfile, "group1/group2")
@test !haskey(hfile, "group1/groupna")

dset1 = d_create(hfile, "dset1", datatype(Int), dataspace((1,)))
dset2 = d_create(group1, "dset2", datatype(Int), dataspace((1,)))

@test haskey(hfile, "dset1")
@test !haskey(hfile, "dsetna")
@test haskey(hfile, "group1/dset2")
@test !haskey(hfile, "group1/dsetna")

meta1 = a_create(dset1, "meta1", datatype(Bool), dataspace((1,)))
@test haskey(dset1, "meta1")
@test !haskey(dset1, "metana")


attribs = attrs(hfile)
attribs["test1"] = true
attribs["test2"] = "foo"

haskey(attribs, "test1")
haskey(attribs, "test2")
!haskey(attribs, "testna")

attribs = attrs(dset2)
attribs["attr"] = "foo"
haskey(attribs, GenericString("attr"))

close(hfile)
rm(fn)
end # haskey tests


@testset "AbstractString" begin

fn = GenericString(tempname())
hfile = h5open(fn, "w")
close(hfile)
hfile = h5open(fn); close(hfile)
hfile = h5open(fn, "w")

@test_nowarn g_create(hfile, GenericString("group1"))
@test_nowarn d_create(hfile, GenericString("dset1"), datatype(Int), dataspace((1,)))
@test_nowarn d_create(hfile, GenericString("dset2"), 1)

@test_nowarn hfile[GenericString("group1")]
@test_nowarn hfile[GenericString("dset1")]


dset1 = hfile["dset1"]
@test_nowarn a_create(dset1, GenericString("meta1"), datatype(Bool), dataspace((1,)))
@test_nowarn a_create(dset1, GenericString("meta2"), 1)
@test_nowarn dset1[GenericString("meta1")]
@test_nowarn dset1[GenericString("x")] = 2

array_of_strings = ["test",]
write(hfile, "array_of_strings", array_of_strings)
@test_nowarn attrs(hfile)[GenericString("ref_test")] = HDF5.Reference(hfile, GenericString("array_of_strings"))
@test read(attrs(hfile)[GenericString("ref_test")]) === HDF5.Reference(hfile, "array_of_strings")

hfile[GenericString("test")] = 17.2
@test_nowarn o_delete(hfile, GenericString("test"))
@test_nowarn a_delete(dset1, GenericString("meta1"))

# transient types
memtype_id = HDF5.h5t_copy(HDF5.H5T_NATIVE_DOUBLE)
dt = HDF5.Datatype(memtype_id)
@test !HDF5.h5t_committed(dt)
t_commit(hfile, GenericString("dt"), dt)
@test HDF5.h5t_committed(dt)

dt = datatype(Int)
ds = dataspace(0)
d = d_create(hfile, GenericString("d"), dt, ds)
g = g_create(hfile, GenericString("g"))
a = a_create(hfile, GenericString("a"), dt, ds)

for obj in (d, g)
   @test_nowarn a_write(obj, GenericString("a"), 1)
   @test_nowarn a_read(obj, GenericString("a"))
   @test_nowarn write(obj, GenericString("aa"), 1)
   @test_nowarn attrs(obj)["attr1"] = GenericString("b")
end
@test_nowarn write(d, "attr2", GenericString("c"))
@test_nowarn d_write(g, GenericString("ag"), GenericString("gg"))
@test_nowarn d_write(g, GenericString("ag_array"), [GenericString("a1"), GenericString("a2")])

genstrs = GenericString["fee", "fi", "foo"]
@test_nowarn a_write(d, GenericString("myattr"), genstrs)
@test genstrs == read(d["myattr"])

for obj in (hfile,)
    @test_nowarn d_open(obj, GenericString("d"))
    @test_nowarn d_write(obj, GenericString("dd"), 1)
    @test_nowarn d_read(obj, GenericString("dd"))
    @test_nowarn read(obj, GenericString("dd"))
    @test_nowarn read(obj, GenericString("dd")=>Int)
end
read(attrs(hfile), GenericString("a"))

write(hfile, GenericString("ASD"), GenericString("Aa"))
write(g, GenericString("ASD"), GenericString("Aa"))
write(g, GenericString("ASD1"), [GenericString("Aa")])

# test writing multiple variable
@test_nowarn write(hfile, GenericString("a1"), rand(2,2), GenericString("a2"), rand(2,2))

# copy methods
d1 = d_create(hfile, GenericString("d1"), dt, ds)
d1["x"] = 32
@test_nowarn o_copy(hfile, GenericString("d1"), hfile, GenericString("d1copy1"))
@test_nowarn o_copy(d1, hfile, GenericString("d1copy2"))

fn = GenericString(tempname())
A = Matrix(reshape(1:120, 15, 8))
@test_nowarn h5write(fn, GenericString("A"), A)
@test_nowarn h5read(fn, GenericString("A"))
@test_nowarn h5read(fn, GenericString("A"), (2:3:15, 3:5))

@test_nowarn h5write(fn, GenericString("x"), 1)
@test_nowarn h5read(fn, GenericString("x") => Int)


@test_nowarn h5rewrite(fn) do fid
    g_create(fid, "mygroup") do g
        write(g, "x", 3.3)
    end
end
@test_nowarn h5rewrite(fn) do fid
    g_create(fid, "mygroup") do g
        write(g, "y", 3.3)
    end
end

@test_nowarn h5write(fn, "W", [1 2; 3 4])
@test_nowarn h5writeattr(fn, GenericString("W"), Dict("a" => 1, "b" => 2))
@test_nowarn h5readattr(fn, GenericString("W"))

fn_external = GenericString(tempname())
dset = d_create_external(hfile, "ext", fn_external, Int, (10,20))

end

# length for FixedString
fix = HDF5.FixedString{4,0}((b"test"...,))
@test length(fix) == 4
