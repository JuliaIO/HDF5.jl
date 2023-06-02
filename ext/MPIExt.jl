module MPIExt

isdefined(Base, :get_extension) ? (using MPI) : (using ..MPI)
import Libdl
using HDF5: HDF5, API, Drivers, Drivers.Driver, Properties, h5doc, h5open

###
### MPIO
###

# define API functions here
function API.h5p_set_fapl_mpio(fapl_id, comm, info)
    API.lock(API.liblock)
    var"#status#" = try
        ccall(
            (:H5Pset_fapl_mpio, API.libhdf5),
            API.herr_t,
            (API.hid_t, MPI.MPI_Comm, MPI.MPI_Info),
            fapl_id,
            comm,
            info
        )
    finally
        API.unlock(API.liblock)
    end
    var"#status#" < 0 && API.@h5error("Error setting MPIO properties")
    return nothing
end

function API.h5p_get_fapl_mpio(fapl_id, comm, info)
    API.lock(API.liblock)
    var"#status#" = try
        ccall(
            (:H5Pget_fapl_mpio, API.libhdf5),
            API.herr_t,
            (API.hid_t, Ptr{MPI.MPI_Comm}, Ptr{MPI.MPI_Info}),
            fapl_id,
            comm,
            info
        )
    finally
        API.unlock(API.liblock)
    end
    var"#status#" < 0 && API.@h5error("Error getting MPIO properties")
    return nothing
end

# The docstring for `MPIO` is included in the function `MPIO` in
# src/drivers/drivers.jl.
struct MPIO <: Driver
    comm::MPI.Comm
    info::MPI.Info
end
Drivers.MPIO(comm::MPI.Comm, info::MPI.Info) = MPIO(comm, info)
Drivers.MPIO(comm::MPI.Comm; kwargs...) = MPIO(comm, MPI.Info(; kwargs...))

function Drivers.set_driver!(fapl::Properties, mpio::MPIO)
    HDF5.has_parallel() || error(
        "HDF5.jl has no parallel support." *
        " Make sure that you're using MPI-enabled HDF5 libraries, and that" *
        " MPI was loaded before HDF5." *
        " See HDF5.jl docs for details."
    )
    # Note: HDF5 creates a COPY of the comm and info objects, so we don't need to keep a reference around.
    API.h5p_set_fapl_mpio(fapl, mpio.comm, mpio.info)
    Drivers.DRIVERS[API.h5p_get_driver(fapl)] = MPIO
    return nothing
end

function Drivers.get_driver(fapl::Properties, ::Type{MPIO})
    comm = MPI.Comm()
    info = MPI.Info()
    API.h5p_get_fapl_mpio(fapl, comm, info)
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
    filename::AbstractString,
    mode::AbstractString,
    comm::MPI.Comm,
    info::MPI.Info=MPI.Info();
    pv...
)
    HDF5.h5open(filename, mode; driver=MPIO(comm, info), pv...)
end

HDF5.h5open(filename::AbstractString, comm::MPI.Comm, args...; pv...) =
    HDF5.h5open(filename, "r", comm, args...; pv...)

end
