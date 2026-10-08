# HDF5TreeCompletion

Optional companion package for [HDF5.jl](https://github.com/JuliaIO/HDF5.jl) that enables
multi-level, `/`-delimited REPL tab-completion for navigating HDF5 files:

```julia
julia> using HDF5, HDF5TreeCompletion

julia> f = h5open("data.h5")

julia> f["gt1l/land_segments/<TAB>"]
"gt1l/land_segments/latitude"   "gt1l/land_segments/longitude"
```

## Why a separate package?

HDF5.jl's `File`/`Group` types are `AbstractDict{String,Any}`, which gives Julia's built-in
REPL dictionary-key completion for free — but only for a single level (`f["<TAB>"]`).
Getting real multi-level path completion requires overriding an *internal, unexported*
function in the `REPL` stdlib (`REPL.REPLCompletions.find_dict_matches`), since Julia's
built-in dict completion only ever infers the receiver expression as a compile-time
constant (to avoid running side-effecting code just from pressing TAB) — a bare variable
qualifies, but `f["a"]` (a real, effectful HDF5 call) never can.

This is isolated in its own package, rather than folded into HDF5.jl itself, specifically
to keep that private-API risk out of HDF5.jl's own dependency graph and release cycle: if
a future Julia release restructures `REPLCompletions.jl` and this override stops applying,
only this package needs a fix, and users who'd rather not carry that risk simply don't
install it — HDF5.jl's own tab-completion (single level) keeps working either way.

## Usage

Just `using HDF5TreeCompletion` alongside `using HDF5` in an interactive session. It has no
exports and no user-facing API beyond installing the completion behavior as a side effect
of loading.
