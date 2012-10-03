rawtypes_julia = {
    "Int8"    => Int8,
    "Uint8"   => Uint8,
    "Int16"   => Int16,
    "Uint16"  => Uint16,
    "Int32"   => Int32,
    "Uint32"  => Uint32,
    "Int64"   => Int64,
    "Uint64"  => Uint64,
    "Float32" => Float32,
    "Float64" => Float64,
    "Any"     => Any,
    "ByteString" => ByteString,
    "Array"   => Array,
}

function parse_braces(str::ByteString)
    chunks = Array(ByteString, 0)
    iend = length(str)
    istart = 1
    while str[iend] == '}'
        imatch, inext = search(str, '{', istart)
        if inext == 0 || inext > length(str)
            error("Unbalanced braces in typestring ", str)
        end
        push(chunks, str[istart:imatch-1])
        istart = inext
        iend -= 1
        if istart >= iend
            error("Empty inner string between braces in typestring ", str)
        end
    end
    push(chunks, str[istart:iend])
    chunks
end

function str2type_julia(str::ByteString)
    chunks = parse_braces(str)
    Tlist = split(chunks[end], ',')
    T = rawtypes_julia[chunks[end]]
    for i = length(chunks)-1:-1:1
        T = rawtypes_julia[chunks[i]]{T}
    end
    T
end

f2attr_typename = {:FORMAT_JULIA_V1 => "julia_type"}
f2typefunction = {:FORMAT_JULIA_V1 => str2type_julia}