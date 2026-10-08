using HDF5
using Test

@testset "ros3" begin
    @test HDF5.has_ros3()

    # Recent libhdf5 builds require an AWS region even for anonymous access, so
    # use the five-argument constructor (without authentication) to specify it.
    h5open(
        "http://s3.us-east-2.amazonaws.com/hdf5ros3/GMODO-SVM01.h5";
        driver=HDF5.Drivers.ROS3(1, false, "us-east-2", "", "")
    ) do f
        @test keys(f) == ["All_Data", "Data_Products"]
    end
end
