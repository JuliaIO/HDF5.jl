module API

using Libdl: dlopen, dlclose, dlpath, dlsym, RTLD_LAZY, RTLD_NODELETE
using Base: StringVector
using Preferences: @load_preference

if haskey(ENV, "JULIA_HDF5_PATH")
  @warn "The environment variable JULIA_HDF5_PATH is deprecated. Use preferences instead."
end

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

include("lock.jl")
include("types.jl")
include("error.jl")
include("functions.jl") # core API ccall wrappers
include("helpers.jl")

function __init__()
    # HDF5.API.__init__() is run before HDF5.__init__()

    # Ensure this is reinitialized on using
    libhdf5handle[] = dlopen(libhdf5)

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
