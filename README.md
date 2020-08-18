
<h1><img alt="HDF5.jl" src="https://raw.githubusercontent.com/JuliaIO/HDF5.jl/master/docs/src/assets/logo.svg" width=300 height=74 ></h1>

_HDF5 interface for the Julia language_

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaIO.github.io/HDF5.jl/stable)
[![Build Status](https://github.com/JuliaIO/HDF5.jl/workflows/CI/badge.svg)](https://github.com/JuliaIO/HDF5.jl/actions)
[![Build Status](https://travis-ci.com/JuliaIO/HDF5.jl.svg?branch=master)](https://travis-ci.com/JuliaIO/HDF5.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/4iagqqiqqo36sika/branch/master?svg=true)](https://ci.appveyor.com/project/musm/HDF5-jl)
[![Coverage](https://codecov.io/gh/JuliaIO/HDF5.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaIO/HDF5.jl)
<!-- [![Coverage](https://coveralls.io/repos/github/JuliaIO/HDF5.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaIO/HDF5.jl?branch=master) -->

[HDF5](https://www.hdfgroup.org/solutions/hdf5/) is a file format and library for storing and accessing
data, commonly used for scientific data. HDF5 files can be created and
read by numerous [programming
languages](https://en.wikipedia.org/wiki/Hierarchical_Data_Format#Interfaces).  This package
provides an interface to the HDF5 library for the Julia language.

## Installation

```julia
julia>]
pkg> add HDF5
```

Starting from Julia 1.3, the HDF5 binaries are by default downloaded using the
[HDF5_jll](https://github.com/JuliaBinaryWrappers/HDF5_jll.jl) package.
To use system-provided HDF5 binaries instead, set the environment variable
`JULIA_HDF5_LIBRARY_PATH` to the HDF5 library path and then run
`Pkg.build("HDF5")`.
This is in particular needed for parallel HDF5 support, which is not provided
by the `HDF5_jll` binaries.

For example, you can set `JULIA_HDF5_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/hdf5/mpich/`
if you're using the system package [`libhdf5-mpich-dev`](https://packages.ubuntu.com/focal/libhdf5-mpich-dev)
on Ubuntu 20.04.

## Quickstart

Begin your code with

```julia
using HDF5
```

To read and write a variable to a file, one approach is to use the filename:
```julia
A = collect(reshape(1:120, 15, 8))
h5write("/tmp/test2.h5", "mygroup2/A", A)
data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))
```
where the last line reads back just `A[2:3:15, 3:5]` from the dataset.

More fine-grained control can be obtained using functional syntax:

```julia
h5open("mydata.h5", "w") do file
    write(file, "A", A)  # alternatively, say "@write file A"
end

c = h5open("mydata.h5", "r") do file
    read(file, "A")
end
```
This allows you to add variables as they are generated to an open HDF5 file.
You don't have to use the `do` syntax (`file = h5open("mydata.h5", "w")` works
just fine), but an advantage is that it will automatically close the file (`close(file)`)
for you, even in cases of error.

Julia's high-level wrapper, providing a dictionary-like interface, may
also be of interest:

```julia
using HDF5

h5open("test.h5", "w") do file
    g = g_create(file, "mygroup") # create a group
    g["dset1"] = 3.2              # create a scalar dataset inside the group
    attrs(g)["Description"] = "This group contains only a single dataset" # an attribute
end
```

Convenience functions for attributes attached to datasets are also provided:

```julia
A = Vector{Int}(1:10)
h5write("bar.h5", "foo", A)
h5writeattr("bar.h5", "foo", Dict("c"=>"value for metadata parameter c","d"=>"metadata d"))
h5readattr("bar.h5", "foo")
```


## Specific file formats

There is no conflict in having multiple modules (HDF5, [JLD](https://github.com/JuliaIO/JLD.jl), and
[MAT](https://github.com/simonster/MAT.jl)) available simultaneously;
the formatting of the file is determined by the open command.

## Complete documentation

The HDF5 API is much more extensive than suggested by this brief
introduction.  More complete documentation is found in the [documentation](https://JuliaIO.github.io/HDF5.jl/stable).

The [`test`](test/) directory contains a number of test scripts that also
demonstrate usage.

## Credits

- Konrad Hinsen initiated Julia's support for HDF5

- Tim Holy and Simon Kornblith (co-maintainers and primary authors)

- Tom Short contributed code and ideas to the dictionary-like
  interface

- Blake Johnson made several improvements, such as support for
  iterating over attributes

- Isaiah Norton and Elliot Saba improved installation on Windows and OSX

- Steve Johnson contributed the `do` syntax and Blosc compression

- Mike Nolta and Jameson Nash contributed code or suggestions for
  improving the handling of HDF5's constants

- Thanks also to the users who have reported bugs and tested fixes

