load("jld.jl")
using JLD

# Define variables of different types
x = 3.7
A = randi(20, 3, 5)
str = "Hello"
stringsA = ASCIIString["It", "was", "a", "dark", "and", "stormy", "night"]
stringsU = UTF8String["It", "was", "a", "dark", "and", "stormy", "night"]
tf = true
TF = A .> 10
B = randn(2, 4)
AB = Any[A, B]
c = float32(3)+float32(7)im
C = reinterpret(Complex128, B, (4,))
type MyStruct
    len::Int
    data::Array{Float64}
end
ms = MyStruct(2, [3.2, -1.7])

iseq(x,y) = isequal(x,y)
iseq(x::MyStruct, y::MyStruct) = (x.len == y.len && x.data == y.data)
macro check(fid, sym)
    ex = quote
        local tmp
        try
            tmp = read($fid, $(string(sym)))
        catch
            error("Error reading ", $(string(sym)))
        end
        if !iseq(tmp, $sym)
            error("For ", $(string(sym)), ", read value does not agree with written value")
        end
    end
    esc(ex)
end

fid = jldopen("/tmp/test.jld","w")
@write fid x
@write fid A
@write fid str
@write fid stringsA
@write fid stringsU
@write fid tf
@write fid TF
@write fid AB
@write fid c
@write fid C
@write fid ms
close(fid)

fidr = jldopen("/tmp/test.jld","r")
@check fidr x
@check fidr A
@check fidr str
@check fidr stringsA
@check fidr stringsU
@check fidr tf
@check fidr TF
@check fidr AB
@check fidr c
@check fidr C
@check fidr ms
close(fidr)
