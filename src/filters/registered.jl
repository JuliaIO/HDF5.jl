"""
    HDF5.Filters.Registered

Module containing convenience methods to create `ExternalFilter` instances
of [HDF5 registered filters](https://portal.hdfgroup.org/display/support/Registered+Filter+Plugins).

This module does not implement any filter or guarantee filter availability.
Rather the functions within this module create `ExternalFilter` instances for convenience.
These instances can be used to determine if a filter is available. They can also
be incorporated as part of a filter pipeline.

Examine `REGISTERED_FILTERS`, a `Dict{H5Z_filter_t, Function}`, for a list of
filter functions contained within this module, which are exported.

```jldoctest
julia> println.(values(HDF5.Filters.Registered.REGISTERED_FILTERS));
FCIDECOMPFilter
LZOFilter
BitGroomFilter
SZ3Filter
Delta_RiceFilter
fpzipFilter
LPC_RiceFilter
LZFFilter
FLACFilter
VBZFilter
FAPECFilter
zfpFilter
CBFFilter
JPEG_XRFilter
LZ4Filter
BLOSC2Filter
ZstandardFilter
SZFilter
Granular_BitRoundFilter
JPEGFilter
SnappyFilter
B³DFilter
APAXFilter
BLOSCFilter
SPDPFilter
bitshuffleFilter
MAFISCFilter
BZIP2Filter
CCSDS_123Filter
JPEG_LSFilter
```

"""
module Registered

using HDF5.Filters:
    Filters, Filter, ExternalFilter, EXTERNAL_FILTER_JULIA_PACKAGES, isavailable
using HDF5.API: API, H5Z_filter_t, H5Z_FLAG_MANDATORY

const _REGISTERED_FILTERIDS_DICT = Dict{H5Z_filter_t,Symbol}(
    305 => :LZO,
    307 => :BZIP2,
    32000 => :LZF,
    32001 => :BLOSC,
    32002 => :MAFISC,
    32003 => :Snappy,
    32004 => :LZ4,
    32005 => :APAX,
    32006 => :CBF,
    32007 => :JPEG_XR,
    32008 => :bitshuffle,
    32009 => :SPDP,
    32010 => :LPC_Rice,
    32011 => :CCSDS_123,
    32012 => :JPEG_LS,
    32013 => :zfp,
    32014 => :fpzip,
    32015 => :Zstandard,
    32016 => :B³D,
    32017 => :SZ,
    32018 => :FCIDECOMP,
    32019 => :JPEG,
    32020 => :VBZ,
    32021 => :FAPEC,
    32022 => :BitGroom,
    32023 => :Granular_BitRound,
    32024 => :SZ3,
    32025 => :Delta_Rice,
    32026 => :BLOSC2,
    32027 => :FLAC
)

const REGISTERED_FILTERS = Dict{H5Z_filter_t,Function}()

for (filter_id, filter_name) in _REGISTERED_FILTERIDS_DICT
    fn_string = String(filter_name) * "Filter"
    fn = Symbol(fn_string)
    filter_name_string = replace(String(filter_name), "_" => raw"\_")
    @eval begin
        @doc """
            $($fn_string)(flags=API.H5Z_FLAG_MANDATORY, data::AbstractVector{<: Integer}=Cuint[], config::Cuint=0)
            $($fn_string)(flags=API.H5Z_FLAG_MANDATORY, data::Integer...)

        Create an [`ExternalFilter`](@ref) for $($filter_name_string) with filter id $($filter_id).
        $(haskey(EXTERNAL_FILTER_JULIA_PACKAGES, $filter_id) ?
            "Users are instead encouraged to use the Julia package $(EXTERNAL_FILTER_JULIA_PACKAGES[$filter_id])." :
            "Users should consider defining a subtype of [`Filter`](@ref) to specify the data."
        )

        # Fields / Arguments
        * `flags` -     (optional) bit vector describing general properties of the filter. Defaults to `API.H5Z_FLAG_MANDATORY`
        * `data` -      (optional) auxillary data for the filter. See [`cd_values`](@ref API.h5p_set_filter). Defaults to `Cuint[]`
        * `config` -    (optional) bit vector representing information about the filter regarding whether it is able to encode data, decode data, neither, or both. Defaults to `0`.

        See [`ExternalFilter`](@ref) for valid argument values.
        """ $fn
        export $fn
        $fn(flags, data::AbstractVector{<:Integer}) =
            ExternalFilter($filter_id, flags, Cuint.(data), $filter_name_string, 0)
        $fn(flags, data::Integer...) =
            ExternalFilter($filter_id, flags, Cuint[data...], $filter_name_string, 0)
        $fn(data::AbstractVector{<:Integer}=Cuint[]) = ExternalFilter(
            $filter_id, H5Z_FLAG_MANDATORY, Cuint.(data), $filter_name_string, 0
        )
        $fn(flags, data, config) =
            ExternalFilter($filter_id, flags, data, $filter_name_string, config)
        REGISTERED_FILTERS[$filter_id] = $fn
    end
end

"""
    available_registered_filters()::Dict{H5Z_filter_t, Function}

Return a `Dict{H5Z_filter_t, Function}` listing the available filter ids and
their corresponding convenience function.
"""
function available_registered_filters()
    filter(p -> isavailable(first(p)), REGISTERED_FILTERS)
end

end
