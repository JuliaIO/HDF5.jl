# The Julia data (\*.jld) module

The JLD module reads and writes "Julia data files" (\*.jld files) using HDF5. To the core HDF5 functionality, this module adds conventions for writing objects which are not directly supported by libhdf5. The key characteristic is that objects of many types can be written, and upon later reading they maintain the proper type. For example, libhdf5 does not know about complex numbers; as a consequence, JLD writes a complex number as a pair of real numbers, and then adds annotation hinting to the reader that these should be interpreted as a complex number of a particular type. The JLD read functions look for those hints and apply them automatically.

Note that \*.jld files are "just" HDF5 files, and consequently can be ready by any language that supports HDF5. However, to get variables read back in the appropriate type for that language, you'll want to use or write a translator. This translator should inspect the annotations of each variable. For further information, [see below](#reference). If you do write a translator for another programming language, if let me know I will be happy to add a link to your package.


## Usage

To get started using Julia data files, load the JLD module:
```
using HDF5, JLD
```
JLD is built on top of HDF5, which is why you need to import HDF5 first.

\*.jld files are created or opened in the following way:
```julia
file = jldopen("mydata.jld", "w")
@write file A
close(file)
```
This creates a dataset named `"A"` containing the contents of the variable `A`.
There are also the convenient `save("mydata.jld", "A", A)` or `@save "mydata.jld" A` [syntaxes](../README.md).

