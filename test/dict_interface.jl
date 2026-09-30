using Test
using HDF5

@testset "AbstractDict interface" begin
    fn = tempname()

    h5open(fn, "w") do h5f
        h5f["A"] = 1.0
        h5f["B"] = [1, 2, 3]
        g = create_group(h5f, "G")
        g["C"] = "hello"

        # Type identity
        @test h5f isa AbstractDict{String,Any}
        @test g isa AbstractDict{String,Any}
        @test h5f isa HDF5.H5DataStore
        @test g isa HDF5.H5DataStore

        # iterate yields name => object pairs, consistent with keys()
        names_via_iterate = String[]
        for (k, v) in h5f
            @test k isa String
            push!(names_via_iterate, k)
            close(v)
        end
        @test sort(names_via_iterate) == sort(keys(h5f))

        # pairs(d) === d for AbstractDict
        @test pairs(h5f) === h5f

        # values matches manual getindex-by-key
        vals_manual = [(v = h5f[k]; x = read(v); close(v); x) for k in keys(h5f)]
        vals_iter = [(x = read(v); close(v); x) for v in values(h5f)]
        @test vals_manual == vals_iter

        # get / get!
        @test get(h5f, "nonexistent", :default) === :default
        @test read(get(h5f, "A", nothing)) == 1.0
        # missing-key path routes through setindex!, which returns the assigned value itself
        newval = get!(h5f, "NewDataset", [4, 5, 6])
        @test newval == [4, 5, 6]
        @test haskey(h5f, "NewDataset")
        # existing-key path routes through getindex, returning the opened Dataset; doesn't overwrite
        again = get!(h5f, "NewDataset", [9, 9, 9])
        @test read(again) == [4, 5, 6]
        close(again)

        # delete!
        @test delete!(h5f, "NewDataset") === h5f
        @test !haskey(h5f, "NewDataset")
        # no-op (not an error) when the key doesn't exist, matching AbstractDict's contract
        @test delete!(h5f, "still_does_not_exist") === h5f

        # iterate must not close previously-yielded objects out from under the caller: e.g.
        # collecting all values and reading them only afterward must still work, since the
        # collection may be the only thing keeping some of them referenced during the loop.
        collected = collect(values(h5f))
        @test length(collected) == length(h5f)
        for v in collected
            read(v) # would throw if already closed
            close(v)
        end

        # copy/empty are explicitly unsupported
        @test_throws ArgumentError copy(h5f)
        @test_throws ArgumentError copy(g)
        @test_throws ArgumentError empty(h5f)

        # ==/hash: identity-based (===), not content-based. Note re-opening the same path
        # (e.g. h5f["G"] twice) mints a fresh HDF5 identifier each time, so it does NOT
        # compare equal - only the exact same Julia object does.
        @test g == g
        @test hash(g) == hash(g)
        g2 = h5f["G"]
        @test g != g2 # distinct opens of the same path are distinct objects/ids
        close(g2)
        h5open(fn, "r") do h5f2
            @test h5f != h5f2 # distinct File objects, even same file on disk
        end
        # cross-type/cross-kind comparisons must not fall through to AbstractDict's generic
        # content-based `==` (which could wrongly compare `true` for e.g. two empty stores
        # of different concrete types, while `hash` differs for them)
        @test h5f != g
        @test g != Dict{String,Any}()
        @test Dict{String,Any}() != g

        close(g)
    end

    # read(f) / read(f, names...) regression (H5DataStore-level methods)
    h5open(fn, "r") do h5f
        @test read(h5f, "A") == 1.0
        @test read(h5f, "A", "B") == (1.0, [1, 2, 3])
        d = read(h5f)
        @test d isa Dict
        @test d["A"] == 1.0
    end

    # filter! actually mutates the file on disk
    h5open(fn, "r+") do h5f
        filter!(p -> first(p) != "A", h5f)
    end
    h5open(fn, "r") do h5f
        @test !haskey(h5f, "A")
        @test haskey(h5f, "B")
    end

    # show output unchanged (tree-style printing, not falling back to AbstractDict's default)
    h5open(fn, "r") do h5f
        str = sprint(show, MIME("text/plain"), h5f)
        @test occursin("HDF5.File", str)
        @test !occursin("Dict{String", str)
    end
end

# The generic fallbacks in src/types.jl (getindex/get/iterate) are never actually exercised
# by File/Group above, since those define their own more specific methods. Test them
# directly against a minimal mock implementor that (like MAT.jl's Matlabv4File/Matlabv5File/
# MatlabHDF5File) supplies only the documented required contract (read/keys/haskey), all
# declared for concrete `String` only.
@testset "H5DataStore generic AbstractDict fallbacks" begin
    struct MockStore <: HDF5.H5DataStore
        data::Dict{String,Any}
    end
    Base.keys(store::MockStore) = collect(keys(store.data))
    Base.haskey(store::MockStore, name::String) = haskey(store.data, name)
    Base.read(store::MockStore, name::String) = store.data[name]

    store = MockStore(Dict("a" => 1, "b" => 2))

    # getindex/get must normalize an AbstractString key to String before dispatching to
    # read/haskey (declared for concrete String only above): otherwise a SubString misses
    # those methods and falls through to the generic vararg `read(::H5DataStore,
    # ::AbstractString...)` fallback, which calls itself with the same non-String argument
    # -- infinite recursion/StackOverflowError instead of a clean lookup.
    key = SubString("xax", 2, 2) # value "a", but typed as SubString, not String
    @test store[key] == 1
    @test get(store, key, :default) == 1
    @test get(store, SubString("xzx", 2, 2), :default) === :default

    @test sort(collect(pairs(store))) == sort(collect(pairs(store.data)))

    # iterate: a `keys(store)` iterator whose own state protocol legitimately uses `nothing`
    # as a non-terminal state (not just "start over") must still be advanced correctly, not
    # restarted from the beginning forever.
    struct WeirdKeys
        data::Vector{String}
    end
    Base.iterate(wk::WeirdKeys) = isempty(wk.data) ? nothing : (wk.data[1], nothing)
    Base.iterate(wk::WeirdKeys, ::Nothing) =
        length(wk.data) < 2 ? nothing : (wk.data[2], :final)
    Base.iterate(wk::WeirdKeys, ::Symbol) = nothing

    struct WeirdStore <: HDF5.H5DataStore
        data::Dict{String,Int}
    end
    Base.keys(store::WeirdStore) = WeirdKeys(collect(keys(store.data)))
    Base.haskey(store::WeirdStore, name::String) = haskey(store.data, name)
    Base.read(store::WeirdStore, name::String) = store.data[name]

    wstore = WeirdStore(Dict("a" => 1, "b" => 2))
    # Drive `iterate` directly (not e.g. `Iterators.take`/`collect`, which would call the
    # generic `length` fallback -- itself `length(keys(store))`, unrelated to what's being
    # tested here) with an explicit bound, so a regression to the old restart-forever
    # behavior fails the count check below instead of hanging the test suite.
    visited = String[]
    state = iterate(wstore)
    while state !== nothing && length(visited) < 10
        (k, _v), st = state
        push!(visited, k)
        state = iterate(wstore, st)
    end
    @test sort(visited) == ["a", "b"]
end
