"""
    HDF5Error

An error thrown by libhdf5.
"""
mutable struct HDF5Error <: Exception
    msg::String
    id::hid_t
end


Base.cconvert(::Type{hid_t}, err::HDF5Error) = err
Base.unsafe_convert(::Type{hid_t}, err::HDF5Error) = err.id

function Base.close(err::HDF5Error)
    if err.id != -1 && isvalid(err)
        h5e_close_stack(err)
        err.id = -1
    end
    return nothing
end
Base.isvalid(err::HDF5Error) = err.id != -1 && h5i_is_valid(err)

Base.length(err::HDF5Error) = h5e_get_num(err)
Base.isempty(err::HDF5Error) = length(err) == 0

function HDF5Error(msg::AbstractString)
    id = h5e_get_current_stack()
    err = HDF5Error(msg,id)
    finalizer(close, err)
    return err
end

const SHORT_ERROR = Ref(true)

function Base.showerror(io::IO, err::HDF5Error)
    n_total = length(err)
    print(io, "HDF5Error: ", err.msg)
    print(io, "\nLibrary stacktrace:")
    h5e_walk(err, H5E_WALK_UPWARD) do n, errptr
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
        major = h5e_get_msg(errval.maj_num)[2]
        minor = h5e_get_msg(errval.min_num)[2]
        print(io, major, "/", minor)
        if errval.desc != C_NULL
            print(io, "\n    ", unsafe_string(errval.desc))
        end
        if SHORT_ERROR[] && n == 1 && n_total > 2
            print(io, "\n      ...")
        end
    end
    return nothing
end
