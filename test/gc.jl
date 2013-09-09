using HDF5

macro gcvalid(args...)
	Expr(:block, quote
		gc_enable()
		gc()
		gc_disable()
	end,
	[:(@assert HDF5.isvalid($x)) for x in args]...)
end

gc_disable()
fn = joinpath(tempdir(),"test.h5")
for i = 1:10
	file = h5open(fn, "w")
    memtype_id = HDF5.h5t_create(HDF5.H5T_COMPOUND, 2*sizeof(Float64))
    HDF5.h5t_insert(memtype_id, "real", 0, HDF5.hdf5_type_id(Float64))
    HDF5.h5t_insert(memtype_id, "imag", sizeof(Float64), HDF5.hdf5_type_id(Float64))
    dt = HDF5Datatype(memtype_id)
    t_commit(file, "dt", dt)
    ds = dataspace((2,))
	d = d_create(file, "d", dt, ds)
	g = g_create(file, "g")
	a = a_create(file, "a", dt, ds)
	@gcvalid dt ds d g a
	close(file)
end
for i = 1:10
	file = h5open(fn, "r")
	dt = file["dt"]
	d = file["d"]
	ds = dataspace(d)
	g = file["g"]
	a = attrs(file)["a"]
	@gcvalid dt ds d g a
	close(file)
end