# roughly following https://support.hdfgroup.org/ftp/HDF5/examples/110/h5_vds.c
using HDF5

basedir = mktempdir()
FILE = "vds.h5"
DATASET = "VDS"
VDSDIM0 = 4
VDSDIM1 = 6
DIM0 = 6
SRC_FILE = ["a.h5","b.h5","c.h5"]
SRC_DATASET = ["A","B","C"]
vdsdims = [VDSDIM0, VDSDIM1]
dims = [DIM0]

for i=1:3
    src_file = h5open(SRC_FILE[i],"w")
    src_file[SRC_DATASET[i]] = collect((i-1)*6+(1:6))
    close(src_file)
end

vfile = h5open(FILE,"w")

space = dataspace(VDSDIM0, VDSDIM1)
dcpl = HDF5.h5p_create(HDF5.H5P_DATASET_CREATE)
count = [1, 1]
block = [VDSDIM1, 1]

# watch out!! dataspace(5) creates a scalar dataspace, not a length 5 one dimensional dataspace
src_space = dataspace((DIM0,))
for i=1:3
    start=[0, i-1]
    HDF5.h5s_select_hyperslab(space, HDF5.H5S_SELECT_SET, start, C_NULL, count, block)
    HDF5.h5p_set_virtual(dcpl, space, SRC_FILE[i], SRC_DATASET[i], src_space)
end

space = dataspace(VDSDIM0, VDSDIM1)
dset = HDF5.h5d_create(vfile.id, DATASET, HDF5.H5T_NATIVE_INT64, space, HDF5.H5P_DEFAULT, dcpl, HDF5.H5P_DEFAULT)
close(space)
close(src_space)
HDF5.h5d_close(dset)
close(vfile)
HDF5.h5p_close(dcpl)
