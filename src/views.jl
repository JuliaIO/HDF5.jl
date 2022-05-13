# Permit Base.view for Dataset and Attribute to normalize Base.copyto! syntax

# Long term consideration:
# If Dataset and Attribute become an AbstractArray, perhaps these should just be SubArrays ?
"""
    DatasetView

This is an experimental data type and may change. Use `view` rather than `DatasetView` directly.
"""
struct DatasetView
    parent::Dataset
    indices
end

function Base.view(obj::Dataset, I...)
    return DatasetView(obj, I)
end

Base.similar(view::DatasetView) = similar(view.parent, length.(view.indices)...)

"""
    AttributeView

This is an experimental data type and may change. Use `view` rather than `AttributeView` directly.
"""
struct AttributeView
    parent::Attribute
    indices
end

function Base.view(obj::Attribute, I...)
    return AttributeView(obj, I)
end

Base.similar(view::AttributeView) = similar(view.parent, length.(view.indices)...)

const DatasetOrAttributeView = Union{DatasetView, AttributeView}

function Base.copyto!(output_buffer::AbstractArray{T}, view::DatasetOrAttributeView) where T
    return Base.read!(view.parent, output_buffer, view.indices...)
end
