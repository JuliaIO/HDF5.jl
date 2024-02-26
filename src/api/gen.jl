using CEnum

to_c_type(t::Type) = t
to_c_type_pairs(va_list) = map(enumerate(to_c_type.(va_list))) do (ind, type)
    :(va_list[$ind]::$type)
end

using Libdl, HDF5_jll

const Ctime_t = Int
const Coff_t = ccall(:jl_sizeof_off_t, Cint, ()) == 8 ? Int64 : Int32

const UINT64_MAX = typemax(UInt64)
const SIZE_MAX = typemax(Csize_t)
const UINT32_MAX = typemax(UInt32)

const hid_t = Int64

function H5Acreate2(loc_id, attr_name, type_id, space_id, acpl_id, aapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Acreate2(loc_id::hid_t, attr_name::Ptr{Cchar}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

@cenum H5_index_t::Int32 begin
    H5_INDEX_UNKNOWN = -1
    H5_INDEX_NAME = 0
    H5_INDEX_CRT_ORDER = 1
    H5_INDEX_N = 2
end

@cenum H5_iter_order_t::Int32 begin
    H5_ITER_UNKNOWN = -1
    H5_ITER_INC = 0
    H5_ITER_DEC = 1
    H5_ITER_NATIVE = 2
    H5_ITER_N = 3
end

const hsize_t = UInt64

# typedef herr_t ( * H5A_operator2_t ) ( hid_t location_id /*in*/ , const char * attr_name /*in*/ , const H5A_info_t * ainfo /*in*/ , void * op_data /*in,out*/ )
const H5A_operator2_t = Ptr{Cvoid}

const herr_t = Cint

function H5Aiterate2(loc_id, idx_type, order, idx, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aiterate2(loc_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, idx::Ptr{hsize_t}, op::H5A_operator2_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dcreate2(loc_id, name, type_id, space_id, lcpl_id, dcpl_id, dapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dcreate2(loc_id::hid_t, name::Ptr{Cchar}, type_id::hid_t, space_id::hid_t, lcpl_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dopen2(loc_id, name, dapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dopen2(loc_id::hid_t, name::Ptr{Cchar}, dapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eclear2(err_stack)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eclear2(err_stack::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5E_auto2_t ) ( hid_t estack , void * client_data )
const H5E_auto2_t = Ptr{Cvoid}

function H5Eget_auto2(estack_id, func, client_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_auto2(estack_id::hid_t, func::Ptr{H5E_auto2_t}, client_data::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eprint2(err_stack, stream)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eprint2(err_stack::hid_t, stream::Ptr{Libc.FILE})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function H5Epush2(err_stack, file, func, line, cls_id, maj_id, min_id, msg, va_list...)
        quote
            lock(liblock)
            result = try
                    @ccall libhdf5.H5Epush2(err_stack::hid_t, file::Ptr{Cchar}, func::Ptr{Cchar}, line::Cuint, cls_id::hid_t, maj_id::hid_t, min_id::hid_t, msg::Ptr{Cchar}; $(to_c_type_pairs(va_list)...))::herr_t
                finally
                    unlock(liblock)
                end
            if result < 0
                err_id = h5e_get_current_stack()
                if h5e_get_num(err_id) > 0
                    throw(H5Error(err_id))
                else
                    h5e_close_stack(err_id)
                end
            end
            return nothing
        end
    end

function H5Eset_auto2(estack_id, func, client_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eset_auto2(estack_id::hid_t, func::H5E_auto2_t, client_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5E_direction_t::UInt32 begin
    H5E_WALK_UPWARD = 0
    H5E_WALK_DOWNWARD = 1
end

# typedef herr_t ( * H5E_walk2_t ) ( unsigned n , const H5E_error2_t * err_desc , void * client_data )
const H5E_walk2_t = Ptr{Cvoid}

function H5Ewalk2(err_stack, direction, func, client_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ewalk2(err_stack::hid_t, direction::H5E_direction_t, func::H5E_walk2_t, client_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5E_error2_t
    cls_id::hid_t
    maj_num::hid_t
    min_num::hid_t
    line::Cuint
    func_name::Ptr{Cchar}
    file_name::Ptr{Cchar}
    desc::Ptr{Cchar}
end

struct var"##Ctag#2587"
    version::Cuint
    super_size::hsize_t
    super_ext_size::hsize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2587"}, f::Symbol)
    f === :version && return Ptr{Cuint}(x + 0)
    f === :super_size && return Ptr{hsize_t}(x + 8)
    f === :super_ext_size && return Ptr{hsize_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2587", f::Symbol)
    r = Ref{var"##Ctag#2587"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2587"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2587"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2588"
    version::Cuint
    meta_size::hsize_t
    tot_space::hsize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2588"}, f::Symbol)
    f === :version && return Ptr{Cuint}(x + 0)
    f === :meta_size && return Ptr{hsize_t}(x + 8)
    f === :tot_space && return Ptr{hsize_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2588", f::Symbol)
    r = Ref{var"##Ctag#2588"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2588"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2588"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct H5_ih_info_t
    index_size::hsize_t
    heap_size::hsize_t
end

struct var"##Ctag#2589"
    version::Cuint
    hdr_size::hsize_t
    msgs_info::H5_ih_info_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2589"}, f::Symbol)
    f === :version && return Ptr{Cuint}(x + 0)
    f === :hdr_size && return Ptr{hsize_t}(x + 8)
    f === :msgs_info && return Ptr{H5_ih_info_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2589", f::Symbol)
    r = Ref{var"##Ctag#2589"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2589"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2589"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct H5F_info2_t
    data::NTuple{80, UInt8}
end

function Base.getproperty(x::Ptr{H5F_info2_t}, f::Symbol)
    f === :super && return Ptr{var"##Ctag#2587"}(x + 0)
    f === :free && return Ptr{var"##Ctag#2588"}(x + 24)
    f === :sohm && return Ptr{var"##Ctag#2589"}(x + 48)
    return getfield(x, f)
end

function Base.getproperty(x::H5F_info2_t, f::Symbol)
    r = Ref{H5F_info2_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5F_info2_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5F_info2_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function H5Fget_info2(obj_id, file_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_info2(obj_id::hid_t, file_info::Ptr{H5F_info2_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gcreate2(loc_id, name, lcpl_id, gcpl_id, gapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gcreate2(loc_id::hid_t, name::Ptr{Cchar}, lcpl_id::hid_t, gcpl_id::hid_t, gapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Gopen2(loc_id, name, gapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gopen2(loc_id::hid_t, name::Ptr{Cchar}, gapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

@cenum H5L_type_t::Int32 begin
    H5L_TYPE_ERROR = -1
    H5L_TYPE_HARD = 0
    H5L_TYPE_SOFT = 1
    H5L_TYPE_EXTERNAL = 64
    H5L_TYPE_MAX = 255
end

const hbool_t = Bool

@cenum H5T_cset_t::Int32 begin
    H5T_CSET_ERROR = -1
    H5T_CSET_ASCII = 0
    H5T_CSET_UTF8 = 1
    H5T_CSET_RESERVED_2 = 2
    H5T_CSET_RESERVED_3 = 3
    H5T_CSET_RESERVED_4 = 4
    H5T_CSET_RESERVED_5 = 5
    H5T_CSET_RESERVED_6 = 6
    H5T_CSET_RESERVED_7 = 7
    H5T_CSET_RESERVED_8 = 8
    H5T_CSET_RESERVED_9 = 9
    H5T_CSET_RESERVED_10 = 10
    H5T_CSET_RESERVED_11 = 11
    H5T_CSET_RESERVED_12 = 12
    H5T_CSET_RESERVED_13 = 13
    H5T_CSET_RESERVED_14 = 14
    H5T_CSET_RESERVED_15 = 15
end

struct var"##Ctag#2551"
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2551"}, f::Symbol)
    f === :token && return Ptr{H5O_token_t}(x + 0)
    f === :val_size && return Ptr{Csize_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2551", f::Symbol)
    r = Ref{var"##Ctag#2551"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2551"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2551"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5L_info2_t
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{H5L_info2_t}, f::Symbol)
    f === :type && return Ptr{H5L_type_t}(x + 0)
    f === :corder_valid && return Ptr{hbool_t}(x + 4)
    f === :corder && return Ptr{Int64}(x + 8)
    f === :cset && return Ptr{H5T_cset_t}(x + 16)
    f === :u && return Ptr{var"##Ctag#2551"}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::H5L_info2_t, f::Symbol)
    r = Ref{H5L_info2_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5L_info2_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5L_info2_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function H5Lget_info2(loc_id, name, linfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_info2(loc_id::hid_t, name::Ptr{Cchar}, linfo::Ptr{H5L_info2_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lget_info_by_idx2(loc_id, group_name, idx_type, order, n, linfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_info_by_idx2(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, linfo::Ptr{H5L_info2_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5L_iterate2_t ) ( hid_t group , const char * name , const H5L_info2_t * info , void * op_data )
const H5L_iterate2_t = Ptr{Cvoid}

function H5Literate2(grp_id, idx_type, order, idx, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Literate2(grp_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, idx::Ptr{hsize_t}, op::H5L_iterate2_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Literate_by_name2(loc_id, group_name, idx_type, order, idx, op, op_data, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Literate_by_name2(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, idx::Ptr{hsize_t}, op::H5L_iterate2_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lvisit2(grp_id, idx_type, order, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lvisit2(grp_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5L_iterate2_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lvisit_by_name2(loc_id, group_name, idx_type, order, op, op_data, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lvisit_by_name2(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, op::H5L_iterate2_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5O_token_t
    __data::NTuple{16, UInt8}
end

@cenum H5O_type_t::Int32 begin
    H5O_TYPE_UNKNOWN = -1
    H5O_TYPE_GROUP = 0
    H5O_TYPE_DATASET = 1
    H5O_TYPE_NAMED_DATATYPE = 2
    H5O_TYPE_MAP = 3
    H5O_TYPE_NTYPES = 4
end

struct H5O_info2_t
    fileno::Culong
    token::H5O_token_t
    type::H5O_type_t
    rc::Cuint
    atime::Ctime_t
    mtime::Ctime_t
    ctime::Ctime_t
    btime::Ctime_t
    num_attrs::hsize_t
end

function H5Oget_info3(loc_id, oinfo, fields)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info3(loc_id::hid_t, oinfo::Ptr{H5O_info2_t}, fields::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info_by_idx3(loc_id, group_name, idx_type, order, n, oinfo, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info_by_idx3(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_info2_t}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info_by_name3(loc_id, name, oinfo, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info_by_name3(loc_id::hid_t, name::Ptr{Cchar}, oinfo::Ptr{H5O_info2_t}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5O_iterate2_t ) ( hid_t obj , const char * name , const H5O_info2_t * info , void * op_data )
const H5O_iterate2_t = Ptr{Cvoid}

function H5Ovisit3(obj_id, idx_type, order, op, op_data, fields)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ovisit3(obj_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate2_t, op_data::Ptr{Cvoid}, fields::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ovisit_by_name3(loc_id, obj_name, idx_type, order, op, op_data, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ovisit_by_name3(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate2_t, op_data::Ptr{Cvoid}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pencode2(plist_id, buf, nalloc, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pencode2(plist_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t}, fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

const H5Z_filter_t = Cint

function H5Pget_filter2(plist_id, idx, flags, cd_nelmts, cd_values, namelen, name, filter_config)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_filter2(plist_id::hid_t, idx::Cuint, flags::Ptr{Cuint}, cd_nelmts::Ptr{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{Cchar}, filter_config::Ptr{Cuint})::H5Z_filter_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_filter_by_id2(plist_id, filter_id, flags, cd_nelmts, cd_values, namelen, name, filter_config)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_filter_by_id2(plist_id::hid_t, filter_id::H5Z_filter_t, flags::Ptr{Cuint}, cd_nelmts::Ptr{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{Cchar}, filter_config::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5P_prp_cb2_t ) ( hid_t prop_id , const char * name , size_t size , void * value )
const H5P_prp_cb2_t = Ptr{Cvoid}

const H5P_prp_set_func_t = H5P_prp_cb2_t

const H5P_prp_get_func_t = H5P_prp_cb2_t

const H5P_prp_delete_func_t = H5P_prp_cb2_t

# typedef herr_t ( * H5P_prp_cb1_t ) ( const char * name , size_t size , void * value )
const H5P_prp_cb1_t = Ptr{Cvoid}

const H5P_prp_copy_func_t = H5P_prp_cb1_t

# typedef int ( * H5P_prp_compare_func_t ) ( const void * value1 , const void * value2 , size_t size )
const H5P_prp_compare_func_t = Ptr{Cvoid}

const H5P_prp_close_func_t = H5P_prp_cb1_t

function H5Pinsert2(plist_id, name, size, value, set, get, prp_del, copy, compare, close)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pinsert2(plist_id::hid_t, name::Ptr{Cchar}, size::Csize_t, value::Ptr{Cvoid}, set::H5P_prp_set_func_t, get::H5P_prp_get_func_t, prp_del::H5P_prp_delete_func_t, copy::H5P_prp_copy_func_t, compare::H5P_prp_compare_func_t, close::H5P_prp_close_func_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

const H5P_prp_create_func_t = H5P_prp_cb1_t

function H5Pregister2(cls_id, name, size, def_value, create, set, get, prp_del, copy, compare, close)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pregister2(cls_id::hid_t, name::Ptr{Cchar}, size::Csize_t, def_value::Ptr{Cvoid}, create::H5P_prp_create_func_t, set::H5P_prp_set_func_t, get::H5P_prp_get_func_t, prp_del::H5P_prp_delete_func_t, copy::H5P_prp_copy_func_t, compare::H5P_prp_compare_func_t, close::H5P_prp_close_func_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5R_type_t::Int32 begin
    H5R_BADTYPE = -1
    H5R_OBJECT1 = 0
    H5R_DATASET_REGION1 = 1
    H5R_OBJECT2 = 2
    H5R_DATASET_REGION2 = 3
    H5R_ATTR = 4
    H5R_MAXTYPE = 5
end

function H5Rdereference2(obj_id, oapl_id, ref_type, ref)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rdereference2(obj_id::hid_t, oapl_id::hid_t, ref_type::H5R_type_t, ref::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rget_obj_type2(id, ref_type, ref, obj_type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_obj_type2(id::hid_t, ref_type::H5R_type_t, ref::Ptr{Cvoid}, obj_type::Ptr{H5O_type_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sencode2(obj_id, buf, nalloc, fapl)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sencode2(obj_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t}, fapl::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tarray_create2(base_id, ndims, dim)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tarray_create2(base_id::hid_t, ndims::Cuint, dim::Ptr{hsize_t})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tcommit2(loc_id, name, type_id, lcpl_id, tcpl_id, tapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tcommit2(loc_id::hid_t, name::Ptr{Cchar}, type_id::hid_t, lcpl_id::hid_t, tcpl_id::hid_t, tapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tget_array_dims2(type_id, dims)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_array_dims2(type_id::hid_t, dims::Ptr{hsize_t})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Topen2(loc_id, name, tapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Topen2(loc_id::hid_t, name::Ptr{Cchar}, tapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

# typedef htri_t ( * H5Z_can_apply_func_t ) ( hid_t dcpl_id , hid_t type_id , hid_t space_id )
const H5Z_can_apply_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5Z_set_local_func_t ) ( hid_t dcpl_id , hid_t type_id , hid_t space_id )
const H5Z_set_local_func_t = Ptr{Cvoid}

# typedef size_t ( * H5Z_func_t ) ( unsigned int flags , size_t cd_nelmts , const unsigned int cd_values [ ] , size_t nbytes , size_t * buf_size , void * * buf )
const H5Z_func_t = Ptr{Cvoid}

struct H5Z_class2_t
    version::Cint
    id::H5Z_filter_t
    encoder_present::Cuint
    decoder_present::Cuint
    name::Ptr{Cchar}
    can_apply::H5Z_can_apply_func_t
    set_local::H5Z_set_local_func_t
    filter::H5Z_func_t
end

mutable struct ADIOI_FileD end

function H5check_version(majnum, minnum, relnum)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5check_version(majnum::Cuint, minnum::Cuint, relnum::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5open()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5open()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5E_auto1_t ) ( void * client_data )
const H5E_auto1_t = Ptr{Cvoid}

function H5Eauto_is_v2(err_stack, is_stack)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eauto_is_v2(err_stack::hid_t, is_stack::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eget_auto1(func, client_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_auto1(func::Ptr{H5E_auto1_t}, client_data::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eset_auto1(func, client_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eset_auto1(func::H5E_auto1_t, client_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

const H5FD_class_value_t = Cint

const haddr_t = UInt64

function H5VL_native_register()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VL_native_register()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

# typedef hid_t ( * H5FD_init_t ) ( void )
const H5FD_init_t = Ptr{Cvoid}

function H5FDperform_init(op)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDperform_init(op::H5FD_init_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_core_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_core_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_family_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_family_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_log_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_log_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_mirror_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_mirror_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_multi_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_multi_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_onion_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_onion_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_ros3_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_ros3_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_sec2_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_sec2_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_splitter_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_splitter_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FD_stdio_init()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FD_stdio_init()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VL_pass_through_register()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VL_pass_through_register()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

const htri_t = Cint

const hssize_t = Int64

# typedef void ( * H5_atclose_func_t ) ( void * ctx )
const H5_atclose_func_t = Ptr{Cvoid}

function H5atclose(func, ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5atclose(func::H5_atclose_func_t, ctx::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5close()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5close()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5dont_atexit()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5dont_atexit()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5garbage_collect()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5garbage_collect()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5set_free_list_limits(reg_global_lim, reg_list_lim, arr_global_lim, arr_list_lim, blk_global_lim, blk_list_lim)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5set_free_list_limits(reg_global_lim::Cint, reg_list_lim::Cint, arr_global_lim::Cint, arr_list_lim::Cint, blk_global_lim::Cint, blk_list_lim::Cint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5get_free_list_sizes(reg_size, arr_size, blk_size, fac_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5get_free_list_sizes(reg_size::Ptr{Csize_t}, arr_size::Ptr{Csize_t}, blk_size::Ptr{Csize_t}, fac_size::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5get_libversion(majnum, minnum, relnum)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5get_libversion(majnum::Ptr{Cuint}, minnum::Ptr{Cuint}, relnum::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5is_library_terminating(is_terminating)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5is_library_terminating(is_terminating::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5is_library_threadsafe(is_ts)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5is_library_threadsafe(is_ts::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5free_memory(mem)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5free_memory(mem::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5allocate_memory(size, clear)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5allocate_memory(size::Csize_t, clear::hbool_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5resize_memory(mem, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5resize_memory(mem::Ptr{Cvoid}, size::Csize_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

@cenum H5I_type_t::Int32 begin
    H5I_UNINIT = -2
    H5I_BADID = -1
    H5I_FILE = 1
    H5I_GROUP = 2
    H5I_DATATYPE = 3
    H5I_DATASPACE = 4
    H5I_DATASET = 5
    H5I_MAP = 6
    H5I_ATTR = 7
    H5I_VFL = 8
    H5I_VOL = 9
    H5I_GENPROP_CLS = 10
    H5I_GENPROP_LST = 11
    H5I_ERROR_CLASS = 12
    H5I_ERROR_MSG = 13
    H5I_ERROR_STACK = 14
    H5I_SPACE_SEL_ITER = 15
    H5I_EVENTSET = 16
    H5I_NTYPES = 17
end

# typedef herr_t ( * H5I_free_t ) ( void * obj , void * * request )
const H5I_free_t = Ptr{Cvoid}

# typedef int ( * H5I_search_func_t ) ( void * obj , hid_t id , void * key )
const H5I_search_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5I_iterate_func_t ) ( hid_t id , void * udata )
const H5I_iterate_func_t = Ptr{Cvoid}

function H5Iregister(type, object)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iregister(type::H5I_type_t, object::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iobject_verify(id, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iobject_verify(id::hid_t, type::H5I_type_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iremove_verify(id, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iremove_verify(id::hid_t, type::H5I_type_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iget_type(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iget_type(id::hid_t)::H5I_type_t
            finally
                unlock(liblock)
            end
        if result < H5I_type_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iget_file_id(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iget_file_id(id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iget_name(id, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iget_name(id::hid_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iinc_ref(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iinc_ref(id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Idec_ref(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Idec_ref(id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Iget_ref(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iget_ref(id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Iregister_type(hash_size, reserved, free_func)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iregister_type(hash_size::Csize_t, reserved::Cuint, free_func::H5I_free_t)::H5I_type_t
            finally
                unlock(liblock)
            end
        if result < H5I_type_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iclear_type(type, force)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iclear_type(type::H5I_type_t, force::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Idestroy_type(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Idestroy_type(type::H5I_type_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Iinc_type_ref(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iinc_type_ref(type::H5I_type_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Idec_type_ref(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Idec_type_ref(type::H5I_type_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Iget_type_ref(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iget_type_ref(type::H5I_type_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Isearch(type, func, key)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Isearch(type::H5I_type_t, func::H5I_search_func_t, key::Ptr{Cvoid})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Iiterate(type, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iiterate(type::H5I_type_t, op::H5I_iterate_func_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Inmembers(type, num_members)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Inmembers(type::H5I_type_t, num_members::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Itype_exists(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Itype_exists(type::H5I_type_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Iis_valid(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iis_valid(id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

struct var"##Ctag#2576"
    total::hsize_t
    meta::hsize_t
    mesg::hsize_t
    free::hsize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2576"}, f::Symbol)
    f === :total && return Ptr{hsize_t}(x + 0)
    f === :meta && return Ptr{hsize_t}(x + 8)
    f === :mesg && return Ptr{hsize_t}(x + 16)
    f === :free && return Ptr{hsize_t}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2576", f::Symbol)
    r = Ref{var"##Ctag#2576"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2576"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2576"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2577"
    present::UInt64
    shared::UInt64
end
function Base.getproperty(x::Ptr{var"##Ctag#2577"}, f::Symbol)
    f === :present && return Ptr{UInt64}(x + 0)
    f === :shared && return Ptr{UInt64}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2577", f::Symbol)
    r = Ref{var"##Ctag#2577"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2577"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2577"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct H5O_hdr_info_t
    data::NTuple{64, UInt8}
end

function Base.getproperty(x::Ptr{H5O_hdr_info_t}, f::Symbol)
    f === :version && return Ptr{Cuint}(x + 0)
    f === :nmesgs && return Ptr{Cuint}(x + 4)
    f === :nchunks && return Ptr{Cuint}(x + 8)
    f === :flags && return Ptr{Cuint}(x + 12)
    f === :space && return Ptr{var"##Ctag#2576"}(x + 16)
    f === :mesg && return Ptr{var"##Ctag#2577"}(x + 48)
    return getfield(x, f)
end

function Base.getproperty(x::H5O_hdr_info_t, f::Symbol)
    r = Ref{H5O_hdr_info_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5O_hdr_info_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5O_hdr_info_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#2590"
    obj::H5_ih_info_t
    attr::H5_ih_info_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2590"}, f::Symbol)
    f === :obj && return Ptr{H5_ih_info_t}(x + 0)
    f === :attr && return Ptr{H5_ih_info_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2590", f::Symbol)
    r = Ref{var"##Ctag#2590"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2590"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2590"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct H5O_native_info_t
    data::NTuple{96, UInt8}
end

function Base.getproperty(x::Ptr{H5O_native_info_t}, f::Symbol)
    f === :hdr && return Ptr{H5O_hdr_info_t}(x + 0)
    f === :meta_size && return Ptr{var"##Ctag#2590"}(x + 64)
    return getfield(x, f)
end

function Base.getproperty(x::H5O_native_info_t, f::Symbol)
    r = Ref{H5O_native_info_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5O_native_info_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5O_native_info_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5O_msg_crt_idx_t = UInt32

@cenum H5O_mcdt_search_ret_t::Int32 begin
    H5O_MCDT_SEARCH_ERROR = -1
    H5O_MCDT_SEARCH_CONT = 0
    H5O_MCDT_SEARCH_STOP = 1
end

# typedef H5O_mcdt_search_ret_t ( * H5O_mcdt_search_cb_t ) ( void * op_data )
const H5O_mcdt_search_cb_t = Ptr{Cvoid}

function H5Oopen(loc_id, name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oopen(loc_id::hid_t, name::Ptr{Cchar}, lapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Oopen_by_token(loc_id, token)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oopen_by_token(loc_id::hid_t, token::H5O_token_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Oopen_by_idx(loc_id, group_name, idx_type, order, n, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oopen_by_idx(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, lapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Oexists_by_name(loc_id, name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oexists_by_name(loc_id::hid_t, name::Ptr{Cchar}, lapl_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Oget_native_info(loc_id, oinfo, fields)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_native_info(loc_id::hid_t, oinfo::Ptr{H5O_native_info_t}, fields::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_native_info_by_name(loc_id, name, oinfo, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_native_info_by_name(loc_id::hid_t, name::Ptr{Cchar}, oinfo::Ptr{H5O_native_info_t}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_native_info_by_idx(loc_id, group_name, idx_type, order, n, oinfo, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_native_info_by_idx(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_native_info_t}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Olink(obj_id, new_loc_id, new_name, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Olink(obj_id::hid_t, new_loc_id::hid_t, new_name::Ptr{Cchar}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oincr_refcount(object_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oincr_refcount(object_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Odecr_refcount(object_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Odecr_refcount(object_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ocopy(src_loc_id, src_name, dst_loc_id, dst_name, ocpypl_id, lcpl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ocopy(src_loc_id::hid_t, src_name::Ptr{Cchar}, dst_loc_id::hid_t, dst_name::Ptr{Cchar}, ocpypl_id::hid_t, lcpl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oset_comment(obj_id, comment)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oset_comment(obj_id::hid_t, comment::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oset_comment_by_name(loc_id, name, comment, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oset_comment_by_name(loc_id::hid_t, name::Ptr{Cchar}, comment::Ptr{Cchar}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_comment(obj_id, comment, bufsize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_comment(obj_id::hid_t, comment::Ptr{Cchar}, bufsize::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Oget_comment_by_name(loc_id, name, comment, bufsize, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_comment_by_name(loc_id::hid_t, name::Ptr{Cchar}, comment::Ptr{Cchar}, bufsize::Csize_t, lapl_id::hid_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Oclose(object_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oclose(object_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oflush(obj_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oflush(obj_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Orefresh(oid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Orefresh(oid::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Odisable_mdc_flushes(object_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Odisable_mdc_flushes(object_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oenable_mdc_flushes(object_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oenable_mdc_flushes(object_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oare_mdc_flushes_disabled(object_id, are_disabled)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oare_mdc_flushes_disabled(object_id::hid_t, are_disabled::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Otoken_cmp(loc_id, token1, token2, cmp_value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Otoken_cmp(loc_id::hid_t, token1::Ptr{H5O_token_t}, token2::Ptr{H5O_token_t}, cmp_value::Ptr{Cint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Otoken_to_str(loc_id, token, token_str)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Otoken_to_str(loc_id::hid_t, token::Ptr{H5O_token_t}, token_str::Ptr{Ptr{Cchar}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Otoken_from_str(loc_id, token_str, token)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Otoken_from_str(loc_id::hid_t, token_str::Ptr{Cchar}, token::Ptr{H5O_token_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5O_stat_t
    size::hsize_t
    free::hsize_t
    nmesgs::Cuint
    nchunks::Cuint
end

struct var"##Ctag#2602"
    obj::H5_ih_info_t
    attr::H5_ih_info_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2602"}, f::Symbol)
    f === :obj && return Ptr{H5_ih_info_t}(x + 0)
    f === :attr && return Ptr{H5_ih_info_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2602", f::Symbol)
    r = Ref{var"##Ctag#2602"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2602"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2602"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct H5O_info1_t
    data::NTuple{160, UInt8}
end

function Base.getproperty(x::Ptr{H5O_info1_t}, f::Symbol)
    f === :fileno && return Ptr{Culong}(x + 0)
    f === :addr && return Ptr{haddr_t}(x + 8)
    f === :type && return Ptr{H5O_type_t}(x + 16)
    f === :rc && return Ptr{Cuint}(x + 20)
    f === :atime && return Ptr{Ctime_t}(x + 24)
    f === :mtime && return Ptr{Ctime_t}(x + 32)
    f === :ctime && return Ptr{Ctime_t}(x + 40)
    f === :btime && return Ptr{Ctime_t}(x + 48)
    f === :num_attrs && return Ptr{hsize_t}(x + 56)
    f === :hdr && return Ptr{H5O_hdr_info_t}(x + 64)
    f === :meta_size && return Ptr{var"##Ctag#2602"}(x + 128)
    return getfield(x, f)
end

function Base.getproperty(x::H5O_info1_t, f::Symbol)
    r = Ref{H5O_info1_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5O_info1_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5O_info1_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

# typedef herr_t ( * H5O_iterate1_t ) ( hid_t obj , const char * name , const H5O_info1_t * info , void * op_data )
const H5O_iterate1_t = Ptr{Cvoid}

function H5Oopen_by_addr(loc_id, addr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oopen_by_addr(loc_id::hid_t, addr::haddr_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Oget_info1(loc_id, oinfo)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info1(loc_id::hid_t, oinfo::Ptr{H5O_info1_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info_by_name1(loc_id, name, oinfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info_by_name1(loc_id::hid_t, name::Ptr{Cchar}, oinfo::Ptr{H5O_info1_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info_by_idx1(loc_id, group_name, idx_type, order, n, oinfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info_by_idx1(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_info1_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info2(loc_id, oinfo, fields)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info2(loc_id::hid_t, oinfo::Ptr{H5O_info1_t}, fields::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info_by_name2(loc_id, name, oinfo, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info_by_name2(loc_id::hid_t, name::Ptr{Cchar}, oinfo::Ptr{H5O_info1_t}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Oget_info_by_idx2(loc_id, group_name, idx_type, order, n, oinfo, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Oget_info_by_idx2(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, oinfo::Ptr{H5O_info1_t}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ovisit1(obj_id, idx_type, order, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ovisit1(obj_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ovisit_by_name1(loc_id, obj_name, idx_type, order, op, op_data, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ovisit_by_name1(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ovisit2(obj_id, idx_type, order, op, op_data, fields)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ovisit2(obj_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid}, fields::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ovisit_by_name2(loc_id, obj_name, idx_type, order, op, op_data, fields, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ovisit_by_name2(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, op::H5O_iterate1_t, op_data::Ptr{Cvoid}, fields::Cuint, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5T_class_t::Int32 begin
    H5T_NO_CLASS = -1
    H5T_INTEGER = 0
    H5T_FLOAT = 1
    H5T_TIME = 2
    H5T_STRING = 3
    H5T_BITFIELD = 4
    H5T_OPAQUE = 5
    H5T_COMPOUND = 6
    H5T_REFERENCE = 7
    H5T_ENUM = 8
    H5T_VLEN = 9
    H5T_ARRAY = 10
    H5T_NCLASSES = 11
end

@cenum H5T_order_t::Int32 begin
    H5T_ORDER_ERROR = -1
    H5T_ORDER_LE = 0
    H5T_ORDER_BE = 1
    H5T_ORDER_VAX = 2
    H5T_ORDER_MIXED = 3
    H5T_ORDER_NONE = 4
end

@cenum H5T_sign_t::Int32 begin
    H5T_SGN_ERROR = -1
    H5T_SGN_NONE = 0
    H5T_SGN_2 = 1
    H5T_NSGN = 2
end

@cenum H5T_norm_t::Int32 begin
    H5T_NORM_ERROR = -1
    H5T_NORM_IMPLIED = 0
    H5T_NORM_MSBSET = 1
    H5T_NORM_NONE = 2
end

@cenum H5T_str_t::Int32 begin
    H5T_STR_ERROR = -1
    H5T_STR_NULLTERM = 0
    H5T_STR_NULLPAD = 1
    H5T_STR_SPACEPAD = 2
    H5T_STR_RESERVED_3 = 3
    H5T_STR_RESERVED_4 = 4
    H5T_STR_RESERVED_5 = 5
    H5T_STR_RESERVED_6 = 6
    H5T_STR_RESERVED_7 = 7
    H5T_STR_RESERVED_8 = 8
    H5T_STR_RESERVED_9 = 9
    H5T_STR_RESERVED_10 = 10
    H5T_STR_RESERVED_11 = 11
    H5T_STR_RESERVED_12 = 12
    H5T_STR_RESERVED_13 = 13
    H5T_STR_RESERVED_14 = 14
    H5T_STR_RESERVED_15 = 15
end

@cenum H5T_pad_t::Int32 begin
    H5T_PAD_ERROR = -1
    H5T_PAD_ZERO = 0
    H5T_PAD_ONE = 1
    H5T_PAD_BACKGROUND = 2
    H5T_NPAD = 3
end

@cenum H5T_direction_t::UInt32 begin
    H5T_DIR_DEFAULT = 0
    H5T_DIR_ASCEND = 1
    H5T_DIR_DESCEND = 2
end

@cenum H5T_conv_except_t::UInt32 begin
    H5T_CONV_EXCEPT_RANGE_HI = 0
    H5T_CONV_EXCEPT_RANGE_LOW = 1
    H5T_CONV_EXCEPT_PRECISION = 2
    H5T_CONV_EXCEPT_TRUNCATE = 3
    H5T_CONV_EXCEPT_PINF = 4
    H5T_CONV_EXCEPT_NINF = 5
    H5T_CONV_EXCEPT_NAN = 6
end

@cenum H5T_conv_ret_t::Int32 begin
    H5T_CONV_ABORT = -1
    H5T_CONV_UNHANDLED = 0
    H5T_CONV_HANDLED = 1
end

struct hvl_t
    len::Csize_t
    p::Ptr{Cvoid}
end

# typedef H5T_conv_ret_t ( * H5T_conv_except_func_t ) ( H5T_conv_except_t except_type , hid_t src_id , hid_t dst_id , void * src_buf , void * dst_buf , void * user_data )
const H5T_conv_except_func_t = Ptr{Cvoid}

function H5Tcreate(type, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tcreate(type::H5T_class_t, size::Csize_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tcopy(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tcopy(type_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tclose(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tclose(type_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tequal(type1_id, type2_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tequal(type1_id::hid_t, type2_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Tlock(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tlock(type_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tcommit_anon(loc_id, type_id, tcpl_id, tapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tcommit_anon(loc_id::hid_t, type_id::hid_t, tcpl_id::hid_t, tapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tget_create_plist(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_create_plist(type_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tcommitted(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tcommitted(type_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Tencode(obj_id, buf, nalloc)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tencode(obj_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tdecode(buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tdecode(buf::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tflush(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tflush(type_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Trefresh(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Trefresh(type_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tinsert(parent_id, name, offset, member_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tinsert(parent_id::hid_t, name::Ptr{Cchar}, offset::Csize_t, member_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tpack(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tpack(type_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tenum_create(base_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tenum_create(base_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tenum_insert(type, name, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tenum_insert(type::hid_t, name::Ptr{Cchar}, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tenum_nameof(type, value, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tenum_nameof(type::hid_t, value::Ptr{Cvoid}, name::Ptr{Cchar}, size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tenum_valueof(type, name, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tenum_valueof(type::hid_t, name::Ptr{Cchar}, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tvlen_create(base_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tvlen_create(base_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_array_ndims(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_array_ndims(type_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Tset_tag(type, tag)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_tag(type::hid_t, tag::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tget_tag(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_tag(type::hid_t)::Ptr{Cchar}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_super(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_super(type::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_class(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_class(type_id::hid_t)::H5T_class_t
            finally
                unlock(liblock)
            end
        if result < H5T_class_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tdetect_class(type_id, cls)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tdetect_class(type_id::hid_t, cls::H5T_class_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Tget_size(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_size(type_id::hid_t)::Csize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_order(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_order(type_id::hid_t)::H5T_order_t
            finally
                unlock(liblock)
            end
        if result < H5T_order_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_precision(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_precision(type_id::hid_t)::Csize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_offset(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_offset(type_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Tget_pad(type_id, lsb, msb)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_pad(type_id::hid_t, lsb::Ptr{H5T_pad_t}, msb::Ptr{H5T_pad_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tget_sign(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_sign(type_id::hid_t)::H5T_sign_t
            finally
                unlock(liblock)
            end
        if result < H5T_sign_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_fields(type_id, spos, epos, esize, mpos, msize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_fields(type_id::hid_t, spos::Ptr{Csize_t}, epos::Ptr{Csize_t}, esize::Ptr{Csize_t}, mpos::Ptr{Csize_t}, msize::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tget_ebias(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_ebias(type_id::hid_t)::Csize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_norm(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_norm(type_id::hid_t)::H5T_norm_t
            finally
                unlock(liblock)
            end
        if result < H5T_norm_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_inpad(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_inpad(type_id::hid_t)::H5T_pad_t
            finally
                unlock(liblock)
            end
        if result < H5T_pad_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_strpad(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_strpad(type_id::hid_t)::H5T_str_t
            finally
                unlock(liblock)
            end
        if result < H5T_str_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_nmembers(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_nmembers(type_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Tget_member_name(type_id, membno)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_member_name(type_id::hid_t, membno::Cuint)::Ptr{Cchar}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_member_index(type_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_member_index(type_id::hid_t, name::Ptr{Cchar})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Tget_member_offset(type_id, membno)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_member_offset(type_id::hid_t, membno::Cuint)::Csize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_member_class(type_id, membno)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_member_class(type_id::hid_t, membno::Cuint)::H5T_class_t
            finally
                unlock(liblock)
            end
        if result < H5T_class_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_member_type(type_id, membno)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_member_type(type_id::hid_t, membno::Cuint)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_member_value(type_id, membno, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_member_value(type_id::hid_t, membno::Cuint, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tget_cset(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_cset(type_id::hid_t)::H5T_cset_t
            finally
                unlock(liblock)
            end
        if result < H5T_cset_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tis_variable_str(type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tis_variable_str(type_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Tget_native_type(type_id, direction)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_native_type(type_id::hid_t, direction::H5T_direction_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tset_size(type_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_size(type_id::hid_t, size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_order(type_id, order)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_order(type_id::hid_t, order::H5T_order_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_precision(type_id, prec)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_precision(type_id::hid_t, prec::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_offset(type_id, offset)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_offset(type_id::hid_t, offset::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_pad(type_id, lsb, msb)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_pad(type_id::hid_t, lsb::H5T_pad_t, msb::H5T_pad_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_sign(type_id, sign)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_sign(type_id::hid_t, sign::H5T_sign_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_fields(type_id, spos, epos, esize, mpos, msize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_fields(type_id::hid_t, spos::Csize_t, epos::Csize_t, esize::Csize_t, mpos::Csize_t, msize::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_ebias(type_id, ebias)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_ebias(type_id::hid_t, ebias::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_norm(type_id, norm)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_norm(type_id::hid_t, norm::H5T_norm_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_inpad(type_id, pad)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_inpad(type_id::hid_t, pad::H5T_pad_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_cset(type_id, cset)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_cset(type_id::hid_t, cset::H5T_cset_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tset_strpad(type_id, strpad)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tset_strpad(type_id::hid_t, strpad::H5T_str_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tconvert(src_id, dst_id, nelmts, buf, background, plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tconvert(src_id::hid_t, dst_id::hid_t, nelmts::Csize_t, buf::Ptr{Cvoid}, background::Ptr{Cvoid}, plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Treclaim(type_id, space_id, plist_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Treclaim(type_id::hid_t, space_id::hid_t, plist_id::hid_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tcommit1(loc_id, name, type_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tcommit1(loc_id::hid_t, name::Ptr{Cchar}, type_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Topen1(loc_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Topen1(loc_id::hid_t, name::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tarray_create1(base_id, ndims, dim, perm)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tarray_create1(base_id::hid_t, ndims::Cint, dim::Ptr{hsize_t}, perm::Ptr{Cint})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Tget_array_dims1(type_id, dims, perm)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tget_array_dims1(type_id::hid_t, dims::Ptr{hsize_t}, perm::Ptr{Cint})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

struct H5A_info_t
    corder_valid::hbool_t
    corder::H5O_msg_crt_idx_t
    cset::H5T_cset_t
    data_size::hsize_t
end

function H5Aclose(attr_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aclose(attr_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Acreate_by_name(loc_id, obj_name, attr_name, type_id, space_id, acpl_id, aapl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Acreate_by_name(loc_id::hid_t, obj_name::Ptr{Cchar}, attr_name::Ptr{Cchar}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t, lapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Adelete(loc_id, attr_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Adelete(loc_id::hid_t, attr_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Adelete_by_idx(loc_id, obj_name, idx_type, order, n, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Adelete_by_idx(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Adelete_by_name(loc_id, obj_name, attr_name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Adelete_by_name(loc_id::hid_t, obj_name::Ptr{Cchar}, attr_name::Ptr{Cchar}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Aexists(obj_id, attr_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aexists(obj_id::hid_t, attr_name::Ptr{Cchar})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Aexists_by_name(obj_id, obj_name, attr_name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aexists_by_name(obj_id::hid_t, obj_name::Ptr{Cchar}, attr_name::Ptr{Cchar}, lapl_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Aget_create_plist(attr_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_create_plist(attr_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aget_info(attr_id, ainfo)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_info(attr_id::hid_t, ainfo::Ptr{H5A_info_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Aget_info_by_idx(loc_id, obj_name, idx_type, order, n, ainfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_info_by_idx(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, ainfo::Ptr{H5A_info_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Aget_info_by_name(loc_id, obj_name, attr_name, ainfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_info_by_name(loc_id::hid_t, obj_name::Ptr{Cchar}, attr_name::Ptr{Cchar}, ainfo::Ptr{H5A_info_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Aget_name(attr_id, buf_size, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_name(attr_id::hid_t, buf_size::Csize_t, buf::Ptr{Cchar})::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aget_name_by_idx(loc_id, obj_name, idx_type, order, n, name, size, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_name_by_idx(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, name::Ptr{Cchar}, size::Csize_t, lapl_id::hid_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aget_space(attr_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_space(attr_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aget_storage_size(attr_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_storage_size(attr_id::hid_t)::hsize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aget_type(attr_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_type(attr_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aiterate_by_name(loc_id, obj_name, idx_type, order, idx, op, op_data, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aiterate_by_name(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, idx::Ptr{hsize_t}, op::H5A_operator2_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Aopen(obj_id, attr_name, aapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aopen(obj_id::hid_t, attr_name::Ptr{Cchar}, aapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aopen_by_idx(loc_id, obj_name, idx_type, order, n, aapl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aopen_by_idx(loc_id::hid_t, obj_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, aapl_id::hid_t, lapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aopen_by_name(loc_id, obj_name, attr_name, aapl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aopen_by_name(loc_id::hid_t, obj_name::Ptr{Cchar}, attr_name::Ptr{Cchar}, aapl_id::hid_t, lapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aread(attr_id, type_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aread(attr_id::hid_t, type_id::hid_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Arename(loc_id, old_name, new_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Arename(loc_id::hid_t, old_name::Ptr{Cchar}, new_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Awrite(attr_id, type_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Awrite(attr_id::hid_t, type_id::hid_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Arename_by_name(loc_id, obj_name, old_attr_name, new_attr_name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Arename_by_name(loc_id::hid_t, obj_name::Ptr{Cchar}, old_attr_name::Ptr{Cchar}, new_attr_name::Ptr{Cchar}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5A_operator1_t ) ( hid_t location_id /*in*/ , const char * attr_name /*in*/ , void * operator_data /*in,out*/ )
const H5A_operator1_t = Ptr{Cvoid}

function H5Acreate1(loc_id, name, type_id, space_id, acpl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Acreate1(loc_id::hid_t, name::Ptr{Cchar}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aget_num_attrs(loc_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aget_num_attrs(loc_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Aiterate1(loc_id, idx, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aiterate1(loc_id::hid_t, idx::Ptr{Cuint}, op::H5A_operator1_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Aopen_idx(loc_id, idx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aopen_idx(loc_id::hid_t, idx::Cuint)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Aopen_name(loc_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Aopen_name(loc_id::hid_t, name::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

@cenum H5C_cache_incr_mode::UInt32 begin
    H5C_incr__off = 0
    H5C_incr__threshold = 1
end

@cenum H5C_cache_flash_incr_mode::UInt32 begin
    H5C_flash_incr__off = 0
    H5C_flash_incr__add_space = 1
end

@cenum H5C_cache_decr_mode::UInt32 begin
    H5C_decr__off = 0
    H5C_decr__threshold = 1
    H5C_decr__age_out = 2
    H5C_decr__age_out_with_threshold = 3
end

struct H5AC_cache_config_t
    version::Cint
    rpt_fcn_enabled::hbool_t
    open_trace_file::hbool_t
    close_trace_file::hbool_t
    trace_file_name::NTuple{1025, Cchar}
    evictions_enabled::hbool_t
    set_initial_size::hbool_t
    initial_size::Csize_t
    min_clean_fraction::Cdouble
    max_size::Csize_t
    min_size::Csize_t
    epoch_length::Clong
    incr_mode::H5C_cache_incr_mode
    lower_hr_threshold::Cdouble
    increment::Cdouble
    apply_max_increment::hbool_t
    max_increment::Csize_t
    flash_incr_mode::H5C_cache_flash_incr_mode
    flash_multiple::Cdouble
    flash_threshold::Cdouble
    decr_mode::H5C_cache_decr_mode
    upper_hr_threshold::Cdouble
    decrement::Cdouble
    apply_max_decrement::hbool_t
    max_decrement::Csize_t
    epochs_before_eviction::Cint
    apply_empty_reserve::hbool_t
    empty_reserve::Cdouble
    dirty_bytes_threshold::Csize_t
    metadata_write_strategy::Cint
end

struct H5AC_cache_image_config_t
    version::Cint
    generate_image::hbool_t
    save_resize_status::hbool_t
    entry_ageout::Cint
end

@cenum H5D_layout_t::Int32 begin
    H5D_LAYOUT_ERROR = -1
    H5D_COMPACT = 0
    H5D_CONTIGUOUS = 1
    H5D_CHUNKED = 2
    H5D_VIRTUAL = 3
    H5D_NLAYOUTS = 4
end

@cenum H5D_chunk_index_t::UInt32 begin
    H5D_CHUNK_IDX_BTREE = 0
    H5D_CHUNK_IDX_SINGLE = 1
    H5D_CHUNK_IDX_NONE = 2
    H5D_CHUNK_IDX_FARRAY = 3
    H5D_CHUNK_IDX_EARRAY = 4
    H5D_CHUNK_IDX_BT2 = 5
    H5D_CHUNK_IDX_NTYPES = 6
end

@cenum H5D_alloc_time_t::Int32 begin
    H5D_ALLOC_TIME_ERROR = -1
    H5D_ALLOC_TIME_DEFAULT = 0
    H5D_ALLOC_TIME_EARLY = 1
    H5D_ALLOC_TIME_LATE = 2
    H5D_ALLOC_TIME_INCR = 3
end

@cenum H5D_space_status_t::Int32 begin
    H5D_SPACE_STATUS_ERROR = -1
    H5D_SPACE_STATUS_NOT_ALLOCATED = 0
    H5D_SPACE_STATUS_PART_ALLOCATED = 1
    H5D_SPACE_STATUS_ALLOCATED = 2
end

@cenum H5D_fill_time_t::Int32 begin
    H5D_FILL_TIME_ERROR = -1
    H5D_FILL_TIME_ALLOC = 0
    H5D_FILL_TIME_NEVER = 1
    H5D_FILL_TIME_IFSET = 2
end

@cenum H5D_fill_value_t::Int32 begin
    H5D_FILL_VALUE_ERROR = -1
    H5D_FILL_VALUE_UNDEFINED = 0
    H5D_FILL_VALUE_DEFAULT = 1
    H5D_FILL_VALUE_USER_DEFINED = 2
end

@cenum H5D_vds_view_t::Int32 begin
    H5D_VDS_ERROR = -1
    H5D_VDS_FIRST_MISSING = 0
    H5D_VDS_LAST_AVAILABLE = 1
end

# typedef herr_t ( * H5D_append_cb_t ) ( hid_t dataset_id , hsize_t * cur_dims , void * op_data )
const H5D_append_cb_t = Ptr{Cvoid}

# typedef herr_t ( * H5D_operator_t ) ( void * elem , hid_t type_id , unsigned ndim , const hsize_t * point , void * operator_data )
const H5D_operator_t = Ptr{Cvoid}

# typedef herr_t ( * H5D_scatter_func_t ) ( const void * * src_buf /*out*/ , size_t * src_buf_bytes_used /*out*/ , void * op_data )
const H5D_scatter_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5D_gather_func_t ) ( const void * dst_buf , size_t dst_buf_bytes_used , void * op_data )
const H5D_gather_func_t = Ptr{Cvoid}

# typedef int ( * H5D_chunk_iter_op_t ) ( const hsize_t * offset , unsigned filter_mask , haddr_t addr , hsize_t size , void * op_data )
const H5D_chunk_iter_op_t = Ptr{Cvoid}

function H5Dcreate_anon(loc_id, type_id, space_id, dcpl_id, dapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dcreate_anon(loc_id::hid_t, type_id::hid_t, space_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dget_space(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_space(dset_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dget_space_status(dset_id, allocation)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_space_status(dset_id::hid_t, allocation::Ptr{H5D_space_status_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dget_type(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_type(dset_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dget_create_plist(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_create_plist(dset_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dget_access_plist(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_access_plist(dset_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dget_storage_size(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_storage_size(dset_id::hid_t)::hsize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dget_chunk_storage_size(dset_id, offset, chunk_bytes)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_chunk_storage_size(dset_id::hid_t, offset::Ptr{hsize_t}, chunk_bytes::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dget_num_chunks(dset_id, fspace_id, nchunks)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_num_chunks(dset_id::hid_t, fspace_id::hid_t, nchunks::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dget_chunk_info_by_coord(dset_id, offset, filter_mask, addr, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_chunk_info_by_coord(dset_id::hid_t, offset::Ptr{hsize_t}, filter_mask::Ptr{Cuint}, addr::Ptr{haddr_t}, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dchunk_iter(dset_id, dxpl_id, cb, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dchunk_iter(dset_id::hid_t, dxpl_id::hid_t, cb::H5D_chunk_iter_op_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dget_chunk_info(dset_id, fspace_id, chk_idx, offset, filter_mask, addr, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_chunk_info(dset_id::hid_t, fspace_id::hid_t, chk_idx::hsize_t, offset::Ptr{hsize_t}, filter_mask::Ptr{Cuint}, addr::Ptr{haddr_t}, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dget_offset(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_offset(dset_id::hid_t)::haddr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dread(dset_id, mem_type_id, mem_space_id, file_space_id, dxpl_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dread(dset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, dxpl_id::hid_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dread_multi(count, dset_id, mem_type_id, mem_space_id, file_space_id, dxpl_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dread_multi(count::Csize_t, dset_id::Ptr{hid_t}, mem_type_id::Ptr{hid_t}, mem_space_id::Ptr{hid_t}, file_space_id::Ptr{hid_t}, dxpl_id::hid_t, buf::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dwrite(dset_id, mem_type_id, mem_space_id, file_space_id, dxpl_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dwrite(dset_id::hid_t, mem_type_id::hid_t, mem_space_id::hid_t, file_space_id::hid_t, dxpl_id::hid_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dwrite_multi(count, dset_id, mem_type_id, mem_space_id, file_space_id, dxpl_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dwrite_multi(count::Csize_t, dset_id::Ptr{hid_t}, mem_type_id::Ptr{hid_t}, mem_space_id::Ptr{hid_t}, file_space_id::Ptr{hid_t}, dxpl_id::hid_t, buf::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dwrite_chunk(dset_id, dxpl_id, filters, offset, data_size, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dwrite_chunk(dset_id::hid_t, dxpl_id::hid_t, filters::UInt32, offset::Ptr{hsize_t}, data_size::Csize_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dread_chunk(dset_id, dxpl_id, offset, filters, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dread_chunk(dset_id::hid_t, dxpl_id::hid_t, offset::Ptr{hsize_t}, filters::Ptr{UInt32}, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Diterate(buf, type_id, space_id, op, operator_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Diterate(buf::Ptr{Cvoid}, type_id::hid_t, space_id::hid_t, op::H5D_operator_t, operator_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dvlen_get_buf_size(dset_id, type_id, space_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dvlen_get_buf_size(dset_id::hid_t, type_id::hid_t, space_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dfill(fill, fill_type_id, buf, buf_type_id, space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dfill(fill::Ptr{Cvoid}, fill_type_id::hid_t, buf::Ptr{Cvoid}, buf_type_id::hid_t, space_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dset_extent(dset_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dset_extent(dset_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dflush(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dflush(dset_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Drefresh(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Drefresh(dset_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dscatter(op, op_data, type_id, dst_space_id, dst_buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dscatter(op::H5D_scatter_func_t, op_data::Ptr{Cvoid}, type_id::hid_t, dst_space_id::hid_t, dst_buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dgather(src_space_id, src_buf, type_id, dst_buf_size, dst_buf, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dgather(src_space_id::hid_t, src_buf::Ptr{Cvoid}, type_id::hid_t, dst_buf_size::Csize_t, dst_buf::Ptr{Cvoid}, op::H5D_gather_func_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dclose(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dclose(dset_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ddebug(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ddebug(dset_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dformat_convert(dset_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dformat_convert(dset_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dget_chunk_index_type(did, idx_type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dget_chunk_index_type(did::hid_t, idx_type::Ptr{H5D_chunk_index_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dcreate1(loc_id, name, type_id, space_id, dcpl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dcreate1(loc_id::hid_t, name::Ptr{Cchar}, type_id::hid_t, space_id::hid_t, dcpl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dopen1(loc_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dopen1(loc_id::hid_t, name::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Dextend(dset_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dextend(dset_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Dvlen_reclaim(type_id, space_id, dxpl_id, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Dvlen_reclaim(type_id::hid_t, space_id::hid_t, dxpl_id::hid_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5E_type_t::UInt32 begin
    H5E_MAJOR = 0
    H5E_MINOR = 1
end

function H5Eregister_class(cls_name, lib_name, version)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eregister_class(cls_name::Ptr{Cchar}, lib_name::Ptr{Cchar}, version::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eunregister_class(class_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eunregister_class(class_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eclose_msg(err_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eclose_msg(err_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ecreate_msg(cls, msg_type, msg)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ecreate_msg(cls::hid_t, msg_type::H5E_type_t, msg::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Ecreate_stack()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ecreate_stack()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eget_current_stack()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_current_stack()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eappend_stack(dst_stack_id, src_stack_id, close_source_stack)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eappend_stack(dst_stack_id::hid_t, src_stack_id::hid_t, close_source_stack::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eclose_stack(stack_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eclose_stack(stack_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eget_class_name(class_id, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_class_name(class_id::hid_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eset_current_stack(err_stack_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eset_current_stack(err_stack_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Epop(err_stack, count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Epop(err_stack::hid_t, count::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eget_msg(msg_id, type, msg, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_msg(msg_id::hid_t, type::Ptr{H5E_type_t}, msg::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eget_num(error_stack_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_num(error_stack_id::hid_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

const H5E_major_t = hid_t

const H5E_minor_t = hid_t

struct H5E_error1_t
    maj_num::H5E_major_t
    min_num::H5E_minor_t
    func_name::Ptr{Cchar}
    file_name::Ptr{Cchar}
    line::Cuint
    desc::Ptr{Cchar}
end

# typedef herr_t ( * H5E_walk1_t ) ( int n , H5E_error1_t * err_desc , void * client_data )
const H5E_walk1_t = Ptr{Cvoid}

function H5Eclear1()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eclear1()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Epush1(file, func, line, maj, min, str)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Epush1(file::Ptr{Cchar}, func::Ptr{Cchar}, line::Cuint, maj::H5E_major_t, min::H5E_minor_t, str::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eprint1(stream)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eprint1(stream::Ptr{Libc.FILE})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ewalk1(direction, func, client_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ewalk1(direction::H5E_direction_t, func::H5E_walk1_t, client_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Eget_major(maj)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_major(maj::H5E_major_t)::Ptr{Cchar}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Eget_minor(min)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Eget_minor(min::H5E_minor_t)::Ptr{Cchar}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

@cenum H5ES_status_t::UInt32 begin
    H5ES_STATUS_IN_PROGRESS = 0
    H5ES_STATUS_SUCCEED = 1
    H5ES_STATUS_CANCELED = 2
    H5ES_STATUS_FAIL = 3
end

struct H5ES_op_info_t
    api_name::Ptr{Cchar}
    api_args::Ptr{Cchar}
    app_file_name::Ptr{Cchar}
    app_func_name::Ptr{Cchar}
    app_line_num::Cuint
    op_ins_count::UInt64
    op_ins_ts::UInt64
    op_exec_ts::UInt64
    op_exec_time::UInt64
end

struct H5ES_err_info_t
    api_name::Ptr{Cchar}
    api_args::Ptr{Cchar}
    app_file_name::Ptr{Cchar}
    app_func_name::Ptr{Cchar}
    app_line_num::Cuint
    op_ins_count::UInt64
    op_ins_ts::UInt64
    op_exec_ts::UInt64
    op_exec_time::UInt64
    err_stack_id::hid_t
end

# typedef int ( * H5ES_event_insert_func_t ) ( const H5ES_op_info_t * op_info , void * ctx )
const H5ES_event_insert_func_t = Ptr{Cvoid}

# typedef int ( * H5ES_event_complete_func_t ) ( const H5ES_op_info_t * op_info , H5ES_status_t status , hid_t err_stack , void * ctx )
const H5ES_event_complete_func_t = Ptr{Cvoid}

function H5EScreate()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5EScreate()::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5ESwait(es_id, timeout, num_in_progress, err_occurred)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESwait(es_id::hid_t, timeout::UInt64, num_in_progress::Ptr{Csize_t}, err_occurred::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5EScancel(es_id, num_not_canceled, err_occurred)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5EScancel(es_id::hid_t, num_not_canceled::Ptr{Csize_t}, err_occurred::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESget_count(es_id, count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESget_count(es_id::hid_t, count::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESget_op_counter(es_id, counter)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESget_op_counter(es_id::hid_t, counter::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESget_err_status(es_id, err_occurred)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESget_err_status(es_id::hid_t, err_occurred::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESget_err_count(es_id, num_errs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESget_err_count(es_id::hid_t, num_errs::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESget_err_info(es_id, num_err_info, err_info, err_cleared)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESget_err_info(es_id::hid_t, num_err_info::Csize_t, err_info::Ptr{H5ES_err_info_t}, err_cleared::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESfree_err_info(num_err_info, err_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESfree_err_info(num_err_info::Csize_t, err_info::Ptr{H5ES_err_info_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESregister_insert_func(es_id, func, ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESregister_insert_func(es_id::hid_t, func::H5ES_event_insert_func_t, ctx::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESregister_complete_func(es_id, func, ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESregister_complete_func(es_id::hid_t, func::H5ES_event_complete_func_t, ctx::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESclose(es_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESclose(es_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5F_scope_t::UInt32 begin
    H5F_SCOPE_LOCAL = 0
    H5F_SCOPE_GLOBAL = 1
end

@cenum H5F_close_degree_t::UInt32 begin
    H5F_CLOSE_DEFAULT = 0
    H5F_CLOSE_WEAK = 1
    H5F_CLOSE_SEMI = 2
    H5F_CLOSE_STRONG = 3
end

@cenum H5F_mem_t::Int32 begin
    H5FD_MEM_NOLIST = -1
    H5FD_MEM_DEFAULT = 0
    H5FD_MEM_SUPER = 1
    H5FD_MEM_BTREE = 2
    H5FD_MEM_DRAW = 3
    H5FD_MEM_GHEAP = 4
    H5FD_MEM_LHEAP = 5
    H5FD_MEM_OHDR = 6
    H5FD_MEM_NTYPES = 7
end

struct H5F_sect_info_t
    addr::haddr_t
    size::hsize_t
end

@cenum H5F_libver_t::Int32 begin
    H5F_LIBVER_ERROR = -1
    H5F_LIBVER_EARLIEST = 0
    H5F_LIBVER_V18 = 1
    H5F_LIBVER_V110 = 2
    H5F_LIBVER_V112 = 3
    H5F_LIBVER_V114 = 4
    H5F_LIBVER_NBOUNDS = 5
end

@cenum H5F_fspace_strategy_t::UInt32 begin
    H5F_FSPACE_STRATEGY_FSM_AGGR = 0
    H5F_FSPACE_STRATEGY_PAGE = 1
    H5F_FSPACE_STRATEGY_AGGR = 2
    H5F_FSPACE_STRATEGY_NONE = 3
    H5F_FSPACE_STRATEGY_NTYPES = 4
end

@cenum H5F_file_space_type_t::UInt32 begin
    H5F_FILE_SPACE_DEFAULT = 0
    H5F_FILE_SPACE_ALL_PERSIST = 1
    H5F_FILE_SPACE_ALL = 2
    H5F_FILE_SPACE_AGGR_VFD = 3
    H5F_FILE_SPACE_VFD = 4
    H5F_FILE_SPACE_NTYPES = 5
end

struct H5F_retry_info_t
    nbins::Cuint
    retries::NTuple{21, Ptr{UInt32}}
end

# typedef herr_t ( * H5F_flush_cb_t ) ( hid_t object_id , void * udata )
const H5F_flush_cb_t = Ptr{Cvoid}

function H5Fis_accessible(container_name, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fis_accessible(container_name::Ptr{Cchar}, fapl_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Fcreate(filename, flags, fcpl_id, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fcreate(filename::Ptr{Cchar}, flags::Cuint, fcpl_id::hid_t, fapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fopen(filename, flags, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fopen(filename::Ptr{Cchar}, flags::Cuint, fapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Freopen(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Freopen(file_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fflush(object_id, scope)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fflush(object_id::hid_t, scope::H5F_scope_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fclose(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fclose(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fdelete(filename, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fdelete(filename::Ptr{Cchar}, fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_create_plist(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_create_plist(file_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_access_plist(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_access_plist(file_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_intent(file_id, intent)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_intent(file_id::hid_t, intent::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_fileno(file_id, fileno)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_fileno(file_id::hid_t, fileno::Ptr{Culong})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_obj_count(file_id, types)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_obj_count(file_id::hid_t, types::Cuint)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_obj_ids(file_id, types, max_objs, obj_id_list)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_obj_ids(file_id::hid_t, types::Cuint, max_objs::Csize_t, obj_id_list::Ptr{hid_t})::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_vfd_handle(file_id, fapl, file_handle)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_vfd_handle(file_id::hid_t, fapl::hid_t, file_handle::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fmount(loc, name, child, plist)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fmount(loc::hid_t, name::Ptr{Cchar}, child::hid_t, plist::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Funmount(loc, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Funmount(loc::hid_t, name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_freespace(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_freespace(file_id::hid_t)::hssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_filesize(file_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_filesize(file_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_eoa(file_id, eoa)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_eoa(file_id::hid_t, eoa::Ptr{haddr_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fincrement_filesize(file_id, increment)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fincrement_filesize(file_id::hid_t, increment::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_file_image(file_id, buf_ptr, buf_len)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_file_image(file_id::hid_t, buf_ptr::Ptr{Cvoid}, buf_len::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_mdc_config(file_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_mdc_config(file_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fset_mdc_config(file_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fset_mdc_config(file_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_mdc_hit_rate(file_id, hit_rate_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_mdc_hit_rate(file_id::hid_t, hit_rate_ptr::Ptr{Cdouble})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_mdc_size(file_id, max_size_ptr, min_clean_size_ptr, cur_size_ptr, cur_num_entries_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_mdc_size(file_id::hid_t, max_size_ptr::Ptr{Csize_t}, min_clean_size_ptr::Ptr{Csize_t}, cur_size_ptr::Ptr{Csize_t}, cur_num_entries_ptr::Ptr{Cint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Freset_mdc_hit_rate_stats(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Freset_mdc_hit_rate_stats(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_name(obj_id, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_name(obj_id::hid_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fget_metadata_read_retry_info(file_id, info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_metadata_read_retry_info(file_id::hid_t, info::Ptr{H5F_retry_info_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fstart_swmr_write(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fstart_swmr_write(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_free_sections(file_id, type, nsects, sect_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_free_sections(file_id::hid_t, type::H5F_mem_t, nsects::Csize_t, sect_info::Ptr{H5F_sect_info_t})::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Fclear_elink_file_cache(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fclear_elink_file_cache(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fset_libver_bounds(file_id, low, high)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fset_libver_bounds(file_id::hid_t, low::H5F_libver_t, high::H5F_libver_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fstart_mdc_logging(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fstart_mdc_logging(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fstop_mdc_logging(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fstop_mdc_logging(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_mdc_logging_status(file_id, is_enabled, is_currently_logging)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_mdc_logging_status(file_id::hid_t, is_enabled::Ptr{hbool_t}, is_currently_logging::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Freset_page_buffering_stats(file_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Freset_page_buffering_stats(file_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_page_buffering_stats(file_id, accesses, hits, misses, evictions, bypasses)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_page_buffering_stats(file_id::hid_t, accesses::Ptr{Cuint}, hits::Ptr{Cuint}, misses::Ptr{Cuint}, evictions::Ptr{Cuint}, bypasses::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_mdc_image_info(file_id, image_addr, image_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_mdc_image_info(file_id::hid_t, image_addr::Ptr{haddr_t}, image_size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fget_dset_no_attrs_hint(file_id, minimize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_dset_no_attrs_hint(file_id::hid_t, minimize::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fset_dset_no_attrs_hint(file_id, minimize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fset_dset_no_attrs_hint(file_id::hid_t, minimize::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fformat_convert(fid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fformat_convert(fid::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct var"##Ctag#2578"
    hdr_size::hsize_t
    msgs_info::H5_ih_info_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2578"}, f::Symbol)
    f === :hdr_size && return Ptr{hsize_t}(x + 0)
    f === :msgs_info && return Ptr{H5_ih_info_t}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2578", f::Symbol)
    r = Ref{var"##Ctag#2578"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2578"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2578"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct H5F_info1_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5F_info1_t}, f::Symbol)
    f === :super_ext_size && return Ptr{hsize_t}(x + 0)
    f === :sohm && return Ptr{var"##Ctag#2578"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5F_info1_t, f::Symbol)
    r = Ref{H5F_info1_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5F_info1_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5F_info1_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function H5Fget_info1(obj_id, file_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fget_info1(obj_id::hid_t, file_info::Ptr{H5F_info1_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fset_latest_format(file_id, latest_format)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fset_latest_format(file_id::hid_t, latest_format::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Fis_hdf5(file_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Fis_hdf5(file_name::Ptr{Cchar})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

const H5FD_mem_t = H5F_mem_t

@cenum H5FD_file_image_op_t::UInt32 begin
    H5FD_FILE_IMAGE_OP_NO_OP = 0
    H5FD_FILE_IMAGE_OP_PROPERTY_LIST_SET = 1
    H5FD_FILE_IMAGE_OP_PROPERTY_LIST_COPY = 2
    H5FD_FILE_IMAGE_OP_PROPERTY_LIST_GET = 3
    H5FD_FILE_IMAGE_OP_PROPERTY_LIST_CLOSE = 4
    H5FD_FILE_IMAGE_OP_FILE_OPEN = 5
    H5FD_FILE_IMAGE_OP_FILE_RESIZE = 6
    H5FD_FILE_IMAGE_OP_FILE_CLOSE = 7
end

struct H5FD_file_image_callbacks_t
    image_malloc::Ptr{Cvoid}
    image_memcpy::Ptr{Cvoid}
    image_realloc::Ptr{Cvoid}
    image_free::Ptr{Cvoid}
    udata_copy::Ptr{Cvoid}
    udata_free::Ptr{Cvoid}
    udata::Ptr{Cvoid}
end

struct H5FD_ctl_memcpy_args_t
    dstbuf::Ptr{Cvoid}
    dst_off::hsize_t
    srcbuf::Ptr{Cvoid}
    src_off::hsize_t
    len::Csize_t
end

function H5FDdriver_query(driver_id, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDdriver_query(driver_id::hid_t, flags::Ptr{Culong})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5L_elink_traverse_t ) ( const char * parent_file_name , const char * parent_group_name , const char * child_file_name , const char * child_object_name , unsigned * acc_flags , hid_t fapl_id , void * op_data )
const H5L_elink_traverse_t = Ptr{Cvoid}

function H5Lmove(src_loc, src_name, dst_loc, dst_name, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lmove(src_loc::hid_t, src_name::Ptr{Cchar}, dst_loc::hid_t, dst_name::Ptr{Cchar}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lcopy(src_loc, src_name, dst_loc, dst_name, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lcopy(src_loc::hid_t, src_name::Ptr{Cchar}, dst_loc::hid_t, dst_name::Ptr{Cchar}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lcreate_hard(cur_loc, cur_name, dst_loc, dst_name, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lcreate_hard(cur_loc::hid_t, cur_name::Ptr{Cchar}, dst_loc::hid_t, dst_name::Ptr{Cchar}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lcreate_soft(link_target, link_loc_id, link_name, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lcreate_soft(link_target::Ptr{Cchar}, link_loc_id::hid_t, link_name::Ptr{Cchar}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ldelete(loc_id, name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ldelete(loc_id::hid_t, name::Ptr{Cchar}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ldelete_by_idx(loc_id, group_name, idx_type, order, n, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ldelete_by_idx(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lget_val(loc_id, name, buf, size, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_val(loc_id::hid_t, name::Ptr{Cchar}, buf::Ptr{Cvoid}, size::Csize_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lget_val_by_idx(loc_id, group_name, idx_type, order, n, buf, size, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_val_by_idx(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, buf::Ptr{Cvoid}, size::Csize_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lexists(loc_id, name, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lexists(loc_id::hid_t, name::Ptr{Cchar}, lapl_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Lget_name_by_idx(loc_id, group_name, idx_type, order, n, name, size, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_name_by_idx(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, name::Ptr{Cchar}, size::Csize_t, lapl_id::hid_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Lcreate_ud(link_loc_id, link_name, link_type, udata, udata_size, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lcreate_ud(link_loc_id::hid_t, link_name::Ptr{Cchar}, link_type::H5L_type_t, udata::Ptr{Cvoid}, udata_size::Csize_t, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lis_registered(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lis_registered(id::H5L_type_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Lunpack_elink_val(ext_linkval, link_size, flags, filename, obj_path)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lunpack_elink_val(ext_linkval::Ptr{Cvoid}, link_size::Csize_t, flags::Ptr{Cuint}, filename::Ptr{Ptr{Cchar}}, obj_path::Ptr{Ptr{Cchar}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lcreate_external(file_name, obj_name, link_loc_id, link_name, lcpl_id, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lcreate_external(file_name::Ptr{Cchar}, obj_name::Ptr{Cchar}, link_loc_id::hid_t, link_name::Ptr{Cchar}, lcpl_id::hid_t, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct var"##Ctag#2632"
    data::NTuple{8, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2632"}, f::Symbol)
    f === :address && return Ptr{haddr_t}(x + 0)
    f === :val_size && return Ptr{Csize_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2632", f::Symbol)
    r = Ref{var"##Ctag#2632"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2632"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2632"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5L_info1_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5L_info1_t}, f::Symbol)
    f === :type && return Ptr{H5L_type_t}(x + 0)
    f === :corder_valid && return Ptr{hbool_t}(x + 4)
    f === :corder && return Ptr{Int64}(x + 8)
    f === :cset && return Ptr{H5T_cset_t}(x + 16)
    f === :u && return Ptr{var"##Ctag#2632"}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::H5L_info1_t, f::Symbol)
    r = Ref{H5L_info1_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5L_info1_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5L_info1_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

# typedef herr_t ( * H5L_iterate1_t ) ( hid_t group , const char * name , const H5L_info1_t * info , void * op_data )
const H5L_iterate1_t = Ptr{Cvoid}

function H5Lget_info1(loc_id, name, linfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_info1(loc_id::hid_t, name::Ptr{Cchar}, linfo::Ptr{H5L_info1_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lget_info_by_idx1(loc_id, group_name, idx_type, order, n, linfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lget_info_by_idx1(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, linfo::Ptr{H5L_info1_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Literate1(grp_id, idx_type, order, idx, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Literate1(grp_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, idx::Ptr{hsize_t}, op::H5L_iterate1_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Literate_by_name1(loc_id, group_name, idx_type, order, idx, op, op_data, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Literate_by_name1(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, idx::Ptr{hsize_t}, op::H5L_iterate1_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lvisit1(grp_id, idx_type, order, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lvisit1(grp_id::hid_t, idx_type::H5_index_t, order::H5_iter_order_t, op::H5L_iterate1_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lvisit_by_name1(loc_id, group_name, idx_type, order, op, op_data, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lvisit_by_name1(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, op::H5L_iterate1_t, op_data::Ptr{Cvoid}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5G_storage_type_t::Int32 begin
    H5G_STORAGE_TYPE_UNKNOWN = -1
    H5G_STORAGE_TYPE_SYMBOL_TABLE = 0
    H5G_STORAGE_TYPE_COMPACT = 1
    H5G_STORAGE_TYPE_DENSE = 2
end

struct H5G_info_t
    storage_type::H5G_storage_type_t
    nlinks::hsize_t
    max_corder::Int64
    mounted::hbool_t
end

function H5Gcreate_anon(loc_id, gcpl_id, gapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gcreate_anon(loc_id::hid_t, gcpl_id::hid_t, gapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Gget_create_plist(group_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_create_plist(group_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Gget_info(loc_id, ginfo)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_info(loc_id::hid_t, ginfo::Ptr{H5G_info_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_info_by_name(loc_id, name, ginfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_info_by_name(loc_id::hid_t, name::Ptr{Cchar}, ginfo::Ptr{H5G_info_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_info_by_idx(loc_id, group_name, idx_type, order, n, ginfo, lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_info_by_idx(loc_id::hid_t, group_name::Ptr{Cchar}, idx_type::H5_index_t, order::H5_iter_order_t, n::hsize_t, ginfo::Ptr{H5G_info_t}, lapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gflush(group_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gflush(group_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Grefresh(group_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Grefresh(group_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gclose(group_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gclose(group_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5G_obj_t::Int32 begin
    H5G_UNKNOWN = -1
    H5G_GROUP = 0
    H5G_DATASET = 1
    H5G_TYPE = 2
    H5G_LINK = 3
    H5G_UDLINK = 4
    H5G_RESERVED_5 = 5
    H5G_RESERVED_6 = 6
    H5G_RESERVED_7 = 7
end

# typedef herr_t ( * H5G_iterate_t ) ( hid_t group , const char * name , void * op_data )
const H5G_iterate_t = Ptr{Cvoid}

struct H5G_stat_t
    fileno::NTuple{2, Culong}
    objno::NTuple{2, Culong}
    nlink::Cuint
    type::H5G_obj_t
    mtime::Ctime_t
    linklen::Csize_t
    ohdr::H5O_stat_t
end

function H5Gcreate1(loc_id, name, size_hint)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gcreate1(loc_id::hid_t, name::Ptr{Cchar}, size_hint::Csize_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Gopen1(loc_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gopen1(loc_id::hid_t, name::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Glink(cur_loc_id, type, cur_name, new_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Glink(cur_loc_id::hid_t, type::H5L_type_t, cur_name::Ptr{Cchar}, new_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Glink2(cur_loc_id, cur_name, type, new_loc_id, new_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Glink2(cur_loc_id::hid_t, cur_name::Ptr{Cchar}, type::H5L_type_t, new_loc_id::hid_t, new_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gmove(src_loc_id, src_name, dst_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gmove(src_loc_id::hid_t, src_name::Ptr{Cchar}, dst_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gmove2(src_loc_id, src_name, dst_loc_id, dst_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gmove2(src_loc_id::hid_t, src_name::Ptr{Cchar}, dst_loc_id::hid_t, dst_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gunlink(loc_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gunlink(loc_id::hid_t, name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_linkval(loc_id, name, size, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_linkval(loc_id::hid_t, name::Ptr{Cchar}, size::Csize_t, buf::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gset_comment(loc_id, name, comment)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gset_comment(loc_id::hid_t, name::Ptr{Cchar}, comment::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_comment(loc_id, name, bufsize, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_comment(loc_id::hid_t, name::Ptr{Cchar}, bufsize::Csize_t, buf::Ptr{Cchar})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Giterate(loc_id, name, idx, op, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Giterate(loc_id::hid_t, name::Ptr{Cchar}, idx::Ptr{Cint}, op::H5G_iterate_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_num_objs(loc_id, num_objs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_num_objs(loc_id::hid_t, num_objs::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_objinfo(loc_id, name, follow_link, statbuf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_objinfo(loc_id::hid_t, name::Ptr{Cchar}, follow_link::hbool_t, statbuf::Ptr{H5G_stat_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Gget_objname_by_idx(loc_id, idx, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_objname_by_idx(loc_id::hid_t, idx::hsize_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Gget_objtype_by_idx(loc_id, idx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Gget_objtype_by_idx(loc_id::hid_t, idx::hsize_t)::H5G_obj_t
            finally
                unlock(liblock)
            end
        if result < H5G_obj_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

const H5VL_class_value_t = Cint

@cenum H5VL_subclass_t::UInt32 begin
    H5VL_SUBCLS_NONE = 0
    H5VL_SUBCLS_INFO = 1
    H5VL_SUBCLS_WRAP = 2
    H5VL_SUBCLS_ATTR = 3
    H5VL_SUBCLS_DATASET = 4
    H5VL_SUBCLS_DATATYPE = 5
    H5VL_SUBCLS_FILE = 6
    H5VL_SUBCLS_GROUP = 7
    H5VL_SUBCLS_LINK = 8
    H5VL_SUBCLS_OBJECT = 9
    H5VL_SUBCLS_REQUEST = 10
    H5VL_SUBCLS_BLOB = 11
    H5VL_SUBCLS_TOKEN = 12
end

function H5VLregister_connector_by_name(connector_name, vipl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLregister_connector_by_name(connector_name::Ptr{Cchar}, vipl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLregister_connector_by_value(connector_value, vipl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLregister_connector_by_value(connector_value::H5VL_class_value_t, vipl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLis_connector_registered_by_name(name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLis_connector_registered_by_name(name::Ptr{Cchar})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5VLis_connector_registered_by_value(connector_value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLis_connector_registered_by_value(connector_value::H5VL_class_value_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5VLget_connector_id(obj_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_connector_id(obj_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLget_connector_id_by_name(name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_connector_id_by_name(name::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLget_connector_id_by_value(connector_value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_connector_id_by_value(connector_value::H5VL_class_value_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLget_connector_name(id, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_connector_name(id::hid_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLclose(connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLclose(connector_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLunregister_connector(connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLunregister_connector(connector_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLquery_optional(obj_id, subcls, opt_type, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLquery_optional(obj_id::hid_t, subcls::H5VL_subclass_t, opt_type::Cint, flags::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLobject_is_native(obj_id, is_native)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject_is_native(obj_id::hid_t, is_native::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

const hobj_ref_t = haddr_t

struct hdset_reg_ref_t
    __data::NTuple{12, UInt8}
end

struct var"##Ctag#2579"
    data::NTuple{64, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2579"}, f::Symbol)
    f === :__data && return Ptr{NTuple{64, UInt8}}(x + 0)
    f === :align && return Ptr{Int64}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2579", f::Symbol)
    r = Ref{var"##Ctag#2579"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2579"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2579"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5R_ref_t
    data::NTuple{64, UInt8}
end

function Base.getproperty(x::Ptr{H5R_ref_t}, f::Symbol)
    f === :u && return Ptr{var"##Ctag#2579"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5R_ref_t, f::Symbol)
    r = Ref{H5R_ref_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5R_ref_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5R_ref_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function H5Rcreate_object(loc_id, name, oapl_id, ref_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rcreate_object(loc_id::hid_t, name::Ptr{Cchar}, oapl_id::hid_t, ref_ptr::Ptr{H5R_ref_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Rcreate_region(loc_id, name, space_id, oapl_id, ref_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rcreate_region(loc_id::hid_t, name::Ptr{Cchar}, space_id::hid_t, oapl_id::hid_t, ref_ptr::Ptr{H5R_ref_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Rcreate_attr(loc_id, name, attr_name, oapl_id, ref_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rcreate_attr(loc_id::hid_t, name::Ptr{Cchar}, attr_name::Ptr{Cchar}, oapl_id::hid_t, ref_ptr::Ptr{H5R_ref_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Rdestroy(ref_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rdestroy(ref_ptr::Ptr{H5R_ref_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Rget_type(ref_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_type(ref_ptr::Ptr{H5R_ref_t})::H5R_type_t
            finally
                unlock(liblock)
            end
        if result < H5R_type_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Requal(ref1_ptr, ref2_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Requal(ref1_ptr::Ptr{H5R_ref_t}, ref2_ptr::Ptr{H5R_ref_t})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Rcopy(src_ref_ptr, dst_ref_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rcopy(src_ref_ptr::Ptr{H5R_ref_t}, dst_ref_ptr::Ptr{H5R_ref_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ropen_object(ref_ptr, rapl_id, oapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ropen_object(ref_ptr::Ptr{H5R_ref_t}, rapl_id::hid_t, oapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Ropen_region(ref_ptr, rapl_id, oapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ropen_region(ref_ptr::Ptr{H5R_ref_t}, rapl_id::hid_t, oapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Ropen_attr(ref_ptr, rapl_id, aapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ropen_attr(ref_ptr::Ptr{H5R_ref_t}, rapl_id::hid_t, aapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rget_obj_type3(ref_ptr, rapl_id, obj_type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_obj_type3(ref_ptr::Ptr{H5R_ref_t}, rapl_id::hid_t, obj_type::Ptr{H5O_type_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Rget_file_name(ref_ptr, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_file_name(ref_ptr::Ptr{H5R_ref_t}, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rget_obj_name(ref_ptr, rapl_id, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_obj_name(ref_ptr::Ptr{H5R_ref_t}, rapl_id::hid_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rget_attr_name(ref_ptr, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_attr_name(ref_ptr::Ptr{H5R_ref_t}, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rget_obj_type1(id, ref_type, ref)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_obj_type1(id::hid_t, ref_type::H5R_type_t, ref::Ptr{Cvoid})::H5G_obj_t
            finally
                unlock(liblock)
            end
        if result < H5G_obj_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rdereference1(obj_id, ref_type, ref)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rdereference1(obj_id::hid_t, ref_type::H5R_type_t, ref::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rcreate(ref, loc_id, name, ref_type, space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rcreate(ref::Ptr{Cvoid}, loc_id::hid_t, name::Ptr{Cchar}, ref_type::H5R_type_t, space_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Rget_region(dataset, ref_type, ref)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_region(dataset::hid_t, ref_type::H5R_type_t, ref::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Rget_name(loc_id, ref_type, ref, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Rget_name(loc_id::hid_t, ref_type::H5R_type_t, ref::Ptr{Cvoid}, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

@cenum H5VL_loc_type_t::UInt32 begin
    H5VL_OBJECT_BY_SELF = 0
    H5VL_OBJECT_BY_NAME = 1
    H5VL_OBJECT_BY_IDX = 2
    H5VL_OBJECT_BY_TOKEN = 3
end

struct H5VL_loc_by_name
    name::Ptr{Cchar}
    lapl_id::hid_t
end

const H5VL_loc_by_name_t = H5VL_loc_by_name

struct H5VL_loc_by_idx
    name::Ptr{Cchar}
    idx_type::H5_index_t
    order::H5_iter_order_t
    n::hsize_t
    lapl_id::hid_t
end

const H5VL_loc_by_idx_t = H5VL_loc_by_idx

struct H5VL_loc_by_token
    token::Ptr{H5O_token_t}
end

const H5VL_loc_by_token_t = H5VL_loc_by_token

struct var"##Ctag#2610"
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2610"}, f::Symbol)
    f === :loc_by_token && return Ptr{H5VL_loc_by_token_t}(x + 0)
    f === :loc_by_name && return Ptr{H5VL_loc_by_name_t}(x + 0)
    f === :loc_by_idx && return Ptr{H5VL_loc_by_idx_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2610", f::Symbol)
    r = Ref{var"##Ctag#2610"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2610"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2610"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_loc_params_t
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_loc_params_t}, f::Symbol)
    f === :obj_type && return Ptr{H5I_type_t}(x + 0)
    f === :type && return Ptr{H5VL_loc_type_t}(x + 4)
    f === :loc_data && return Ptr{var"##Ctag#2610"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_loc_params_t, f::Symbol)
    r = Ref{H5VL_loc_params_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_loc_params_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_loc_params_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_optional_args_t
    op_type::Cint
    args::Ptr{Cvoid}
end

@cenum H5VL_attr_get_t::UInt32 begin
    H5VL_ATTR_GET_ACPL = 0
    H5VL_ATTR_GET_INFO = 1
    H5VL_ATTR_GET_NAME = 2
    H5VL_ATTR_GET_SPACE = 3
    H5VL_ATTR_GET_STORAGE_SIZE = 4
    H5VL_ATTR_GET_TYPE = 5
end

struct H5VL_attr_get_name_args_t
    loc_params::H5VL_loc_params_t
    buf_size::Csize_t
    buf::Ptr{Cchar}
    attr_name_len::Ptr{Csize_t}
end

struct H5VL_attr_get_info_args_t
    loc_params::H5VL_loc_params_t
    attr_name::Ptr{Cchar}
    ainfo::Ptr{H5A_info_t}
end

struct var"##Ctag#2603"
    data::NTuple{64, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2603"}, f::Symbol)
    f === :get_acpl && return Ptr{var"##Ctag#2604"}(x + 0)
    f === :get_info && return Ptr{H5VL_attr_get_info_args_t}(x + 0)
    f === :get_name && return Ptr{H5VL_attr_get_name_args_t}(x + 0)
    f === :get_space && return Ptr{var"##Ctag#2605"}(x + 0)
    f === :get_storage_size && return Ptr{var"##Ctag#2606"}(x + 0)
    f === :get_type && return Ptr{var"##Ctag#2607"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2603", f::Symbol)
    r = Ref{var"##Ctag#2603"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2603"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2603"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_attr_get_args_t
    data::NTuple{72, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_attr_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_attr_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2603"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_attr_get_args_t, f::Symbol)
    r = Ref{H5VL_attr_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_attr_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_attr_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_attr_specific_t::UInt32 begin
    H5VL_ATTR_DELETE = 0
    H5VL_ATTR_DELETE_BY_IDX = 1
    H5VL_ATTR_EXISTS = 2
    H5VL_ATTR_ITER = 3
    H5VL_ATTR_RENAME = 4
end

struct H5VL_attr_iterate_args_t
    idx_type::H5_index_t
    order::H5_iter_order_t
    idx::Ptr{hsize_t}
    op::H5A_operator2_t
    op_data::Ptr{Cvoid}
end

struct H5VL_attr_delete_by_idx_args_t
    idx_type::H5_index_t
    order::H5_iter_order_t
    n::hsize_t
end

struct var"##Ctag#2560"
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2560"}, f::Symbol)
    f === :del && return Ptr{var"##Ctag#2561"}(x + 0)
    f === :delete_by_idx && return Ptr{H5VL_attr_delete_by_idx_args_t}(x + 0)
    f === :exists && return Ptr{var"##Ctag#2562"}(x + 0)
    f === :iterate && return Ptr{H5VL_attr_iterate_args_t}(x + 0)
    f === :rename && return Ptr{var"##Ctag#2563"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2560", f::Symbol)
    r = Ref{var"##Ctag#2560"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2560"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2560"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_attr_specific_args_t
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_attr_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_attr_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2560"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_attr_specific_args_t, f::Symbol)
    r = Ref{H5VL_attr_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_attr_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_attr_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_attr_optional_t = Cint

@cenum H5VL_dataset_get_t::UInt32 begin
    H5VL_DATASET_GET_DAPL = 0
    H5VL_DATASET_GET_DCPL = 1
    H5VL_DATASET_GET_SPACE = 2
    H5VL_DATASET_GET_SPACE_STATUS = 3
    H5VL_DATASET_GET_STORAGE_SIZE = 4
    H5VL_DATASET_GET_TYPE = 5
end

struct var"##Ctag#2542"
    data::NTuple{8, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2542"}, f::Symbol)
    f === :get_dapl && return Ptr{var"##Ctag#2543"}(x + 0)
    f === :get_dcpl && return Ptr{var"##Ctag#2544"}(x + 0)
    f === :get_space && return Ptr{var"##Ctag#2545"}(x + 0)
    f === :get_space_status && return Ptr{var"##Ctag#2546"}(x + 0)
    f === :get_storage_size && return Ptr{var"##Ctag#2547"}(x + 0)
    f === :get_type && return Ptr{var"##Ctag#2548"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2542", f::Symbol)
    r = Ref{var"##Ctag#2542"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2542"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2542"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_dataset_get_args_t
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_dataset_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_dataset_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2542"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_dataset_get_args_t, f::Symbol)
    r = Ref{H5VL_dataset_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_dataset_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_dataset_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_dataset_specific_t::UInt32 begin
    H5VL_DATASET_SET_EXTENT = 0
    H5VL_DATASET_FLUSH = 1
    H5VL_DATASET_REFRESH = 2
end

struct var"##Ctag#2628"
    data::NTuple{8, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2628"}, f::Symbol)
    f === :set_extent && return Ptr{var"##Ctag#2629"}(x + 0)
    f === :flush && return Ptr{var"##Ctag#2630"}(x + 0)
    f === :refresh && return Ptr{var"##Ctag#2631"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2628", f::Symbol)
    r = Ref{var"##Ctag#2628"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2628"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2628"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_dataset_specific_args_t
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_dataset_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_dataset_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2628"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_dataset_specific_args_t, f::Symbol)
    r = Ref{H5VL_dataset_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_dataset_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_dataset_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_dataset_optional_t = Cint

@cenum H5VL_datatype_get_t::UInt32 begin
    H5VL_DATATYPE_GET_BINARY_SIZE = 0
    H5VL_DATATYPE_GET_BINARY = 1
    H5VL_DATATYPE_GET_TCPL = 2
end

struct var"##Ctag#2570"
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2570"}, f::Symbol)
    f === :get_binary_size && return Ptr{var"##Ctag#2571"}(x + 0)
    f === :get_binary && return Ptr{var"##Ctag#2572"}(x + 0)
    f === :get_tcpl && return Ptr{var"##Ctag#2573"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2570", f::Symbol)
    r = Ref{var"##Ctag#2570"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2570"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2570"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_datatype_get_args_t
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_datatype_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_datatype_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2570"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_datatype_get_args_t, f::Symbol)
    r = Ref{H5VL_datatype_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_datatype_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_datatype_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_datatype_specific_t::UInt32 begin
    H5VL_DATATYPE_FLUSH = 0
    H5VL_DATATYPE_REFRESH = 1
end

struct var"##Ctag#2622"
    data::NTuple{8, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2622"}, f::Symbol)
    f === :flush && return Ptr{var"##Ctag#2623"}(x + 0)
    f === :refresh && return Ptr{var"##Ctag#2624"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2622", f::Symbol)
    r = Ref{var"##Ctag#2622"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2622"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2622"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_datatype_specific_args_t
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_datatype_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_datatype_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2622"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_datatype_specific_args_t, f::Symbol)
    r = Ref{H5VL_datatype_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_datatype_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_datatype_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_datatype_optional_t = Cint

struct H5VL_file_cont_info_t
    version::Cuint
    feature_flags::UInt64
    token_size::Csize_t
    blob_id_size::Csize_t
end

@cenum H5VL_file_get_t::UInt32 begin
    H5VL_FILE_GET_CONT_INFO = 0
    H5VL_FILE_GET_FAPL = 1
    H5VL_FILE_GET_FCPL = 2
    H5VL_FILE_GET_FILENO = 3
    H5VL_FILE_GET_INTENT = 4
    H5VL_FILE_GET_NAME = 5
    H5VL_FILE_GET_OBJ_COUNT = 6
    H5VL_FILE_GET_OBJ_IDS = 7
end

struct H5VL_file_get_name_args_t
    type::H5I_type_t
    buf_size::Csize_t
    buf::Ptr{Cchar}
    file_name_len::Ptr{Csize_t}
end

struct H5VL_file_get_obj_ids_args_t
    types::Cuint
    max_objs::Csize_t
    oid_list::Ptr{hid_t}
    count::Ptr{Csize_t}
end

struct var"##Ctag#2615"
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2615"}, f::Symbol)
    f === :get_cont_info && return Ptr{var"##Ctag#2616"}(x + 0)
    f === :get_fapl && return Ptr{var"##Ctag#2617"}(x + 0)
    f === :get_fcpl && return Ptr{var"##Ctag#2618"}(x + 0)
    f === :get_fileno && return Ptr{var"##Ctag#2619"}(x + 0)
    f === :get_intent && return Ptr{var"##Ctag#2620"}(x + 0)
    f === :get_name && return Ptr{H5VL_file_get_name_args_t}(x + 0)
    f === :get_obj_count && return Ptr{var"##Ctag#2621"}(x + 0)
    f === :get_obj_ids && return Ptr{H5VL_file_get_obj_ids_args_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2615", f::Symbol)
    r = Ref{var"##Ctag#2615"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2615"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2615"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_file_get_args_t
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_file_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_file_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2615"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_file_get_args_t, f::Symbol)
    r = Ref{H5VL_file_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_file_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_file_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_file_specific_t::UInt32 begin
    H5VL_FILE_FLUSH = 0
    H5VL_FILE_REOPEN = 1
    H5VL_FILE_IS_ACCESSIBLE = 2
    H5VL_FILE_DELETE = 3
    H5VL_FILE_IS_EQUAL = 4
end

struct var"##Ctag#2633"
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2633"}, f::Symbol)
    f === :flush && return Ptr{var"##Ctag#2634"}(x + 0)
    f === :reopen && return Ptr{var"##Ctag#2635"}(x + 0)
    f === :is_accessible && return Ptr{var"##Ctag#2636"}(x + 0)
    f === :del && return Ptr{var"##Ctag#2637"}(x + 0)
    f === :is_equal && return Ptr{var"##Ctag#2638"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2633", f::Symbol)
    r = Ref{var"##Ctag#2633"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2633"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2633"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_file_specific_args_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_file_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_file_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2633"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_file_specific_args_t, f::Symbol)
    r = Ref{H5VL_file_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_file_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_file_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_file_optional_t = Cint

@cenum H5VL_group_get_t::UInt32 begin
    H5VL_GROUP_GET_GCPL = 0
    H5VL_GROUP_GET_INFO = 1
end

struct H5VL_group_get_info_args_t
    loc_params::H5VL_loc_params_t
    ginfo::Ptr{H5G_info_t}
end

struct var"##Ctag#2608"
    data::NTuple{48, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2608"}, f::Symbol)
    f === :get_gcpl && return Ptr{var"##Ctag#2609"}(x + 0)
    f === :get_info && return Ptr{H5VL_group_get_info_args_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2608", f::Symbol)
    r = Ref{var"##Ctag#2608"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2608"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2608"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_group_get_args_t
    data::NTuple{56, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_group_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_group_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2608"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_group_get_args_t, f::Symbol)
    r = Ref{H5VL_group_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_group_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_group_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_group_specific_t::UInt32 begin
    H5VL_GROUP_MOUNT = 0
    H5VL_GROUP_UNMOUNT = 1
    H5VL_GROUP_FLUSH = 2
    H5VL_GROUP_REFRESH = 3
end

struct H5VL_group_spec_mount_args_t
    name::Ptr{Cchar}
    child_file::Ptr{Cvoid}
    fmpl_id::hid_t
end

struct var"##Ctag#2556"
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2556"}, f::Symbol)
    f === :mount && return Ptr{H5VL_group_spec_mount_args_t}(x + 0)
    f === :unmount && return Ptr{var"##Ctag#2557"}(x + 0)
    f === :flush && return Ptr{var"##Ctag#2558"}(x + 0)
    f === :refresh && return Ptr{var"##Ctag#2559"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2556", f::Symbol)
    r = Ref{var"##Ctag#2556"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2556"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2556"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_group_specific_args_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_group_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_group_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2556"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_group_specific_args_t, f::Symbol)
    r = Ref{H5VL_group_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_group_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_group_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_group_optional_t = Cint

@cenum H5VL_link_create_t::UInt32 begin
    H5VL_LINK_CREATE_HARD = 0
    H5VL_LINK_CREATE_SOFT = 1
    H5VL_LINK_CREATE_UD = 2
end

struct var"##Ctag#2552"
    data::NTuple{48, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2552"}, f::Symbol)
    f === :hard && return Ptr{var"##Ctag#2553"}(x + 0)
    f === :soft && return Ptr{var"##Ctag#2554"}(x + 0)
    f === :ud && return Ptr{var"##Ctag#2555"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2552", f::Symbol)
    r = Ref{var"##Ctag#2552"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2552"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2552"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_link_create_args_t
    data::NTuple{56, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_link_create_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_link_create_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2552"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_link_create_args_t, f::Symbol)
    r = Ref{H5VL_link_create_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_link_create_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_link_create_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_link_get_t::UInt32 begin
    H5VL_LINK_GET_INFO = 0
    H5VL_LINK_GET_NAME = 1
    H5VL_LINK_GET_VAL = 2
end

struct var"##Ctag#2611"
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2611"}, f::Symbol)
    f === :get_info && return Ptr{var"##Ctag#2612"}(x + 0)
    f === :get_name && return Ptr{var"##Ctag#2613"}(x + 0)
    f === :get_val && return Ptr{var"##Ctag#2614"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2611", f::Symbol)
    r = Ref{var"##Ctag#2611"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2611"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2611"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_link_get_args_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_link_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_link_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2611"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_link_get_args_t, f::Symbol)
    r = Ref{H5VL_link_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_link_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_link_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_link_specific_t::UInt32 begin
    H5VL_LINK_DELETE = 0
    H5VL_LINK_EXISTS = 1
    H5VL_LINK_ITER = 2
end

struct H5VL_link_iterate_args_t
    recursive::hbool_t
    idx_type::H5_index_t
    order::H5_iter_order_t
    idx_p::Ptr{hsize_t}
    op::H5L_iterate2_t
    op_data::Ptr{Cvoid}
end

struct var"##Ctag#2574"
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2574"}, f::Symbol)
    f === :exists && return Ptr{var"##Ctag#2575"}(x + 0)
    f === :iterate && return Ptr{H5VL_link_iterate_args_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2574", f::Symbol)
    r = Ref{var"##Ctag#2574"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2574"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2574"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_link_specific_args_t
    data::NTuple{48, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_link_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_link_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2574"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_link_specific_args_t, f::Symbol)
    r = Ref{H5VL_link_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_link_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_link_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_link_optional_t = Cint

@cenum H5VL_object_get_t::UInt32 begin
    H5VL_OBJECT_GET_FILE = 0
    H5VL_OBJECT_GET_NAME = 1
    H5VL_OBJECT_GET_TYPE = 2
    H5VL_OBJECT_GET_INFO = 3
end

struct var"##Ctag#2580"
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2580"}, f::Symbol)
    f === :get_file && return Ptr{var"##Ctag#2581"}(x + 0)
    f === :get_name && return Ptr{var"##Ctag#2582"}(x + 0)
    f === :get_type && return Ptr{var"##Ctag#2583"}(x + 0)
    f === :get_info && return Ptr{var"##Ctag#2584"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2580", f::Symbol)
    r = Ref{var"##Ctag#2580"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2580"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2580"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_object_get_args_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_object_get_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_object_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2580"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_object_get_args_t, f::Symbol)
    r = Ref{H5VL_object_get_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_object_get_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_object_get_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

@cenum H5VL_object_specific_t::UInt32 begin
    H5VL_OBJECT_CHANGE_REF_COUNT = 0
    H5VL_OBJECT_EXISTS = 1
    H5VL_OBJECT_LOOKUP = 2
    H5VL_OBJECT_VISIT = 3
    H5VL_OBJECT_FLUSH = 4
    H5VL_OBJECT_REFRESH = 5
end

struct H5VL_object_visit_args_t
    idx_type::H5_index_t
    order::H5_iter_order_t
    fields::Cuint
    op::H5O_iterate2_t
    op_data::Ptr{Cvoid}
end

struct var"##Ctag#2564"
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2564"}, f::Symbol)
    f === :change_rc && return Ptr{var"##Ctag#2565"}(x + 0)
    f === :exists && return Ptr{var"##Ctag#2566"}(x + 0)
    f === :lookup && return Ptr{var"##Ctag#2567"}(x + 0)
    f === :visit && return Ptr{H5VL_object_visit_args_t}(x + 0)
    f === :flush && return Ptr{var"##Ctag#2568"}(x + 0)
    f === :refresh && return Ptr{var"##Ctag#2569"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2564", f::Symbol)
    r = Ref{var"##Ctag#2564"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2564"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2564"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_object_specific_args_t
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_object_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_object_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2564"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_object_specific_args_t, f::Symbol)
    r = Ref{H5VL_object_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_object_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_object_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_object_optional_t = Cint

@cenum H5VL_request_status_t::UInt32 begin
    H5VL_REQUEST_STATUS_IN_PROGRESS = 0
    H5VL_REQUEST_STATUS_SUCCEED = 1
    H5VL_REQUEST_STATUS_FAIL = 2
    H5VL_REQUEST_STATUS_CANT_CANCEL = 3
    H5VL_REQUEST_STATUS_CANCELED = 4
end

@cenum H5VL_request_specific_t::UInt32 begin
    H5VL_REQUEST_GET_ERR_STACK = 0
    H5VL_REQUEST_GET_EXEC_TIME = 1
end

struct var"##Ctag#2539"
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2539"}, f::Symbol)
    f === :get_err_stack && return Ptr{var"##Ctag#2540"}(x + 0)
    f === :get_exec_time && return Ptr{var"##Ctag#2541"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2539", f::Symbol)
    r = Ref{var"##Ctag#2539"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2539"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2539"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_request_specific_args_t
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_request_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_request_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2539"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_request_specific_args_t, f::Symbol)
    r = Ref{H5VL_request_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_request_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_request_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_request_optional_t = Cint

@cenum H5VL_blob_specific_t::UInt32 begin
    H5VL_BLOB_DELETE = 0
    H5VL_BLOB_ISNULL = 1
    H5VL_BLOB_SETNULL = 2
end

struct var"##Ctag#2585"
    data::NTuple{8, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2585"}, f::Symbol)
    f === :is_null && return Ptr{var"##Ctag#2586"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2585", f::Symbol)
    r = Ref{var"##Ctag#2585"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2585"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2585"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_blob_specific_args_t
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_blob_specific_args_t}, f::Symbol)
    f === :op_type && return Ptr{H5VL_blob_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2585"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_blob_specific_args_t, f::Symbol)
    r = Ref{H5VL_blob_specific_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_blob_specific_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_blob_specific_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

const H5VL_blob_optional_t = Cint

struct H5VL_info_class_t
    size::Csize_t
    copy::Ptr{Cvoid}
    cmp::Ptr{Cvoid}
    free::Ptr{Cvoid}
    to_str::Ptr{Cvoid}
    from_str::Ptr{Cvoid}
end

struct H5VL_wrap_class_t
    get_object::Ptr{Cvoid}
    get_wrap_ctx::Ptr{Cvoid}
    wrap_object::Ptr{Cvoid}
    unwrap_object::Ptr{Cvoid}
    free_wrap_ctx::Ptr{Cvoid}
end

struct H5VL_attr_class_t
    create::Ptr{Cvoid}
    open::Ptr{Cvoid}
    read::Ptr{Cvoid}
    write::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
    close::Ptr{Cvoid}
end

struct H5VL_dataset_class_t
    create::Ptr{Cvoid}
    open::Ptr{Cvoid}
    read::Ptr{Cvoid}
    write::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
    close::Ptr{Cvoid}
end

struct H5VL_datatype_class_t
    commit::Ptr{Cvoid}
    open::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
    close::Ptr{Cvoid}
end

struct H5VL_file_class_t
    create::Ptr{Cvoid}
    open::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
    close::Ptr{Cvoid}
end

struct H5VL_group_class_t
    create::Ptr{Cvoid}
    open::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
    close::Ptr{Cvoid}
end

struct H5VL_link_class_t
    create::Ptr{Cvoid}
    copy::Ptr{Cvoid}
    move::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
end

struct H5VL_object_class_t
    open::Ptr{Cvoid}
    copy::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
end

# typedef herr_t ( * H5VL_request_notify_t ) ( void * ctx , H5VL_request_status_t status )
const H5VL_request_notify_t = Ptr{Cvoid}

@cenum H5VL_get_conn_lvl_t::UInt32 begin
    H5VL_GET_CONN_LVL_CURR = 0
    H5VL_GET_CONN_LVL_TERM = 1
end

struct H5VL_introspect_class_t
    get_conn_cls::Ptr{Cvoid}
    get_cap_flags::Ptr{Cvoid}
    opt_query::Ptr{Cvoid}
end

struct H5VL_request_class_t
    wait::Ptr{Cvoid}
    notify::Ptr{Cvoid}
    cancel::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
    free::Ptr{Cvoid}
end

struct H5VL_blob_class_t
    put::Ptr{Cvoid}
    get::Ptr{Cvoid}
    specific::Ptr{Cvoid}
    optional::Ptr{Cvoid}
end

struct H5VL_token_class_t
    cmp::Ptr{Cvoid}
    to_str::Ptr{Cvoid}
    from_str::Ptr{Cvoid}
end

struct H5VL_class_t
    version::Cuint
    value::H5VL_class_value_t
    name::Ptr{Cchar}
    conn_version::Cuint
    cap_flags::UInt64
    initialize::Ptr{Cvoid}
    terminate::Ptr{Cvoid}
    info_cls::H5VL_info_class_t
    wrap_cls::H5VL_wrap_class_t
    attr_cls::H5VL_attr_class_t
    dataset_cls::H5VL_dataset_class_t
    datatype_cls::H5VL_datatype_class_t
    file_cls::H5VL_file_class_t
    group_cls::H5VL_group_class_t
    link_cls::H5VL_link_class_t
    object_cls::H5VL_object_class_t
    introspect_cls::H5VL_introspect_class_t
    request_cls::H5VL_request_class_t
    blob_cls::H5VL_blob_class_t
    token_cls::H5VL_token_class_t
    optional::Ptr{Cvoid}
end

function H5VLregister_connector(cls, vipl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLregister_connector(cls::Ptr{H5VL_class_t}, vipl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLobject(obj_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject(obj_id::hid_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLget_file_type(file_obj, connector_id, dtype_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_file_type(file_obj::Ptr{Cvoid}, connector_id::hid_t, dtype_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLpeek_connector_id_by_name(name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLpeek_connector_id_by_name(name::Ptr{Cchar})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLpeek_connector_id_by_value(value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLpeek_connector_id_by_value(value::H5VL_class_value_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLregister_opt_operation(subcls, op_name, op_val)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLregister_opt_operation(subcls::H5VL_subclass_t, op_name::Ptr{Cchar}, op_val::Ptr{Cint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfind_opt_operation(subcls, op_name, op_val)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfind_opt_operation(subcls::H5VL_subclass_t, op_name::Ptr{Cchar}, op_val::Ptr{Cint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLunregister_opt_operation(subcls, op_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLunregister_opt_operation(subcls::H5VL_subclass_t, op_name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_optional_op(req, connector_id, args)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_optional_op(req::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5VL_map_get_t::UInt32 begin
    H5VL_MAP_GET_MAPL = 0
    H5VL_MAP_GET_MCPL = 1
    H5VL_MAP_GET_KEY_TYPE = 2
    H5VL_MAP_GET_VAL_TYPE = 3
    H5VL_MAP_GET_COUNT = 4
end

@cenum H5VL_map_specific_t::UInt32 begin
    H5VL_MAP_ITER = 0
    H5VL_MAP_DELETE = 1
end

# typedef herr_t ( * H5M_iterate_t ) ( hid_t map_id , const void * key , void * op_data )
const H5M_iterate_t = Ptr{Cvoid}

struct H5VL_map_args_t
    data::NTuple{96, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_map_args_t}, f::Symbol)
    f === :create && return Ptr{var"##Ctag#2639"}(x + 0)
    f === :open && return Ptr{var"##Ctag#2640"}(x + 0)
    f === :get_val && return Ptr{var"##Ctag#2641"}(x + 0)
    f === :exists && return Ptr{var"##Ctag#2642"}(x + 0)
    f === :put && return Ptr{var"##Ctag#2643"}(x + 0)
    f === :get && return Ptr{Cvoid}(x + 0)
    f === :specific && return Ptr{Cvoid}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_map_args_t, f::Symbol)
    r = Ref{H5VL_map_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_map_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_map_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

# typedef void * ( * H5MM_allocate_t ) ( size_t size , void * alloc_info )
const H5MM_allocate_t = Ptr{Cvoid}

# typedef void ( * H5MM_free_t ) ( void * mem , void * free_info )
const H5MM_free_t = Ptr{Cvoid}

@cenum H5S_class_t::Int32 begin
    H5S_NO_CLASS = -1
    H5S_SCALAR = 0
    H5S_SIMPLE = 1
    H5S_NULL = 2
end

@cenum H5S_seloper_t::Int32 begin
    H5S_SELECT_NOOP = -1
    H5S_SELECT_SET = 0
    H5S_SELECT_OR = 1
    H5S_SELECT_AND = 2
    H5S_SELECT_XOR = 3
    H5S_SELECT_NOTB = 4
    H5S_SELECT_NOTA = 5
    H5S_SELECT_APPEND = 6
    H5S_SELECT_PREPEND = 7
    H5S_SELECT_INVALID = 8
end

@cenum H5S_sel_type::Int32 begin
    H5S_SEL_ERROR = -1
    H5S_SEL_NONE = 0
    H5S_SEL_POINTS = 1
    H5S_SEL_HYPERSLABS = 2
    H5S_SEL_ALL = 3
    H5S_SEL_N = 4
end

function H5Sclose(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sclose(space_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Scombine_hyperslab(space_id, op, start, stride, count, block)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Scombine_hyperslab(space_id::hid_t, op::H5S_seloper_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Scombine_select(space1_id, op, space2_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Scombine_select(space1_id::hid_t, op::H5S_seloper_t, space2_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Scopy(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Scopy(space_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Screate(type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Screate(type::H5S_class_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Screate_simple(rank, dims, maxdims)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Screate_simple(rank::Cint, dims::Ptr{hsize_t}, maxdims::Ptr{hsize_t})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sdecode(buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sdecode(buf::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sextent_copy(dst_id, src_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sextent_copy(dst_id::hid_t, src_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sextent_equal(space1_id, space2_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sextent_equal(space1_id::hid_t, space2_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Sget_regular_hyperslab(spaceid, start, stride, count, block)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_regular_hyperslab(spaceid::hid_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Sget_select_bounds(spaceid, start, _end)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_bounds(spaceid::hid_t, start::Ptr{hsize_t}, _end::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sget_select_elem_npoints(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_elem_npoints(spaceid::hid_t)::hssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sget_select_elem_pointlist(spaceid, startpoint, numpoints, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_elem_pointlist(spaceid::hid_t, startpoint::hsize_t, numpoints::hsize_t, buf::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sget_select_hyper_blocklist(spaceid, startblock, numblocks, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_hyper_blocklist(spaceid::hid_t, startblock::hsize_t, numblocks::hsize_t, buf::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sget_select_hyper_nblocks(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_hyper_nblocks(spaceid::hid_t)::hssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sget_select_npoints(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_npoints(spaceid::hid_t)::hssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sget_select_type(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_select_type(spaceid::hid_t)::H5S_sel_type
            finally
                unlock(liblock)
            end
        if result < H5S_sel_type(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sget_simple_extent_dims(space_id, dims, maxdims)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_simple_extent_dims(space_id::hid_t, dims::Ptr{hsize_t}, maxdims::Ptr{hsize_t})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Sget_simple_extent_ndims(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_simple_extent_ndims(space_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Sget_simple_extent_npoints(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_simple_extent_npoints(space_id::hid_t)::hssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sget_simple_extent_type(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sget_simple_extent_type(space_id::hid_t)::H5S_class_t
            finally
                unlock(liblock)
            end
        if result < H5S_class_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sis_regular_hyperslab(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sis_regular_hyperslab(spaceid::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Sis_simple(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sis_simple(space_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Smodify_select(space1_id, op, space2_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Smodify_select(space1_id::hid_t, op::H5S_seloper_t, space2_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Soffset_simple(space_id, offset)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Soffset_simple(space_id::hid_t, offset::Ptr{hssize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ssel_iter_close(sel_iter_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ssel_iter_close(sel_iter_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ssel_iter_create(spaceid, elmt_size, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ssel_iter_create(spaceid::hid_t, elmt_size::Csize_t, flags::Cuint)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Ssel_iter_get_seq_list(sel_iter_id, maxseq, maxelmts, nseq, nelmts, off, len)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ssel_iter_get_seq_list(sel_iter_id::hid_t, maxseq::Csize_t, maxelmts::Csize_t, nseq::Ptr{Csize_t}, nelmts::Ptr{Csize_t}, off::Ptr{hsize_t}, len::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Ssel_iter_reset(sel_iter_id, space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Ssel_iter_reset(sel_iter_id::hid_t, space_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_adjust(spaceid, offset)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_adjust(spaceid::hid_t, offset::Ptr{hssize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_all(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_all(spaceid::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_copy(dst_id, src_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_copy(dst_id::hid_t, src_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_elements(space_id, op, num_elem, coord)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_elements(space_id::hid_t, op::H5S_seloper_t, num_elem::Csize_t, coord::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_hyperslab(space_id, op, start, stride, count, block)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_hyperslab(space_id::hid_t, op::H5S_seloper_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_intersect_block(space_id, start, _end)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_intersect_block(space_id::hid_t, start::Ptr{hsize_t}, _end::Ptr{hsize_t})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Sselect_none(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_none(spaceid::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sselect_project_intersection(src_space_id, dst_space_id, src_intersect_space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_project_intersection(src_space_id::hid_t, dst_space_id::hid_t, src_intersect_space_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Sselect_shape_same(space1_id, space2_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_shape_same(space1_id::hid_t, space2_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Sselect_valid(spaceid)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sselect_valid(spaceid::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Sset_extent_none(space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sset_extent_none(space_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sset_extent_simple(space_id, rank, dims, max)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sset_extent_simple(space_id::hid_t, rank::Cint, dims::Ptr{hsize_t}, max::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Sencode1(obj_id, buf, nalloc)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Sencode1(obj_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5Z_SO_scale_type_t::UInt32 begin
    H5Z_SO_FLOAT_DSCALE = 0
    H5Z_SO_FLOAT_ESCALE = 1
    H5Z_SO_INT = 2
end

@cenum H5Z_EDC_t::Int32 begin
    H5Z_ERROR_EDC = -1
    H5Z_DISABLE_EDC = 0
    H5Z_ENABLE_EDC = 1
    H5Z_NO_EDC = 2
end

@cenum H5Z_cb_return_t::Int32 begin
    H5Z_CB_ERROR = -1
    H5Z_CB_FAIL = 0
    H5Z_CB_CONT = 1
    H5Z_CB_NO = 2
end

# typedef H5Z_cb_return_t ( * H5Z_filter_func_t ) ( H5Z_filter_t filter , void * buf , size_t buf_size , void * op_data )
const H5Z_filter_func_t = Ptr{Cvoid}

function H5Zfilter_avail(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Zfilter_avail(id::H5Z_filter_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Zget_filter_info(filter, filter_config_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Zget_filter_info(filter::H5Z_filter_t, filter_config_flags::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5P_cls_create_func_t ) ( hid_t prop_id , void * create_data )
const H5P_cls_create_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5P_cls_copy_func_t ) ( hid_t new_prop_id , hid_t old_prop_id , void * copy_data )
const H5P_cls_copy_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5P_cls_close_func_t ) ( hid_t prop_id , void * close_data )
const H5P_cls_close_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5P_prp_encode_func_t ) ( const void * value , void * * buf , size_t * size )
const H5P_prp_encode_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5P_prp_decode_func_t ) ( const void * * buf , void * value )
const H5P_prp_decode_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5P_iterate_t ) ( hid_t id , const char * name , void * iter_data )
const H5P_iterate_t = Ptr{Cvoid}

@cenum H5D_selection_io_mode_t::UInt32 begin
    H5D_SELECTION_IO_MODE_DEFAULT = 0
    H5D_SELECTION_IO_MODE_OFF = 1
    H5D_SELECTION_IO_MODE_ON = 2
end

function H5Pclose(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pclose(plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pclose_class(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pclose_class(plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pcopy(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pcopy(plist_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pcopy_prop(dst_id, src_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pcopy_prop(dst_id::hid_t, src_id::hid_t, name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pcreate(cls_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pcreate(cls_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pcreate_class(parent, name, create, create_data, copy, copy_data, close, close_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pcreate_class(parent::hid_t, name::Ptr{Cchar}, create::H5P_cls_create_func_t, create_data::Ptr{Cvoid}, copy::H5P_cls_copy_func_t, copy_data::Ptr{Cvoid}, close::H5P_cls_close_func_t, close_data::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pdecode(buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pdecode(buf::Ptr{Cvoid})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pequal(id1, id2)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pequal(id1::hid_t, id2::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Pexist(plist_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pexist(plist_id::hid_t, name::Ptr{Cchar})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Pget(plist_id, name, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget(plist_id::hid_t, name::Ptr{Cchar}, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_class(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_class(plist_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_class_name(pclass_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_class_name(pclass_id::hid_t)::Ptr{Cchar}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_class_parent(pclass_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_class_parent(pclass_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_nprops(id, nprops)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_nprops(id::hid_t, nprops::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_size(id, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_size(id::hid_t, name::Ptr{Cchar}, size::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pisa_class(plist_id, pclass_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pisa_class(plist_id::hid_t, pclass_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Piterate(id, idx, iter_func, iter_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Piterate(id::hid_t, idx::Ptr{Cint}, iter_func::H5P_iterate_t, iter_data::Ptr{Cvoid})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Premove(plist_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Premove(plist_id::hid_t, name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset(plist_id, name, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset(plist_id::hid_t, name::Ptr{Cchar}, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Punregister(pclass_id, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Punregister(pclass_id::hid_t, name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pall_filters_avail(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pall_filters_avail(plist_id::hid_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5Pget_attr_creation_order(plist_id, crt_order_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_attr_creation_order(plist_id::hid_t, crt_order_flags::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_attr_phase_change(plist_id, max_compact, min_dense)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_attr_phase_change(plist_id::hid_t, max_compact::Ptr{Cuint}, min_dense::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_nfilters(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_nfilters(plist_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Pget_obj_track_times(plist_id, track_times)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_obj_track_times(plist_id::hid_t, track_times::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pmodify_filter(plist_id, filter, flags, cd_nelmts, cd_values)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pmodify_filter(plist_id::hid_t, filter::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, cd_values::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Premove_filter(plist_id, filter)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Premove_filter(plist_id::hid_t, filter::H5Z_filter_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_attr_creation_order(plist_id, crt_order_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_attr_creation_order(plist_id::hid_t, crt_order_flags::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_attr_phase_change(plist_id, max_compact, min_dense)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_attr_phase_change(plist_id::hid_t, max_compact::Cuint, min_dense::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_deflate(plist_id, level)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_deflate(plist_id::hid_t, level::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_filter(plist_id, filter, flags, cd_nelmts, c_values)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_filter(plist_id::hid_t, filter::H5Z_filter_t, flags::Cuint, cd_nelmts::Csize_t, c_values::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fletcher32(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fletcher32(plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_obj_track_times(plist_id, track_times)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_obj_track_times(plist_id::hid_t, track_times::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_file_space_page_size(plist_id, fsp_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_file_space_page_size(plist_id::hid_t, fsp_size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_file_space_strategy(plist_id, strategy, persist, threshold)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_file_space_strategy(plist_id::hid_t, strategy::Ptr{H5F_fspace_strategy_t}, persist::Ptr{hbool_t}, threshold::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_istore_k(plist_id, ik)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_istore_k(plist_id::hid_t, ik::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_shared_mesg_index(plist_id, index_num, mesg_type_flags, min_mesg_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_shared_mesg_index(plist_id::hid_t, index_num::Cuint, mesg_type_flags::Ptr{Cuint}, min_mesg_size::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_shared_mesg_nindexes(plist_id, nindexes)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_shared_mesg_nindexes(plist_id::hid_t, nindexes::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_shared_mesg_phase_change(plist_id, max_list, min_btree)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_shared_mesg_phase_change(plist_id::hid_t, max_list::Ptr{Cuint}, min_btree::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_sizes(plist_id, sizeof_addr, sizeof_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_sizes(plist_id::hid_t, sizeof_addr::Ptr{Csize_t}, sizeof_size::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_sym_k(plist_id, ik, lk)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_sym_k(plist_id::hid_t, ik::Ptr{Cuint}, lk::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_userblock(plist_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_userblock(plist_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_file_space_page_size(plist_id, fsp_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_file_space_page_size(plist_id::hid_t, fsp_size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_file_space_strategy(plist_id, strategy, persist, threshold)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_file_space_strategy(plist_id::hid_t, strategy::H5F_fspace_strategy_t, persist::hbool_t, threshold::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_istore_k(plist_id, ik)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_istore_k(plist_id::hid_t, ik::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_shared_mesg_index(plist_id, index_num, mesg_type_flags, min_mesg_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_shared_mesg_index(plist_id::hid_t, index_num::Cuint, mesg_type_flags::Cuint, min_mesg_size::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_shared_mesg_nindexes(plist_id, nindexes)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_shared_mesg_nindexes(plist_id::hid_t, nindexes::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_shared_mesg_phase_change(plist_id, max_list, min_btree)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_shared_mesg_phase_change(plist_id::hid_t, max_list::Cuint, min_btree::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_sizes(plist_id, sizeof_addr, sizeof_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_sizes(plist_id::hid_t, sizeof_addr::Csize_t, sizeof_size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_sym_k(plist_id, ik, lk)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_sym_k(plist_id::hid_t, ik::Cuint, lk::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_userblock(plist_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_userblock(plist_id::hid_t, size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_alignment(fapl_id, threshold, alignment)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_alignment(fapl_id::hid_t, threshold::Ptr{hsize_t}, alignment::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_cache(plist_id, mdc_nelmts, rdcc_nslots, rdcc_nbytes, rdcc_w0)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_cache(plist_id::hid_t, mdc_nelmts::Ptr{Cint}, rdcc_nslots::Ptr{Csize_t}, rdcc_nbytes::Ptr{Csize_t}, rdcc_w0::Ptr{Cdouble})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_core_write_tracking(fapl_id, is_enabled, page_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_core_write_tracking(fapl_id::hid_t, is_enabled::Ptr{hbool_t}, page_size::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_driver(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_driver(plist_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_driver_info(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_driver_info(plist_id::hid_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_driver_config_str(fapl_id, config_buf, buf_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_driver_config_str(fapl_id::hid_t, config_buf::Ptr{Cchar}, buf_size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_elink_file_cache_size(plist_id, efc_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_elink_file_cache_size(plist_id::hid_t, efc_size::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_evict_on_close(fapl_id, evict_on_close)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_evict_on_close(fapl_id::hid_t, evict_on_close::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_family_offset(fapl_id, offset)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_family_offset(fapl_id::hid_t, offset::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fclose_degree(fapl_id, degree)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fclose_degree(fapl_id::hid_t, degree::Ptr{H5F_close_degree_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_file_image(fapl_id, buf_ptr_ptr, buf_len_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_file_image(fapl_id::hid_t, buf_ptr_ptr::Ptr{Ptr{Cvoid}}, buf_len_ptr::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_file_image_callbacks(fapl_id, callbacks_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_file_image_callbacks(fapl_id::hid_t, callbacks_ptr::Ptr{H5FD_file_image_callbacks_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_file_locking(fapl_id, use_file_locking, ignore_when_disabled)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_file_locking(fapl_id::hid_t, use_file_locking::Ptr{hbool_t}, ignore_when_disabled::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_gc_references(fapl_id, gc_ref)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_gc_references(fapl_id::hid_t, gc_ref::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_libver_bounds(plist_id, low, high)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_libver_bounds(plist_id::hid_t, low::Ptr{H5F_libver_t}, high::Ptr{H5F_libver_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_mdc_config(plist_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_mdc_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_mdc_image_config(plist_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_mdc_image_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_image_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_mdc_log_options(plist_id, is_enabled, location, location_size, start_on_access)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_mdc_log_options(plist_id::hid_t, is_enabled::Ptr{hbool_t}, location::Ptr{Cchar}, location_size::Ptr{Csize_t}, start_on_access::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_meta_block_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_meta_block_size(fapl_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_metadata_read_attempts(plist_id, attempts)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_metadata_read_attempts(plist_id::hid_t, attempts::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_multi_type(fapl_id, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_multi_type(fapl_id::hid_t, type::Ptr{H5FD_mem_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_object_flush_cb(plist_id, func, udata)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_object_flush_cb(plist_id::hid_t, func::Ptr{H5F_flush_cb_t}, udata::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_page_buffer_size(plist_id, buf_size, min_meta_perc, min_raw_perc)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_page_buffer_size(plist_id::hid_t, buf_size::Ptr{Csize_t}, min_meta_perc::Ptr{Cuint}, min_raw_perc::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_sieve_buf_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_sieve_buf_size(fapl_id::hid_t, size::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_small_data_block_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_small_data_block_size(fapl_id::hid_t, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_vol_id(plist_id, vol_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_vol_id(plist_id::hid_t, vol_id::Ptr{hid_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_vol_info(plist_id, vol_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_vol_info(plist_id::hid_t, vol_info::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_alignment(fapl_id, threshold, alignment)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_alignment(fapl_id::hid_t, threshold::hsize_t, alignment::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_cache(plist_id, mdc_nelmts, rdcc_nslots, rdcc_nbytes, rdcc_w0)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_cache(plist_id::hid_t, mdc_nelmts::Cint, rdcc_nslots::Csize_t, rdcc_nbytes::Csize_t, rdcc_w0::Cdouble)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_core_write_tracking(fapl_id, is_enabled, page_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_core_write_tracking(fapl_id::hid_t, is_enabled::hbool_t, page_size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_driver(plist_id, driver_id, driver_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_driver(plist_id::hid_t, driver_id::hid_t, driver_info::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_driver_by_name(plist_id, driver_name, driver_config)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_driver_by_name(plist_id::hid_t, driver_name::Ptr{Cchar}, driver_config::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_driver_by_value(plist_id, driver_value, driver_config)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_driver_by_value(plist_id::hid_t, driver_value::H5FD_class_value_t, driver_config::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_elink_file_cache_size(plist_id, efc_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_elink_file_cache_size(plist_id::hid_t, efc_size::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_evict_on_close(fapl_id, evict_on_close)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_evict_on_close(fapl_id::hid_t, evict_on_close::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_family_offset(fapl_id, offset)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_family_offset(fapl_id::hid_t, offset::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fclose_degree(fapl_id, degree)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fclose_degree(fapl_id::hid_t, degree::H5F_close_degree_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_file_image(fapl_id, buf_ptr, buf_len)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_file_image(fapl_id::hid_t, buf_ptr::Ptr{Cvoid}, buf_len::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_file_image_callbacks(fapl_id, callbacks_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_file_image_callbacks(fapl_id::hid_t, callbacks_ptr::Ptr{H5FD_file_image_callbacks_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_file_locking(fapl_id, use_file_locking, ignore_when_disabled)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_file_locking(fapl_id::hid_t, use_file_locking::hbool_t, ignore_when_disabled::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_gc_references(fapl_id, gc_ref)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_gc_references(fapl_id::hid_t, gc_ref::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_libver_bounds(plist_id, low, high)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_libver_bounds(plist_id::hid_t, low::H5F_libver_t, high::H5F_libver_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_mdc_config(plist_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_mdc_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_mdc_log_options(plist_id, is_enabled, location, start_on_access)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_mdc_log_options(plist_id::hid_t, is_enabled::hbool_t, location::Ptr{Cchar}, start_on_access::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_meta_block_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_meta_block_size(fapl_id::hid_t, size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_metadata_read_attempts(plist_id, attempts)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_metadata_read_attempts(plist_id::hid_t, attempts::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_multi_type(fapl_id, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_multi_type(fapl_id::hid_t, type::H5FD_mem_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_object_flush_cb(plist_id, func, udata)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_object_flush_cb(plist_id::hid_t, func::H5F_flush_cb_t, udata::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_sieve_buf_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_sieve_buf_size(fapl_id::hid_t, size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_small_data_block_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_small_data_block_size(fapl_id::hid_t, size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_vol(plist_id, new_vol_id, new_vol_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_vol(plist_id::hid_t, new_vol_id::hid_t, new_vol_info::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_vol_cap_flags(plist_id, cap_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_vol_cap_flags(plist_id::hid_t, cap_flags::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_all_coll_metadata_ops(plist_id, is_collective)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_all_coll_metadata_ops(plist_id::hid_t, is_collective::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_all_coll_metadata_ops(plist_id, is_collective)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_all_coll_metadata_ops(plist_id::hid_t, is_collective::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_coll_metadata_write(plist_id, is_collective)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_coll_metadata_write(plist_id::hid_t, is_collective::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_coll_metadata_write(plist_id, is_collective)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_coll_metadata_write(plist_id::hid_t, is_collective::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_mdc_image_config(plist_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_mdc_image_config(plist_id::hid_t, config_ptr::Ptr{H5AC_cache_image_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_page_buffer_size(plist_id, buf_size, min_meta_per, min_raw_per)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_page_buffer_size(plist_id::hid_t, buf_size::Csize_t, min_meta_per::Cuint, min_raw_per::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pfill_value_defined(plist, status)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pfill_value_defined(plist::hid_t, status::Ptr{H5D_fill_value_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_alloc_time(plist_id, alloc_time)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_alloc_time(plist_id::hid_t, alloc_time::Ptr{H5D_alloc_time_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_chunk(plist_id, max_ndims, dim)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_chunk(plist_id::hid_t, max_ndims::Cint, dim::Ptr{hsize_t})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Pget_chunk_opts(plist_id, opts)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_chunk_opts(plist_id::hid_t, opts::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_dset_no_attrs_hint(dcpl_id, minimize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_dset_no_attrs_hint(dcpl_id::hid_t, minimize::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_external(plist_id, idx, name_size, name, offset, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_external(plist_id::hid_t, idx::Cuint, name_size::Csize_t, name::Ptr{Cchar}, offset::Ptr{Coff_t}, size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_external_count(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_external_count(plist_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Pget_fill_time(plist_id, fill_time)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fill_time(plist_id::hid_t, fill_time::Ptr{H5D_fill_time_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fill_value(plist_id, type_id, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fill_value(plist_id::hid_t, type_id::hid_t, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_layout(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_layout(plist_id::hid_t)::H5D_layout_t
            finally
                unlock(liblock)
            end
        if result < H5D_layout_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_virtual_count(dcpl_id, count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_count(dcpl_id::hid_t, count::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_virtual_dsetname(dcpl_id, index, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_dsetname(dcpl_id::hid_t, index::Csize_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_virtual_filename(dcpl_id, index, name, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_filename(dcpl_id::hid_t, index::Csize_t, name::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_virtual_srcspace(dcpl_id, index)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_srcspace(dcpl_id::hid_t, index::Csize_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_virtual_vspace(dcpl_id, index)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_vspace(dcpl_id::hid_t, index::Csize_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pset_alloc_time(plist_id, alloc_time)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_alloc_time(plist_id::hid_t, alloc_time::H5D_alloc_time_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_chunk(plist_id, ndims, dim)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_chunk(plist_id::hid_t, ndims::Cint, dim::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_chunk_opts(plist_id, opts)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_chunk_opts(plist_id::hid_t, opts::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_dset_no_attrs_hint(dcpl_id, minimize)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_dset_no_attrs_hint(dcpl_id::hid_t, minimize::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_external(plist_id, name, offset, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_external(plist_id::hid_t, name::Ptr{Cchar}, offset::Coff_t, size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fill_time(plist_id, fill_time)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fill_time(plist_id::hid_t, fill_time::H5D_fill_time_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fill_value(plist_id, type_id, value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fill_value(plist_id::hid_t, type_id::hid_t, value::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_shuffle(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_shuffle(plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_layout(plist_id, layout)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_layout(plist_id::hid_t, layout::H5D_layout_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_nbit(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_nbit(plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_scaleoffset(plist_id, scale_type, scale_factor)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_scaleoffset(plist_id::hid_t, scale_type::H5Z_SO_scale_type_t, scale_factor::Cint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_szip(plist_id, options_mask, pixels_per_block)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_szip(plist_id::hid_t, options_mask::Cuint, pixels_per_block::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_virtual(dcpl_id, vspace_id, src_file_name, src_dset_name, src_space_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_virtual(dcpl_id::hid_t, vspace_id::hid_t, src_file_name::Ptr{Cchar}, src_dset_name::Ptr{Cchar}, src_space_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_append_flush(dapl_id, dims, boundary, func, udata)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_append_flush(dapl_id::hid_t, dims::Cuint, boundary::Ptr{hsize_t}, func::Ptr{H5D_append_cb_t}, udata::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_chunk_cache(dapl_id, rdcc_nslots, rdcc_nbytes, rdcc_w0)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_chunk_cache(dapl_id::hid_t, rdcc_nslots::Ptr{Csize_t}, rdcc_nbytes::Ptr{Csize_t}, rdcc_w0::Ptr{Cdouble})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_efile_prefix(dapl_id, prefix, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_efile_prefix(dapl_id::hid_t, prefix::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_virtual_prefix(dapl_id, prefix, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_prefix(dapl_id::hid_t, prefix::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_virtual_printf_gap(dapl_id, gap_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_printf_gap(dapl_id::hid_t, gap_size::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_virtual_view(dapl_id, view)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_virtual_view(dapl_id::hid_t, view::Ptr{H5D_vds_view_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_append_flush(dapl_id, ndims, boundary, func, udata)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_append_flush(dapl_id::hid_t, ndims::Cuint, boundary::Ptr{hsize_t}, func::H5D_append_cb_t, udata::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_chunk_cache(dapl_id, rdcc_nslots, rdcc_nbytes, rdcc_w0)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_chunk_cache(dapl_id::hid_t, rdcc_nslots::Csize_t, rdcc_nbytes::Csize_t, rdcc_w0::Cdouble)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_efile_prefix(dapl_id, prefix)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_efile_prefix(dapl_id::hid_t, prefix::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_virtual_prefix(dapl_id, prefix)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_virtual_prefix(dapl_id::hid_t, prefix::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_virtual_printf_gap(dapl_id, gap_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_virtual_printf_gap(dapl_id::hid_t, gap_size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_virtual_view(dapl_id, view)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_virtual_view(dapl_id::hid_t, view::H5D_vds_view_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_btree_ratios(plist_id, left, middle, right)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_btree_ratios(plist_id::hid_t, left::Ptr{Cdouble}, middle::Ptr{Cdouble}, right::Ptr{Cdouble})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_buffer(plist_id, tconv, bkg)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_buffer(plist_id::hid_t, tconv::Ptr{Ptr{Cvoid}}, bkg::Ptr{Ptr{Cvoid}})::Csize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_data_transform(plist_id, expression, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_data_transform(plist_id::hid_t, expression::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_edc_check(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_edc_check(plist_id::hid_t)::H5Z_EDC_t
            finally
                unlock(liblock)
            end
        if result < H5Z_EDC_t(0)
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_hyper_vector_size(fapl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_hyper_vector_size(fapl_id::hid_t, size::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_preserve(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_preserve(plist_id::hid_t)::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5Pget_type_conv_cb(dxpl_id, op, operate_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_type_conv_cb(dxpl_id::hid_t, op::Ptr{H5T_conv_except_func_t}, operate_data::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_vlen_mem_manager(plist_id, alloc_func, alloc_info, free_func, free_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_vlen_mem_manager(plist_id::hid_t, alloc_func::Ptr{H5MM_allocate_t}, alloc_info::Ptr{Ptr{Cvoid}}, free_func::Ptr{H5MM_free_t}, free_info::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_btree_ratios(plist_id, left, middle, right)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_btree_ratios(plist_id::hid_t, left::Cdouble, middle::Cdouble, right::Cdouble)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_buffer(plist_id, size, tconv, bkg)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_buffer(plist_id::hid_t, size::Csize_t, tconv::Ptr{Cvoid}, bkg::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_data_transform(plist_id, expression)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_data_transform(plist_id::hid_t, expression::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_edc_check(plist_id, check)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_edc_check(plist_id::hid_t, check::H5Z_EDC_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_filter_callback(plist_id, func, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_filter_callback(plist_id::hid_t, func::H5Z_filter_func_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_hyper_vector_size(plist_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_hyper_vector_size(plist_id::hid_t, size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_preserve(plist_id, status)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_preserve(plist_id::hid_t, status::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_type_conv_cb(dxpl_id, op, operate_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_type_conv_cb(dxpl_id::hid_t, op::H5T_conv_except_func_t, operate_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_vlen_mem_manager(plist_id, alloc_func, alloc_info, free_func, free_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_vlen_mem_manager(plist_id::hid_t, alloc_func::H5MM_allocate_t, alloc_info::Ptr{Cvoid}, free_func::H5MM_free_t, free_info::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_dataset_io_hyperslab_selection(plist_id, rank, op, start, stride, count, block)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_dataset_io_hyperslab_selection(plist_id::hid_t, rank::Cuint, op::H5S_seloper_t, start::Ptr{hsize_t}, stride::Ptr{hsize_t}, count::Ptr{hsize_t}, block::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_selection_io(plist_id, selection_io_mode)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_selection_io(plist_id::hid_t, selection_io_mode::H5D_selection_io_mode_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_selection_io(plist_id, selection_io_mode)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_selection_io(plist_id::hid_t, selection_io_mode::Ptr{H5D_selection_io_mode_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_no_selection_io_cause(plist_id, no_selection_io_cause)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_no_selection_io_cause(plist_id::hid_t, no_selection_io_cause::Ptr{UInt32})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_actual_selection_io_mode(plist_id, actual_selection_io_mode)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_actual_selection_io_mode(plist_id::hid_t, actual_selection_io_mode::Ptr{UInt32})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_modify_write_buf(plist_id, modify_write_buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_modify_write_buf(plist_id::hid_t, modify_write_buf::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_modify_write_buf(plist_id, modify_write_buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_modify_write_buf(plist_id::hid_t, modify_write_buf::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_create_intermediate_group(plist_id, crt_intmd)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_create_intermediate_group(plist_id::hid_t, crt_intmd::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_create_intermediate_group(plist_id, crt_intmd)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_create_intermediate_group(plist_id::hid_t, crt_intmd::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_est_link_info(plist_id, est_num_entries, est_name_len)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_est_link_info(plist_id::hid_t, est_num_entries::Ptr{Cuint}, est_name_len::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_link_creation_order(plist_id, crt_order_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_link_creation_order(plist_id::hid_t, crt_order_flags::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_link_phase_change(plist_id, max_compact, min_dense)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_link_phase_change(plist_id::hid_t, max_compact::Ptr{Cuint}, min_dense::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_local_heap_size_hint(plist_id, size_hint)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_local_heap_size_hint(plist_id::hid_t, size_hint::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_est_link_info(plist_id, est_num_entries, est_name_len)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_est_link_info(plist_id::hid_t, est_num_entries::Cuint, est_name_len::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_link_creation_order(plist_id, crt_order_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_link_creation_order(plist_id::hid_t, crt_order_flags::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_link_phase_change(plist_id, max_compact, min_dense)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_link_phase_change(plist_id::hid_t, max_compact::Cuint, min_dense::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_local_heap_size_hint(plist_id, size_hint)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_local_heap_size_hint(plist_id::hid_t, size_hint::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_char_encoding(plist_id, encoding)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_char_encoding(plist_id::hid_t, encoding::Ptr{H5T_cset_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_char_encoding(plist_id, encoding)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_char_encoding(plist_id::hid_t, encoding::H5T_cset_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_elink_acc_flags(lapl_id, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_elink_acc_flags(lapl_id::hid_t, flags::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_elink_cb(lapl_id, func, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_elink_cb(lapl_id::hid_t, func::Ptr{H5L_elink_traverse_t}, op_data::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_elink_fapl(lapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_elink_fapl(lapl_id::hid_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_elink_prefix(plist_id, prefix, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_elink_prefix(plist_id::hid_t, prefix::Ptr{Cchar}, size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_nlinks(plist_id, nlinks)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_nlinks(plist_id::hid_t, nlinks::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_elink_acc_flags(lapl_id, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_elink_acc_flags(lapl_id::hid_t, flags::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_elink_cb(lapl_id, func, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_elink_cb(lapl_id::hid_t, func::H5L_elink_traverse_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_elink_fapl(lapl_id, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_elink_fapl(lapl_id::hid_t, fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_elink_prefix(plist_id, prefix)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_elink_prefix(plist_id::hid_t, prefix::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_nlinks(plist_id, nlinks)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_nlinks(plist_id::hid_t, nlinks::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Padd_merge_committed_dtype_path(plist_id, path)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Padd_merge_committed_dtype_path(plist_id::hid_t, path::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pfree_merge_committed_dtype_paths(plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pfree_merge_committed_dtype_paths(plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_copy_object(plist_id, copy_options)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_copy_object(plist_id::hid_t, copy_options::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_mcdt_search_cb(plist_id, func, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_mcdt_search_cb(plist_id::hid_t, func::Ptr{H5O_mcdt_search_cb_t}, op_data::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_copy_object(plist_id, copy_options)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_copy_object(plist_id::hid_t, copy_options::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_mcdt_search_cb(plist_id, func, op_data)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_mcdt_search_cb(plist_id::hid_t, func::H5O_mcdt_search_cb_t, op_data::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pregister1(cls_id, name, size, def_value, prp_create, prp_set, prp_get, prp_del, prp_copy, prp_close)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pregister1(cls_id::hid_t, name::Ptr{Cchar}, size::Csize_t, def_value::Ptr{Cvoid}, prp_create::H5P_prp_create_func_t, prp_set::H5P_prp_set_func_t, prp_get::H5P_prp_get_func_t, prp_del::H5P_prp_delete_func_t, prp_copy::H5P_prp_copy_func_t, prp_close::H5P_prp_close_func_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pinsert1(plist_id, name, size, value, prp_set, prp_get, prp_delete, prp_copy, prp_close)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pinsert1(plist_id::hid_t, name::Ptr{Cchar}, size::Csize_t, value::Ptr{Cvoid}, prp_set::H5P_prp_set_func_t, prp_get::H5P_prp_get_func_t, prp_delete::H5P_prp_delete_func_t, prp_copy::H5P_prp_copy_func_t, prp_close::H5P_prp_close_func_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pencode1(plist_id, buf, nalloc)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pencode1(plist_id::hid_t, buf::Ptr{Cvoid}, nalloc::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_filter1(plist_id, filter, flags, cd_nelmts, cd_values, namelen, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_filter1(plist_id::hid_t, filter::Cuint, flags::Ptr{Cuint}, cd_nelmts::Ptr{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{Cchar})::H5Z_filter_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5Pget_filter_by_id1(plist_id, id, flags, cd_nelmts, cd_values, namelen, name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_filter_by_id1(plist_id::hid_t, id::H5Z_filter_t, flags::Ptr{Cuint}, cd_nelmts::Ptr{Csize_t}, cd_values::Ptr{Cuint}, namelen::Csize_t, name::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_version(plist_id, boot, freelist, stab, shhdr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_version(plist_id::hid_t, boot::Ptr{Cuint}, freelist::Ptr{Cuint}, stab::Ptr{Cuint}, shhdr::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_file_space(plist_id, strategy, threshold)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_file_space(plist_id::hid_t, strategy::H5F_file_space_type_t, threshold::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_file_space(plist_id, strategy, threshold)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_file_space(plist_id::hid_t, strategy::Ptr{H5F_file_space_type_t}, threshold::Ptr{hsize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5PL_type_t::Int32 begin
    H5PL_TYPE_ERROR = -1
    H5PL_TYPE_FILTER = 0
    H5PL_TYPE_VOL = 1
    H5PL_TYPE_VFD = 2
    H5PL_TYPE_NONE = 3
end

function H5PLset_loading_state(plugin_control_mask)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLset_loading_state(plugin_control_mask::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLget_loading_state(plugin_control_mask)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLget_loading_state(plugin_control_mask::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLappend(search_path)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLappend(search_path::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLprepend(search_path)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLprepend(search_path::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLreplace(search_path, index)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLreplace(search_path::Ptr{Cchar}, index::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLinsert(search_path, index)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLinsert(search_path::Ptr{Cchar}, index::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLremove(index)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLremove(index::Cuint)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5PLget(index, path_buf, buf_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLget(index::Cuint, path_buf::Ptr{Cchar}, buf_size::Csize_t)::Cssize_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5PLsize(num_paths)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5PLsize(num_paths::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESinsert_request(es_id, connector_id, request)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESinsert_request(es_id::hid_t, connector_id::hid_t, request::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5ESget_requests(es_id, order, connector_ids, requests, array_len, count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5ESget_requests(es_id::hid_t, order::H5_iter_order_t, connector_ids::Ptr{hid_t}, requests::Ptr{Ptr{Cvoid}}, array_len::Csize_t, count::Ptr{Csize_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5FD_class_t
    version::Cuint
    value::H5FD_class_value_t
    name::Ptr{Cchar}
    maxaddr::haddr_t
    fc_degree::H5F_close_degree_t
    terminate::Ptr{Cvoid}
    sb_size::Ptr{Cvoid}
    sb_encode::Ptr{Cvoid}
    sb_decode::Ptr{Cvoid}
    fapl_size::Csize_t
    fapl_get::Ptr{Cvoid}
    fapl_copy::Ptr{Cvoid}
    fapl_free::Ptr{Cvoid}
    dxpl_size::Csize_t
    dxpl_copy::Ptr{Cvoid}
    dxpl_free::Ptr{Cvoid}
    open::Ptr{Cvoid}
    close::Ptr{Cvoid}
    cmp::Ptr{Cvoid}
    query::Ptr{Cvoid}
    get_type_map::Ptr{Cvoid}
    alloc::Ptr{Cvoid}
    free::Ptr{Cvoid}
    get_eoa::Ptr{Cvoid}
    set_eoa::Ptr{Cvoid}
    get_eof::Ptr{Cvoid}
    get_handle::Ptr{Cvoid}
    read::Ptr{Cvoid}
    write::Ptr{Cvoid}
    read_vector::Ptr{Cvoid}
    write_vector::Ptr{Cvoid}
    read_selection::Ptr{Cvoid}
    write_selection::Ptr{Cvoid}
    flush::Ptr{Cvoid}
    truncate::Ptr{Cvoid}
    lock::Ptr{Cvoid}
    unlock::Ptr{Cvoid}
    del::Ptr{Cvoid}
    ctl::Ptr{Cvoid}
    fl_map::NTuple{7, H5FD_mem_t}
end

struct H5FD_t
    driver_id::hid_t
    cls::Ptr{H5FD_class_t}
    fileno::Culong
    access_flags::Cuint
    feature_flags::Culong
    maxaddr::haddr_t
    base_addr::haddr_t
    threshold::hsize_t
    alignment::hsize_t
    paged_aggr::hbool_t
end

struct H5FD_free_t
    addr::haddr_t
    size::hsize_t
    next::Ptr{H5FD_free_t}
end

function H5FDregister(cls)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDregister(cls::Ptr{H5FD_class_t})::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FDis_driver_registered_by_name(driver_name)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDis_driver_registered_by_name(driver_name::Ptr{Cchar})::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5FDis_driver_registered_by_value(driver_value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDis_driver_registered_by_value(driver_value::H5FD_class_value_t)::htri_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result > 0
    end
end

function H5FDunregister(driver_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDunregister(driver_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDopen(name, flags, fapl_id, maxaddr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDopen(name::Ptr{Cchar}, flags::Cuint, fapl_id::hid_t, maxaddr::haddr_t)::Ptr{H5FD_t}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FDclose(file)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDclose(file::Ptr{H5FD_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDcmp(f1, f2)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDcmp(f1::Ptr{H5FD_t}, f2::Ptr{H5FD_t})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5FDquery(f, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDquery(f::Ptr{H5FD_t}, flags::Ptr{Culong})::Cint
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return Int(result)
    end
end

function H5FDalloc(file, type, dxpl_id, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDalloc(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, size::hsize_t)::haddr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FDfree(file, type, dxpl_id, addr, size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDfree(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, addr::haddr_t, size::hsize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDget_eoa(file, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDget_eoa(file::Ptr{H5FD_t}, type::H5FD_mem_t)::haddr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FDset_eoa(file, type, eoa)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDset_eoa(file::Ptr{H5FD_t}, type::H5FD_mem_t, eoa::haddr_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDget_eof(file, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDget_eof(file::Ptr{H5FD_t}, type::H5FD_mem_t)::haddr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5FDget_vfd_handle(file, fapl, file_handle)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDget_vfd_handle(file::Ptr{H5FD_t}, fapl::hid_t, file_handle::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDread(file, type, dxpl_id, addr, size, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDread(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, addr::haddr_t, size::Csize_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDwrite(file, type, dxpl_id, addr, size, buf)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDwrite(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, addr::haddr_t, size::Csize_t, buf::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDread_vector(file, dxpl_id, count, types, addrs, sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDread_vector(file::Ptr{H5FD_t}, dxpl_id::hid_t, count::UInt32, types::Ptr{H5FD_mem_t}, addrs::Ptr{haddr_t}, sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDwrite_vector(file, dxpl_id, count, types, addrs, sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDwrite_vector(file::Ptr{H5FD_t}, dxpl_id::hid_t, count::UInt32, types::Ptr{H5FD_mem_t}, addrs::Ptr{haddr_t}, sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDread_selection(file, type, dxpl_id, count, mem_spaces, file_spaces, offsets, element_sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDread_selection(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, count::UInt32, mem_spaces::Ptr{hid_t}, file_spaces::Ptr{hid_t}, offsets::Ptr{haddr_t}, element_sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDwrite_selection(file, type, dxpl_id, count, mem_spaces, file_spaces, offsets, element_sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDwrite_selection(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, count::UInt32, mem_spaces::Ptr{hid_t}, file_spaces::Ptr{hid_t}, offsets::Ptr{haddr_t}, element_sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDread_vector_from_selection(file, type, dxpl_id, count, mem_spaces, file_spaces, offsets, element_sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDread_vector_from_selection(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, count::UInt32, mem_spaces::Ptr{hid_t}, file_spaces::Ptr{hid_t}, offsets::Ptr{haddr_t}, element_sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDwrite_vector_from_selection(file, type, dxpl_id, count, mem_spaces, file_spaces, offsets, element_sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDwrite_vector_from_selection(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, count::UInt32, mem_spaces::Ptr{hid_t}, file_spaces::Ptr{hid_t}, offsets::Ptr{haddr_t}, element_sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDread_from_selection(file, type, dxpl_id, count, mem_space_ids, file_space_ids, offsets, element_sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDread_from_selection(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, count::UInt32, mem_space_ids::Ptr{hid_t}, file_space_ids::Ptr{hid_t}, offsets::Ptr{haddr_t}, element_sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDwrite_from_selection(file, type, dxpl_id, count, mem_space_ids, file_space_ids, offsets, element_sizes, bufs)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDwrite_from_selection(file::Ptr{H5FD_t}, type::H5FD_mem_t, dxpl_id::hid_t, count::UInt32, mem_space_ids::Ptr{hid_t}, file_space_ids::Ptr{hid_t}, offsets::Ptr{haddr_t}, element_sizes::Ptr{Csize_t}, bufs::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDflush(file, dxpl_id, closing)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDflush(file::Ptr{H5FD_t}, dxpl_id::hid_t, closing::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDtruncate(file, dxpl_id, closing)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDtruncate(file::Ptr{H5FD_t}, dxpl_id::hid_t, closing::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDlock(file, rw)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDlock(file::Ptr{H5FD_t}, rw::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDunlock(file)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDunlock(file::Ptr{H5FD_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDdelete(name, fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDdelete(name::Ptr{Cchar}, fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDctl(file, op_code, flags, input, output)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDctl(file::Ptr{H5FD_t}, op_code::UInt64, flags::UInt64, input::Ptr{Cvoid}, output::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef herr_t ( * H5I_future_realize_func_t ) ( void * future_object , hid_t * actual_object_id )
const H5I_future_realize_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5I_future_discard_func_t ) ( void * future_object )
const H5I_future_discard_func_t = Ptr{Cvoid}

function H5Iregister_future(type, object, realize_cb, discard_cb)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Iregister_future(type::H5I_type_t, object::Ptr{Cvoid}, realize_cb::H5I_future_realize_func_t, discard_cb::H5I_future_discard_func_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

# typedef herr_t ( * H5L_create_func_t ) ( const char * link_name , hid_t loc_group , const void * lnkdata , size_t lnkdata_size , hid_t lcpl_id )
const H5L_create_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5L_move_func_t ) ( const char * new_name , hid_t new_loc , const void * lnkdata , size_t lnkdata_size )
const H5L_move_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5L_copy_func_t ) ( const char * new_name , hid_t new_loc , const void * lnkdata , size_t lnkdata_size )
const H5L_copy_func_t = Ptr{Cvoid}

# typedef hid_t ( * H5L_traverse_func_t ) ( const char * link_name , hid_t cur_group , const void * lnkdata , size_t lnkdata_size , hid_t lapl_id , hid_t dxpl_id )
const H5L_traverse_func_t = Ptr{Cvoid}

# typedef herr_t ( * H5L_delete_func_t ) ( const char * link_name , hid_t file , const void * lnkdata , size_t lnkdata_size )
const H5L_delete_func_t = Ptr{Cvoid}

# typedef ssize_t ( * H5L_query_func_t ) ( const char * link_name , const void * lnkdata , size_t lnkdata_size , void * buf /*out*/ , size_t buf_size )
const H5L_query_func_t = Ptr{Cvoid}

struct H5L_class_t
    version::Cint
    id::H5L_type_t
    comment::Ptr{Cchar}
    create_func::H5L_create_func_t
    move_func::H5L_move_func_t
    copy_func::H5L_copy_func_t
    trav_func::H5L_traverse_func_t
    del_func::H5L_delete_func_t
    query_func::H5L_query_func_t
end

function H5Lregister(cls)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lregister(cls::Ptr{H5L_class_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Lunregister(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Lunregister(id::H5L_type_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

# typedef hid_t ( * H5L_traverse_0_func_t ) ( const char * link_name , hid_t cur_group , const void * lnkdata , size_t lnkdata_size , hid_t lapl_id )
const H5L_traverse_0_func_t = Ptr{Cvoid}

struct H5L_class_0_t
    version::Cint
    id::H5L_type_t
    comment::Ptr{Cchar}
    create_func::H5L_create_func_t
    move_func::H5L_move_func_t
    copy_func::H5L_copy_func_t
    trav_func::H5L_traverse_0_func_t
    del_func::H5L_delete_func_t
    query_func::H5L_query_func_t
end

@cenum H5T_cmd_t::UInt32 begin
    H5T_CONV_INIT = 0
    H5T_CONV_CONV = 1
    H5T_CONV_FREE = 2
end

@cenum H5T_bkg_t::UInt32 begin
    H5T_BKG_NO = 0
    H5T_BKG_TEMP = 1
    H5T_BKG_YES = 2
end

struct H5T_cdata_t
    command::H5T_cmd_t
    need_bkg::H5T_bkg_t
    recalc::hbool_t
    priv::Ptr{Cvoid}
end

@cenum H5T_pers_t::Int32 begin
    H5T_PERS_DONTCARE = -1
    H5T_PERS_HARD = 0
    H5T_PERS_SOFT = 1
end

# typedef herr_t ( * H5T_conv_t ) ( hid_t src_id , hid_t dst_id , H5T_cdata_t * cdata , size_t nelmts , size_t buf_stride , size_t bkg_stride , void * buf , void * bkg , hid_t dset_xfer_plist )
const H5T_conv_t = Ptr{Cvoid}

function H5Tregister(pers, name, src_id, dst_id, func)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tregister(pers::H5T_pers_t, name::Ptr{Cchar}, src_id::hid_t, dst_id::hid_t, func::H5T_conv_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tunregister(pers, name, src_id, dst_id, func)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tunregister(pers::H5T_pers_t, name::Ptr{Cchar}, src_id::hid_t, dst_id::hid_t, func::H5T_conv_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Tfind(src_id, dst_id, pcdata)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Tfind(src_id::hid_t, dst_id::hid_t, pcdata::Ptr{Ptr{H5T_cdata_t}})::H5T_conv_t
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5TSmutex_acquire(lock_count, acquired)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5TSmutex_acquire(lock_count::Cuint, acquired::Ptr{Bool})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5TSmutex_release(lock_count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5TSmutex_release(lock_count::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5TSmutex_get_attempt_count(count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5TSmutex_get_attempt_count(count::Ptr{Cuint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5Z_cb_t
    func::H5Z_filter_func_t
    op_data::Ptr{Cvoid}
end

function H5Zregister(cls)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Zregister(cls::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Zunregister(id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Zunregister(id::H5Z_filter_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5Z_class1_t
    id::H5Z_filter_t
    name::Ptr{Cchar}
    can_apply::H5Z_can_apply_func_t
    set_local::H5Z_set_local_func_t
    filter::H5Z_func_t
end

function H5VLcmp_connector_cls(cmp, connector_id1, connector_id2)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLcmp_connector_cls(cmp::Ptr{Cint}, connector_id1::hid_t, connector_id2::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLwrap_register(obj, type)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLwrap_register(obj::Ptr{Cvoid}, type::H5I_type_t)::hid_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLretrieve_lib_state(state)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLretrieve_lib_state(state::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLstart_lib_state()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLstart_lib_state()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrestore_lib_state(state)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrestore_lib_state(state::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfinish_lib_state()
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfinish_lib_state()::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfree_lib_state(state)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfree_lib_state(state::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLget_object(obj, connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_object(obj::Ptr{Cvoid}, connector_id::hid_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLget_wrap_ctx(obj, connector_id, wrap_ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_wrap_ctx(obj::Ptr{Cvoid}, connector_id::hid_t, wrap_ctx::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLwrap_object(obj, obj_type, connector_id, wrap_ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLwrap_object(obj::Ptr{Cvoid}, obj_type::H5I_type_t, connector_id::hid_t, wrap_ctx::Ptr{Cvoid})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLunwrap_object(obj, connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLunwrap_object(obj::Ptr{Cvoid}, connector_id::hid_t)::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLfree_wrap_ctx(wrap_ctx, connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfree_wrap_ctx(wrap_ctx::Ptr{Cvoid}, connector_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLinitialize(connector_id, vipl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLinitialize(connector_id::hid_t, vipl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLterminate(connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLterminate(connector_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLget_cap_flags(connector_id, cap_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_cap_flags(connector_id::hid_t, cap_flags::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLget_value(connector_id, conn_value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLget_value(connector_id::hid_t, conn_value::Ptr{H5VL_class_value_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLcopy_connector_info(connector_id, dst_vol_info, src_vol_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLcopy_connector_info(connector_id::hid_t, dst_vol_info::Ptr{Ptr{Cvoid}}, src_vol_info::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLcmp_connector_info(cmp, connector_id, info1, info2)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLcmp_connector_info(cmp::Ptr{Cint}, connector_id::hid_t, info1::Ptr{Cvoid}, info2::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfree_connector_info(connector_id, vol_info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfree_connector_info(connector_id::hid_t, vol_info::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLconnector_info_to_str(info, connector_id, str)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLconnector_info_to_str(info::Ptr{Cvoid}, connector_id::hid_t, str::Ptr{Ptr{Cchar}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLconnector_str_to_info(str, connector_id, info)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLconnector_str_to_info(str::Ptr{Cchar}, connector_id::hid_t, info::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLattr_create(obj, loc_params, connector_id, attr_name, type_id, space_id, acpl_id, aapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_create(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, attr_name::Ptr{Cchar}, type_id::hid_t, space_id::hid_t, acpl_id::hid_t, aapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLattr_open(obj, loc_params, connector_id, name, aapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_open(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, aapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLattr_read(attr, connector_id, dtype_id, buf, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_read(attr::Ptr{Cvoid}, connector_id::hid_t, dtype_id::hid_t, buf::Ptr{Cvoid}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLattr_write(attr, connector_id, dtype_id, buf, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_write(attr::Ptr{Cvoid}, connector_id::hid_t, dtype_id::hid_t, buf::Ptr{Cvoid}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLattr_get(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_get(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_attr_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLattr_specific(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_specific(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_attr_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLattr_optional(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_optional(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLattr_close(attr, connector_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLattr_close(attr::Ptr{Cvoid}, connector_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdataset_create(obj, loc_params, connector_id, name, lcpl_id, type_id, space_id, dcpl_id, dapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_create(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, lcpl_id::hid_t, type_id::hid_t, space_id::hid_t, dcpl_id::hid_t, dapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLdataset_open(obj, loc_params, connector_id, name, dapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_open(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, dapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLdataset_read(count, dset, connector_id, mem_type_id, mem_space_id, file_space_id, plist_id, buf, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_read(count::Csize_t, dset::Ptr{Ptr{Cvoid}}, connector_id::hid_t, mem_type_id::Ptr{hid_t}, mem_space_id::Ptr{hid_t}, file_space_id::Ptr{hid_t}, plist_id::hid_t, buf::Ptr{Ptr{Cvoid}}, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdataset_write(count, dset, connector_id, mem_type_id, mem_space_id, file_space_id, plist_id, buf, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_write(count::Csize_t, dset::Ptr{Ptr{Cvoid}}, connector_id::hid_t, mem_type_id::Ptr{hid_t}, mem_space_id::Ptr{hid_t}, file_space_id::Ptr{hid_t}, plist_id::hid_t, buf::Ptr{Ptr{Cvoid}}, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdataset_get(dset, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_get(dset::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_dataset_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdataset_specific(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_specific(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_dataset_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdataset_optional(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_optional(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdataset_close(dset, connector_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdataset_close(dset::Ptr{Cvoid}, connector_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdatatype_commit(obj, loc_params, connector_id, name, type_id, lcpl_id, tcpl_id, tapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdatatype_commit(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, type_id::hid_t, lcpl_id::hid_t, tcpl_id::hid_t, tapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLdatatype_open(obj, loc_params, connector_id, name, tapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdatatype_open(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, tapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLdatatype_get(dt, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdatatype_get(dt::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_datatype_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdatatype_specific(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdatatype_specific(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_datatype_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdatatype_optional(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdatatype_optional(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLdatatype_close(dt, connector_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLdatatype_close(dt::Ptr{Cvoid}, connector_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfile_create(name, flags, fcpl_id, fapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfile_create(name::Ptr{Cchar}, flags::Cuint, fcpl_id::hid_t, fapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLfile_open(name, flags, fapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfile_open(name::Ptr{Cchar}, flags::Cuint, fapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLfile_get(file, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfile_get(file::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_file_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfile_specific(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfile_specific(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_file_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfile_optional(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfile_optional(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLfile_close(file, connector_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLfile_close(file::Ptr{Cvoid}, connector_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLgroup_create(obj, loc_params, connector_id, name, lcpl_id, gcpl_id, gapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLgroup_create(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, lcpl_id::hid_t, gcpl_id::hid_t, gapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLgroup_open(obj, loc_params, connector_id, name, gapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLgroup_open(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, name::Ptr{Cchar}, gapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLgroup_get(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLgroup_get(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_group_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLgroup_specific(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLgroup_specific(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_group_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLgroup_optional(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLgroup_optional(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLgroup_close(grp, connector_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLgroup_close(grp::Ptr{Cvoid}, connector_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLlink_create(args, obj, loc_params, connector_id, lcpl_id, lapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLlink_create(args::Ptr{H5VL_link_create_args_t}, obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, lcpl_id::hid_t, lapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLlink_copy(src_obj, loc_params1, dst_obj, loc_params2, connector_id, lcpl_id, lapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLlink_copy(src_obj::Ptr{Cvoid}, loc_params1::Ptr{H5VL_loc_params_t}, dst_obj::Ptr{Cvoid}, loc_params2::Ptr{H5VL_loc_params_t}, connector_id::hid_t, lcpl_id::hid_t, lapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLlink_move(src_obj, loc_params1, dst_obj, loc_params2, connector_id, lcpl_id, lapl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLlink_move(src_obj::Ptr{Cvoid}, loc_params1::Ptr{H5VL_loc_params_t}, dst_obj::Ptr{Cvoid}, loc_params2::Ptr{H5VL_loc_params_t}, connector_id::hid_t, lcpl_id::hid_t, lapl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLlink_get(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLlink_get(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_link_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLlink_specific(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLlink_specific(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_link_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLlink_optional(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLlink_optional(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLobject_open(obj, loc_params, connector_id, opened_type, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject_open(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, opened_type::Ptr{H5I_type_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::Ptr{Cvoid}
            finally
                unlock(liblock)
            end
        if result == C_NULL
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return result
    end
end

function H5VLobject_copy(src_obj, loc_params1, src_name, dst_obj, loc_params2, dst_name, connector_id, ocpypl_id, lcpl_id, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject_copy(src_obj::Ptr{Cvoid}, loc_params1::Ptr{H5VL_loc_params_t}, src_name::Ptr{Cchar}, dst_obj::Ptr{Cvoid}, loc_params2::Ptr{H5VL_loc_params_t}, dst_name::Ptr{Cchar}, connector_id::hid_t, ocpypl_id::hid_t, lcpl_id::hid_t, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLobject_get(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject_get(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_object_get_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLobject_specific(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject_specific(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_object_specific_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLobject_optional(obj, loc_params, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLobject_optional(obj::Ptr{Cvoid}, loc_params::Ptr{H5VL_loc_params_t}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLintrospect_get_conn_cls(obj, connector_id, lvl, conn_cls)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLintrospect_get_conn_cls(obj::Ptr{Cvoid}, connector_id::hid_t, lvl::H5VL_get_conn_lvl_t, conn_cls::Ptr{Ptr{H5VL_class_t}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLintrospect_get_cap_flags(info, connector_id, cap_flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLintrospect_get_cap_flags(info::Ptr{Cvoid}, connector_id::hid_t, cap_flags::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLintrospect_opt_query(obj, connector_id, subcls, opt_type, flags)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLintrospect_opt_query(obj::Ptr{Cvoid}, connector_id::hid_t, subcls::H5VL_subclass_t, opt_type::Cint, flags::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_wait(req, connector_id, timeout, status)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_wait(req::Ptr{Cvoid}, connector_id::hid_t, timeout::UInt64, status::Ptr{H5VL_request_status_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_notify(req, connector_id, cb, ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_notify(req::Ptr{Cvoid}, connector_id::hid_t, cb::H5VL_request_notify_t, ctx::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_cancel(req, connector_id, status)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_cancel(req::Ptr{Cvoid}, connector_id::hid_t, status::Ptr{H5VL_request_status_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_specific(req, connector_id, args)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_specific(req::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_request_specific_args_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_optional(req, connector_id, args)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_optional(req::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLrequest_free(req, connector_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLrequest_free(req::Ptr{Cvoid}, connector_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLblob_put(obj, connector_id, buf, size, blob_id, ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLblob_put(obj::Ptr{Cvoid}, connector_id::hid_t, buf::Ptr{Cvoid}, size::Csize_t, blob_id::Ptr{Cvoid}, ctx::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLblob_get(obj, connector_id, blob_id, buf, size, ctx)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLblob_get(obj::Ptr{Cvoid}, connector_id::hid_t, blob_id::Ptr{Cvoid}, buf::Ptr{Cvoid}, size::Csize_t, ctx::Ptr{Cvoid})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLblob_specific(obj, connector_id, blob_id, args)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLblob_specific(obj::Ptr{Cvoid}, connector_id::hid_t, blob_id::Ptr{Cvoid}, args::Ptr{H5VL_blob_specific_args_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLblob_optional(obj, connector_id, blob_id, args)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLblob_optional(obj::Ptr{Cvoid}, connector_id::hid_t, blob_id::Ptr{Cvoid}, args::Ptr{H5VL_optional_args_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLtoken_cmp(obj, connector_id, token1, token2, cmp_value)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLtoken_cmp(obj::Ptr{Cvoid}, connector_id::hid_t, token1::Ptr{H5O_token_t}, token2::Ptr{H5O_token_t}, cmp_value::Ptr{Cint})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLtoken_to_str(obj, obj_type, connector_id, token, token_str)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLtoken_to_str(obj::Ptr{Cvoid}, obj_type::H5I_type_t, connector_id::hid_t, token::Ptr{H5O_token_t}, token_str::Ptr{Ptr{Cchar}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLtoken_from_str(obj, obj_type, connector_id, token_str, token)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLtoken_from_str(obj::Ptr{Cvoid}, obj_type::H5I_type_t, connector_id::hid_t, token_str::Ptr{Cchar}, token::Ptr{H5O_token_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLoptional(obj, connector_id, args, dxpl_id, req)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLoptional(obj::Ptr{Cvoid}, connector_id::hid_t, args::Ptr{H5VL_optional_args_t}, dxpl_id::hid_t, req::Ptr{Ptr{Cvoid}})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5VL_native_attr_iterate_old_t
    loc_id::hid_t
    attr_num::Ptr{Cuint}
    op::H5A_operator1_t
    op_data::Ptr{Cvoid}
end

struct H5VL_native_attr_optional_args_t
    data::NTuple{32, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_native_attr_optional_args_t}, f::Symbol)
    f === :iterate_old && return Ptr{H5VL_native_attr_iterate_old_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_native_attr_optional_args_t, f::Symbol)
    r = Ref{H5VL_native_attr_optional_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_native_attr_optional_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_native_attr_optional_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_native_dataset_chunk_read_t
    offset::Ptr{hsize_t}
    filters::UInt32
    buf::Ptr{Cvoid}
end

struct H5VL_native_dataset_chunk_write_t
    offset::Ptr{hsize_t}
    filters::UInt32
    size::UInt32
    buf::Ptr{Cvoid}
end

struct H5VL_native_dataset_get_vlen_buf_size_t
    type_id::hid_t
    space_id::hid_t
    size::Ptr{hsize_t}
end

struct H5VL_native_dataset_get_chunk_storage_size_t
    offset::Ptr{hsize_t}
    size::Ptr{hsize_t}
end

struct H5VL_native_dataset_get_num_chunks_t
    space_id::hid_t
    nchunks::Ptr{hsize_t}
end

struct H5VL_native_dataset_get_chunk_info_by_idx_t
    space_id::hid_t
    chk_index::hsize_t
    offset::Ptr{hsize_t}
    filter_mask::Ptr{Cuint}
    addr::Ptr{haddr_t}
    size::Ptr{hsize_t}
end

struct H5VL_native_dataset_get_chunk_info_by_coord_t
    offset::Ptr{hsize_t}
    filter_mask::Ptr{Cuint}
    addr::Ptr{haddr_t}
    size::Ptr{hsize_t}
end

struct H5VL_native_dataset_optional_args_t
    data::NTuple{48, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_native_dataset_optional_args_t}, f::Symbol)
    f === :get_chunk_idx_type && return Ptr{var"##Ctag#2625"}(x + 0)
    f === :get_chunk_storage_size && return Ptr{H5VL_native_dataset_get_chunk_storage_size_t}(x + 0)
    f === :get_num_chunks && return Ptr{H5VL_native_dataset_get_num_chunks_t}(x + 0)
    f === :get_chunk_info_by_idx && return Ptr{H5VL_native_dataset_get_chunk_info_by_idx_t}(x + 0)
    f === :get_chunk_info_by_coord && return Ptr{H5VL_native_dataset_get_chunk_info_by_coord_t}(x + 0)
    f === :chunk_read && return Ptr{H5VL_native_dataset_chunk_read_t}(x + 0)
    f === :chunk_write && return Ptr{H5VL_native_dataset_chunk_write_t}(x + 0)
    f === :get_vlen_buf_size && return Ptr{H5VL_native_dataset_get_vlen_buf_size_t}(x + 0)
    f === :get_offset && return Ptr{var"##Ctag#2626"}(x + 0)
    f === :chunk_iter && return Ptr{var"##Ctag#2627"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_native_dataset_optional_args_t, f::Symbol)
    r = Ref{H5VL_native_dataset_optional_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_native_dataset_optional_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_native_dataset_optional_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_native_file_get_file_image_t
    buf_size::Csize_t
    buf::Ptr{Cvoid}
    image_len::Ptr{Csize_t}
end

struct H5VL_native_file_get_free_sections_t
    type::H5F_mem_t
    sect_info::Ptr{H5F_sect_info_t}
    nsects::Csize_t
    sect_count::Ptr{Csize_t}
end

struct H5VL_native_file_get_freespace_t
    size::Ptr{hsize_t}
end

struct H5VL_native_file_get_info_t
    type::H5I_type_t
    finfo::Ptr{H5F_info2_t}
end

struct H5VL_native_file_get_mdc_size_t
    max_size::Ptr{Csize_t}
    min_clean_size::Ptr{Csize_t}
    cur_size::Ptr{Csize_t}
    cur_num_entries::Ptr{UInt32}
end

struct H5VL_native_file_get_vfd_handle_t
    fapl_id::hid_t
    file_handle::Ptr{Ptr{Cvoid}}
end

struct H5VL_native_file_get_mdc_logging_status_t
    is_enabled::Ptr{hbool_t}
    is_currently_logging::Ptr{hbool_t}
end

struct H5VL_native_file_get_page_buffering_stats_t
    accesses::Ptr{Cuint}
    hits::Ptr{Cuint}
    misses::Ptr{Cuint}
    evictions::Ptr{Cuint}
    bypasses::Ptr{Cuint}
end

struct H5VL_native_file_get_mdc_image_info_t
    addr::Ptr{haddr_t}
    len::Ptr{hsize_t}
end

struct H5VL_native_file_set_libver_bounds_t
    low::H5F_libver_t
    high::H5F_libver_t
end

struct H5VL_native_file_optional_args_t
    data::NTuple{40, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_native_file_optional_args_t}, f::Symbol)
    f === :get_file_image && return Ptr{H5VL_native_file_get_file_image_t}(x + 0)
    f === :get_free_sections && return Ptr{H5VL_native_file_get_free_sections_t}(x + 0)
    f === :get_freespace && return Ptr{H5VL_native_file_get_freespace_t}(x + 0)
    f === :get_info && return Ptr{H5VL_native_file_get_info_t}(x + 0)
    f === :get_mdc_config && return Ptr{var"##Ctag#2591"}(x + 0)
    f === :get_mdc_hit_rate && return Ptr{var"##Ctag#2592"}(x + 0)
    f === :get_mdc_size && return Ptr{H5VL_native_file_get_mdc_size_t}(x + 0)
    f === :get_size && return Ptr{var"##Ctag#2593"}(x + 0)
    f === :get_vfd_handle && return Ptr{H5VL_native_file_get_vfd_handle_t}(x + 0)
    f === :set_mdc_config && return Ptr{var"##Ctag#2594"}(x + 0)
    f === :get_metadata_read_retry_info && return Ptr{var"##Ctag#2595"}(x + 0)
    f === :get_mdc_logging_status && return Ptr{H5VL_native_file_get_mdc_logging_status_t}(x + 0)
    f === :get_page_buffering_stats && return Ptr{H5VL_native_file_get_page_buffering_stats_t}(x + 0)
    f === :get_mdc_image_info && return Ptr{H5VL_native_file_get_mdc_image_info_t}(x + 0)
    f === :get_eoa && return Ptr{var"##Ctag#2596"}(x + 0)
    f === :increment_filesize && return Ptr{var"##Ctag#2597"}(x + 0)
    f === :set_libver_bounds && return Ptr{H5VL_native_file_set_libver_bounds_t}(x + 0)
    f === :get_min_dset_ohdr_flag && return Ptr{var"##Ctag#2598"}(x + 0)
    f === :set_min_dset_ohdr_flag && return Ptr{var"##Ctag#2599"}(x + 0)
    f === :get_mpi_atomicity && return Ptr{var"##Ctag#2600"}(x + 0)
    f === :set_mpi_atomicity && return Ptr{var"##Ctag#2601"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_native_file_optional_args_t, f::Symbol)
    r = Ref{H5VL_native_file_optional_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_native_file_optional_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_native_file_optional_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_native_group_iterate_old_t
    loc_params::H5VL_loc_params_t
    idx::hsize_t
    last_obj::Ptr{hsize_t}
    op::H5G_iterate_t
    op_data::Ptr{Cvoid}
end

struct H5VL_native_group_get_objinfo_t
    loc_params::H5VL_loc_params_t
    follow_link::hbool_t
    statbuf::Ptr{H5G_stat_t}
end

struct H5VL_native_group_optional_args_t
    data::NTuple{72, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_native_group_optional_args_t}, f::Symbol)
    f === :iterate_old && return Ptr{H5VL_native_group_iterate_old_t}(x + 0)
    f === :get_objinfo && return Ptr{H5VL_native_group_get_objinfo_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_native_group_optional_args_t, f::Symbol)
    r = Ref{H5VL_native_group_optional_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_native_group_optional_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_native_group_optional_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct H5VL_native_object_get_comment_t
    buf_size::Csize_t
    buf::Ptr{Cvoid}
    comment_len::Ptr{Csize_t}
end

struct H5VL_native_object_get_native_info_t
    fields::Cuint
    ninfo::Ptr{H5O_native_info_t}
end

struct H5VL_native_object_optional_args_t
    data::NTuple{24, UInt8}
end

function Base.getproperty(x::Ptr{H5VL_native_object_optional_args_t}, f::Symbol)
    f === :get_comment && return Ptr{H5VL_native_object_get_comment_t}(x + 0)
    f === :set_comment && return Ptr{var"##Ctag#2549"}(x + 0)
    f === :are_mdc_flushes_disabled && return Ptr{var"##Ctag#2550"}(x + 0)
    f === :get_native_info && return Ptr{H5VL_native_object_get_native_info_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::H5VL_native_object_optional_args_t, f::Symbol)
    r = Ref{H5VL_native_object_optional_args_t}(x)
    ptr = Base.unsafe_convert(Ptr{H5VL_native_object_optional_args_t}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{H5VL_native_object_optional_args_t}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

function H5VLnative_addr_to_token(loc_id, addr, token)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLnative_addr_to_token(loc_id::hid_t, addr::haddr_t, token::Ptr{H5O_token_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5VLnative_token_to_addr(loc_id, token, addr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5VLnative_token_to_addr(loc_id::hid_t, token::H5O_token_t, addr::Ptr{haddr_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_core(fapl_id, increment, backing_store)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_core(fapl_id::hid_t, increment::Csize_t, backing_store::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fapl_core(fapl_id, increment, backing_store)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_core(fapl_id::hid_t, increment::Ptr{Csize_t}, backing_store::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_family(fapl_id, memb_size, memb_fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_family(fapl_id::hid_t, memb_size::hsize_t, memb_fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fapl_family(fapl_id, memb_size, memb_fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_family(fapl_id::hid_t, memb_size::Ptr{hsize_t}, memb_fapl_id::Ptr{hid_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_log(fapl_id, logfile, flags, buf_size)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_log(fapl_id::hid_t, logfile::Ptr{Cchar}, flags::Culonglong, buf_size::Csize_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5FD_mirror_fapl_t
    magic::UInt32
    version::UInt32
    handshake_port::Cint
    remote_ip::NTuple{33, Cchar}
end

function H5Pget_fapl_mirror(fapl_id, fa_out)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_mirror(fapl_id::hid_t, fa_out::Ptr{H5FD_mirror_fapl_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_mirror(fapl_id, fa)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_mirror(fapl_id::hid_t, fa::Ptr{H5FD_mirror_fapl_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_multi(fapl_id, memb_map, memb_fapl, memb_name, memb_addr, relax)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_multi(fapl_id::hid_t, memb_map::Ptr{H5FD_mem_t}, memb_fapl::Ptr{hid_t}, memb_name::Ptr{Ptr{Cchar}}, memb_addr::Ptr{haddr_t}, relax::hbool_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fapl_multi(fapl_id, memb_map, memb_fapl, memb_name, memb_addr, relax)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_multi(fapl_id::hid_t, memb_map::Ptr{H5FD_mem_t}, memb_fapl::Ptr{hid_t}, memb_name::Ptr{Ptr{Cchar}}, memb_addr::Ptr{haddr_t}, relax::Ptr{hbool_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_split(fapl, meta_ext, meta_plist_id, raw_ext, raw_plist_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_split(fapl::hid_t, meta_ext::Ptr{Cchar}, meta_plist_id::hid_t, raw_ext::Ptr{Cchar}, raw_plist_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

@cenum H5FD_onion_target_file_constant_t::UInt32 begin
    H5FD_ONION_STORE_TARGET_ONION = 0
end

struct H5FD_onion_fapl_info_t
    version::UInt8
    backing_fapl_id::hid_t
    page_size::UInt32
    store_target::H5FD_onion_target_file_constant_t
    revision_num::UInt64
    force_write_open::UInt8
    creation_flags::UInt8
    comment::NTuple{256, Cchar}
end

function H5Pget_fapl_onion(fapl_id, fa_out)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_onion(fapl_id::hid_t, fa_out::Ptr{H5FD_onion_fapl_info_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_onion(fapl_id, fa)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_onion(fapl_id::hid_t, fa::Ptr{H5FD_onion_fapl_info_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5FDonion_get_revision_count(filename, fapl_id, revision_count)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5FDonion_get_revision_count(filename::Ptr{Cchar}, fapl_id::hid_t, revision_count::Ptr{UInt64})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5FD_ros3_fapl_t
    version::Int32
    authenticate::hbool_t
    aws_region::NTuple{33, Cchar}
    secret_id::NTuple{129, Cchar}
    secret_key::NTuple{129, Cchar}
end

function H5Pget_fapl_ros3(fapl_id, fa_out)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_ros3(fapl_id::hid_t, fa_out::Ptr{H5FD_ros3_fapl_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_ros3(fapl_id, fa)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_ros3(fapl_id::hid_t, fa::Ptr{H5FD_ros3_fapl_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fapl_ros3_token(fapl_id, size, token)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_ros3_token(fapl_id::hid_t, size::Csize_t, token::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_ros3_token(fapl_id, token)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_ros3_token(fapl_id::hid_t, token::Ptr{Cchar})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_sec2(fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_sec2(fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5FD_splitter_vfd_config_t
    magic::Int32
    version::Cuint
    rw_fapl_id::hid_t
    wo_fapl_id::hid_t
    wo_path::NTuple{4097, Cchar}
    log_file_path::NTuple{4097, Cchar}
    ignore_wo_errs::hbool_t
end

function H5Pset_fapl_splitter(fapl_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_splitter(fapl_id::hid_t, config_ptr::Ptr{H5FD_splitter_vfd_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pget_fapl_splitter(fapl_id, config_ptr)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pget_fapl_splitter(fapl_id::hid_t, config_ptr::Ptr{H5FD_splitter_vfd_config_t})::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

function H5Pset_fapl_stdio(fapl_id)
    begin
        lock(liblock)
        result = try
                @ccall libhdf5.H5Pset_fapl_stdio(fapl_id::hid_t)::herr_t
            finally
                unlock(liblock)
            end
        if result < 0
            err_id = h5e_get_current_stack()
            if h5e_get_num(err_id) > 0
                throw(H5Error(err_id))
            else
                h5e_close_stack(err_id)
            end
        end
        return nothing
    end
end

struct H5VL_pass_through_info_t
    under_vol_id::hid_t
    under_vol_info::Ptr{Cvoid}
end

struct var"##Ctag#2540"
    err_stack_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2540"}, f::Symbol)
    f === :err_stack_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2540", f::Symbol)
    r = Ref{var"##Ctag#2540"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2540"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2540"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2541"
    exec_ts::Ptr{UInt64}
    exec_time::Ptr{UInt64}
end
function Base.getproperty(x::Ptr{var"##Ctag#2541"}, f::Symbol)
    f === :exec_ts && return Ptr{Ptr{UInt64}}(x + 0)
    f === :exec_time && return Ptr{Ptr{UInt64}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2541", f::Symbol)
    r = Ref{var"##Ctag#2541"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2541"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2541"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2543"
    dapl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2543"}, f::Symbol)
    f === :dapl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2543", f::Symbol)
    r = Ref{var"##Ctag#2543"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2543"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2543"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2544"
    dcpl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2544"}, f::Symbol)
    f === :dcpl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2544", f::Symbol)
    r = Ref{var"##Ctag#2544"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2544"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2544"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2545"
    space_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2545"}, f::Symbol)
    f === :space_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2545", f::Symbol)
    r = Ref{var"##Ctag#2545"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2545"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2545"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2546"
    status::Ptr{H5D_space_status_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2546"}, f::Symbol)
    f === :status && return Ptr{Ptr{H5D_space_status_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2546", f::Symbol)
    r = Ref{var"##Ctag#2546"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2546"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2546"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2547"
    storage_size::Ptr{hsize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2547"}, f::Symbol)
    f === :storage_size && return Ptr{Ptr{hsize_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2547", f::Symbol)
    r = Ref{var"##Ctag#2547"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2547"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2547"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2548"
    type_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2548"}, f::Symbol)
    f === :type_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2548", f::Symbol)
    r = Ref{var"##Ctag#2548"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2548"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2548"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2549"
    comment::Ptr{Cchar}
end
function Base.getproperty(x::Ptr{var"##Ctag#2549"}, f::Symbol)
    f === :comment && return Ptr{Ptr{Cchar}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2549", f::Symbol)
    r = Ref{var"##Ctag#2549"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2549"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2549"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2550"
    flag::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2550"}, f::Symbol)
    f === :flag && return Ptr{Ptr{hbool_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2550", f::Symbol)
    r = Ref{var"##Ctag#2550"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2550"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2550"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2553"
    curr_obj::Ptr{Cvoid}
    curr_loc_params::H5VL_loc_params_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2553"}, f::Symbol)
    f === :curr_obj && return Ptr{Ptr{Cvoid}}(x + 0)
    f === :curr_loc_params && return Ptr{H5VL_loc_params_t}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2553", f::Symbol)
    r = Ref{var"##Ctag#2553"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2553"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2553"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2554"
    target::Ptr{Cchar}
end
function Base.getproperty(x::Ptr{var"##Ctag#2554"}, f::Symbol)
    f === :target && return Ptr{Ptr{Cchar}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2554", f::Symbol)
    r = Ref{var"##Ctag#2554"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2554"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2554"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2555"
    type::H5L_type_t
    buf::Ptr{Cvoid}
    buf_size::Csize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2555"}, f::Symbol)
    f === :type && return Ptr{H5L_type_t}(x + 0)
    f === :buf && return Ptr{Ptr{Cvoid}}(x + 8)
    f === :buf_size && return Ptr{Csize_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2555", f::Symbol)
    r = Ref{var"##Ctag#2555"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2555"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2555"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2557"
    name::Ptr{Cchar}
end
function Base.getproperty(x::Ptr{var"##Ctag#2557"}, f::Symbol)
    f === :name && return Ptr{Ptr{Cchar}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2557", f::Symbol)
    r = Ref{var"##Ctag#2557"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2557"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2557"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2558"
    grp_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2558"}, f::Symbol)
    f === :grp_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2558", f::Symbol)
    r = Ref{var"##Ctag#2558"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2558"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2558"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2559"
    grp_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2559"}, f::Symbol)
    f === :grp_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2559", f::Symbol)
    r = Ref{var"##Ctag#2559"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2559"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2559"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2561"
    name::Ptr{Cchar}
end
function Base.getproperty(x::Ptr{var"##Ctag#2561"}, f::Symbol)
    f === :name && return Ptr{Ptr{Cchar}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2561", f::Symbol)
    r = Ref{var"##Ctag#2561"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2561"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2561"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2562"
    name::Ptr{Cchar}
    exists::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2562"}, f::Symbol)
    f === :name && return Ptr{Ptr{Cchar}}(x + 0)
    f === :exists && return Ptr{Ptr{hbool_t}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2562", f::Symbol)
    r = Ref{var"##Ctag#2562"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2562"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2562"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2563"
    old_name::Ptr{Cchar}
    new_name::Ptr{Cchar}
end
function Base.getproperty(x::Ptr{var"##Ctag#2563"}, f::Symbol)
    f === :old_name && return Ptr{Ptr{Cchar}}(x + 0)
    f === :new_name && return Ptr{Ptr{Cchar}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2563", f::Symbol)
    r = Ref{var"##Ctag#2563"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2563"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2563"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2565"
    delta::Cint
end
function Base.getproperty(x::Ptr{var"##Ctag#2565"}, f::Symbol)
    f === :delta && return Ptr{Cint}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2565", f::Symbol)
    r = Ref{var"##Ctag#2565"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2565"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2565"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2566"
    exists::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2566"}, f::Symbol)
    f === :exists && return Ptr{Ptr{hbool_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2566", f::Symbol)
    r = Ref{var"##Ctag#2566"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2566"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2566"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2567"
    token_ptr::Ptr{H5O_token_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2567"}, f::Symbol)
    f === :token_ptr && return Ptr{Ptr{H5O_token_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2567", f::Symbol)
    r = Ref{var"##Ctag#2567"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2567"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2567"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2568"
    obj_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2568"}, f::Symbol)
    f === :obj_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2568", f::Symbol)
    r = Ref{var"##Ctag#2568"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2568"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2568"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2569"
    obj_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2569"}, f::Symbol)
    f === :obj_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2569", f::Symbol)
    r = Ref{var"##Ctag#2569"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2569"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2569"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2571"
    size::Ptr{Csize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2571"}, f::Symbol)
    f === :size && return Ptr{Ptr{Csize_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2571", f::Symbol)
    r = Ref{var"##Ctag#2571"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2571"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2571"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2572"
    buf::Ptr{Cvoid}
    buf_size::Csize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2572"}, f::Symbol)
    f === :buf && return Ptr{Ptr{Cvoid}}(x + 0)
    f === :buf_size && return Ptr{Csize_t}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2572", f::Symbol)
    r = Ref{var"##Ctag#2572"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2572"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2572"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2573"
    tcpl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2573"}, f::Symbol)
    f === :tcpl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2573", f::Symbol)
    r = Ref{var"##Ctag#2573"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2573"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2573"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2575"
    exists::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2575"}, f::Symbol)
    f === :exists && return Ptr{Ptr{hbool_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2575", f::Symbol)
    r = Ref{var"##Ctag#2575"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2575"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2575"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2581"
    file::Ptr{Ptr{Cvoid}}
end
function Base.getproperty(x::Ptr{var"##Ctag#2581"}, f::Symbol)
    f === :file && return Ptr{Ptr{Ptr{Cvoid}}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2581", f::Symbol)
    r = Ref{var"##Ctag#2581"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2581"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2581"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2582"
    buf_size::Csize_t
    buf::Ptr{Cchar}
    name_len::Ptr{Csize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2582"}, f::Symbol)
    f === :buf_size && return Ptr{Csize_t}(x + 0)
    f === :buf && return Ptr{Ptr{Cchar}}(x + 8)
    f === :name_len && return Ptr{Ptr{Csize_t}}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2582", f::Symbol)
    r = Ref{var"##Ctag#2582"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2582"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2582"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2583"
    obj_type::Ptr{H5O_type_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2583"}, f::Symbol)
    f === :obj_type && return Ptr{Ptr{H5O_type_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2583", f::Symbol)
    r = Ref{var"##Ctag#2583"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2583"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2583"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2584"
    fields::Cuint
    oinfo::Ptr{H5O_info2_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2584"}, f::Symbol)
    f === :fields && return Ptr{Cuint}(x + 0)
    f === :oinfo && return Ptr{Ptr{H5O_info2_t}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2584", f::Symbol)
    r = Ref{var"##Ctag#2584"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2584"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2584"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2586"
    isnull::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2586"}, f::Symbol)
    f === :isnull && return Ptr{Ptr{hbool_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2586", f::Symbol)
    r = Ref{var"##Ctag#2586"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2586"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2586"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2591"
    config::Ptr{H5AC_cache_config_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2591"}, f::Symbol)
    f === :config && return Ptr{Ptr{H5AC_cache_config_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2591", f::Symbol)
    r = Ref{var"##Ctag#2591"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2591"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2591"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2592"
    hit_rate::Ptr{Cdouble}
end
function Base.getproperty(x::Ptr{var"##Ctag#2592"}, f::Symbol)
    f === :hit_rate && return Ptr{Ptr{Cdouble}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2592", f::Symbol)
    r = Ref{var"##Ctag#2592"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2592"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2592"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2593"
    size::Ptr{hsize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2593"}, f::Symbol)
    f === :size && return Ptr{Ptr{hsize_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2593", f::Symbol)
    r = Ref{var"##Ctag#2593"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2593"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2593"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2594"
    config::Ptr{H5AC_cache_config_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2594"}, f::Symbol)
    f === :config && return Ptr{Ptr{H5AC_cache_config_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2594", f::Symbol)
    r = Ref{var"##Ctag#2594"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2594"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2594"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2595"
    info::Ptr{H5F_retry_info_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2595"}, f::Symbol)
    f === :info && return Ptr{Ptr{H5F_retry_info_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2595", f::Symbol)
    r = Ref{var"##Ctag#2595"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2595"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2595"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2596"
    eoa::Ptr{haddr_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2596"}, f::Symbol)
    f === :eoa && return Ptr{Ptr{haddr_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2596", f::Symbol)
    r = Ref{var"##Ctag#2596"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2596"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2596"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2597"
    increment::hsize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2597"}, f::Symbol)
    f === :increment && return Ptr{hsize_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2597", f::Symbol)
    r = Ref{var"##Ctag#2597"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2597"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2597"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2598"
    minimize::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2598"}, f::Symbol)
    f === :minimize && return Ptr{Ptr{hbool_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2598", f::Symbol)
    r = Ref{var"##Ctag#2598"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2598"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2598"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2599"
    minimize::hbool_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2599"}, f::Symbol)
    f === :minimize && return Ptr{hbool_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2599", f::Symbol)
    r = Ref{var"##Ctag#2599"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2599"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2599"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2600"
    flag::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2600"}, f::Symbol)
    f === :flag && return Ptr{Ptr{hbool_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2600", f::Symbol)
    r = Ref{var"##Ctag#2600"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2600"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2600"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2601"
    flag::hbool_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2601"}, f::Symbol)
    f === :flag && return Ptr{hbool_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2601", f::Symbol)
    r = Ref{var"##Ctag#2601"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2601"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2601"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2604"
    acpl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2604"}, f::Symbol)
    f === :acpl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2604", f::Symbol)
    r = Ref{var"##Ctag#2604"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2604"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2604"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2605"
    space_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2605"}, f::Symbol)
    f === :space_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2605", f::Symbol)
    r = Ref{var"##Ctag#2605"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2605"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2605"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2606"
    data_size::Ptr{hsize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2606"}, f::Symbol)
    f === :data_size && return Ptr{Ptr{hsize_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2606", f::Symbol)
    r = Ref{var"##Ctag#2606"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2606"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2606"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2607"
    type_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2607"}, f::Symbol)
    f === :type_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2607", f::Symbol)
    r = Ref{var"##Ctag#2607"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2607"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2607"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2609"
    gcpl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2609"}, f::Symbol)
    f === :gcpl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2609", f::Symbol)
    r = Ref{var"##Ctag#2609"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2609"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2609"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2612"
    linfo::Ptr{H5L_info2_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2612"}, f::Symbol)
    f === :linfo && return Ptr{Ptr{H5L_info2_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2612", f::Symbol)
    r = Ref{var"##Ctag#2612"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2612"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2612"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2613"
    name_size::Csize_t
    name::Ptr{Cchar}
    name_len::Ptr{Csize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2613"}, f::Symbol)
    f === :name_size && return Ptr{Csize_t}(x + 0)
    f === :name && return Ptr{Ptr{Cchar}}(x + 8)
    f === :name_len && return Ptr{Ptr{Csize_t}}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2613", f::Symbol)
    r = Ref{var"##Ctag#2613"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2613"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2613"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2614"
    buf_size::Csize_t
    buf::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2614"}, f::Symbol)
    f === :buf_size && return Ptr{Csize_t}(x + 0)
    f === :buf && return Ptr{Ptr{Cvoid}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2614", f::Symbol)
    r = Ref{var"##Ctag#2614"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2614"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2614"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2616"
    info::Ptr{H5VL_file_cont_info_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2616"}, f::Symbol)
    f === :info && return Ptr{Ptr{H5VL_file_cont_info_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2616", f::Symbol)
    r = Ref{var"##Ctag#2616"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2616"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2616"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2617"
    fapl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2617"}, f::Symbol)
    f === :fapl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2617", f::Symbol)
    r = Ref{var"##Ctag#2617"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2617"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2617"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2618"
    fcpl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2618"}, f::Symbol)
    f === :fcpl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2618", f::Symbol)
    r = Ref{var"##Ctag#2618"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2618"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2618"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2619"
    fileno::Ptr{Culong}
end
function Base.getproperty(x::Ptr{var"##Ctag#2619"}, f::Symbol)
    f === :fileno && return Ptr{Ptr{Culong}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2619", f::Symbol)
    r = Ref{var"##Ctag#2619"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2619"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2619"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2620"
    flags::Ptr{Cuint}
end
function Base.getproperty(x::Ptr{var"##Ctag#2620"}, f::Symbol)
    f === :flags && return Ptr{Ptr{Cuint}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2620", f::Symbol)
    r = Ref{var"##Ctag#2620"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2620"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2620"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2621"
    types::Cuint
    count::Ptr{Csize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2621"}, f::Symbol)
    f === :types && return Ptr{Cuint}(x + 0)
    f === :count && return Ptr{Ptr{Csize_t}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2621", f::Symbol)
    r = Ref{var"##Ctag#2621"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2621"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2621"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2623"
    type_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2623"}, f::Symbol)
    f === :type_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2623", f::Symbol)
    r = Ref{var"##Ctag#2623"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2623"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2623"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2624"
    type_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2624"}, f::Symbol)
    f === :type_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2624", f::Symbol)
    r = Ref{var"##Ctag#2624"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2624"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2624"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2625"
    idx_type::Ptr{H5D_chunk_index_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2625"}, f::Symbol)
    f === :idx_type && return Ptr{Ptr{H5D_chunk_index_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2625", f::Symbol)
    r = Ref{var"##Ctag#2625"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2625"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2625"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2626"
    offset::Ptr{haddr_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2626"}, f::Symbol)
    f === :offset && return Ptr{Ptr{haddr_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2626", f::Symbol)
    r = Ref{var"##Ctag#2626"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2626"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2626"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2627"
    op::H5D_chunk_iter_op_t
    op_data::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2627"}, f::Symbol)
    f === :op && return Ptr{H5D_chunk_iter_op_t}(x + 0)
    f === :op_data && return Ptr{Ptr{Cvoid}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2627", f::Symbol)
    r = Ref{var"##Ctag#2627"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2627"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2627"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2629"
    size::Ptr{hsize_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2629"}, f::Symbol)
    f === :size && return Ptr{Ptr{hsize_t}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2629", f::Symbol)
    r = Ref{var"##Ctag#2629"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2629"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2629"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2630"
    dset_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2630"}, f::Symbol)
    f === :dset_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2630", f::Symbol)
    r = Ref{var"##Ctag#2630"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2630"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2630"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2631"
    dset_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2631"}, f::Symbol)
    f === :dset_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2631", f::Symbol)
    r = Ref{var"##Ctag#2631"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2631"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2631"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2634"
    obj_type::H5I_type_t
    scope::H5F_scope_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2634"}, f::Symbol)
    f === :obj_type && return Ptr{H5I_type_t}(x + 0)
    f === :scope && return Ptr{H5F_scope_t}(x + 4)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2634", f::Symbol)
    r = Ref{var"##Ctag#2634"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2634"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2634"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2635"
    file::Ptr{Ptr{Cvoid}}
end
function Base.getproperty(x::Ptr{var"##Ctag#2635"}, f::Symbol)
    f === :file && return Ptr{Ptr{Ptr{Cvoid}}}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2635", f::Symbol)
    r = Ref{var"##Ctag#2635"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2635"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2635"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2636"
    filename::Ptr{Cchar}
    fapl_id::hid_t
    accessible::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2636"}, f::Symbol)
    f === :filename && return Ptr{Ptr{Cchar}}(x + 0)
    f === :fapl_id && return Ptr{hid_t}(x + 8)
    f === :accessible && return Ptr{Ptr{hbool_t}}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2636", f::Symbol)
    r = Ref{var"##Ctag#2636"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2636"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2636"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2637"
    filename::Ptr{Cchar}
    fapl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2637"}, f::Symbol)
    f === :filename && return Ptr{Ptr{Cchar}}(x + 0)
    f === :fapl_id && return Ptr{hid_t}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2637", f::Symbol)
    r = Ref{var"##Ctag#2637"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2637"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2637"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2638"
    obj2::Ptr{Cvoid}
    same_file::Ptr{hbool_t}
end
function Base.getproperty(x::Ptr{var"##Ctag#2638"}, f::Symbol)
    f === :obj2 && return Ptr{Ptr{Cvoid}}(x + 0)
    f === :same_file && return Ptr{Ptr{hbool_t}}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2638", f::Symbol)
    r = Ref{var"##Ctag#2638"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2638"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2638"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2639"
    loc_params::H5VL_loc_params_t
    name::Ptr{Cchar}
    lcpl_id::hid_t
    key_type_id::hid_t
    val_type_id::hid_t
    mcpl_id::hid_t
    mapl_id::hid_t
    map::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2639"}, f::Symbol)
    f === :loc_params && return Ptr{H5VL_loc_params_t}(x + 0)
    f === :name && return Ptr{Ptr{Cchar}}(x + 40)
    f === :lcpl_id && return Ptr{hid_t}(x + 48)
    f === :key_type_id && return Ptr{hid_t}(x + 56)
    f === :val_type_id && return Ptr{hid_t}(x + 64)
    f === :mcpl_id && return Ptr{hid_t}(x + 72)
    f === :mapl_id && return Ptr{hid_t}(x + 80)
    f === :map && return Ptr{Ptr{Cvoid}}(x + 88)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2639", f::Symbol)
    r = Ref{var"##Ctag#2639"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2639"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2639"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2640"
    loc_params::H5VL_loc_params_t
    name::Ptr{Cchar}
    mapl_id::hid_t
    map::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2640"}, f::Symbol)
    f === :loc_params && return Ptr{H5VL_loc_params_t}(x + 0)
    f === :name && return Ptr{Ptr{Cchar}}(x + 40)
    f === :mapl_id && return Ptr{hid_t}(x + 48)
    f === :map && return Ptr{Ptr{Cvoid}}(x + 56)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2640", f::Symbol)
    r = Ref{var"##Ctag#2640"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2640"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2640"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2641"
    key_mem_type_id::hid_t
    key::Ptr{Cvoid}
    value_mem_type_id::hid_t
    value::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2641"}, f::Symbol)
    f === :key_mem_type_id && return Ptr{hid_t}(x + 0)
    f === :key && return Ptr{Ptr{Cvoid}}(x + 8)
    f === :value_mem_type_id && return Ptr{hid_t}(x + 16)
    f === :value && return Ptr{Ptr{Cvoid}}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2641", f::Symbol)
    r = Ref{var"##Ctag#2641"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2641"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2641"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2642"
    key_mem_type_id::hid_t
    key::Ptr{Cvoid}
    exists::hbool_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2642"}, f::Symbol)
    f === :key_mem_type_id && return Ptr{hid_t}(x + 0)
    f === :key && return Ptr{Ptr{Cvoid}}(x + 8)
    f === :exists && return Ptr{hbool_t}(x + 16)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2642", f::Symbol)
    r = Ref{var"##Ctag#2642"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2642"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2642"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2643"
    key_mem_type_id::hid_t
    key::Ptr{Cvoid}
    value_mem_type_id::hid_t
    value::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2643"}, f::Symbol)
    f === :key_mem_type_id && return Ptr{hid_t}(x + 0)
    f === :key && return Ptr{Ptr{Cvoid}}(x + 8)
    f === :value_mem_type_id && return Ptr{hid_t}(x + 16)
    f === :value && return Ptr{Ptr{Cvoid}}(x + 24)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2643", f::Symbol)
    r = Ref{var"##Ctag#2643"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2643"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2643"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2645"
    data::NTuple{8, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2645"}, f::Symbol)
    f === :get_mapl && return Ptr{var"##Ctag#2646"}(x + 0)
    f === :get_mcpl && return Ptr{var"##Ctag#2647"}(x + 0)
    f === :get_key_type && return Ptr{var"##Ctag#2648"}(x + 0)
    f === :get_val_type && return Ptr{var"##Ctag#2649"}(x + 0)
    f === :get_count && return Ptr{var"##Ctag#2650"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2645", f::Symbol)
    r = Ref{var"##Ctag#2645"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2645"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2645"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#2644"
    data::NTuple{16, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2644"}, f::Symbol)
    f === :get_type && return Ptr{H5VL_map_get_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2645"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2644", f::Symbol)
    r = Ref{var"##Ctag#2644"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2644"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2644"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#2646"
    mapl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2646"}, f::Symbol)
    f === :mapl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2646", f::Symbol)
    r = Ref{var"##Ctag#2646"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2646"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2646"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2647"
    mcpl_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2647"}, f::Symbol)
    f === :mcpl_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2647", f::Symbol)
    r = Ref{var"##Ctag#2647"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2647"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2647"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2648"
    type_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2648"}, f::Symbol)
    f === :type_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2648", f::Symbol)
    r = Ref{var"##Ctag#2648"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2648"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2648"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2649"
    type_id::hid_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2649"}, f::Symbol)
    f === :type_id && return Ptr{hid_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2649", f::Symbol)
    r = Ref{var"##Ctag#2649"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2649"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2649"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2650"
    count::hsize_t
end
function Base.getproperty(x::Ptr{var"##Ctag#2650"}, f::Symbol)
    f === :count && return Ptr{hsize_t}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2650", f::Symbol)
    r = Ref{var"##Ctag#2650"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2650"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2650"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2652"
    data::NTuple{72, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2652"}, f::Symbol)
    f === :iterate && return Ptr{var"##Ctag#2653"}(x + 0)
    f === :del && return Ptr{var"##Ctag#2654"}(x + 0)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2652", f::Symbol)
    r = Ref{var"##Ctag#2652"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2652"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2652"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#2651"
    data::NTuple{80, UInt8}
end

function Base.getproperty(x::Ptr{var"##Ctag#2651"}, f::Symbol)
    f === :specific_type && return Ptr{H5VL_map_specific_t}(x + 0)
    f === :args && return Ptr{var"##Ctag#2652"}(x + 8)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2651", f::Symbol)
    r = Ref{var"##Ctag#2651"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2651"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2651"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end

struct var"##Ctag#2653"
    loc_params::H5VL_loc_params_t
    idx::hsize_t
    key_mem_type_id::hid_t
    op::H5M_iterate_t
    op_data::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2653"}, f::Symbol)
    f === :loc_params && return Ptr{H5VL_loc_params_t}(x + 0)
    f === :idx && return Ptr{hsize_t}(x + 40)
    f === :key_mem_type_id && return Ptr{hid_t}(x + 48)
    f === :op && return Ptr{H5M_iterate_t}(x + 56)
    f === :op_data && return Ptr{Ptr{Cvoid}}(x + 64)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2653", f::Symbol)
    r = Ref{var"##Ctag#2653"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2653"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2653"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


struct var"##Ctag#2654"
    loc_params::H5VL_loc_params_t
    key_mem_type_id::hid_t
    key::Ptr{Cvoid}
end
function Base.getproperty(x::Ptr{var"##Ctag#2654"}, f::Symbol)
    f === :loc_params && return Ptr{H5VL_loc_params_t}(x + 0)
    f === :key_mem_type_id && return Ptr{hid_t}(x + 40)
    f === :key && return Ptr{Ptr{Cvoid}}(x + 48)
    return getfield(x, f)
end

function Base.getproperty(x::var"##Ctag#2654", f::Symbol)
    r = Ref{var"##Ctag#2654"}(x)
    ptr = Base.unsafe_convert(Ptr{var"##Ctag#2654"}, r)
    fptr = getproperty(ptr, f)
    GC.@preserve r unsafe_load(fptr)
end

function Base.setproperty!(x::Ptr{var"##Ctag#2654"}, f::Symbol, v)
    unsafe_store!(getproperty(x, f), v)
end


const H5_DEFAULT_PLUGINDIR = "/usr/local/hdf5/lib/plugin"

const H5_DEV_T_IS_SCALAR = 1

const H5_EXAMPLESDIR = "/tmp"

const H5_FORTRAN_HAVE_C_LONG_DOUBLE = 1

const H5_FORTRAN_HAVE_C_SIZEOF = 1

const H5_FORTRAN_HAVE_SIZEOF = 1

const H5_FORTRAN_HAVE_STORAGE_SIZE = 1

const H5_FORTRAN_SIZEOF_LONG_DOUBLE = "8"

# Skipping MacroDefinition: H5_H5CONFIG_F_IKIND INTEGER , DIMENSION ( 1 : num_ikinds ) : : ikind = ( / 1 , 2 , 4 , 8 , 16 / )

# Skipping MacroDefinition: H5_H5CONFIG_F_NUM_IKIND INTEGER , PARAMETER : : num_ikinds = 5

# Skipping MacroDefinition: H5_H5CONFIG_F_NUM_RKIND INTEGER , PARAMETER : : num_rkinds = 3

# Skipping MacroDefinition: H5_H5CONFIG_F_RKIND INTEGER , DIMENSION ( 1 : num_rkinds ) : : rkind = ( / 4 , 8 , 16 / )

# Skipping MacroDefinition: H5_H5CONFIG_F_RKIND_SIZEOF INTEGER , DIMENSION ( 1 : num_rkinds ) : : rkind_sizeof = ( / 4 , 8 , 16 / )

const H5_HAVE_ALARM = 1

const H5_HAVE_ASPRINTF = 1

const H5_HAVE_ATTRIBUTE = 1

const H5_HAVE_CLOCK_GETTIME = 1

const H5_HAVE_DARWIN = 1

const H5_HAVE_EMBEDDED_LIBINFO = 1

const H5_HAVE_FCNTL = 1

const H5_HAVE_FILTER_DEFLATE = 1

const H5_HAVE_FILTER_SZIP = 1

const H5_HAVE_FLOCK = 1

const H5_HAVE_FORK = 1

const H5_HAVE_Fortran_INTEGER_SIZEOF_16 = 1

const H5_HAVE_GETHOSTNAME = 1

const H5_HAVE_GETRUSAGE = 1

const H5_HAVE_GETTIMEOFDAY = 1

const H5_HAVE_IOCTL = 1

const H5_HAVE_LIBCRYPTO = 1

const H5_HAVE_LIBCURL = 1

const H5_HAVE_LIBDL = 1

const H5_HAVE_LIBM = 1

const H5_HAVE_LIBSZ = 1

const H5_HAVE_LIBZ = 1

const H5_HAVE_MIRROR_VFD = 1

const H5_HAVE_PARALLEL = 1

const H5_HAVE_PARALLEL_FILTERED_WRITES = 1

const H5_HAVE_PREADWRITE = 1

const H5_HAVE_RANDOM = 1

const H5_HAVE_RAND_R = 1

const H5_HAVE_ROS3_VFD = 1

const H5_HAVE_STAT_ST_BLOCKS = 1

const H5_HAVE_STRCASESTR = 1

const H5_HAVE_STRDUP = 1

const H5_HAVE_SYMLINK = 1

const H5_HAVE_TIMEZONE = 1

const H5_HAVE_TIOCGETD = 1

const H5_HAVE_TIOCGWINSZ = 1

const H5_HAVE_TMPFILE = 1

const H5_HAVE_TM_GMTOFF = 1

const H5_HAVE_VASPRINTF = 1

const H5_HAVE_WAITPID = 1

const H5_IGNORE_DISABLED_FILE_LOCKS = 1

const H5_INCLUDE_HL = 1

const H5_LDOUBLE_TO_LLONG_ACCURATE = 1

const H5_LLONG_TO_LDOUBLE_CORRECT = 1

const H5_LT_OBJDIR = ".libs/"

const H5_PACKAGE = "hdf5"

const H5_PACKAGE_BUGREPORT = "help@hdfgroup.org"

const H5_PACKAGE_NAME = "HDF5"

const H5_PACKAGE_STRING = "HDF5 1.14.3"

const H5_PACKAGE_TARNAME = "hdf5"

const H5_PACKAGE_URL = ""

const H5_PACKAGE_VERSION = "1.14.3"

const H5_PAC_C_MAX_REAL_PRECISION = 17

const H5_PAC_FC_MAX_REAL_PRECISION = 33

const H5_SIZEOF_BOOL = 1

const H5_SIZEOF_CHAR = 1

const H5_SIZEOF_DOUBLE = 8

const H5_SIZEOF_FLOAT = 4

const H5_SIZEOF_INT = 4

const H5_SIZEOF_INT16_T = 2

const H5_SIZEOF_INT32_T = 4

const H5_SIZEOF_INT64_T = 8

const H5_SIZEOF_INT8_T = 1

const H5_SIZEOF_INT_FAST16_T = 2

const H5_SIZEOF_INT_FAST32_T = 4

const H5_SIZEOF_INT_FAST64_T = 8

const H5_SIZEOF_INT_FAST8_T = 1

const H5_SIZEOF_INT_LEAST16_T = 2

const H5_SIZEOF_INT_LEAST32_T = 4

const H5_SIZEOF_INT_LEAST64_T = 8

const H5_SIZEOF_INT_LEAST8_T = 1

const H5_SIZEOF_LONG = 8

const H5_SIZEOF_LONG_DOUBLE = 8

const H5_SIZEOF_LONG_LONG = 8

const H5_SIZEOF_OFF_T = 8

const H5_SIZEOF_PTRDIFF_T = 8

const H5_SIZEOF_SHORT = 2

const H5_SIZEOF_SIZE_T = 8

const H5_SIZEOF_SSIZE_T = 8

const H5_SIZEOF_TIME_T = 8

const H5_SIZEOF_UINT16_T = 2

const H5_SIZEOF_UINT32_T = 4

const H5_SIZEOF_UINT64_T = 8

const H5_SIZEOF_UINT8_T = 1

const H5_SIZEOF_UINT_FAST16_T = 2

const H5_SIZEOF_UINT_FAST32_T = 4

const H5_SIZEOF_UINT_FAST64_T = 8

const H5_SIZEOF_UINT_FAST8_T = 1

const H5_SIZEOF_UINT_LEAST16_T = 2

const H5_SIZEOF_UINT_LEAST32_T = 4

const H5_SIZEOF_UINT_LEAST64_T = 8

const H5_SIZEOF_UINT_LEAST8_T = 1

const H5_SIZEOF_UNSIGNED = 4

const H5_SIZEOF__QUAD = 0

const H5_SIZEOF___FLOAT128 = 0

const H5_STDC_HEADERS = 1

const H5_TEST_EXPRESS_LEVEL_DEFAULT = 3

const H5_USE_114_API_DEFAULT = 1

const H5_USE_FILE_LOCKING = 1

const H5_VERSION = "1.14.3"

const H5_WANT_DATA_ACCURACY = 1

const H5_WANT_DCONV_EXCEPTION = 1

const H5Acreate_vers = 2

const H5Acreate = H5Acreate2

const H5Aiterate_vers = 2

const H5Aiterate = H5Aiterate2

const H5A_operator_t = H5A_operator2_t

const H5Dcreate_vers = 2

const H5Dcreate = H5Dcreate2

const H5Dopen_vers = 2

const H5Dopen = H5Dopen2

const H5Eclear_vers = 2

const H5Eclear = H5Eclear2

const H5Eget_auto_vers = 2

const H5Eget_auto = H5Eget_auto2

const H5Eprint_vers = 2

const H5Eprint = H5Eprint2

const H5Epush_vers = 2

const H5Epush = H5Epush2

const H5Eset_auto_vers = 2

const H5Eset_auto = H5Eset_auto2

const H5Ewalk_vers = 2

const H5Ewalk = H5Ewalk2

const H5E_error_t = H5E_error2_t

const H5E_walk_t = H5E_walk2_t

const H5Fget_info_vers = 2

const H5Fget_info = H5Fget_info2

const H5F_info_t = H5F_info2_t

const H5Gcreate_vers = 2

const H5Gcreate = H5Gcreate2

const H5Gopen_vers = 2

const H5Gopen = H5Gopen2

const H5Lget_info_vers = 2

const H5Lget_info = H5Lget_info2

const H5L_info_t = H5L_info2_t

const H5Lget_info_by_idx_vers = 2

const H5Lget_info_by_idx = H5Lget_info_by_idx2

const H5Literate_vers = 2

const H5Literate = H5Literate2

const H5L_iterate_t = H5L_iterate2_t

const H5Literate_by_name_vers = 2

const H5Literate_by_name = H5Literate_by_name2

const H5Lvisit_vers = 2

const H5Lvisit = H5Lvisit2

const H5Lvisit_by_name_vers = 2

const H5Lvisit_by_name = H5Lvisit_by_name2

const H5Oget_info_vers = 3

const H5Oget_info = H5Oget_info3

const H5Oget_info_by_idx_vers = 3

const H5Oget_info_by_idx = H5Oget_info_by_idx3

const H5Oget_info_by_name_vers = 3

const H5Oget_info_by_name = H5Oget_info_by_name3

const H5Ovisit_vers = 3

const H5Ovisit = H5Ovisit3

const H5Ovisit_by_name_vers = 3

const H5Ovisit_by_name = H5Ovisit_by_name3

const H5Pencode_vers = 2

const H5Pencode = H5Pencode2

const H5Pget_filter_vers = 2

const H5Pget_filter = H5Pget_filter2

const H5Pget_filter_by_id_vers = 2

const H5Pget_filter_by_id = H5Pget_filter_by_id2

const H5Pinsert_vers = 2

const H5Pinsert = H5Pinsert2

const H5Pregister_vers = 2

const H5Pregister = H5Pregister2

const H5Rdereference_vers = 2

const H5Rdereference = H5Rdereference2

const H5Rget_obj_type_vers = 2

const H5Rget_obj_type = H5Rget_obj_type2

const H5Sencode_vers = 2

const H5Sencode = H5Sencode2

const H5Tarray_create_vers = 2

const H5Tarray_create = H5Tarray_create2

const H5Tcommit_vers = 2

const H5Tcommit = H5Tcommit2

const H5Tget_array_dims_vers = 2

const H5Tget_array_dims = H5Tget_array_dims2

const H5Topen_vers = 2

const H5Topen = H5Topen2

const H5E_auto_t_vers = 2

const H5E_auto_t = H5E_auto2_t

const H5O_info_t_vers = 2

const H5O_info_t = H5O_info2_t

const H5O_iterate_t_vers = 2

const H5O_iterate_t = H5O_iterate2_t

const H5Z_class_t_vers = 2

const H5Z_class_t = H5Z_class2_t

const NO_TAGS_WITH_MODIFIERS = 1

const ROMIO_VERSION = 126

const H5_VERS_MAJOR = 1

const H5_VERS_MINOR = 14

const H5_VERS_RELEASE = 3

const H5_VERS_SUBRELEASE = ""

const H5_VERS_INFO = "HDF5 library version: 1.14.3"

const HDF5_DRIVER = "HDF5_DRIVER"

const HDF5_DRIVER_CONFIG = "HDF5_DRIVER_CONFIG"

const HDF5_VOL_CONNECTOR = "HDF5_VOL_CONNECTOR"

const HDF5_PLUGIN_PATH = "HDF5_PLUGIN_PATH"

const HDF5_PLUGIN_PRELOAD = "HDF5_PLUGIN_PRELOAD"

const HDF5_USE_FILE_LOCKING = "HDF5_USE_FILE_LOCKING"

const HDF5_NOCLEANUP = "HDF5_NOCLEANUP"

const H5_SIZEOF_HSIZE_T = 8

const H5_SIZEOF_HSSIZE_T = 8

const HSIZE_UNDEF = UINT64_MAX

const H5_SIZEOF_HADDR_T = 8

const HADDR_UNDEF = UINT64_MAX

const HADDR_MAX = HADDR_UNDEF - 1

const H5_ITER_ERROR = -1

const H5_ITER_CONT = 0

const H5_ITER_STOP = 1

const H5O_MAX_TOKEN_SIZE = 16

# Skipping MacroDefinition: H5_DLLVAR extern

# Skipping MacroDefinition: H5TEST_DLLVAR extern

# Skipping MacroDefinition: H5TOOLS_DLLVAR extern

# Skipping MacroDefinition: H5_DLLCPPVAR extern

# Skipping MacroDefinition: H5_HLDLLVAR extern

# Skipping MacroDefinition: H5_HLCPPDLLVAR extern

# Skipping MacroDefinition: H5_FCDLLVAR extern

# Skipping MacroDefinition: H5_FCTESTDLLVAR extern

# Skipping MacroDefinition: HDF5_HL_F90CSTUBDLLVAR extern

const H5_SIZEOF_HID_T = H5_SIZEOF_INT64_T

const H5I_INVALID_HID = -1

const H5O_COPY_SHALLOW_HIERARCHY_FLAG = Cuint(0x0001)

const H5O_COPY_EXPAND_SOFT_LINK_FLAG = Cuint(0x0002)

const H5O_COPY_EXPAND_EXT_LINK_FLAG = Cuint(0x0004)

const H5O_COPY_EXPAND_REFERENCE_FLAG = Cuint(0x0008)

const H5O_COPY_WITHOUT_ATTR_FLAG = Cuint(0x0010)

const H5O_COPY_PRESERVE_NULL_FLAG = Cuint(0x0020)

const H5O_COPY_MERGE_COMMITTED_DTYPE_FLAG = Cuint(0x0040)

const H5O_COPY_ALL = Cuint(0x007f)

const H5O_SHMESG_NONE_FLAG = 0x0000

const H5O_SHMESG_SDSPACE_FLAG = unsigned(1) << 0x0001

const H5O_SHMESG_DTYPE_FLAG = unsigned(1) << 0x0003

const H5O_SHMESG_FILL_FLAG = unsigned(1) << 0x0005

const H5O_SHMESG_PLINE_FLAG = unsigned(1) << 0x000b

const H5O_SHMESG_ATTR_FLAG = unsigned(1) << 0x000c

const H5O_SHMESG_ALL_FLAG = (((H5O_SHMESG_SDSPACE_FLAG | H5O_SHMESG_DTYPE_FLAG) | H5O_SHMESG_FILL_FLAG) | H5O_SHMESG_PLINE_FLAG) | H5O_SHMESG_ATTR_FLAG

const H5O_HDR_CHUNK0_SIZE = 0x03

const H5O_HDR_ATTR_CRT_ORDER_TRACKED = 0x04

const H5O_HDR_ATTR_CRT_ORDER_INDEXED = 0x08

const H5O_HDR_ATTR_STORE_PHASE_CHANGE = 0x10

const H5O_HDR_STORE_TIMES = 0x20

const H5O_HDR_ALL_FLAGS = (((H5O_HDR_CHUNK0_SIZE | H5O_HDR_ATTR_CRT_ORDER_TRACKED) | H5O_HDR_ATTR_CRT_ORDER_INDEXED) | H5O_HDR_ATTR_STORE_PHASE_CHANGE) | H5O_HDR_STORE_TIMES

const H5O_SHMESG_MAX_NINDEXES = 8

const H5O_SHMESG_MAX_LIST_SIZE = 5000

const H5O_INFO_BASIC = Cuint(0x0001)

const H5O_INFO_TIME = Cuint(0x0002)

const H5O_INFO_NUM_ATTRS = Cuint(0x0004)

const H5O_INFO_ALL = (H5O_INFO_BASIC | H5O_INFO_TIME) | H5O_INFO_NUM_ATTRS

const H5O_NATIVE_INFO_HDR = Cuint(0x0008)

const H5O_NATIVE_INFO_META_SIZE = Cuint(0x0010)

const H5O_NATIVE_INFO_ALL = H5O_NATIVE_INFO_HDR | H5O_NATIVE_INFO_META_SIZE

# Skipping MacroDefinition: H5OPEN H5open ( ) ,

const H5O_TOKEN_UNDEF = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5O_TOKEN_UNDEF_g), hid_t))

const H5O_INFO_HDR = Cuint(0x0008)

const H5O_INFO_META_SIZE = Cuint(0x0010)

const H5T_NCSET = H5T_CSET_RESERVED_2

const H5T_NSTR = H5T_STR_RESERVED_3

const H5T_VARIABLE = SIZE_MAX

const H5T_OPAQUE_TAG_MAX = 256

const H5T_IEEE_F32BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_IEEE_F32BE_g), hid_t))

const H5T_IEEE_F32LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_IEEE_F32LE_g), hid_t))

const H5T_IEEE_F64BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_IEEE_F64BE_g), hid_t))

const H5T_IEEE_F64LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_IEEE_F64LE_g), hid_t))

const H5T_STD_I8BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I8BE_g), hid_t))

const H5T_STD_I8LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I8LE_g), hid_t))

const H5T_STD_I16BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I16BE_g), hid_t))

const H5T_STD_I16LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I16LE_g), hid_t))

const H5T_STD_I32BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I32BE_g), hid_t))

const H5T_STD_I32LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I32LE_g), hid_t))

const H5T_STD_I64BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I64BE_g), hid_t))

const H5T_STD_I64LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_I64LE_g), hid_t))

const H5T_STD_U8BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U8BE_g), hid_t))

const H5T_STD_U8LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U8LE_g), hid_t))

const H5T_STD_U16BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U16BE_g), hid_t))

const H5T_STD_U16LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U16LE_g), hid_t))

const H5T_STD_U32BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U32BE_g), hid_t))

const H5T_STD_U32LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U32LE_g), hid_t))

const H5T_STD_U64BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U64BE_g), hid_t))

const H5T_STD_U64LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_U64LE_g), hid_t))

const H5T_STD_B8BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B8BE_g), hid_t))

const H5T_STD_B8LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B8LE_g), hid_t))

const H5T_STD_B16BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B16BE_g), hid_t))

const H5T_STD_B16LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B16LE_g), hid_t))

const H5T_STD_B32BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B32BE_g), hid_t))

const H5T_STD_B32LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B32LE_g), hid_t))

const H5T_STD_B64BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B64BE_g), hid_t))

const H5T_STD_B64LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_B64LE_g), hid_t))

const H5T_STD_REF_OBJ = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_REF_OBJ_g), hid_t))

const H5T_STD_REF_DSETREG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_REF_DSETREG_g), hid_t))

const H5T_STD_REF = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_STD_REF_g), hid_t))

const H5T_UNIX_D32BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_UNIX_D32BE_g), hid_t))

const H5T_UNIX_D32LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_UNIX_D32LE_g), hid_t))

const H5T_UNIX_D64BE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_UNIX_D64BE_g), hid_t))

const H5T_UNIX_D64LE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_UNIX_D64LE_g), hid_t))

const H5T_C_S1 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_C_S1_g), hid_t))

const H5T_FORTRAN_S1 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_FORTRAN_S1_g), hid_t))

const H5T_INTEL_I8 = H5T_STD_I8LE

const H5T_INTEL_I16 = H5T_STD_I16LE

const H5T_INTEL_I32 = H5T_STD_I32LE

const H5T_INTEL_I64 = H5T_STD_I64LE

const H5T_INTEL_U8 = H5T_STD_U8LE

const H5T_INTEL_U16 = H5T_STD_U16LE

const H5T_INTEL_U32 = H5T_STD_U32LE

const H5T_INTEL_U64 = H5T_STD_U64LE

const H5T_INTEL_B8 = H5T_STD_B8LE

const H5T_INTEL_B16 = H5T_STD_B16LE

const H5T_INTEL_B32 = H5T_STD_B32LE

const H5T_INTEL_B64 = H5T_STD_B64LE

const H5T_INTEL_F32 = H5T_IEEE_F32LE

const H5T_INTEL_F64 = H5T_IEEE_F64LE

const H5T_ALPHA_I8 = H5T_STD_I8LE

const H5T_ALPHA_I16 = H5T_STD_I16LE

const H5T_ALPHA_I32 = H5T_STD_I32LE

const H5T_ALPHA_I64 = H5T_STD_I64LE

const H5T_ALPHA_U8 = H5T_STD_U8LE

const H5T_ALPHA_U16 = H5T_STD_U16LE

const H5T_ALPHA_U32 = H5T_STD_U32LE

const H5T_ALPHA_U64 = H5T_STD_U64LE

const H5T_ALPHA_B8 = H5T_STD_B8LE

const H5T_ALPHA_B16 = H5T_STD_B16LE

const H5T_ALPHA_B32 = H5T_STD_B32LE

const H5T_ALPHA_B64 = H5T_STD_B64LE

const H5T_ALPHA_F32 = H5T_IEEE_F32LE

const H5T_ALPHA_F64 = H5T_IEEE_F64LE

const H5T_MIPS_I8 = H5T_STD_I8BE

const H5T_MIPS_I16 = H5T_STD_I16BE

const H5T_MIPS_I32 = H5T_STD_I32BE

const H5T_MIPS_I64 = H5T_STD_I64BE

const H5T_MIPS_U8 = H5T_STD_U8BE

const H5T_MIPS_U16 = H5T_STD_U16BE

const H5T_MIPS_U32 = H5T_STD_U32BE

const H5T_MIPS_U64 = H5T_STD_U64BE

const H5T_MIPS_B8 = H5T_STD_B8BE

const H5T_MIPS_B16 = H5T_STD_B16BE

const H5T_MIPS_B32 = H5T_STD_B32BE

const H5T_MIPS_B64 = H5T_STD_B64BE

const H5T_MIPS_F32 = H5T_IEEE_F32BE

const H5T_MIPS_F64 = H5T_IEEE_F64BE

const H5T_VAX_F32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_VAX_F32_g), hid_t))

const H5T_VAX_F64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_VAX_F64_g), hid_t))

const H5T_NATIVE_SCHAR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_SCHAR_g), hid_t))

const H5T_NATIVE_UCHAR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UCHAR_g), hid_t))

const H5T_NATIVE_CHAR = H5T_NATIVE_SCHAR

const H5T_NATIVE_SHORT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_SHORT_g), hid_t))

const H5T_NATIVE_USHORT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_USHORT_g), hid_t))

const H5T_NATIVE_INT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_g), hid_t))

const H5T_NATIVE_UINT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_g), hid_t))

const H5T_NATIVE_LONG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_LONG_g), hid_t))

const H5T_NATIVE_ULONG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_ULONG_g), hid_t))

const H5T_NATIVE_LLONG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_LLONG_g), hid_t))

const H5T_NATIVE_ULLONG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_ULLONG_g), hid_t))

const H5T_NATIVE_FLOAT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_FLOAT_g), hid_t))

const H5T_NATIVE_DOUBLE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_DOUBLE_g), hid_t))

const H5T_NATIVE_LDOUBLE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_LDOUBLE_g), hid_t))

const H5T_NATIVE_B8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_B8_g), hid_t))

const H5T_NATIVE_B16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_B16_g), hid_t))

const H5T_NATIVE_B32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_B32_g), hid_t))

const H5T_NATIVE_B64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_B64_g), hid_t))

const H5T_NATIVE_OPAQUE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_OPAQUE_g), hid_t))

const H5T_NATIVE_HADDR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_HADDR_g), hid_t))

const H5T_NATIVE_HSIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_HSIZE_g), hid_t))

const H5T_NATIVE_HSSIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_HSSIZE_g), hid_t))

const H5T_NATIVE_HERR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_HERR_g), hid_t))

const H5T_NATIVE_HBOOL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_HBOOL_g), hid_t))

const H5T_NATIVE_INT8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT8_g), hid_t))

const H5T_NATIVE_UINT8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT8_g), hid_t))

const H5T_NATIVE_INT_LEAST8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_LEAST8_g), hid_t))

const H5T_NATIVE_UINT_LEAST8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_LEAST8_g), hid_t))

const H5T_NATIVE_INT_FAST8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_FAST8_g), hid_t))

const H5T_NATIVE_UINT_FAST8 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_FAST8_g), hid_t))

const H5T_NATIVE_INT16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT16_g), hid_t))

const H5T_NATIVE_UINT16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT16_g), hid_t))

const H5T_NATIVE_INT_LEAST16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_LEAST16_g), hid_t))

const H5T_NATIVE_UINT_LEAST16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_LEAST16_g), hid_t))

const H5T_NATIVE_INT_FAST16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_FAST16_g), hid_t))

const H5T_NATIVE_UINT_FAST16 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_FAST16_g), hid_t))

const H5T_NATIVE_INT32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT32_g), hid_t))

const H5T_NATIVE_UINT32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT32_g), hid_t))

const H5T_NATIVE_INT_LEAST32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_LEAST32_g), hid_t))

const H5T_NATIVE_UINT_LEAST32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_LEAST32_g), hid_t))

const H5T_NATIVE_INT_FAST32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_FAST32_g), hid_t))

const H5T_NATIVE_UINT_FAST32 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_FAST32_g), hid_t))

const H5T_NATIVE_INT64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT64_g), hid_t))

const H5T_NATIVE_UINT64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT64_g), hid_t))

const H5T_NATIVE_INT_LEAST64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_LEAST64_g), hid_t))

const H5T_NATIVE_UINT_LEAST64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_LEAST64_g), hid_t))

const H5T_NATIVE_INT_FAST64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_INT_FAST64_g), hid_t))

const H5T_NATIVE_UINT_FAST64 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5T_NATIVE_UINT_FAST64_g), hid_t))

const H5AC__CURR_CACHE_CONFIG_VERSION = 1

const H5AC__MAX_TRACE_FILE_NAME_LEN = 1024

const H5AC_METADATA_WRITE_STRATEGY__PROCESS_0_ONLY = 0

const H5AC_METADATA_WRITE_STRATEGY__DISTRIBUTED = 1

const H5AC__CURR_CACHE_IMAGE_CONFIG_VERSION = 1

const H5AC__CACHE_IMAGE__ENTRY_AGEOUT__NONE = -1

const H5AC__CACHE_IMAGE__ENTRY_AGEOUT__MAX = 100

const H5D_CHUNK_CACHE_NSLOTS_DEFAULT = SIZE_MAX

const H5D_CHUNK_CACHE_NBYTES_DEFAULT = SIZE_MAX

const H5D_CHUNK_CACHE_W0_DEFAULT = -1.0

const H5D_CHUNK_DONT_FILTER_PARTIAL_CHUNKS = Cuint(0x0002)

const H5D_CHUNK_BTREE = H5D_CHUNK_IDX_BTREE

const H5D_XFER_DIRECT_CHUNK_WRITE_FLAG_NAME = "direct_chunk_flag"

const H5D_XFER_DIRECT_CHUNK_WRITE_FILTERS_NAME = "direct_chunk_filters"

const H5D_XFER_DIRECT_CHUNK_WRITE_OFFSET_NAME = "direct_chunk_offset"

const H5D_XFER_DIRECT_CHUNK_WRITE_DATASIZE_NAME = "direct_chunk_datasize"

const H5D_XFER_DIRECT_CHUNK_READ_FLAG_NAME = "direct_chunk_read_flag"

const H5D_XFER_DIRECT_CHUNK_READ_OFFSET_NAME = "direct_chunk_read_offset"

const H5D_XFER_DIRECT_CHUNK_READ_FILTERS_NAME = "direct_chunk_read_filters"

const H5E_DEFAULT = 0

const H5E_ERR_CLS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ERR_CLS_g), hid_t))

const H5E_DATATYPE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_DATATYPE_g), hid_t))

const H5E_VFL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_VFL_g), hid_t))

const H5E_EARRAY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_EARRAY_g), hid_t))

const H5E_ARGS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ARGS_g), hid_t))

const H5E_LIB = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_LIB_g), hid_t))

const H5E_IO = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_IO_g), hid_t))

const H5E_CACHE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CACHE_g), hid_t))

const H5E_FILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FILE_g), hid_t))

const H5E_HEAP = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_HEAP_g), hid_t))

const H5E_BTREE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BTREE_g), hid_t))

const H5E_RS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_RS_g), hid_t))

const H5E_REFERENCE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_REFERENCE_g), hid_t))

const H5E_RESOURCE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_RESOURCE_g), hid_t))

const H5E_NONE_MAJOR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NONE_MAJOR_g), hid_t))

const H5E_INTERNAL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_INTERNAL_g), hid_t))

const H5E_PLUGIN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_PLUGIN_g), hid_t))

const H5E_CONTEXT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CONTEXT_g), hid_t))

const H5E_FSPACE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FSPACE_g), hid_t))

const H5E_PLIST = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_PLIST_g), hid_t))

const H5E_EFL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_EFL_g), hid_t))

const H5E_FUNC = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FUNC_g), hid_t))

const H5E_SOHM = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SOHM_g), hid_t))

const H5E_ID = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ID_g), hid_t))

const H5E_ATTR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ATTR_g), hid_t))

const H5E_SLIST = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SLIST_g), hid_t))

const H5E_STORAGE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_STORAGE_g), hid_t))

const H5E_SYM = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SYM_g), hid_t))

const H5E_MAP = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_MAP_g), hid_t))

const H5E_ERROR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ERROR_g), hid_t))

const H5E_TST = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_TST_g), hid_t))

const H5E_PLINE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_PLINE_g), hid_t))

const H5E_DATASET = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_DATASET_g), hid_t))

const H5E_EVENTSET = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_EVENTSET_g), hid_t))

const H5E_FARRAY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FARRAY_g), hid_t))

const H5E_OHDR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_OHDR_g), hid_t))

const H5E_PAGEBUF = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_PAGEBUF_g), hid_t))

const H5E_VOL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_VOL_g), hid_t))

const H5E_LINK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_LINK_g), hid_t))

const H5E_DATASPACE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_DATASPACE_g), hid_t))

const H5E_CANTOPENOBJ = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTOPENOBJ_g), hid_t))

const H5E_CANTCLOSEOBJ = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCLOSEOBJ_g), hid_t))

const H5E_COMPLEN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_COMPLEN_g), hid_t))

const H5E_PATH = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_PATH_g), hid_t))

const H5E_CANTCONVERT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCONVERT_g), hid_t))

const H5E_BADSIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADSIZE_g), hid_t))

const H5E_SEEKERROR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SEEKERROR_g), hid_t))

const H5E_READERROR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_READERROR_g), hid_t))

const H5E_WRITEERROR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_WRITEERROR_g), hid_t))

const H5E_CLOSEERROR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CLOSEERROR_g), hid_t))

const H5E_OVERFLOW = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_OVERFLOW_g), hid_t))

const H5E_FCNTL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FCNTL_g), hid_t))

const H5E_FILEEXISTS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FILEEXISTS_g), hid_t))

const H5E_FILEOPEN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_FILEOPEN_g), hid_t))

const H5E_CANTCREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCREATE_g), hid_t))

const H5E_CANTOPENFILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTOPENFILE_g), hid_t))

const H5E_CANTCLOSEFILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCLOSEFILE_g), hid_t))

const H5E_NOTHDF5 = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOTHDF5_g), hid_t))

const H5E_BADFILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADFILE_g), hid_t))

const H5E_TRUNCATED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_TRUNCATED_g), hid_t))

const H5E_MOUNT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_MOUNT_g), hid_t))

const H5E_UNMOUNT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_UNMOUNT_g), hid_t))

const H5E_CANTDELETEFILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTDELETEFILE_g), hid_t))

const H5E_CANTLOCKFILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTLOCKFILE_g), hid_t))

const H5E_CANTUNLOCKFILE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNLOCKFILE_g), hid_t))

const H5E_CANTMERGE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMERGE_g), hid_t))

const H5E_CANTREVIVE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTREVIVE_g), hid_t))

const H5E_CANTSHRINK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSHRINK_g), hid_t))

const H5E_CANTFLUSH = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTFLUSH_g), hid_t))

const H5E_CANTUNSERIALIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNSERIALIZE_g), hid_t))

const H5E_CANTSERIALIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSERIALIZE_g), hid_t))

const H5E_CANTTAG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTTAG_g), hid_t))

const H5E_CANTLOAD = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTLOAD_g), hid_t))

const H5E_PROTECT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_PROTECT_g), hid_t))

const H5E_NOTCACHED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOTCACHED_g), hid_t))

const H5E_SYSTEM = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SYSTEM_g), hid_t))

const H5E_CANTINS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTINS_g), hid_t))

const H5E_CANTPROTECT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTPROTECT_g), hid_t))

const H5E_CANTUNPROTECT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNPROTECT_g), hid_t))

const H5E_CANTPIN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTPIN_g), hid_t))

const H5E_CANTUNPIN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNPIN_g), hid_t))

const H5E_CANTMARKDIRTY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMARKDIRTY_g), hid_t))

const H5E_CANTMARKCLEAN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMARKCLEAN_g), hid_t))

const H5E_CANTMARKUNSERIALIZED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMARKUNSERIALIZED_g), hid_t))

const H5E_CANTMARKSERIALIZED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMARKSERIALIZED_g), hid_t))

const H5E_CANTDIRTY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTDIRTY_g), hid_t))

const H5E_CANTCLEAN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCLEAN_g), hid_t))

const H5E_CANTEXPUNGE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTEXPUNGE_g), hid_t))

const H5E_CANTRESIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTRESIZE_g), hid_t))

const H5E_CANTDEPEND = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTDEPEND_g), hid_t))

const H5E_CANTUNDEPEND = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNDEPEND_g), hid_t))

const H5E_CANTNOTIFY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTNOTIFY_g), hid_t))

const H5E_LOGGING = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_LOGGING_g), hid_t))

const H5E_CANTCORK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCORK_g), hid_t))

const H5E_CANTUNCORK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNCORK_g), hid_t))

const H5E_CANTRESTORE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTRESTORE_g), hid_t))

const H5E_CANTCOMPUTE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCOMPUTE_g), hid_t))

const H5E_CANTEXTEND = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTEXTEND_g), hid_t))

const H5E_CANTATTACH = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTATTACH_g), hid_t))

const H5E_CANTUPDATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUPDATE_g), hid_t))

const H5E_CANTOPERATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTOPERATE_g), hid_t))

const H5E_NOFILTER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOFILTER_g), hid_t))

const H5E_CALLBACK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CALLBACK_g), hid_t))

const H5E_CANAPPLY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANAPPLY_g), hid_t))

const H5E_SETLOCAL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SETLOCAL_g), hid_t))

const H5E_NOENCODER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOENCODER_g), hid_t))

const H5E_CANTFILTER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTFILTER_g), hid_t))

const H5E_CANTPUT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTPUT_g), hid_t))

const H5E_BADID = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADID_g), hid_t))

const H5E_BADGROUP = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADGROUP_g), hid_t))

const H5E_CANTREGISTER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTREGISTER_g), hid_t))

const H5E_CANTINC = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTINC_g), hid_t))

const H5E_CANTDEC = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTDEC_g), hid_t))

const H5E_NOIDS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOIDS_g), hid_t))

const H5E_CANTCLIP = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCLIP_g), hid_t))

const H5E_CANTCOUNT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCOUNT_g), hid_t))

const H5E_CANTSELECT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSELECT_g), hid_t))

const H5E_CANTNEXT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTNEXT_g), hid_t))

const H5E_BADSELECT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADSELECT_g), hid_t))

const H5E_CANTCOMPARE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCOMPARE_g), hid_t))

const H5E_INCONSISTENTSTATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_INCONSISTENTSTATE_g), hid_t))

const H5E_CANTAPPEND = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTAPPEND_g), hid_t))

const H5E_UNINITIALIZED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_UNINITIALIZED_g), hid_t))

const H5E_UNSUPPORTED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_UNSUPPORTED_g), hid_t))

const H5E_BADTYPE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADTYPE_g), hid_t))

const H5E_BADRANGE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADRANGE_g), hid_t))

const H5E_BADVALUE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADVALUE_g), hid_t))

const H5E_NOTFOUND = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOTFOUND_g), hid_t))

const H5E_EXISTS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_EXISTS_g), hid_t))

const H5E_CANTENCODE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTENCODE_g), hid_t))

const H5E_CANTDECODE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTDECODE_g), hid_t))

const H5E_CANTSPLIT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSPLIT_g), hid_t))

const H5E_CANTREDISTRIBUTE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTREDISTRIBUTE_g), hid_t))

const H5E_CANTSWAP = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSWAP_g), hid_t))

const H5E_CANTINSERT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTINSERT_g), hid_t))

const H5E_CANTLIST = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTLIST_g), hid_t))

const H5E_CANTMODIFY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMODIFY_g), hid_t))

const H5E_CANTREMOVE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTREMOVE_g), hid_t))

const H5E_CANTFIND = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTFIND_g), hid_t))

const H5E_TRAVERSE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_TRAVERSE_g), hid_t))

const H5E_NLINKS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NLINKS_g), hid_t))

const H5E_NOTREGISTERED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOTREGISTERED_g), hid_t))

const H5E_CANTMOVE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTMOVE_g), hid_t))

const H5E_CANTSORT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSORT_g), hid_t))

const H5E_CANTWAIT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTWAIT_g), hid_t))

const H5E_CANTCANCEL = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCANCEL_g), hid_t))

const H5E_NOSPACE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NOSPACE_g), hid_t))

const H5E_CANTALLOC = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTALLOC_g), hid_t))

const H5E_CANTCOPY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTCOPY_g), hid_t))

const H5E_CANTFREE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTFREE_g), hid_t))

const H5E_ALREADYEXISTS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ALREADYEXISTS_g), hid_t))

const H5E_CANTLOCK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTLOCK_g), hid_t))

const H5E_CANTUNLOCK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTUNLOCK_g), hid_t))

const H5E_CANTGC = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTGC_g), hid_t))

const H5E_CANTGETSIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTGETSIZE_g), hid_t))

const H5E_OBJOPEN = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_OBJOPEN_g), hid_t))

const H5E_CANTRECV = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTRECV_g), hid_t))

const H5E_CANTGATHER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTGATHER_g), hid_t))

const H5E_NO_INDEPENDENT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NO_INDEPENDENT_g), hid_t))

const H5E_CANTGET = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTGET_g), hid_t))

const H5E_CANTSET = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTSET_g), hid_t))

const H5E_DUPCLASS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_DUPCLASS_g), hid_t))

const H5E_SETDISALLOWED = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SETDISALLOWED_g), hid_t))

const H5E_OPENERROR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_OPENERROR_g), hid_t))

const H5E_NONE_MINOR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_NONE_MINOR_g), hid_t))

const H5E_SYSERRSTR = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_SYSERRSTR_g), hid_t))

const H5E_CANTINIT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTINIT_g), hid_t))

const H5E_ALREADYINIT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ALREADYINIT_g), hid_t))

const H5E_CANTRELEASE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTRELEASE_g), hid_t))

const H5E_LINKCOUNT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_LINKCOUNT_g), hid_t))

const H5E_VERSION = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_VERSION_g), hid_t))

const H5E_ALIGNMENT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_ALIGNMENT_g), hid_t))

const H5E_BADMESG = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADMESG_g), hid_t))

const H5E_CANTDELETE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTDELETE_g), hid_t))

const H5E_BADITER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_BADITER_g), hid_t))

const H5E_CANTPACK = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTPACK_g), hid_t))

const H5E_CANTRESET = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTRESET_g), hid_t))

const H5E_CANTRENAME = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5E_CANTRENAME_g), hid_t))

# Skipping MacroDefinition: H5E_BEGIN_TRY { unsigned H5E_saved_is_v2 ; union { H5E_auto1_t efunc1 ; H5E_auto2_t efunc2 ; } H5E_saved ; void * H5E_saved_edata ; ( void ) H5Eauto_is_v2 ( H5E_DEFAULT , & H5E_saved_is_v2 ) ; if ( H5E_saved_is_v2 ) { ( void ) H5Eget_auto2 ( H5E_DEFAULT , & H5E_saved . efunc2 , & H5E_saved_edata ) ; ( void ) H5Eset_auto2 ( H5E_DEFAULT , NULL , NULL ) ; } else { ( void ) H5Eget_auto1 ( & H5E_saved . efunc1 , & H5E_saved_edata ) ; ( void ) H5Eset_auto1 ( NULL , NULL ) ; }

# Skipping MacroDefinition: H5E_END_TRY if ( H5E_saved_is_v2 ) ( void ) H5Eset_auto2 ( H5E_DEFAULT , H5E_saved . efunc2 , H5E_saved_edata ) ; else ( void ) H5Eset_auto1 ( H5E_saved . efunc1 , H5E_saved_edata ) ; }

const H5ES_NONE = 0

const H5ES_WAIT_FOREVER = UINT64_MAX

const H5ES_WAIT_NONE = 0

# Skipping MacroDefinition: H5CHECK H5check ( ) ,

const H5F_ACC_RDONLY = Cuint(0x0000)

const H5F_ACC_RDWR = Cuint(0x0001)

const H5F_ACC_TRUNC = Cuint(0x0002)

const H5F_ACC_EXCL = Cuint(0x0004)

const H5F_ACC_CREAT = Cuint(0x0010)

const H5F_ACC_SWMR_WRITE = Cuint(0x0020)

const H5F_ACC_SWMR_READ = Cuint(0x0040)

const H5F_ACC_DEFAULT = Cuint(0xffff)

const H5F_OBJ_FILE = Cuint(0x0001)

const H5F_OBJ_DATASET = Cuint(0x0002)

const H5F_OBJ_GROUP = Cuint(0x0004)

const H5F_OBJ_DATATYPE = Cuint(0x0008)

const H5F_OBJ_ATTR = Cuint(0x0010)

const H5F_OBJ_ALL = (((H5F_OBJ_FILE | H5F_OBJ_DATASET) | H5F_OBJ_GROUP) | H5F_OBJ_DATATYPE) | H5F_OBJ_ATTR

const H5F_OBJ_LOCAL = Cuint(0x0020)

const H5F_FAMILY_DEFAULT = 0

const H5F_UNLIMITED = HSIZE_UNDEF

const H5F_LIBVER_LATEST = H5F_LIBVER_V114

const H5F_NUM_METADATA_READ_RETRY_TYPES = 21

const H5F_ACC_DEBUG = Cuint(0x0000)

const H5FD_VFD_DEFAULT = 0

const H5_VFD_INVALID = H5FD_class_value_t(-1)

const H5_VFD_SEC2 = H5FD_class_value_t(0)

const H5_VFD_CORE = H5FD_class_value_t(1)

const H5_VFD_LOG = H5FD_class_value_t(2)

const H5_VFD_FAMILY = H5FD_class_value_t(3)

const H5_VFD_MULTI = H5FD_class_value_t(4)

const H5_VFD_STDIO = H5FD_class_value_t(5)

const H5_VFD_SPLITTER = H5FD_class_value_t(6)

const H5_VFD_DIRECT = H5FD_class_value_t(8)

const H5_VFD_MIRROR = H5FD_class_value_t(9)

const H5_VFD_HDFS = H5FD_class_value_t(10)

const H5_VFD_ROS3 = H5FD_class_value_t(11)

const H5_VFD_SUBFILING = H5FD_class_value_t(12)

const H5_VFD_IOC = H5FD_class_value_t(13)

const H5_VFD_ONION = H5FD_class_value_t(14)

const H5_VFD_RESERVED = 256

const H5_VFD_MAX = 65535

const H5FD_FEAT_AGGREGATE_METADATA = 0x00000001

const H5FD_FEAT_ACCUMULATE_METADATA_WRITE = 0x00000002

const H5FD_FEAT_ACCUMULATE_METADATA_READ = 0x00000004

const H5FD_FEAT_ACCUMULATE_METADATA = H5FD_FEAT_ACCUMULATE_METADATA_WRITE | H5FD_FEAT_ACCUMULATE_METADATA_READ

const H5FD_FEAT_DATA_SIEVE = 0x00000008

const H5FD_FEAT_AGGREGATE_SMALLDATA = 0x00000010

const H5FD_FEAT_IGNORE_DRVRINFO = 0x00000020

const H5FD_FEAT_DIRTY_DRVRINFO_LOAD = 0x00000040

const H5FD_FEAT_POSIX_COMPAT_HANDLE = 0x00000080

const H5FD_FEAT_ALLOCATE_EARLY = 0x00000200

const H5FD_FEAT_ALLOW_FILE_IMAGE = 0x00000400

const H5FD_FEAT_CAN_USE_FILE_IMAGE_CALLBACKS = 0x00000800

const H5FD_FEAT_SUPPORTS_SWMR_IO = 0x00001000

const H5FD_FEAT_USE_ALLOC_SIZE = 0x00002000

const H5FD_FEAT_PAGED_AGGR = 0x00004000

const H5FD_FEAT_DEFAULT_VFD_COMPATIBLE = 0x00008000

const H5FD_FEAT_MEMMANAGE = 0x00010000

const H5FD_CTL_OPC_RESERVED = 512

const H5FD_CTL_OPC_EXPER_MIN = H5FD_CTL_OPC_RESERVED

const H5FD_CTL_OPC_EXPER_MAX = H5FD_CTL_OPC_RESERVED + 511

const H5FD_CTL_INVALID_OPCODE = 0

const H5FD_CTL_TEST_OPCODE = 1

const H5FD_CTL_MEM_ALLOC = 5

const H5FD_CTL_MEM_FREE = 6

const H5FD_CTL_MEM_COPY = 7

const H5FD_CTL_FAIL_IF_UNKNOWN_FLAG = 0x0001

const H5FD_CTL_ROUTE_TO_TERMINAL_VFD_FLAG = 0x0002

const H5L_MAX_LINK_NAME_LEN = UINT32_MAX

const H5L_SAME_LOC = 0

const H5L_TYPE_BUILTIN_MAX = H5L_TYPE_SOFT

const H5L_TYPE_UD_MIN = H5L_TYPE_EXTERNAL

const H5L_TYPE_UD_MAX = H5L_TYPE_MAX

const H5G_SAME_LOC = H5L_SAME_LOC

const H5G_LINK_ERROR = H5L_TYPE_ERROR

const H5G_LINK_HARD = H5L_TYPE_HARD

const H5G_LINK_SOFT = H5L_TYPE_SOFT

const H5G_link_t = H5L_type_t

const H5G_NTYPES = 256

const H5G_NLIBTYPES = 8

const H5G_NUSERTYPES = H5G_NTYPES - H5G_NLIBTYPES

const H5VL_VERSION = 3

const H5_VOL_INVALID = -1

const H5_VOL_NATIVE = 0

const H5_VOL_RESERVED = 256

const H5_VOL_MAX = 65535

const H5VL_CAP_FLAG_NONE = 0x0000000000000000

const H5VL_CAP_FLAG_THREADSAFE = 0x0000000000000001

const H5VL_CAP_FLAG_ASYNC = 0x0000000000000002

const H5VL_CAP_FLAG_NATIVE_FILES = 0x0000000000000004

const H5VL_CAP_FLAG_ATTR_BASIC = 0x0000000000000008

const H5VL_CAP_FLAG_ATTR_MORE = 0x0000000000000010

const H5VL_CAP_FLAG_DATASET_BASIC = 0x0000000000000020

const H5VL_CAP_FLAG_DATASET_MORE = 0x0000000000000040

const H5VL_CAP_FLAG_FILE_BASIC = 0x0000000000000080

const H5VL_CAP_FLAG_FILE_MORE = 0x0000000000000100

const H5VL_CAP_FLAG_GROUP_BASIC = 0x0000000000000200

const H5VL_CAP_FLAG_GROUP_MORE = 0x0000000000000400

const H5VL_CAP_FLAG_LINK_BASIC = 0x0000000000000800

const H5VL_CAP_FLAG_LINK_MORE = 0x0000000000001000

const H5VL_CAP_FLAG_MAP_BASIC = 0x0000000000002000

const H5VL_CAP_FLAG_MAP_MORE = 0x0000000000004000

const H5VL_CAP_FLAG_OBJECT_BASIC = 0x0000000000008000

const H5VL_CAP_FLAG_OBJECT_MORE = 0x0000000000010000

const H5VL_CAP_FLAG_REF_BASIC = 0x0000000000020000

const H5VL_CAP_FLAG_REF_MORE = 0x0000000000040000

const H5VL_CAP_FLAG_OBJ_REF = 0x0000000000080000

const H5VL_CAP_FLAG_REG_REF = 0x0000000000100000

const H5VL_CAP_FLAG_ATTR_REF = 0x0000000000200000

const H5VL_CAP_FLAG_STORED_DATATYPES = 0x0000000000400000

const H5VL_CAP_FLAG_CREATION_ORDER = 0x0000000000800000

const H5VL_CAP_FLAG_ITERATE = 0x0000000001000000

const H5VL_CAP_FLAG_STORAGE_SIZE = 0x0000000002000000

const H5VL_CAP_FLAG_BY_IDX = 0x0000000004000000

const H5VL_CAP_FLAG_GET_PLIST = 0x0000000008000000

const H5VL_CAP_FLAG_FLUSH_REFRESH = 0x0000000010000000

const H5VL_CAP_FLAG_EXTERNAL_LINKS = 0x0000000020000000

const H5VL_CAP_FLAG_HARD_LINKS = 0x0000000040000000

const H5VL_CAP_FLAG_SOFT_LINKS = 0x0000000080000000

const H5VL_CAP_FLAG_UD_LINKS = 0x0000000100000000

const H5VL_CAP_FLAG_TRACK_TIMES = 0x0000000200000000

const H5VL_CAP_FLAG_MOUNT = 0x0000000400000000

const H5VL_CAP_FLAG_FILTERS = 0x0000000800000000

const H5VL_CAP_FLAG_FILL_VALUES = 0x0000001000000000

const H5VL_OPT_QUERY_SUPPORTED = 0x0001

const H5VL_OPT_QUERY_READ_DATA = 0x0002

const H5VL_OPT_QUERY_WRITE_DATA = 0x0004

const H5VL_OPT_QUERY_QUERY_METADATA = 0x0008

const H5VL_OPT_QUERY_MODIFY_METADATA = 0x0010

const H5VL_OPT_QUERY_COLLECTIVE = 0x0020

const H5VL_OPT_QUERY_NO_ASYNC = 0x0040

const H5VL_OPT_QUERY_MULTI_OBJ = 0x0080

# Skipping MacroDefinition: H5R_OBJ_REF_BUF_SIZE sizeof ( haddr_t )

# Skipping MacroDefinition: H5R_DSET_REG_REF_BUF_SIZE ( sizeof ( haddr_t ) + 4 )

const H5R_REF_BUF_SIZE = 64

const H5R_OBJECT = H5R_OBJECT1

const H5R_DATASET_REGION = H5R_DATASET_REGION1

const H5VL_CONTAINER_INFO_VERSION = 0x01

const H5VL_MAX_BLOB_ID_SIZE = 16

const H5VL_RESERVED_NATIVE_OPTIONAL = 1024

const H5VL_MAP_CREATE = 1

const H5VL_MAP_OPEN = 2

const H5VL_MAP_GET_VAL = 3

const H5VL_MAP_EXISTS = 4

const H5VL_MAP_PUT = 5

const H5VL_MAP_GET = 6

const H5VL_MAP_SPECIFIC = 7

const H5VL_MAP_OPTIONAL = 8

const H5VL_MAP_CLOSE = 9

const H5S_ALL = 0

const H5S_BLOCK = 1

const H5S_PLIST = 2

const H5S_UNLIMITED = HSIZE_UNDEF

const H5S_MAX_RANK = 32

const H5S_SEL_ITER_GET_SEQ_LIST_SORTED = 0x0001

const H5S_SEL_ITER_SHARE_WITH_DATASPACE = 0x0002

const H5Z_FILTER_ERROR = -1

const H5Z_FILTER_NONE = 0

const H5Z_FILTER_DEFLATE = 1

const H5Z_FILTER_SHUFFLE = 2

const H5Z_FILTER_FLETCHER32 = 3

const H5Z_FILTER_SZIP = 4

const H5Z_FILTER_NBIT = 5

const H5Z_FILTER_SCALEOFFSET = 6

const H5Z_FILTER_RESERVED = 256

const H5Z_FILTER_MAX = 65535

const H5Z_FILTER_ALL = 0

const H5Z_MAX_NFILTERS = 32

const H5Z_FLAG_DEFMASK = 0x00ff

const H5Z_FLAG_MANDATORY = 0x0000

const H5Z_FLAG_OPTIONAL = 0x0001

const H5Z_FLAG_INVMASK = 0xff00

const H5Z_FLAG_REVERSE = 0x0100

const H5Z_FLAG_SKIP_EDC = 0x0200

const H5_SZIP_ALLOW_K13_OPTION_MASK = 1

const H5_SZIP_CHIP_OPTION_MASK = 2

const H5_SZIP_EC_OPTION_MASK = 4

const H5_SZIP_NN_OPTION_MASK = 32

const H5_SZIP_MAX_PIXELS_PER_BLOCK = 32

const H5Z_SHUFFLE_USER_NPARMS = 0

const H5Z_SHUFFLE_TOTAL_NPARMS = 1

const H5Z_SZIP_USER_NPARMS = 2

const H5Z_SZIP_TOTAL_NPARMS = 4

const H5Z_SZIP_PARM_MASK = 0

const H5Z_SZIP_PARM_PPB = 1

const H5Z_SZIP_PARM_BPP = 2

const H5Z_SZIP_PARM_PPS = 3

const H5Z_NBIT_USER_NPARMS = 0

const H5Z_SCALEOFFSET_USER_NPARMS = 2

const H5Z_SO_INT_MINBITS_DEFAULT = 0

const H5Z_FILTER_CONFIG_ENCODE_ENABLED = 0x0001

const H5Z_FILTER_CONFIG_DECODE_ENABLED = 0x0002

const H5P_ROOT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_ROOT_ID_g), hid_t))

const H5P_OBJECT_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_OBJECT_CREATE_ID_g), hid_t))

const H5P_FILE_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_FILE_CREATE_ID_g), hid_t))

const H5P_FILE_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_FILE_ACCESS_ID_g), hid_t))

const H5P_DATASET_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_DATASET_CREATE_ID_g), hid_t))

const H5P_DATASET_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_DATASET_ACCESS_ID_g), hid_t))

const H5P_DATASET_XFER = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_DATASET_XFER_ID_g), hid_t))

const H5P_FILE_MOUNT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_FILE_MOUNT_ID_g), hid_t))

const H5P_GROUP_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_GROUP_CREATE_ID_g), hid_t))

const H5P_GROUP_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_GROUP_ACCESS_ID_g), hid_t))

const H5P_DATATYPE_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_DATATYPE_CREATE_ID_g), hid_t))

const H5P_DATATYPE_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_DATATYPE_ACCESS_ID_g), hid_t))

const H5P_MAP_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_MAP_CREATE_ID_g), hid_t))

const H5P_MAP_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_MAP_ACCESS_ID_g), hid_t))

const H5P_STRING_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_STRING_CREATE_ID_g), hid_t))

const H5P_ATTRIBUTE_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_ATTRIBUTE_CREATE_ID_g), hid_t))

const H5P_ATTRIBUTE_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_ATTRIBUTE_ACCESS_ID_g), hid_t))

const H5P_OBJECT_COPY = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_OBJECT_COPY_ID_g), hid_t))

const H5P_LINK_CREATE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_LINK_CREATE_ID_g), hid_t))

const H5P_LINK_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_LINK_ACCESS_ID_g), hid_t))

const H5P_VOL_INITIALIZE = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_VOL_INITIALIZE_ID_g), hid_t))

const H5P_REFERENCE_ACCESS = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_CLS_REFERENCE_ACCESS_ID_g), hid_t))

const H5P_FILE_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_FILE_CREATE_ID_g), hid_t))

const H5P_FILE_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_FILE_ACCESS_ID_g), hid_t))

const H5P_DATASET_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_DATASET_CREATE_ID_g), hid_t))

const H5P_DATASET_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_DATASET_ACCESS_ID_g), hid_t))

const H5P_DATASET_XFER_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_DATASET_XFER_ID_g), hid_t))

const H5P_FILE_MOUNT_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_FILE_MOUNT_ID_g), hid_t))

const H5P_GROUP_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_GROUP_CREATE_ID_g), hid_t))

const H5P_GROUP_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_GROUP_ACCESS_ID_g), hid_t))

const H5P_DATATYPE_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_DATATYPE_CREATE_ID_g), hid_t))

const H5P_DATATYPE_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_DATATYPE_ACCESS_ID_g), hid_t))

const H5P_MAP_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_MAP_CREATE_ID_g), hid_t))

const H5P_MAP_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_MAP_ACCESS_ID_g), hid_t))

const H5P_ATTRIBUTE_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_ATTRIBUTE_CREATE_ID_g), hid_t))

const H5P_ATTRIBUTE_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_ATTRIBUTE_ACCESS_ID_g), hid_t))

const H5P_OBJECT_COPY_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_OBJECT_COPY_ID_g), hid_t))

const H5P_LINK_CREATE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_LINK_CREATE_ID_g), hid_t))

const H5P_LINK_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_LINK_ACCESS_ID_g), hid_t))

const H5P_VOL_INITIALIZE_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_VOL_INITIALIZE_ID_g), hid_t))

const H5P_REFERENCE_ACCESS_DEFAULT = unsafe_load(cglobal(dlsym(HDF5_jll.libhdf5_handle, :H5P_LST_REFERENCE_ACCESS_ID_g), hid_t))

const H5P_CRT_ORDER_TRACKED = 0x0001

const H5P_CRT_ORDER_INDEXED = 0x0002

const H5P_DEFAULT = 0

const H5D_SEL_IO_DISABLE_BY_API = Cuint(0x0001)

const H5D_SEL_IO_NOT_CONTIGUOUS_OR_CHUNKED_DATASET = Cuint(0x0002)

const H5D_SEL_IO_CONTIGUOUS_SIEVE_BUFFER = Cuint(0x0004)

const H5D_SEL_IO_NO_VECTOR_OR_SELECTION_IO_CB = Cuint(0x0008)

const H5D_SEL_IO_PAGE_BUFFER = Cuint(0x0010)

const H5D_SEL_IO_DATASET_FILTER = Cuint(0x0020)

const H5D_SEL_IO_CHUNK_CACHE = Cuint(0x0040)

const H5D_SEL_IO_TCONV_BUF_TOO_SMALL = Cuint(0x0080)

const H5D_SEL_IO_BKG_BUF_TOO_SMALL = Cuint(0x0100)

const H5D_SEL_IO_DEFAULT_OFF = Cuint(0x0200)

const H5D_SCALAR_IO = Cuint(0x0001)

const H5D_VECTOR_IO = Cuint(0x0002)

const H5D_SELECTION_IO = Cuint(0x0004)

const H5P_NO_CLASS = H5P_ROOT

const H5PL_NO_PLUGIN = "::"

const H5PL_FILTER_PLUGIN = 0x0001

const H5PL_VOL_PLUGIN = 0x0002

const H5PL_VFD_PLUGIN = 0x0004

const H5PL_ALL_PLUGIN = 0xffff

const H5FD_CLASS_VERSION = 0x01

const H5FD_MEM_FHEAP_HDR = H5FD_MEM_OHDR

const H5FD_MEM_FHEAP_IBLOCK = H5FD_MEM_OHDR

const H5FD_MEM_FHEAP_DBLOCK = H5FD_MEM_LHEAP

const H5FD_MEM_FHEAP_HUGE_OBJ = H5FD_MEM_DRAW

const H5FD_MEM_FSPACE_HDR = H5FD_MEM_OHDR

const H5FD_MEM_FSPACE_SINFO = H5FD_MEM_LHEAP

const H5FD_MEM_SOHM_TABLE = H5FD_MEM_OHDR

const H5FD_MEM_SOHM_INDEX = H5FD_MEM_BTREE

const H5FD_MEM_EARRAY_HDR = H5FD_MEM_OHDR

const H5FD_MEM_EARRAY_IBLOCK = H5FD_MEM_OHDR

const H5FD_MEM_EARRAY_SBLOCK = H5FD_MEM_BTREE

const H5FD_MEM_EARRAY_DBLOCK = H5FD_MEM_LHEAP

const H5FD_MEM_EARRAY_DBLK_PAGE = H5FD_MEM_LHEAP

const H5FD_MEM_FARRAY_HDR = H5FD_MEM_OHDR

const H5FD_MEM_FARRAY_DBLOCK = H5FD_MEM_LHEAP

const H5FD_MEM_FARRAY_DBLK_PAGE = H5FD_MEM_LHEAP

# Skipping MacroDefinition: H5FD_FLMAP_SINGLE { H5FD_MEM_SUPER , /*default*/ H5FD_MEM_SUPER , /*super*/ H5FD_MEM_SUPER , /*btree*/ H5FD_MEM_SUPER , /*draw*/ H5FD_MEM_SUPER , /*gheap*/ H5FD_MEM_SUPER , /*lheap*/ H5FD_MEM_SUPER /*ohdr*/ }

# Skipping MacroDefinition: H5FD_FLMAP_DICHOTOMY { H5FD_MEM_SUPER , /*default*/ H5FD_MEM_SUPER , /*super*/ H5FD_MEM_SUPER , /*btree*/ H5FD_MEM_DRAW , /*draw*/ H5FD_MEM_DRAW , /*gheap*/ H5FD_MEM_SUPER , /*lheap*/ H5FD_MEM_SUPER /*ohdr*/ }

# Skipping MacroDefinition: H5FD_FLMAP_DEFAULT { H5FD_MEM_DEFAULT , /*default*/ H5FD_MEM_DEFAULT , /*super*/ H5FD_MEM_DEFAULT , /*btree*/ H5FD_MEM_DEFAULT , /*draw*/ H5FD_MEM_DEFAULT , /*gheap*/ H5FD_MEM_DEFAULT , /*lheap*/ H5FD_MEM_DEFAULT /*ohdr*/ }

const H5L_LINK_CLASS_T_VERS = 1

const H5L_EXT_VERSION = 0

const H5L_EXT_FLAGS_ALL = 0

const H5L_LINK_CLASS_T_VERS_0 = 0

const H5Z_CLASS_T_VERS = 1

const H5VL_NATIVE = H5VL_native_register()

const H5VL_NATIVE_NAME = "native"

const H5VL_NATIVE_VALUE = H5_VOL_NATIVE

const H5VL_NATIVE_VERSION = 0

const H5VL_NATIVE_ATTR_ITERATE_OLD = 0

const H5VL_NATIVE_DATASET_FORMAT_CONVERT = 0

const H5VL_NATIVE_DATASET_GET_CHUNK_INDEX_TYPE = 1

const H5VL_NATIVE_DATASET_GET_CHUNK_STORAGE_SIZE = 2

const H5VL_NATIVE_DATASET_GET_NUM_CHUNKS = 3

const H5VL_NATIVE_DATASET_GET_CHUNK_INFO_BY_IDX = 4

const H5VL_NATIVE_DATASET_GET_CHUNK_INFO_BY_COORD = 5

const H5VL_NATIVE_DATASET_CHUNK_READ = 6

const H5VL_NATIVE_DATASET_CHUNK_WRITE = 7

const H5VL_NATIVE_DATASET_GET_VLEN_BUF_SIZE = 8

const H5VL_NATIVE_DATASET_GET_OFFSET = 9

const H5VL_NATIVE_DATASET_CHUNK_ITER = 10

const H5VL_NATIVE_FILE_CLEAR_ELINK_CACHE = 0

const H5VL_NATIVE_FILE_GET_FILE_IMAGE = 1

const H5VL_NATIVE_FILE_GET_FREE_SECTIONS = 2

const H5VL_NATIVE_FILE_GET_FREE_SPACE = 3

const H5VL_NATIVE_FILE_GET_INFO = 4

const H5VL_NATIVE_FILE_GET_MDC_CONF = 5

const H5VL_NATIVE_FILE_GET_MDC_HR = 6

const H5VL_NATIVE_FILE_GET_MDC_SIZE = 7

const H5VL_NATIVE_FILE_GET_SIZE = 8

const H5VL_NATIVE_FILE_GET_VFD_HANDLE = 9

const H5VL_NATIVE_FILE_RESET_MDC_HIT_RATE = 10

const H5VL_NATIVE_FILE_SET_MDC_CONFIG = 11

const H5VL_NATIVE_FILE_GET_METADATA_READ_RETRY_INFO = 12

const H5VL_NATIVE_FILE_START_SWMR_WRITE = 13

const H5VL_NATIVE_FILE_START_MDC_LOGGING = 14

const H5VL_NATIVE_FILE_STOP_MDC_LOGGING = 15

const H5VL_NATIVE_FILE_GET_MDC_LOGGING_STATUS = 16

const H5VL_NATIVE_FILE_FORMAT_CONVERT = 17

const H5VL_NATIVE_FILE_RESET_PAGE_BUFFERING_STATS = 18

const H5VL_NATIVE_FILE_GET_PAGE_BUFFERING_STATS = 19

const H5VL_NATIVE_FILE_GET_MDC_IMAGE_INFO = 20

const H5VL_NATIVE_FILE_GET_EOA = 21

const H5VL_NATIVE_FILE_INCR_FILESIZE = 22

const H5VL_NATIVE_FILE_SET_LIBVER_BOUNDS = 23

const H5VL_NATIVE_FILE_GET_MIN_DSET_OHDR_FLAG = 24

const H5VL_NATIVE_FILE_SET_MIN_DSET_OHDR_FLAG = 25

const H5VL_NATIVE_FILE_POST_OPEN = 28

const H5VL_NATIVE_GROUP_ITERATE_OLD = 0

const H5VL_NATIVE_GROUP_GET_OBJINFO = 1

const H5VL_NATIVE_OBJECT_GET_COMMENT = 0

const H5VL_NATIVE_OBJECT_SET_COMMENT = 1

const H5VL_NATIVE_OBJECT_DISABLE_MDC_FLUSHES = 2

const H5VL_NATIVE_OBJECT_ENABLE_MDC_FLUSHES = 3

const H5VL_NATIVE_OBJECT_ARE_MDC_FLUSHES_DISABLED = 4

const H5VL_NATIVE_OBJECT_GET_NATIVE_INFO = 5

const H5FD_CORE = H5FDperform_init(H5FD_core_init)

const H5FD_CORE_VALUE = H5_VFD_CORE

const H5FD_DIRECT = H5I_INVALID_HID

const H5FD_DIRECT_VALUE = H5_VFD_INVALID

const H5FD_FAMILY = H5FDperform_init(H5FD_family_init)

const H5FD_FAMILY_VALUE = H5_VFD_FAMILY

const H5FD_HDFS = H5I_INVALID_HID

const H5FD_HDFS_VALUE = H5_VFD_INVALID

const H5FD_LOG = H5FDperform_init(H5FD_log_init)

const H5FD_LOG_VALUE = H5_VFD_LOG

const H5FD_LOG_TRUNCATE = 0x00000001

const H5FD_LOG_META_IO = H5FD_LOG_TRUNCATE

const H5FD_LOG_LOC_READ = 0x00000002

const H5FD_LOG_LOC_WRITE = 0x00000004

const H5FD_LOG_LOC_SEEK = 0x00000008

const H5FD_LOG_LOC_IO = (H5FD_LOG_LOC_READ | H5FD_LOG_LOC_WRITE) | H5FD_LOG_LOC_SEEK

const H5FD_LOG_FILE_READ = 0x00000010

const H5FD_LOG_FILE_WRITE = 0x00000020

const H5FD_LOG_FILE_IO = H5FD_LOG_FILE_READ | H5FD_LOG_FILE_WRITE

const H5FD_LOG_FLAVOR = 0x00000040

const H5FD_LOG_NUM_READ = 0x00000080

const H5FD_LOG_NUM_WRITE = 0x00000100

const H5FD_LOG_NUM_SEEK = 0x00000200

const H5FD_LOG_NUM_TRUNCATE = 0x00000400

const H5FD_LOG_NUM_IO = ((H5FD_LOG_NUM_READ | H5FD_LOG_NUM_WRITE) | H5FD_LOG_NUM_SEEK) | H5FD_LOG_NUM_TRUNCATE

const H5FD_LOG_TIME_OPEN = 0x00000800

const H5FD_LOG_TIME_STAT = 0x00001000

const H5FD_LOG_TIME_READ = 0x00002000

const H5FD_LOG_TIME_WRITE = 0x00004000

const H5FD_LOG_TIME_SEEK = 0x00008000

const H5FD_LOG_TIME_TRUNCATE = 0x00010000

const H5FD_LOG_TIME_CLOSE = 0x00020000

const H5FD_LOG_TIME_IO = (((((H5FD_LOG_TIME_OPEN | H5FD_LOG_TIME_STAT) | H5FD_LOG_TIME_READ) | H5FD_LOG_TIME_WRITE) | H5FD_LOG_TIME_SEEK) | H5FD_LOG_TIME_TRUNCATE) | H5FD_LOG_TIME_CLOSE

const H5FD_LOG_ALLOC = 0x00040000

const H5FD_LOG_FREE = 0x00080000

const H5FD_LOG_ALL = ((((((H5FD_LOG_FREE | H5FD_LOG_ALLOC) | H5FD_LOG_TIME_IO) | H5FD_LOG_NUM_IO) | H5FD_LOG_FLAVOR) | H5FD_LOG_FILE_IO) | H5FD_LOG_LOC_IO) | H5FD_LOG_META_IO

const H5FD_MIRROR = H5FDperform_init(H5FD_mirror_init)

const H5FD_MIRROR_VALUE = H5_VFD_MIRROR

const H5FD_MIRROR_FAPL_MAGIC = 0xf8dd514c

const H5FD_MIRROR_CURR_FAPL_T_VERSION = 1

const H5FD_MIRROR_MAX_IP_LEN = 32

const H5D_ONE_LINK_CHUNK_IO_THRESHOLD = 0

const H5D_MULTI_CHUNK_IO_COL_THRESHOLD = 60

const H5FD_MULTI = H5FDperform_init(H5FD_multi_init)

const H5FD_ONION = H5FDperform_init(H5FD_onion_init)

const H5FD_ONION_VALUE = H5_VFD_ONION

const H5FD_ONION_FAPL_INFO_VERSION_CURR = 1

const H5FD_ONION_FAPL_INFO_CREATE_FLAG_ENABLE_PAGE_ALIGNMENT = Cuint(0x0001)

const H5FD_ONION_FAPL_INFO_COMMENT_MAX_LEN = 255

const H5FD_ONION_FAPL_INFO_REVISION_ID_LATEST = UINT64_MAX

const H5FD_ROS3 = H5FDperform_init(H5FD_ros3_init)

const H5FD_ROS3_VALUE = H5_VFD_ROS3

const H5FD_CURR_ROS3_FAPL_T_VERSION = 1

const H5FD_ROS3_MAX_REGION_LEN = 32

const H5FD_ROS3_MAX_SECRET_ID_LEN = 128

const H5FD_ROS3_MAX_SECRET_KEY_LEN = 128

const H5FD_ROS3_MAX_SECRET_TOK_LEN = 1024

const H5FD_SEC2 = H5FDperform_init(H5FD_sec2_init)

const H5FD_SEC2_VALUE = H5_VFD_SEC2

const H5FD_SPLITTER = H5FDperform_init(H5FD_splitter_init)

const H5FD_SPLITTER_VALUE = H5_VFD_SPLITTER

const H5FD_CURR_SPLITTER_VFD_CONFIG_VERSION = 1

const H5FD_SPLITTER_PATH_MAX = 4096

const H5FD_SPLITTER_MAGIC = 0x2b916880

const H5FD_STDIO = H5FDperform_init(H5FD_stdio_init)

const H5FD_SUBFILING = H5I_INVALID_HID

const H5FD_SUBFILING_NAME = "subfiling"

const H5FD_IOC = H5I_INVALID_HID

const H5FD_IOC_NAME = "ioc"

const H5VL_PASSTHRU = H5VL_pass_through_register()

const H5VL_PASSTHRU_NAME = "pass_through"

const H5VL_PASSTHRU_VALUE = 1

const H5VL_PASSTHRU_VERSION = 0

