using .MPI

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

hdf5_prop_get_set["fapl_mpio"] =
    (h5p_get_fapl_mpio, h5p_set_fapl_mpio, H5P_FILE_ACCESS)

hdf5_prop_get_set["dxpl_mpio"] =
    (h5p_get_dxpl_mpio, h5p_set_dxpl_mpio, H5P_DATASET_XFER)
