module API

import Libdl
using Base: StringVector

const depsfile = joinpath(@__DIR__, "..", "..",  "deps", "deps.jl")

if isfile(depsfile)
    include(depsfile)
else
    error("HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
          "and restart Julia.")
end


include("types.jl")
include("functions.jl")
include("helpers.jl")

end # module
