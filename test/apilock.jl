using Pkg, Test
@testset "issue1179" begin
    @test try
        run(`$(Base.julia_cmd()) --project=$(dirname(Pkg.project().path)) -t 6 $(joinpath(@__DIR__, "issue1179.jl"))`)
        true
    catch err
        @info err
        false
    end
end