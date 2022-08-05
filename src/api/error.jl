# An error thrown by libhdf5
mutable struct H5Error <: Exception
    msg::String
    id::hid_t
end

macro h5error(msg)
    # Check if the is actually any errors on the stack. This is necessary as there are a
    # small number of functions which return `0` in case of an error, but `0` is also a
    # valid return value, e.g. `h5t_get_member_offset`

    # This needs to be a macro as we need to call `h5e_get_current_stack()` _before_
    # evaluating the message expression, as some message expressions can call API
    # functions, which would clear the error stack.
    quote
        err_id = h5e_get_current_stack()
        if h5e_get_num(err_id) > 0
            throw(H5Error($(esc(msg)), err_id))
        else
            h5e_close_stack(err_id)
        end
    end
end

Base.cconvert(::Type{hid_t}, err::H5Error) = err
Base.unsafe_convert(::Type{hid_t}, err::H5Error) = err.id

function Base.close(err::H5Error)
    if err.id != -1 && isvalid(err)
        h5e_close_stack(err)
        err.id = -1
    end
    return nothing
end
Base.isvalid(err::H5Error) = err.id != -1 && h5i_is_valid(err)

Base.length(err::H5Error) = h5e_get_num(err)
Base.isempty(err::H5Error) = length(err) == 0

function H5Error(msg::AbstractString)
    id = h5e_get_current_stack()
    err = H5Error(msg, id)
    finalizer(close, err)
    return err
end

const SHORT_ERROR = Ref(true)

function Base.showerror(io::IO, err::H5Error)
    n_total = length(err)
    print(io, "$(typeof(err)): ", err.msg)
    print(io, "\nlibhdf5 Stacktrace:")
    h5e_walk(err, H5E_WALK_UPWARD) do n, errptr
        n += 1 # 1-based indexing
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
            printstyled(
                io,
                "\n",
                " "^(4 + ndigits(n_total)),
                unsafe_string(errval.desc);
                color=:light_black
            )
        end
        if SHORT_ERROR[]
            if n_total > 1
                print(io, "\n", lpad("⋮", 2 + ndigits(n_total)))
            end
            return true # stop iterating
        end
        return false
    end
    return nothing
end
