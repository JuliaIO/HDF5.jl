# Groups

```@meta
CurrentModule = HDF5
```

```@docs
Group
create_group
open_group
create_external
```

## `AbstractDict` interface

`Group` (like [`File`](@ref File)) is a subtype of `AbstractDict{String,Any}`, via the shared
`HDF5.H5DataStore` supertype. This means a `Group` supports the standard dict interface:
`keys`, `haskey`, `getindex`/`setindex!`, `get`, `get!`, `length`, `isempty`, iteration
(`for (name, obj) in group`, yielding `name => obj` pairs), `pairs`, `values`, and
`delete!`. In particular, this enables native Julia REPL tab-completion of immediate member
names, e.g. `group["<tab>"]`. This only completes a single level at a time (Julia's built-in
dict-key completion can't decompose a `/`-joined path string) -- for full multi-level path
completion (`group["some/nested/<tab>"]`), install the optional companion package
[HDF5TreeCompletion](https://github.com/JuliaIO/HDF5.jl/tree/master/HDF5TreeCompletion).

A few dict operations are intentionally restricted, since their generic `AbstractDict`
fallback would silently do something unrelated to a real HDF5 operation: `copy(group)` and
`empty(group)` throw an informative error (use [`copy_object`](@ref) to copy an HDF5
object). `==`/`hash` remain identity-based, not content-based.
