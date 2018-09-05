using HDF5
using Test

@testset "h5tb" begin
    mktemp() do fname, io
        h5open(fname, "w") do f
            fv = 3.14
            data = [1.,2.,3.,4.,5.,6.]
            h5t = datatype(data[1])
            title = "lal"
            name = "mym"
            nfield = 2
            nrec = 3
            recsize = 16
            colname = ["f1", "f2"]
            offset = [0,8]
            tid = [h5t.id, h5t.id]
            chunk = 7
            fillvalue = [3.14, 2.71]
            compress = 1
            HDF5.h5tb_make_table(title, f.id, name, nfield, nrec, recsize, colname, offset, tid, chunk, fillvalue, compress, data)
            fieldsize = [8,8]
            HDF5.h5tb_append_records(f.id, name, nrec, recsize, offset, fieldsize, data)
            HDF5.h5tb_write_records(f.id, name, 1, 4, recsize, offset, fieldsize, convert.(Float64,collect(1:8) .+ 20))
            buf = fill(0., 100)
            HDF5.h5tb_read_table(f.id, name, recsize, offset, fieldsize, buf)
            @test buf[1:12] == [1.0, 2.0, 21.0, 22.0, 23.0, 24.0, 25.0, 26.0, 27.0, 28.0, 5.0, 6.0]
            buf .= 0
            HDF5.h5tb_read_records(f.id, name, 2, 3, recsize, offset, fieldsize, buf)
            @test buf[1:6] == collect(23:28)

            _nfield = Ref{HDF5.Hsize}(0)
            _nrec = Ref{HDF5.Hsize}(0)
            HDF5.h5tb_get_table_info(f.id, name, _nfield, _nrec)
            @test _nfield[] == nfield
            @test _nrec[] == 6

            _colnamebuf = [fill(0xff, 10), fill(0xff,10)]
            _fieldsize = Vector{Csize_t}(undef, _nfield[])
            _offset = Vector{Csize_t}(undef, _nfield[])
            _recsize = Ref{Csize_t}(0)
            HDF5.h5tb_get_field_info(f.id, name, _colnamebuf, _fieldsize, _offset, _recsize)
            _colname = [String(d[1:findfirst(isequal(0x00),d)-1]) for d in _colnamebuf]
            @test _colname == colname
            @test _fieldsize == fieldsize
            @test _offset == offset
            @test _recsize[] == recsize
        end
    end
end
