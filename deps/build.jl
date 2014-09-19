using BinDeps 

@BinDeps.setup

@linux_only begin
    hdf5 = library_dependency("libhdf5", aliases = ["libhdf5_hl.so", "libhdf5_hl.so.8", "libhdf5_hl.so.8.0.2", "libhdf5.so", "libhdf5.so.8", "libhdf5.so.8.0.2
     
    provides(AptGet, "hdf5-tools", hdf5)
    provides(Yum, "hdf5", hdf5)

    julia_usrdir = normpath(JULIA_HOME*"/../") # This is a stopgap, we need a better builtin solution to get the included libraries
    libdirs = String["$(julia_usrdir)/lib"]
    includedirs = String["$(julia_usrdir)/include"]
    env = {"LIBS" => "-lz ", 
           "LD_LIBRARY_PATH" => join([libdirs[1];BinDeps.libdir(hdf5)],":")}
    provides(Sources, 
        URI("http://www.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.8.13.tar.gz"),
        SHA="82f6b38eec103b4fccfbf14892786e0c27a8135d3252d8601cf5bf20066d38c1",
        hdf5)
    provides( BuildProcess,
          Autotools(lib_dirs = libdirs,
                    include_dirs = includedirs,
                    env = env,
                    configure_options = ["--libdir=$(BinDeps.libdir(hdf5))"]),
          hdf5 )

    @BinDeps.install [:hdf5 => :hdf5]

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

@BinDeps.install [:libhdf5 => :libhdf5]
