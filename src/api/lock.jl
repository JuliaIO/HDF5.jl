const liblock = ReentrantLock()

# Try to acquire the lock (test-test-set) and close if successful
# Otherwise, defer finalization
# https://github.com/JuliaIO/HDF5.jl/issues/1048
function try_close_finalizer(x)
    if !islocked(liblock) && trylock(liblock) do
        close(x)
        true
    end
    else
        finalizer(try_close_finalizer, x)
    end
    return nothing
end
