using HDF5
using JLD
using Compat
using Base.Test

# Define variables of different types
x = 3.7
A = reshape(1:15, 3, 5)
Aarray = Vector{Float64}[[1.2,1.3],[2.2,2.3,2.4]]
str = "Hello"
stringsA = ASCIIString["It", "was", "a", "dark", "and", "stormy", "night"]
stringsU = UTF8String["It", "was", "a", "dark", "and", "stormy", "night"]
strings16 = convert(Array{UTF16String}, stringsA)
strings16_2d = reshape(strings16[1:6], (2,3))
empty_string = ""
empty_string_array = ASCIIString[]
empty_array_of_strings = ASCIIString[""]
tf = true
TF = A .> 10
B = [-1.5 sqrt(2) NaN 6;
     0.0  Inf eps() -Inf]
AB = Any[A, B]
t = (3, "cat")
c = Complex64(3,7)
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
d = Dict([(syms[1],"aardvark"), (syms[2], "banana")])
ex = quote
    function incrementby1(x::Int)
        x+1
    end
end
T = UInt8
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
immutable ObjWithPointer
    a::Ptr{Void}
end
objwithpointer = ObjWithPointer(0)
# Custom BitsType (#99)
bitstype 64 MyBT
bt = reinterpret(MyBT, @compat Int64(55))
# Symbol arrays (#100)
sa_asc = [:a, :b]
sa_utf8 = [:α, :β]
# SubArray (to test tuple type params)
subarray = sub([1:5;], 1:5)
# Array of empty tuples (to test tuple type params)
arr_empty_tuple = (@compat Tuple{})[]
immutable EmptyImmutable end
emptyimmutable = EmptyImmutable()
arr_emptyimmutable = [emptyimmutable]
type EmptyType end
emptytype = EmptyType()
arr_emptytype = [emptytype]
immutable EmptyII
    x::EmptyImmutable
end
emptyii = EmptyII(EmptyImmutable())
immutable EmptyIT
    x::EmptyType
end
emptyit = EmptyIT(EmptyType())
type EmptyTI
    x::EmptyImmutable
end
emptyti = EmptyTI(EmptyImmutable())
type EmptyTT
    x::EmptyType
end
emptytt = EmptyTT(EmptyType())
immutable EmptyIIOtherField
    x::EmptyImmutable
    y::Float64
end
emptyiiotherfield = EmptyIIOtherField(EmptyImmutable(), 5.0)

# Unicode type field names (#118)
type MyUnicodeStruct☺{τ}
    α::τ
    ∂ₓα::τ
    MyUnicodeStruct☺(α::τ, ∂ₓα::τ) = new(α, ∂ₓα)
end
unicodestruct☺ = MyUnicodeStruct☺{Float64}(1.0, -1.0)
# Arrays of matrices (#131)
array_of_matrices = Matrix{Int}[[1 2; 3 4], [5 6; 7 8]]
# Tuple of arrays and bitstype
tup = (1, 2, [1, 2], [1 2; 3 4], bt)
# Empty tuple
empty_tup = ()
# Non-pointer-free immutable
immutable MyImmutable{T}
    x::Int
    y::Vector{T}
    z::Bool
end
nonpointerfree_immutable_1 = MyImmutable(1, [1., 2., 3.], false)
nonpointerfree_immutable_2 = MyImmutable(2, Any[3., 4., 5.], true)
immutable MyImmutable2
    x::Vector{Int}
    MyImmutable2() = new()
end
nonpointerfree_immutable_3 = MyImmutable2()
# Immutable with a non-concrete datatype (issue #143)
immutable Vague
    name::ByteString
end
vague = Vague("foo")
# Immutable with a union of BitsTypes
immutable BitsUnion
    x::Union(Int64, Float64)
end
bitsunion = BitsUnion(5.0)
# Immutable with a union of Types
immutable TypeUnionField
    x::Union(Type{Int64}, Type{Float64})
end
typeunionfield = TypeUnionField(Int64)
# Generic union type field
immutable GenericUnionField
    x::Union(Vector{Int},Int)
