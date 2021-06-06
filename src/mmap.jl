# Reading with mmap
ismmappable(::Type{<:ScalarType}) = true
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
            # TODO: Should check return value of h5f_get_driver()
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
        # returned by "h5f_get_vfd_handle" has
        # the correct format as required by the "fdio" function. The former
        # calls
        # https://gitlabext.iag.uni-stuttgart.de/libs/hdf5/blob/develop/src/H5FDcore.c#L1209
        #
        # The workaround is to create a new file handle, which should actually
        # not make any problems. Since we need to know the permissions of the
        # original file handle, we first retrieve them using the "h5f_get_intent"
        # function

        # Check permissions
        intent = API.h5f_get_intent(obj.file)
        flag = intent == API.H5F_ACC_RDONLY ? "r" : "r+"
        fd = open(obj.file.filename, flag)
    end

    offset = API.h5d_get_offset(obj)
    if offset % Base.datatype_alignment(T) == 0
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
