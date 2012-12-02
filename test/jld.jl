load("jld.jl")
using JLD

fid = jldopen("/tmp/test.jld","w")
write(fid, "x", 3.7)
A = randi(20, 3, 5)
write(fid, "A", A)
write(fid, "string", "Hello")
write(fid, "stringsA", ASCIIString["It", "was", "a", "dark", "and", "stormy", "night"])
write(fid, "stringsU", UTF8String["It", "was", "a", "dark", "and", "stormy", "night"])
B = randn(2, 4)
AB = Any[A, B]
write(fid, "AB", AB)
# ABreal = Array{Real}[A,B]
# write(fid, "ABreal", ABreal)
type MyStruct
    len::Int
    data::Array{Float64}
end
ms = MyStruct(2, [3.2, -1.7])
write(fid, "mystruct", ms)
close(fid)

fidr = jldopen("/tmp/test.jld","r")
@assert typeof(read(fidr, "x")) == Float64
@assert typeof(read(fidr, "A")) == Array{Int, 2}
@assert typeof(read(fidr, "string")) == ASCIIString
@assert typeof(read(fidr, "stringsA")) == Array{ASCIIString, 1}
@assert typeof(read(fidr, "stringsU")) == Array{UTF8String, 1}
ABr = read(fidr, "AB")
@assert ABr == AB
msr = read(fidr, "mystruct")
close(fidr)