end
genericunionfield = GenericUnionField(1)
# Array references
arr_contained = [1, 2, 3]
arr_ref = typeof(arr_contained)[]
push!(arr_ref, arr_contained, arr_contained)
# Object references
type ObjRefType
    x::ObjRefType
    y::ObjRefType
    ObjRefType() = new()
    ObjRefType(x, y) = new(x, y)
end
ref1 = ObjRefType()
obj_ref = ObjRefType(ObjRefType(ref1, ref1), ObjRefType(ref1, ref1))
# Immutable that requires padding between elements in array
immutable PaddingTest
    x::Int64
    y::Int8
end
padding_test = PaddingTest[PaddingTest(i, i) for i = 1:8]
# Empty arrays of various types and sizes
empty_arr_1 = Int[]
empty_arr_2 = Array(Int, 56, 0)
empty_arr_3 = Any[]
empty_arr_4 = cell(0, 97)
# Moderately big dataset (which will be mmapped)
bigdata = [1:10000;]
# BigFloats and BigInts
bigints = big(3).^(1:100)
bigfloats = big(3.2).^(1:100)
# None
none = Union()
nonearr = Array(Union(), 5)
# nothing/Void
scalar_nothing = nothing
vector_nothing = Union(Int,Nothing)[1,nothing]

# some data big enough to ensure that compression is used:
Abig = kron(eye(10), rand(20,20))
Bbig = Any[i for i=1:3000]
Sbig = "A test string "^1000

# Bitstype type parameters
type BitsParams{x}; end
bitsparamfloat  = BitsParams{1.0}()
bitsparambool   = BitsParams{true}()
bitsparamsymbol = BitsParams{:x}()
bitsparamint    = BitsParams{1}()
bitsparamuint   = BitsParams{0x01}()
bitsparamint16  = BitsParams{@compat Int16(1)}()

# Tuple of tuples
tuple_of_tuples = (1, 2, (3, 4, [5, 6]), [7, 8])

# SimpleVector
if VERSION >= v"0.4.0-dev+4319"
    simplevec = Base.svec(1, 2, Int64, "foo")
    iseq(x::SimpleVector, y::SimpleVector) = collect(x) == collect(y)
end

# Issue #243
# Type that overloads != so that it is not boolean
type NALikeType; end
Base.(:(!=))(::NALikeType, ::NALikeType) = NALikeType()
Base.(:(!=))(::NALikeType, ::Nothing) = NALikeType()
Base.(:(!=))(::Nothing, ::NALikeType) = NALikeType()
natyperef = Any[NALikeType(), NALikeType()]

iseq(x,y) = isequal(x,y)
iseq(x::MyStruct, y::MyStruct) = (x.len == y.len && x.data == y.data)
iseq(x::MyImmutable, y::MyImmutable) = (isequal(x.x, y.x) && isequal(x.y, y.y) && isequal(x.z, y.z))
iseq(x::Union(EmptyTI, EmptyTT), y::Union(EmptyTI, EmptyTT)) = isequal(x.x, y.x)
iseq(c1::Array{Base.Sys.CPUinfo}, c2::Array{Base.Sys.CPUinfo}) = length(c1) == length(c2) && all([iseq(c1[i], c2[i]) for i = 1:length(c1)])
function iseq(c1::Base.Sys.CPUinfo, c2::Base.Sys.CPUinfo)
    for n in fieldnames(Base.Sys.CPUinfo)
        if getfield(c1, n) != getfield(c2, n)
            return false
        end
    end
    true
end
iseq(x::MyUnicodeStruct☺, y::MyUnicodeStruct☺) = (x.α == y.α && x.∂ₓα == y.∂ₓα)
iseq(x::Array{None}, y::Array{None}) = size(x) == size(y)
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
                written = $sym
                error("For ", $(string(sym)), ", read value $tmp does not agree with written value $written")
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

# Issue #106
module Mod106
bitstype 64 Typ{T}
typ{T}(x::Int64, ::Type{T}) = Base.box(Typ{T}, Base.unbox(Int64,x))
abstract UnexportedT
end


