# Dataset defined in types.jl

# Get the dataspace of a dataset
dataspace(dset::Dataset) = Dataspace(API.h5d_get_space(checkvalid(dset)))

# Open Dataset

open_dataset(parent::Union{File,Group},
    name::AbstractString,
    dapl::DatasetAccessProperties=DatasetAccessProperties(),
    dxpl::DatasetTransferProperties=DatasetTransferProperties()
) = Dataset(API.h5d_open(checkvalid(parent), name, dapl), file(parent), dxpl)

# Setting dset creation properties with name/value pairs
"""
    create_dataset(parent, path, datatype, dataspace; properties...)

# Arguments
* `parent` - `File` or `Group`
* `path` - `String` describing the path of the dataset within the HDF5 file or
           `nothing` to create an anonymous dataset
* `datatype` - `Datatype` or `Type` or the dataset
* `dataspace` - `Dataspace` or `Dims` of the dataset
* `properties` - keyword name-value pairs set properties of the dataset

# Keywords

There are many keyword properties that can be set. Below are a few select keywords.
* `chunk` - `Dims` describing the size of a chunk. Needed to apply filters.
* `filters` - `AbstractVector{<: Filters.Filter}` describing the order of the filters to apply to the data. See [`Filters`](@ref)
* `external` - `Tuple{AbstractString, Intger, Integer}` `(filepath, offset, filesize)` External dataset file location, data offset, and file size. See [`API.h5p_set_external`](@ref).

Additionally, the initial create, transfer, and access properties can be provided as a keyword:
* `dcpl` - [`DatasetCreateProperties`](@ref)
* `dxpl` - [`DatasetTransferProperties`](@ref)
* `dapl` - [`DatasetAccessProperties`](@ref)

See also
* [`H5P`](@ref H5P)
"""
function create_dataset(
    parent::Union{File,Group},
    path::Union{AbstractString,Nothing},
    dtype::Datatype,
    dspace::Dataspace;
    dcpl::DatasetCreateProperties = DatasetCreateProperties(),
    dxpl::DatasetTransferProperties = DatasetTransferProperties(),
    dapl::DatasetAccessProperties = DatasetAccessProperties(),
    pv...
)
    !isnothing(path) && haskey(parent, path) && error("cannot create dataset: object \"", path, "\" already exists at ", name(parent))
    pv = setproperties!(dcpl,dxpl,dapl; pv...)
    isempty(pv) || error("invalid keyword options")
    if isnothing(path)
        ds = API.h5d_create_anon(parent, dtype, dspace, dcpl, dapl)
    else
        ds = API.h5d_create(parent, path, dtype, dspace, _link_properties(path), dcpl, dapl)
    end
    Dataset(ds, file(parent), dxpl)
end
create_dataset(parent::Union{File,Group}, path::Union{AbstractString,Nothing}, dtype::Datatype, dspace_dims::Dims; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims); pv...)
create_dataset(parent::Union{File,Group}, path::Union{AbstractString,Nothing}, dtype::Datatype, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
create_dataset(parent::Union{File,Group}, path::Union{AbstractString,Nothing}, dtype::Type, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
create_dataset(parent::Union{File,Group}, path::Union{AbstractString,Nothing}, dtype::Type, dspace_dims::Dims; pv...) = create_dataset(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims); pv...)
create_dataset(parent::Union{File,Group}, path::Union{AbstractString,Nothing}, dtype::Type, dspace_dims::Int...; pv...) = create_dataset(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims); pv...)

# Get the datatype of a dataset
datatype(dset::Dataset) = Datatype(API.h5d_get_type(checkvalid(dset)), file(dset))

function read_dataset(parent::Union{File,Group}, name::AbstractString)
    local ret
    obj = open_dataset(parent, name)
    try
        ret = read(obj)
    finally
        close(obj)
    end
    ret
end

refresh(ds::Dataset) = API.h5d_refresh(checkvalid(ds))
Base.flush(ds::Dataset) = API.h5d_flush(checkvalid(ds))

# Array constructor for datasets
Base.Array(x::Dataset) = read(x)

Base.lastindex(dset::Dataset) = length(dset)
Base.lastindex(dset::Dataset, d::Int) = size(dset, d)

function iscompact(obj::Dataset)
    prop = API.h5d_get_create_plist(checkvalid(obj))
    try
        API.h5p_get_layout(prop) == API.H5D_COMPACT
    finally
        API.h5p_close(prop)
    end
