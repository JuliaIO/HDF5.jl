# HDF5 interface for the Julia language

[HDF5][HDF5] is a file format and library for storing and accessing
data, commonly used for scientific data. HDF5 files can be created and
read by numerous [programming
languages](http://www.hdfgroup.org/tools5desc.html).  This package
provides an interface to the HDF5 library for the
[Julia][Julia] language.

## Julia data (\*.jld) and Matlab (\*.mat) files

The core HDF5 functionality is the foundation for two special-purpose modules, used to read and write HDF5 files with specific formatting conventions. The first is the JLD ("Julia data") module (provided in this package), which implements a generic mechanism for reading and writing Julia variables. While one can use "plain" HDF5 for this purpose, the advantage of the JLD module is that it preserves the exact type information of each variable.

The other functionality provided through HDF5 is the ability to read and write Matlab \*.mat files saved as "-v7.3". The Matlab-specific portions have been moved to Simon Kornblith's [MAT.jl](https://github.com/simonster/MAT.jl) repository.

## Installation

Within Julia, use the package manager:
```julia
Pkg.add("HDF5")
```

You also need to have the HDF5 library installed on your system. Version 1.8 or higher is required. Here are some examples of how to install HDF5:

- Debian/(K)Ubuntu: `apt-get -u install hdf5-tools`
- OSX: `brew install hdf5` (using [Homebrew](http://mxcl.github.com/homebrew/))
- Windows: determine whether you're running 32bit or 64bit Julia by typing `Int` on the command line. Then [download](http://www.hdfgroup.org/HDF5/release/obtain5.html) the appropriate version, using the Visual Studio (VS) build. When you run the installer, allow it to set up the system PATH variable as suggested (Julia will use this to help find the library).

## Quickstart

To use the JLD module, begin your code with

```julia
using HDF5
using JLD
```

Here's an example using functional syntax, which may be especially familiar to Matlab users:

```julia
file = jldopen("mydata.jld", "w")
write(file, "A", A)  # alternatively, say "@write file A"
close(file)

file = jldopen("mydata.jld", "r")
c = read(file, "A")
close(file)
```

For HDF5 users coming from other languages, Julia's high-level wrapper providing a dictionary-like interface may be of interest. This is demonstrated with the "plain" (unformatted) HDF5 interface:

```julia
using HDF5

file = h5open("test.h5", "w")
g = g_create(file, "mygroup") # create a group
g["dset1"] = 3.2              # create a scalar dataset
attrs(g)["Description"] = "This group contains only a single dataset" # an attribute
close(file)
```

There is no conflict in having multiple modules (HDF5, JLD, and [MAT](https://github.com/simonster/MAT.jl)) available simultaneously; the formatting of the file is determined by the open command.

More extensive documentation is found in the `doc/` directory.

The test/ directory contains a number of test scripts that also contain example of usage.

## Credits

- [Konrad Hinsen](https://github.com/khinsen/julia_hdf5) initiated Julia's support for HDF5
- Tim Holy (maintainer)
- Tom Short contributed code and ideas to the dictionary-like interface, and string->type conversion in the JLD module
- Simon Kornblith fixed problems in the Matlab support
- Blake Johnson made several improvements, such as support for iterating over attributes
- Mike Nolta and Jameson Nash contributed code or suggestions for improving the handling of HDF5's constants
- Several users have reported bugs and tested fixes: Jason Knight, Mark McCurry


[Julia]: http://julialang.org "Julia"
[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
