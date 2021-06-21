using HDF5, FileIO, Test

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
