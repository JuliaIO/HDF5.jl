### High-level interface ###
"""
    h5open(filename::AbstractString, mode::AbstractString="r"; swmr=false, pv...)

Open or create an HDF5 file where `mode` is one of:
 - "r"  read only
 - "r+" read and write
 - "cw" read and write, create file if not existing, do not truncate
 - "w"  read and write, create a new file (destroys any existing contents)

Pass `swmr=true` to enable (Single Writer Multiple Reader) SWMR write access for "w" and
"r+", or SWMR read access for "r".
"""
function h5open(filename::AbstractString, mode::AbstractString = "r"; swmr::Bool = false, pv...)
    # With garbage collection, the other modes don't make sense
    fapl = FileAccessProperties(; fclose_degree = :strong)
    fcpl = FileCreateProperties()
    setproperties!((fapl, fcpl); pv...)
    rd, wr, cr, tr, ff =
        mode == "r"  ? (true,  false, false, false, false) :
        mode == "r+" ? (true,  true,  false, false, true ) :
        mode == "cw" ? (false, true,  true,  false, true ) :
        mode == "w"  ? (false, true,  true,  true,  false) :
        # mode == "w+" ? (true,  true,  true,  true,  false) :
        # mode == "a"  ? (true,  true,  true,  true,  true ) :
        error("invalid open mode: ", mode)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end

    if cr && (tr || !isfile(filename))
        flag = swmr ? API.H5F_ACC_TRUNC | API.H5F_ACC_SWMR_WRITE : API.H5F_ACC_TRUNC
        fid = API.h5f_create(filename, flag, fcpl, fapl)
    else
        ishdf5(filename) || error("unable to determine if $filename is accessible in the HDF5 format (file may not exist)")
        if wr
            flag = swmr ? API.H5F_ACC_RDWR | API.H5F_ACC_SWMR_WRITE : API.H5F_ACC_RDWR
        else
            flag = swmr ? API.H5F_ACC_RDONLY | API.H5F_ACC_SWMR_READ : API.H5F_ACC_RDONLY
        end
        fid = API.h5f_open(filename, flag, fapl)
    end
    close(fapl)
    close(fcpl)
    return File(fid, filename)
end

"""
    function h5open(f::Function, args...; swmr=false, pv...)

Apply the function f to the result of `h5open(args...;kwargs...)` and close the resulting
`HDF5.File` upon completion. For example with a `do` block:


    h5open("foo.h5","w") do h5
        h5["foo"]=[1,2,3]
    end

"""
function h5open(f::Function, args...; swmr=false, pv...)
    fid = h5open(args...; swmr=swmr, pv...)
    try
        f(fid)
    finally
        close(fid)
    end
end

function h5rewrite(f::Function, filename::AbstractString, args...)
    tmppath,tmpio = mktemp(dirname(filename))
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

function h5write(filename, name::AbstractString, data; pv...)
    fid = h5open(filename, "cw"; pv...)
    try
        write(fid, name, data)
    finally
        close(fid)
    end
end

function h5read(filename, name::AbstractString; pv...)
    local dat
    fid = h5open(filename, "r"; pv...)
    try
        obj = getindex(fid, name; pv...)
        dat = read(obj)
        close(obj)
    finally
        close(fid)
    end
    dat
end

