# HDF5 interface for the Julia language

[HDF5][HDF5] is a file format and library for storing and accessing
data, commonly used for scientific data. HDF5 files can be created and
read by numerous [programming
languages](http://www.hdfgroup.org/tools5desc.html).  This package
provides an interface to the HDF5 library for the
[Julia][Julia] language.

Language wrappers for HDF5 are often described as either "low level" or "high level." This package contains both flavors: at the low level, it directly wraps HDF5's functions, thus copying their API and making them available fro within Julia. At the high level, it provides a set of functions built on the low-level wrap which may make the usage of this library more convenient.

## Julia data (\*.jld) and Matlab (\*.mat) files

In addition to the core HDF5 functionality, this package also provides two special-purpose modules used to read and write HDF5 files with specific formatting conventions. The first is the JLD ("Julia data") module, which provides a generic mechanism for reading and writing Julia variables. While one can use "plain" HDF5 for this purpose, the advantage of the JLD module is that it preserves the exact type information of each variable. The other module is MatIO ("Matlab I/O"), which can read and write *.mat files saved as "-v7.3".

## Quickstart

To use the JLD module, begin your code with

```julia
load("jld.jl")
using JLD
using HDF5
```

Here's an example using functional syntax, which may be especially familiar to Matlab users:

```julia
file = jldopen("mydata.jld", "w")
write(file, "A", A)  # alternatively, say "@write fid A"
close(file)

file = jldopen("mydata.jld", "r")
c = read(file, "A")
close(file)
```

For HDF5 users coming from other languages, Julia's high-level wrapper providing a dictionary-like interface may be of particular interest. This is demonstrated with the "plain" (unformatted) HDF5 interface:

```julia
load("hdf5.jl")
using HDF5

file = h5open("test.h5", "w")
g = g_create(file, "mygroup") # create a group
g["dset1"] = 3.2              # create a scalar dataset
attrs(g)["Description"] = "This group contains only a single dataset" # an attribute
close(file)
```

For Matlab files, you would say ``load("matio.jl"); using MatIO``. There is no conflict in having multiple modules (HDF5, JLD, and MatIO) available simultaneously; the formatting of the file is determined by the open command.

More extensive documentation is found [here](doc/hdf5).

## Details

HDF5 is a large library, and the low-level wrap is not complete. However, many of the most-commonly used functions are wrapped, and in general wrapping a new function takes only a single line of code. Users who need additional functionality are encourage to contribute it. Low-level functions are not exported, so you access them by importing ``HDF5``. This provides access to many constants (e.g., ``HDF5.H5T_STD_I16BE``), raw dataset, datatype, and dataspace utilities, and wrappers for the direct library calls (e.g., ``HDF5.h5d_create(...)``).

Julia, like Fortran and Matlab, stores arrays in column-major order.
HDF5 uses C's row-major order, and consequently every array's
dimensions are inverted compared to what you see with tools like
h5dump. This is the same convention as for the Fortran and Matlab HDF5
interfaces. The advantage is that no data rearrangement takes place,
neither when reading nor when writing.

The test/ directory contains a number of test scripts that also contain example of usage.

## Credits

- [Konrad Hinsen](https://github.com/khinsen/julia_hdf5) initiated Julia's support for HDF5
- Tim Holy (maintainer)
- Tom Short contributed code and ideas to the dictionary-like interface, and string->type conversion in the JLD module
- [Mike Nolta](https://github.com/nolta/julia_hdf5) and Jameson Nash contributed code or suggestions for improving the handling of HDF5's constants


[Julia]: http://julialang.org "Julia"
[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
