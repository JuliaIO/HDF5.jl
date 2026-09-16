using HDF5
using HDF5TreeCompletion
using REPL
using Test

fn = tempname() * ".h5"
h5open(fn, "w") do f
    create_group(f, "gt1l")
    create_group(f["gt1l"], "land_segments")
    f["gt1l/land_segments/latitude"] = [1.0, 2.0, 3.0]
    f["gt1l/land_segments/longitude"] = [4.0, 5.0, 6.0]
    create_group(f, "gt2l")
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
        @test completion_texts("f[\"") == ["\"gt1l\"", "\"gt2l\""]
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
end

close(f)
rm(fn; force=true)
@eval Main f = nothing
