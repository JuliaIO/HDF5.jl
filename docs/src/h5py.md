# Python interoperability

When loading python created hdf5 files from Julia the dimensions of arrays are reversed.
The reason is that in python C-memory layout is the default, while Julia uses Fortran layout.
Here is an example:

```@example h5py
using PyCall #hide
import Conda #hide
Conda.add("h5py") #hide
Conda.add("numpy") #hide
py""" #hide
import h5py
import numpy as np
path = "created_by_h5py.h5"
file = h5py.File(path, "w")
arr1d = np.array([1,2,3])
arr2d = np.array([[1,2,3], [4,5,6]])
arr3d = np.array([[[1,2,3], [4,5,6]]])
assert arr1d.shape == (3,)
assert arr2d.shape == (2,3)
assert arr3d.shape == (1,2,3)
file["1d"] = arr1d
file["2d"] = arr2d
file["3d"] = arr3d
file.close()
""" #hide
```

When we try to load it from julia, dimensions are reversed:

```@example h5py
using HDF5
using Test
path = "created_by_h5py.h5"
h5open(path, "r") do file
    arr1d = read(file["1d"])
    arr2d = read(file["2d"])
    arr3d = read(file["3d"])
    @test size(arr1d) == (3,)
    @test size(arr2d) == (3,2)
    @test size(arr3d) == (3,2,1)
end
```

To fix this, we can simply reverse the dimensions again:

```@example h5py
function reversedims(arr)
    return permutedims(arr, reverse(1:ndims(arr)))
end

path = "created_by_h5py.h5"
h5open(path, "r") do file
    arr1d = reversedims(read(file["1d"]))
    arr2d = reversedims(read(file["2d"]))
    arr3d = reversedims(read(file["3d"]))
    @test arr1d == [1,2,3]
    @test arr2d == [1 2 3; 4 5 6]
    @test arr3d == reshape(arr2d, (1,2,3))
end
```

  Similarly `reversedims` can be used before saving arrays intended for use from python.
  If copying of data is undesirable, other options are:
  * using Fortran memory layout on the python side
  * using C-memory layout on the Julia side (e.g. replace `permutedims` by `PermutedDimsArray` above)

```@example h5py
using HDF5
path = "created_by_h5py.h5"
h5open(path, "r") do file
    arr1d = read(file["1d"])
    arr2d = read(file["2d"])
    arr3d = read(file["3d"])
    @test size(arr1d) == (3,)
    @test size(arr2d) == (3,2)
    @test size(arr3d) == (3,2,1)
end

using HDF5
function reversedims(arr)
    dims = ntuple(identity, Val(ndims(arr)))
    return permutedims(arr, reverse(dims))
end

path = "created_by_h5py.h5"
h5open(path, "r") do file
    arr1d = reversedims(read(file["1d"]))
    arr2d = reversedims(read(file["2d"]))
    arr3d = reversedims(read(file["3d"]))
    @test arr1d == [1,2,3]
    @test arr2d == [1 2 3; 4 5 6]
    @test arr3d == reshape(arr2d, (1,2,3))
end
```
