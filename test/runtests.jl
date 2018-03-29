using HDF5
using Compat.Test
using Compat.Distributed
using Compat.SharedArrays

include("plain.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("external.jl")
include("swmr.jl")
