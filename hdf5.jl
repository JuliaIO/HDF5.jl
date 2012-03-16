## Type aliases for standard C types, introduced for better readability

typealias C_int Int32
typealias C_unsigned Uint32
typealias C_char Uint8
typealias C_unsigned_long_long Uint64
typealias C_size_t Uint64

####################
## HDF5 interface ##
####################

## HDF5 types and constants

typealias C_hid_t  C_int
typealias C_herr_t C_int
typealias C_hsize_t C_unsigned_long_long
typealias C_tri_t C_int
typealias C_H5T_sign_t C_int
typealias C_H5T_class_t C_int

hdf5_symbols = {:H5E_DEFAULT    => convert(C_int, 0),
                :H5P_DEFAULT    => convert(C_int, 0),
                # file access modes
                :H5F_ACC_RDONLY => convert(C_unsigned, 0x00),
                :H5F_ACC_RDWR   => convert(C_unsigned, 0x01),
                :H5F_ACC_TRUNC  => convert(C_unsigned, 0x02),
                :H5F_ACC_EXCL   => convert(C_unsigned, 0x04),
                :H5F_ACC_DEBUG  => convert(C_unsigned, 0x08),
                :H5F_ACC_CREAT  => convert(C_unsigned, 0x10),
                # object types (C enum H5Itype_t)
                :H5I_FILE => 1,
                :H5I_GROUP => 2,
                :H5I_DATATYPE => 3,
                :H5I_DATASPACE => 4,
                :H5I_DATASET => 5,
                :H5I_ATTR => 6,
                :H5I_REFERENCE => 7,
                # type classes (C enum H5T_class_t)
                :H5T_INTEGER => 0,
                :H5T_FLOAT => 1,
                :H5T_TIME => 2,
                :H5T_STRING => 3,
                :H5T_BITFIELD => 4,
                :H5T_OPAQUE => 5,
                :H5T_COMPOUND => 6,
                :H5T_REFERENCE => 7,
                :H5T_ENUM => 8,
                :H5T_VLEN => 9,
                :H5T_ARRAY => 10,
                # Sign types (C enum H5T_sign_t)
                :H5T_SGN_NONE => 0, ## unsigned
                :H5T_SGN_2 => 1, ## 2's complement
                }

## Julia types corresponding to the HDF5 base types
hdf5_type_map = {(hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_2],
                  1) => Int8,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_2],
                  2) => Int16,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_2],
                  4) => Int32,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_2],
                  8) => Int64,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_NONE],
                  1) => Uint8,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_NONE],
                  2) => Uint16,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_NONE],
                  4) => Uint32,
                 (hdf5_symbols[:H5T_INTEGER],
                  hdf5_symbols[:H5T_SGN_NONE],
                  8) => Uint64,
                 (hdf5_symbols[:H5T_FLOAT],
                  nothing,
                  4) => Float32,
                 (hdf5_symbols[:H5T_FLOAT],
                  nothing,
                  8) => Float64,
                 }

## Load the HDF5 wrapper library and disable automatic error printing.
hdf5lib = dlopen("hdf5_wrapper")
status = ccall(dlsym(hdf5lib, :H5Eset_auto2),
               C_herr_t,
               (C_hid_t, Ptr{Void}, Ptr{Void}),
               hdf5_symbols[:H5E_DEFAULT], C_NULL, C_NULL)
assert(status==0)


## HDF5 uses a plain integer to refer to each file, group, or
## dataset. These are wrapped into special types in order to allow
## method dispatch.

abstract HDF5Object

type HDF5File <: HDF5Object
   id::C_hid_t
   filename::String

   function HDF5File(id, filename)
       f = new(id, filename)
       finalizer(f, close)
       f
   end
end

type HDF5Group <: HDF5Object
   id::C_hid_t
   file::HDF5File

   function HDF5Group(id, file)
       g = new(id, file)
       finalizer(g, close)
       g
   end
end

type HDF5Dataset <: HDF5Object
   id::C_hid_t
   file::HDF5File

   function HDF5Dataset(id, file)
       ds = new(id, file)
       finalizer(ds, close)
       ds
   end
end

type HDF5NamedType <: HDF5Object
   id::C_hid_t
   file::HDF5File

   function HDF5NamedType(id, file)
       nt = new(id, file)
       finalizer(nt, close)
       nt
   end
