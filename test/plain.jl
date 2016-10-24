using HDF5, Compat, Base.Test
using Compat.String
const test_path = splitdir(@__FILE__)[1]

# Create a new file
fn = joinpath(tempdir(),"test.h5")
f = h5open(fn, "w")
# Write scalars
f["Float64"] = 3.2
f["Int16"] = @compat Int16(4)
# compression of empty array (issue #246)
f["compressedempty", "shuffle", (), "compress", 4] = Array(Int64, 0)
f["bloscempty", "blosc", 4] = Array(Int64, 0)
# Create arrays of different types
A = randn(3,5)
write(f, "Afloat64", convert(Matrix{Float64}, A))
write(f, "Afloat32", convert(Matrix{Float32}, A))
Ai = rand(1:20, 2, 4)
write(f, "Aint8", convert(Matrix{Int8}, Ai))
f["Aint16"] = convert(Matrix{Int16}, Ai)
write(f, "Aint32", convert(Matrix{Int32}, Ai))
write(f, "Aint64", convert(Matrix{Int64}, Ai))
write(f, "Auint8", convert(Matrix{UInt8}, Ai))
write(f, "Auint16", convert(Matrix{UInt16}, Ai))
write(f, "Auint32", convert(Matrix{UInt32}, Ai))
write(f, "Auint64", convert(Matrix{UInt64}, Ai))

salut = "Hi there"
ucode = "uniçº∂e"
write(f, "salut", salut)
write(f, "ucode", ucode)
# Manually write a variable-length string (issue #187)
let
    dtype = HDF5Datatype(HDF5.h5t_copy(HDF5.H5T_C_S1))
    HDF5.h5t_set_size(dtype.id, HDF5.H5T_VARIABLE)
    HDF5.h5t_set_cset(dtype.id, HDF5.cset(typeof(salut)))
    dspace = HDF5.dataspace(salut)
    dset = HDF5.d_create(f, "salut-vlen", dtype, dspace)
    HDF5.h5d_write(dset, dtype, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, [pointer(salut.data)])
end
# Arrays of strings
salut_split = ["Hi", "there"]
write(f, "salut_split", salut_split)
# Arrays of strings as vlen
vlen = HDF5Vlen(salut_split)
d_write(f, "salut_vlen", vlen)
# Empty arrays
empty = Array(UInt32, 0)
write(f, "empty", empty)
# Empty strings
empty_string = ""
write(f, "empty_string", empty_string)
# Empty array of strings
empty_string_array = Compat.ASCIIString[]
write(f, "empty_string_array", empty_string_array)
# Array of empty string
empty_array_of_strings = Compat.ASCIIString[""]
write(f, "empty_array_of_strings", empty_array_of_strings)
# Attributes
species = [["N", "C"]; ["A", "B"]]
attrs(f)["species"] = species
C∞ = 42
attrs(f)["C∞"] = C∞
dset = f["salut"]
label = "This is a string"
attrs(dset)["typeinfo"] = label
close(dset)
# Group
g = g_create(f, "mygroup")
# Test dataset with compression
R = rand(1:20, 20, 40);
g["CompressedA", "chunk", (5,6), "shuffle", (), "compress", 9] = R
g["BloscA", "chunk", (5,6), "shuffle", (), "blosc", 9] = R
close(g)
# Copy group containing dataset
o_copy(f, "mygroup", f, "mygroup2")
# Copy dataset
g = g_create(f, "mygroup3")
o_copy(f["mygroup/CompressedA"], g, "CompressedA")
o_copy(f["mygroup/BloscA"], g, "BloscA")
close(g)
# Writing hyperslabs
dset = d_create(f,"slab",datatype(Float64),dataspace(20,20,5),"chunk",(5,5,1))
Xslab = randn(20,20,5)
for i = 1:5
    dset[:,:,i] = Xslab[:,:,i]
end
# More complex hyperslab and assignment with "incorrect" types (issue #34)
d = d_create(f, "slab2", datatype(Float64), ((10,20),(100,200)), "chunk", (1,1))
d[:,:] = 5
d[1,1] = 4
# 1d indexing
d = d_create(f, "slab3", datatype(Int), ((10,),(-1,)), "chunk", (5,))
@assert d[:] == zeros(Int, 10)
d[3:5] = 3:5
# Create a dataset designed to be deleted
f["deleteme"] = 17.2
close(f)
# Test the h5read/write interface, with attributes
W = copy(reshape(1:120, 15, 8))
Wa = @compat Dict("a"=>1, "b"=>2)
h5write(fn, "newgroup/W", W)
h5writeattr(fn, "newgroup/W", Wa)