# test mmapping of small arrays (Issue #192)
fid = jldopen(fn, "w", mmaparrays = true)
write(fid, "a", [1:3;])
@test ismmappable(fid["a"])
close(fid)
rm(fn)

fid = jldopen(fn, "w", mmaparrays=false)
write(fid, "a", [1:3;]; mmap = true)
@test ismmappable(fid["a"])
close(fid)
rm(fn)

fid = jldopen(fn, "w", compress = true)
write(fid, "a", [1:3;])
@test ismmappable(fid["a"]) == false
close(fid)
rm(fn)

 
for compress in (true,false)
    fid = jldopen(fn, "w", compress=compress)
    @write fid x
    @write fid A
    @write fid Aarray
    @write fid str
    @write fid stringsA
    @write fid stringsU
    @write fid strings16
    @write fid strings16_2d
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
    @test_throws JLD.PointerException @write fid objwithpointer
    @write fid bt
    @write fid sa_asc
    @write fid sa_utf8
    @write fid subarray
    @write fid arr_empty_tuple
    @write fid emptyimmutable
    @write fid emptytype
    @write fid arr_emptyimmutable
    @write fid arr_emptytype
    @write fid emptyii
    @write fid emptyit
    @write fid emptyti
    @write fid emptytt
    @write fid emptyiiotherfield
    @write fid unicodestruct☺
    @write fid array_of_matrices
    @write fid tup
    @write fid empty_tup
    @write fid nonpointerfree_immutable_1
    @write fid nonpointerfree_immutable_2
    @write fid nonpointerfree_immutable_3
    @write fid vague
    @write fid bitsunion
    @write fid typeunionfield
    @write fid genericunionfield
    @write fid arr_ref
    @write fid obj_ref
    @write fid padding_test
    @write fid empty_arr_1
    @write fid empty_arr_2
    @write fid empty_arr_3
    @write fid empty_arr_4
    @write fid bigdata
    @write fid bigfloats
    @write fid bigints
    @write fid none
    @write fid nonearr
    @write fid scalar_nothing
    @write fid vector_nothing
    @write fid Abig
    @write fid Bbig
    @write fid Sbig
    @test_throws ErrorException @write fid bitsparamint16
    @write fid bitsparamfloat
    @write fid bitsparambool
    @write fid bitsparamsymbol
    @write fid bitsparamint
    @write fid bitsparamuint
    @write fid tuple_of_tuples
    VERSION >= v"0.4.0-dev+4319" && @write fid simplevec
    @write fid natyperef

    # Make sure we can create groups (i.e., use HDF5 features)
    g = g_create(fid, "mygroup")
    i = 7
    @write g i
    write(fid, "group1/x", Any[1])
    write(fid, "group2/x", Any[2])
    close(fid)

    # mmapping currently fails on Windows; re-enable once it can work
    for mmap = (@windows ? false : (false, true))
        fidr = jldopen(fn, "r", mmaparrays=mmap)
        @check fidr x
        @check fidr A
        dsetA = fidr["A"]
        @test ndims(dsetA) == ndims(A)
        @test size(dsetA) == size(A)
        @test size(dsetA, 1) == size(A, 1)
        @test size(dsetA, 2) == size(A, 2)
        @test size(dsetA, 3) == size(A, 3)
        @check fidr Aarray
        @check fidr str
        @check fidr stringsA
        @check fidr stringsU
        @check fidr strings16
        @check fidr strings16_2d
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
        
        @check fidr bt
        @check fidr sa_asc
        @check fidr sa_utf8
        @check fidr subarray
        @check fidr arr_empty_tuple
        @check fidr emptyimmutable
        @check fidr emptytype
        @check fidr arr_emptyimmutable
        @check fidr arr_emptytype
        @check fidr emptyii
        @check fidr emptyit
        @check fidr emptyti
        @check fidr emptytt
        @check fidr emptyiiotherfield
        @check fidr unicodestruct☺
        @check fidr array_of_matrices
        @check fidr tup
        @check fidr empty_tup
        @check fidr nonpointerfree_immutable_1
        @check fidr nonpointerfree_immutable_2
        @check fidr nonpointerfree_immutable_3
        vaguer = read(fidr, "vague")
        @test typeof(vaguer) == typeof(vague) && vaguer.name == vague.name
        @check fidr bitsunion
        @check fidr typeunionfield
        @check fidr genericunionfield
        
        arr = read(fidr, "arr_ref")
        @test arr == arr_ref
        @test arr[1] === arr[2]
        
        obj = read(fidr, "obj_ref")
        @test obj.x.x === obj.x.y == obj.y.x === obj.y.y
        @test obj.x !== obj.y
        
        @check fidr padding_test
        @check fidr empty_arr_1
        @check fidr empty_arr_2
        @check fidr empty_arr_3
        @check fidr empty_arr_4
        @check fidr bigdata
        @check fidr bigfloats
        @check fidr bigints
        @check fidr none
        @check fidr nonearr
        @check fidr scalar_nothing
        @check fidr vector_nothing
        @check fidr Abig
        @check fidr Bbig
        @check fidr Sbig
        @check fidr bitsparamfloat
        @check fidr bitsparambool
        @check fidr bitsparamsymbol
        @check fidr bitsparamint
        @check fidr bitsparamuint
        @check fidr tuple_of_tuples
        VERSION >= v"0.4.0-dev+4319" && @check fidr simplevec
        @check fidr natyperef
        
        x1 = read(fidr, "group1/x")
        @assert x1 == Any[1]
        x2 = read(fidr, "group2/x")
        @assert x2 == Any[2]
        
        close(fidr)
    end