end

function ischunked(obj::Dataset)
    prop = API.h5d_get_create_plist(checkvalid(obj))
    try
        API.h5p_get_layout(prop) == API.H5D_CHUNKED
    finally
        API.h5p_close(prop)
    end
end

function iscontiguous(obj::Dataset)
    prop = API.h5d_get_create_plist(checkvalid(obj))
    try
        API.h5p_get_layout(prop) == API.H5D_CONTIGUOUS
    finally
        API.h5p_close(prop)
    end
end

# Reading with mmap
ismmappable(::Type{<:ScalarType}) = true
ismmappable(::Type{Complex{T}}) where {T<:BitsType} = true
ismmappable(::Type) = false
ismmappable(obj::Dataset, ::Type{T}) where {T} = ismmappable(T) && iscontiguous(obj)
ismmappable(obj::Dataset) = ismmappable(obj, get_jl_type(obj))

function readmmap(obj::Dataset, ::Type{T}) where {T}
    dspace = dataspace(obj)
    stype = API.h5s_get_simple_extent_type(dspace)
    (stype != API.H5S_SIMPLE) && error("can only mmap simple dataspaces")
    dims = size(dspace)

    if isempty(dims)
        return T[]
    end
    if !Sys.iswindows()
        local fdint
        prop = API.h5d_get_access_plist(obj)
        try
            # TODO: Should check return value of API.h5f_get_driver()
            fdptr = API.h5f_get_vfd_handle(obj.file, prop)
            fdint = unsafe_load(convert(Ptr{Cint}, fdptr))
        finally
            API.h5p_close(prop)
        end
        fd = fdio(fdint)
    else
        # This is a workaround since the regular code path does not work on windows
        # (see #89 for background). The error is that "Mmap.mmap(fd, ...)" cannot
        # create create a valid file mapping. The question is if the handler
        # returned by "API.h5f_get_vfd_handle" has
        # the correct format as required by the "fdio" function. The former
        # calls
        # https://gitlabext.iag.uni-stuttgart.de/libs/hdf5/blob/develop/src/H5FDcore.c#L1209
        #
        # The workaround is to create a new file handle, which should actually
        # not make any problems. Since we need to know the permissions of the
        # original file handle, we first retrieve them using the "API.h5f_get_intent"
        # function

        # Check permissions
        intent = API.h5f_get_intent(obj.file)
        flag = intent == API.H5F_ACC_RDONLY ? "r" : "r+"
        fd = open(obj.file.filename, flag)
    end

    offset = API.h5d_get_offset(obj)
    if offset == -1 % API.haddr_t
        # note that API.h5d_get_offset may not actually raise an error, so we need to check it here
        error("Error getting offset")
    elseif offset % Base.datatype_alignment(T) == 0
        A = Mmap.mmap(fd, Array{T,length(dims)}, dims, offset)
    else
        Aflat = Mmap.mmap(fd, Vector{UInt8}, prod(dims)*sizeof(T), offset)
        A = reshape(reinterpret(T, Aflat), dims)
    end

    if Sys.iswindows()
        close(fd)
    end

    return A
end

function readmmap(obj::Dataset)
    T = get_jl_type(obj)
    ismmappable(T) || error("Cannot mmap datasets of type $T")
    iscontiguous(obj) || error("Cannot mmap discontiguous dataset")
    readmmap(obj, T)
end

# Generic write
function Base.write(parent::Union{File,Group}, name1::Union{AbstractString,Nothing}, val1, name2::Union{AbstractString,Nothing}, val2, nameval...) # FIXME: remove?
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

# Plain dataset & attribute writes
# Due to method ambiguities we generate these explicitly

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = create_dataset(parent, name, data; properties...)

function create_dataset(parent::Union{File,Group}, name::Union{AbstractString,Nothing}, data; pv...)
    dtype = datatype(data)
    dspace = dataspace(data)
    obj = try
        create_dataset(parent, name, dtype, dspace; pv...)
    finally
        close(dspace)
    end
    return obj, dtype
end

# Create and write, closing the objects upon exit
function write_dataset(parent::Union{File,Group}, name::Union{AbstractString,Nothing}, data; pv...)
    obj, dtype = create_dataset(parent, name, data; pv...)
    try
        write_dataset(obj, dtype, data)
    catch exc
        delete_object(obj)
        rethrow(exc)
    finally
        close(obj)
        close(dtype)
    end
    nothing
end

