using HDF5
using Test
using Pkg

HDF5.Filters.@dev_embedded_filters

@info "libhdf5 v$(HDF5.API.h5_get_libversion())"

# To debug HDF5.jl tests, uncomment the next line
# ENV["JULIA_DEBUG"] = "Main"

@testset verbose=true "HDF5.jl" begin

@debug "plain"
include("plain.jl")
@debug "compound"
include("compound.jl")
@debug "custom"
include("custom.jl")
@debug "reference"
include("reference.jl")
@debug "dataspace"
include("dataspace.jl")
@debug "hyperslab"
include("hyperslab.jl")
@debug "readremote"
include("readremote.jl")
@debug "extend_test"
include("extend_test.jl")
@debug "gc"
include("gc.jl")
@debug "external"
include("external.jl")
@debug "swmr"
include("swmr.jl")
@debug "mmap"
include("mmap.jl")
@debug "properties"
include("properties.jl")
@debug "table"
include("table.jl")
@debug "filter"
include("filter.jl")
@debug "chunkstorage"
include("chunkstorage.jl")
@debug "fileio"
include("fileio.jl")
@debug "filter test utils"
include("filters/FilterTestUtils.jl")

using MPI
if HDF5.has_parallel()
    # basic MPI tests, for actual parallel tests we need to run in MPI mode
    include("mpio.jl")
end

# Clean up after all resources
HDF5.API.h5_close()

end
