using HDF5
using Test
using Pkg

println("HDF5 version ", HDF5.h5_get_libversion())

include("plain.jl")
include("compound.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("external.jl")
include("swmr.jl")
include("mmap.jl")
if Sys.islinux()
  include("virtual.jl")
end
if get(Pkg.installed(), "MPI", nothing) !== nothing
  # basic MPI tests, for actual parallel tests we need to run in MPI mode
  include("mpio.jl")
end
