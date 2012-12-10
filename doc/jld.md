# The Julia data (\*.jld) module

The JLD module reads and writes "Julia data files" (\*.jld files) using HDF5. To the core HDF5 functionality, this module adds conventions for writing objects which are not directly supported by libhdf5. The key characteristic is that objects of many types can be written, and upon later reading they maintain the proper type.

Currently this module is EXPERIMENTAL. For the moment, there is some risk that the format conventions will change without a guarantee of backwards compatibility. Once this module leaves experimental status, backwards-compatibility will be provided. The good news is that your data, being written in HDF5, cannot truly be "lost"; you may just have to do a bit of type conversion.

## Usage

To get started using Julia data files, load the JLD module:
```
load("HDF5.jl")
using JLD
using HDF5
```
JLD is built on top of HDF5; the last, line, `using HDF5`, is necessary if you want to use many of the features of HDF5 directly.

\*.jld files are created or opened in the following way:
```julia
file = jldopen("mydata.jld", "w")
@write fid A
close(file)
```
This creates a dataset named `"A"` containing the contents of the variable `A`.

Provided that you've said `using HDF5`, the features described for the HDF5 module work for \*.jld files, too. For example:
```julia
julia> fidr = jldopen("/tmp/test.jld","r");

julia> dump(fidr, 20)
JldFile len 19
  A: Array{Int64,2} (3,5)
  AB: Array{Any,1} (2,)
  C: Array{Complex128,1} (4,)
  TF: Array{Bool,2} (3,5)
  c: Complex64
  d: Dict{Symbol,ASCIIString}
  ex: Expr
  ms: CompositeKind
  mygroup: HDF5Group{JldFile} len 1
    i: Int64
  str: ASCIIString
  stringsA: Array{ASCIIString,1} (7,)
  stringsU: Array{UTF8String,1} (7,)
  sym: Symbol
  syms: Array{Symbol,1} (2,)
  t: Tuple (2,)
  tf: Bool
  x: Float64
```



## Reference: the *.jld HDF5 format

This is intended as a brief "reference standard" describing the structure of the HDF5 files created by JLD. This may be of value to others trying to read such files from other languages.

### Major structural elements

- Files created using `jldopen` have a 512-byte header, which begins with a sequence of characters similar to "Julia data file (HDF5), version 0.0.0".  However, note that we also support opening a pre-existing "plain" HDF5 file with `jldopen(filename, "r+")`; new items will be written using *.jld formatting conventions. Such files will lack the 512-byte header.
- Each Julia objects is stored as a dataset; groups are deliberately saved for "user structure." Complex objects are therefore stored by making use of HDF5's reference features. There are two reserved group names, `/_refs` and `/_types` (see below). 
- Each dataset has at least a `julia_type` attribute, consisting of a string used to encode its type. Other reserved attribute names: `julia_format`, `CompositeKind`, `Module`.

### Storage format for specific types

- Scalars and arrays of HDF5-supported `BitsKind`s: represented directly
- ASCII/UTF8 strings and arrays of such strings: represented directly (using variable-length strings)
- `Type`s: stored as a H5S_NULL, with the type encoded directly by the `julia_type` attribute. Examples include `Nothing`, `Any`, and `Int32` (as a type, not a value).
- `Bool`s: scalars are written as a single Uint8. Arrays of Bools are written with an additional attribute "julia_format", containing a string which describes the encoding strategy. Currently "EachUint8" is the only supported format (which writes `Array{Bool}` as an `Array{Uint8}`), but in the future it's anticipated that `BitArray`s will be the default. TODO: consider letting `g[name, "julia_format", "EachUint8"] = B`, where `B` is a boolean array, specify the format explicitly.
- `Complex64`/`Complex128`: written as pairs of `Float32`/`Float64`s. An array of complex numbers with dimensionality `(s1, s2, ...)` is written as an array of `FloatingPoint`s with  dimensionality `(2, s1, s2, ...)`.
- `Symbol`: represented as a string. Array of symbols represented as array of strings.
- General arrays: written as an array of references. A group of the same pathname, but rooted at `/_refs` rather than `/`, is created to store the referenced data. See more detail about [/_refs](#_refs) below. The `julia_type` will be, e.g., "Array{Any, 1}".
- `Tuple`: stored in the same way as a "general array", but with `julia_type` "Tuple"
- Associative (Dict): written as `Any[keys, vals]`, where `keys` and `vals` are arrays, using the "general array" format.
- CompositeKind: written as an `Array{Any, 1}` (using the format of "general array"), where each item corresponds to a field. The CompositeKind itself is documented in [/_types](#_types).
- Expressions: stored as `Any[ex.head, ex.args]` using the "general array" syntax. Note that expressions quickly lead to deep nesting in `/_refs`.


#### Missing, but will be supported

- `Int128`/`Uint128`: presumably similar to Complex128 (encode as pair of Uint64). The holdup: is the sign bit portable?

#### Not currently supported, and may never be

- Functions (closures)
- Generic `BitsKind`s

These are not supported due to concerns about portability (Julia's serializer, largely used for inter-process communication, doesn't seem to worry about this, but perhaps that's because it's safe to assume that all machines in a cluster have the same endian architecture).

Also, when writing, undefined array entries will cause an error.

### /_refs

For any "container" object in `/` that needs to reference sub-objects, there's a group of the same pathname under `/_refs` containing the references. Within `/_refs`, datasets may themselves need additional references. These are stored in a sub-group; the letter "g" is appended to prevent name conflicts with the dataset of references.

### /_types

Each new type (CompositeKind) gets described by a dataset in `/_types`, containing a 2-by-n array of strings. Row 1 contains the field names, row 2 the corresponding Julia type declaration. (When viewed in h5dump, these look like pairs.) This dataset also has a "Module" attribute, consisting of an array of strings that encodes the module hierarchy. The Module attribute is necessary for Julia to reconstruct the object in the case where the given type is not exported to Main. The array of name/type pairs is there (1) to help [readsafely](#data-types-and-code-evolution), and (2) to assist other languages in interpreting \*.jld files.



## Data types and code evolution

`readsafely` loads a CompositeKind as a Dict. This provides a fallback if the type definition changes in the code after a \*.jld file is written, or if the correct Module simply hasn't been loaded.
