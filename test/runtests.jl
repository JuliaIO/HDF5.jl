using HDF5
HDF5.init()

# backwards-compatible test_throws (works in julia 0.2)
macro test_throws_02(args...)
    if VERSION >= v"0.3-"
        :(@test_throws($(esc(args[1])), $(esc(args[2]))))
    else
        :(@test_throws($(esc(args[2]))))
    end
end

include("plain.jl")
include("jld.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("require.jl")
if Pkg.installed("DataFrames") != nothing
    include("jld_dataframe.jl")
end
