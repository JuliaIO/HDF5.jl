

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
    <td>"w"</td> <td>read-write, destroying any existing contents (if any)</td>
  </tr>
</table>

This produces an object of type `PlainHDF5File`, a subtype of the abstract type `HDF5File`. The subtypes of `HDF5File` are used in method dispatch to enforce any file-type-specific formatting. "Plain" files have no elements (groups, datasets, or attributes) that are not explicitly created by the user.

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

You can read the information in a dataset in any of the following ways:

```julia
A = read(dset)
A = read(g, "mydataset")
Asub = dset[2:3, 1:3]
```

The last syntax reads just a subset of the data array (assuming that `dset` is an array of sufficient size). libhdf5 has internal mechanisms for slicing arrays, and consequently if you need only a small piece of a large array, it can be faster to read just what you need rather than reading the entire array and discarding most of it.

Datasets can be created in either of the following ways:

```julia
g["mydataset"] = rand(3,5)
write(g, "mydataset", rand(3,5))
```

You can also optionally "chunk" and compress your data. For example,

```julia
A = rand(100,100)
g["A", "chunk", (5,5), "compress", 3] = A
```

stores the matrix `A` in 5-by-5 chunks and uses a compression level 3. Chunking can be useful if you will typically extract small segments of an array. Chunking is required if you plan to use compression.

More [fine-grained control](#mid-level-routines) is also available.

Supported data types
--------------------

PlainHDF5File knows how to store values of the following types: signed and unsigned integers of 8, 16, 32, and 64 bits, `Float32` and `Float64`; `Array`s of these numeric types; `ASCIIString` and `UTF8String`; and `Array`s of these two string types. `Array`s of strings are supported using HDF5's variable-length-strings facility.

This module also supports HDF5's VLEN, OPAQUE, and REFERENCE types, which can be used to encode more complex types. In general, you need to specify how you want to combine these more advanced facilities to represent more complex data types. For many of the data types in Julia, the JLD module implements support. You can likewise define your own file format if, for example, you need to interact with some external program that has explicit formatting requirements.

Creating groups and attributes
------------------------------

Create a new group in the following way:

```julia
g = g_create(parent::Union(HDF5File, HDF5Group), name::ASCIIString)
```

The named group will be created as a child of the parent.

Attributes can be created using

```julia
attrs(parent::Union(HDF5Group, HDF5Dataset))[name] = value
```

where `attrs` simply indicates that the object referenced by `name` (a string) is an attribute, not another group or dataset. (Datasets cannot have child datasets, but groups can have either.) `value` must be a simple type: `BitsKind`s, strings, and arrays of either of these. The HDF5 standard does not permit attributes to store "complex" objects. 

Getting information
-------------------

```julia
name(obj)
```

will return the full HDF5 pathname of object `obj`.

```julia
names(g)
```

will show all objects inside group `g`.

You can iterate over the objects in a group, i.e.,
```julia
for obj in g
  data = read(obj)
  println(data)
end
```
This gives you a straightforward way of recursively exploring an entire HDF5 file. A convenient way of examining the structure of an HDF5 file is the `dump` function, e.g.,
```julia
dump(fid)
```

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

Finally, sometimes you need to be able to conveniently test whether a file is an HDF5 file:
```julia
tf = ishdf5(filename)
```


Mid-level routines
------------------

Sometimes you might want more fine-grained control, which can be achieved using a different set of routines. For example,
```julia
g = g_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString)
dset = d_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString[, apl])
attr = a_open(parent::Union(HDF5Group, HDF5Dataset), name::ASCIIString)
t = t_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString)
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

Low-level routines
------------------

Many of the most commonly-used libhdf5 functions have been wrapped. These are not exported, so you need to preface them with `HDF5.function` to use them. The library follows a consistent convention: for example, libhdf5's `H5Adelete` is wrapped with a Julia function called `h5a_delete`. The arguments are exactly as specified in the [HDF5][HDF5] reference manual.

Note that Julia's HDF5 directly uses the "2" interfaces, e.g., `H5Dcreate2`, so you need to have version 1.8 of the HDF5 library or later.

Details
-------

HDF5 is a large library, and the low-level wrap is not complete. However, many of the most-commonly used functions are wrapped, and in general wrapping a new function takes only a single line of code. Users who need additional functionality are encourage to contribute it. Low-level functions are not exported, so you access them by importing ``HDF5``. This provides access to many constants (e.g., ``HDF5.H5T_STD_I16BE``), raw dataset, datatype, and dataspace utilities, and wrappers for the direct library calls (e.g., ``HDF5.h5d_create(...)``).

Julia, like Fortran and Matlab, stores arrays in column-major order.
HDF5 uses C's row-major order, and consequently every array's
dimensions are inverted compared to what you see with tools like
h5dump. This is the same convention as for the Fortran and Matlab HDF5
interfaces. The advantage is that no data rearrangement takes place,
neither when reading nor when writing.



[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
