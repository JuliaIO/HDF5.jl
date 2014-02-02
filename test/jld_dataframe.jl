using HDF5
using JLD
using DataFrames

fname = joinpath(tempdir(), "mydata.jld")

df = DataFrame({[2:6], pi*[1:5]})
df2 = DataFrame(a = [1:5], b = pi * [1:5])

file = jldopen(fname, "w")
write(file, "df", df)
write(file, "df2", df2)
close(file)

file = jldopen(fname, "r")
x = read(file, "df")
y = read(file, "df2")
close(file)

using Base.Test
@test isequal(df, x)
@test isequal(df2, y)
