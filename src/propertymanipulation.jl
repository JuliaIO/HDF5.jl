### Property manipulation ###
get_access_properties(d::Dataset)   = DatasetAccessProperties(API.h5d_get_access_plist(d))
get_access_properties(f::File)      = FileAccessProperties(API.h5f_get_access_plist(f))
get_create_properties(d::Dataset)   = DatasetCreateProperties(API.h5d_get_create_plist(d))
get_create_properties(g::Group)     = GroupCreateProperties(API.h5g_get_create_plist(g))
get_create_properties(f::File)      = FileCreateProperties(API.h5f_get_create_plist(f))
get_create_properties(a::Attribute) = AttributeCreateProperties(API.h5a_get_create_plist(a))
