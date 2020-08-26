using Random, Test, HDF5

import HDF5.datatype

struct Simple
  a::Float64
  b::Int
end

function datatype(::Type{Simple})
  dtype = HDF5.h5t_create(HDF5.H5T_COMPOUND, sizeof(Simple))
  HDF5.h5t_insert(dtype, "a", fieldoffset(Simple, 1), datatype(Float64))
  HDF5.h5t_insert(dtype, "b", fieldoffset(Simple, 2), datatype(Int))
  HDF5Datatype(dtype)
end

@testset "custom" begin
  N = 10
  v = [Simple(rand(Float64), rand(Int)) for _ in 1:N]

  fn = tempname()
  h5open(fn, "w") do h5f
    dtype = datatype(Simple)
    dspace = dataspace(v)
    dset = HDF5.h5d_create(h5f.id, "data", dtype.id, dspace.id)
    HDF5.h5d_write(dset, dtype.id, v)
  end

  h5open(fn, "r") do h5f
    dset = h5f["data"]
    @test_throws ErrorException read(dset, Float64)
    @test_throws ErrorException read(dset, Union{Float64, Int})

    v_read = read(dset, Simple)
    @test v_read == v

    v_read = read(h5f, "data"=>Simple)
    @test v_read == v
  end

  v_read = h5read(fn, "data"=>Simple)
  @test v_read == v
end
