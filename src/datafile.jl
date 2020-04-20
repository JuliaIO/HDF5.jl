################################
## Generic DataFile interface ##
################################
# This provides common methods that could be applicable to any
# interface for reading variables out of a file, e.g. HDF5,
# JLD, or MAT files. This is the super class of HDF5File, HDF5Group,
# JldFile, JldGroup, Matlabv5File, and MatlabHDF5File.
#
# Types inheriting from DataFile should have names, read, and write
# methods

abstract type DataFile end

import Base: read, write

# Convenience macros
macro read(fid, sym)
    if !isa(sym, Symbol)
        error("Second input to @read must be a symbol (i.e., a variable)")
    end
    esc(:($sym = read($fid, $(string(sym)))))
end
macro write(fid, sym)
    if !isa(sym, Symbol)
        error("Second input to @write must be a symbol (i.e., a variable)")
    end
    esc(:(write($fid, $(string(sym)), $sym)))
end

# Read a list of variables, read(parent, "A", "B", "x", ...)
read(parent::DataFile, name::String...) =
	tuple([read(parent, x) for x in name]...)

# Read one or more variables and pass them to a function. This is
# convenient for avoiding type inference pitfalls with the usual
# read syntax.
read(f::Base.Callable, parent::DataFile, name::String...) =
	f(read(parent, name...)...)

# Read every variable in the file
function read(f::DataFile)
    vars = names(f)
    vals = Vector{Any}(undef,length(vars))
    for i = 1:length(vars)
        vals[i] = read(f, vars[i])
    end
    Dict(zip(vars, vals))
end