# Read the file back in
fr = h5open(fn)
x = read(fr, "Float64")
@assert x == 3.2 && isa(x, Float64)
y = read(fr, "Int16")
@assert y == 4 && isa(y, Int16)
bloscempty = read(fr, "bloscempty")
@assert bloscempty == Int64[] && isa(bloscempty, Vector{Int64})
Af32 = read(fr, "Afloat32")
@assert convert(Matrix{Float32}, A) == Af32
@assert eltype(Af32) == Float32
Af64 = read(fr, "Afloat64")
@assert convert(Matrix{Float64}, A) == Af64
@assert eltype(Af64) == Float64
@assert eltype(fr["Afloat64"]) == Float64  # issue 167
Ai8 = read(fr, "Aint8")
@assert Ai == Ai8
@assert eltype(Ai8) == Int8
Ai16 = read(fr, "Aint16")
@assert Ai == Ai16
@assert eltype(Ai16) == Int16
Ai32 = read(fr, "Aint32")
@assert Ai == Ai32
@assert eltype(Ai32) == Int32
Ai64 = read(fr, "Aint64")
@assert Ai == Ai64
@assert eltype(Ai64) == Int64
Ai8 = read(fr, "Auint8")
@assert Ai == Ai8
@assert eltype(Ai8) == UInt8
Ai16 = read(fr, "Auint16")
@assert Ai == Ai16
@assert eltype(Ai16) == UInt16
Ai32 = read(fr, "Auint32")
@assert Ai == Ai32
@assert eltype(Ai32) == UInt32
Ai64 = read(fr, "Auint64")
@assert Ai == Ai64
@assert eltype(Ai64) == UInt64
salutr = read(fr, "salut")
@assert salut == salutr
salutr = read(fr, "salut-vlen")
@assert salut == salutr
ucoder = read(fr, "ucode")
@assert ucode == ucoder
salut_splitr = read(fr, "salut_split")
@assert salut_splitr == salut_split
salut_vlenr = read(fr, "salut_vlen")
@assert salut_vlenr == salut_split
Rr = read(fr, "mygroup/CompressedA")
@assert Rr == R
Rr2 = read(fr, "mygroup2/CompressedA")
@assert Rr2 == R
Rr3 = read(fr, "mygroup3/CompressedA")
@assert Rr3 == R
Rr4 = read(fr, "mygroup/BloscA")
@assert Rr4 == R
Rr5 = read(fr, "mygroup2/BloscA")
@assert Rr5 == R
Rr6 = read(fr, "mygroup3/BloscA")
@assert Rr6 == R
dset = fr["mygroup/CompressedA"]
@assert get_chunk(dset) == (5,6)
@assert name(dset) == "/mygroup/CompressedA"
dset2 = fr["mygroup/BloscA"]
@assert get_chunk(dset2) == (5,6)
@assert name(dset2) == "/mygroup/BloscA"
Xslabr = read(fr, "slab")
@assert Xslabr == Xslab
Xslabr = h5read(fn, "slab", (:, :, :))  # issue #87
@assert Xslabr == Xslab
Xslab2r = read(fr, "slab2")
target = fill(5, 10, 20)
target[1] = 4
@assert Xslab2r == target
dset = fr["slab3"]
@assert dset[3:5] == [3:5;]
emptyr = read(fr, "empty")
@assert isempty(emptyr)
empty_stringr = read(fr, "empty_string")
@assert empty_stringr == empty_string
empty_string_arrayr = read(fr, "empty_string_array")
@assert empty_string_arrayr == empty_string_array
empty_array_of_stringsr = read(fr, "empty_array_of_strings")
@assert empty_array_of_stringsr == empty_array_of_strings
@assert a_read(fr, "species") == species
@assert a_read(fr, "C∞") == C∞
dset = fr["salut"]
@assert a_read(dset, "typeinfo") == label
close(dset)
# Test ref-based reading
Aref = fr["Afloat64"]
sel = (2:3, 1:2:5)
Asub = Aref[sel...]
@assert Asub == A[sel...]
close(Aref)
# Test iteration, name, and parent
for obj in fr
    @assert filename(obj) == fn
    n = name(obj)
    p = parent(obj)
