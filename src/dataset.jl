mutable struct Dataset
    id::API.hid_t
    file::File
    xfer::DatasetTransferProperties

    function Dataset(id, file, xfer = DatasetTransferProperties())
        dset = new(id, file, xfer)
        finalizer(close, dset)
        dset
    end
end
Base.cconvert(::Type{API.hid_t}, dset::Dataset) = dset
Base.unsafe_convert(::Type{API.hid_t}, dset::Dataset) = dset.id

function Base.close(obj::Dataset)
    if obj.id != -1
        if obj.file.id != -1 && isvalid(obj)
            API.h5d_close(obj)
        end
        obj.id = -1
    end
    nothing
end

Base.isvalid(obj::Dataset) = obj.id != -1 && obj.file.id != -1 && API.h5i_is_valid(obj)

function Base.getindex(dset::Dataset, name::AbstractString)
    haskey(dset, name) || throw(KeyError(name))
    open_attribute(dset, name)
end
Base.setindex!(dset::Dataset, val, name::AbstractString) = write_attribute(dset, name, val)


get_access_properties(d::Dataset)   = DatasetAccessProperties(API.h5d_get_access_plist(d))
get_create_properties(d::Dataset)   = DatasetCreateProperties(API.h5d_get_create_plist(d))


open_dataset(parent::Union{File,Group}, name::AbstractString,
             fapl::FileAccessProperties=FileAccessProperties(),
             dxpl::DatasetTransferProperties=DatasetTransferProperties()) =
    Dataset(API.h5d_open(checkvalid(parent), name, fapl), file(parent), dxpl)

# Setting dset creation properties with name/value pairs
function create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace::Dataspace; pv...)
    dcpl = DatasetCreateProperties()
    dxpl = DatasetTransferProperties()
    dapl = DatasetAccessProperties()
    setproperties!((dcpl,dxpl,dapl); pv...)
    haskey(parent, path) && error("cannot create dataset: object \"", path, "\" already exists at ", name(parent))
    Dataset(API.h5d_create(parent, path, dtype, dspace, _link_properties(path), dcpl, dapl), file(parent), dxpl)
end
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Dims; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims); pv...)
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Datatype, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, dtype, dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)
create_dataset(parent::Union{File,Group}, path::AbstractString, dtype::Type, dspace_dims::Tuple{Dims,Dims}; pv...) = create_dataset(checkvalid(parent), path, datatype(dtype), dataspace(dspace_dims[1], max_dims=dspace_dims[2]); pv...)


# Get the dataspace of a dataset
dataspace(dset::Dataset) = Dataspace(API.h5d_get_space(checkvalid(dset)))
# Get the datatype of a dataset
datatype(dset::Dataset) = Datatype(API.h5d_get_type(checkvalid(dset)), file(dset))

Base.ndims(dset::Dataset) =
    dataspace(dspace -> Base.ndims(dspace), dset)
Base.size(dset::Dataset) =
    dataspace(dspace -> Base.size(dspace), dset)
Base.size(dset::Dataset, d::Integer) =
    dataspace(dspace -> Base.size(dspace, d), dset)
Base.length(dset::Dataset) =
    dataspace(dspace -> Base.length(dspace), dset)
Base.isempty(dset::Dataset) =
    dataspace(dspace -> Base.isempty(dspace), dset)
isnull(dset::Dataset) =
    dataspace(dspace -> isnull(dspace), dset)
hyperslab(dset::Dataset, I::Union{AbstractRange{Int},Int}...) =
    dataspace(dspace -> hyperslab(dspace, I...), dset)


# Querying items in the file
Base.eltype(dset::Dataset) = get_jl_type(dset)


Base.lastindex(dset::Dataset) = length(dset)
Base.lastindex(dset::Dataset, d::Int) = size(dset, d)


iscompact(obj::Dataset) = get_create_properties(checkvalid(obj)).layout == :compact
ischunked(obj::Dataset) = get_create_properties(checkvalid(obj)).layout == :chunked
iscontiguous(obj::Dataset) = get_create_properties(checkvalid(obj)).layout == :contiguous

refresh(ds::Dataset) = API.h5d_refresh(checkvalid(ds))
Base.flush(ds::Dataset) = API.h5d_flush(checkvalid(ds))


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
    memtype = Datatype(API.h5t_get_native_type(filetype))  # padded layout in memory
    close(filetype)

    elT = eltype(X)
    if sizeof(elT) != sizeof(memtype)
        error("""
              Type size mismatch
              sizeof($elT) = $(sizeof(elT))
              sizeof($memtype) = $(sizeof(memtype))
              """)
    end

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

vlen_get_buf_size(dset::Dataset, dtype::Datatype, dspace::Dataspace) = API.h5d_vlen_get_buf_size(dset, dtype, dspace)

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

read_dataset(dset::Dataset, memtype::Datatype, buf, xfer::DatasetTransferProperties=dset.xfer) =
    API.h5d_read(dset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, buf)
write_dataset(dset::Dataset, memtype::Datatype, x, xfer::DatasetTransferProperties=dset.xfer) =
    API.h5d_write(dset, memtype, API.H5S_ALL, API.H5S_ALL, xfer, x)

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

# Create datasets and attributes with "native" types, but don't write the data.
# The return syntax is: dset, dtype = create_dataset(parent, name, data; properties...)
function create_dataset(parent::Union{File,Group}, name::AbstractString, data; pv...)
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
function write_dataset(parent::Union{File,Group}, name::AbstractString, data; pv...)
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

