using HDF5
using JLD
using Base.Test

# Define variables of different types
x = 3.7
A = reshape(1:15, 3, 5)
Aarray = Vector{Float64}[[1.2,1.3],[2.2,2.3,2.4]]
str = "Hello"
stringsA = ASCIIString["It", "was", "a", "dark", "and", "stormy", "night"]
stringsU = UTF8String["It", "was", "a", "dark", "and", "stormy", "night"]
if VERSION >= v"0.3-"
    strings16 = convert(Array{UTF16String}, stringsA)
    strings16_2d = reshape(strings16[1:6], (2,3))
end
empty_string = ""
empty_string_array = ASCIIString[]
empty_array_of_strings = ASCIIString[""]
tf = true
TF = A .> 10
B = [-1.5 sqrt(2) NaN 6;
     0.0  Inf eps() -Inf]
AB = Any[A, B]
t = (3, "cat")
c = float32(3)+float32(7)im
cint = 1+im  # issue 108
C = reinterpret(Complex128, B, (4,))
emptyA = zeros(0,2)
emptyB = zeros(2,0)
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
msempty = MyStruct(5, Float64[])
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
α = 22
β = Any[[1, 2], [3, 4]]  # issue #93
vv = Vector{Int}[[1,2,3]]  # issue #123
typevar = Array{Int}[[1]]
typevar_lb = Vector{TypeVar(:U, Integer)}[[1]]
typevar_ub = Vector{TypeVar(:U, Int, Any)}[[1]]
typevar_lb_ub = Vector{TypeVar(:U, Int, Real)}[[1]]
undef = cell(1)
undefs = cell(2, 2)
ms_undef = MyStruct(0)
# Unexported type:
cpus = Base.Sys.cpu_info()
# Immutable type:
rng = 1:5
# Type with a pointer field (#84)
objwithpointer = big(10)^10000
# Custom BitsType (#99)
bitstype 64 MyBT
bt = reinterpret(MyBT, 55)
# Symbol arrays (#100)
sa_asc = [:a, :b]
sa_utf8 = [:α, :β]
# SubArray (to test tuple type params)
subarray = sub([1:5], 1:5)
# Array of empty tuples (to test tuple type params)
arr_empty_tuple = ()[]
immutable EmptyType
end
emptytype = EmptyType()
# Unicode type field names (#118)
type MyUnicodeStruct☺{τ}
    α::τ
    ∂ₓα::τ
    MyUnicodeStruct☺(α::τ, ∂ₓα::τ) = new(α, ∂ₓα)
end
unicodestruct☺ = MyUnicodeStruct☺{Float64}(1.0, -1.0)
# Arrays of matrices (#131)
array_of_matrices = Matrix{Int}[[1 2; 3 4], [5 6; 7 8]]


iseq(x,y) = isequal(x,y)
iseq(x::MyStruct, y::MyStruct) = (x.len == y.len && x.data == y.data)
iseq(c1::Array{Base.Sys.CPUinfo}, c2::Array{Base.Sys.CPUinfo}) = length(c1) == length(c2) && all([iseq(c1[i], c2[i]) for i = 1:length(c1)])
function iseq(c1::Base.Sys.CPUinfo, c2::Base.Sys.CPUinfo)
    for n in Base.Sys.CPUinfo.names
        if getfield(c1, n) != getfield(c2, n)
            return false
        end
    end
    true
end
iseq(x::MyUnicodeStruct☺, y::MyUnicodeStruct☺) = (x.α == y.α && x.∂ₓα == y.∂ₓα)
macro check(fid, sym)
    ex = quote
        let tmp
            try
                tmp = read($fid, $(string(sym)))
            catch e
                warn("Error reading ", $(string(sym)))
                rethrow(e)
            end
            if !iseq(tmp, $sym)
                error("For ", $(string(sym)), ", read value does not agree with written value")
            end
            written_type = typeof($sym)
            if typeof(tmp) != written_type
                error("For ", $(string(sym)), ", read type $(typeof(tmp)) does not agree with written type $(written_type)")
            end
        end
    end
    esc(ex)
end

# Test for equality of expressions, skipping line numbers
checkexpr(a, b) = @assert a == b
function checkexpr(a::Expr, b::Expr)
    @assert a.head == b.head
    i = 1
    j = 1
    while i <= length(a.args) && j <= length(b.args)
        if isa(a.args[i], Expr) && a.args[i].head == :line
            i += 1
            continue
        end
        if isa(b.args[j], Expr) && b.args[j].head == :line
            j += 1
            continue
        end
        checkexpr(a.args[i], b.args[j])
        i += 1
        j += 1
    end
    @assert i >= length(a.args) && j >= length(b.args)
end

fn = joinpath(tempdir(),"test.jld")

fid = jldopen(fn, "w")
@write fid x
@write fid A
@write fid Aarray
@write fid str
@write fid stringsA
@write fid stringsU
if VERSION >= v"0.3-"
    @write fid strings16
    @write fid strings16_2d