# Write to already-created objects
function Base.write(obj::Dataset, x)
    dtype = datatype(x)
    try
        write_dataset(obj, dtype, x)
    finally
        close(dtype)
    end
end

# For plain files and groups, let "write(obj, name, val; properties...)" mean "write_dataset"
Base.write(parent::Union{File,Group}, name::Union{AbstractString,Nothing}, data; pv...) = write_dataset(parent, name, data; pv...)


# Indexing

Base.eachindex(::IndexLinear, A::Dataset) = Base.OneTo(length(A))
Base.axes(dset::Dataset) = map(Base.OneTo, size(dset))

# Write to a subset of a dataset using array slices: dataset[:,:,10] = array

const IndexType = Union{AbstractRange{Int},Int,Colon}
function Base.setindex!(dset::Dataset, X::Array{T}, I::IndexType...) where T
    !isconcretetype(T) && error("type $T is not concrete")
    U = get_jl_type(dset)

    # perform conversions for numeric types
    if (U <: Number) && (T <: Number) && U !== T
        X = convert(Array{U}, X)
    end

    filetype = datatype(dset)
    memtype = _memtype(filetype, eltype(X))
    close(filetype)

    dspace = dataspace(dset)
    stype = API.h5s_get_simple_extent_type(dspace)
    stype == API.H5S_NULL && error("attempting to write to null dataspace")

    indices = Base.to_indices(dset, I)
    dspace = hyperslab(dspace, indices...)

    memspace = dataspace(X)

    if API.h5s_get_select_npoints(dspace) != API.h5s_get_select_npoints(memspace)
        error("number of elements in src and dest arrays must be equal")
    end

    try
        API.h5d_write(dset, memtype, memspace, dspace, dset.xfer, X)
    finally
        close(memtype)
        close(memspace)
        close(dspace)
    end

    return X
end

function Base.setindex!(dset::Dataset, x::T, I::IndexType...) where T <: Number
    indices = Base.to_indices(dset, I)
    X = fill(x, map(length, indices))
    Base.setindex!(dset, X, indices...)
end

function Base.setindex!(dset::Dataset, X::AbstractArray, I::IndexType...)
    Base.setindex!(dset, Array(X), I...)
end

"""
    create_external_dataset(parent, name, filepath, dtype, dspace, offset = 0)

Create a external dataset with data in an external file.
* `parent` - File or Group
* `name` - Name of the Dataset
* `filepath` - File path to where the data is tored
* `dtype` - Datatype, Type, or value where `datatype` is applicable
* `offset` - Offset, in bytes, from the beginning of the file to the location in the file where the data starts.

Use `API.h5p_set_external` to link to multiple segments.

See also [`API.h5p_set_external`](@ref)
"""
function create_external_dataset(parent::Union{File,Group}, name::AbstractString, filepath::AbstractString, t, sz::Dims, offset::Integer=0)
    create_external_dataset(parent, name, filepath, datatype(t), dataspace(sz), offset)
end
function create_external_dataset(parent::Union{File,Group}, name::AbstractString, filepath::AbstractString, dtype::Datatype, dspace::Dataspace, offset::Integer=0)
    checkvalid(parent)
    create_dataset(parent, name, dtype, dspace; external=(filepath, offset, length(dspace)*sizeof(dtype)))
end

### HDF5 utilities ###


# default behavior
read_dataset(dset::Dataset, memtype::Datatype, buf, xfer::DatasetTransferProperties=dset.xfer) =
    API.h5d_read(dset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
write_dataset(dset::Dataset, memtype::Datatype, x, xfer::DatasetTransferProperties=dset.xfer) =
    API.h5d_write(dset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, x)

# type-specific behaviors
function _check_invalid(dataset::Dataset, buf::AbstractArray)
    num_bytes_dset = Base.checked_mul(sizeof(datatype(dataset)), length(dataset))
    num_bytes_buf = Base.checked_mul(sizeof(eltype(buf)), length(buf))
    num_bytes_buf == num_bytes_dset || throw(ArgumentError(
        "Invalid number of bytes: $num_bytes_buf != $num_bytes_dset, for dataset \"$(name(dataset))\""
    ))
    stride(buf, 1) == 1 || throw(ArgumentError("Cannot read/write arrays with a different stride than `Array`"))
end
function read_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::DatasetTransferProperties=dataset.xfer)
    _check_invalid(dataset, buf)
    API.h5d_read(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
end

function write_dataset(dataset::Dataset, memtype::Datatype, buf::AbstractArray, xfer::DatasetTransferProperties=dataset.xfer)
    _check_invalid(dataset, buf)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
end
function write_dataset(dataset::Dataset, memtype::Datatype, str::Union{AbstractString,Nothing}, xfer::DatasetTransferProperties=dataset.xfer)
    strbuf = Base.cconvert(Cstring, str)
    GC.@preserve strbuf begin
        # unsafe_convert(Cstring, strbuf) is responsible for enforcing the no-'\0' policy,
        # but then need explicit convert to Ptr{UInt8} since Ptr{Cstring} -> Ptr{Cvoid} is
        # not automatic.
        buf = convert(Ptr{UInt8}, Base.unsafe_convert(Cstring, strbuf))
        API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
    end
end
function write_dataset(dataset::Dataset, memtype::Datatype, x::T, xfer::DatasetTransferProperties=dataset.xfer) where {T<:Union{ScalarType, Complex{<:ScalarType}}}
    tmp = Ref{T}(x)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, tmp)
