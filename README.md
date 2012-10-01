# HDF5 interface for the Julia language

[HDF5][HDF5] is a file format and library for storing data, commonly
used for scientific data. This package provides a partial interface
to the HDF5 library for the [Julia][Julia] language.

HDF5 is a large library, and this wrapper is not complete. However, it
already provides useful functionality:

* Opening an HDF5 file for reading or writing (``fid = h5open("name.h5", "w")``)
* Navigating to "groups" (``groupMyData = fid["MyData"]``) and creating new ones (``group(fid, "MyData")``)
* Reading and writing array and string data (``write(groupMyData, "AnImage", A)`` and ``A = read(groupMyData, "AnImage")``)
* Reading subsets of data (``dset = groupMyData["AnImage"]; Asub = dset[1:2:37, 200:300]``)
* Limited support for HDF5 properties such as compression
* The ability to write arrays-of-arrays ("cell arrays") preserving their structure

Users who need more comprehensive support for HDF5 are very much
encouraged to contribute additional functionality.

Julia, like Fortran and Matlab, stores arrays in column-major order.
HDF5 uses C's row-major order, and consequently every array's
dimensions are inverted compared to what you see with tools like
h5dump. This is the same convention as for the Fortran HDF5
interface. The advantage is that no data rearrangement takes place,
neither when reading nor when writing.

This library is entirely contained in the file "hdf5.jl", and any routines using it should start in the following way:

```julia
load("hdf5.jl")
import HDF5Mod.*
```

Advanced (unexported) functionality can be accessed by importing ``HDF5Mod``.  This provides access to many constants (e.g., ``H5T_STD_I16BE``), raw dataset, datatype, and dataspace utilities, and wrappers for the direct library calls.

The easiest way to determine whether this will work for you is to load the file "test.jl", which should run without error. This file also contains further examples illustrating how to use the library.

[Julia]: http://julialang.org "Julia"
[HDF5]: http://www.hdfgroup.org/HDF5/ "HDF5"

## Credits

- [Konrad Hinsen](https://github.com/khinsen/julia_hdf5) initiated Julia support for HDF5
- [Mike Nolta](https://github.com/nolta/julia_hdf5) and Jameson Nash contributed code or suggestions for improving the handling of HDF5's constants
