### Generic H5DataStore interface ###

# Common methods that could be applicable to any interface for reading/writing variables from a file, e.g. HDF5, JLD, or MAT files.
# Types inheriting from H5DataStore should have names, read, and write methods.
# Supertype of HDF5.File, HDF5.Group, JldFile, JldGroup, Matlabv5File, and MatlabHDF5File.
abstract type H5DataStore end

# Convenience macros
macro read(fid, sym)
    !isa(sym, Symbol) && error("Second input to @read must be a symbol (i.e., a variable)")
    esc(:($sym = read($fid, $(string(sym)))))
end
macro write(fid, sym)
    !isa(sym, Symbol) && error("Second input to @write must be a symbol (i.e., a variable)")
    esc(:(write($fid, $(string(sym)), $sym)))
end

# Read a list of variables, read(parent, "A", "B", "x", ...)
function Base.read(parent::H5DataStore, name::AbstractString...)
    tuple((read(parent, x) for x in name)...)
end

# Read every variable in the file
function Base.read(f::H5DataStore)
    vars = keys(f)
    vals = Vector{Any}(undef,length(vars))
    for i = 1:length(vars)
        vals[i] = read(f, vars[i])
    end
    Dict(zip(vars, vals))
end


## HDF5 uses a plain integer to refer to each file, group, or
## dataset. These are wrapped into special types in order to allow
## method dispatch.

# Note re finalizers: we use them to ensure that objects passed back
# to the user will eventually be cleaned up properly. However, since
# finalizers don't run on a predictable schedule, we also call close
# directly on function exit. (This avoids certain problems, like those
# that occur when passing a freshly-created file to some other
# application).

# This defines an "unformatted" HDF5 data file. Formatted files are defined in separate modules.
mutable struct File <: H5DataStore
    id::API.hid_t
    filename::String

    function File(id, filename, toclose::Bool=true)
        f = new(id, filename)
        if toclose
            finalizer(close, f)
        end
        f
    end
end
Base.cconvert(::Type{API.hid_t}, f::File) = f
Base.unsafe_convert(::Type{API.hid_t}, f::File) = f.id

# Close functions that should try calling close regardless
function Base.close(obj::File)
    if obj.id != -1
        API.h5f_close(obj)
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::File) = obj.id != -1 && API.h5i_is_valid(obj)

get_access_properties(f::File)      = FileAccessProperties(API.h5f_get_access_plist(f))
get_create_properties(f::File)      = FileCreateProperties(API.h5f_get_create_plist(f))


"""
    isopen(obj::HDF5.File)

Returns `true` if `obj` has not been closed, `false` if it has been closed.
"""
Base.isopen(obj::File) = obj.id != -1

"""
    start_swmr_write(h5::HDF5.File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://portal.hdfgroup.org/display/HDF5/Single+Writer+Multiple+Reader++-+SWMR).
"""
start_swmr_write(h5::File) = API.h5f_start_swmr_write(h5)
