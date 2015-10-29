using HDF5

runtest(filename) = (println(filename); include(filename))

runtest("plain.jl")
runtest("readremote.jl")
runtest("extend_test.jl")
runtest("gc.jl")
runtest("external.jl")

nothing