end

## HDF5-specific exception type

type HDF5Exception <: Exception
   msg::String
   object::HDF5Object
end

## HDF5 has a generic "close" function that closes groups,
## datasets, and named types. That allows a single close method
## for everything exept files.

function close(object::HDF5Object)
    status = ccall(dlsym(hdf5lib, :H5Oclose),
                   C_herr_t,
                   (C_hid_t,),
                   object.id)
    if status < 0
        error(HDF5Exception("could not close HDF5 object", object))
    end
end

function close(file::HDF5File)
    status = ccall(dlsym(hdf5lib, :H5Fclose),
                   C_herr_t,
                   (C_hid_t,),
                   file.id)
    if status < 0
        error(HDF5Exception("could not close HDF5 file", file))
    end
end

## h5open is made to resemble open() from io.j. It incorporates
## the functionality of H5Fopen and H5Fcreate.

function h5open(fname::String, rd::Bool, wr::Bool, cr::Bool, tr::Bool)
    if !rd
        error("HDF5 files have no write-only mode")
    end
    if cr != tr
        error("Truncation and creation are identical for HDF5 files")
    end
    if cr && !rd
        error("Can't create a read-only HDF5 file")
    end
    if cr
        fid = ccall(dlsym(hdf5lib, :H5Fcreate),
                    C_hid_t,
                    (Ptr{C_char}, C_unsigned, C_hid_t, C_hid_t),
                    fname,
                    hdf5_symbols[:H5F_ACC_TRUNC],
                    hdf5_symbols[:H5P_DEFAULT],
                    hdf5_symbols[:H5P_DEFAULT])
    else
        fid = ccall(dlsym(hdf5lib, :H5Fopen),
                    C_hid_t,
                    (Ptr{C_char}, C_unsigned, C_hid_t),
                    fname,
                    wr ? hdf5_symbols[:H5F_ACC_RDWR] :
                         hdf5_symbols[:H5F_ACC_RDONLY],
                    hdf5_symbols[:H5P_DEFAULT])
    end
    if fid < 0
        error("could not open HDF5 file ", fname)
    end
    HDF5File(fid, fname)
end

function h5open(fname::String, mode::String)
    mode == "r"  ? h5open(fname, true,  false, false, false) :
    mode == "r+" ? h5open(fname, true,  true , false, false) :
    mode == "w"  ? h5open(fname, true,  true , true , true)  :
    mode == "w+" ? h5open(fname, true,  true , true , true)  :
    error("invalid open mode: ", mode)
end

h5open(fname::String) = h5open(fname, true, false, false, false)

function root_group(h5file::HDF5File)
    gid = ccall(dlsym(hdf5lib, :H5Gopen2),
                C_hid_t,
                (C_hid_t, Ptr{C_char}, C_hid_t),
                h5file.id, "/", hdf5_symbols[:H5P_DEFAULT])
    if gid < 0
        error(HDF5Exception("could not open root group in HDF5 file ", h5file))
    end
    HDF5Group(gid, h5file)
end

## Groups as sequences

function length(group::HDF5Group)
    nlinks = Array(C_hsize_t, 1)
    status = ccall(dlsym(hdf5lib, :jl_H5Gn_members),
                C_herr_t,
                (C_hid_t, Ptr{C_hsize_t}),
                group.id, nlinks)
    if status < 0
        error(HDF5Exception("could not obtain number of links", group))
    end
    nlinks[1]
end

function ref(group::HDF5Group, path::ASCIIString)
    obj_id = ccall(dlsym(hdf5lib, :H5Oopen),
                   C_hid_t,
                   (C_hid_t, Ptr{C_char}, C_hid_t),
                   group.id, path, hdf5_symbols[:H5P_DEFAULT])
    if obj_id < 0
        error(HDF5Exception("could not access path $path ", group))
    end
    obj_type = ccall(dlsym(hdf5lib, :H5Iget_type),
                     C_int,
                     (C_hid_t, ),
                     obj_id)
    obj_type == hdf5_symbols[:H5I_GROUP] ? HDF5Group(obj_id, group.file) :
    obj_type == hdf5_symbols[:H5I_DATATYPE] ? HDF5NamedType(obj_id, group.file) :
    obj_type == hdf5_symbols[:H5I_DATASET] ? HDF5Dataset(obj_id, group.file) :
    error(HDF5Exception("invalid object type for path $path ", group))
