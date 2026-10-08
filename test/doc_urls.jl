using Test

# Documentation URLs must come from HDF5DocURLs (via `h5doc`, `h5doc_group`,
# `h5doc_anchor`, `h5doc_filter` and `h5doc_external`), so that they can be
# refreshed without editing HDF5.jl. This test fails on raw links to hdfgroup.org or
# github.com/HDFGroup in Julia source, so that new ones are not added by accident.
@testset "no raw HDF Group URLs" begin
    root = dirname(@__DIR__)
    hdfurl = r"https?://[A-Za-z0-9.-]*(hdfgroup\.org|github\.com/HDFGroup)"
    thisfile = abspath(@__FILE__)

    # (path relative to the repository root, text that must appear on the line)
    allowed = [
        # Provenance of C code, not documentation links
        ("src/api/types.jl", "H5Epublic.h"),
        ("ext/CodecLz4Ext/CodecLz4Ext.jl", "H5Zlz4.c"),
        # Filter names that are stored in HDF5 files; changing them changes the files
        ("ext/CodecLz4Ext/CodecLz4Ext.jl", "lz4_name"),
        ("ext/CodecBzip2Ext/CodecBzip2Ext.jl", "bzip2_name"),
    ]

    function files(dir, ext)
        found = String[]
        isdir(dir) || return found
        for (d, _, fs) in walkdir(dir), f in fs
            endswith(f, ext) && push!(found, joinpath(d, f))
        end
        return found
    end

    jlfiles = String[]
    for dir in ("src", "ext", "test", "gen")
        append!(jlfiles, files(joinpath(root, dir), ".jl"))
    end
    filter!(f -> abspath(f) != thisfile, jlfiles)
    # Source files are part of the checkout; skip when running from a bare test directory
    isempty(filter(f -> startswith(relpath(f, root), "src"), jlfiles)) && return nothing

    @testset "Julia sources" begin
        offenders = String[]
        for file in jlfiles
            rel = replace(relpath(file, root), '\\' => '/')
            # the Doxygen tag parser legitimately builds URLs for HDF5DocURLs
            startswith(rel, "gen/") && continue
            for (n, line) in enumerate(eachline(file))
                occursin(hdfurl, line) || continue
                any(a -> a[1] == rel && occursin(a[2], line), allowed) && continue
                push!(offenders, "$rel:$n: $(strip(line))")
            end
        end
        @test isempty(offenders)
        isempty(offenders) ||
            @info "Raw HDF Group URLs; use HDF5DocURLs (see src/docurls.jl):\n" *
                join(offenders, "\n")
    end

    @testset "retired portal.hdfgroup.org links" begin
        # This site no longer serves the pages. Also applies to Markdown, which
        # cannot call HDF5DocURLs and so has to link to a current page by hand.
        offenders = String[]
        mdfiles = [
            files(joinpath(root, "docs"), ".md")
            files(joinpath(root, "ext"), ".md")
        ]
        isfile(joinpath(root, "README.md")) && push!(mdfiles, joinpath(root, "README.md"))
        for file in [jlfiles; mdfiles]
            for (n, line) in enumerate(eachline(file))
                occursin("portal.hdfgroup.org", line) &&
                    push!(offenders, "$(relpath(file, root)):$n")
            end
        end
        filter!(o -> !startswith(o, "test/doc_urls.jl"), offenders)
        @test isempty(offenders)
    end
end
