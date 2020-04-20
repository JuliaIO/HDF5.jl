using HDF5
using Test

macro gcvalid(args...)
    Expr(:block, quote
        GC.enable(true)
        GC.gc()
        GC.enable(false)
    end,
    [:(@test HDF5.isvalid($(esc(x)))) for x in args]...)
end

macro closederror(x)
    quote
        try
            $(esc(x))
        catch e
            isa(e, ErrorException) || rethrow(e)
            e.msg == "File or object has been closed" || error("Attempt to access closed object did not throw")
        end
    end
end

@testset "gc" begin

GC.enable(false)
fn = tempname()
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

    @closederror read(d)
    for obj in (d, g)
        @closederror a_read(obj, "a")
        @closederror a_write(obj, "a", 1)
    end
    for obj in (g, file)
        @closederror d_open(obj, "d")
        @closederror d_read(obj, "d")
        @closederror d_write(obj, "d", 1)
        @closederror read(obj, "x")
        @closederror write(obj, "x", "y")
    end
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
GC.enable(true)
rm(fn)

end # testset gc
