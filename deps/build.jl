using BinDeps 

@BinDeps.setup

@windows_only begin
    hdf5 = library_dependency("hdf5")

    const OS_ARCH = WORD_SIZE == 64 ? "x86_64" : "x86"

    if WORD_SIZE == 32
            provides(Binaries,URI("https://ia601003.us.archive.org/29/items/julialang/windows/hdf5-1.8-win32.7z"),hdf5,os = :Windows)
    else
            provides(Binaries,URI("https://ia601003.us.archive.org/29/items/julialang/windows/hdf5-1.8-win64.7z"),hdf5,os = :Windows)
    end
    push!(DL_LOAD_PATH, joinpath(Pkg.dir("HDF5/deps/usr/lib/"), OS_ARCH))
end

@BinDeps.install

