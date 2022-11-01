const liblock = ReentrantLock()

"""
    HDF5.API.use_lock_pref::Symbol

Julia compile time preference of whether to use a `ReentrantLock`. By default
the HDF5 C library is not thread-safe. Concurrent calls to the HDF5 library
from multiple threads will likely fail.
"""
const use_lock_pref = Symbol(Preferences.@load_preference("use_api_lock", default = "sometimes"))

# _use_lock is for internal or debugging use only and will be ignored when use_lock_pref is :always or :never
@static if use_lock_pref == :always
    const _use_lock = Ref(true)

    """
        HDF5.API.use_lock() = true

    A lock will always be used regardless of the number of threads used as
    configured at compile time.

    See [`HDF.API.get_use_lock_pref`](@ref) and [`HDF5.API.set_use_lock_pref!`](@ref).
    """
    @inline use_lock() = true
 
elseif use_lock_pref == :never
    const _use_lock = Ref(false)

    """
        HDF5.API.use_lock() = false

    The use of a lock during multithreading has been disabled at compile time.

    See [`HDF.API.get_use_lock_pref`](@ref) and [`HDF5.API.set_use_lock_pref!`](@ref).
    """
    @inline use_lock() = false

else
    # The default is :sometimes, but warn if an unknown value is used.
    @static if use_lock_pref != :sometimes
        @warn """An unknown HDF5 `use_lock` preference of "$use_lock_pref"
        was loaded. The `use_lock` will default to `:sometimes`.
        Use `HDF5.API.set_use_lock_pref!(:sometimes)` to remove this warning."""
    end

    const _use_lock = Ref(true)

    """
        HDF5.API.use_lock()

    Determine whether to use a lock at runtime or not. This is called by each
    low-level API function in HDF5.API.

    By default, this will return `true` if `Threads.nthreads() > 1` and `false`
    otherwise.
    
    See [`HDF.API.get_use_lock_pref`](@ref) and [`HDF5.API.set_use_lock_pref!`](@ref).
    """
    @inline use_lock() = _use_lock[]
end

"""
    HDF5.API.set_use_lock_pref!(use_lock::Symbol)

Set the compile time preference configuration whether to use a lock or not
when using multithreading.

Restarting Julia will be required for this preference to take effect since
the HDF5 package will need to be recompiled.

There are three valid values.
* `:always`, A `ReentrantLock` is always used when calling a low-level API function.
* `:sometimes`, A `ReentrantLock` is used when using multithreading, e.g. `Threads.nthreads() > 1`.
* `:never`, A `RenntrantLock is only used with finalizers. The user is responsible for calling `lock(HDF5.API.liblock)`.

See also [`HDF5.API.get_use_lock_pref`](@ref).
"""
function set_use_lock_pref!(use_api_lock::Symbol)
    use_api_lock in (:always, :sometimes, :never) || error("The argument `use_lock` must be either `:always`, `:sometimes`, or `:never`.")
    @info "Please restart Julia for the use_lock preference to take effect"
    Preferences.@set_preferences!("use_api_lock" => string(use_api_lock))
end

"""
    get_use_lock_pref()

Get the compile time preference configuration whether to use a lock or not
when using multithreading.

See [`HDF5.API.set_use_lock_pref!`](@ref) for the definition of the values.
"""
function get_use_lock_pref()
    return use_lock_pref
end

"""
    HDF5.API.lock_and_close(obj)

Acquire HDF5.API.liblock before trying to close `obj`. This will always acquire
the lock regardless of the value of `HDF5.API.get_use_lock_pref()`. It is
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
