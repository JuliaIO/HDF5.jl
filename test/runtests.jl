# Work around JuliaLang/Pkg.jl#2500
if VERSION < v"1.8-"
    test_project = first(Base.load_path())
    preferences_file = "../LocalPreferences.toml"
    test_preferences_file = joinpath(dirname(test_project), "LocalPreferences.toml")
    if isfile(preferences_file) && !isfile(test_preferences_file)
        cp(preferences_file, test_preferences_file)
        @info "copied LocalPreferences.toml to $test_preferences_file"
    end
end

using HDF5
using Test
using Pkg
filter_path = joinpath(dirname(pathof(HDF5)), "..", "filters")
if !Base.BinaryPlatforms.CPUID.test_cpu_feature(Base.BinaryPlatforms.CPUID.JL_X86_avx2)
    Pkg.add(PackageSpec(; name="Blosc_jll", version=v"1.21.2+0"))
end
Pkg.develop([
    PackageSpec(; path=joinpath(filter_path, "H5Zblosc")),
    PackageSpec(; path=joinpath(filter_path, "H5Zbzip2")),
    PackageSpec(; path=joinpath(filter_path, "H5Zlz4")),
    PackageSpec(; path=joinpath(filter_path, "H5Zzstd")),
    PackageSpec(; path=joinpath(filter_path, "H5Zbitshuffle")),
    PackageSpec(; path=joinpath(filter_path, "H5ZChunkCodecZstd")),
    PackageSpec(; path=joinpath(filter_path, "H5ZChunkCodecBzip2")),
])

@info "libhdf5 v$(HDF5.API.h5_get_libversion())"

# To debug HDF5.jl tests, uncomment the next line
# ENV["JULIA_DEBUG"] = "Main"

@testset "HDF5.jl" begin
    @debug "plain"
    include("plain.jl")
    @debug "create_dataset"
    include("create_dataset.jl")
    @debug "strings"
    include("strings.jl")
    @debug "api"
    include("api.jl")
    @debug "compound"
    include("compound.jl")
    @debug "custom"
    include("custom.jl")
    @debug "reference"
    include("reference.jl")
    @debug "dataspace"
    include("dataspace.jl")
    @debug "datatype"
    include("datatype.jl")
    @debug "hyperslab"
    include("hyperslab.jl")
    @debug "attributes"
    include("attributes.jl")
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
    @debug "filter implementations"
    include("filter_implementations.jl")
    @debug "chunkstorage"
    include("chunkstorage.jl")
    @debug "fileio"
    include("fileio.jl")
    @debug "nonallocating"
    include("nonallocating.jl")
    @debug "filter test utils"
    include("filters/FilterTestUtils.jl")
    @debug "doc urls"
    include("doc_urls.jl")
    @debug "objects"
    include("objects.jl")
    @debug "dict interface"
    include("dict_interface.jl")
    # `h5d_get_space` seems to be broken for virtual datasets for libhdf5 1.10,
    # see https://github.com/JuliaIO/HDF5.jl/pull/1061#issuecomment-1571009149
    if HDF5.API.h5_get_libversion() >= v"1.12"
        @debug "virtual datasets"
        include("virtual_dataset.jl")
    end
    @debug "api lock"
    include("apilock.jl")

    # basic MPI tests, for actual parallel tests we need to run in MPI mode
    include("mpio.jl")

    # The ROS3 tests read from a public S3 bucket, so they need network access and
    # depend on how the libhdf5 build handles S3 requests. They are opt-in: set
    # HDF5_TEST_ROS3=true to run them (done for selected jobs in .github/workflows/CI.yml).
    if get(ENV, "HDF5_TEST_ROS3", "false") == "true"
        if HDF5.has_ros3()
            include("ros3.jl")
        else
            @warn "HDF5_TEST_ROS3=true, but this libhdf5 was built without ROS3 support"
        end
    end

    # Clean up after all resources
    HDF5.API.h5_close()
end
