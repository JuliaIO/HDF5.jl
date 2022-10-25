#!/bin/env julia
#
# Runs JuliaFormatter on the repository
# Invoke this script directly, `./contrib/format/format.jl`
# or via `julia --project=contrib/format contrib/format/format.jl`

# Install the project if not the current project environment
if Base.active_project() != joinpath(@__DIR__, "Project.toml")
    using Pkg
    Pkg.activate(@__DIR__)
    Pkg.resolve()
    Pkg.instantiate()
end

include("JuliaFormatterTool.jl")

using .JuliaFormatterTool

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) == 0
        run_formatter_loop()
    else
        run_formatter_loop(ARGS[1])
    end
end
