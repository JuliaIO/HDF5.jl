module OrderedCollectionsFileIOExt

import HDF5: _infer_track_order
@static if isdefined(Base, :get_extension)
    import OrderedCollections
else
    import ..OrderedCollections
end

function _infer_track_order(
    track_order::Union{Nothing,Bool}, dict::OrderedCollections.OrderedDict
)
    return something(track_order, true)
end

end
