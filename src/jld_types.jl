# Controls whether tuples and non-pointerfree immutables, which Julia
# stores as references, are stored inline in compound types when
# possible. Currently this is problematic because Julia fields of these
# types may be undefined.
const INLINE_TUPLE = false
const INLINE_POINTER_IMMUTABLE = false

const JLD_REF_TYPE = JldDatatype(HDF5Datatype(HDF5.H5T_STD_REF_OBJ, false), -1)
const BUILTIN_TYPES = Set([Symbol, Type])

# Holds information about the mapping between a Julia and HDF5 type
immutable JldTypeInfo
    dtypes::Vector{JldDatatype}
    offsets::Vector{Int}
    size::Int
end

# Get information about the HDF5 type corresponding to a Julia type
function JldTypeInfo(parent::JldFile, types::(Type...))
    dtypes = Array(JldDatatype, length(types))
    offsets = Array(Int, length(types))
    offset = 0
    for i = 1:length(types)
        dtype = dtypes[i] = h5fieldtype(parent, types[i])
        offsets[i] = offset
        offset += HDF5.h5t_get_size(dtype)
    end
    JldTypeInfo(dtypes, offsets, offset)
end
JldTypeInfo(parent::JldFile, T::ANY) = JldTypeInfo(parent, T.types)

## Convert between Julia and HDF5
# Definitions for basic types

# HDF5 bits kinds
h5convert!{T<:HDF5.HDF5BitsKind}(out::Ptr, ::JldFile, x::T, ::JldWriteSession) =
    unsafe_store!(convert(Ptr{T}, out), x)

_jlconvert_bits{T}(::Type{T}, ptr::Ptr) = unsafe_load(convert(Ptr{T}, ptr))
_jlconvert_bits!{T}(out::Ptr, ::Type{T}, ptr::Ptr) =
    (unsafe_store!(convert(Ptr{T}, out), unsafe_load(convert(Ptr{T}, ptr))); nothing)

jlconvert{T<:HDF5.HDF5BitsKind}(::Type{T}, ::JldFile, ptr::Ptr) = _jlconvert_bits(T, ptr)
jlconvert!{T<:HDF5.HDF5BitsKind}(out::Ptr, ::Type{T}, ::JldFile, ptr::Ptr) = _jlconvert_bits!(out, T, ptr)

# ByteStrings
h5convert!(out::Ptr, ::JldFile, x::ByteString, ::JldWriteSession) =
    unsafe_store!(convert(Ptr{Ptr{Uint8}}, out), pointer(x))
function jlconvert{T<:ByteString}(::Type{T}, ::JldFile, ptr::Ptr)
    strptr = unsafe_load(convert(Ptr{Ptr{Uint8}}, ptr))
    n = int(ccall(:strlen, Csize_t, (Ptr{Uint8},), strptr))
    T(pointer_to_array(strptr, (n,), true))
end

# UTF16Strings
h5convert!(out::Ptr, ::JldFile, x::UTF16String, ::JldWriteSession) =
    unsafe_store!(convert(Ptr{HDF5.Hvl_t}, out), HDF5.Hvl_t(length(x.data), pointer(x.data)))
function jlconvert(::Type{UTF16String}, ::JldFile, ptr::Ptr)
    hvl = unsafe_load(convert(Ptr{HDF5.Hvl_t}, ptr))
    UTF16String(pointer_to_array(convert(Ptr{Uint16}, hvl.p), hvl.len, true))
end

# Symbols
function h5convert!(out::Ptr, file::JldFile, x::Symbol, wsession::JldWriteSession)
    str = string(x)
    push!(wsession.persist, str)
    h5convert!(out, file, str, wsession)
end
jlconvert(::Type{Symbol}, file::JldFile, ptr::Ptr) = symbol(jlconvert(UTF8String, file, ptr))

# Types
function h5convert!(out::Ptr, file::JldFile, x::Type, wsession::JldWriteSession)
    str = full_typename(file, x)
    push!(wsession.persist, str)
    h5convert!(out, file, str, wsession)
end
jlconvert(::Type{Type}, file::JldFile, ptr::Ptr) = julia_type(jlconvert(UTF8String, file, ptr))

## Get corresponding HDF5Datatype for a specific type

# HDF5BitsKinds are also HDF5BitsKind
h5fieldtype{T<:HDF5.HDF5BitsKind}(parent::JldFile, ::Type{T}) =
    JldDatatype(HDF5Datatype(HDF5.hdf5_type_id(T), false), -1)

