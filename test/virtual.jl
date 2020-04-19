fns = String[]
vds = tempname()
h5open(vds, "w") do fid
    layout = VirtualLayout((10, sum(1:5)), Float64)
    for i in 1:5
        fn = tempname()
        push!(fns, fn)
        h5open(fn, "w") do fid′
            fid′["x"] = rand(10, i)
        end
        off = sum(1:i-1)
        layout[:,  (off + 1):(off + i)] = VirtualSource(fn, "x")[:, :]
    end
    d_create_virtual(fid, "x", layout)
end
@test h5read(vds, "x", fclose_degree = 0) ≈ hcat([h5read(fn, "x") for fn in fns]...)
