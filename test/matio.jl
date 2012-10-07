load("matio.jl")
import MatIO.*
fid = matopen("/tmp/matwrite.mat","w")
A = randi(20, 3, 5)
B = randn(2, 4)
AB = Any[A, B]
write(fid, "AB", AB)
close(fid)
