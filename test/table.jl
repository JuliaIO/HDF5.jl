using HDF5
using Test


hf = h5open(tempname(), "w")

fv = 3.14
data = [1.,2.,3.,4.,5.,6.]
floatsize = sizeof(data[1])
h5t = datatype(data[1])
title = "lal"
name = "mym"
nfield = 2
nrec = 3
recsize = nfield * floatsize
colname = ["f1_verylongnameforfun", "f2"]
offset = [0,floatsize]
tid = [h5t.id, h5t.id]
chunk = 7
fillvalue = [3.14, 2.71]
compress = 1

HDF5.API.h5tb_make_table(title, hf, name, nfield, nrec, recsize, colname, offset, tid, chunk, fillvalue, compress, data)
fieldsize = [floatsize, floatsize]
HDF5.API.h5tb_append_records(hf, name, nrec, recsize, offset, fieldsize, data)
HDF5.API.h5tb_write_records(hf, name, 1, 4, recsize, offset, fieldsize, collect(1:8) .+ 20.0)
buf = fill(0.0, 100)

HDF5.API.h5tb_read_table(hf, name, recsize, offset, fieldsize, buf)
@test buf[1:12] == [1.0, 2.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 5.0, 6.0]
buf .= 0.0
HDF5.API.h5tb_read_records(hf, name, 2, 3, recsize, offset, fieldsize, buf)
@test buf[1:6] == collect(23:28)

h5_nfields, h5_nrec = HDF5.API.h5tb_get_table_info(hf, name)
@test h5_nfields == nfield
@test h5_nrec == 6

h5_colname, h5_fieldsize, h5_offset, h5_recsize = HDF5.API.h5tb_get_field_info(hf, name)

@test h5_colname == colname
@test h5_fieldsize == fieldsize
@test h5_offset == offset
@test h5_recsize == recsize

close(hf)
