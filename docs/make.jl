using Documenter
using HDF5
using H5Zblosc
using H5Zbzip2
using H5Zlz4
using H5Zzstd
using MPI  # needed to generate docs for parallel HDF5 API

# Used in index.md to filter the autodocs list
not_low_level_api(m::Method) = !endswith(String(m.file), "src/api.jl")
not_low_level_api(f::Function) = all(not_low_level_api, methods(f))
not_low_level_api(o) = true

# defined on separate page
not_low_level_api(::Type{<:HDF5.Properties}) = false

# Manually-defined low-level API (in source file src/api_helpers.jl)
not_low_level_api(::typeof(HDF5.API.h5p_get_class_name)) = false
not_low_level_api(::typeof(HDF5.API.h5t_get_member_name)) = false
not_low_level_api(::typeof(HDF5.API.h5t_get_tag)) = false

makedocs(;
    sitename="HDF5.jl",
    modules=[HDF5, H5Zblosc, H5Zbzip2, H5Zlz4, H5Zzstd],
    authors="Mustafa Mohamad <mus-m@outlook.com> and contributors",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaIO.github.io/HDF5.jl",
        assets=String[],
        sidebar_sitename=false
    ),
    strict=true,
    pages=[
        "Home" => "index.md",
        "Interface" => [
            "interface/configuration.md",
            "interface/files.md",
            "interface/groups.md",
            "interface/dataspaces.md",
            "interface/dataset.md",
            "interface/attributes.md",
            "interface/properties.md",
            "interface/filters.md",
            "interface/objects.md",
        ],
        "mpi.md",
        "Low-level library bindings" => "api_bindings.md",
        "Additional Resources" => "resources.md",
    ]
)

deploydocs(; repo="github.com/JuliaIO/HDF5.jl.git", push_preview=true)
