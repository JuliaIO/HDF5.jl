using HDF5
using Test

function create_h5_uint24()
    dt = HDF5.API.h5t_copy(HDF5.API.H5T_STD_U32LE)
    HDF5.API.h5t_set_size(dt, 3)
    HDF5.API.h5t_set_precision(dt, 24)
    return HDF5.Datatype(dt)
end

@testset "Datatypes" begin
    DT = create_h5_uint24()
    @test HDF5.API.h5t_get_size(DT) == 3
    @test HDF5.API.h5t_get_precision(DT) == 24
    @test HDF5.API.h5t_get_offset(DT) == 0
    @test HDF5.API.h5t_get_order(DT) == HDF5.API.H5T_ORDER_LE

    HDF5.API.h5t_set_precision(DT, 12)
    @test HDF5.API.h5t_get_precision(DT) == 12
    @test HDF5.API.h5t_get_offset(DT) == 0

    HDF5.API.h5t_set_offset(DT, 12)
    @test HDF5.API.h5t_get_precision(DT) == 12
    @test HDF5.API.h5t_get_offset(DT) == 12

    io = IOBuffer()
    show(io, DT)
    str = String(take!(io))
    @test contains(str, "undefined integer")
    @test contains(str, "size: 3 bytes")
    @test contains(str, "precision: 12 bits")
    @test contains(str, "offset: 12 bits")
    @test contains(str, "order: little endian byte order")

    HDF5.API.h5t_set_order(DT, HDF5.API.H5T_ORDER_BE)
    @test HDF5.API.h5t_get_order(DT) == HDF5.API.H5T_ORDER_BE
    show(io, DT)
    str = String(take!(io))
    @test contains(str, "order: big endian byte order")
end
