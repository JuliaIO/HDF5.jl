load("hdf5.jl")

## Load an example data file from NASA's Earth Observing System
h5f = h5open("OMI.L2.CloudOMCLDO2Strip200kmAlongCloudSat.2011.06.22.050738Z.v003.he5")

## Indexing with HDF5 paths produces group or dataset objects.
dataset = h5f["HDFEOS/SWATHS/CloudFractionAndPressure/Data Fields/ChiSquaredOfFit"]

## Datasets are read by indexing them as if they were arrays.
data = dataset[1:end,1:end]

close(h5f)