end

##start(g::HDF5Group) = 1
##done(g::HDF5Group, i) = (length(g) < i)
##next(g::HDF5Group, i) = (g[i], i+1)

## Make a file act like its root group
##convert(::Type{HDF5Group}, f::HDF5File) = root_group(f)
length(file::HDF5File) = length(root_group(file))
ref(file::HDF5File, path::ASCIIString) = ref(root_group(file), path)

## Datasets as arrays

function close_dataspace(id::C_hid_t)
    status = ccall(dlsym(hdf5lib, :H5Sclose),
                   C_herr_t,
                   (C_hid_t,),
                   id)
    if status < 0
        error(HDF5Exception("could not close HDF5 dataspace", id))
    end
end

function dataspace_id(ds::HDF5Dataset)
    space_id = ccall(dlsym(hdf5lib, :H5Dget_space),
                     C_hid_t,
                     (C_hid_t,),
                     ds.id)
    if space_id < 0
        error(HDF5Exception("could not open HDF5 dataspace", ds))
    end
    is_simple = ccall(dlsym(hdf5lib, :H5Sis_simple),
                      C_tri_t,
                      (C_hid_t,),
                      space_id)
    if is_simple <= 0   ## failure (negative) or false (0)
        close_dataspace(space_id)
        error(HDF5Exception("can't handle non-simple dataspace", ds))
    end
    space_id
end

function datatype(ds::HDF5Dataset)
    type_id = ccall(dlsym(hdf5lib, :H5Dget_type),
                    C_hid_t,
                    (C_hid_t,),
                    ds.id)
    if type_id < 0
        error(HDF5Exception("could not open HDF5 datatype", ds))
    end
    native_type_id = ccall(dlsym(hdf5lib, :H5Tget_native_type),
                           C_hid_t,
                           (C_hid_t, C_int),
                           type_id, convert(C_int, 0))
    type_class = ccall(dlsym(hdf5lib, :H5Tget_class),
                       C_H5T_class_t,
                       (C_hid_t, ),
                       native_type_id)
    type_size = ccall(dlsym(hdf5lib, :H5Tget_size),
                      C_size_t,
                      (C_hid_t, ),
                      native_type_id)
    if type_class == hdf5_symbols[:H5T_INTEGER]
        type_sign = ccall(dlsym(hdf5lib, :H5Tget_sign),
                          C_H5T_sign_t,
                          (C_hid_t, ),
                          native_type_id)
        println(type_sign)
    else
        type_sign = nothing
    end
    for id =[type_id, native_type_id]
        status = ccall(dlsym(hdf5lib, :H5Tclose),
                       C_herr_t,
                       (C_hid_t,),
                       id)
        if status < 0
            error(HDF5Exception("could not close HDF5 datatype", id))
        end
    end
    julia_type = nothing
    try
        julia_type = hdf5_type_map[(type_class, type_sign, type_size)]
    catch
        error(HDF5Exception("Datatype not yet implemented", ds))
    end
    julia_type
end

function ndims(ds::HDF5Dataset)
    space_id = dataspace_id(ds)
    numdims = ccall(dlsym(hdf5lib, :H5Sget_simple_extent_ndims),
                    C_int,
                    (C_hid_t,),
                    space_id)
    close_dataspace(space_id)
    numdims
end

function size(ds::HDF5Dataset)
    space_id = dataspace_id(ds)
    numdims = ccall(dlsym(hdf5lib, :H5Sget_simple_extent_ndims),
                    C_int,
                    (C_hid_t,),
                    space_id)
    dims = Array(C_hsize_t, numdims)
    numdims = ccall(dlsym(hdf5lib, :H5Sget_simple_extent_dims),
                    C_int,
                    (C_hid_t, Ptr{C_hsize_t}, Ptr{C_hsize_t}),
                    space_id, dims, C_NULL)
    close_dataspace(space_id)
    ntuple(numdims, i->dims[end-i+1])
end

size(ds::HDF5Dataset, d) = size(ds)[d]
length(ds::HDF5Dataset) = reduce(*, size(ds))

