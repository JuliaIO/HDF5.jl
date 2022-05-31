module API

import Libdl
using Base: StringVector

const depsfile = joinpath(@__DIR__, "..", "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
          "and restart Julia.")
end

include("types.jl")
include("error.jl")
include("functions.jl") # core API ccall wrappers
include("helpers.jl")

end
