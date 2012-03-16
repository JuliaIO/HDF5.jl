<a name="HDF5-interface-for-the-Julia-language"/>

## HDF5 interface for the Julia language

This is a first attempt at writing a Julia interface to the HDF5
library.  At the moment, it only supports accessing groups and
datasets inside a file, and reading from datasets whose dataspace is
of type "simple" (meaning arrays). Adding the remaining HDF5 features
(attributes, compound datatypes, etc.) and of course HDF5 output is
not particularly difficult, but a lot of work. I probably won't
continue to work on this until there are better tools for Julia-C
interfacing.  In fact, I'd rather write such a tool myself than
continue to do everything manually.

The interface consists of two parts: (1) a small C wrapper,
hdf5_wrapper.c, which is necessary because the Julia C interface
doesn't (yet?) support C structs, and (2) a Julia file, hdf5.jl, which
accesses HDF5 through Julia's ccall function.  The C wrapper must be
compiled first, using the supplied Makefile. This has been tested on
MacOS X only.

Since Julia stores arrays in column-major order, like Fortran, wheras
HDF5 uses C's row-major order, every array's dimensions are inverted
compared to what you see with tools like h5dump. This is the same
convention as for the Fortran HDF5 interface. The advantage is
that no data rearrangement takes place, neither when reading nor
when writing.

<a name="Resources"/>

- **Julia:** <http://julialang.org>
- **HDF5:** <http://www.hdfgroup.org/HDF5/>
