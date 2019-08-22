# HDF5 interface for the Julia language

[![Build Status](https://travis-ci.org/JuliaIO/HDF5.jl.svg?branch=master)](https://travis-ci.org/JuliaIO/HDF5.jl) [![Build status](https://ci.appveyor.com/api/projects/status/4iagqqiqqo36sika/branch/master?svg=true)](https://ci.appveyor.com/project/musm/hdf5-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/github/JuliaIO/HDF5.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaIO/HDF5.jl?branch=master)
[![codecov](https://codecov.io/gh/JuliaIO/HDF5.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaIO/HDF5.jl)

[HDF5][HDF5] is a file format and library for storing and accessing
data, commonly used for scientific data. HDF5 files can be created and
read by numerous [programming
languages](http://www.hdfgroup.org/tools5desc.html).  This package
provides an interface to the HDF5 library for the
[Julia][Julia] language.

## Julia data (\*.jld) and Matlab (\*.mat) files

The core HDF5 functionality is the foundation for two special-purpose
packages, used to read and write HDF5 files with specific formatting
conventions. The first is the
[JLD](https://github.com/JuliaIO/JLD.jl) ("Julia data") package,
which implements a generic mechanism for reading and writing Julia
variables. While one can use "plain" HDF5 for this purpose, the
advantage of the JLD package is that it preserves the exact type
information of each variable.

The other functionality provided through HDF5 is the ability to read
and write Matlab \*.mat files saved as "-v7.3". The Matlab-specific
portions have been moved to Simon Kornblith's
[MAT.jl](https://github.com/simonster/MAT.jl) package.

## Installation

```julia
julia>]
pkg> add HDF5
```

If your platform is not supported then we automatically attempt to build hdf5 from source. To manually force a source build set the environment variable `julia> ENV["FORCE_COMPILE_HDF5"] = "yes"`. If a suitable MPI compiler is detected hdf5 will be built with parallel support.

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
introduction.  More complete documentation is found in the
[`doc`](doc/) directory.

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


[Julia]: http://julialang.org "Julia"
[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
