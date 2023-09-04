"""
    ROS3()
    ROS3(aws_region::String, secret_id::String, secret_key::String)
    ROS3(version::Int32, authenticate::Bool, aws_region::String, secret_id::String, secret_key::String)

This is the read-only virtual driver that enables access to HDF5 objects stored in AWS S3
"""
struct ROS3 <: Driver
    version::Int32
    authenticate::Bool
    aws_region::String
    secret_id::String
    secret_key::String
    function ROS3(version, authenticate, aws_region, secret_id, secret_key)
        length(aws_region) <= API.H5FD_ROS3_MAX_REGION_LEN ||
            "length(aws_region), $(length(aws_region)), must be less than or equal to $(API.H5FD_ROS3_MAX_REGION_LEN)"
        length(secret_id) <= API.H5FD_ROS3_MAX_SECRET_ID_LEN ||
            "length(secret_id), $(length(secret_id)), must be less than or equal to $(API.H5FD_ROS3_MAX_SECRET_ID_LEN)"
        length(secret_key) <= API.H5FD_ROS3_MAX_SECRET_KEY_LEN ||
            "length(secret_key), $(length(secret_key)), must be less than or equal to $(API.H5FD_ROS3_MAX_SECRET_KEY_LEN)"
        new(version, authenticate, aws_region, secret_id, secret_key)
    end
end

ROS3() = ROS3(1, false, "", "", "")

ROS3(region::AbstractString, id::AbstractString, key::AbstractString) =
    ROS3(1, true, region, id, key)

function ROS3(driver::API.H5FD_ros3_fapl_t)
    aws_region = _ntuple_to_string(driver.aws_region)
    secret_id = _ntuple_to_string(driver.secret_id)
    secret_key = _ntuple_to_string(driver.secret_key)
    ROS3(driver.version, driver.authenticate, aws_region, secret_id, secret_key)
end
_ntuple_to_string(x) = unsafe_string(Ptr{Cchar}(pointer_from_objref(Ref(x))), length(x))

function Base.convert(::Type{API.H5FD_ros3_fapl_t}, driver::ROS3)
    aws_region = ntuple(
        i -> i <= length(driver.aws_region) ? Cchar(driver.aws_region[i]) : Cchar(0x0),
        API.H5FD_ROS3_MAX_REGION_LEN + 1
    )
    secret_id = ntuple(
        i -> i <= length(driver.secret_id) ? Cchar(driver.secret_id[i]) : Cchar(0x0),
        API.H5FD_ROS3_MAX_SECRET_ID_LEN + 1
    )
    secret_key = ntuple(
        i -> i <= length(driver.secret_key) ? Cchar(driver.secret_key[i]) : Cchar(0x0),
        API.H5FD_ROS3_MAX_SECRET_KEY_LEN + 1
    )
    s = API.H5FD_ros3_fapl_t(
        driver.version, driver.authenticate, aws_region, secret_id, secret_key,
    )
end

function get_driver(fapl::Properties, ::Type{ROS3})
    r_fa = Ref{API.H5FD_ros3_fapl_t}()
    API.h5p_get_fapl_ros3(fapl, r_fa)
    return ROS3(r_fa[])
end

function set_driver!(fapl::Properties, driver::ROS3)
    HDF5.has_ros3() || error(
        "HDF5.jl has no ros3 support." *
        " Make sure that you're using ROS3-enabled HDF5 libraries"
    )
    HDF5.init!(fapl)
    API.h5p_set_fapl_ros3(fapl, Ref{API.H5FD_ros3_fapl_t}(driver))
    DRIVERS[API.h5p_get_driver(fapl)] = ROS3
    return nothing
end
