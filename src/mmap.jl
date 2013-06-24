module HDF5Mmap
using HDF5

import HDF5.write, HDF5.read, Base.mmap

type MmapHDF5File <: HDF5File
    id::HDF5.Hid
    filename::String
    toclose::Bool

    function MmapHDF5File(id, filename, toclose::Bool)
        f = new(id, filename, toclose)
        if toclose
            finalizer(f, close)
        end
        f
    end
end
mmap(f::HDF5File) = MmapHDF5File(f.id, f.filename, false)

function read{T<:HDF5.HDF5BitsKind}(obj::HDF5Dataset{MmapHDF5File}, ::Type{Array{T}})
    local fd
    prop = HDF5.h5d_get_create_plist(obj.id)
    try
        if HDF5.h5p_get_layout(prop) == HDF5.H5D_CHUNKED
            error("Cannot mmap chunked HDF5 arrays")
        end
    finally
        HDF5.h5p_close(prop)
    end

    prop = HDF5.h5d_get_access_plist(obj.id)
    try
        # TODO: Check that we will get file descriptor from driver
        #driver = h5p_get_driver(prop)
        ret = Ptr{Cint}[0]
        HDF5.h5f_get_vfd_handle(obj.file.id, prop, ret)
        fd = unsafe_load(ret[1])
    finally
        HDF5.h5p_close(prop)
    end
    
    offset = HDF5.h5d_get_offset(obj.id)
    if offset == uint64(-1)
        error("Cannot mmap array")
    end
    mmap_array(T, size(obj), fdio(fd), convert(FileOffset, offset))
end
read(obj::HDF5Dataset{MmapHDF5File}, T::Type) = read(plain(obj), T)
read(obj::HDF5Dataset{MmapHDF5File}) = read(obj, HDF5.hdf5_to_julia(obj))

write(f::MmapHDF5File, args...) = write(plain(f), args...)
end
