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
    Core([increment::Csize_t, backing_store::Cuint, [write_tracking::Cuint, page_size::Csize_t]])
    Core(; increment::Csize_t = 8192, backing_store::Cuint = true, write_tracking::Cuint = false, page_size::Csize_t = 524288)

# Arguments

* `increment`: specifies the increment by which allocated memory is to be increased each time more memory is required. (default: 8192)
* `backing_store`: Boolean flag indicating whether to write the file contents to disk when the file is closed. (default: false)
* `write_tracking`: Boolean flag indicating whether write tracking is enabled. (default: false)
* `page_size`: Size, in bytes, of write aggregation pages. (default: 524288)
"""
struct Core <: Driver
    increment::Csize_t
    backing_store::Cuint #Bool
    write_tracking::Cuint #Bool
    page_size::Csize_t
end
Core(increment, backing_store) = Core(increment, backing_store, false, 524288)
Core(;
    increment = 8192,
    backing_store = true,
    write_tracking = false,
    page_size = 524288
) = Core(increment, backing_store, write_tracking, page_size)

function get_driver(p::Properties, ::Type{Core})
    r_increment = Ref{Csize_t}(0)
    r_backing_store = Ref{Cuint}(0)
    r_write_tracking = Ref{Cuint}(0)
    r_page_size = Ref{Csize_t}(0)
    API.h5p_get_fapl_core(p, r_increment, r_backing_store)
    API.h5p_get_core_write_tracking(p, r_write_tracking, r_page_size)
    return Core(
        r_increment[],
        r_backing_store[],
        r_write_tracking[],
        r_page_size[]
    )
end

function set_driver!(p::Properties, driver::Core)
    API.h5p_set_fapl_core(p, driver.increment, driver.backing_store)
    API.h5p_set_core_write_tracking(p, driver.write_tracking, driver.page_size)
    return nothing
end

"""
    POSIX()

Also referred to as SEC2, this driver uses POSIX file-system functions like read and
write to perform I/O to a single, permanent file on local disk with no system
buffering. This driver is POSIX-compliant and is the default file driver for all systems.
"""
struct POSIX <: Driver
end

function get_driver(p::Properties, ::Type{POSIX})
    POSIX()
end

function set_driver!(p::Properties, ::POSIX)
    API.h5p_set_fapl_sec2(p)
end

function __init__()
    DRIVERS[API.h5fd_core_init()] = Core
    DRIVERS[API.h5fd_sec2_init()] = POSIX
    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" include("mpio.jl")
end

end # module
