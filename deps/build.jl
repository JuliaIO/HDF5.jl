using BinDeps

@BinDeps.setup

# https://support.hdfgroup.org/HDF5/ lists "Current Releases"
# make sure we have one of those
const MINVERSION = v"1.8.0"
function h5_get_libversion(n, h)
    f = Libdl.dlsym_e(h, "H5get_libversion")
    majnum, minnum, relnum = Ref{Cuint}(), Ref{Cuint}(), Ref{Cuint}()
    status = ccall(f,Cint, (Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), majnum, minnum, relnum)
    status < 0 && error("Error getting HDF5 library version")
    VersionNumber(majnum[], minnum[], relnum[])
end
validate(n,h) = h5_get_libversion(n,h) > MINVERSION

if is_linux()
    hdf5 = library_dependency("libhdf5",
        aliases = ["libhdf5", "libhdf5_serial", "libhdf5_serial.so.10", "libhdf5_openmpi", "libhdf5_mpich"],
        validate = validate)
    provides(AptGet, "hdf5-tools", hdf5)
    provides(Pacman, "hdf5", hdf5)
    provides(Yum, "hdf5", hdf5)
end

if is_windows()
    using WinRPM
    hdf5 = library_dependency("libhdf5", validate = validate)
    provides(WinRPM.RPM, "hdf5", hdf5, os = :Windows )
end

if is_apple()
    using Homebrew
    hdf5 = library_dependency("libhdf5", validate = validate)
    provides(Homebrew.HB, "homebrew/science/hdf5", hdf5, os = :Darwin )
end

provides(Sources, URI("https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.0-patch1/src/hdf5-1.10.0-patch1.tar.gz"), hdf5)
provides(BuildProcess, Autotools(libtarget = joinpath("src", "libhdf5.la")), hdf5)

@BinDeps.install Dict(:libhdf5 => :libhdf5)
