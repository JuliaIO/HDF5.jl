# Parallel HDF5

It is possible to read and write [parallel
HDF5](https://portal.hdfgroup.org/display/HDF5/Parallel+HDF5) files using MPI.
For this, the HDF5 binaries loaded by HDF5.jl must have been compiled with
parallel support, and linked to the specific MPI implementation that will be used for parallel I/O.

Parallel-enabled HDF5 libraries are usually included in computing clusters and
linked to the available MPI implementations.
They are also available via the package manager of a number of Linux
distributions.

Finally, note that the MPI.jl package is lazy-loaded by HDF5.jl
using [Requires](https://github.com/JuliaPackaging/Requires.jl).
In practice, this means that in Julia code, `MPI` must be imported _before_
`HDF5` for parallel functionality to be available.

## Setting-up Parallel HDF5

The following step-by-step guide assumes one already has access to
parallel-enabled HDF5 libraries linked to an existent MPI installation.

### 1. Using system-provided MPI libraries

Set the environment variable `JULIA_MPI_BINARY=system` and then run
`]build MPI` from Julia.
For more control, one can also set the `JULIA_MPI_PATH` environment variable
to the top-level installation directory of the MPI library.
See the [MPI.jl
docs](https://juliaparallel.github.io/MPI.jl/stable/configuration/#Using-a-system-provided-MPI-1)
for details.

### 2. Using parallel HDF5 libraries

As detailed in [Using custom or system provided HDF5 binaries](@ref), set the
`JULIA_HDF5_PATH` environment variable to the path where the parallel HDF5
binaries are located.
Then run `]build HDF5` from Julia.

### 3. Loading MPI-enabled HDF5

In Julia code, MPI.jl must be loaded _before_ HDF5.jl for MPI functionality to
be available:

```julia
using MPI
using HDF5

@assert HDF5.has_parallel()
```

### Reading and writing data in parallel

A parallel HDF5 file may be opened by passing a `MPI.Comm` (and optionally a
`MPI.Info`) object to [`h5open`](@ref).
For instance:

```julia
comm = MPI.COMM_WORLD
info = MPI.Info()
ff = h5open(filename, "w", comm, info)
```

MPI-distributed data is typically written by first creating a dataset
describing the global dimensions of the data.
The following example writes a `10 × Nproc` array distributed over `Nproc` MPI
processes.

```julia
Nproc = MPI.Comm_size(comm)
myrank = MPI.Comm_rank(comm)
M = 10
A = fill(myrank, M)  # local data
dims = (M, Nproc)    # dimensions of global data

# Create dataset
dset = create_dataset(ff, "/data", datatype(eltype(A)), dataspace(dims))

# Write local data
dset[:, myrank + 1] = A
```

Note that metadata operations, such as `create_dataset`, must be called _collectively_ (on all processes at the same time, with the same arguments), but the actual writing to the dataset may be done independently. See [Collective Calling Requirements in Parallel HDF5 Applications](https://portal.hdfgroup.org/display/HDF5/Collective+Calling+Requirements+in+Parallel+HDF5+Applications) for the exact requirements.

Sometimes, it may be more efficient to write data in chunks, so that each
process writes to a separate chunk of the file.
This is especially the case when data is uniformly distributed among MPI
processes.
In this example, this can be achieved by passing `chunk=(M, 1)` to `create_dataset`.

For better performance, it is sometimes preferable to perform [collective
I/O](https://portal.hdfgroup.org/display/HDF5/Introduction+to+Parallel+HDF5)
when reading and writing datasets in parallel.
This is achieved by passing `dxpl_mpio=:collective` to `create_dataset`.
See also the [HDF5 docs](https://portal.hdfgroup.org/display/HDF5/H5P_SET_DXPL_MPIO).

A few more examples are available in [`test/mpio.jl`](https://github.com/JuliaIO/HDF5.jl/blob/master/test/mpio.jl).

