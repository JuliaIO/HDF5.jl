"""
    HFD5.RawAPI

Low-level HDF5 API without locks.
"""
module RawAPI

import Libdl
using Base: StringVector

const depsfile = joinpath(@__DIR__, "..", "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error(
        "HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
        "and restart Julia."
    )
end

const _use_lock = false
use_lock() = _use_lock
lock_and_close(obj) = close(obj)

include("types.jl")
include("error.jl")
include("functions.jl") # core API ccall wrappers
include("helpers.jl")

function __init__()
    # HDF5.API.__init__() is run before HDF5.__init__()

    # From deps.jl
    check_deps()

    # Ensure this is reinitialized on using
    libhdf5handle[] = Libdl.dlopen(libhdf5)

    # Disable file locking as that can cause problems with mmap'ing.
    # File locking is disabled in HDF5.init!(::FileAccessPropertyList)
    # or here if h5p_set_file_locking is not available
    @static if !has_h5p_set_file_locking() && !haskey(ENV, "HDF5_USE_FILE_LOCKING")
        ENV["HDF5_USE_FILE_LOCKING"] = "FALSE"
    end

    # use our own error handling machinery (i.e. turn off automatic error printing)
    h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)
end

end # module API
