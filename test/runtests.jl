using HDF5
using Compat.Test
using Compat.Distributed
@static if VERSION ≥ v"0.7.0-DEV.3637"
    using Pkg
end

println("HDF5 version ", HDF5.h5_get_libversion())

include("plain.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("external.jl")
include("swmr.jl")
if get(Pkg.installed(), "MPI", nothing) !== nothing
  # basic MPI tests, for actual parallel tests we need to run in MPI mode
  include("mpio.jl")
end
