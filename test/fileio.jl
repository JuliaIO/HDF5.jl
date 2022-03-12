using HDF5, OrderedCollections, FileIO, Test

@testset "fileio" begin
fn = tempname() * ".h5"

hfile = h5open(fn, "w")
hfile["A"] = 1.0
hfile["B"] = [1,2,3]
create_group(hfile, "G")
hfile["G/A"] = collect(-3:4)
create_group(hfile, "G1/G2")
hfile["G1/G2/A"] = "hello"
close(hfile);

# test loader
data = Dict("A" => 1.0, "B"=> [1,2,3], "G/A"=>collect(-3:4), "G1/G2/A"=>"hello")
@test load(fn) == data
@test load(fn, "A") == 1.0
@test load(fn, "A","B") == (1.0, [1,2,3])
@test load(fn, "G/A") == collect(-3:4)

rm(fn)

# test saver
save(fn, data)
@test load(fn) == data
@test load(fn, "A") == 1.0
fr = h5open(fn, "r")
read(fr, "A") == 1.0
close(fr)

rm(fn)
end

@testset "track order" begin
fn = tempname() * ".h5"

idx_type = HDF5.IDX_TYPE[]  # save
HDF5.IDX_TYPE[] = HDF5.API.H5_INDEX_CRT_ORDER

h5open(fn, "w"; track_order=true) do io
  fcpl = HDF5.get_create_properties(io)
  @test fcpl.track_order
  io["b"] = 1
  io["a"] = 2
  g = create_group(io, "G"; track_order=true)
  write(g, "c", 1)
  write(g, "a", 2)
end

d = OrderedDict()
h5open(fn, "r"; track_order=true) do io
  HDF5.loadtodict!(d, io)
end

@test all(keys(d) .== ["b", "a", "G/c", "G/a"])

HDF5.IDX_TYPE[] = idx_type  # restore
end
