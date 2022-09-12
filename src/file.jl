"""
    h5open(filename::AbstractString, mode::AbstractString="r"; swmr=false, pv...)

Open or create an HDF5 file where `mode` is one of:
 - "r"  read only
 - "r+" read and write
 - "cw" read and write, create file if not existing, do not truncate
 - "w"  read and write, create a new file (destroys any existing contents)

Pass `swmr=true` to enable (Single Writer Multiple Reader) SWMR write access for "w" and
"r+", or SWMR read access for "r".

Properties can be specified as keywords for [`FileAccessProperties`](@ref) and [`FileCreateProperties`](@ref).

Also the keywords `fapl` and `fcpl` can be used to provide default instances of these property lists. Property
lists passed in via keyword will be closed. This is useful to set properties not currently defined by HDF5.jl.

Note that `h5open` uses `fclose_degree = :strong` by default, but this can be overriden by the `fapl` keyword.
"""
function h5open(
    filename::AbstractString,
    mode::AbstractString,
    fapl::FileAccessProperties,
    fcpl::FileCreateProperties=FileCreateProperties();
    swmr::Bool=false
)
    #! format: off
    rd, wr, cr, tr, ff =
        mode == "r"  ? (true,  false, false, false, false) :
        mode == "r+" ? (true,  true,  false, false, true ) :
        mode == "cw" ? (false, true,  true,  false, true ) :
        mode == "w"  ? (false, true,  true,  true,  false) :
        # mode == "w+" ? (true,  true,  true,  true,  false) :
        # mode == "a"  ? (true,  true,  true,  true,  true ) :
        error("invalid open mode: ", mode)
    #! format: on
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end

    if cr && (tr || !isfile(filename))
        flag = swmr ? API.H5F_ACC_TRUNC | API.H5F_ACC_SWMR_WRITE : API.H5F_ACC_TRUNC
        fid = API.h5f_create(filename, flag, fcpl, fapl)
    else
        if wr
            flag = swmr ? API.H5F_ACC_RDWR | API.H5F_ACC_SWMR_WRITE : API.H5F_ACC_RDWR
        else
            flag = swmr ? API.H5F_ACC_RDONLY | API.H5F_ACC_SWMR_READ : API.H5F_ACC_RDONLY
        end
        fid = API.h5f_open(filename, flag, fapl)
    end
    return File(fid, filename)
end

function h5open(
    filename::AbstractString,
    mode::AbstractString="r";
    swmr::Bool=false,
    # With garbage collection, the other modes don't make sense
    fapl = FileAccessProperties(; fclose_degree=:strong),
    fcpl = FileCreateProperties(),
    pv...
)
    try
        pv = setproperties!(fapl, fcpl; pv...)
        isempty(pv) || error("invalid keyword options $pv")
        return h5open(filename, mode, fapl, fcpl; swmr=swmr)
    finally
        close(fapl)
        close(fcpl)
    end
end

"""
    function h5open(f::Function, args...; pv...)

Apply the function f to the result of `h5open(args...; kwargs...)` and close the resulting
`HDF5.File` upon completion.
For example with a `do` block:

    h5open("foo.h5","w") do h5
        h5["foo"]=[1,2,3]
    end

"""
function h5open(f::Function, args...; context=copy(CONTEXT), pv...)
    file = h5open(args...; pv...)
    task_local_storage(:hdf5_context, context) do
        if (track_order = get(pv, :track_order, nothing)) !== nothing
            context.file_create.track_order = context.group_create.track_order = track_order
        end
        try
            f(file)  # the function body can access `context` via `get_context_property`
        finally
            close(file)
            close(context)
        end
    end
end

function h5rewrite(f::Function, filename::AbstractString, args...)
    tmppath, tmpio = mktemp(dirname(filename))
    close(tmpio)

    try
        val = h5open(f, tmppath, "w", args...)
        Base.Filesystem.rename(tmppath, filename)
        return val
    catch
        Base.Filesystem.unlink(tmppath)
        rethrow()
    end
end

function Base.close(obj::File)
    if obj.id != -1
        API.h5f_close(obj)
        obj.id = -1
    end
    nothing
end

"""
  isopen(obj::HDF5.File)

Returns `true` if `obj` has not been closed, `false` if it has been closed.
"""
Base.isopen(obj::File) = obj.id != -1

"""
    ishdf5(name::AbstractString)

Returns `true` if the file specified by `name` is in the HDF5 format, and `false` otherwise.
"""
function ishdf5(name::AbstractString)
    isfile(name) || return false # fastpath in case the file is non-existant
    # TODO: v1.12 use the more robust API.h5f_is_accesible
    try
        # docs falsely claim API.h5f_is_hdf5 doesn't error, but it does
        return API.h5f_is_hdf5(name)
    catch
        return false
    end
end

# Extract the file
file(f::File) = f
file(o::Union{Object,Attribute}) = o.file
fd(obj::Object) = API.h5i_get_file_id(checkvalid(obj))

filename(obj::Union{File,Group,Dataset,Attribute,Datatype}) =
    API.h5f_get_name(checkvalid(obj))

"""
    start_swmr_write(h5::HDF5.File)

Start Single Reader Multiple Writer (SWMR) writing mode.
See [SWMR documentation](https://portal.hdfgroup.org/display/HDF5/Single+Writer+Multiple+Reader++-+SWMR).
"""
start_swmr_write(h5::File) = API.h5f_start_swmr_write(h5)

# Flush buffers
Base.flush(f::Union{Object,Attribute,Datatype,File}, scope=API.H5F_SCOPE_GLOBAL) =
    API.h5f_flush(checkvalid(f), scope)