function array_space_id(data)
    dims = convert(Array{C_hsize_t,1}, [size(data)...][end:-1:1])
    ds_id = ccall(dlsym(hdf5lib, :H5Screate_simple),
                  C_hid_t,
                  (C_int, Ptr{C_hsize_t}, Ptr{C_hsize_t}),
                  length(dims), dims, dims)
    if ds_id < 0
        error("Couldn't create HDF5 dataspace")
    end
    ds_id
end

# The return value of array_type_id is am HDF5 type id that should
# not be closed.
function array_type_id(data)
    # This relies on linear indexing, which I don't really like, so I
    # hope there is another way to obtain the element type of an array.
    element_type = typeof(data[1])
    if element_type <: Integer
        type_class = 0
        if typemax(element_type) == 0
            is_signed = 0
        else
            is_signed = 1
        end
    elseif element_type <: Float
        type_class = 1
        is_signed = 1
    else
        error("datatype not yet supported")
    end
    
    type_id = ccall(dlsym(hdf5lib, :jl_HDF5_type_id),
                    C_hid_t,
                    (C_int, C_int, C_int),
                    type_class, sizeof(element_type), is_signed)
    if type_id < 0
        error("No matching HDF5 datatype")
    end
    type_id
end

function ref(ds::HDF5Dataset, indices...)
    space_id = dataspace_id(ds)
    ndims = ccall(dlsym(hdf5lib, :H5Sget_simple_extent_ndims),
                  C_int,
                  (C_hid_t,),
                  space_id)
    if length(indices) != ndims
        close_dataspace(space_id)
        error(HDF5Exception("wrong number of indices", ds))
    end
    
    dims = Array(C_hsize_t, ndims)
    ndims = ccall(dlsym(hdf5lib, :H5Sget_simple_extent_dims),
                  C_int,
                  (C_hid_t, Ptr{C_hsize_t}, Ptr{C_hsize_t}),
                  space_id, dims, C_NULL)

    selection_space_id = ccall(dlsym(hdf5lib, :H5Scopy),
                               C_hid_t,
                               (C_hid_t,),
                               space_id)
    close_dataspace(space_id)
    if selection_space_id < 0
        error(HDF5Exception("can't copy dataspace", ds))
    end

    ds_start = Array(C_hsize_t, ndims)
    ds_stride = Array(C_hsize_t, ndims)
    ds_count = Array(C_hsize_t, ndims)
    array_dims = ()
    for k = 1:ndims
        index = indices[ndims-k+1]
        if isa(index, Integer)
            ds_start[k] = index-1
            ds_stride[k] = 1
            ds_count[k] = 1
        elseif isa(index, Ranges)
            ds_start[k] = first(index)-1
            ds_stride[k] = step(index)
            ds_count[k] = length(index)
            array_dims = tuple(length(index), array_dims...)
        else
            close_dataspace(selection_space_id)
            error("index must be range or integer")
        end
        if ds_start[k] < 0 || ds_start[k]+ds_count[k]*ds_stride[k] > dims[k]
            close_dataspace(selection_space_id)
            error("index out of range")
        end
    end

    data = Array(datatype(ds), array_dims...)
    data_type_id = array_type_id(data)  ## don't close this one
    data_space_id = array_space_id(data)
    status = ccall(dlsym(hdf5lib, :H5Dread),
                   C_herr_t,
                   (C_hid_t, C_hid_t, C_hid_t, C_hid_t, C_hid_t, Ptr{Void}),
                   ds.id, data_type_id, data_space_id,
                   selection_space_id, hdf5_symbols[:H5P_DEFAULT], data)
    close_dataspace(data_space_id)
    if status < 0 
        error(HDF5Exception("read error", ds))
    end
    data
end

## Implementations of show()

function show(file::HDF5File)
    print("HDF5File('$(file.filename)')")
end

function show(group::HDF5Group)
    print("HDF5Group($(group.id), '$(group.file.filename)')")
end

function show(ds::HDF5Dataset)
    print("HDF5Dataset($(ds.id), '$(ds.file.filename)')")
end

function show(nt::HDF5NamedType)
    print("HDF5NamedType($(nt.id), '$(nt.file.filename)')")
end