JLD files can be opened with the `mmaparrays` option, which if true returns "qualified" array data sets as arrays using [memory-mapping](hdf5.md#memory-mapping):

```julia
file = jldopen("mydata.jld", "r", mmaparrays=true)
y = read(file, "y")   # y will be a mmapped array, not read immediately in its entirety
```

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

## Types and their definitions

You can save objects that have user-defined type; before loading those objects from a JLD file in a fresh julia session, these types need to be defined. You can ensure this happens automatically with `addrequire`. For example, suppose you have a file `"MyTypes.jl"` somewhere on your default `LOAD_PATH`, defined this way:
```
module MyTypes

export MyType

type MyType
    value::Int
end

end
```
and you have an object `x` of type `MyType`. Then save `x` in the following way:

```
jldopen("somedata.jld", "w") do file
    addrequire(file, "MyTypes")
    write(file, "x", x)
end
```
This will cause `"MyTypes.jl"` to be loaded automatically whenever `"somedata.jld"` is opened.

Types are saved with their full module path, e.g., `MyTypes.MyType`. In general, most types should naturally be in modules that have a consistent module path each time you use them. However, in rare cases you may want to save types from a different module path than you expect to use them. You can use the `rootmodule` option to truncate the module path. For example, if you save your file this way:
```
module A
    module B
        using HDF5, JLD
        include("MyTypes.jl")
        x = MyTypes.MyType(7)      # Full module path is A.B.MyTypes.MyType
        jldopen("test.jld", "w") do file
            addrequire(file, "MyTypes")
            write(file, "x", x, rootmodule="B")  # truncate up to and including B, so path is MyTypes.MyType
        end
    end
end
```
Then you can read this file from the REPL prompt simply with `@load "test.jld"`. The `MyTypes` module will be defined inside `Main`, with no reference to `A.B`.

## Reference: the *.jld HDF5 format <a name="reference"></a>

This is intended as a brief "reference standard" describing the structure of the HDF5 files created by JLD. This may be of value to others trying to read such files from other languages. If you're interested in understanding the format, it is highly recommended to run the script `test/jld.jl`, which generates a sample file called `test.jld` in your temporary directory (e.g., `/tmp`). This file can then be inspected with `h5dump`.

### Major structural elements

- Files created using `jldopen` have a 512-byte header, which begins with a sequence of characters similar to "Julia data file (HDF5), version 0.0.0".  However, note that we also support opening a pre-existing "plain" HDF5 file with `jldopen(filename, "r+")`; new items will be written using *.jld formatting conventions. Such files will lack the 512-byte header.
- Each Julia object is stored as a dataset; groups are intentionally saved for "user structure." Complex objects are therefore stored by making use of HDF5's reference features. To support referencing, there are two reserved group names, `/_refs` and `/_types` (see below).
- Each dataset has at least a `julia_type` attribute, consisting of a string used to encode its type. Other reserved attribute names: `julia_format`, `CompositeKind`, `Module`, `TypeParameters`. (The last three are specific to writing `CompositeKind`s.)

### Storage format for specific types

Let's begin with a couple of examples. For a `Float64` with value `3.7`, stored with name `"x"`, `h5dump` would show the following:
```
   DATASET "x" {
      DATATYPE  H5T_IEEE_F64LE
      DATASPACE  SCALAR
      DATA {
      (0): 3.7
      }
      ATTRIBUTE "julia type" {
         DATATYPE  H5T_STRING {
               STRSIZE 7;
               STRPAD H5T_STR_NULLTERM;
               CSET H5T_CSET_ASCII;
               CTYPE H5T_C_S1;
            }
         DATASPACE  SCALAR
         DATA {
         (0): "Float64"
         }
      }
   }
```
HDF5 provides sufficient metadata to encode the type directly (note the `DATATYPE` field representing the encoding type, and the `DATASPACE SCALAR` which indicates this is a single value). So here, the `julia_type` attribute could be viewed as redundant (and is not needed for "plain" HDF5 files). For consistency, it is always provided.

For an `Array{Any, 1}` stored with name `"AB"`, you might see the following:
```
   DATASET "AB" {
      DATATYPE  H5T_REFERENCE
      DATASPACE  SIMPLE { ( 2 ) / ( 2 ) }
      DATA {
      (0): DATASET 14512 /_refs/AB/1 , DATASET 15112 /_refs/AB/2 
      }
      ATTRIBUTE "julia type" {
         DATATYPE  H5T_STRING {
               STRSIZE 12;
               STRPAD H5T_STR_NULLTERM;
               CSET H5T_CSET_ASCII;
               CTYPE H5T_C_S1;
            }
         DATASPACE  SCALAR
         DATA {
         (0): "Array{Any,1}"
         }
      }
   }
```
Here you can see that the `DATATYPE` is `H5T_REFERENCE`, which means that the objects inside this dataset are references to other objects. This object is an array of two elements, as indicated by `DATASPACE  SIMPLE { ( 2 ) / ( 2 ) }`. The `DATA` line explains where these references point, here to some datasets inside `/_refs`. The `julia_type` attribute assures that upon loading from the file, this dataset will be represented as an `Array{Any, 1}` rather than, say, an `Array{Array{Int32, 2}, 1}`. The key point is that whatever type it had when saved, that type will be used when it is reloaded.

This format illustrates the storage for *general arrays* (anything but arrays of `Integer`s, `FloatingPoint`s, or ASCII/UTF8 strings). This basic format is used as an ingredient for storage of most other Julia types. For example, a tuple differs from this simply in that the `julia_type` attribute is `"Tuple"`; the data are otherwise identical to this format.

Here is a brief description of the current formatting conventions:

- Scalars and arrays of HDF5-supported `BitsKind`s: represented directly. For such objects,  `julia_type` would be "Float64" (for a scalar double), "Array{Int8, 2}" (for a two-dimensional array of 8-bit integers).
- ASCII/UTF8 strings and arrays of such strings: represented directly (using variable-length strings). `julia_type` might be "ASCIIString" or "Array{UTF8String, 1}".
- `Type`s: stored as a H5S_NULL, with the type encoded directly by the `julia_type` attribute. Examples include `Nothing`, `Any`, and `Int32` (as a type, not a value), and the `julia_type` attribute is, e.g., "Type{Nothing}".
- `Bool`s: scalars are written as a single Uint8. Arrays of Bools are written with an additional attribute "julia_format", containing a string which describes the encoding strategy. Currently "EachUint8" is the only supported format (which writes `Array{Bool}` as an `Array{Uint8}`), but in the future it's anticipated that `BitArray`s will be the default. TODO: consider letting `g[name, "julia_format", "EachUint8"] = B`, where `B` is a boolean array, specify the format explicitly.
- `BitArray`s: stored using the generic CompositeKind format, see below.
- `Complex64`/`Complex128`: written as pairs of `Float32`/`Float64`s. An array of complex numbers with dimensionality `(s1, s2, ...)` is written as an array of `FloatingPoint`s with  dimensionality `(2, s1, s2, ...)`.
- `Symbol`: the symbol's name is represented as a string. An array of symbols is represented as array of strings.
- General arrays: written as an array of references (see detailed example above). A group of the same pathname, but rooted at `/_refs` rather than `/`, is created to store the referenced data. See more detail about [/_refs](#_refs) below.
- `Tuple`: stored in the same way as a "general array", but with `julia_type` "Tuple"
- `Associative` (Dict): written as `Any[keys, vals]`, where `keys` and `vals` are arrays, using the "general array" format.
- `CompositeKind`: written as an `Array{Any, 1}` (using the format of "general array"), where each item corresponds to the value of a field. The `julia_type` attribute is `"CompositeKind"`, and then the actual type is stored in two additional attributes, called `"CompositeKind"` and `"TypeParameters"` (e.g., `BitArray{2}` would be stored with `"CompositeKind" = "BitArray"` and `"TypeParameters" = ASCIIString["2"]`). The CompositeKind itself is documented in the group [/_types](#_types).
- `Expr`essions: stored as `Any[ex.head, ex.args]` using the "general array" syntax. Note that expressions quickly lead to deep nesting in `/_refs`.

#### Missing, but will be supported

- `Int128`/`Uint128`: presumably similar to Complex128 (encode as pair of Uint64). The holdup: is the sign bit portable?

#### Not currently supported, and may never be

- Functions (closures)
- Generic `BitsKind`s

The latter are not supported due to concerns about portability (Julia's serializer, largely used for inter-process communication, doesn't seem to worry about this, but perhaps that's because it's safe to assume that all machines in a cluster have the same endian architecture).

Also, when writing arrays, undefined elements will cause an error.

### /_refs

For any "container" object in `/` that needs to reference sub-objects, there's a group of the same pathname under `/_refs` containing the references. Within `/_refs`, datasets may themselves need additional references. These are stored in a sub-group; the letter "g" is appended to prevent name conflicts with the dataset of references.

### /_types

Each new type (CompositeKind) gets described by a dataset in `/_types`, containing a 2-by-n array of strings. Row 1 contains the field names, row 2 the corresponding Julia type declaration. (When viewed in `h5dump`, these look like pairs.) It also has a `"Module"` attribute, consisting of an array of strings that encodes the module hierarchy. The Module attribute is necessary for Julia to reconstruct the object in the case where the given type is not exported to Main. The array of name/type pairs is there (1) to help [readsafely](#data-types-and-code-evolution), and (2) to assist other languages in interpreting \*.jld files.



## Data types and code evolution

`readsafely` loads generic datasets, but loads `CompositeKind`s as a `Dict`. This provides a fallback if the type definition changes in the code after a \*.jld file is written, or if the correct type definition simply doesn't exist (e.g., if it was defined in a package that hasn't been loaded into this Julia session).
