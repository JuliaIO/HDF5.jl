using .MPI
import Libdl

# Check whether the HDF5 libraries were compiled with parallel support.
HAS_PARALLEL[] = Libdl.dlopen(libhdf5) do lib
    Libdl.dlsym(lib, :H5Pget_fapl_mpio, throw_error=false) !== nothing
end

# Low-level MPI handles.
const MPIHandle = Union{MPI.MPI_Comm, MPI.MPI_Info}

# MPI.jl wrapper types.
const MPIHandleWrapper = Union{MPI.Comm, MPI.Info}

const H5MPIHandle = let csize = sizeof(MPI.MPI_Comm)
    @assert csize in (4, 8)
    csize == 4 ? Hmpih32 : Hmpih64
end

h5_to_mpi(handle::H5MPIHandle) = reinterpret(MPI.MPI_Comm, handle)

mpi_to_h5(handle::MPIHandle) = reinterpret(H5MPIHandle, handle)
mpi_to_h5(mpiobj::MPIHandleWrapper) = mpi_to_h5(mpiobj.val)

# Set MPIO properties in HDF5.
# Note: HDF5 creates a COPY of the comm and info objects.
function h5p_set_fapl_mpio(fapl_id, comm::MPI.Comm, info::MPI.Info)
    h5comm = mpi_to_h5(comm)
    h5info = mpi_to_h5(info)
    h5p_set_fapl_mpio(fapl_id, h5comm, h5info)
end

h5p_set_fapl_mpio(fapl_id, comm::Hmpih32, info::Hmpih32) =
    h5p_set_fapl_mpio32(fapl_id, comm, info)
h5p_set_fapl_mpio(fapl_id, comm::Hmpih64, info::Hmpih64) =
    h5p_set_fapl_mpio64(fapl_id, comm, info)

# Retrieves the copies of the comm and info MPIO objects from the HDF5 property list.
function h5p_get_fapl_mpio(fapl_id)
    h5comm, h5info = h5p_get_fapl_mpio(fapl_id, H5MPIHandle)
    comm = MPI.Comm(h5_to_mpi(h5comm))
    info = MPI.Info(h5_to_mpi(h5info))
    comm, info
end

function h5p_get_fapl_mpio(fapl_id, ::Type{h}) where {h}
    comm, info = Ref{h}(), Ref{h}()
    h5p_get_fapl_mpio(fapl_id, comm, info)
    comm[], info[]
end

h5p_get_fapl_mpio(fapl_id, comm::Ref{Hmpih32}, info::Ref{Hmpih32}) =
    h5p_get_fapl_mpio32(fapl_id, comm, info)
h5p_get_fapl_mpio(fapl_id, comm::Ref{Hmpih64}, info::Ref{Hmpih64}) =
    h5p_get_fapl_mpio64(fapl_id, comm, info)

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
function h5open(
        filename::AbstractString, mode::AbstractString,
        comm::MPI.Comm, info::MPI.Info = MPI.Info(); pv...
    )
    check_hdf5_parallel()
    h5open(filename, mode; fapl_mpio=(comm, info), pv...)
end

h5open(filename::AbstractString, comm::MPI.Comm, args...; pv...) =
    h5open(filename, "r", comm, args...; pv...)