end # compress in (true,false)

for compress in (false,true)
    # object references in a write session
    x = ObjRefType()
    a = [x, x]
    b = [x, x]
    @save fn a b
    jldopen(fn, "r") do fid
        a = read(fid, "a")
        b = read(fid, "b")
        @test a[1] === a[2] === b[2] === a[1]
        
        # Let gc get rid of a and b
        a = nothing
        b = nothing
        gc()
        
        a = read(fid, "a")
        b = read(fid, "b")
        @test typeof(a[1]) == ObjRefType
        @test a[1] === a[2] === b[2] === a[1]
    end
    
    # do syntax
    jldopen(fn, "w"; compress=compress) do fid
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
    d = Dict([("x",3.2), ("β",β), ("A",A)])
    save(fn, d, compress=compress)
    d2 = load(fn)
    @assert d == d2
    β2 = load(fn, "β")
    @assert β == β2
    β2, A2 = load(fn, "β", "A")
    @assert β == β2
    @assert A == A2
    
    save(fn, "x", 3.2, "β", β, "A", A, compress=compress)
    d3 = load(fn)
    @assert d == d3
    
    # #71
    jldopen(fn, "w", compress=compress) do file
        file["a"] = 1
    end
    jldopen(fn, "r") do file
        @assert read(file, "a") == 1
    end
    
    # Issue #106
    save(fn, "i106", Mod106.typ(@compat(Int64(1)), Mod106.UnexportedT), compress=compress)
    i106 = load(fn, "i106")
    @assert i106 == Mod106.typ(@compat(Int64(1)), Mod106.UnexportedT)
    
    # bracket syntax for datasets
    jldopen(fn, "w", compress=compress) do file
        file["a"] = [1:100;]
        file["b"] = [x*y for x=1:10,y=1:10]
        file["c"] = Any[1, 2, 3]
        file["d"] = [1//2, 1//4, 1//8]
    end
    jldopen(fn, "r+", compress=compress) do file
        @test(file["a"][1:50] == [1:50;])
        file["a"][1:50] = 1:2:100
        @test(file["a"][1:50] == [1:2:100;])
        @test(file["b"][5,6][1]==5*6)
        @test(file["c"][1:2] == [1, 2])
        file["c"][2:3] = [5, 7]
        @test(read(file, "c") == [1, 5, 7])
        @test(file["d"][2:3] == [1//4, 1//8])
        file["d"][1:1] = [9]
        @test(read(file, "d") == [9, 1//4, 1//8])
    end
    
    # bracket syntax when created by HDF5
    println("The following unrecognized JLD file warning is a sign of normal operation.")
    if compress
        h5open(fn, "w") do file
            file["a", "blosc",5] = [1:100;]
            file["a"][51:100] = [1:50;]
            file["b", "blosc",5] = [x*y for x=1:10,y=1:10]
        end
    else
        h5open(fn, "w") do file
            file["a"] = [1:100;]
            file["a"][51:100] = [1:50;]
            file["b"] = [x*y for x=1:10,y=1:10]
        end
    end
    jldopen(fn, "r") do file
        @assert(file["a"][1:50] == [1:50;])
        @assert(file["a"][:] == [1:50;1:50])
        @assert(file["b"][5,6][1]==5*6)
    end
    
    # delete!
    jldopen(fn, "w", compress=compress) do file
        file["ms"] = ms
        delete!(file, "ms")
        file["ms"] = β
        g = g_create(file,"g")
        file["g/ms"] = ms
        @test_throws ErrorException delete!(file, "_refs/g/ms")
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

end # compress in (false,true)

# mismatched and missing types
module JLDTemp1
using JLD
import ..fn, Core.Intrinsics.box

type TestType1
    x::Int
end
type TestType2
    x::Int
end
immutable TestType3
    x::TestType2
end

type TestType4
    x::Int
end
type TestType5
    x::TestType4
end
type TestType6 end
bitstype 8 TestType7
immutable TestType8
    a::TestType4
    b::TestType5
    c::TestType6
    d::TestType7
end

jldopen(fn, "w") do file
    truncate_module_path(file, JLDTemp1)
    write(file, "x1", TestType1(1))
    write(file, "x2", TestType3(TestType2(1)))
    write(file, "x3", TestType4(1))
    write(file, "x4", TestType5(TestType4(2)))
    write(file, "x5", [TestType5(TestType4(i)) for i = 1:5])
    write(file, "x6", TestType6())
    write(file, "x7", reinterpret(TestType7, 0x77))
    write(file, "x8", TestType8(TestType4(2), TestType5(TestType4(3)),
                                TestType6(), reinterpret(TestType7, 0x12)))
    write(file, "x9", (TestType4(1),
                       (TestType5(TestType4(2)),
                        [TestType5(TestType4(i)) for i = 1:5]),
                       TestType6()))
end
end

type TestType1
    x::Float64
end
type TestType2
    x::Int
end
immutable TestType3
    x::TestType1
end

import Core.Intrinsics.box, Core.Intrinsics.unbox
jldopen(fn, "r") do file
    @test_throws JLD.TypeMismatchException read(file, "x1")
    @test_throws MethodError read(file, "x2")
    println("The following missing type warnings are a sign of normal operation.")
    @test read(file, "x3").x == 1
    @test read(file, "x4").x.x == 2

    x = read(file, "x5")
    for i = 1:5
        @test x[i].x.x == i
    end
    @test isempty(fieldnames(typeof(read(file, "x6"))))
    @test reinterpret(UInt8, read(file, "x7")) == 0x77

    x = read(file, "x8")
    @test x.a.x == 2
    @test x.b.x.x == 3
    @test isempty(fieldnames(typeof(x.c)))
    @test reinterpret(UInt8, x.d) == 0x12

    x = read(file, "x9")
    @test isa(x, Tuple)
    @test length(x) == 3
    @test x[1].x == 1
    @test isa(x[2], Tuple)
    @test length(x[2]) == 2
    @test x[2][1].x.x == 2
    for i = 1:5
        @test x[2][2][i].x.x == i
    end
    @test isempty(fieldnames(typeof(x[3])))
end

# Issue #176
exx = quote
    function incrementby1(x::Int)
        x+1
    end
end
for i = 1:2
    fid = jldopen(fn, "w")
    @write fid exx
    close(fid)
end

# Issue #226
t1 = mtime(fn)
sleep(3)
jldopen(fn, "r") do file
end
t2 = mtime(fn)
@test t2 == t1
