using HDF5
using HDF5.Filters
using HDF5.API
using Test
using Preferences
using Libdl
using H5Zzstd, H5Zbzip2, H5ZChunkCodecZstd, H5ZChunkCodecBzip2

# Filter implementations used to exercise the registry without depending on any codec.
# They XOR every byte with a constant; the constant tells us which implementation ran.
const XOR_ID = API.H5Z_filter_t(301)
const XOR_AUTO_ID = API.H5Z_filter_t(302)

function xor_filter_with(
    key::UInt8,
    flags::Cuint,
    cd_nelmts::Csize_t,
    cd_values::Ptr{Cuint},
    nbytes::Csize_t,
    buf_size::Ptr{Csize_t},
    buf::Ptr{Ptr{Cvoid}}
)::Csize_t
    p = Ptr{UInt8}(unsafe_load(buf))
    for i in 1:nbytes
        unsafe_store!(p, xor(unsafe_load(p, i), key), i)
    end
    return nbytes
end
xor_a5(flags, cd_nelmts, cd_values, nbytes, buf_size, buf) =
    xor_filter_with(0xa5, flags, cd_nelmts, cd_values, nbytes, buf_size, buf)
xor_77(flags, cd_nelmts, cd_values, nbytes, buf_size, buf) =
    xor_filter_with(0x77, flags, cd_nelmts, cd_values, nbytes, buf_size, buf)

struct XorFilterA <: Filters.Filter end
struct XorFilterB <: Filters.Filter end
struct XorAutoFilter <: Filters.Filter end
for (T, id, fn) in (
    (:XorFilterA, XOR_ID, :xor_a5),
    (:XorFilterB, XOR_ID, :xor_77),
    (:XorAutoFilter, XOR_AUTO_ID, :xor_77)
)
    @eval begin
        Filters.filterid(::Type{$T}) = $id
        Filters.filtername(::Type{$T}) = string($T)
        Filters.filter_func(::Type{$T}) = $fn
        Filters.filter_cfunc(::Type{$T}) = @cfunction(
            $fn,
            Csize_t,
            (Cuint, Csize_t, Ptr{Cuint}, Csize_t, Ptr{Csize_t}, Ptr{Ptr{Cvoid}})
        )
    end
end

# Write one chunk with filter `id` and return the raw, filtered bytes of the chunk.
function raw_chunk(id, data)
    fn = tempname()
    try
        h5open(fn, "w") do f
            ds = create_dataset(
                f,
                "d",
                datatype(data),
                dataspace(data);
                chunk=size(data),
                filters=Filters.ExternalFilter(id)
            )
            write(ds, data)
        end
        h5open(fn) do f
            @test read(f["d"]) == data
        end
        h5open(fn) do f
            return last(HDF5.do_read_chunk(f["d"], 1))
        end
    finally
        rm(fn; force=true)
    end
end

function reset_filter_settings()
    delete_preferences!(
        HDF5, "filter_priority", "filter_disabled", "filter_auto_register"; force=true
    )
    Filters.load_preferences!()
    for id in (32015, 307, XOR_ID, XOR_AUTO_ID)
        Filters.reset_priority!(id)
    end
end

