using .MPI
import Libdl
import HDF5: h5open

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

"""
    MPIO(comm::MPI.Comm, info::MPI.Info)
    MPIO(comm::MPI.Comm; kwargs....)

The parallel MPI file driver. This requires the use of
[MPI.jl](https://github.com/JuliaParallel/MPI.jl), and a custom HDF5 binary that has been
built with MPI support.

- `comm` is the communicator over which the file will be opened.
- `info`/`kwargs` are MPI-IO options, and are passed to `MPI_FILE_OPEN`.

# See also

- [`HDF5.has_parallel`](@ref)
- [Parallel HDF5](@ref)

# External links

- $(h5doc("H5P_SET_FAPL_MPIO"))
- [Parallel HDF5](https://portal.hdfgroup.org/display/HDF5/Parallel+HDF5)
"""
struct MPIO <: Driver
    comm::MPI.Comm
    info::MPI.Info
end
MPIO(comm::MPI.Comm; kwargs...) = MPIO(comm, MPI.Info(; kwargs...))

function set_driver!(fapl::Properties, mpio::MPIO)
    HDF5.has_parallel() || error(
        "HDF5.jl has no parallel support." *
        " Make sure that you're using MPI-enabled HDF5 libraries, and that" *
        " MPI was loaded before HDF5." *
        " See HDF5.jl docs for details."
    )
    # Note: HDF5 creates a COPY of the comm and info objects, so we don't need to keep a reference around.
    API.h5p_set_fapl_mpio(fapl, mpio.comm, mpio.info)
    DRIVERS[API.h5p_get_driver(fapl)] = MPIO
    return nothing
end

function get_driver(fapl::Properties, ::Type{MPIO})
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
function h5open(
    filename::AbstractString,
    mode::AbstractString,
    comm::MPI.Comm,
    info::MPI.Info=MPI.Info();
    pv...
)
    h5open(filename, mode; driver=MPIO(comm, info), pv...)
end

h5open(filename::AbstractString, comm::MPI.Comm, args...; pv...) =
    h5open(filename, "r", comm, args...; pv...)