end
function write_dataset(dataset::Dataset, memtype::Datatype, strs::Array{<:AbstractString}, xfer::DatasetTransferProperties=dataset.xfer)
    p = Ref{Cstring}(strs)
    API.h5d_write(dataset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, p)
end
write_dataset(dataset::Dataset, memtype::Datatype, ::EmptyArray, xfer::DatasetTransferProperties=dataset.xfer) = nothing

"""
    get_datasets(file::HDF5.File) -> datasets::Vector{HDF5.Dataset}

Get all the datasets in an hdf5 file without loading the data.
"""
function get_datasets(file::File)
    list = Dataset[]
    get_datasets!(list, file)
    list
end
 function get_datasets!(list::Vector{Dataset}, node::Union{File,Group,Dataset})
    if isa(node, Dataset)
        push!(list, node)
    else
        for c in keys(node)
            get_datasets!(list, node[c])
        end
    end
end

### Chunks ###

# heuristic chunk layout (return empty array to disable chunking)
function heuristic_chunk(T, shape)
    Ts = sizeof(T)
    sz = prod(shape)
    sz == 0 && return Int[] # never return a zero-size chunk
    chunk = [shape...]
    nd = length(chunk)
    # simplification of ugly heuristic target chunk size from PyTables/h5py:
    target = min(1500000, max(12000, floor(Int, 300*cbrt(Ts*sz))))
    Ts > target && return ones(chunk)
    # divide last non-unit dimension by 2 until we get <= target
    # (since Julia default to column-major, favor contiguous first dimension)
    while Ts*prod(chunk) > target
        i = nd
        while chunk[i] == 1
            i -= 1
        end
        chunk[i] >>= 1
    end
    return chunk
end
heuristic_chunk(T, ::Tuple{}) = Int[]
heuristic_chunk(A::AbstractArray{T}) where {T} = heuristic_chunk(T, size(A))
heuristic_chunk(x) = Int[]
# (strings are saved as scalars, and hence cannot be chunked)

"""
    do_write_chunk(dataset::Dataset, offset, chunk_bytes::AbstractArray, filter_mask=0)

Write a raw chunk at a given offset.
`chunk_bytes` is an AbstractArray that can be converted to a pointer, Ptr{Cvoid}.
`offset` is a 1-based list of rank `ndims(dataset)` and must fall on a chunk boundary.
"""
function do_write_chunk(dataset::Dataset, offset, chunk_bytes::AbstractArray, filter_mask=0)
    checkvalid(dataset)
    offs = collect(API.hsize_t, reverse(offset)) .- 1
    write_chunk(dataset, offs, chunk_bytes; filter_mask=UInt32(filter_mask))
end

"""
    do_write_chunk(dataset::Dataset, index, chunk_bytes::AbstractArray, filter_mask=0)

Write a raw chunk at a given linear index.
`chunk_bytes` is an AbstractArray that can be converted to a pointer, Ptr{Cvoid}.
`index` is 1-based and consecutive up to the number of chunks.
"""
function do_write_chunk(dataset::Dataset, index::Integer, chunk_bytes::AbstractArray, filter_mask=0)
    checkvalid(dataset)
    index -= 1
    write_chunk(dataset, index, chunk_bytes; filter_mask=UInt32(filter_mask))
end

