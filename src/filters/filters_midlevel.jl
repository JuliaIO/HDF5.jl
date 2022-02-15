"""
    isavailable(filter_or_id)

Given a subtype of `Filters.Filter` or the filter ID number as an integer,
return `true` if the filter is available and `false` otherwise.
"""
isavailable(filter_or_id) = API.h5z_filter_avail(filter_or_id)

"""
    isencoderenabled(filter_or_id)

Given a subtype of `Filters.Filter` or the filter ID number as an integer,
return `true` if the filter can encode or compress data.
"""
function isencoderenabled(filter_or_id)
    info = API.h5z_get_filter_info(filter_or_id)
    return info & API.H5Z_FILTER_CONFIG_ENCODE_ENABLED != 0
end

"""
    isdecoderenabled(filter_or_id)

Given a subtype of `Filters.Filter` or the filter ID number as an integer,
return `true` if the filter can decode or decompress data.
"""
function isdecoderenabled(filter_or_id)
    info = API.h5z_get_filter_info(filter_or_id)
    return info & API.H5Z_FILTER_CONFIG_DECODE_ENABLED != 0
end
