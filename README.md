
<h1><img alt="HDF5.jl" src="https://raw.githubusercontent.com/JuliaIO/HDF5.jl/master/docs/src/assets/logo.svg" width=300 height=74 ></h1>

_HDF5 interface for the Julia language_


[![Stable](https://img.shields.io/badge/documentation-blue.svg)](https://JuliaIO.github.io/HDF5.jl/stable)
[![Build Status](https://github.com/JuliaIO/HDF5.jl/workflows/CI/badge.svg?branch=master)](https://github.com/JuliaIO/HDF5.jl/actions)
[![Coverage](https://codecov.io/gh/JuliaIO/HDF5.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaIO/HDF5.jl)
<!-- [![Coverage](https://coveralls.io/repos/github/JuliaIO/HDF5.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaIO/HDF5.jl?branch=master) -->

[HDF5](https://www.hdfgroup.org/solutions/hdf5/) is a file format and library for storing and
accessing data, commonly used for scientific data. HDF5 files can be created and read by numerous
[programming languages](https://en.wikipedia.org/wiki/Hierarchical_Data_Format#Interfaces). This
package provides an interface to the HDF5 library for the Julia language.

### Changelog

Please see [HISTORY.md](HISTORY.md). Most changes have deprecation warnings and thus may not be listed in the changelog.

### Installation

```julia
julia>]
pkg> add HDF5
```
For custom build instructions please refer to the [documentation](https://JuliaIO.github.io/HDF5.jl/stable).

### Quickstart


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
    g = create_group(file, "mygroup") # create a group
    g["dset1"] = 3.2                  # create a scalar dataset inside the group
    attributes(g)["Description"] = "This group contains only a single dataset" # an attribute
end
```

Convenience functions for attributes attached to datasets are also provided:

```julia
A = Vector{Int}(1:10)
h5write("bar.h5", "foo", A)
h5writeattr("bar.h5", "foo", Dict("c"=>"value for metadata parameter c","d"=>"metadata d"))
h5readattr("bar.h5", "foo")
```
