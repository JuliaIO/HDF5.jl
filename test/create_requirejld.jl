using HDF5, JLD
include("JLDTest.jl")
x = JLDTest(5)
jldopen("require.jld", "w") do file
    addrequire(file, "JLDTest.jl")
    write(file, "x", x)
end
