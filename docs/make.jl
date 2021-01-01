using Documenter
using HDF5
using MPI  # needed to generate docs for parallel HDF5 API


makedocs(;
    sitename="HDF5.jl",
    modules=[HDF5],
    authors="Mustafa Mohamad <mus-m@outlook.com> and contributors",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaIO.github.io/HDF5.jl",
        assets=String[],
        sidebar_sitename=false,
    ),
    pages=[
        "Home" => "index.md",
        "Low-level library bindings" => "api_bindings.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaIO/HDF5.jl.git",
    push_preview=true,
)
