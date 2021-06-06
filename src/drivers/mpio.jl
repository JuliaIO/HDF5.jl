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

h5_to_mpi(handle::H5MPIHandle) = reinterpret(MPI.MPI_Comm, handle)

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
Libdl.dlopen(API.libhdf5) do lib
    if Libdl.dlsym(lib, :H5Pget_fapl_mpio, throw_error=false) !== nothing
        HDF5.HAS_PARALLEL[] = true
        H5FD_MPIO   = ccall((:H5FD_mpio_init, API.libhdf5), API.hid_t, ())
        DRIVERS[H5FD_MPIO] = MPIO
    end
end


function set_driver!(p::Properties, mpio::MPIO)
    # Note: HDF5 creates a COPY of the comm and info objects.
    GC.@preserve comm begin
        API.h5p_set_fapl_mpio(fapl, mpi_to_h5(comm), mpi_to_h5(info))
    end
end

function get_driver(p::Properties, ::Type{MPIO})
    h5comm, h5info = API.h5p_get_fapl_mpio(fapl, H5MPIHandle)
    comm = MPI.Comm(h5_to_mpi(h5comm))
    info = MPI.Info(h5_to_mpi(h5info))
    return MPIO(comm, info)
end



function check_hdf5_parallel()
    has_parallel() && return
    error(
        "HDF5.jl has no parallel support." *
        " Make sure that you're using MPI-enabled HDF5 libraries, and that" *
        " MPI was loaded before HDF5." *
        " See HDF5.jl docs for details."
    )
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
    check_hdf5_parallel()
    h5open(filename, mode; fapl_mpio=(comm, info), pv...)
end

HDF5.h5open(filename::AbstractString, comm::MPI.Comm, args...; pv...) =
    h5open(filename, "r", comm, args...; pv...)
