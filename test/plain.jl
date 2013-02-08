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
write(f, "salut", salut)
# Arrays of strings
salut_split = ["Hi", "there"]
write(f, "salut_split", salut_split)
# Empty arrays
empty = Array(Uint32, 0)
write(f, "empty", empty)
# Attributes
dset = f["salut"]
label = "This is a string"
attrs(dset)["typeinfo"] = label
close(dset)
# Group
g = g_create(f, "mygroup")
# Test dataset with compression
R = rand(1:20, 20, 40);
g["CompressedA", "chunk", (5,5), "compress", 9] = R
close(g)
# Create a dataset designed to be deleted
f["deleteme"] = 17.2
close(f)

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
salut_splitr = read(fr, "salut_split")
@assert salut_splitr == salut_split
Rr = read(fr, "mygroup/CompressedA")
@assert Rr == R
dset = fr["mygroup/CompressedA"]
@assert name(dset) == "/mygroup/CompressedA"
emptyr = read(fr, "empty")
@assert isempty(emptyr)
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
close(fr)

# Test object deletion
fr = h5open(fn, "r+")
@assert exists(fr, "deleteme")
o_delete(fr, "deleteme")
@assert !exists(fr, "deleteme")
close(fr)
