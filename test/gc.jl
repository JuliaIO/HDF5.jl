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
    memtype_id = HDF5.API.h5t_create(HDF5.API.H5T_COMPOUND, 2*sizeof(Float64))
    HDF5.API.h5t_insert(memtype_id, "real", 0, HDF5.hdf5_type_id(Float64))
    HDF5.API.h5t_insert(memtype_id, "imag", sizeof(Float64), HDF5.hdf5_type_id(Float64))
    dt = HDF5.Datatype(memtype_id)
    commit_datatype(file, "dt", dt)
    ds = dataspace((2,))
    d = create_dataset(file, "d", dt, ds)
    g = create_group(file, "g")
    a = create_attribute(file, "a", dt, ds)
    @gcvalid dt ds d g a
    close(file)

    @closederror read(d)
    for obj in (d, g)
        @closederror read_attribute(obj, "a")
        @closederror write_attribute(obj, "a", 1)
    end
    for obj in (g, file)
        @closederror open_dataset(obj, "d")
        @closederror read_dataset(obj, "d")
        @closederror write_dataset(obj, "d", 1)
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
    a = attributes(file)["a"]
    @gcvalid dt ds d g a
    close(file)
end
GC.enable(true)

let plist = HDF5.init!(HDF5.FileAccessProperties())  # related to issue #620
    HDF5.API.h5p_close(plist)
    @test_nowarn finalize(plist)
end

rm(fn)

end # testset gc
