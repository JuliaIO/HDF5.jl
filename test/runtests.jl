using HDF5

include("plain.jl")
include("jld.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("require.jl")
include("custom_serialization.jl")
if Pkg.installed("DataFrames") != nothing
    include("jld_dataframe.jl")
end
