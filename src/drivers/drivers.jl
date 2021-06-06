module Drivers

export POSIX

import ..API
import ..HDF5: HDF5, Properties, h5doc

using Requires: @require


const DRIVERS = Dict{API.hid_t, Any}()

function get_driver(p::Properties)
    driver_id = API.h5p_get_driver(p)
    D = get(DRIVERS, driver_id) do
        error("Unknown driver type")
    end
    get_driver(p, D)
end

abstract type Driver end


"""
    POSIX()

Also referred to as SEC2, this driver uses POSIX file-system functions like read and
write to perform I/O to a single, permanent file on local disk with no system
buffering. This driver is POSIX-compliant and is the default file driver for all systems.
"""
struct POSIX <: Driver
end

DRIVERS[API.H5FD_SEC2] = POSIX

function get_driver(p::Properties, ::Type{POSIX})
    POSIX()
end

function set_driver!(p::Properties, ::POSIX)
    API.h5p_set_fapl_sec2(p)
end

function __init__()
    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" @eval include("mpio.jl")
end

end # module
