module API

using Libdl: dlopen, dlclose, dlpath, dlsym, RTLD_LAZY, RTLD_NODELETE
using Base: StringVector
using Preferences: @load_preference, delete_preferences!, set_preferences!
using UUIDs: UUID

const _PREFERENCE_LIBHDF5 = @load_preference("libhdf5", nothing)
const _PREFERENCE_LIBHDF5_HL = @load_preference("libhdf5_hl", nothing)
if _PREFERENCE_LIBHDF5 === nothing && _PREFERENCE_LIBHDF5_HL === nothing
    using HDF5_jll
elseif _PREFERENCE_LIBHDF5 !== nothing && _PREFERENCE_LIBHDF5_HL === nothing
    error("You have only set a preference for the path of libhdf5, but not of libhdf5_hl.")
elseif _PREFERENCE_LIBHDF5 === nothing && _PREFERENCE_LIBHDF5_HL !== nothing
    error("You have only set a preference for the path of libhdf5_hl, but not of libhdf5.")
else
    libhdf5 = _PREFERENCE_LIBHDF5
    libhdf5_hl = _PREFERENCE_LIBHDF5_HL
    # Check whether we can open the libraries
    flags = RTLD_LAZY | RTLD_NODELETE
    dlopen(libhdf5, flags; throw_error=true)
    dlopen(libhdf5_hl, flags; throw_error=true)
    libhdf5_size = filesize(dlpath(libhdf5))
end

const HDF5_JL_UUID = UUID("f67ccb44-e63f-5c2f-98bd-6dc0ccc4ba2f")
const HDF5_JLL_JL_UUID = UUID("0234f1f7-429e-5d53-9886-15a909be8d59")

"""
    set_libraries!(libhdf5 = nothing, libhdf5_hl = nothing; force = true)

Convenience function to set the preferences for a system-provided HDF5 library.
Pass the paths pointing to the libraries `libhdf5` and `libhdf5_hl` as strings
to set the preference. If `libhdf5` and `libhdf5_hl` are `nothing` use the default,
i.e. the binaries provided by HDF5_jll.jl.
"""
function set_libraries!(libhdf5=nothing, libhdf5_hl=nothing; force=true)
    if isnothing(libhdf5) && isnothing(libhdf5_hl)
        delete_preferences!(HDF5_JL_UUID, "libhdf5"; force)
        delete_preferences!(HDF5_JL_UUID, "libhdf5_hl"; force)
        delete_preferences!(HDF5_JLL_JL_UUID, "libhdf5_path", "libhdf5_hl_path"; force)
        @info "The libraries from HDF5_jll will be used."
    elseif isnothing(libhdf5) || isnothing(libhdf5_hl)
        throw(
            ArgumentError(
                "Specify either no positional arguments or both positional arguments."
            )
        )
    else
        isfile(libhdf5) || throw(ArgumentError("$libhdf5 is not a file that exists."))
        isfile(libhdf5_hl) || throw(ArgumentError("$libhdf5_hl is not a file that exists."))
        set_preferences!(HDF5_JL_UUID, "libhdf5" => libhdf5; force)
        set_preferences!(HDF5_JL_UUID, "libhdf5_hl" => libhdf5_hl; force)
        # Also set the HDF5_jll override settings in case some other package tries to use HDF5_jll
        set_preferences!(
            HDF5_JLL_JL_UUID, "libhdf5_path" => libhdf5, "libhdf5_hl_path" => libhdf5_hl
        )
    end
    @info "Please restart Julia and reload HDF5.jl for the library changes to take effect"
end

include("lock.jl")
include("types.jl")
include("error.jl")
include("functions.jl") # core API ccall wrappers
include("helpers.jl")

function __init__()
    # HDF5.API.__init__() is run before HDF5.__init__()

    # Ensure this is reinitialized on using
    libhdf5handle[] = dlopen(libhdf5)

    # Warn if the environment is set and does not agree with Preferences.jl 
    if haskey(ENV, "JULIA_HDF5_PATH")
        if _PREFERENCE_LIBHDF5 === nothing
            @warn "The environment variable JULIA_HDF5_PATH is deprecated and ignored. Use Preferences.jl as detailed in the documentation." ENV["JULIA_HDF5_PATH"] _PREFERENCE_LIBHDF5
        elseif !startswith(_PREFERENCE_LIBHDF5, ENV["JULIA_HDF5_PATH"])
            @warn "The environment variable JULIA_HDF5_PATH is deprecated and does not agree with the Preferences.jl setting." ENV["JULIA_HDF5_PATH"] _PREFERENCE_LIBHDF5
        else
            @debug "The environment variable JULIA_HDF5_PATH is set and agrees with the Preferences.jl setting." ENV["JULIA_HDF5_PATH"] _PREFERENCE_LIBHDF5
        end
    end
    # Disable file locking as that can cause problems with mmap'ing.
    # File locking is disabled in HDF5.init!(::FileAccessPropertyList)
    # or here if h5p_set_file_locking is not available
    @static if !has_h5p_set_file_locking() && !haskey(ENV, "HDF5_USE_FILE_LOCKING")
        ENV["HDF5_USE_FILE_LOCKING"] = "FALSE"
    end

    # use our own error handling machinery (i.e. turn off automatic error printing)
    h5e_set_auto(API.H5E_DEFAULT, C_NULL, C_NULL)
end

end # module API