end
# Test reading multiple vars at once
z = read(fr, "Float64", "Int16")
@assert z == (3.2, 4)
@assert typeof(z) == @compat Tuple{Float64, Int16}
# Test function syntax
read(fr, "Float64") do x
	@assert x == 3.2
end
read(fr, "Float64", "Int16") do x, y
	@assert x == 3.2
	@assert y == 4
end
# Test reading entire file at once
z = read(fr)
@assert z["Float64"] == 3.2
close(fr)

# Test object deletion
fr = h5open(fn, "r+")
@assert exists(fr, "deleteme")
o_delete(fr, "deleteme")
@assert !exists(fr, "deleteme")
close(fr)

# Test the h5read interface
Wr = h5read(fn, "newgroup/W")
@assert Wr == W
rng = (2:3:15, 3:5)
Wr = h5read(fn, "newgroup/W", rng)
@assert Wr == W[rng...]
War = h5readattr(fn, "newgroup/W")
@assert War == Wa

# more do syntax
h5open(fn, "w") do fid
    g_create(fid, "mygroup") do g
        write(g, "x", 3.2)
    end
end
fid = h5open(fn, "r")
@assert names(fid) == Compat.ASCIIString["mygroup"]
g = fid["mygroup"]
@assert names(g) == Compat.ASCIIString["x"]
close(g)
close(fid)

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
    @test names(fid) == Compat.ASCIIString["mygroup"]
    @test names(fid["mygroup"]) == Compat.ASCIIString["x"]
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
    @test names(fid) == Compat.ASCIIString["mygroup"]
    @test names(fid["mygroup"]) == Compat.ASCIIString["x"]
end

# overwrite
h5rewrite(outfile) do fid
    g_create(fid, "mygroup") do g
        write(g, "y", 3.3)
    end
end
@test length(readdir(tmpdir)) == 1
h5open(outfile, "r") do fid
    @test names(fid) == Compat.ASCIIString["mygroup"]
    @test names(fid["mygroup"]) == Compat.ASCIIString["y"]
end

rm(tmpdir, recursive=true)

d = h5read(joinpath(test_path, "compound.h5"), "/data")
@assert typeof(d) == HDF5.HDF5Compound
@assert typeof(d.data) == Array{UInt8,1}
@assert length(d.data) == 128
@test d.membertype == Type[Float64, HDF5.FixedArray{Float64,(3,)}, HDF5.FixedArray{Float64,(3,)}, Float64]
@assert d.membername == Compat.ASCIIString["wgt", "xyz", "uvw", "E"]
@assert d.memberoffset == UInt64[0x00, 0x08, 0x20, 0x38]

# File creation and access property lists
cpl = HDF5Properties(p_create(HDF5.H5P_FILE_CREATE))
cpl["userblock"] = 1024
apl = HDF5Properties(p_create(HDF5.H5P_FILE_ACCESS))
apl["libver_bounds"] = (HDF5.H5F_LIBVER_EARLIEST, HDF5.H5F_LIBVER_LATEST)
h5open(fn, false, true, true, true, false, cpl, apl) do fid
    write(fid, "intarray", [1,2,3])
end
h5open(fn, "r", "libver_bounds",
        (HDF5.H5F_LIBVER_EARLIEST, HDF5.H5F_LIBVER_LATEST)) do fid
    intarray = read(fid, "intarray")
    @test intarray == [1,2,3]
end

fd = h5open(joinpath(test_path, "datasets.h5"), "w")
fd["level_0"] = [1,2,3]
grp = g_create(fd, "mygroup")
fd["mygroup/level_1"] = [4, 5]
grp2 = g_create(grp, "deep_group")
fd["mygroup/deep_group/level_2"] = [6.0, 7.0]
datasets = get_datasets(fd)
@assert sort(map(name, datasets)) ==  ["/level_0", "/mygroup/deep_group/level_2", "/mygroup/level_1"]
close(fd)
