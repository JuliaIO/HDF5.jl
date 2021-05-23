module HDF5

using Base: unsafe_convert, StringVector
using Requires: @require
# needed for filter(f, tuple) in julia 1.3
using Compat

import Libdl
import Mmap

### PUBLIC API ###

export
@read, @write,
h5open, h5read, h5write, h5rewrite, h5writeattr, h5readattr,
create_attribute, open_attribute, read_attribute, write_attribute, delete_attribute, attributes,
create_dataset, open_dataset, read_dataset, write_dataset,
create_group, open_group,
copy_object, open_object, delete_object,
create_datatype, commit_datatype, open_datatype,
create_property,
group_info, object_info,
dataspace, datatype

### The following require module scoping ###

# file, filename, name,
# get_chunk, get_datasets,
# get_access_properties, get_create_properties,
# root, readmmap, set_dims!,
# iscontiguous, iscompact, ischunked,
# ishdf5, ismmappable,
# refresh
# start_swmr_write
# create_external, create_external_dataset

### Types
# H5DataStore, Attribute, File, Group, Dataset, Datatype, Opaque,
# Dataspace, Object, Properties, VLen, ChunkStorage, Reference


const depsfile = joinpath(dirname(@__DIR__), "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
          "and restart Julia.")
end

# Core API ccall wrappers
include("api_types.jl")
include("api.jl")
include("api_helpers.jl")

include("properties.jl")
include("file.jl")
include("group.jl")
include("datatype.jl")
include("dataspace.jl")
include("dataset.jl")
include("object.jl")
include("attribute.jl")
include("typeconversions.jl")
include("show.jl")
include("blosc_filter.jl")
include("interface.jl")
include("mmap.jl")
include("chunked.jl")

include("api_midlevel.jl")



const libversion = h5_get_libversion()

const HAS_PARALLEL = Ref(false)

"""
    has_parallel()

Returns `true` if the HDF5 libraries were compiled with parallel support,
and if parallel functionality was loaded into HDF5.jl.

For the second condition to be true, MPI.jl must be imported before HDF5.jl.
"""
has_parallel() = HAS_PARALLEL[]

function __init__()
    check_deps()

    # disable file locking as that can cause problems with mmap'ing
    if !haskey(ENV, "HDF5_USE_FILE_LOCKING")
        ENV["HDF5_USE_FILE_LOCKING"] = "FALSE"
    end

    register_blosc()

    # Turn off automatic error printing
    # h5e_set_auto(H5E_DEFAULT, C_NULL, C_NULL)

    ASCII_LINK_PROPERTIES[] = create_property(H5P_LINK_CREATE; char_encoding = H5T_CSET_ASCII,
                                       create_intermediate_group = 1)
    UTF8_LINK_PROPERTIES[]  = create_property(H5P_LINK_CREATE; char_encoding = H5T_CSET_UTF8,
                                       create_intermediate_group = 1)
    ASCII_ATTRIBUTE_PROPERTIES[] = create_property(H5P_ATTRIBUTE_CREATE; char_encoding = H5T_CSET_ASCII)
    UTF8_ATTRIBUTE_PROPERTIES[]  = create_property(H5P_ATTRIBUTE_CREATE; char_encoding = H5T_CSET_UTF8)

    @require MPI="da04e1cc-30fd-572f-bb4f-1f8673147195" @eval include("mpio.jl")

    return nothing
end

include("deprecated.jl")

end  # module
