module HDF5TreeCompletion

import HDF5: H5DataStore
import REPL

if isdefined(REPL.REPLCompletions, :find_dict_matches)
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
    in that case completion just falls back to single-level behavior, not an error (this
    whole method definition is skipped, via the surrounding `isdefined` guard, if the
    function it extends no longer exists).
    """
    function REPL.REPLCompletions.find_dict_matches(store::H5DataStore, partial_key::AbstractString)
        startswith(partial_key, "\"") || return String[]
        raw = partial_key[2:end] # drop the leading quote; repr() adds it back below
        slash = findlast('/', raw)
        prefix, _trailing = if slash === nothing
            ("", raw)
        else
            # `slash - 1` can land inside a multibyte UTF-8 character (string indices are
            # byte offsets); use `prevind` to always split on a valid character boundary.
            (raw[1:prevind(raw, slash)], raw[(slash + 1):end])
        end

        # `prefix` is Julia source text as typed (e.g. a literal `"` in a name is typed as
        # `\"`), not the real HDF5 name -- unescape it before using it to look anything up.
        # An incomplete escape sequence (e.g. a trailing lone backslash while still typing)
        # isn't a real error, just no matches yet.
        unescaped_prefix = try
            isempty(prefix) ? prefix : Base.unescape_string(prefix)
        catch
            return String[]
        end

        base = store
        if !isempty(unescaped_prefix)
            try
                haskey(base, unescaped_prefix) || return String[]
                base = base[unescaped_prefix]
            catch
                return String[] # mid-typed/invalid prefix: no matches, don't error the prompt
            end
        end

        matches = String[]
        try
            base isa H5DataStore || return matches
            for k in keys(base)
                full = isempty(unescaped_prefix) ? k : unescaped_prefix * "/" * k
                rkey = repr(full)
                startswith(rkey, partial_key) && push!(matches, rkey)
            end
        finally
            # Only intermediate H5DataStore handles are ours to close -- the generic
            # H5DataStore fallback getindex (used by non-HDF5.jl implementors like MAT.jl)
            # can return a plain, non-closeable value (e.g. a scalar or Array).
            base === store || (base isa H5DataStore && close(base))
        end
        return matches
    end
end

end # module
