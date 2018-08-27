using BinDeps
using Libdl

@BinDeps.setup
# https://support.hdfgroup.org/HDF5/ lists "Current Releases"
# make sure we have one of those
const MINVERSION = v"1.8.0"
function h5_get_libversion(lib, handle)
    sym = Libdl.dlsym_e(handle, "H5get_libversion")
    majnum, minnum, relnum = Ref{Cuint}(), Ref{Cuint}(), Ref{Cuint}()
    status = ccall(sym, Cint, (Ptr{Cuint}, Ptr{Cuint}, Ptr{Cuint}), majnum, minnum, relnum)
    status < 0 && error("Error getting HDF5 library version")
    VersionNumber(majnum[], minnum[], relnum[])
end
compatible_version(lib, handle) = h5_get_libversion(lib, handle) >= MINVERSION

hdf5 = library_dependency("libhdf5",
    aliases = ["libhdf5_openmpi", "libhdf5_mpich", "libhdf5", "libhdf5_serial", "libhdf5_serial.so.10" ],
    validate=compatible_version)

provides(AptGet, "hdf5-tools", hdf5, os=:Linux)
provides(Pacman, "hdf5", hdf5, os=:Linux)
provides(Yum, "hdf5", hdf5, os=:Linux)
provides(BSDPkg, "hdf5", hdf5, os=:FreeBSD)

if Sys.iswindows()
    using WinRPM
    provides(WinRPM.RPM, "hdf5", hdf5, os=:Windows)
end

if Sys.isapple()
    using Homebrew
    provides(Homebrew.HB, "hdf5", hdf5, os=:Darwin)
end

provides(Sources, URI("https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.0-patch1/src/hdf5-1.10.0-patch1.tar.gz"), hdf5)
provides(BuildProcess, Autotools(libtarget=joinpath("src", "libhdf5.la")), hdf5)

@BinDeps.install Dict(:libhdf5 => :libhdf5)
