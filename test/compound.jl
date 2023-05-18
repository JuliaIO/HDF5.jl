using Random, Test, HDF5

import HDF5.datatype
import Base.convert
import Base.unsafe_convert

struct foo
    a::Float64
    b::String
    c::String
    d::Array{ComplexF64,2}
    e::Array{Int64,1}
end

struct foo_hdf5
    a::Float64
    b::Cstring
    c::NTuple{20,UInt8}
    d::NTuple{9,ComplexF64}
    e::HDF5.API.hvl_t
end

function unsafe_convert(::Type{foo_hdf5}, x::foo)
    foo_hdf5(
        x.a,
        Base.unsafe_convert(Cstring, x.b),
        ntuple(i -> i <= ncodeunits(x.c) ? codeunit(x.c, i) : '\0', 20),
        ntuple(i -> x.d[i], length(x.d)),
        HDF5.API.hvl_t(length(x.e), pointer(x.e))
    )
end

function datatype(::Type{foo_hdf5})
    dtype = HDF5.API.h5t_create(HDF5.API.H5T_COMPOUND, sizeof(foo_hdf5))
    HDF5.API.h5t_insert(dtype, "a", fieldoffset(foo_hdf5, 1), datatype(Float64))

    vlenstr_dtype = HDF5.API.h5t_copy(HDF5.API.H5T_C_S1)
    HDF5.API.h5t_set_size(vlenstr_dtype, HDF5.API.H5T_VARIABLE)
    HDF5.API.h5t_set_cset(vlenstr_dtype, HDF5.API.H5T_CSET_UTF8)
    HDF5.API.h5t_insert(dtype, "b", fieldoffset(foo_hdf5, 2), vlenstr_dtype)

    fixedstr_dtype = HDF5.API.h5t_copy(HDF5.API.H5T_C_S1)
    HDF5.API.h5t_set_size(fixedstr_dtype, 20 * sizeof(UInt8))
    HDF5.API.h5t_set_cset(fixedstr_dtype, HDF5.API.H5T_CSET_UTF8)
    HDF5.API.h5t_set_strpad(fixedstr_dtype, HDF5.API.H5T_STR_NULLPAD)
    HDF5.API.h5t_insert(dtype, "c", fieldoffset(foo_hdf5, 3), fixedstr_dtype)

    hsz = HDF5.API.hsize_t[3, 3]
    array_dtype = HDF5.API.h5t_array_create(datatype(ComplexF64), 2, hsz)
    HDF5.API.h5t_insert(dtype, "d", fieldoffset(foo_hdf5, 4), array_dtype)

    vlen_dtype = HDF5.API.h5t_vlen_create(datatype(Int64))
    HDF5.API.h5t_insert(dtype, "e", fieldoffset(foo_hdf5, 5), vlen_dtype)

    HDF5.Datatype(dtype)
end

struct bar
    a::Vector{String}
end

struct bar_hdf5
    a::NTuple{2,NTuple{20,UInt8}}
end

function datatype(::Type{bar_hdf5})
    dtype = HDF5.API.h5t_create(HDF5.API.H5T_COMPOUND, sizeof(bar_hdf5))

    fixedstr_dtype = HDF5.API.h5t_copy(HDF5.API.H5T_C_S1)
    HDF5.API.h5t_set_size(fixedstr_dtype, 20 * sizeof(UInt8))
    HDF5.API.h5t_set_cset(fixedstr_dtype, HDF5.API.H5T_CSET_UTF8)

    hsz = HDF5.API.hsize_t[2]
    array_dtype = HDF5.API.h5t_array_create(fixedstr_dtype, 1, hsz)

    HDF5.API.h5t_insert(dtype, "a", fieldoffset(bar_hdf5, 1), array_dtype)

    HDF5.Datatype(dtype)
end

function convert(::Type{bar_hdf5}, x::bar)
    bar_hdf5(
        ntuple(
            i -> ntuple(j -> j <= ncodeunits(x.a[i]) ? codeunit(x.a[i], j) : '\0', 20), 2
        )
    )
end

@testset "compound" begin
    N = 10
    v = [
        foo(
            rand(),
            randstring(rand(10:100)),
            randstring(10),
            rand(ComplexF64, 3, 3),
            rand(1:10, rand(10:100))
        ) for _ in 1:N
    ]

    v[1] = foo(1.0, "uniçº∂e", "uniçº∂e", rand(ComplexF64, 3, 3), rand(1:10, rand(10:100)))

    v_write = unsafe_convert.(foo_hdf5, v)

    w = [bar(["uniçº∂e", "hello"])]
    w_write = convert.(bar_hdf5, w)

    fn = tempname()
    h5open(fn, "w") do h5f
        foo_dtype = datatype(foo_hdf5)
        foo_space = dataspace(v_write)
        foo_dset = create_dataset(h5f, "foo", foo_dtype, foo_space)
        write_dataset(foo_dset, foo_dtype, v_write)

        bar_dtype = datatype(bar_hdf5)
        bar_space = dataspace(w_write)
        bar_dset = create_dataset(h5f, "bar", bar_dtype, bar_space)
        write_dataset(bar_dset, bar_dtype, w_write)
    end

    v_read = h5read(fn, "foo")
    for field in (:a, :b, :c, :d, :e)
        f = x -> getfield(x, field)
        @test f.(v) == f.(v_read)
    end

    w_read = h5read(fn, "bar")
    for field in (:a,)
        f = x -> getfield(x, field)
        @test f.(w) == f.(w_read)
    end

    T = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,Cstring}}
    TT = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,T}}
    TTT = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,TT}}
    TTTT = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,TTT}}

    @test HDF5.do_reclaim(TTTT) == true
    @test HDF5.do_normalize(TTTT) == true

    T = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,HDF5.FixedArray}}
    TT = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,T}}
    TTT = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,TT}}
    TTTT = NamedTuple{(:a, :b, :c, :d, :e, :f),Tuple{Int,Int,Int,Int,Int,TTT}}

    @test HDF5.do_reclaim(TTTT) == false
    @test HDF5.do_normalize(TTTT) == true
