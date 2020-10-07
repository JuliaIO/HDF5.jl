using HDF5
using Test
using Pkg

println("HDF5 version ", HDF5.h5_get_libversion())

# Copied over from JuliaLang/Test
"""
The `GenericString` can be used to test generic string APIs that program to
the `AbstractString` interface, in order to ensure that functions can work
with string types besides the standard `String` type.
"""
struct GenericString <: AbstractString
    string::AbstractString
end
Base.ncodeunits(s::GenericString) = ncodeunits(s.string)::Int
Base.codeunit(s::GenericString) = codeunit(s.string)::Type{<:Union{UInt8,UInt16,UInt32}}
Base.codeunit(s::GenericString, i::Integer) = codeunit(s.string, i)::Union{UInt8,UInt16,UInt32}
Base.isvalid(s::GenericString, i::Integer) = isvalid(s.string, i)::Bool
Base.iterate(s::GenericString, i::Integer=1) = iterate(s.string, i)::Union{Nothing,Tuple{AbstractChar,Int}}
Base.reverse(s::GenericString) = GenericString(reverse(s.string))
Base.reverse(s::SubString{GenericString}) = GenericString(typeof(s.string)(reverse(String(s))))

include("plain.jl")
include("compound.jl")
include("custom.jl")
include("reference.jl")
include("hyperslab.jl")
include("readremote.jl")
include("extend_test.jl")
include("gc.jl")
include("external.jl")
include("swmr.jl")
include("mmap.jl")
include("properties.jl")

try
    using MPI
    # basic MPI tests, for actual parallel tests we need to run in MPI mode
    include("mpio.jl")
catch
end
