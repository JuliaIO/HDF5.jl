OS = $(shell uname)

ifeq ($(OS), Linux)
SHLIB_EXT = so
endif

ifeq ($(OS), Darwin)
SHLIB_EXT = dylib
endif

hdf5_wrapper.$(SHLIB_EXT): hdf5_wrapper.c
	h5cc -O2 -shared -fPIC hdf5_wrapper.c -o hdf5_wrapper.$(SHLIB_EXT)
