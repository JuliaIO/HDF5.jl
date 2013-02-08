using HDF5
using JLD

# Define variables of different types
x = 3.7
A = rand(1:20, 3, 5)
str = "Hello"
stringsA = ASCIIString["It", "was", "a", "dark", "and", "stormy", "night"]
stringsU = UTF8String["It", "was", "a", "dark", "and", "stormy", "night"]
tf = true
TF = A .> 10
B = randn(2, 4)
AB = Any[A, B]
t = (3, "cat")
c = float32(3)+float32(7)im
C = reinterpret(Complex128, B, (4,))
try
    global MyStruct
    type MyStruct
        len::Int
        data::Array{Float64}
    end
catch
end
ms = MyStruct(2, [3.2, -1.7])
sym = :TestSymbol
syms = [:a, :b]
d = Dict(syms, ["aardvark", "banana"])
ex = quote
    function incrementby1(x::Int)
        x+1
    end
end
T = Uint8

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

fn = joinpath(tempdir(),"test.jld")

fid = jldopen(fn, "w")
@write fid x
@write fid A
@write fid str
@write fid stringsA
@write fid stringsU
@write fid tf
@write fid TF
@write fid AB
@write fid t
@write fid c
@write fid C
@write fid ms
@write fid sym
@write fid syms
@write fid d
@write fid ex
@write fid T
# Make sure we can create groups (i.e., use HDF5 features)
g = g_create(fid, "mygroup")
i = 7
@write g i
close(fid)

fidr = jldopen(fn, "r")
@check fidr x
@check fidr A
@check fidr str
@check fidr stringsA
@check fidr stringsU
@check fidr tf
@check fidr TF
@check fidr AB
@check fidr t
@check fidr c
@check fidr C
@check fidr ms
@check fidr sym
@check fidr syms
@check fidr d
exr = read(fidr, "ex")   # line numbers are stripped, don't expect equality
@check fidr T
close(fidr)
