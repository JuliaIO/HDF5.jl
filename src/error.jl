"""
    H5Error

An error thrown by libhdf5.
"""
mutable struct H5Error <: Exception
    msg::String
    id::API.hid_t
end


Base.cconvert(::Type{API.hid_t}, err::H5Error) = err
Base.unsafe_convert(::Type{API.hid_t}, err::H5Error) = err.id

function Base.close(err::H5Error)
    if err.id != -1 && isvalid(err)
        API.h5e_close_stack(err)
        err.id = -1
    end
    return nothing
end
Base.isvalid(err::H5Error) = err.id != -1 && API.h5i_is_valid(err)

Base.length(err::H5Error) = API.h5e_get_num(err)
Base.isempty(err::H5Error) = length(err) == 0

function H5Error(msg::AbstractString)
    id = API.h5e_get_current_stack()
    err = H5Error(msg, id)
    finalizer(close, err)
    return err
end

const SHORT_ERROR = Ref(true)

function Base.showerror(io::IO, err::H5Error)
    n_total = length(err)
    print(io, "H5Error: ", err.msg)
    print(io, "\nlibhdf5 Stacktrace:")
    API.h5e_walk(err, H5E_WALK_UPWARD) do n, errptr
        n += 1
        if SHORT_ERROR[] && 1 < n < n_total
            return nothing
        end
        errval = unsafe_load(errptr)
        print(io, "\n", lpad("[$n] ", 4 + ndigits(n_total)))
        if errval.func_name != C_NULL
            printstyled(io, unsafe_string(errval.func_name); bold=true)
            print(io, ": ")
        end
        major = API.h5e_get_msg(errval.maj_num)[2]
        minor = API.h5e_get_msg(errval.min_num)[2]
        print(io, major, "/", minor)
        if errval.desc != C_NULL
            printstyled(io, "\n", " "^(4 + ndigits(n_total)), unsafe_string(errval.desc), color=:light_black)
        end
        if SHORT_ERROR[] && n == 1 && n_total > 2
            print(io, "\n", lpad("⋮", 2 + ndigits(n_total)))
        end
    end
    return nothing
end
