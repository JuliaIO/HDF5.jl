# Create a type that encodes array dimensions as parameters.
# This is an intermediate needed to encode the H5T_ARRAY types.
# The data are eventually read as plain Arrays.

abstract FixedArray{T,N} <: AbstractArray{T,N}

import Base.size

function fixedarray_definetype(N::Int)
    sz = [symbol(string("n", i)) for i = 1:N]
    typename = symbol(string("FixedArray", N))
    extype = Expr(:curly, typename, :T, sz...)
    excreate = Expr(:type, false, Expr(:<:, extype, :(FixedArray{T, $N})), quote end)
end

const fixedarray_isdefined = [false]
const fixedarray_dict = Dict{(DataType,Dims),DataType}()
function fixedarray_type(T::DataType, sz::Dims)
    t = (T,sz)
    if haskey(fixedarray_dict, t)
        return fixedarray_dict[t]
    end
    N = length(sz)
    if N > length(fixedarray_isdefined)
        append!(fixedarray_isdefined, falses(N-length(fixedarray_isdefined)))
    end
    if !fixedarray_isdefined[N]
        eval(fixedarray_definetype(N))
        fixedarray_isdefined[N] = true
    end
    typename = symbol(string("FixedArray", N))
    ret = eval(Expr(:curly, typename, T, sz...))
    fixedarray_dict[t] = ret
    ret
end

size{T<:FixedArray}(::Type{T}) = T.parameters[2:end]
