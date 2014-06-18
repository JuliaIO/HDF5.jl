# HDF5 interface for the Julia language

[HDF5][HDF5] is a file format and library for storing and accessing
data, commonly used for scientific data. HDF5 files can be created and
read by numerous [programming
languages](http://www.hdfgroup.org/tools5desc.html).  This package
provides an interface to the HDF5 library for the
[Julia][Julia] language.

## Julia data (\*.jld) and Matlab (\*.mat) files

The core HDF5 functionality is the foundation for two special-purpose
modules, used to read and write HDF5 files with specific formatting
conventions. The first is the JLD ("Julia data") module (provided in
this package), which implements a generic mechanism for reading and
writing Julia variables. While one can use "plain" HDF5 for this
purpose, the advantage of the JLD module is that it preserves the
exact type information of each variable.

The other functionality provided through HDF5 is the ability to read
and write Matlab \*.mat files saved as "-v7.3". The Matlab-specific
portions have been moved to Simon Kornblith's
[MAT.jl](https://github.com/simonster/MAT.jl) repository.

## Installation

Within Julia, use the package manager:
```julia
Pkg.add("HDF5")
```

You also need to have the HDF5 library installed on your
system (version 1.8 or higher is required), but **for most users
no additional steps should be required; the HDF5 library should be
installed for you automatically when you add the package.**

If you have to install HDF5 manually, here are some examples of
how to do it:

- Debian/(K)Ubuntu: `apt-get -u install hdf5-tools`
- OSX: `brew tap homebrew/science; brew install hdf5` (using [Homebrew](http://brew.sh))
- Windows: determine whether you're running 32bit or 64bit Julia by
  typing `Int` on the command line. Then
  [download](http://www.hdfgroup.org/HDF5/release/obtain5.html) the
  appropriate version, using the Visual Studio (VS) build. When you
  run the installer, allow it to set up the system PATH variable as
  suggested (Julia will use this to help find the library).

If you've installed the library but discover that Julia is not finding
it, you can add the path to Julia's `Sys.DL_LOAD_PATH` variable, e.g.,
```
push!(Sys.DL_LOAD_PATH, "/opt/local/lib")
```
Inserting this command into your `.juliarc.jl` file will cause this to
happen automatically each time you start Julia.

If you're on Linux but you do not have root privileges on your machine (and
you can't persuade the sysadmin to install the libraries for you), you can [download](http://www.hdfgroup.org/HDF5/release/obtain5.html) the
binaries and place them somewhere in your home directory. To use HDF5,
you'll have to start julia as
```
LD_LIBRARY_PATH=/path/to/hdf5/libs julia
```
You can set up an alias so this happens for you automatically each time
you start julia.

## Quickstart

To use the JLD module, begin your code with

```julia
using HDF5, JLD
```

If you just want to save a few variables and don't care to use the more
advanced features of HDF5, then a simple syntax is:

```
t = 15
z = [1,3]
save("/tmp/myfile.jld", "t", t, "arr", z)
```
Here we're explicitly saving `t` and `z` as `"t"` and `"arr"` within
myfile.jld. You can alternatively pass `save` a dictionary; the keys must be
strings and are saved as the variable names of their values within the JLD
file. You can read these variables back in with
```
d = load("/tmp/myfile.jld")
```
which reads the entire file into a returned dictionary `d`. Or you can be more
specific and just request particular variables of interest. For example, `z =
load("/tmp/myfile.jld", "arr")` will return the value of `arr` from the file
and assign it back to z.

There are also convenience macros `@save` and `@load` that work on the
variables themselves. `@save "/tmp/myfile.jld" t z` will create a file with
just `t` and `z`; if you don't mention any variables, then it saves all the
variables in the current module. Conversely, `@load` will pop the saved
variables directly into the global workspace of the current module.
However, keep in mind that these macros have significant limitations: for example,
you can't use `@load` inside a function, there are constraints on using string
interpolation inside filenames, etc. These limitations stem
from the fact that Julia compiles functions to machine code before evaluation,
so you cannot introduce new variables at runtime or evaluate expressions
in other workspaces.
The `save` and `load` functions do not have these limitations, and are therefore
recommended as being considerably more robust, at the cost of some slight
reduction of convenience.

For plain HDF5 files, you can similarly say
```julia
A = reshape(1:120, 15, 8)
h5write("/tmp/test2.h5", "mygroup2/A", A)
data = h5read("/tmp/test2.h5", "mygroup2/A", (2:3:15, 3:5))
```
where the last line reads back just `A[2:3:15, 3:5]` from the dataset.

More fine-grained control can be obtained using functional syntax:

```julia
jldopen("mydata.jld", "w") do file
    write(file, "A", A)  # alternatively, say "@write file A"
end

c = jldopen("mydata.jld", "r") do file
    read(file, "A")
end
```
This allows you to add variables as they are generated to an open JLD file.
You don't have to use the `do` syntax (`file = jldopen("mydata.jld", "w")` works
just fine), but an advantage is that it will automatically close the file (`close(file)`)
for you, even in cases of error.

Julia's high-level wrapper, providing a dictionary-like interface, may
also be of interest. This is demonstrated with the "plain" (unformatted)
HDF5 interface:

```julia
using HDF5

h5open("test.h5", "w") do file
    g = g_create(file, "mygroup") # create a group
    g["dset1"] = 3.2              # create a scalar dataset inside the group
    attrs(g)["Description"] = "This group contains only a single dataset" # an attribute
end
```

There is no conflict in having multiple modules (HDF5, JLD, and
[MAT](https://github.com/simonster/MAT.jl)) available simultaneously;
the formatting of the file is determined by the open command.

## Complete documentation

More extensive documentation is found in the [`doc/`](doc/) directory.

The `test/` directory contains a number of test scripts that also
demonstrate usage.

## Credits

- [Konrad Hinsen](https://github.com/khinsen/julia_hdf5) initiated
  Julia's support for HDF5

- Tim Holy and Simon Kornblith (co-maintainers and primary authors)

- Tom Short contributed code and ideas to the dictionary-like
  interface, and string->type conversion in the JLD module

- Blake Johnson made several improvements, such as support for
  iterating over attributes

- Isaiah Norton and Elliot Saba improved installation on Windows and OSX

- Steve Johnson contributed the `do` syntax

- Mike Nolta and Jameson Nash contributed code or suggestions for
  improving the handling of HDF5's constants

- Thanks also to the users who have reported bugs and tested fixes


[Julia]: http://julialang.org "Julia"
[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"
