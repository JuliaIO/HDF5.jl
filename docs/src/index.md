```@meta
CurrentModule = HDF5
```

# HDF5.jl

## Overview

[HDF5](https://www.hdfgroup.org/solutions/hdf5/) stands for Hierarchical Data Format v5 and is closely modeled on file systems. In HDF5, a "group" is analogous to a directory, a "dataset" is like a file. HDF5 also uses "attributes" to associate metadata with a particular group or dataset. HDF5 uses ASCII names for these different objects, and objects can be accessed by Unix-like pathnames, e.g., "/sample1/tempsensor/firsttrial" for a top-level group "sample1", a subgroup "tempsensor", and a dataset "firsttrial".

For simple types (scalars, strings, and arrays), HDF5 provides sufficient metadata to know how each item is to be interpreted. For example, HDF5 encodes that a given block of bytes is to be interpreted as an array of `Int64`, and represents them in a way that is compatible across different computing architectures.

However, to preserve Julia objects, one generally needs additional type information to be supplied,
which is easy to provide using attributes. This is handled for you automatically in the [JLD](https://github.com/JuliaIO/JLD.jl)/[JLD2](https://github.com/JuliaIO/JLD2.jl). These specific formats (conventions) provide "extra" functionality, but they are still both regular
HDF5 files and are therefore compatible with any HDF5 reader or writer.

Language wrappers for HDF5 are often described as either "low level" or "high level." This package contains both flavors: at the low level, it directly wraps HDF5's functions, thus copying their API and making them available from within Julia. At the high level, it provides a set of functions built on the low-level wrap which may make the usage of this library more convenient.

## Installation

```julia
julia>]
pkg> add HDF5
```

Starting from Julia 1.3, the HDF5 binaries are by default downloaded using the `HDF5_jll` package.

### Using custom or system provided HDF5 binaries

To use system-provided HDF5 binaries instead, set the environment variable `JULIA_HDF5_PATH` to the top-level installation directory HDF5, i.e. the library should be located in `${JULIA_HDF5_PATH}/lib`. Then run `import Pkg; Pkg.build("HDF5")`. In particular, this is required if you need parallel HDF5 support, which is not provided by the `HDF5_jll` binaries.

For example, to use HDF5 (`libhdf5-mpich-dev`) with MPI using system libraries on Ubuntu 20.04, you would run:

```sh
$ sudo apt install mpich libhdf5-mpich-dev
$ JULIA_HDF5_PATH=/usr/lib/x86_64-linux-gnu/hdf5/mpich/
$ JULIA_MPI_BINARY=system
```

Then in Julia, run:

```julia
pkg> build
```

## Opening and closing files

"Plain" (i.e., with no extra formatting conventions) HDF5 files are created and/or opened with the `h5open` command:

```julia
fid = h5open(filename, mode)
```

The mode can be any one of the following:

| mode | Meaning                                                             |
| :--- | :------------------------------------------------------------------ |
| "r"  | read-only                                                           |
| "r+" | read-write, preserving any existing contents                        |
| "cw" | read-write, create file if not existing, preserve existing contents |
| "w"  | read-write, destroying any existing contents (if any)               |

For example

```@repl main
using HDF5
fname = tempname(); # temporary file
fid = h5open(fname, "w")
```

This produces an object of type `HDF5File`, a subtype of the abstract type `DataFile`. This file will have no elements (groups, datasets, or attributes) that are not explicitly created by the user.

When you're finished with a file, you should close it:

```julia
close(fid)
```

Closing a file also closes any other open objects (e.g., datasets, groups) in that file. In general, you need to close an HDF5 file to "release" it for use by other applications.

## Writing a group or dataset

Groups can be created as follows:

```@repl main
create_group(fid, "mygroup")
```

We can write the `"mydataset"` by:

```@repl main
fid["mydataset"] = rand()
```

Or

```@repl main
create_dataset(fid, "myvector", rand(10))
```

Writing to a dataset to a group is as simple as:

```@repl main
g = fid["mygroup"]
g["mydataset"] = "Hello World!"
```

The `do` syntax is also supported, which will automatically take care of closing the file handle:

```@repl main
h5open("example2.h5", "w") do fid
    create_group(fid, "mygroup")
end
```

## Opening and closing objects

If you have a file object `fid`, and this has a group or dataset called `"mygroup"` at the top level of a file, you can open it in the following way:

```@repl main
obj = fid["mygroup"]
```

This does not read any data or attributes associated with the object, it's simply a handle for further manipulations. For example:

```@repl main
g = fid["mygroup"]
dset = g["mydataset"]
```

or simply

```@repl main
dset = fid["mygroup/mydataset"]
```

When you're done with an object, you can close it using `close(obj)`. If you forget to do this, it will be closed for you anyway when the file is closed, or if `obj` goes out of scope and gets garbage collected.

## Reading and writing data

Suppose you have a group `g` which contains a dataset with path `"mydataset"`, and that you've also opened this dataset as `dset = g["mydataset"]`.
You can read information in this dataset in any of the following ways:

```julia
A = read(dset)
A = read(g, "mydataset")
Asub = dset[2:3, 1:3]
```

The last syntax reads just a subset of the data array (assuming that `dset` is an array of sufficient size).
libhdf5 has internal mechanisms for slicing arrays, and consequently if you need only a small piece of a large array, it can be faster to read just what you need rather than reading the entire array and discarding most of it.

Datasets can be created with either

```julia
g["mydataset"] = rand(3,5)
write(g, "mydataset", rand(3,5))
```

## Passing parameters

It is often required to pass parameters to specific routines, which are collected
in so-called property lists in HDF5. There are different property lists for
different tasks, e.g. for the access/creation of files, datasets, groups.
In this high level framework multiple parameters can be simply applied by
appending them at the end of function calls as keyword arguments.

```julia
g["A"] = A  # basic
g["A", chunk=(5,5)] = A # add chunks

B = h5read(fn,"mygroup/B", # two parameters
  fapl_mpio=(ccomm,cinfo), # if parameter requires multiple args use tuples
  dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE )
```

This will automatically create the correct property lists, add the properties,
and apply the property list while reading/writing the data.
The naming of the properties generally follows that of HDF5, i.e. the key
`fapl_mpio` returns the HDF5 functions `h5pget/set_fapl_mpio` and their
corresponding property list type `H5P_FILE_ACCESS`.
The complete list if routines and their interfaces is available at the
[H5P: Property List Interface](https://portal.hdfgroup.org/display/HDF5/Property+Lists)
documentation. Note that not all properties are available. When searching
for a property check whether the corresponding `h5pget/set` functions are
available.

## Chunking and compression

You can also optionally "chunk" and/or compress your data. For example,

```julia
A = rand(100,100)
g["A", chunk=(5,5)] = A
```

stores the matrix `A` in 5-by-5 chunks. Chunking improves efficiency if you
write or extract small segments or slices of an array, if these are not stored
contiguously.

```julia
A = rand(100,100)
g1["A", chunk=(5,5), compress=3] = A
g2["A", chunk=(5,5), shuffle=(), deflate=3] = A
g3["A", chunk=(5,5), blosc=3] = A
```

Standard compression in HDF5 (`"compress"`) corresponds to (`"deflate"`) and
uses the [deflate/zlib](http://en.wikipedia.org/wiki/DEFLATE) algorithm. The
deflate algorithm is often more efficient if prefixed by a `"shuffle"` filter.
Blosc is generally much faster than deflate -- however, reading Blosc-compressed
HDF5 files require Blosc to be installed. This is the case for Julia, but often
not for vanilla HDF5 distributions that may be used outside Julia. (In this
case, the structure of the HDF5 file is still accessible, but compressed
datasets cannot be read.) Compression requires chunking, and heuristic chunking
is automatically used if you specify compression but don't specify chunking.

It is also possible to write to subsets of an on-disk HDF5 dataset. This is
useful to incrementally save to very large datasets you don't want to keep in
memory. For example,

```julia
dset = create_dataset(g, "B", datatype(Float64), dataspace(1000,100,10), chunk=(100,100,1))
dset[:,1,1] = rand(1000)
```

creates a Float64 dataset in the file or group `g`, with dimensions 1000x100x10, and then
writes to just the first 1000 element slice.
If you know the typical size of subset reasons you'll be reading/writing, it can be beneficial to set the chunk dimensions appropriately.

More [fine-grained control](#mid-level-routines) is also available.

## Memory mapping

If you will frequently be accessing individual elements or small regions of array datasets, it can be substantially more efficient to bypass HDF5 routines and use direct [memory mapping](https://en.wikipedia.org/wiki/Memory-mapped_file).
This is possible only under particular conditions: when the dataset is an array of standard "bits" types (e.g., `Float64` or `Int32`) and no chunking/compression is being used.
You can use the `ismmappable` function to test whether this is possible; for example,

```julia
dset = g["x"]
if HDF5.ismmappable(dset)
    dset = HDF5.readmmap(dset)
end
val = dset[15]
```

Note that `readmmap` returns an `Array` rather than an HDF5 object.

**Note**: if you use `readmmap` on a dataset and subsequently close the file, the array data are still available---and file continues to be in use---until all of the arrays are garbage-collected.
This is in contrast to standard HDF5 datasets, where closing the file prevents further access to any of the datasets, but the file is also detached and can safely be rewritten immediately.

Under the default
[allocation-time policy](https://portal.hdfgroup.org/display/HDF5/H5P_SET_ALLOC_TIME),
a newly added `ismmappable` dataset can only be memory mapped after it has been written
to.
The following fails:

```julia
vec_dset = create_dataset(g, "v", datatype(Float64), dataspace(10_000,1))
HDF5.ismmappable(vec_dset)    # == true
vec = HDF5.readmmap(vec_dset) # throws ErrorException("Error mmapping array")
```

because although the dataset description has been added, the space within the HDF5 file
has not yet actually been allocated (so the file region cannot be memory mapped by the OS).
The storage can be allocated by making at least one write:

```julia
vec_dset[1,1] = 0.0      # force allocation of /g/v within the file
vec = HDF5.readmmap(vec_dset) # and now the memory mapping can succeed
```

Alternatively, the policy can be set so that the space is allocated immediately upon
creation of the data set with the `alloc_time` keyword:

```julia
mtx_dset = create_dataset(g, "M", datatype(Float64), dataspace(100, 1000),
                    alloc_time = HDF5.H5D_ALLOC_TIME_EARLY)
mtx = HDF5.readmmap(mtx_dset) # succeeds immediately
```

## Supported data types

`HDF5.jl` knows how to store values of the following types: signed and unsigned integers of 8, 16, 32, and 64 bits, `Float32`, `Float64`; `Complex` versions of these numeric types; `Array`s of these numeric types (including complex versions); `ASCIIString` and `UTF8String`; and `Array`s of these two string types.
`Array`s of strings are supported using HDF5's variable-length-strings facility.
By default `Complex` numbers are stored as compound types with `r` and `i` fields following the `h5py` convention.
When reading data, compound types with matching field names will be loaded as the corresponding `Complex` Julia type.
These field names are configurable with the `HDF5.set_complex_field_names(real::AbstractString, imag::AbstractString)` function and complex support can be completely enabled/disabled with `HDF5.enable/disable_complex_support()`.

For `Array`s, note that the array dimensionality is preserved, including 0-length
dimensions:

```julia
fid["zero_vector"] = zeros(0)
fid["zero_matrix"] = zeros(0, 0)
size(fid["zero_vector"]) # == (0,)
size(fid["zero_matrix"]) # == (0, 0)
```

An _exception_ to this rule is Julia's 0-dimensional `Array`, which is stored as an HDF5
scalar because there is a value to be preserved:

```julia
fid["zero_dim_value"] = fill(1.0π)
read(fid["zero_dim_value"]) # == 3.141592653589793, != [3.141592653589793]
```

HDF5 also has the concept of a null array which contains a type but has neither size nor
contents, which is represented by the type `HDF5.EmptyArray`:

```julia
fid["empty_array"] = HDF5.EmptyArray{Float32}()
HDF5.isnull(fid["empty_array"]) # == true
size(fid["empty_array"]) # == ()
eltype(fid["empty_array"]) # == Float32
```

This module also supports HDF5's VLEN, OPAQUE, and REFERENCE types, which can be used to encode more complex types. In general, you need to specify how you want to combine these more advanced facilities to represent more complex data types. For many of the data types in Julia, the JLD module implements support. You can likewise define your own file format if, for example, you need to interact with some external program that has explicit formatting requirements.

## Creating groups and attributes

Create a new group in the following way:

```julia
g = create_group(parent, name)
```

The named group will be created as a child of the parent.

Attributes can be created using

```julia
attributes(parent)[name] = value
```

where `attributes` simply indicates that the object referenced by `name` (a string) is an attribute, not another group or dataset. (Datasets cannot have child datasets, but groups can have either.) `value` must be a simple type: `BitsKind`s, strings, and arrays of either of these. The HDF5 standard recommends against storing large objects as attributes.

## Getting information

```julia
HDF5.name(obj)
```

will return the full HDF5 pathname of object `obj`.

```julia
keys(g)
```

returns a string array containing all objects inside group `g`. These relative pathnames, not absolute pathnames.

You can iterate over the objects in a group, i.e.,

```julia
for obj in g
  data = read(obj)
  println(data)
end
```

This gives you a straightforward way of recursively exploring an entire HDF5 file.

If you need to know whether group `g` has a dataset named `mydata`, you can test that with

```julia
if haskey(g, "mydata")
   ...
end
tf = haskey(g, "mydata")
```

If instead you want to know whether `g` has an attribute named `myattribute`, do it this way:

```julia
tf = haskey(attributes(g), "myattribute")
```

If you have an HDF5 object, and you want to know where it fits in the hierarchy of the file, the following can be useful:

```julia
p = parent(obj)     # p is the parent object (usually a group)
fn = HDF5.filename(obj)  # fn is a string
g = HDF5.root(obj)       # g is the group "/"
```

For array objects (datasets and attributes) the following methods work:

```
dims = size(dset)
nd = ndims(dset)
len = length(dset)
```

Objects can be created with properties, and you can query those
properties in the following way:

```
p = HDF5.get_create_properties(dset)
chunksz = HDF5.get_chunk(p)
```

The simpler syntax `chunksz = HDF5.get_chunk(dset)` is also available.

Finally, sometimes you need to be able to conveniently test whether a file is an HDF5 file:

```julia
tf = HDF5.ishdf5(filename)
```

## Mid-level routines

Sometimes you might want more fine-grained control, which can be achieved using a different set of routines. For example,

```julia
g = open_group(parent, name)
dset = open_dataset(parent, name[, apl])
attr = open_attribute(parent, name)
t = open_datatype(parent, name)
```

These open the named group, dataset, attribute, and committed datatype, respectively. For datasets, `apl` stands for "access parameter list" and provides opportunities for more sophisticated control (see the [HDF5](https://www.hdfgroup.org/solutions/hdf5/) documentation).

New objects can be created in the following ways:

```julia
g = create_group(parent, name[, lcpl, dcpl])
dset = create_dataset(parent, name, data[, lcpl, dcpl, dapl])
attr = create_attribute(parent, name, data)
```

creates groups, datasets, and attributes without writing any data to them. You can then use `write(obj, data)` to store the data. The optional property lists allow even more fine-grained control. This syntax uses `data` to infer the object's "HDF5.datatype" and "HDF5.dataspace"; for the most explicit control, `data` can be replaced with `dtype, dspace`, where `dtype` is an `HDF5.Datatype` and `dspace` is an `HDF5.Dataspace`.

Analogously, to create committed data types, use

```julia
t = commit_datatype(parent, name, dtype[, lcpl, tcpl, tapl])
```

You can create and write data in one step,

```julia
write_dataset(parent, name, data[, lcpl, dcpl, dapl])
write_attribute(parent, name, data)
```

You can use extendible dimensions,

```julia
d = create_dataset(parent, name, dtype, (dims, max_dims), chunk=(chunk_dims))
HDF5.set_dims!(d, new_dims)
```

where dims is a tuple of integers. For example

```julia
b = create_dataset(fid, "b", Int, ((1000,),(-1,)), chunk=(100,)) #-1 is equivalent to typemax(hsize_t)
HDF5.set_dims!(b, (10000,))
b[1:10000] = collect(1:10000)
```

when dimensions are reduced, the truncated data is lost. A maximum dimension of -1 is often referred to as unlimited dimensions, though it is limited by the maximum size of an unsigned integer.

Finally, it's possible to delete objects:

```julia
delete_object(parent, name)   # for groups, datasets, and datatypes
delete_attribute(parent, name)   # for attributes
```

## Low-level routines

Many of the most commonly-used libhdf5 functions have been wrapped. These are not exported, so you need to preface them with `HDF5.function` to use them. The library follows a consistent convention: for example, libhdf5's `H5Adelete` is wrapped with a Julia function called `h5a_delete`. The arguments are exactly as specified in the [HDF5](https://www.hdfgroup.org/solutions/hdf5/) reference manual.

HDF5 is a large library, and the low-level wrap is not complete. However, many of the most-commonly used functions are wrapped, and in general wrapping a new function takes only a single line of code. Users who need additional functionality are encourage to contribute it.

Note that Julia's HDF5 directly uses the "2" interfaces, e.g., `H5Dcreate2`, so you need to have version 1.8 of the HDF5 library or later.


## Parallel HDF5

It is possible to read and write [parallel
HDF5](https://portal.hdfgroup.org/display/HDF5/Parallel+HDF5) files using MPI.
For this, the HDF5 binaries loaded by HDF5.jl must have been compiled with
parallel support, and linked to the specific MPI implementation that will be used for parallel I/O.

Parallel-enabled HDF5 libraries are usually included in computing clusters and
linked to the available MPI implementations.
They are also available via the package manager of a number of Linux
distributions.

Finally, note that the MPI.jl package is lazy-loaded by HDF5.jl
using [Requires](https://github.com/JuliaPackaging/Requires.jl).
In practice, this means that in Julia code, `MPI` must be imported _before_
`HDF5` for parallel functionality to be available.

### Setting-up Parallel HDF5

The following step-by-step guide assumes one already has access to
parallel-enabled HDF5 libraries linked to an existent MPI installation.

#### 1. Using system-provided MPI libraries

Set the environment variable `JULIA_MPI_BINARY=system` and then run
`]build MPI` from Julia.
For more control, one can also set the `JULIA_MPI_PATH` environment variable
to the top-level installation directory of the MPI library.
See the [MPI.jl
docs](https://juliaparallel.github.io/MPI.jl/stable/configuration/#Using-a-system-provided-MPI-1)
for details.

#### 2. Using parallel HDF5 libraries

As detailed in [Using custom or system provided HDF5 binaries](@ref), set the
`JULIA_HDF5_PATH` environment variable to the path where the parallel HDF5
binaries are located.
Then run `]build HDF5` from Julia.

#### 3. Loading MPI-enabled HDF5

In Julia code, MPI.jl must be loaded _before_ HDF5.jl for MPI functionality to
be available:

```julia
using MPI
using HDF5
```

### Reading and writing data in parallel

A parallel HDF5 file may be opened by passing a `MPI.Comm` (and optionally a
`MPI.Info`) object to [`h5open`](@ref).
For instance:

```julia
comm = MPI.COMM_WORLD
info = MPI.Info()
ff = h5open(filename, "w", comm, info)
```

MPI-distributed data is typically written by first creating a dataset
describing the global dimensions of the data.
The following example writes a `10 × Nproc` array distributed over `Nproc` MPI
processes.

```julia
Nproc = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)
M = 10
A = fill(myrank, M)  # local data
dims = (M, Nproc)    # dimensions of global data

# Create dataset
dset = create_dataset(ff, "/data", datatype(eltype(A)), dataspace(dims))

# Write local data
dset[:, myrank + 1] = A
```

Note that all MPI processes must call `create_dataset` with the same arguments.

Sometimes, it may be more efficient to write data in chunks, so that each
process writes to a separate chunk of the file.
This is especially the case when data is uniformly distributed among MPI
processes.
In this example, this can be achieved by passing `chunk=(M, 1)` to `create_dataset`.

For better performance, it is sometimes preferable to perform [collective
I/O](https://portal.hdfgroup.org/display/HDF5/Introduction+to+Parallel+HDF5)
when reading and writing datasets in parallel.
This is achieved by passing `dxpl_mpio=HDF5.H5FD_MPIO_COLLECTIVE` to `create_dataset`.
See also the [HDF5 docs](https://portal.hdfgroup.org/display/HDF5/H5P_SET_DXPL_MPIO).

A few more examples are available in [`test/mpio.jl`](https://github.com/JuliaIO/HDF5.jl/blob/master/test/mpio.jl).

## Language interoperability with row- and column-major order arrays

There are two main methods for storing multidimensional arrays in linear storage [row-major order and column-major order](https://en.wikipedia.org/wiki/Row-_and_column-major_order). Julia, like Fortran and MATLAB, stores multidimensional arrays in column-major order, while other languages, including C and Python (NumPy), use row-major order. Therefore when reading an array in Julia from row-major order language the dimensions may be inverted.

To read a multidimensional array into the original shape from an HDF5 file written by Python (`numpy` and `h5py`) or C/C++/Objective-C, simply reverse the dimensions. For example, one may add the following line after reading the dataset `dset`:
```julia
dset = permutedims(dset, reverse(1:ndims(dset)))
```

Note that some languages or libraries use both methods, so please check the datset's description for details. For example, NumPy arrays are row-major by default, but NumPy can use either row-major or column-major ordered arrays.

## Credits

- Konrad Hinsen initiated Julia's support for HDF5

- Tim Holy and Simon Kornblith (primary authors)

- Tom Short contributed code and ideas to the dictionary-like
  interface

- Blake Johnson made several improvements, such as support for
  iterating over attributes

- Isaiah Norton and Elliot Saba improved installation on Windows and OSX

- Steve Johnson contributed the `do` syntax and Blosc compression

- Mike Nolta and Jameson Nash contributed code or suggestions for
  improving the handling of HDF5's constants

- Thanks also to the users who have reported bugs and tested fixes

# API Reference

Below we include a limited number of API references. Note not all of these are public interfaces, thus proceed with caution.

```@index
Pages = ["index.md"]
```

```@autodocs
Modules = [HDF5]
Filter = not_low_level_api
```
