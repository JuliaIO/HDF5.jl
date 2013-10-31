include("plain.jl")
include("jld.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
if Pkg.installed("DataFrames")
    include("jld_dataframe.jl")
end
