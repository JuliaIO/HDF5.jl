module API

using Libdl
using Base: StringVector
using Preferences: @load_preference

# We avoid calling Libdl.find_library to avoid possible segfault when calling
# dlclose (#929).
# The only difference with Libdl.find_library is that we allow custom dlopen
# flags via the `flags` argument.
function find_library_alt(libnames, extrapaths=String[]; flags=RTLD_LAZY)
    for lib in libnames
        for path in extrapaths
            l = joinpath(path, lib)
            p = dlopen(l, flags; throw_error=false)
            if p !== nothing
                dlclose(p)
                return l
            end
        end
        p = dlopen(lib, flags; throw_error=false)
        if p !== nothing
            dlclose(p)
            return lib
        end
    end
    return ""
end

const libpath = @load_preference("libhdf5path", nothing)
if libpath === nothing
    using HDF5_JLL
else
    libpaths = [libpath, joinpath(libpath, "lib"), joinpath(libpath, "lib64")]
    flags = RTLD_LAZY | RTLD_NODELETE  # RTLD_NODELETE may be needed to avoid segfault (#929)

    libhdf5 = find_library_alt(["libhdf5"], libpaths; flags=flags)
    libhdf5_hl = find_library_alt(["libhdf5_hl"], libpaths; flags=flags)

    isempty(libhdf5) && error("libhdf5 could not be found")
    isempty(libhdf5_hl) && error("libhdf5_hl could not be found")

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
