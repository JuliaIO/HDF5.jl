using HDF5
using Base.Test
using Compat.Distributed

include("plain.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("external.jl")
include("swmr.jl")
