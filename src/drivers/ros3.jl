"""
    ROS3()

This is the read-only virtual driver that enables access to HDF5 objects stored in AWS S3
"""
struct ROS3 <: Driver
    fa::API.H5FD_ros3_fapl_t
end

function ROS3(
    version::Integer,
    auth::Bool,
    region::AbstractString,
    id::AbstractString,
    key::AbstractString
)
    return (ROS3 ∘ API.H5FD_ros3_fapl_t)(
        version,
        auth,
        Base.unsafe_convert(Cstring, region),
        Base.unsafe_convert(Cstring, id),
        Base.unsafe_convert(Cstring, key)
    )
end

ROS3(region::AbstractString, id::AbstractString, key::AbstractString) =
    ROS3(1, true, region, id, key)
ROS3() = ROS3(1, false, "", "", "")

function get_driver(fapl::Properties, ::Type{ROS3})
    r_fa = Ref{H5FD_ros3_fapl_t}()
    API.h5p_get_fapl_ros(fapl, r_fa)
    return ROS3(r_fa[])
end

function set_driver!(fapl::Properties, driver::ROS3)
    HDF5.has_ros3() || error(
        "HDF5.jl has no ros3 support." *
        " Make sure that you're using ROS3-enabled HDF5 libraries"
    )
    HDF5.init!(fapl)
    API.h5p_set_fapl_ros(fapl, Ref(driver.fa))
    DRIVERS[API.h5p_get_driver(fapl)] = ROS3
    return nothing
end
