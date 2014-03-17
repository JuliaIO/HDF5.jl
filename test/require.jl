using HDF5, JLD

x = jldopen("require.jld") do file
    read(file, "x")
end
@assert typeof(x) == JLDTest
@assert x.data == 5
