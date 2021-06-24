using .MPI
import Libdl

# Low-level MPI handles.
const MPIHandle = Union{MPI.MPI_Comm, MPI.MPI_Info}

# MPI.jl wrapper types.
const MPIHandleWrapper = Union{MPI.Comm, MPI.Info}

const H5MPIHandle = let csize = sizeof(MPI.MPI_Comm)
    @assert csize in (4, 8)
    csize == 4 ? API.Hmpih32 : API.Hmpih64
end

h5_to_mpi_comm(handle::H5MPIHandle) = reinterpret(MPI.MPI_Comm, handle)
h5_to_mpi_info(handle::H5MPIHandle) = reinterpret(MPI.MPI_Info, handle)

mpi_to_h5(handle::MPIHandle) = reinterpret(H5MPIHandle, handle)
mpi_to_h5(mpiobj::MPIHandleWrapper) = mpi_to_h5(mpiobj.val)


"""
    MPIO(comm::MPI.Comm, info::MPI.Info)
    MPIO(comm::MPI.Comm; kwargs....)

The parallel MPI file driver. This requires the use of
[MPI.jl](https://github.com/JuliaParallel/MPI.jl), and a custom HDF5 binary that has been
built with MPI support.

- `comm` is the communicator over which the file will be opened.
- `info`/`kwargs` are MPI-IO options, and are passed to `MPI_FILE_OPEN`.

# External links

- $(h5doc("H5P_SET_FAPL_MPIO"))
- [Parallel HDF5](https://portal.hdfgroup.org/display/HDF5/Parallel+HDF5)
"""
struct MPIO <: Driver
    comm::MPI.Comm
    info::MPI.Info
end
 MPIO(comm::MPI.Comm; kwargs...) =
    MPIO(comm, MPI.Info(;kwargs...))

# Check whether the HDF5 libraries were compiled with parallel support.
try
    DRIVERS[API.h5fd_mpio_init()] = MPIO
    HDF5.HAS_PARALLEL[] = true
catch e
end

function set_driver!(fapl::Properties, mpio::MPIO)
    HDF5.has_parallel() || error(
        "HDF5.jl has no parallel support." *
        " Make sure that you're using MPI-enabled HDF5 libraries, and that" *
        " MPI was loaded before HDF5." *
        " See HDF5.jl docs for details."
    )
    # Note: HDF5 creates a COPY of the comm and info objects.
    GC.@preserve mpio begin
        API.h5p_set_fapl_mpio(fapl, mpi_to_h5(mpio.comm), mpi_to_h5(mpio.info))
    end
end

function get_driver(fapl::Properties, ::Type{MPIO})
    h5comm, h5info = API.h5p_get_fapl_mpio(fapl, H5MPIHandle)
    comm = MPI.Comm(h5_to_mpi_comm(h5comm))
    info = MPI.Info(h5_to_mpi_info(h5info))
    return MPIO(comm, info)
end

"""
    h5open(filename, [mode="r"], comm::MPI.Comm, [info::MPI.Info]; pv...)

Open or create a parallel HDF5 file using the MPI-IO driver.

Equivalent to `h5open(filename, mode; fapl_mpio=(comm, info), pv...)`.
Throws an informative error if the loaded HDF5 libraries do not include parallel
support.

See the [HDF5 docs](https://portal.hdfgroup.org/display/HDF5/H5P_SET_FAPL_MPIO)
for details on the `comm` and `info` arguments.
"""
function HDF5.h5open(
        filename::AbstractString, mode::AbstractString,
        comm::MPI.Comm, info::MPI.Info = MPI.Info(); pv...
    )
    HDF5.h5open(filename, mode; driver=MPIO(comm, info), pv...)
end

HDF5.h5open(filename::AbstractString, comm::MPI.Comm, args...; pv...) =
    HDF5.h5open(filename, "r", comm, args...; pv...)
