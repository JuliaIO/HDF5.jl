module HDF5TreeCompletion

import HDF5: File, Group, H5DataStore
import REPL

const HandleStore = Union{File,Group}

if isdefined(REPL.REPLCompletions, :find_dict_matches)
    """
        REPL.REPLCompletions.find_dict_matches(store::Union{HDF5.File,HDF5.Group}, partial_key::AbstractString)

    Multi-level tab-completion for `/`-delimited HDF5 paths, e.g. `f["gt1l/land_segments/<TAB>"]`.

    Julia's built-in dictionary-key completion only ever evaluates the receiver expression
    (everything before the final `[`) via type inference, not execution, and requires it to
    reduce to a compile-time constant — so it can only ever be a bare variable (`f`), never a
    compound expression like `f["gt1l"]` (a real, effectful `getindex` call). This means the
    partial key text handed to `find_dict_matches` may itself contain embedded `/` separators
    that were never decomposed. This method splits on the last `/`, resolves everything before
    it via a real (effectful) HDF5 lookup, and matches the remainder against that group's
    children, reconstructing the full path for each match.

    This specializes on `HDF5.File`/`HDF5.Group` specifically, not the broader `H5DataStore`
    abstract type: `H5DataStore`'s generic fallback `getindex` delegates to `read`, so a
    third-party implementor (e.g. MAT.jl's `Matlabv5File`) can fully materialize a large value
    merely to discover, on the next keystroke, that it isn't traversable. `File`/`Group`
    indexing always returns a handle (`Dataset`/`Group`/etc.), never materialized data, so this
    method's own recursive traversal and cleanup stay cheap and safe.

    This overrides an internal, unexported REPL function. It is not public API and could
    silently stop being called if a future Julia release restructures `REPLCompletions.jl` —
    in that case completion just falls back to single-level behavior, not an error (this
    whole method definition is skipped, via the surrounding `isdefined` guard, if the
    function it extends no longer exists).
    """
    function REPL.REPLCompletions.find_dict_matches(store::HandleStore, partial_key::AbstractString)
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
                # `getindex(::Union{File,Group}, path)` already starts with a `haskey`
                # check internally, so an explicit precheck here would just traverse the
                # hierarchy twice on every nested completion; let the `catch` below turn a
                # missing/invalid (possibly still-being-typed) prefix into no matches.
                base = base[unescaped_prefix]
            catch
                return String[]
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
            # Only close a handle that's actually closeable and not `store` itself: even
            # restricted to File/Group, `H5DataStore`'s documented fallback contract (which
            # this `finally` must still respect for whatever `base` ends up being) doesn't
            # require a `close` method.
            base === store || applicable(close, base) && close(base)
        end
        return matches
    end
end

end # module