# ByteString types are variable length strings
function h5fieldtype{T<:ByteString}(parent::JldFile, ::Type{T})
    type_id = HDF5.h5t_copy(HDF5.hdf5_type_id(T))
    HDF5.h5t_set_size(type_id, HDF5.H5T_VARIABLE)
    HDF5.h5t_set_cset(type_id, HDF5.cset(T))
    JldDatatype(HDF5Datatype(type_id, false), -1)
end

# UTF16Strings are stored as compound types that contain a vlen
h5fieldtype(parent::JldFile, ::Type{UTF16String}) = h5type(parent, UTF16String)

# Symbols and types are stored as compound types that contain a
# variable length string
h5fieldtype(parent::JldFile, ::Type{Symbol}) = h5type(parent, Symbol)
h5fieldtype{T<:Type}(parent::JldFile, ::Type{T}) = h5type(parent, Type)

# Arrays are references
# These show up as having T.size == 0, hence the need for specialization
h5fieldtype{T,N}(parent::JldFile, ::Type{Array{T,N}}) = JLD_REF_TYPE

if INLINE_TUPLE
    h5fieldtype(parent::JldFile, T::(Type...)) =
        isleaftype(T) ? h5type(parent, T) : JLD_REF_TYPE
    h5fieldtype(parent::JldFile, T::Tuple) =
        isleaftype(T) ? h5type(parent, T) : JLD_REF_TYPE
else
    h5fieldtype(parent::JldFile, T::(Type...)) = JLD_REF_TYPE
    h5fieldtype(parent::JldFile, T::Tuple) = JLD_REF_TYPE
end

# For cases not defined above: If the type is mutable and non-empty,
# this is a reference. If the type is immutable, this is a type itself.
if INLINE_POINTER_IMMUTABLE
    h5fieldtype(parent::JldFile, T::ANY) =
        isleaftype(T) && (!T.mutable || T.size == 0) ? h5type(parent, T) : JLD_REF_TYPE
else
    h5fieldtype(parent::JldFile, T::ANY) =
        isleaftype(T) && (!T.mutable || T.size == 0) && T.pointerfree ? h5type(parent, T) : JLD_REF_TYPE
end

h5fieldtype(parent::JldGroup, x) = h5fieldtype(file(parent), x)

# Write an HDF5 datatype to the file
function commit_datatype(parent::JldFile, dtype::HDF5Datatype, T::ANY)
    # Write to HDF5 file
    pparent = parent.plain
    if !exists(pparent, pathtypes)
        gtypes = g_create(pparent, pathtypes)
    else
        gtypes = pparent[pathtypes]
    end

    id = length(gtypes)+1
    try
        HDF5.t_commit(gtypes, @sprintf("%08d", id), dtype)
    finally
        close(gtypes)
    end
    a_write(dtype, name_type_attr, full_typename(parent, T))

    # Store in map
    parent.jlh5type[T] = JldDatatype(dtype, id)
end

# The HDF5 library loses track of relationships among committed types
# after the file is saved. We mangle the names by appending a
# sequential identifier so that we can recover these relationships
# later.
mangle_name(jtype::JldDatatype, jlname) =
    jtype.index <= 0 ? string(jlname, "_") : string(jlname, "_", jtype.index)
Base.convert(::Type{HDF5.Hid}, x::JldDatatype) = x.dtype.id

# Implement h5convert! to convert from Julia to HDF5 representation for
# a given JldTypeInfo and Julia type
function gen_h5convert!(typeinfo::JldTypeInfo, T::ANY)
    method_exists(h5convert!, (Ptr, JldFile, T, JldWriteSession)) && return

    istuple = isa(T, Tuple)
    types = istuple ? T : T.types
    getindex_fn = istuple ? (:getindex) : (:getfield)
    ex = Expr(:block)
    args = ex.args
    for i = 1:length(typeinfo.dtypes)
        offset = typeinfo.offsets[i]
        if HDF5.h5t_get_class(typeinfo.dtypes[i]) == HDF5.H5T_REFERENCE
            if istuple
                push!(args, :(unsafe_store!(convert(Ptr{HDF5ReferenceObj}, out)+$offset,
                                            write_ref(file, $getindex_fn(x, $i), wsession))))
            else
                push!(args, quote
                    if isdefined(x, $i)
                        ref = write_ref(file, $getindex_fn(x, $i), wsession)
                    else
                        ref = HDF5.HDF5ReferenceObj_NULL
                    end
                    unsafe_store!(convert(Ptr{HDF5ReferenceObj}, out)+$offset, ref)
                end)
            end
        else
            push!(args, :(h5convert!(out+$offset, file, $getindex_fn(x, $i), wsession)))
        end
    end
    @eval h5convert!(out::Ptr, file::JldFile, x::$T, wsession::JldWriteSession) = ($ex; nothing)
    nothing
