using HDF5
using Documenter

makedocs(;
    modules=[HDF5],
    authors="Mustafa Mohamad <mus-m@outlook.com> and contributors",
    repo="https://github.com/JuliaIO/HDF5.jl/blob/{commit}{path}#L{line}",
    sitename="HDF5.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaIO.github.io/HDF5.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaIO/HDF5.jl",
)
