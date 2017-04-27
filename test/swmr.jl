# following https://support.hdfgroup.org/HDF5/doc/RM/RM_H5F.html#File-StartSwmrWrite
# and https://support.hdfgroup.org/HDF5/docNewFeatures/SWMR/Design-HDF5-SWMR-20130629.v5.2.pdf

if HDF5.libversion >= v"1.10.0"

if nprocs() == 1
  addprocs(1)
end
@everywhere using HDF5
using Base.Test


@testset "swmr" begin
fname = tempname()
@testset begin "h5d_oappend"
  h5open(fname,"w") do h5
  g = g_create(h5, "shoe")
  d = d_create(g,"bar", datatype(Float64), ((1,),(-1,)), "chunk", (100,))
  dxpl_id = HDF5.get_create_properties(d)
  v = [1.0,2.0]
  memtype = datatype(Float64).id
  # @test HDF5.h5d_oappend(d.id, dxpl_id, 0, length(v),memtype, v)
  end # do
end #testset

function dataset_write(d)
  for i=1:10
    set_dims!(d, (i*10,))
    inds = (1:10)+(i-1)*10
    inds, size(d)
    d[inds]=inds
    sleep(0.1)
    flush(d) # flush the dataset
  end
end

@everywhere function dataset_read(d)
  n=length(d)
  nbigger=0
  while n < 100
    sleep(0.02)
    HDF5.refresh(d)
    nlast,n=n,length(d)
    vals = read(d)
    n>1 && @assert vals == collect(1:n)
    n>nlast && (nbigger+=1)
  end
  return nbigger
end

@everywhere function swmr_reader(fname, startedchannel)
  h5open(fname,"r,swmr") do h5
  d=h5["foo"]
  put!(startedchannel,true)
  dataset_read(d)
  end
end

function remote_test(h5)
  startedchannel = RemoteChannel(1)
  a=@spawn(swmr_reader(fname,startedchannel))
  wait(startedchannel) # wait to make sure the reading process is ready
  dataset_write(h5["foo"])
  nbigger=fetch(a)
  @test nbigger==10
end

function prep_h5_file(h5)
  d = d_create(h5, "foo", datatype(Int), ((1,),(100,)), "chunk", (1,))
  attrs(h5)["bar"]="bar"
  g = g_create(h5, "group")
end

@testset "create libver swmr" begin
  h5open(fname, "w", "libver_bounds", (HDF5.H5F_LIBVER_LATEST, HDF5.H5F_LIBVER_LATEST)) do h5
  prep_h5_file(h5)
  HDF5.start_swmr_write(h5)
  remote_test(h5)
  end
end

@testset "create h5open swmr" begin
  h5open(fname, "w,swmr") do h5
  prep_h5_file(h5)
  end
  h5open(fname,"r+,swmr") do h5
  remote_test(h5)
  end
end

end #@testset "swmr"
end # if libversion
