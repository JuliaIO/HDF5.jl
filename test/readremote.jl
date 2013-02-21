# Check that we can read the official HDF5 example files
urlbase = "http://www.hdfgroup.org/ftp/HDF5/examples/files/exbyapi/"

using HDF5

fcmp = [0 1 2 3 4 5 6;
    2 1.66667 2.4 3.28571 4.22222 5.18182 6.15385;
    4 2.33333 2.8 3.57143 4.44444 5.36364 6.30769;
    6 3 3.2 3.85714 4.66667 5.54545 6.46154]'
icmp = [0 -1 -2 -3 -4 -5 -6;
    0 0 0 0 0 0 0;
    0 1 2 3 4 5 6;
    0 2 4 6 8 10 12]'
scmp = ["Parting", "is such", "sweet", "sorrow."]
vicmp = Array{Int32}[[3,2,1],[1,1,2,3,5,8,13,21,34,55,89,144]]
opq = Array{Uint8}[[0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x30],
                   [0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x31],
                   [0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x32],
                   [0x4f, 0x50, 0x41, 0x51, 0x55, 0x45, 0x33]]

const savedir = joinpath(tempdir(), "h5")
if !isdir(savedir)
    mkdir(savedir)
end
function getfile(name)
    file = joinpath(savedir, name)
    if !isfile(file)
        file = download(urlbase*name, file)
    end
    file
end

file = getfile("h5ex_t_floatatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
@assert norm(a - fcmp) < 1e-5
close(fid)

file = getfile("h5ex_t_float.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@assert norm(d - fcmp) < 1e-5
close(fid)

file = getfile("h5ex_t_intatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
@assert a == icmp
close(fid)

file = getfile("h5ex_t_int.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@assert d == icmp
close(fid)

file = getfile("h5ex_t_objrefatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
g = fid[a[1]]
@assert isa(g, HDF5Group)
ds2 = fid[a[2]]
ds2v = read(ds2)
@assert isa(ds2v, Array{Int32})
@assert isempty(ds2v)
close(fid)

file = getfile("h5ex_t_objref.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
g = fid[d[1]]
@assert isa(g, HDF5Group)
ds2 = fid[d[2]]
ds2v = read(ds2)
@assert isa(ds2v, Array{Int32})
@assert isempty(ds2v)
close(fid)

file = getfile("h5ex_t_stringatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
@assert a == scmp
close(fid)

file = getfile("h5ex_t_string.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@assert d == scmp
close(fid)

file = getfile("h5ex_t_vlenatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
@assert a == vicmp
close(fid)

file = getfile("h5ex_t_vlen.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@assert d == vicmp
close(fid)

file = getfile("h5ex_t_vlstringatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
@assert a == scmp
close(fid)

file = getfile("h5ex_t_vlstring.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@assert d == scmp
close(fid)

file = getfile("h5ex_t_opaqueatt.h5")
fid = h5open(file, "r")
dset = fid["DS1"]
a = a_read(dset, "A1")
@assert a.tag == "Character array"
@assert a.data == opq
close(fid)

file = getfile("h5ex_t_opaque.h5")
fid = h5open(file, "r")
d = read(fid, "DS1")
@assert d.tag == "Character array"
@assert d.data == opq
close(fid)
