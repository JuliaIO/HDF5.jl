using HDF5
using JLD
import DataFrames

fname = joinpath(tempdir(), "mydata.jld")

df =  DataFrames.DataFrame(Any[[2:6;], pi*[1:5;]])
df2 = DataFrames.DataFrame(a = [1:5;], b = pi * [1:5;])

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

# Testing issue #236
fname = joinpath(tempdir(), "int_str_data.jld")
df3 = DataFrames.DataFrame(A = [1:4;], B = ["M", "F", "F", "M"])
file = jldopen(fname, "w")
write(file, "df3", df3)
close(file)
file = jldopen(fname, "r")
iob = IOBuffer()
dump(iob, file)
x = read(file, "df3")
@test isequal(df3, x)
