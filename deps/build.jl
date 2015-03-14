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
    hdf5 = library_dependency("libhdf5")
    provides(WinRPM.RPM, "hdf5", hdf5, os = :Windows )
end

@osx_only begin
    using Homebrew
    hdf5 = library_dependency("libhdf5")
    provides(Homebrew.HB, "hdf5", hdf5, os = :Darwin )
end

@compat @BinDeps.install "HDF5" Dict(:libhdf5 => :libhdf5)
