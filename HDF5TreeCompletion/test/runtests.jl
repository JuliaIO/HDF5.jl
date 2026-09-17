using HDF5
using HDF5TreeCompletion
using REPL
using Test

# A minimal H5DataStore that only implements the generic fallback contract (keys/haskey/read),
# like MAT.jl's Matlabv5File -- used to test that an intermediate non-HDF5.jl, non-closeable
# value doesn't crash completion.
struct FakeStore <: HDF5.H5DataStore
    data::Dict{String,Any}
end
Base.keys(s::FakeStore) = Base.keys(s.data)
Base.haskey(s::FakeStore, k::AbstractString) = haskey(s.data, k)
Base.read(s::FakeStore, k::AbstractString) = s.data[k]

fn = tempname() * ".h5"
h5open(fn, "w") do f
    create_group(f, "gt1l")
    create_group(f["gt1l"], "land_segments")
    f["gt1l/land_segments/latitude"] = [1.0, 2.0, 3.0]
    f["gt1l/land_segments/longitude"] = [4.0, 5.0, 6.0]
    create_group(f, "gt2l")

    create_group(f, "unicode")
    create_group(f["unicode"], "α")
    f["unicode/α/child"] = 1

    create_group(f, "quoted")
    create_group(f["quoted"], "a\"b")
    f["quoted/a\"b/child"] = 1
end

# Opened at true top level (not inside a closure/do-block) so that assigning the
# `f` global below takes effect at the next top-level statement's world age, exactly
# as it would between successive lines typed at a real REPL prompt.
f = h5open(fn, "r")
@eval Main f = $f

complete(str) = REPL.REPLCompletions.completions(str, lastindex(str), Main)[1]
completion_texts(str) = sort!([REPL.REPLCompletions.completion_text(c) for c in complete(str)])

@testset "HDF5TreeCompletion" begin
    @testset "top-level" begin
        @test completion_texts("f[\"") ==
            ["\"gt1l\"", "\"gt2l\"", "\"quoted\"", "\"unicode\""]
    end

    # Note: when there's exactly one match and the bracket isn't already closed, the
    # REPL auto-appends the closing `]` too (the same convenience behavior plain Dict
    # completion has) -- expected values below account for that.

    @testset "one level deep" begin
        @test completion_texts("f[\"gt1l/") == ["\"gt1l/land_segments\"]"]
    end

    @testset "two levels deep" begin
        @test completion_texts("f[\"gt1l/land_segments/") ==
            ["\"gt1l/land_segments/latitude\"", "\"gt1l/land_segments/longitude\""]
    end

    @testset "partial trailing segment" begin
        @test completion_texts("f[\"gt1l/land_segments/lat") ==
            ["\"gt1l/land_segments/latitude\"]"]
    end

    @testset "invalid intermediate prefix" begin
        @test isempty(complete("f[\"does_not_exist/"))
    end

    @testset "no trailing slash still matches top level" begin
        @test completion_texts("f[\"gt1") == ["\"gt1l\"]"]
    end

    @testset "multibyte character immediately before the slash" begin
        # `slash - 1` would land mid-codepoint here (string indices are byte offsets);
        # must use `prevind` to split on a valid character boundary.
        @test completion_texts("f[\"unicode/α/") == ["\"unicode/α/child\"]"]
    end

    @testset "escaped quote in a path segment" begin
        # The buffer text for a group literally named `a"b` is `a\"b` (escaped) -- must be
        # unescaped before being used as the real HDF5 lookup key, not compared/looked-up
        # in its literal escaped spelling.
        @test completion_texts("f[\"quoted/a\\\"b/") == ["\"quoted/a\\\"b/child\"]"]
    end

    @testset "non-closeable intermediate value from the generic H5DataStore fallback" begin
        # Mimics a non-HDF5.jl H5DataStore (e.g. MAT.jl) whose generic `getindex` fallback
        # (`read(store, name)`) can return a plain, non-closeable value -- completing past
        # such a value must not attempt to `close` it.
        fake = FakeStore(Dict("scalarkey" => 42))
        @test isempty(REPL.REPLCompletions.find_dict_matches(fake, "\"scalarkey/"))
    end
end

close(f)
rm(fn; force=true)
@eval Main f = nothing
