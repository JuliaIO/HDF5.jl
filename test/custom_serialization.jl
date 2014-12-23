module MyTypes

export MyType, MyContainer

## Objects we want to save
# data in MyType is always of length 5, and that is the basis for a more efficient serialization
immutable MyType{T}
    data::Vector{T}
    id::Int
    
    function MyType(v::Vector{T}, id::Integer)
        length(v) == 5 || error("All vectors must be of length 5")
        new(v, id)
    end
end
MyType{T}(v::Vector{T}, id::Integer) = MyType{T}(v, id)
Base.eltype{T}(::Type{MyType{T}}) = T
==(a::MyType, b::MyType) = a.data == b.data && a.id == b.id

immutable MyContainer{T}
    objs::Vector{MyType{T}}
end
Base.eltype{T}(::Type{MyContainer{T}}) = T
==(a::MyContainer, b::MyContainer) = length(a.objs) == length(b.objs) && all(i->a.objs[i]==b.objs[i], 1:length(a.objs))

end


### Here are the definitions needed to implement the custom serialization
# If you prefer, you could include these definitions in the MyTypes module
module MySerializer

using HDF5, JLD, MyTypes

## Defining the serialization format
type MyContainerSerializer{T}
    data::Matrix{T}
    ids::Vector{Int}
end
MyContainerSerializer{T}(data::Matrix{T},ids) = MyContainerSerializer{T}(data, ids)
Base.eltype{T}(::Type{MyContainerSerializer{T}}) = T
Base.eltype{T}(::MyContainerSerializer{T}) = T

JLD.readas(serdata::MyContainerSerializer) =
    MyContainer([MyType(serdata.data[:,i], serdata.ids[i]) for i = 1:length(serdata.ids)])
function JLD.writeas{T}(data::MyContainer{T})
    ids = [obj.id for obj in data.objs]
    n = length(data.objs)
    vectors = Array(T, 5, n)
    for i = 1:n
        vectors[:,i] = data.objs[i].data
    end
    MyContainerSerializer(vectors, ids)
end

end   # MySerializer



using MyTypes, JLD, Base.Test

obj1 = MyType(rand(5), 2)
obj2 = MyType(rand(5), 17)
container = MyContainer([obj1,obj2])
filename = joinpath(tempdir(), "customserializer.jld")
jldopen(filename, "w") do file
    write(file, "mydata", container)
end

container_r = jldopen(filename) do file
    obj = file["mydata"]
    dtype = JLD.datatype(obj.plain)
    @test JLD.jldatatype(JLD.file(obj), dtype) === MySerializer.MyContainerSerializer{Float64}
    read(file, "mydata")
end

@test container_r == container
