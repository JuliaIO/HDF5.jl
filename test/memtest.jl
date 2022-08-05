using HDF5
const PRINT_MEMORY = `ps -p $(getpid()) -o rss=`
const DATA = zeros(1000)
macro memtest(ex)
    @info :Memory
    quote
        for i in 1:100
            for _ in 1:100
                $ex
            end
            # HDF5.h5_garbage_collect()
            GC.gc()
            print(rpad(i, 8))
            run(PRINT_MEMORY)
        end
    end
end
@memtest h5open("/tmp/memtest.h5", "w") do file
    dset = create_dataset(file, "A", datatype(DATA), dataspace(DATA); chunk=(100,))
    dset[:] = DATA[:]
end
@memtest h5open("/tmp/memtest.h5", "w") do file
    file["A", chunk=(100,)] = DATA[:]
end
@memtest h5open("/tmp/memtest.h5", "r") do file
    file["A", "dxpl_mpio", 0]
end
