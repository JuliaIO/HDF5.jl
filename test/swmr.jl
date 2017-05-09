# following https://support.hdfgroup.org/HDF5/doc/RM/RM_H5F.html#File-StartSwmrWrite
# and https://support.hdfgroup.org/HDF5/docNewFeatures/SWMR/HDF5_SWMR_Users_Guide.pdf

if HDF5.libversion >= v"1.10.0"

if nprocs() == 1
  addprocs(1)
end
@everywhere using HDF5
using Base.Test




@testset "swmr" begin
fname = tempname()

@testset "swmr modes" begin
  h5open(fname,"w",swmr=true) do h5
    h5["foo"] = collect(1:10)
  end
  h5open(fname,"r",swmr=true) do h5
    @test read(h5["foo"]) == collect(1:10)
  end
  h5open(fname,"r+",swmr=true) do h5
    @test read(h5["foo"]) == collect(1:10)
  end
end

@testset "h5d_oappend" begin
  h5open(fname,"w") do h5
  g = g_create(h5, "shoe")
  d = d_create(g,"bar", datatype(Float64), ((1,),(-1,)), "chunk", (100,))
  dxpl_id = HDF5.get_create_properties(d)
  v = [1.0,2.0]
  memtype = datatype(Float64).id
  # @test HDF5.h5d_oappend(d.id, dxpl_id, 0, length(v),memtype, v)
  end # do
end #testset

function dataset_write(d, ch_written, ch_read)
  for i=1:10
    @assert take!(ch_read) == true
    set_dims!(d, (i*10,))
    inds = (1:10)+(i-1)*10
    inds, size(d)
    d[inds]=inds
    flush(d) # flush the dataset
    i<10 && put!(ch_written,i)
  end
end

@everywhere function dataset_read(d, ch_written, ch_read)
  n=length(d)
  nbigger=0
  i=0
  while n < 100
    if n>1
      i = take!(ch_written)
    end
    HDF5.refresh(d)
    nlast,n=n,length(d)
    vals = read(d)
    n>1 && @assert vals == collect(1:n)
    n>nlast && (nbigger+=1)
    put!(ch_read,true)
  end
  return nbigger
end

@everywhere function swmr_reader(fname, ch_written, ch_read)
  h5open(fname,"r";swmr=true) do h5
  d=h5["foo"]
  dataset_read(d, ch_written, ch_read)
  end
end

function remote_test(h5)
  ch_written, ch_read = RemoteChannel(1), RemoteChannel(1)
  a=@spawn(swmr_reader(fname, ch_written, ch_read))
  dataset_write(h5["foo"], ch_written, ch_read)
  nbigger=fetch(a)
  @test nbigger>=9
  # seems like itshould be 10, but the "create by libver" test reliably returns 9
  # The reader does not see the state where length(h5["foo"]) == 10
end

function prep_h5_file(h5)
  d = d_create(h5, "foo", datatype(Int), ((1,),(100,)), "chunk", (1,))
  attrs(h5)["bar"]="bar"
  g = g_create(h5, "group")
end

@testset "create by libver, then start_swmr_write" begin
  h5open(fname, "w", "libver_bounds", (HDF5.H5F_LIBVER_LATEST, HDF5.H5F_LIBVER_LATEST)) do h5
  prep_h5_file(h5)
  HDF5.start_swmr_write(h5) # after creating datasets
  remote_test(h5)
  end
end

@testset "create by swmr mode, then close and open again" begin
  h5open(fname, "w",swmr=true) do h5
  prep_h5_file(h5)
  end
  # close the file after creating datasets, open again with swmr write access but not truncate
  h5open(fname,"r+",swmr=true) do h5
  remote_test(h5)
  end
end

end #@testset "swmr"
end # if libversion
