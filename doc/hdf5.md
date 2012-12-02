

HDF5 Reference Guide
=======================

Overview
--------

[HDF5][HDF5] stands for Hierarchical Data Format v5 and is closely modeled on file systems. In HDF5, a "group" is analogous to a directory, a "dataset" is like a file. HDF5 also uses "attributes" to associate metadata with a particular group or dataset. HDF5 uses ASCII names for these different objects, and objects can be accessed by UNIX-like pathnames, e.g., "/sample1/tempsensor/firsttrial" for a top-level group "sample1", a subgroup "tempsensor", and a dataset "firsttrial".

For simple types (scalars, strings, and arrays), HDF5 provides sufficient metadata to know how each item is to be interpreted. For example, HDF5 encodes that a given block of bytes is to be interpreted as an array of `Int64`, and represents them in a way that is compatible across different computing architectures.

However, to preserve Julia objects, one generally needs additional type information to be supplied, which is easy to provide using attributes. This is handled for you automatically in the [JLD](/jld/) and [MatIO](/matio/) modules, for two different conventions (\*.jld and \*.mat files, respectively). These specific formats provide "extra" functionality, but they are still both regular HDF5 files and are therefore compatible with any HDF5 reader or writer.


Opening and closing files
-------------------------

Files are created and/or opened with the `h5open` command:

```julia
fid = h5open(filename, mode)
```

The mode can be any one of the following:

<table>
  <tr>
    <td>mode</td> <td>Meaning</td>
  </tr>
  <tr>
    <td>`"r"`</td> <td>read-only</td>
  </tr>
  <tr>
    <td>`"r+"`</td> <td>read-write, preserving any existing contents</td>
  </tr>
  <tr>
    <td>`"w"`</td> <td>read-write, destroying any existing contents (if any)</td>
  </tr>
</table>

This produces an object of type `PlainHDF5File`, a subtype of the abstract type `HDF5File`. The subtypes of `HDF5File` are used in method dispatch to enforce any file-type-specific formatting. "Plain" files have no additional formatting.

Similarly, you close the file using `close`:

```julia
close(fid)
```

Closing a file also closes any other open objects (e.g., datasets, groups) in that file.

Opening and closing objects
---------------------------

If you have a group or dataset called `"myobject"` at the top level of a file, you can open it in the following way:

```julia
obj = fid["myobject"]
```

This does not read any data or attributes associated with the object; it's simply a handle for further manipulations. For example:

```julia
g = fid["mygroup"]
dset = g["mydataset"]
```

or simply

```julia
dset = fid["mygroup/mydataset"]
```

Close the object using `close(obj)`.

Reading and writing data
------------------------

You can read the information in a dataset in any of the following ways:

```julia
A = read(dset)
A = read(g, "mydataset")
Asub = dset[2:3, 1:3]
```

The last syntax reads just a subset of the data array, and can be an efficient way to extract a subset of the data.

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

stores the matrix `A` in 5-by-5 chunks (to facilitate extracting small pieces) and uses a compression level 3.

More [fine-grained control](#midlevel) is also available.

Supported data types
--------------------

PlainHDF5File knows how to store values of the following types: signed and unsigned integers of 8, 16, 32, and 64 bits, `Float32` and `Float64`; `Array`s of these numeric types; `ASCIIString` and `UTF8String`; and `Array`s of these two string types. `Array`s of strings are supported using HDF5's VLEN type. This package also support HDF5's OPAQUE and REFERENCE types, which can be used to encode more complex types. However, there is no convention specified for storing such objects; for such objects, the [JLD](/jld/) module may be of interest.

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


Mid-level routines  <a id="midlevel"></a>
------------------

```julia
g = g_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString)
dset = d_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString[, apl])
attr = a_open(parent::Union(HDF5Group, HDF5Dataset), name::ASCIIString)
t = t_open(parent::Union(HDF5File, HDF5Group), name::ASCIIString)
```

These open the named group, dataset, attribute, and committed datatype, respectively. For datasets, `apl` stands for "access parameter list" and provides opportunities for more sophisticated control (see the [HDF5][HDF5]) documentation.

Similarly,

```julia
g = g_create(parent, name[, lcpl, dcpl])
dset = d_create(parent, name, dtype, dspace[, lcpl, dcpl, dapl])
attr = a_create(parent, name, dtype, dspace)
```

creates groups, datasets, and attributes without writing any data to them. You can then use `write(obj, data)` to store the data.

```julia
t = t_commit(parent, name, dtype[, lcpl, tcpl, tapl]) 
```

This creates (commits) a committed data type.

Exploring contents of a file or group
-------------------------------------

```julia
name(obj)
```

will return the full HDF5 pathname of object `obj`.

```julia
names(g)
```

will show all objects inside group `g`.

```julia
g = root(obj)
```

will return the "root group" ("/") for any file, given an object in that file.

### File-specific methods

```julia
tf::Bool = ishdf5(filename::String)
```

tests whether a file with the given name is an HDF5 file.

----
[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
