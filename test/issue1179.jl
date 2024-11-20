using HDF5

T = ComplexF64
# T = Float64 # OK
sizes = (100, 100, 100)
Threads.@threads for i in 1:Threads.nthreads()
    h5open("file$i.hdf5", "w") do h5
        d = create_dataset(h5, "rand", T, sizes)
        for n in 1:sizes[3]
            d[:,:,n] = rand(T, sizes[1:2])
        end
    end
end