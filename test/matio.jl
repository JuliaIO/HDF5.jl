load("matio.jl")
import MatIO.*
fid = matopen("/tmp/matwrite.mat","w")
A = randi(20, 3, 5)
B = randn(2, 4)
AB = Any[A, B]
write(fid, "AB", AB)
type MyStruct
    len::Int
    data::Array{Float64}
end
ms = MyStruct(2, [3.2, -1.7])
write(fid, "mystruct", ms)
close(fid)
