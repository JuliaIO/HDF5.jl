module API

import Libdl
import ..HDF5
using Base: StringVector

const depsfile = joinpath(@__DIR__, "..", "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("HDF5 is not properly installed. Please run Pkg.build(\"HDF5\") ",
          "and restart Julia.")
end

# stub: methods defined in error.jl
macro h5error(msg)
  # Check if the is actually any errors on the stack. This is necessary as there are a
  # small number of functions which return `0` in case of an error, but `0` is also a
  # valid return value, e.g. `h5t_get_member_offset`

  # This needs to be a macro as we need to call `h5e_get_current_stack()` _before_
  # evaluating the message expression, as some message expressions can call API
  # functions, which would clear the error stack.
  quote
      err_id = h5e_get_current_stack()
      if h5e_get_num(err_id) > 0
          throw(HDF5.H5Error($(esc(msg)), err_id))
      else
          h5e_close_stack(err_id)
      end
  end
end

# Core API ccall wrappers
include("types.jl")
include("functions.jl")
include("helpers.jl")

end
