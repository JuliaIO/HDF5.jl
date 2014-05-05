using HDF5
using JLD

# Define variables of different types
x = 3.7
A = rand(1:20, 3, 5)
str = "Hello"
stringsA = ASCIIString["It", "was", "a", "dark", "and", "stormy", "night"]
stringsU = UTF8String["It", "was", "a", "dark", "and", "stormy", "night"]
empty_string = ""
empty_string_array = ASCIIString[]
empty_array_of_strings = ASCIIString[""]
tf = true
TF = A .> 10
B = randn(2, 4)
AB = Any[A, B]
t = (3, "cat")
c = float32(3)+float32(7)im
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
@write fid str
@write fid stringsA
@write fid stringsU
@write fid empty_string
@write fid empty_string_array
@write fid empty_array_of_strings
@write fid tf
@write fid TF
@write fid AB
@write fid t
@write fid c
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
@write fid cpus
@write fid rng
@write fid typevar
@write fid typevar_lb
@write fid typevar_ub
@write fid typevar_lb_ub
@write fid undef
@write fid undefs
@write fid ms_undef
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
    @check fidr str
    @check fidr stringsA
    @check fidr stringsU
    @check fidr empty_string
    @check fidr empty_string_array
    @check fidr empty_array_of_strings
    @check fidr tf
    @check fidr TF
    @check fidr AB
    @check fidr t
    @check fidr c
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

# #71
jldopen(fn, "w") do file
    file["a"] = 1
end
jldopen(fn, "r") do file
    @assert read(file, "a") == 1
end
