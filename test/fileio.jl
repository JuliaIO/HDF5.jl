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

let fn = tempname() * ".h5"
  h5open(fn, "w"; track_order=true) do io
    fcpl = HDF5.get_create_properties(io)
    @test fcpl.track_order
    io["b"] = 1
    io["a"] = 2
    g = create_group(io, "G"; track_order=true)
    gcpl = HDF5.get_create_properties(io["G"])
    @test gcpl.track_order
    write(g, "z", 3)
    write(g, "f", 4)
  end

  dat = load(fn; dict=OrderedDict())  # `track_order` is inferred from `OrderedDict`

  @test all(keys(dat) .== ["b", "a", "G/z", "G/f"])
end

let fn = tempname() * ".h5"
  save(fn, OrderedDict("b"=>1, "a"=>2, "G/z"=>3, "G/f"=>4))

  dat = load(fn; dict=OrderedDict())

  @test all(keys(dat) .== ["b", "a", "G/z", "G/f"])
end

end
