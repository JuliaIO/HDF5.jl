using HDF5

runtest(filename) = (println(filename); include(filename))

runtest("plain.jl")
runtest("jld.jl")
runtest("readremote.jl")
runtest("extend_test.jl")
runtest("gc.jl")
runtest("require.jl")
if Pkg.installed("DataFrames") != nothing
    runtest("jld_dataframe.jl")
end
