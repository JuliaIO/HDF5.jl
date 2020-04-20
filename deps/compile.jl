using BinaryProvider
using CMakeWrapper: cmake_executable
using Libdl: dlext

function compile(libname, tarball_url, hash; prefix=BinaryProvider.global_prefix, verbose=false)
    # download to tarball_path
    tarball_path = joinpath(prefix, "downloads", "src.tar.gz")
    download_verify(tarball_url, hash, tarball_path; force=true, verbose=verbose)

    # unpack into source_path
    tarball_dir = joinpath(prefix, "downloads", dirname(first(list_tarball_files(tarball_path)))) # e.g. "hdf5-1.10.5"
    source_path = joinpath(prefix, "downloads", "src")
    verbose && @info("Unpacking $tarball_path into $source_path")
    rm(tarball_dir, force=true, recursive=true)
    rm(source_path, force=true, recursive=true)
    unpack(tarball_path, dirname(tarball_dir); verbose=verbose)
    mv(tarball_dir, source_path)

    build_dir = joinpath(source_path, "build")
    mkdir(build_dir)
    verbose && @info("Compiling in $build_dir...")
    cd(build_dir) do
        # build in parallel hdf5 mode if mpi is installed
        parallel_mode_flag = Sys.which("mpicc") !== nothing ? "ON" : "OFF"
        run(`$cmake_executable -DBUILD_TESTING:BOOL=OFF -DBUILD_SHARED_LIBS:BOOL=ON -DHDF5_BUILD_CPP_LIB:BOOL=OFF -DHDF5_BUILD_EXAMPLES:BOOL=OFF -DHDF5_ENABLE_PARALLEL:BOOL=$parallel_mode_flag ..`)
        run(`$cmake_executable --build . --config release -j $(Sys.CPU_THREADS + 1)`)
        mkpath(libdir(prefix))
        cp("bin/libhdf5.$dlext",       joinpath(libdir(prefix), libname*"."*dlext),       force=true, follow_symlinks=true)
        cp("bin/libhdf5_hl.$dlext",    joinpath(libdir(prefix), libname*"_hl."*dlext),    force=true, follow_symlinks=true)
        cp("bin/libhdf5_tools.$dlext", joinpath(libdir(prefix), libname*"_tools."*dlext), force=true, follow_symlinks=true)
    end
end