end

## jlconvert/jlconvert!
# Converts from HDF5 to Julia representation for a given JldTypeInfo
# and Julia type. The mutating version is only available for bits
# types.

uses_reference(T::DataType) = !T.pointerfree
uses_reference(::Tuple) = true

# Tuples
function gen_jlconvert(typeinfo::JldTypeInfo, T::(Type...))
    method_exists(jlconvert, (Type{T}, JldFile, Ptr)) && return

    ex = Expr(:block)
    args = ex.args
    tup = Expr(:tuple)
    tupargs = tup.args
    for i = 1:length(typeinfo.dtypes)
        h5offset = typeinfo.offsets[i]
        field = symbol(string("field", i))

        if HDF5.h5t_get_class(typeinfo.dtypes[i]) == HDF5.H5T_REFERENCE
            push!(args, :($field = read_ref(file, unsafe_load(convert(Ptr{HDF5ReferenceObj}, ptr)+$h5offset))))
        else
            push!(args, :($field = jlconvert($(T[i]), file, ptr+$h5offset)))
        end
        push!(tupargs, field)
    end
    @eval jlconvert(::Type{$T}, file::JldFile, ptr::Ptr) = ($ex; $tup)
    nothing
end

# Normal objects
function _gen_jlconvert_type(typeinfo::JldTypeInfo, T::ANY)
    ex = Expr(:block)
    args = ex.args
    for i = 1:length(typeinfo.dtypes)
        h5offset = typeinfo.offsets[i]

        if HDF5.h5t_get_class(typeinfo.dtypes[i]) == HDF5.H5T_REFERENCE
            push!(args, quote
                ref = unsafe_load(convert(Ptr{HDF5ReferenceObj}, ptr)+$h5offset)
                if ref != HDF5.HDF5ReferenceObj_NULL
                    out.$(T.names[i]) = read_ref(file, ref)::$(T.types[i])
                end
            end)
        else
            push!(args, :(out.$(T.names[i]) = jlconvert($(T.types[i]), file, ptr+$h5offset)))
        end
    end
    @eval function jlconvert(::Type{$T}, file::JldFile, ptr::Ptr)
        out = ccall(:jl_new_struct_uninit, Any, (Any,), $T)::$T
        $ex
        out
    end
    nothing
end

# Immutables
function _gen_jlconvert_immutable(typeinfo::JldTypeInfo, T::ANY)
    ex = Expr(:block)
    args = ex.args
    jloffsets = fieldoffsets(T)
    for i = 1:length(typeinfo.dtypes)
        h5offset = typeinfo.offsets[i]
        jloffset = jloffsets[i]

        if HDF5.h5t_get_class(typeinfo.dtypes[i]) == HDF5.H5T_REFERENCE
            obj = gensym("obj")
            push!(args, quote
                ref = unsafe_load(convert(Ptr{HDF5ReferenceObj}, ptr)+$h5offset)
                local $obj # must keep alive to prevent collection
                if ref == HDF5.HDF5ReferenceObj_NULL
                    unsafe_store!(convert(Ptr{Int}, out)+$jloffset, 0)
                else
                    $obj = read_ref(file, ref)
                    unsafe_store!(convert(Ptr{Ptr{Void}}, out)+$jloffset, pointer_from_objref($obj))
                end
            end)
        elseif uses_reference(T.types[i])
            # Tuple fields and non-pointerfree immutables are stored
            # inline by JLD if INLINE_TUPLE/INLINE_POINTER_IMMUTABLE is
            # true, but not by Julia
            obj = gensym("obj")
            push!(args, quote
                obj = jlconvert($(T.types[i]), file, ptr+$h5offset)
                unsafe_store!(convert(Ptr{Ptr{Void}}, out)+$jloffset, pointer_from_objref(obj))
            end)
        else
            push!(args, :(jlconvert!(out+$jloffset, $(T.types[i]), file, ptr+$h5offset)))
        end
    end
    @eval begin
        jlconvert!(out::Ptr, ::Type{$T}, file::JldFile, ptr::Ptr) = ($ex; nothing)
        $(
        if T.pointerfree
            quote
                function jlconvert(::Type{$T}, file::JldFile, ptr::Ptr)
                    out = Array($T, 1)
                    jlconvert!(pointer(out), $T, file, ptr)
                    out[1]
                end
            end
        else
            # XXX can this be improved?
            quote
                function jlconvert(::Type{$T}, file::JldFile, ptr::Ptr)
                    out = ccall(:jl_new_struct_uninit, Any, (Any,), $T)::$T
                    jlconvert!(pointer_from_objref(out)+sizeof(Int), $T, file, ptr)
                    out
                end
            end
        end
        )
    end
    nothing
