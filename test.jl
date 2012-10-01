load("hdf5.jl")
import HDF5Mod.*
import HDF5Mod

# Create a new file
fn = "/tmp/test.h5"
fid = h5open(fn, "w")
# Create arrays of different types
A = randn(3,5)
write(fid, "Afloat64", float64(A))
write(fid, "Afloat32", float32(A))
Ai = randi(20, 2, 4)
write(fid, "Aint8", int8(Ai))
write(fid, "Aint16", int16(Ai))
write(fid, "Aint32", int32(Ai))
write(fid, "Aint64", int64(Ai))
write(fid, "Auint8", uint8(Ai))
write(fid, "Auint16", uint16(Ai))
write(fid, "Auint32", uint32(Ai))
write(fid, "Auint64", uint64(Ai))
# Test strings
salut = "Hi there"
write(fid, "salut", salut)
# Test array of arrays
comp1 = [1 2; 3 4]
comp2 = [5 6 7; 8 9 10]
AB = Array{Int}[comp1, comp2]
write(fid, "AB", AB)
# Test dataset with compression
R = randi(20, 200, 400);
dtype = HDF5Mod.datatype(R)
dspace = HDF5Mod.dataspace(R)
p = properties()
p["chunk"] = (20,20)
p["compress"] = 9
dset = HDF5Mod.dataset(fid, "CompressedA", dtype, dspace, HDF5Properties(), p)
write(dset, R)
close(dset)
close(p)
close(dtype)
close(dspace)
close(fid)

# Read the file back in
fidr = h5open(fn)
Af32 = read(fidr, "Afloat32")
@assert float32(A) == Af32
@assert eltype(Af32) == Float32
Af64 = read(fidr, "Afloat64")
@assert float64(A) == Af64
@assert eltype(Af64) == Float64
Ai8 = read(fidr, "Aint8")
@assert Ai == Ai8
@assert eltype(Ai8) == Int8
Ai16 = read(fidr, "Aint16")
@assert Ai == Ai16
@assert eltype(Ai16) == Int16
Ai32 = read(fidr, "Aint32")
@assert Ai == Ai32
@assert eltype(Ai32) == Int32
Ai64 = read(fidr, "Aint64")
@assert Ai == Ai64
@assert eltype(Ai64) == Int64
Ai8 = read(fidr, "Auint8")
@assert Ai == Ai8
@assert eltype(Ai8) == Uint8
Ai16 = read(fidr, "Auint16")
@assert Ai == Ai16
@assert eltype(Ai16) == Uint16
Ai32 = read(fidr, "Auint32")
@assert Ai == Ai32
@assert eltype(Ai32) == Uint32
Ai64 = read(fidr, "Auint64")
@assert Ai == Ai64
@assert eltype(Ai64) == Uint64
salutr = read(fidr, "salut")
@assert salut == salutr
ABr = read(fidr, "AB")
@assert AB == ABr
Rr = read(fidr, "CompressedA")
@assert Rr == R
# Test ref-based reading
Aref = fidr["Afloat64"]
sel = (2:3, 1:2:5)
Asub = Aref[sel...]
@assert Asub == A[sel...]
close(Aref)
close(fidr)