"""
    do_read_chunk(dataset::Dataset, offset)

Read a raw chunk at a given offset.
`offset` is a 1-based list of rank `ndims(dataset)` and must fall on a chunk boundary.
"""
function do_read_chunk(dataset::Dataset, offset)
    checkvalid(dataset)
    offs = collect(API.hsize_t, reverse(offset)) .- 1
    filters = Ref{UInt32}()
    buf = read_chunk(dataset, offs; filters = filters)
    return (filters[], buf)
end

"""
    do_read_chunk(dataset::Dataset, index::Integer)

Read a raw chunk at a given index.
`index` is 1-based and consecutive up to the number of chunks.
"""
function do_read_chunk(dataset::Dataset, index::Integer)
    checkvalid(dataset)
    index -= 1
    filters = Ref{UInt32}()
    buf = read_chunk(dataset, index; filters = filters)
    return (filters[], buf)
end

struct ChunkStorage{I<:IndexStyle,N} <: AbstractArray{Tuple{UInt32,Vector{UInt8}},N}
    dataset::Dataset
end
ChunkStorage{I,N}(dataset) where {I,N} = ChunkStorage{I,N}(dataset)
Base.IndexStyle(::ChunkStorage{I}) where {I<:IndexStyle} = I()

# ChunkStorage{IndexCartesian,N} (default)

function ChunkStorage(dataset)
    ChunkStorage{IndexCartesian, ndims(dataset)}(dataset)
end

Base.size(cs::ChunkStorage{IndexCartesian}) = get_num_chunks_per_dim(cs.dataset)


function Base.axes(cs::ChunkStorage{IndexCartesian})
    chunk = get_chunk(cs.dataset)
    extent = size(cs.dataset)
    ntuple(i -> 1:chunk[i]:extent[i], length(extent))
end

# Filter flags provided
function Base.setindex!(chunk_storage::ChunkStorage{IndexCartesian}, v::Tuple{<:Integer,AbstractArray}, index::Integer...)
    do_write_chunk(chunk_storage.dataset, index, v[2], v[1])
end

# Filter flags will default to 0
function Base.setindex!(chunk_storage::ChunkStorage{IndexCartesian}, v::AbstractArray, index::Integer...)
    do_write_chunk(chunk_storage.dataset, index, v)
end

function Base.getindex(chunk_storage::ChunkStorage{IndexCartesian}, index::Integer...)
    do_read_chunk(chunk_storage.dataset, API.hsize_t.(index))
end

# ChunkStorage{IndexLinear,1}

ChunkStorage{IndexLinear}(dataset) = ChunkStorage{IndexLinear,1}(dataset)
Base.size(cs::ChunkStorage{IndexLinear})   = (get_num_chunks(cs.dataset),)
Base.length(cs::ChunkStorage{IndexLinear}) =  get_num_chunks(cs.dataset)

function Base.setindex!(chunk_storage::ChunkStorage{IndexLinear}, v::Tuple{<:Integer,AbstractArray}, index::Integer)
    do_write_chunk(chunk_storage.dataset, index, v[2], v[1])
end

# Filter flags will default to 0
function Base.setindex!(chunk_storage::ChunkStorage{IndexLinear}, v::AbstractArray, index::Integer)
    do_write_chunk(chunk_storage.dataset, index, v)
end

function Base.getindex(chunk_storage::ChunkStorage{IndexLinear}, index::Integer)
    do_read_chunk(chunk_storage.dataset, index)
end

# TODO: Move to show.jl. May need to include show.jl after this line.
# ChunkStorage axes may be StepRanges, but this is not available until v"1.6.0"
# no method matching CartesianIndices(::Tuple{StepRange{Int64,Int64},UnitRange{Int64}}) until v"1.6.0"

function Base.show(io::IO, cs::ChunkStorage{IndexCartesian,N}) where N
    println(io, "HDF5.ChunkStorage{IndexCartesian,$N}")
    print(io, "Axes: ")
    println(io, axes(cs))
    print(io, cs.dataset)
end
Base.show(io::IO, ::MIME{Symbol("text/plain")}, cs::ChunkStorage{IndexCartesian,N}) where {N} = show(io, cs)

function get_chunk(dset::Dataset)
    p = get_create_properties(dset)
    local ret
    try
        ret = get_chunk(p)
    finally
        close(p)
    end
    ret
end

# properties that require chunks in order to work (e.g. any filter)
# values do not matter -- just needed to form a NamedTuple with the desired keys
const chunked_props = (; compress=nothing, deflate=nothing, blosc=nothing, shuffle=nothing)
