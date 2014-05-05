using HDF5, JLD

module JLDTemp
using HDF5, JLD
include("JLDTest.jl")

function create()
    x = JLDTest(5)
    jldopen("require.jld", "w") do file
        addrequire(file, joinpath(Pkg.dir(), "HDF5", "test", "JLDTest.jl"))
        write(file, "x", x, rootmodule="JLDTemp")
    end
end
end

JLDTemp.create()

x = jldopen("require.jld") do file
    read(file, "x")
end
@assert typeof(x) == JLDTest
@assert x.data == 5
rm("require.jld")
