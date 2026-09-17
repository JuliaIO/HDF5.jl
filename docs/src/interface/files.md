# Files

```@meta
CurrentModule = HDF5
```

```@docs
h5open
ishdf5
Base.isopen
Base.read
start_swmr_write
```

## `AbstractDict` interface

`File` (like [`Group`](@ref Group)) is a subtype of `AbstractDict{String,Any}` and supports
the standard dict interface (`keys`, `getindex`, iteration as `name => obj` pairs, `delete!`,
etc.) — see [Groups](@ref) for the full description and caveats (`copy`/`empty` throw
informative errors; `==`/`hash` are identity-based).
