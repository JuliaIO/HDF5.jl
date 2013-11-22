using HDF5

# Create a new file
fn = joinpath(tempdir(),"test.h5")
f = h5open(fn, "w")
# Write scalars
f["Float64"] = 3.2
f["Int16"] = int16(4)
# Create arrays of different types
A = randn(3,5)
write(f, "Afloat64", float64(A))
write(f, "Afloat32", float32(A))
Ai = rand(1:20, 2, 4)
write(f, "Aint8", int8(Ai))
f["Aint16"] = int16(Ai)
write(f, "Aint32", int32(Ai))
write(f, "Aint64", int64(Ai))
write(f, "Auint8", uint8(Ai))
write(f, "Auint16", uint16(Ai))
write(f, "Auint32", uint32(Ai))
write(f, "Auint64", uint64(Ai))
# Test strings
salut = "Hi there"
ucode = "uniçº∂e"
write(f, "salut", salut)
write(f, "ucode", ucode)
# Arrays of strings
salut_split = ["Hi", "there"]
write(f, "salut_split", salut_split)
# Empty arrays
empty = Array(Uint32, 0)
write(f, "empty", empty)
# Empty strings
empty_string = ""
write(f, "empty_string", empty_string)
# Empty array of strings
empty_string_array = ASCIIString[]
write(f, "empty_string_array", empty_string_array)
# Array of empty string
empty_array_of_strings = ASCIIString[""]
write(f, "empty_array_of_strings", empty_array_of_strings)
# Attributes
dset = f["salut"]
label = "This is a string"
attrs(dset)["typeinfo"] = label
close(dset)
# Group
g = g_create(f, "mygroup")
# Test dataset with compression
R = rand(1:20, 20, 40);
g["CompressedA", "chunk", (5,6), "compress", 9] = R
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
# Test the h5read/write interface
W = reshape(1:120, 15, 8)
h5write(fn, "newgroup/W", W)

# Read the file back in
fr = h5open(fn)
x = read(fr, "Float64")
@assert x == 3.2 && isa(x, Float64)
y = read(fr, "Int16")
@assert y == 4 && isa(y, Int16)
Af32 = read(fr, "Afloat32")
@assert float32(A) == Af32
@assert eltype(Af32) == Float32
Af64 = read(fr, "Afloat64")
@assert float64(A) == Af64
@assert eltype(Af64) == Float64
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
@assert eltype(Ai8) == Uint8
Ai16 = read(fr, "Auint16")
@assert Ai == Ai16
@assert eltype(Ai16) == Uint16
Ai32 = read(fr, "Auint32")
@assert Ai == Ai32
@assert eltype(Ai32) == Uint32
Ai64 = read(fr, "Auint64")
@assert Ai == Ai64
@assert eltype(Ai64) == Uint64
salutr = read(fr, "salut")
@assert salut == salutr
ucoder = read(fr, "ucode")
@assert ucode == ucoder
salut_splitr = read(fr, "salut_split")
@assert salut_splitr == salut_split
Rr = read(fr, "mygroup/CompressedA")
@assert Rr == R
dset = fr["mygroup/CompressedA"]
@assert get_chunk(dset) == (5,6)
@assert name(dset) == "/mygroup/CompressedA"
Xslabr = read(fr, "slab")
@assert Xslabr == Xslab
Xslab2r = read(fr, "slab2")
target = fill(5, 10, 20)
target[1] = 4
@assert Xslab2r == target
dset = fr["slab3"]
@assert dset[3:5] == 3:5
emptyr = read(fr, "empty")
@assert isempty(emptyr)
empty_stringr = read(fr, "empty_string")
@assert empty_stringr == empty_string
empty_string_arrayr = read(fr, "empty_string_array")
@assert empty_string_arrayr == empty_string_array
empty_array_of_stringsr = read(fr, "empty_array_of_strings")
@assert empty_array_of_stringsr == empty_array_of_strings
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
@assert typeof(z) == (Float64, Int16)
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