end

# Dispatch for non-tuple types
function gen_jlconvert(typeinfo::JldTypeInfo, T::ANY)
    method_exists(jlconvert, (Type{T}, JldFile, Ptr)) && return

    if isempty(T.names)
        if T.size == 0
            @eval begin
                jlconvert(::Type{$T}, ::JldFile, ::Ptr) = $T()
                jlconvert!(::Ptr, ::Type{$T}, ::JldFile, ::Ptr) = nothing
            end
        else
            @eval begin
               jlconvert(::Type{$T}, ::JldFile, ptr::Ptr) =  _jlconvert_bits($T, ptr)
               jlconvert!(out::Ptr, ::Type{$T}, ::JldFile, ptr::Ptr) =  _jlconvert_bits!(out, $T, ptr)
            end
        end
        nothing
    elseif T.mutable
        _gen_jlconvert_type(typeinfo, T)
    else
        _gen_jlconvert_immutable(typeinfo, T)
    end
end

h5type{T<:Ptr}(parent::JldFile, ::Type{T}) = throw(PointerException())

# Construct HDF5 type corresponding to Symbol
function h5type(parent::JldFile, ::Type{Symbol})
    haskey(parent.jlh5type, Symbol) && return parent.jlh5type[Symbol]
    id = HDF5.h5t_create(HDF5.H5T_COMPOUND, 8)
    HDF5.h5t_insert(id, "symbol_", 0, h5fieldtype(parent, UTF8String))
    dtype = HDF5Datatype(id, parent.plain)
    commit_datatype(parent, dtype, Symbol)
end

# Construct HDF5 type corresponding to Type
function h5type{T}(parent::JldFile, ::Type{Type{T}})
    haskey(parent.jlh5type, Type) && return parent.jlh5type[Type]
    id = HDF5.h5t_create(HDF5.H5T_COMPOUND, 8)
    HDF5.h5t_insert(id, "typename_", 0, h5fieldtype(parent, UTF8String))
    dtype = HDF5Datatype(id, parent.plain)
    commit_datatype(parent, dtype, Type)
end

# Construct HDF5 type corresponding to UTF16String
function h5type(parent::JldFile, ::Type{UTF16String})
    haskey(parent.jlh5type, UTF16String) && return parent.jlh5type[UTF16String]
    vlen = HDF5.h5t_vlen_create(HDF5.H5T_NATIVE_UINT16)
    id = HDF5.h5t_create(HDF5.H5T_COMPOUND, HDF5.h5t_get_size(vlen))
    HDF5.h5t_insert(id, "data_", 0, vlen)
    HDF5.h5t_close(vlen)
    dtype = HDF5Datatype(id, parent.plain)
    commit_datatype(parent, dtype, UTF16String)
end

unknown_type_err() =
    error("""$T is not of a type supported by JLD
             Please report this error at https://github.com/timholy/HDF5.jl""")

# Construct HDF5 type corresponding to a tuple type
function h5type(parent::JldFile, T::(ANY...))
    !isa(T, (DataType...)) && unknown_type_err()
    haskey(parent.jlh5type, T) && return parent.jlh5type[T]
    isleaftype(T) || error("unexpected non-leaf type $T")

    typeinfo = JldTypeInfo(parent, T)
    if isempty(T)
        id = HDF5.h5t_create(HDF5.H5T_OPAQUE, 1)
    else
        id = HDF5.h5t_create(HDF5.H5T_COMPOUND, typeinfo.size)
    end
    for i = 1:length(typeinfo.offsets)
        fielddtype = typeinfo.dtypes[i]
        HDF5.h5t_insert(id, mangle_name(fielddtype, i), typeinfo.offsets[i], fielddtype)
    end

    gen_h5convert!(typeinfo, T)

    dtype = HDF5Datatype(id, parent.plain)
    jlddtype = commit_datatype(parent, dtype, T)
    if isempty(T)
        # to allow recovery of empty tuples, which HDF5 does not allow
        a_write(dtype, "empty", uint8(1))
    end
    jlddtype
end

