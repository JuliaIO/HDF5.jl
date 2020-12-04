using HDF5
using Test
using Pkg

println("HDF5 version ", HDF5.h5_get_libversion())

@testset "HDF5.jl" begin

include("plain.jl")
include("compound.jl")
include("custom.jl")
include("reference.jl")
include("dataspace.jl")
include("hyperslab.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("external.jl")
include("swmr.jl")
include("mmap.jl")
include("properties.jl")

try
    using MPI
    # basic MPI tests, for actual parallel tests we need to run in MPI mode
    include("mpio.jl")
catch
end

end
