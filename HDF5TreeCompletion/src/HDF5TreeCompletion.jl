module HDF5TreeCompletion

import HDF5: H5DataStore
import REPL

"""
    REPL.REPLCompletions.find_dict_matches(store::HDF5.H5DataStore, partial_key::AbstractString)

Multi-level tab-completion for `/`-delimited HDF5 paths, e.g. `f["gt1l/land_segments/<TAB>"]`.

Julia's built-in dictionary-key completion only ever evaluates the receiver expression
(everything before the final `[`) via type inference, not execution, and requires it to
reduce to a compile-time constant — so it can only ever be a bare variable (`f`), never a
compound expression like `f["gt1l"]` (a real, effectful `getindex` call). This means the
partial key text handed to `find_dict_matches` may itself contain embedded `/` separators
that were never decomposed. This method splits on the last `/`, resolves everything before
it via a real (effectful) HDF5 lookup, and matches the remainder against that group's
children, reconstructing the full path for each match.

This overrides an internal, unexported REPL function. It is not public API and could
silently stop being called if a future Julia release restructures `REPLCompletions.jl` —
in that case completion just falls back to single-level behavior, not an error.
"""
function REPL.REPLCompletions.find_dict_matches(store::H5DataStore, partial_key::AbstractString)
    startswith(partial_key, "\"") || return String[]
    raw = partial_key[2:end] # drop the leading quote; repr() adds it back below
    slash = findlast('/', raw)
    prefix, _trailing = slash === nothing ? ("", raw) : (raw[1:(slash - 1)], raw[(slash + 1):end])

    base = store
    if !isempty(prefix)
        try
            haskey(base, prefix) || return String[]
            base = base[prefix]
        catch
            return String[] # mid-typed/invalid prefix: no matches, don't error the prompt
        end
    end

    matches = String[]
    try
        base isa H5DataStore || return matches
        for k in keys(base)
            full = isempty(prefix) ? k : prefix * "/" * k
            rkey = repr(full)
            startswith(rkey, partial_key) && push!(matches, rkey)
        end
    finally
        base === store || close(base) # don't leak the opened intermediate group handle
    end
    return matches
end

end # module