# Construct HDF5 type corresponding to a user-defined type
function h5type(parent::JldFile, T::ANY)
    !isa(T, DataType) && unknown_type_err()
    haskey(parent.jlh5type, T) && return parent.jlh5type[T]
    isleaftype(T) || error("unexpected non-leaf type")

    if isempty(T.names)
        # Empty type or non-basic bitstype
        id = HDF5.h5t_create(HDF5.H5T_OPAQUE, max(1, T.size))
        if T.size == 0
            @eval h5convert!(out::Ptr, ::JldFile, x::$T, ::JldWriteSession) = nothing
        else
            @eval h5convert!(out::Ptr, ::JldFile, x::$T, ::JldWriteSession) =
                unsafe_store!(convert(Ptr{$T}, out), x)
        end
    else
        # Compound type
        typeinfo = JldTypeInfo(parent, T.types)
        id = HDF5.h5t_create(HDF5.H5T_COMPOUND, typeinfo.size)
        for i = 1:length(typeinfo.offsets)
            fielddtype = typeinfo.dtypes[i]
            HDF5.h5t_insert(id, mangle_name(fielddtype, T.names[i]), typeinfo.offsets[i], fielddtype)
        end
        gen_h5convert!(typeinfo, T)
    end

    dtype = HDF5Datatype(id, parent.plain)
    jlddtype = commit_datatype(parent, dtype, T)
    if T.size == 0
        # to allow recovery of empty types, which HDF5 does not allow
        a_write(dtype, "empty", uint8(1))
    end
    jlddtype
end

## Get corresponding HDF5Datatype for a specific value

# For simple types, just pass through to HDF5
h5datatype{T<:BitsKindOrByteString}(parent::JldFile, ::T) =
    HDF5.hdf5_type_id(T)

# Arrays of types are arrays of the corresponding field type
# This stores arrays of mutable types as reference arrays
h5datatype{T}(parent::JldFile, ::Array{T}) =
    h5fieldtype(parent, T)

# For compound types, call h5type
h5datatype(parent::JldFile, x::ANY) = h5type(parent, typeof(x))

# Needed to dispatch to the right h5type implementation
h5datatype(parent::JldFile, x::Type) = h5type(parent, Type{Type})

h5datatype(parent::JldGroup, x) = h5datatype(file(parent), x)

## Get corresponding Julia type for a specific HDF5 type
function jldatatype(parent::JldFile, dtype::HDF5Datatype)
    class_id = HDF5.h5t_get_class(dtype.id)
    if class_id == HDF5.H5T_STRING
        cset = HDF5.h5t_get_cset(dtype.id)
        if cset == HDF5.H5T_CSET_ASCII
            return ASCIIString
        elseif cset == HDF5.H5T_CSET_UTF8
            return UTF8String
        else
            error("character set ", cset, " not recognized")
        end
    elseif class_id == HDF5.H5T_INTEGER || class_id == HDF5.H5T_FLOAT
        native_type = HDF5.h5t_get_native_type(dtype.id)
        native_size = HDF5.h5t_get_size(native_type)
        if class_id == HDF5.H5T_INTEGER
            is_signed = HDF5.h5t_get_sign(native_type)
        else
            is_signed = nothing
        end
        
        T = HDF5.hdf5_type_map[(class_id, is_signed, native_size)]
    elseif class_id == HDF5.H5T_COMPOUND || class_id == HDF5.H5T_OPAQUE
        id = HDF5.objinfo(dtype).addr
        haskey(parent.h5jltype, id) && return parent.h5jltype[id]

        typename = a_read(dtype, name_type_attr)
        T = julia_type(typename)
        T == UnsupportedType && error("type $typename does not exist in namespace")
        # TODO attempt to reconstruct type

        if !(T in BUILTIN_TYPES)
            # Get dependent types
            if class_id == HDF5.H5T_COMPOUND
                for i = 0:HDF5.h5t_get_nmembers(dtype.id)-1
                    member_name = HDF5.h5t_get_member_name(dtype.id, i)
                    idx = rsearchindex(member_name, "_")
                    if idx != sizeof(member_name)
                        member_dtype = HDF5.t_open(parent.plain, string(pathtypes, '/', lpad(member_name[idx+1:end], 8, '0')))
                        jldatatype(parent, member_dtype)
                    end
                end
            end

            # TODO check that
            #    - the type matches
            #    - the type has the same field names

            gen_jlconvert(JldTypeInfo(parent, T), T)
        end

        parent.jlh5type[T] = JldDatatype(dtype, id)
        parent.h5jltype[id] = T
        T
    else
        error("unrecognized HDF5 datatype class ", class_id)
    end
end

jldatatype(parent::JldGroup, x) = jldatatype(file(parent), x)