end

struct Bar
    a::Int32
    b::Float64
    c::Bool
end

mutable struct MutableBar
    x::Int64
end

@testset "create_dataset (compound)" begin
    bars = [Bar(1, 2, true), Bar(3, 4, false), Bar(5, 6, true), Bar(7, 8, false)]
    fn = tempname()
    h5open(fn, "w") do h5f
        d = create_dataset(h5f, "the/bars", Bar, ((2,), (-1,)); chunk=(100,))
        d[1:2] = bars[1:2]
    end

    h5open(fn, "cw") do h5f
        d = h5f["the/bars"]
        HDF5.set_extent_dims(d, (4,))
        d[3:4] = bars[3:4]
    end

    thebars = h5open(fn, "r") do h5f
        read(h5f, "the/bars")
    end

    @test 4 == length(thebars)
    @test 1 == thebars[1].a
    @test true == thebars[3].c
    @test 8 == thebars[4].b
end

@testset "write_compound" begin
    bars = [
        [Bar(1, 1.1, true) Bar(2, 2.1, false) Bar(3, 3.1, true)]
        [Bar(4, 4.1, false) Bar(5, 5.1, true) Bar(6, 6.1, false)]
    ]

    namedtuples = [(a=1, b=2.3), (a=4, b=5.6)]

    tuples = [(1, namedtuples[1], (0.1,)), (2, namedtuples[2], (1.0,))]

    fn = tempname()
    h5open(fn, "w") do h5f
        write_dataset(h5f, "the/bars", bars)
        write_dataset(h5f, "the/namedtuples", namedtuples)
        write_dataset(h5f, "the/tuples", tuples)
    end

    thebars = h5open(fn, "r") do h5f
        read(h5f, "the/bars")
    end

    @test (2, 3) == size(thebars)
    @test thebars[1, 2].b ≈ 2.1
    @test thebars[2, 1].a == 4
    @test thebars[1, 3].c

    thebars_r = reinterpret(Bar, thebars)
    @test (2, 3) == size(thebars_r)
    @test thebars_r[1, 2].b ≈ 2.1
    @test thebars_r[2, 1].a == 4
    @test thebars_r[1, 3].c

    thenamedtuples = h5open(fn, "r") do h5f
        read(h5f, "the/namedtuples")
    end

    @test (2,) == size(thenamedtuples)
    @test thenamedtuples[1].a == 1
    @test thenamedtuples[1].b ≈ 2.3
    @test thenamedtuples[2].a == 4
    @test thenamedtuples[2].b ≈ 5.6

    thetuples = h5open(fn, "r") do h5f
        read(h5f, "the/tuples")
    end

    @test (2,) == size(thetuples)
    @test thetuples[1][1] == 1
    @test thetuples[1][2].a == 1
    @test thetuples[1][2].b ≈ 2.3
    @test thetuples[1][3][1] ≈ 0.1
    @test thetuples[2][1] == 2
    @test thetuples[2][2].a == 4
    @test thetuples[2][2].b ≈ 5.6
    @test thetuples[2][3][1] ≈ 1.0

    mutable_bars = [MutableBar(1), MutableBar(2), MutableBar(3)]

    fn = tempname()
    @test_throws ArgumentError begin
        h5open(fn, "w") do h5f
            write_dataset(h5f, "the/mutable_bars", mutable_bars)
        end
    end

    Base.convert(::Type{NamedTuple{(:x,),Tuple{Int64}}}, mb::MutableBar) = (x=mb.x,)
    Base.unsafe_convert(::Type{Ptr{Nothing}}, mb::MutableBar) = pointer_from_objref(mb)

    h5open(fn, "w") do h5f
        write_dataset(h5f, "the/mutable_bars", mutable_bars)
        write_dataset(h5f, "the/mutable_bar", first(mutable_bars))
    end

    h5open(fn, "r") do h5f
        @test [1, 2, 3] == [b.x for b in read(h5f, "the/mutable_bars")]
        @test 1 == read(h5f, "the/mutable_bar").x
    end

    h5open(fn, "w") do h5f
        write_attribute(h5f, "mutable_bars", mutable_bars)
        write_attribute(h5f, "mutable_bar", first(mutable_bars))
    end

    h5open(fn, "r") do h5f
        @test [1, 2, 3] == [b.x for b in attrs(h5f)["mutable_bars"]]
        @test 1 == attrs(h5f)["mutable_bar"].x
    end
end
