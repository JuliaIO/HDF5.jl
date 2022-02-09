# Windows specific methods

function win_setenv(key, value)
    ccall(:_wputenv_s, Cint, (Cwstring,Cwstring), key, value)
end
function win_sync_hdf5_plugin_path()
    # Fix https://github.com/JuliaIO/HDF5.jl/issues/905
    win_setenv("HDF5_PLUGIN_PATH", ENV["HDF5_PLUGIN_PATH"])
end
function win_sync_hdf5_env()
    # Issue #905, JuliaLang/julia#44054
    for (key, value) in ENV
        if startswith(key, "HDF5")
            win_setenv(key, value)
        end
    end
end

# We do this here since we load HDF5 during precompilation
win_sync_hdf5_env()