end
@write fid empty_string
@write fid empty_string_array
@write fid empty_array_of_strings
@write fid tf
@write fid TF
@write fid AB
@write fid t
@write fid c
@write fid cint
@write fid C
@write fid emptyA
@write fid emptyB
@write fid ms
@write fid msempty
@write fid sym
@write fid syms
@write fid d
@write fid ex
@write fid T
@write fid char
@write fid unicode_char
@write fid α
@write fid β
@write fid vv
@write fid cpus
@write fid rng
@write fid typevar
@write fid typevar_lb
@write fid typevar_ub
@write fid typevar_lb_ub
@write fid undef
@write fid undefs
@write fid ms_undef
@write fid objwithpointer  # This should not write anything
@write fid bt
@write fid sa_asc
@write fid sa_utf8
@write fid subarray
@write fid arr_empty_tuple
@write fid emptytype
@write fid unicodestruct☺
@write fid array_of_matrices
# Make sure we can create groups (i.e., use HDF5 features)
g = g_create(fid, "mygroup")
i = 7
@write g i
write(fid, "group1/x", {1})
write(fid, "group2/x", {2})
close(fid)

for mmap = (true, false)
    fidr = jldopen(fn, "r", mmaparrays=mmap)
    @check fidr x
    @check fidr A
    @check fidr Aarray
    @check fidr str
    @check fidr stringsA
    @check fidr stringsU
    if VERSION >= v"0.3-"
        @check fidr strings16
        @check fidr strings16_2d
    end
    @check fidr empty_string
    @check fidr empty_string_array
    @check fidr empty_array_of_strings
    @check fidr tf
    @check fidr TF
    @check fidr AB
    @check fidr t
    @check fidr c
    @check fidr cint
    @check fidr C
    @check fidr emptyA
    @check fidr emptyB
    @check fidr ms
    @check fidr msempty
    @check fidr sym
    @check fidr syms
    @check fidr d
    exr = read(fidr, "ex")   # line numbers are stripped, don't expect equality
    checkexpr(ex, exr)
    @check fidr T
    @check fidr char
    @check fidr unicode_char
    @check fidr α
    @check fidr β
    @check fidr vv
    @check fidr cpus
    @check fidr rng
    @check fidr typevar
    @check fidr typevar_lb
    @check fidr typevar_ub
    @check fidr typevar_lb_ub

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
    
    @assert !in("objwithpointer", names(fidr))
    @check fidr bt
    @check fidr sa_asc
    @check fidr sa_utf8
    @check fidr subarray
    @check fidr arr_empty_tuple
    @check fidr emptytype
    @check fidr unicodestruct☺
    @check fidr array_of_matrices
    
    x1 = read(fidr, "group1/x")
    @assert x1 == {1}
    x2 = read(fidr, "group2/x")
    @assert x2 == {2}

    close(fidr)
end

# do syntax
jldopen(fn, "w") do fid
    g_create(fid, "mygroup") do g
        write(g, "x", 3.2)
    end
end
fid = jldopen(fn, "r")
@assert names(fid) == ASCIIString["mygroup"]
g = fid["mygroup"]
@assert names(g) == ASCIIString["x"]
@assert read(g, "x") == 3.2
close(g)
close(fid)

# Function load() and save() syntax
d = ["x"=>3.2, "β"=>β, "A"=>A]
save(fn, d)
d2 = load(fn)
@assert d == d2
β2 = load(fn, "β")
@assert β == β2
β2, A2 = load(fn, "β", "A")
@assert β == β2
@assert A == A2

save(fn, "x", 3.2, "β", β, "A", A)
d3 = load(fn)
@assert d == d3

# Test reference semantics
v = Array(Vector{Int},0)
arr = [1,2,3]
push!(v, arr)
push!(v, arr)
@assert v[1] === v[2]
save(fn, "v", v)
v2 = load(fn,"v")
@assert v2[1] === v2[2]
v2[1][1] = 2
@assert v2[2] == [2,2,3]

# #71
jldopen(fn, "w") do file
    file["a"] = 1
end
jldopen(fn, "r") do file
    @assert read(file, "a") == 1
end

# Issue #106
module Mod106
bitstype 64 Typ{T}
typ{T}(x::Int, ::Type{T}) = Base.box(Typ{T}, Base.unbox(Int,x))
abstract UnexportedT
end
save(fn, "i106", Mod106.typ(1, Mod106.UnexportedT))
i106 = load(fn, "i106")
@assert i106 == Mod106.typ(1, Mod106.UnexportedT)

# bracket syntax for datasets
jldopen(fn, "w") do file
    file["a"] = [1:100]
    file["b"] = [x*y for x=1:10,y=1:10]
end
jldopen(fn, "r") do file
    @assert(file["a"][1:50] == [1:50])
    @assert(file["b"][5,6][1]==5*6)
end

# bracket syntax when created by HDF5
h5open(fn, "w") do file
    file["a"] = [1:100]
    file["a"][51:100] = [1:50]
    file["b"] = [x*y for x=1:10,y=1:10]
end
jldopen(fn, "r") do file
    @assert(file["a"][1:50] == [1:50])
    @assert(file["a"][:] == [[1:50],[1:50]])
    @assert(file["b"][5,6][1]==5*6)
end

# delete!
jldopen(fn, "w") do file
    file["ms"] = ms
    delete!(file, "ms")
    file["ms"] = β
    g = g_create(file,"g")
    file["g/ms"] = ms
    @test_throws_02 ErrorException delete!(file, "_refs/g/ms")
    delete!(file, "g/ms")
    file["g/ms"] = ms
    delete!(file, "/g/ms")
    g["ms"] = ms
    delete!(g,"ms")
    g["ms"] = ms
    delete!(g["ms"])
    g["ms"] = ms
    delete!(g)
    g = g_create(file,"g")
    g["ms"] = ms
    delete!(g)
end
jldopen(fn, "r") do file
    @assert(read(file["ms"]) == β)
    @assert(!exists(file, "g/ms"))
    @assert(!exists(file, "g"))
end
