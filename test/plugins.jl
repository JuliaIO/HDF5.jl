import HDF5.API

@testset "plugins" begin
    state = API.h5pl_get_loading_state()
    @test state != API.H5PL_TYPE_ERROR
    @test API.h5pl_set_loading_state(state) === nothing
    tmp = mktempdir()
    @test API.h5pl_append(tmp) === nothing
    @test API.h5pl_get(1) == tmp
    tmp = mktempdir()
    @test API.h5pl_prepend(tmp) === nothing
    @test API.h5pl_get(0) == tmp
    tmp = mktempdir()
    @test API.h5pl_replace(tmp, 1) === nothing
    @test API.h5pl_get(1) == tmp
    tmp = mktempdir()
    @test API.h5pl_insert(tmp, 1) === nothing
    @test API.h5pl_get(1) == tmp
    @test API.h5pl_remove(1) === nothing
    @test API.h5pl_size() == 3
end
