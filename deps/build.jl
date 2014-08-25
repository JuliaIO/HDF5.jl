using BinDeps 

@BinDeps.setup

@linux_only begin
    hdf5 = library_dependency("libhdf5")
    provides(AptGet, "hdf5-tools", hdf5)
    provides(Yum, "hdf5", hdf5)
end

@windows_only begin
    hdf5 = library_dependency("libhdf5-0")

    provides(Binaries, URI("https://sourceforge.net/projects/mingw-w64-archlinux/files/x86_64/mingw-w64-hdf5-1.8.13-1-any.pkg.tar.xz"),
        hdf5, unpacked_dir = "usr/$(Sys.MACHINE)/bin", os = :Windows)

    push!(DL_LOAD_PATH, joinpath(dirname(@__FILE__), "usr", Sys.MACHINE, "bin"))
end

@osx_only begin
    using Homebrew
    hdf5 = library_dependency("libhdf5")
    provides( Homebrew.HB, "hdf5", hdf5, os = :Darwin )
end

@BinDeps.install