function h5read(filename, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    local dat
    fid = h5open(filename, "r"; pv...)
    try
        obj = getindex(fid, name_type_pair[1]; pv...)
        dat = read(obj, name_type_pair[2])
        close(obj)
    finally
        close(fid)
    end
    dat
end

function h5read(filename, name::AbstractString, indices::Tuple{Vararg{Union{AbstractRange{Int},Int,Colon}}}; pv...)
    local dat
    fid = h5open(filename, "r"; pv...)
    try
        dset = getindex(fid, name; pv...)
        dat = dset[indices...]
        close(dset)
    finally
        close(fid)
    end
    dat
end

function h5writeattr(filename, name::AbstractString, data::Dict)
    fid = h5open(filename, "r+")
    try
        obj = fid[name]
        attrs = attributes(obj)
        for x in keys(data)
            attrs[x] = data[x]
        end
        close(obj)
    finally
        close(fid)
    end
end

function h5readattr(filename, name::AbstractString)
    local dat
    fid = h5open(filename,"r")
    try
        obj = fid[name]
        a = attributes(obj)
        dat = Dict(x => read(a[x]) for x in keys(a))
        close(obj)
    finally
        close(fid)
    end
    dat
end

"""
    ishdf5(name::AbstractString)

Returns `true` if the file specified by `name` is in the HDF5 format, and `false` otherwise.
"""
function ishdf5(name::AbstractString)
    isfile(name) || return false # fastpath in case the file is non-existant
    # TODO: v1.12 use the more robust h5f_is_accesible
    try
        # docs falsely claim h5f_is_hdf5 doesn't error, but it does and prints the error stack on fail
        # silence the error stack in case the call throws
        return silence_errors(() -> API.h5f_is_hdf5(name))
    catch
        return false
    end
end

# Ensure that objects haven't been closed
checkvalid(obj) = isvalid(obj) ? obj : error("File or object has been closed")

# Flush buffers
Base.flush(f::Union{Object,Attribute,Datatype,File}, scope = API.H5F_SCOPE_GLOBAL) = API.h5f_flush(checkvalid(f), scope)

# filename and name
filename(obj::Union{File,Group,Dataset,Attribute,Datatype}) = API.h5f_get_name(checkvalid(obj))
name(obj::Union{File,Group,Dataset,Datatype}) = API.h5i_get_name(checkvalid(obj))

# Generic read functions

function Base.read(parent::Union{File,Group}, name::AbstractString; pv...)
    obj = getindex(parent, name; pv...)
    val = read(obj)
    close(obj)
    val
end

function Base.read(parent::Union{File,Group}, name_type_pair::Pair{<:AbstractString,DataType}; pv...)
    obj = getindex(parent, name_type_pair[1]; pv...)
    val = read(obj, name_type_pair[2])
    close(obj)
    val
end

# "Plain" (unformatted) reads. These work only for simple types: scalars, arrays, and strings
# See also "Reading arrays using getindex" below
# This infers the Julia type from the HDF5.Datatype. Specific file formats should provide their own read(dset).

function Base.read(obj::DatasetOrAttribute)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    val = generic_read(obj, dtype, T)
    close(dtype)
    return val
end

function Base.getindex(dset::Dataset, I...)
    dtype = datatype(dset)
    T = get_jl_type(dtype)
    val = generic_read(dset, dtype, T, I...)
    close(dtype)
    return val
end

function Base.read(obj::DatasetOrAttribute, ::Type{T}, I...) where T
    dtype = datatype(obj)
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end

# `Type{String}` does not have a definite size, so the generic_read does not accept
# it even though it will return a `String`. This explicit overload allows that usage.
function Base.read(obj::DatasetOrAttribute, ::Type{String}, I...)
    dtype = datatype(obj)
    T = get_jl_type(dtype)
    T <: Union{Cstring, FixedString} || error(name(obj), " cannot be read as type `String`")
    val = generic_read(obj, dtype, T, I...)
    close(dtype)
    return val
end


Base.read(attr::Attributes, name::AbstractString) = read_attribute(attr.parent, name)

# Generic write
function Base.write(parent::Union{File,Group}, name1::AbstractString, val1, name2::AbstractString, val2, nameval...) # FIXME: remove?
    if !iseven(length(nameval))
        error("name, value arguments must come in pairs")
    end
    write(parent, name1, val1)
    write(parent, name2, val2)
    for i = 1:2:length(nameval)
        thisname = nameval[i]
        if !isa(thisname, AbstractString)
            error("Argument ", i+5, " should be a string, but it's a ", typeof(thisname))
        end
        write(parent, thisname, nameval[i+1])
    end
end

# Write to already-created objects
function Base.write(obj::Attribute, x)
    dtype = datatype(x)
    try
        write_attribute(obj, dtype, x)
    finally
        close(dtype)
    end
end
function Base.write(obj::Dataset, x)
    dtype = datatype(x)
    try
        write_dataset(obj, dtype, x)
    finally
        close(dtype)
    end
end

# For plain files and groups, let "write(obj, name, val; properties...)" mean "write_dataset"
Base.write(parent::Union{File,Group}, name::AbstractString, data; pv...) = write_dataset(parent, name, data; pv...)
# For datasets, "write(dset, name, val; properties...)" means "write_attribute"
Base.write(parent::Dataset, name::AbstractString, data; pv...) = write_attribute(parent, name, data; pv...)

"""
    create_external(source::Union{HDF5.File, HDF5.Group}, source_relpath, target_filename, target_path, 
                    [lcpl::LinkCreateProperties, lapl::LinkAccessProperties])

Create an external link such that `source[source_relpath]` points to `target_path` within the file
with path `target_filename`

# External links
- $(h5doc("H5L_CREATE_EXTERNAL"))
"""
function create_external(source::Union{File,Group}, source_relpath, target_filename, target_path,
                         lcpl::LinkCreateProperties=LinkCreateProperties(), lapl::LinkAccessProperties=LinkAccessProperties();
                         lcpl_id=nothing, lapl_id=nothing)
    if lcpl_id !== nothing
        depwarn("lcpl_id keyword argument has been deprecated, use `lcpl` positional argument instead", :create_external)
        lcpl = lcpl_id
    end    
    if lapl_id !== nothing
        depwarn("lapl_id keyword argument has been deprecated, use `lcpl` positional argument instead", :create_external)
        lapl = lapl_id
    end 
    API.h5l_create_external(target_filename, target_path, source, source_relpath, lcpl, lapl)
    nothing
end

