function h5open(filename::AbstractString, rd::Bool, wr::Bool, cr::Bool, tr::Bool, ff::Bool,
        cpl::HDF5Properties=DEFAULT_PROPERTIES, apl::HDF5Properties=DEFAULT_PROPERTIES)
    Base.depwarn("instead use  h5open(filename::AbstractString, mode::AbstractString,
cpl::HDF5Properties=DEFAULT_PROPERTIES, apl::HDF5Properties=DEFAULT_PROPERTIES; swmr=false)",:h5open)
    if ff && !wr
        error("HDF5 does not support appending without writing")
    end
    close_apl = false
    if apl.id == H5P_DEFAULT
        apl = p_create(H5P_FILE_ACCESS, false)
        close_apl = true
        # With garbage collection, the other modes don't make sense
        apl["fclose_degree"] = H5F_CLOSE_STRONG
    end
    if cr && (tr || !isfile(filename))
        fid = h5f_create(filename, H5F_ACC_TRUNC, cpl.id, apl.id)
    else
        if !h5f_is_hdf5(filename)
            error("This does not appear to be an HDF5 file")
        end
        fid = h5f_open(filename, wr ? H5F_ACC_RDWR : H5F_ACC_RDONLY, apl.id)
    end
    if close_apl
        # Close properties manually to avoid errors when the file is
        # closed before the properties are gc'ed
        close(apl)
    end
    HDF5File(fid, filename)
end
