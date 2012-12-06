# The Julia data (*.jld) module

## Basic usage

Talk about Type preservation

Demonstrate opening/closing files

All the other HDF5 stuff works

## The *.jld HDF5 format

- 512-byte header. This is optional, so that a pre-existing "plain" HDF5 file can have new items written to it in *.jld format.
- Each object is a dataset; groups are saved for "user structure" (exceptions: /_refs, /_types)
- Each object has at least a "julia_type" attribute, consisting of a string used to encode its type. Other reserved attribute names: "julia_format", "CompositeKind", "Module"

### Specific types

Currently there is no support for "generic" `BitsKind`s because of fears that it wouldn't be portable (the serializer doesn't seem to worry about this, but I suspect that's because it's safe to assume that all machines in a cluster have the same endian architecture). But maybe I'm wrong to be concerned about that. At any rate, the consequence is that each `BitKind` currently needs custom support.

- Scalars and arrays of HDF5-supported `BitsKind`s: represented directly
- ASCII/UTF8 strings and arrays of such strings: represented directly (using variable-length strings)
- `Nothing`: written as a H5S_NULL dataset with julia_type "Nothing"
- `Bool`s: scalars are written as a single Uint8. Arrays of Bools are written with an additional attribute "julia_format", containing a string which describes the encoding strategy. Currently "EachUint8" is the only supported format (which writes `Array{Bool}` as an `Array{Uint8}`), but in the future it's anticipated that `BitArray`s will be the default. TODO: consider letting `g[name, "julia_format", "EachUint8"] = A` specify the format explicitly.
- `Complex64`/`Complex128`: written as pairs of `Float32`/`Float64`s. An array of complex numbers with dimensionality `(s1, s2, ...)` is written as an array of `FloatingPoint`s with  dimensionality `(2, s1, s2, ...)`.
- `Symbol`: represented as a string. Array of symbols represented as array of strings.
- General arrays: written as an array of references. A group of the same pathname, but rooted at /_refs rather than /, is created to store the referenced data. See more detail about [/_refs](#refs) below.
- Associative (Dict): written as `Any[keys, vals]`, where `keys` and `vals` are arrays, using the "general array" format described previously.
- CompositeKind: written as an `Array{Any, 1}`, where each item corresponds to a field of the type. The type is documented in [/_types](#types).

#### Missing, but will be supported

- `Tuple` (just convert to array)
- `Int128`/`Uint128`: presumably similar to Complex128 (encode as pair of Uint64). The holdup: is the sign bit portable?

#### Not currently supported, and may never be

- Expressions
- Functions (closures)

The emphasis is on data, not code. This might change in response to feedback.

Also, when writing, undefined array entries will cause an error. I don't currently anticipate changing this behavior.

### /_refs
<a id="refs"></a>

For any "container" object in / that needs to reference sub-objects, there's a group of the same pathname under _refs containing the references. The referenced items are either datasets or groups (depending on whether they also need references).

NOTE: TODO (currently `/_refs` has a flat organization)

### /_types
<a id="types"></a>

Each new type (CompositeKind) gets described by a dataset in `/_types`, containing a 2-by-n array of strings. Row 1 contains the field names, row 2 the corresponding Julia type declaration. (When viewed in h5dump, these look like pairs.) This dataset also has a "Module" attribute, consisting of an array of strings that encodes the module hierarchy. The Module attribute is necessary for Julia to reconstruct the object in the case where the given type is not exported to Main. The array of name/type pairs is there (1) to help [readsafely](#readsafely), and (2) to assist other languages in interpreting \*.jld files.



## Data types and code evolution
<a id="readsafely"></a>

`readsafely` loads a CompositeKind as a Dict. This provides a fallback if the type definition changes in the code after a \*.jld file is written, or if the correct Module simply hasn't been loaded.
