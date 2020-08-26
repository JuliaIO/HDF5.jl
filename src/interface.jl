function _read(dset::DatasetOrAttribute, ::Type{T}) where T
  filetype = datatype(dset)
  memtype = HDF5Datatype(h5t_get_native_type(filetype.id))  # padded layout in memory
  close(filetype)

  if sizeof(T) != h5t_get_size(memtype.id)
    h5type_str = h5lt_dtype_to_text(memtype.id)
    error("""
          Type size mismatch
          sizeof($T) = $(sizeof(T))
          sizeof($h5type_str) = $(h5t_get_size(memtype.id))
          """)
  end

  dspace = dataspace(dset)
  stype = h5s_get_simple_extent_type(dspace.id)
  stype == H5S_NULL && return T[]

  if stype == H5S_SCALAR
    sz = (1,)
  else
    sz, _ = get_dims(dspace)
  end

  buf = Array{T}(undef, sz...)
  memspace = dataspace(buf)

  if dset isa HDF5Dataset
    h5d_read(dset.id, memtype.id, memspace.id, H5S_ALL, dset.xfer.id, buf)
  else
    h5a_read(dset.id, memtype.id, buf)
  end

  out = do_normalize(T) ? normalize_types.(buf) : buf

  xfer_id = dset isa HDF5Dataset ? dset.xfer.id : H5P_DEFAULT
  do_reclaim(T) && h5d_vlen_reclaim(memtype.id, memspace.id, xfer_id, buf)

  close(memtype)
  close(memspace)

  if stype == H5S_SCALAR
    return out[1]
  else
    return out
  end
end

# Read OPAQUE datasets and attributes
function _read(obj::DatasetOrAttribute, ::Type{HDF5Opaque})
    local buf
    local len
    local tag
    sz = size(obj)
    objtype = datatype(obj)
    try
        len = h5t_get_size(objtype)
        buf = Vector{UInt8}(undef,prod(sz)*len)
        tag = h5t_get_tag(objtype.id)
        readarray(obj, objtype.id, buf)
    finally
        close(objtype)
    end
    data = Array{Array{UInt8}}(undef,sz)
    for i = 1:prod(sz)
        data[i] = buf[(i-1)*len+1:i*len]
    end
    HDF5Opaque(data, tag)
end

function _get_jl_type(objtype)
  class_id = h5t_get_class(objtype.id)
  if class_id == H5T_OPAQUE
    return HDF5Opaque
  else
    return get_mem_compatible_jl_type(objtype)
  end
end

function _read(dset::DatasetOrAttribute)
  dtype = datatype(dset)
  T = _get_jl_type(dtype)
  _read(dset, T)
end
