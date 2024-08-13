using Documenter
using HDF5
using H5Zblosc
using H5Zbzip2
using H5Zlz4
using H5Zzstd
using H5Zbitshuffle
using MPI  # needed to generate docs for parallel HDF5 API

DocMeta.setdocmeta!(HDF5, :DocTestSetup, :(using HDF5); recursive=true)

makedocs(;
    sitename="HDF5.jl",
    modules=[
        HDF5,
        H5Zblosc,
        H5Zbzip2,
        H5Zlz4,
        H5Zzstd,
        H5Zbitshuffle,
        Base.get_extension(HDF5, :BloscExt),
        Base.get_extension(HDF5, :CodecBzip2Ext),
        Base.get_extension(HDF5, :CodecLz4Ext),
        Base.get_extension(HDF5, :CodecZstdExt),
        Base.get_extension(HDF5, :bitshuffle_jll_ext),
    ],
    authors="Mustafa Mohamad <mus-m@outlook.com> and contributors",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaIO.github.io/HDF5.jl",
        assets=String[],
        sidebar_sitename=false,
        size_threshold_ignore=["api_bindings.md",]
    ),
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
