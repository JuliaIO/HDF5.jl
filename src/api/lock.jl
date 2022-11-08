const liblock = ReentrantLock()

"""
    HDF5.API.use_api_lock::Bool

Julia compile time preference of whether to use a `ReentrantLock`. By default
the HDF5 C library is not thread-safe. Concurrent calls to the HDF5 library
from multiple threads will likely fail.
"""
const use_api_lock = Preferences.@load_preference("use_api_lock", default = true)

@static if !(use_api_lock isa Bool)
    error("""An unknown HDF5 `use_api_lock` preference of "$use_api_lock"
    was loaded. The `use_api_lock` will default to `true`.
    Use `HDF5.API.set_use_api_lock!(true)` to remove this warning.""")
end

"""
    HDF5.API.set_use_api_lock!(use_lock::Bool)

Set the compile time preference configuration whether to use a lock or not
when using multithreading.

Restarting Julia will be required for this preference to take effect since
the HDF5 package will need to be recompiled.

The valid values are `true` or `false`.

See also [`HDF5.API.get_use_api_lock`](@ref).
"""
function set_use_api_lock!(use_api_lock::Bool)
    @info "Please restart Julia for the use_lock preference to take effect"
    Preferences.@set_preferences!("use_api_lock" => use_api_lock)
end

"""
    get_use_api_lock()

Get the compile time preference configuration whether to use a lock or not
when using multithreading.

See [`HDF5.API.set_use_api_lock!`](@ref) for the definition of the values.
"""
function get_use_api_lock()
    return use_api_lock
end

"""
    HDF5.API.lock_and_close(obj)

Acquire HDF5.API.liblock before trying to close `obj`. This will always acquire
the lock regardless of the value of `HDF5.API.get_use_api_lock()`. It is
intended for use with finalizers.
"""
function lock_and_close(obj)
    lock(liblock)
    try
        close(obj)
    finally
        unlock(liblock)
    end
end
