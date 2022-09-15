# virtual dataset
struct VirtualMapping
  vspace::Dataspace
  srcfile::String
  srcdset::String
  srcspace::Dataspace
end

struct VirtualLayout <: AbstractVector{VirtualMapping}
  dcpl::DatasetCreateProperties
end

function Base.length(vlayout::VirtualLayout)
  return API.h5p_get_virtual_count(vlayout.dcpl)
end
Base.size(vlayout::VirtualLayout) = (length(vlayout),)

function Base.push!(vlayout::VirtualLayout, vmap::VirtualMapping)
  API.h5p_set_virtual(vlayout.dcpl, vmap.vspace, vmap.srcfile, vmap.srcdset, vmap.srcspace)
  return vlayout
end
function Base.append!(vlayout::VirtualLayout, vmaps)
  for vmap in vmaps
      push!(vlayout, vmap)
  end
  return vlayout
end

function Base.getindex(vlayout::VirtualLayout, i::Integer)
  vspace = Dataspace(API.h5p_get_virtual_vspace(vlayout.dcpl, i-1))
  srcfile = API.h5p_get_virtual_filename(vlayout.dcpl, i-1)
  srcdset = API.h5p_get_virtual_dsetname(vlayout.dcpl, i-1)
  srcspace = Dataspace(API.h5p_get_virtual_srcspace(vlayout.dcpl, i-1))
  return VirtualMapping(vspace, srcfile, srcdset, srcspace)
end

