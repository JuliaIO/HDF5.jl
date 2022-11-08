using HDF5
if VERSION >= v"1.6"
    using Preferences
end
using Test

@testset "API Lock Preference" begin
    prev_use_api_lock = HDF5.API.get_use_api_lock()
    @test prev_use_api_lock isa Bool
    @static if VERSION >= v"1.6"
        HDF5.API.set_use_api_lock!(true)
        @test load_preference(HDF5, "use_api_lock") == true
        HDF5.API.set_use_api_lock!(false)
        @test load_preference(HDF5, "use_api_lock") == false
        HDF5.API.set_use_api_lock!(prev_use_api_lock)
        @test load_preference(HDF5, "use_api_lock") == prev_use_api_lock
        delete_preferences!(HDF5, "use_api_lock"; force=true)
        @test load_preference(HDF5, "use_api_lock") === nothing
    else
        @test prev_use_api_lock
        @test_throws ErrorException HDF5.API.set_use_api_lock!(true)
    end
end
