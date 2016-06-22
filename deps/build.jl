using BinDeps, Compat

@BinDeps.setup

@linux_only begin
    hdf5 = library_dependency("libhdf5", aliases = ["libhdf5", "libhdf5_serial", "libhdf5_openmpi", "libhdf5_mpich"])
    provides(AptGet, "hdf5-tools", hdf5)
    provides(Pacman, "hdf5", hdf5)
    provides(Yum, "hdf5", hdf5)
end

@windows_only begin
    using WinRPM
    hdf5 = library_dependency("libhdf5", aliases = ["hdf5_w64", "hdf5"])
    provides(WinRPM.RPM, "hdf5", hdf5, os = :Windows )
end

@osx_only begin
    using Homebrew
    hdf5 = library_dependency("libhdf5")
    provides(Homebrew.HB, "hdf5", hdf5, os = :Darwin )
end

provides(Sources, URI("http://www.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.0-patch1/src/hdf5-1.10.0-patch1.tar.gz"), hdf5)
provides(BuildProcess, Autotools(libtarget = "libhdf5.la"), hdf5)

@compat @BinDeps.install Dict(:libhdf5 => :libhdf5)
