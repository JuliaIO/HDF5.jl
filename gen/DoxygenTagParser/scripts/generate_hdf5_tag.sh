#!/usr/bin/env bash
# Generate the Doxygen hdf5.tag file that DoxygenTagParser uses to cross-reference
# HDF5 C API documentation from HDF5.jl docstrings.
#
# One-time setup (if cmake/doxygen/git are not already available):
#   curl -fsSL https://pixi.sh/install.sh | bash
#   pixi global install cmake doxygen git
#
# Usage:
#   ./generate_hdf5_tag.sh [hdf5-git-ref]
#
# hdf5-git-ref defaults to $HDF5_TAG_REF, or the tag below if that is unset.
# It must be a valid tag/branch name in https://github.com/HDFGroup/hdf5, e.g.
# hdf5_2.1.0, hdf5_1.14.6. Pick a ref covered by the HDF5_jll compat bounds in
# ../../Project.toml.
#
# The resulting tag file is written to ../hdf5.tag, which is where
# DoxygenTagParser.jl looks for it by default (see HDF5_TAG_URL).

set -euo pipefail

DEFAULT_HDF5_REF="hdf5_2.1.0"
HDF5_REF="${1:-${HDF5_TAG_REF:-${DEFAULT_HDF5_REF}}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARSER_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLONE_DIR="${SCRIPT_DIR}/hdf5"
BUILD_DIR="${CLONE_DIR}/build"
OUTPUT_TAG="${PARSER_DIR}/hdf5.tag"

for cmd in git cmake doxygen; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "error: '${cmd}' is required but was not found on PATH." >&2
        echo "       install it with, e.g.:" >&2
        echo "         curl -fsSL https://pixi.sh/install.sh | bash" >&2
        echo "         pixi global install cmake doxygen git" >&2
        exit 1
    fi
done

if [ -d "${CLONE_DIR}/.git" ]; then
    echo "Reusing existing clone at ${CLONE_DIR}, fetching ${HDF5_REF}"
    git -C "${CLONE_DIR}" fetch --depth 1 origin "${HDF5_REF}"
    git -C "${CLONE_DIR}" checkout --detach --force FETCH_HEAD
else
    echo "Cloning HDFGroup/hdf5 @ ${HDF5_REF} into ${CLONE_DIR}"
    git clone --depth 1 --branch "${HDF5_REF}" https://github.com/HDFGroup/hdf5.git "${CLONE_DIR}"
fi

JOBS="$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

echo "Configuring build (this regenerates the doxygen target if the ref changed)"
cmake -S "${CLONE_DIR}" -B "${BUILD_DIR}" -D HDF5_BUILD_DOC=ON

echo "Building doxygen docs with ${JOBS} jobs"
cmake --build "${BUILD_DIR}" --target doxygen --parallel "${JOBS}"

cp "${BUILD_DIR}/hdf5.tag" "${OUTPUT_TAG}"
echo "Wrote ${OUTPUT_TAG}"
