using HDF5
using Test

"""
    Test Set create_dataset

Test the combination of arguments to create_dataset.
"""

@testset "create_dataset" begin
    mktemp() do fn, io
        h5open(fn, "w") do h5f
            h5g = create_group(h5f, "test_group")

            # Arguments
            #  Test file and group
            parents = (h5f, h5g)
            # Test anonymous dattaset, String, and SubString
            names = (nothing, "test_dataset", @view("test_dataset"[1:4]))
            # Test primitive, HDF5.Datatype, non-primitive, non-primitive HDF5.Datatype
            types = (UInt8, datatype(UInt8), Complex{Float32}, datatype(Complex{Float32}))
            # Test Tuple, HDF5.Dataspace, two tuples (extendible), extendible HDF5.Dataspace
            spaces = (
                (3, 4),
                dataspace((16, 16)),
                ((4, 4), (8, 8)),
                dataspace((16, 16); max_dims=(32, 32))
            )
            # TODO: test keywords

            # Create argument cross product
            p = Iterators.product(parents, names, types, spaces)

            for (parent, name, type, space) in p
                try
                    # create a chunked dataset since contiguous datasets are not extendible
                    ds = create_dataset(parent, name, type, space; chunk=(2, 2))
                    @test datatype(ds) == datatype(type)
                    @test dataspace(ds) == dataspace(space)
                    @test isvalid(ds)
                    close(ds)
                    if !isnothing(name)
                        # if it is not an anonymous dataset, try to open it
                        ds2 = open_dataset(parent, name)
                        @test isvalid(ds2)
                        close(ds2)
                        delete_object(parent, name)
                    end
                catch err
                    throw(ArgumentError("""
                        Error occured with (
                            $parent :: $(typeof(parent)),
                            $name :: $(typeof(name)),
                            $type :: $(typeof(type)),
                            $space :: $(typeof(space)))
                    """))
                end
            end
        end
    end
end
