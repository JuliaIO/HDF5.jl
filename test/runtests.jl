using HDF5
using Test
using Pkg

@info "libhdf5 v$(HDF5.API.h5_get_libversion())"

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
include("table.jl")

    
try
    using MPI
    if HDF5.has_parallel()
        # basic MPI tests, for actual parallel tests we need to run in MPI mode
        include("mpio.jl")
    end
catch
end

end
