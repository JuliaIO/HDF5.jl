
Julia HDF5 Guide
================

Overview
--------

[HDF5][HDF5] stands for Hierarchical Data Format v5 and is closely modeled on file systems. In HDF5, a "group" is analogous to a directory, a "dataset" is like a file. HDF5 also uses "attributes" to associate metadata with a particular group or dataset. HDF5 uses ASCII names for these different objects, and objects can be accessed by UNIX-like pathnames, e.g., "/sample1/tempsensor/firsttrial" for a top-level group "sample1", a subgroup "tempsensor", and a dataset "firsttrial".

For simple types (scalars, strings, and arrays), HDF5 provides sufficient metadata to know how each item is to be interpreted. For example, HDF5 encodes that a given block of bytes is to be interpreted as an array of `Int64`, and represents them in a way that is compatible across different computing architectures.

However, to preserve Julia objects, one generally needs additional type information to be supplied, which is easy to provide using attributes. This is handled for you automatically in the JLD and MatIO modules for \*.jld and \*.mat files. These specific formats (conventions) provide "extra" functionality, but they are still both regular HDF5 files and are therefore compatible with any HDF5 reader or writer.

Language wrappers for HDF5 are often described as either "low level" or "high level." This package contains both flavors: at the low level, it directly wraps HDF5's functions, thus copying their API and making them available from within Julia. At the high level, it provides a set of functions built on the low-level wrap which may make the usage of this library more convenient.


Opening and closing files
-------------------------

"Plain" (i.e., with no extra formatting conventions) HDF5 files are created and/or opened with the `h5open` command:

```julia
fid = h5open(filename, mode)
```

The mode can be any one of the following:

<table>
  <tr>
    <td>mode</td> <td>Meaning</td>
  </tr>
  <tr>
    <td>"r"</td> <td>read-only</td>
  </tr>
  <tr>
    <td>"r+"</td> <td>read-write, preserving any existing contents</td>
  </tr>
  <tr>
    <td>"cw"</td> <td>read-write, create file if not existing, preserve existing contents</td>
  </tr>
  <tr>
    <td>"w"</td> <td>read-write, destroying any existing contents (if any)</td>
  </tr>
</table>

This produces an object of type `HDF5File`, a subtype of the abstract type `DataFile`. This file will have no elements (groups, datasets, or attributes) that are not explicitly created by the user.

When you're finished with a file, you should close it:

```julia
close(fid)
```

Closing a file also closes any other open objects (e.g., datasets, groups) in that file. In general, you need to close an HDF5 file to "release" it for use by other applications.

Opening and closing objects
---------------------------

If you have a file object `fid`, and this has a group or dataset called `"myobject"` at the top level of a file, you can open it in the following way:

```julia
obj = fid["myobject"]
```

This does not read any data or attributes associated with the object, it's simply a handle for further manipulations. For example:

```julia
g = fid["mygroup"]
dset = g["mydataset"]
```

or simply

```julia
dset = fid["mygroup/mydataset"]
```

When you're done with an object, you can close it using `close(obj)`. If you forget to do this, it will be closed for you anyway when the file is closed, or if `obj` goes out of scope and gets garbage collected.

Reading and writing data
------------------------

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

Passing parameters
------------------------

It is often required to pass parameters to specific routines, which are collected 
in so-called property lists in HDF5. There are different property lists for
different tasks, e.g. for the access/creation of files, datasets, groups.
In this high level framework multiple parameters can be simply applied by
appending them at the end of function calls as a list of key/value pairs.

```julia
g["A"] = A  # basic
g["A", "chunk", (5,5)] = A # add chunks

B=h5read(fn,"mygroup/B", # two parameters
  "fapl_mpio", (ccomm,cinfo), # if parameter requires multiple args use tuples
  "dxpl_mpio", HDF5.H5FD_MPIO_COLLECTIVE ) 
```

