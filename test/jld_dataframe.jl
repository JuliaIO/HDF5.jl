using HDF5
using JLD
using Base.Test

if Pkg.installed("DataFrames") != nothing
    using DataFrames

    filename = joinpath(tempdir(), "mydata.jld")

    df = DataFrame({[2:6], pi*[1:5]})
#     df2 = @DataFrame(a => [1:5], b => pi * [1:5])

    file = jldopen(filename, "w")
    write(file, "df", df)
#     write(file, "df2", df2)
    close(file)

    file = jldopen(filename, "r")
    x = read(file, "df")
#     y = read(file, "df2")
    close(file)

    @test all(df .== x)
#     @test all(df2 .== y)
end
