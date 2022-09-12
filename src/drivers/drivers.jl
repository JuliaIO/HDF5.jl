module Drivers

export POSIX, ROS3

import ..API
import ..HDF5: HDF5, Properties, h5doc

using Libdl: dlopen, dlsym
using Requires: @require

function get_driver(p::Properties)
    driver_id = API.h5p_get_driver(p)
    D = get(DRIVERS, driver_id) do
        error("Unknown driver type")
    end
    get_driver(p, D)
end

abstract type Driver end

const DRIVERS = Dict{API.hid_t,Type{<:Driver}}()

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
Core(; increment=8192, backing_store=true, write_tracking=false, page_size=524288) =
    Core(increment, backing_store, write_tracking, page_size)

function get_driver(p::Properties, ::Type{Core})
    r_increment = Ref{Csize_t}(0)
    r_backing_store = Ref{Cuint}(0)
    r_write_tracking = Ref{Cuint}(0)
    r_page_size = Ref{Csize_t}(0)
    API.h5p_get_fapl_core(p, r_increment, r_backing_store)
    API.h5p_get_core_write_tracking(p, r_write_tracking, r_page_size)
    return Core(r_increment[], r_backing_store[], r_write_tracking[], r_page_size[])
end

function set_driver!(fapl::Properties, driver::Core)
    HDF5.init!(fapl)
    API.h5p_set_fapl_core(fapl, driver.increment, driver.backing_store)
    API.h5p_set_core_write_tracking(fapl, driver.write_tracking, driver.page_size)
    DRIVERS[API.h5p_get_driver(fapl)] = Core
    return nothing
end

"""
    POSIX()

Also referred to as SEC2, this driver uses POSIX file-system functions like read and
write to perform I/O to a single, permanent file on local disk with no system
buffering. This driver is POSIX-compliant and is the default file driver for all systems.
"""
struct POSIX <: Driver end

function get_driver(fapl::Properties, ::Type{POSIX})
    POSIX()
end

function set_driver!(fapl::Properties, ::POSIX)
    HDF5.init!(fapl)
    API.h5p_set_fapl_sec2(fapl)
    DRIVERS[API.h5p_get_driver(fapl)] = POSIX
    return nothing
end

"""
    ROS3()

This is the read-only virtual driver that enables access to HDF5 objects stored in AWS S3
"""
struct ROS3 <: Driver
    fa::API.H5FD_ros3_fapl_t
end
ROS3(
    version::Integer,
    auth::Bool,
    region::AbstractString,
    id::AbstractString,
    key::AbstractString
) = (ROS3 ∘ API.H5FD_ros3_fapl_t)(
    version,
    auth,
    Base.unsafe_convert(Cstring, region),
    Base.unsafe_convert(Cstring, id),
    Base.unsafe_convert(Cstring, key)
)
ROS3(region::AbstractString, id::AbstractString, key::AbstractString) =
    ROS3(1, true, region, id, key)
ROS3() = ROS3(1, false, "", "", "")

function get_driver(fapl::Properties, ::Type{ROS3})
    r_fa = Ref{H5FD_ros3_fapl_t}()
    API.h5p_get_fapl_ros(fapl, r_fa)
    return ROS3(r_fa[])
end

function set_driver!(fapl::Properties, driver::ROS3)
    HDF5.init!(fapl)
    API.h5p_set_fapl_ros(fapl, Ref(driver.fa))
    DRIVERS[API.h5p_get_driver(fapl)] = ROS3
    return nothing
end

function __init__()
    # Initialize POSIX,ROS3 keys in DRIVERS
    HDF5.FileAccessProperties() do fapl
        set_driver!(fapl, POSIX())
        set_driver!(fapl, ROS3())
    end

    # Check whether the libhdf5 was compiled with parallel support.
    HDF5.HAS_PARALLEL[] = API._has_symbol(:H5Pset_fapl_mpio)

    @require MPI = "da04e1cc-30fd-572f-bb4f-1f8673147195" (
        HDF5.has_parallel() && include("mpio.jl")
    )
end

end # module