@testset "filter implementations" begin
    reset_filter_settings()
    data = rand(UInt8, 64)

    @testset "name resolution" begin
        @test Filters.filter_id(:zstd) == 32015
        @test Filters.filter_id("Bzip2") == 307
        @test Filters.filter_id("32001") == 32001
        @test Filters.filter_id(H5Zzstd.ZstdFilter) == 32015
        @test_throws ArgumentError Filters.filter_id(:nonexistent)
    end

    @testset "implementations coexist" begin
        zstd = Filters.implementations(:zstd)
        @test [:H5Zzstd, :H5ZChunkCodecZstd] ⊆ [i.provider for i in zstd]
        bzip2 = Filters.implementations(:bzip2)
        @test [:H5Zbzip2, :H5ZChunkCodecBzip2] ⊆ [i.provider for i in bzip2]
        # The package loaded first is active by default
        @test Filters.active_implementation(:zstd) in (:H5Zzstd, :H5ZChunkCodecZstd)
        @test HDF5.API.h5z_filter_avail(32015)
        @test HDF5.API.h5z_filter_avail(307)
    end

    @testset "priority selects implementation and data is interchangeable" begin
        fdata = rand(Float32, 200, 100)
        zstdfilters = (H5Zzstd.ZstdFilter(7), H5ZChunkCodecZstd.ChunkCodecZstdFilter(7))
        bzip2filters = (
            H5Zbzip2.Bzip2Filter(4), H5ZChunkCodecBzip2.ChunkCodecBzip2Filter(4)
        )
        for (name, filters) in ((:zstd, zstdfilters), (:bzip2, bzip2filters)),
            writer in Symbol.(parentmodule.(typeof.(filters))),
            reader in Symbol.(parentmodule.(typeof.(filters)))

            fn = tempname()
            try
                Filters.set_priority!(name, writer)
                @test Filters.active_implementation(name) == writer
                @test Filters.FILTERS[Filters.filter_id(name)] == only(
                    i.type for i in Filters.implementations(name) if i.provider == writer
                )
                h5open(fn, "w") do f
                    write_dataset(f, "d", fdata; chunk=(50, 50), filters=filters[1])
                    write_dataset(f, "e", fdata; chunk=(50, 50), filters=filters[2])
                end
                Filters.set_priority!(name, reader)
                @test Filters.active_implementation(name) == reader
                h5open(fn) do f
                    @test read(f["d"]) == fdata
                    @test read(f["e"]) == fdata
                    # the type of the filter read back belongs to the active implementation
                    @test only(
                        Filters.FilterPipeline(HDF5.get_create_properties(f["d"]))
                    ) isa Filters.FILTERS[Filters.filter_id(name)]
                end
            finally
                rm(fn; force=true)
            end
        end
        Filters.reset_priority!(:zstd)
        Filters.reset_priority!(:bzip2)
        # Compression levels survive in both implementations, including negative zstd levels
        fn = tempname()
        try
            Filters.set_priority!(:zstd, :H5ZChunkCodecZstd)
            h5open(fn, "w") do f
                write_dataset(
                    f,
                    "d",
                    fdata;
                    chunk=(50, 50),
                    filters=H5ZChunkCodecZstd.ChunkCodecZstdFilter(-3)
                )
            end
            h5open(fn) do f
                filter = only(Filters.FilterPipeline(HDF5.get_create_properties(f["d"])))
                @test filter.clevel % Cint == -3
                @test repr(filter) == "ChunkCodecZstdFilter(-3)"
                @test read(f["d"]) == fdata
            end
        finally
            rm(fn; force=true)
            Filters.reset_priority!(:zstd)
        end
    end

    @testset "unlisted and unknown providers" begin
        Filters.set_priority!(:zstd, :NoSuchProvider, :H5ZChunkCodecZstd)
        @test Filters.active_implementation(:zstd) == :H5ZChunkCodecZstd
        Filters.set_priority!(:zstd, :NoSuchProvider)
        # unlisted providers are still used when nothing listed is available
        @test Filters.active_implementation(:zstd) in (:H5Zzstd, :H5ZChunkCodecZstd)
        @test_throws ErrorException Filters.activate!(:zstd, :NoSuchProvider)
        Filters.reset_priority!(:zstd)
    end

    @testset "activate!" begin
        Filters.activate!(H5ZChunkCodecZstd.ChunkCodecZstdFilter)
        @test Filters.active_implementation(:zstd) == :H5ZChunkCodecZstd
        Filters.activate!(:zstd, :H5Zzstd)
        @test Filters.active_implementation(:zstd) == :H5Zzstd
        Filters.reset_priority!(:zstd)
    end

    @testset "multiple Julia implementations of one id" begin
        register_filter = Filters.register_filter
        register_filter(XorFilterA; provider=:XorA)
        register_filter(XorFilterB; provider=:XorB)
        @test Filters.active_implementation(XOR_ID) == :XorA # first loaded
        @test raw_chunk(XOR_ID, data) == xor.(data, 0xa5)
        Filters.set_priority!(XOR_ID, :XorB, :XorA)
        @test Filters.active_implementation(XOR_ID) == :XorB
        @test Filters.FILTERS[XOR_ID] === XorFilterB
        @test raw_chunk(XOR_ID, data) == xor.(data, 0x77)
        Filters.set_priority!(XOR_ID, :XorA, :XorB)
        @test raw_chunk(XOR_ID, data) == xor.(data, 0xa5)
        @test [i.provider for i in Filters.implementations(XOR_ID)] == [:XorA, :XorB]
        # registering again does not duplicate an implementation
        register_filter(XorFilterA; provider=:XorA)
        @test length(Filters.implementations(XOR_ID)) == 2
    end

    @testset "preferences" begin
        # priorities set at runtime take precedence over preferences
        Filters.reset_priority!(XOR_ID)
        Filters.reset_priority!(:bzip2)
        set_preferences!(
            HDF5,
            "filter_priority" =>
                Dict("301" => ["XorB", "XorA"], "bzip2" => ["H5ZChunkCodecBzip2"]);
            force=true
        )
        Filters.load_preferences!()
        @test Filters.priority(XOR_ID) == [:XorB, :XorA]
        @test Filters.active_implementation(XOR_ID) == :XorB
        @test Filters.active_implementation(:bzip2) == :H5ZChunkCodecBzip2
        # runtime settings override preferences
        Filters.set_priority!(XOR_ID, :XorA)
        @test Filters.active_implementation(XOR_ID) == :XorA
        Filters.reset_priority!(XOR_ID)
        @test Filters.active_implementation(XOR_ID) == :XorB

        # "default" applies to filters without their own entry
        set_preferences!(HDF5, "filter_priority" => Dict("default" => ["XorB"]); force=true)
        Filters.load_preferences!()
        @test Filters.priority(XOR_ID) == [:XorB]
        @test Filters.priority(:zstd) == [:XorB]

        # disabled providers are never selected automatically
        set_preferences!(
            HDF5,
            "filter_priority" => Dict("301" => ["XorB", "XorA"]),
            "filter_disabled" => ["XorB"];
            force=true
        )
        Filters.load_preferences!()
        @test Filters.active_implementation(XOR_ID) == :XorA

        # bad values are ignored with a warning
        set_preferences!(
            HDF5, "filter_priority" => Dict("notafilter" => ["XorB"]); force=true
        )
        @test_logs (:warn, r"Ignoring HDF5 preference filter_priority entry") Filters.load_preferences!()
        set_preferences!(HDF5, "filter_auto_register" => "yes"; force=true)
        @test_logs (:warn, r"filter_auto_register") match_mode = :any Filters.load_preferences!()
        reset_filter_settings()
    end

    @testset "auto registration can be disabled" begin
        set_preferences!(HDF5, "filter_auto_register" => false; force=true)
        Filters.load_preferences!()
        try
            Filters.register_filter(XorAutoFilter; provider=:XorAuto)
            # known to HDF5.jl but not registered with libhdf5
            @test [i.provider for i in Filters.implementations(XOR_AUTO_ID)] == [:XorAuto]
            @test Filters.active_implementation(XOR_AUTO_ID) === nothing
            @test !HDF5.API.h5z_filter_avail(XOR_AUTO_ID)
            Filters.activate_all!()
            @test Filters.active_implementation(XOR_AUTO_ID) == :XorAuto
            @test HDF5.API.h5z_filter_avail(XOR_AUTO_ID)
            @test raw_chunk(XOR_AUTO_ID, data) == xor.(data, 0x77)
            # existing registrations are left alone
            @test Filters.active_implementation(32015) in (:H5Zzstd, :H5ZChunkCodecZstd)
        finally
            reset_filter_settings()
        end
    end

    @testset "native plugin" begin
        plugin_src = joinpath(@__DIR__, "filters", "native_xor_plugin.c")
        cc = Sys.which("cc")
        if cc === nothing || Sys.iswindows()
            @info "Skipping native plugin test: no C compiler"
        else
            mktempdir() do dir
                lib = joinpath(dir, "libnativexor.so")
                flags = Sys.isapple() ? ["-undefined", "dynamic_lookup"] : String[]
                ok = success(`$cc -shared -fPIC -O1 $flags -o $lib $plugin_src`)
                if !ok
                    @info "Skipping native plugin test: could not compile plugin"
                else
                    try
                        HDF5.API.h5pl_append(dir)
                    catch err
                        @warn "Could not append plugin path" err
                    end
                    # The native plugin XORs with 0x5a
                    Filters.set_priority!(XOR_ID, :XorA, :XorB)
                    @test raw_chunk(XOR_ID, data) == xor.(data, 0xa5)
                    Filters.set_priority!(XOR_ID, :native, :XorA)
                    @test Filters.active_implementation(XOR_ID) == :native
                    @test raw_chunk(XOR_ID, data) == xor.(data, 0x5a)
                    # back to Julia and again to native
                    Filters.set_priority!(XOR_ID, :XorB, :native)
                    @test Filters.active_implementation(XOR_ID) == :XorB
                    @test raw_chunk(XOR_ID, data) == xor.(data, 0x77)
                    Filters.activate!(XOR_ID, :native)
                    @test Filters.active_implementation(XOR_ID) == :native
                    @test raw_chunk(XOR_ID, data) == xor.(data, 0x5a)
                    reset_filter_settings()
                end
            end
        end
        # a native plugin that does not exist is skipped
        Filters.set_priority!(32015, :native, :H5Zzstd)
        @test Filters.active_implementation(32015) == :H5Zzstd
        @test_throws ErrorException Filters.activate!(32015, :native)
        Filters.reset_priority!(32015)
    end

    reset_filter_settings()
end
