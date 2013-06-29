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
        MyStruct(len::Int) = new(len)
        MyStruct(len::Int, data::Array{Float64}) = new(len, data)
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
char = 'x'
unicode_char = '\U10ffff'
undef = cell(1)
undefs = cell(2, 2)
ms_undef = MyStruct(0)

iseq(x,y) = isequal(x,y)
iseq(x::MyStruct, y::MyStruct) = (x.len == y.len && x.data == y.data)
macro check(fid, sym)
    ex = quote
        let tmp
            try
                tmp = read($fid, $(string(sym)))
            catch
                error("Error reading ", $(string(sym)))
            end
            if !iseq(tmp, $sym)
                error("For ", $(string(sym)), ", read value does not agree with written value")
            end
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
@write fid char
@write fid unicode_char
@write fid undef
@write fid undefs
@write fid ms_undef
# Make sure we can create groups (i.e., use HDF5 features)
g = g_create(fid, "mygroup")
i = 7
@write g i
close(fid)

for mmap = (true, false)
    fidr = jldopen(fn, "r", mmaparrays=mmap)
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
    @check fidr char
    @check fidr unicode_char

    # Special cases for reading undefs
    undef = read(fidr, "undef")
    if !isa(undef, Array{Any, 1}) || length(undef) != 1 || isdefined(undef, 1)
        error("For undef, read value does not agree with written value")
    end
    undefs = read(fidr, "undefs")
    if !isa(undefs, Array{Any, 2}) || length(undefs) != 4 || any(map(i->isdefined(undefs, i), 1:4))
        error("For undefs, read value does not agree with written value")
    end
    ms_undef = read(fidr, "ms_undef")
    if !isa(ms_undef, MyStruct) || ms_undef.len != 0 || isdefined(ms_undef, :data)
        error("For ms_undef, read value does not agree with written value")
    end

    close(fidr)
end