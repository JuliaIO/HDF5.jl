"""
    JuliaFormatterTool

Implements a script that runs a simple loop that runs `JuliaFormatter.format` on
every iteration after the user presses enter.
"""
module JuliaFormatterTool

export run_formatter_loop

using JuliaFormatter

# This tool lives in <repo>/contrib/format/, format <repo> by default
const default_target_dir = joinpath(dirname(dirname(@__DIR__)))

"""
    run_formatter_loop(target_dir = $default_target_dir)

This function runs a simple loop that runs `JuliaFormatter.format` on
every iteration, every time the user presses enter.
"""
function run_formatter_loop(target_dir::AbstractString=default_target_dir)
    printstyled("Welcome to Julia Formatter Tool!\n"; color=:cyan, bold=true)
    printstyled("--------------------------------\n"; color=:cyan, bold=true)
    let running::Bool = true
        while running
            println()
            printstyled(
                "Press enter to format the directory $target_dir or `q[enter]` to quit\n";
                color=:light_cyan
            )
            printstyled("format.jl> "; color=:green, bold=true)
            input = readline()
            running = input != "q" && input != "quit" && !startswith(input, "exit")
            if running
                println("Applying JuliaFormatter...")
                @info "Is the current directory formatted?" target_dir format(target_dir)
            end
        end
        println("Thank you for formatting HDF5.jl. Have a nice day!")
    end
    return nothing
end

end # module JuliaFormatterTool