This will automatically create the correct property lists, add the properties,
and apply the property list while reading/writing the data.
The naming of the properties generally follows that of HDF5, i.e. the key
`fapl_mpio` returns the HDF5 functions `h5pget/set_fapl_mpio` and their
corresponding property list type `H5P_FILE_ACCESS`.
The complete list if routines and their interfaces is available at the
[H5P: Property List Interface](https://support.hdfgroup.org/HDF5/doc/RM/RM_H5P.html)
documentation. Note that not all properties are available. When searching
for a property check whether the corresponding `h5pget/set` functions are
available.


Chunking and compression
------------------------

You can also optionally "chunk" and/or compress your data. For example,

```julia
A = rand(100,100)
g["A", "chunk", (5,5)] = A
```

stores the matrix `A` in 5-by-5 chunks. Chunking improves efficiency if you
write or extract small segments or slices of an array, if these are not stored
contiguously.

```julia
A = rand(100,100)
g1["A", "chunk", (5,5), "compress", 3] = A
g2["A", "chunk", (5,5), "shuffle", (), "deflate", 3] = A
g3["A", "chunk", (5,5), "blosc", 3] = A
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
dset = d_create(g, "B", datatype(Float64), dataspace(1000,100,10), "chunk", (100,100,1))
dset[:,1,1] = rand(1000)
```

creates a Float64 dataset in the file or group `g`, with dimensions 1000x100x10, and then
writes to just the first 1000 element slice.
If you know the typical size of subset reasons you'll be reading/writing, it can be beneficial to set the chunk dimensions appropriately.

More [fine-grained control](#mid-level-routines) is also available.

Memory mapping
--------------

If you will frequently be accessing individual elements or small regions of array datasets, it can be substantially more efficient to bypass HDF5 routines and use direct [memory mapping](https://en.wikipedia.org/wiki/Memory-mapped_file).
This is possible only under particular conditions: when the dataset is an array of standard "bits" types (e.g., `Float64` or `Int32`) and no chunking/compression is being used.
You can use the `ismmappable` function to test whether this is possible; for example,

```julia
dset = g["x"]
if ismmappable(dset)
    dset = readmmap(dset)
end
val = dset[15]
```

Note that `readmmap` returns an `Array` rather than an HDF5 object.

**Note**: if you use `readmmap` on a dataset and subsequently close the file, the array data are still available---and file continues to be in use---until all of the arrays are garbage-collected.
This is in contrast to standard HDF5 datasets, where closing the file prevents further access to any of the datasets, but the file is also detached and can safely be rewritten immediately.

Supported data types
--------------------

PlainHDF5File knows how to store values of the following types: signed and unsigned integers of 8, 16, 32, and 64 bits, `Float32` and `Float64`; `Array`s of these numeric types; `ASCIIString` and `UTF8String`; and `Array`s of these two string types. `Array`s of strings are supported using HDF5's variable-length-strings facility.

This module also supports HDF5's VLEN, OPAQUE, and REFERENCE types, which can be used to encode more complex types. In general, you need to specify how you want to combine these more advanced facilities to represent more complex data types. For many of the data types in Julia, the JLD module implements support. You can likewise define your own file format if, for example, you need to interact with some external program that has explicit formatting requirements.

Creating groups and attributes
------------------------------

Create a new group in the following way:

```julia
g = g_create(parent, name)
```

The named group will be created as a child of the parent.

Attributes can be created using

```julia
attrs(parent)[name] = value
```

where `attrs` simply indicates that the object referenced by `name` (a string) is an attribute, not another group or dataset. (Datasets cannot have child datasets, but groups can have either.) `value` must be a simple type: `BitsKind`s, strings, and arrays of either of these. The HDF5 standard recommends against storing large objects as attributes.

Getting information
-------------------

```julia
name(obj)
```

will return the full HDF5 pathname of object `obj`.

```julia
names(g)
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
if exists(g, "mydata")
   ...
end
tf = has(g, "mydata")  # synonym for "exists"
```
If instead you want to know whether `g` has an attribute named `myattribute`, do it this way:
```julia
tf = exists(attrs(g), "myattribute")
```

If you have an HDF5 object, and you want to know where it fits in the hierarchy of the file, the following can be useful:
```julia
p = parent(obj)     # p is the parent object (usually a group)
fn = filename(obj)  # fn is a string
g = root(obj)       # g is the group "/"
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
p = get_create_properties(dset)
chunksz = get_chunk(p)
```
The simpler syntax `chunksz = get_chunk(dset)` is also available.

Finally, sometimes you need to be able to conveniently test whether a file is an HDF5 file:
```julia
tf = ishdf5(filename)
```


Mid-level routines
------------------

Sometimes you might want more fine-grained control, which can be achieved using a different set of routines. For example,
```julia
g = g_open(parent, name)
dset = d_open(parent, name[, apl])
attr = a_open(parent, name)
t = t_open(parent, name)
```

These open the named group, dataset, attribute, and committed datatype, respectively. For datasets, `apl` stands for "access parameter list" and provides opportunities for more sophisticated control (see the [HDF5][HDF5] documentation).

New objects can be created in the following ways:
```julia
g = g_create(parent, name[, lcpl, dcpl])
dset = d_create(parent, name, data[, lcpl, dcpl, dapl])
attr = a_create(parent, name, data)
```
creates groups, datasets, and attributes without writing any data to them. You can then use `write(obj, data)` to store the data. The optional property lists allow even more fine-grained control. This syntax uses `data` to infer the object's "datatype" and "dataspace"; for the most explicit control, `data` can be replaced with `dtype, dspace`, where `dtype` is an `HDF5Datatype` and `dspace` is an `HDF5Dataspace`.

Analogously, to create committed data types, use
```julia
t = t_commit(parent, name, dtype[, lcpl, tcpl, tapl])
```

You can create and write data in one step,
```julia
d_write(parent, name, data[, lcpl, dcpl, dapl])
a_write(parent, name, data)
```

You can use extendible dimensions,
```julia
d = d_create(parent, name, dtype, (dims, max_dims), "chunk", (chunk_dims), [lcpl, dcpl, dapl])
set_dims!(d, new_dims)
```
where dims is a tuple of integers.  For example
```julia
b = d_create(fid, "b", Int, ((1000,),(-1,)), "chunk", (100,)) #-1 is equivalent to typemax(Hsize)
set_dims!(b, (10000,))
b[1:10000] = collect(1:10000)
```
when dimensions are reduced, the truncated data is lost.  A maximum dimension of -1 is often referred to as unlimited dimensions, though it is limited by the maximum size of an unsigned integer.

Finally, it's possible to delete objects:
```julia
o_delete(parent, name)   # for groups, datasets, and datatypes
a_delete(parent, name)   # for attributes
```

Low-level routines
------------------

Many of the most commonly-used libhdf5 functions have been wrapped. These are not exported, so you need to preface them with `HDF5.function` to use them. The library follows a consistent convention: for example, libhdf5's `H5Adelete` is wrapped with a Julia function called `h5a_delete`. The arguments are exactly as specified in the [HDF5][HDF5] reference manual.

HDF5 is a large library, and the low-level wrap is not complete. However, many of the most-commonly used functions are wrapped, and in general wrapping a new function takes only a single line of code. Users who need additional functionality are encourage to contribute it.

Note that Julia's HDF5 directly uses the "2" interfaces, e.g., `H5Dcreate2`, so you need to have version 1.8 of the HDF5 library or later.

Details
-------

Julia, like Fortran and Matlab, stores arrays in column-major order.
HDF5 uses C's row-major order, and consequently every array's
dimensions are inverted compared to what you see with tools like
h5dump. This is the same convention as for the Fortran and Matlab HDF5
interfaces. The advantage is that no data rearrangement takes place
when reading or writing.



[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
