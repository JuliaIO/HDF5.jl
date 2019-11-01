using Random, Test, HDF5

import HDF5.datatype
import Base.unsafe_convert

struct foo
  a::Float64
  b::String
  c::String
  d::Array{ComplexF64,2}
end

struct foo_hdf5
  a::Float64
  b::Cstring
  c::NTuple{10, Cchar}
  d::NTuple{9, ComplexF64}
end

function unsafe_convert(::Type{foo_hdf5}, x::foo)
  foo_hdf5(x.a, Base.unsafe_convert(Cstring, x.b), ntuple(i -> x.c[i], length(x.c)), ntuple(i -> x.d[i], length(x.d)))
end

function datatype(::Type{foo_hdf5})
  dtype = HDF5.h5t_create(HDF5.H5T_COMPOUND, sizeof(foo_hdf5))
  HDF5.h5t_insert(dtype, "a", fieldoffset(foo_hdf5, 1), datatype(Float64))

  vlenstr_dtype = HDF5.h5t_copy(HDF5.H5T_C_S1)
  HDF5.h5t_set_size(vlenstr_dtype, HDF5.H5T_VARIABLE)
  HDF5.h5t_set_cset(vlenstr_dtype, HDF5.H5T_CSET_UTF8)
  HDF5.h5t_insert(dtype, "b", fieldoffset(foo_hdf5, 2), vlenstr_dtype)

  fixedstr_dtype = HDF5.h5t_copy(HDF5.H5T_C_S1)
  HDF5.h5t_set_size(fixedstr_dtype, 10 * sizeof(Cchar))
  HDF5.h5t_set_cset(fixedstr_dtype, HDF5.H5T_CSET_UTF8)
  HDF5.h5t_insert(dtype, "c", fieldoffset(foo_hdf5, 3), fixedstr_dtype)

  hsz = HDF5.Hsize[3,3]
  array_dtype = HDF5.h5t_array_create(datatype(ComplexF64).id, 2, hsz)
  HDF5.h5t_insert(dtype, "d", fieldoffset(foo_hdf5, 4), array_dtype)

  HDF5Datatype(dtype)
end

@testset "compound" begin
  N = 10
  v = [foo(rand(), randstring(rand(10:100)), randstring(10), rand(ComplexF64, 3,3)) for _ in 1:N]
  v_write = unsafe_convert.(foo_hdf5, v)

  fn = tempname()
  h5open(fn, "w") do h5f
    dtype = datatype(foo_hdf5)
    space = dataspace(v_write)
    dset = HDF5.h5d_create(h5f.id, "data", dtype.id, space.id)
    HDF5.h5d_write(dset, dtype.id, v_write)
  end

  v_read = h5read(fn, "data")
  for field in (:a, :b, :c, :d)
    f = x -> getfield(x, field)
    @test f.(v) == f.(v_read)
  end
end
