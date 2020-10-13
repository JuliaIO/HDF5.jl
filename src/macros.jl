import Base.Meta: isexpr

"""
```julia
@defconstants H5PREFIX begin
    STATIC_CONSTANT::hid_t = 1
    DYNAMIC_CONSTANT::hid_t
    ...
end
```

Defines a collection of "constants" (`STATIC_CONSTANT`, `DYANMIC_CONSTANT`, ...) within
the namespace `H5PREFIX` wherein the distinction between runtime and static values is
abstracted away from the user's view.

For truly constant values such as `STATIC_CONSTANT`, the syntax is given as in the first
line above where the value is assigned to a name with a type assertion. The value may also
be an expression which is evaluated the current module context. Note that the value
evaluation occurs before the constants are assigned, so the expression cannot refer to
any previous constants within the same block; e.g. the following will not work:
```julia
julia> @defconstants BITMASK begin
           BIT_ONE::UInt = 0x1
           BIT_TWO::UInt = 0x2
           BIT_BOTH::Uint = BIT_ONE | BIT_TWO
       end
ERROR: LoadError: UndefVarError: BIT_ONE not defined
...
```

The second permitted syntax is for runtime constants which require initialization.
In this form, only the name and value type are given, and an appropriately-typed,
uninitialized `Ref` container is assigned to the constant binding. These values must be
assigned at runtime from an `__init__()` function:
```julia
function __init__()
    H5PREFIX.DYANMIC_CONSTANT = my_runtime_value()
end
```
"""
macro defconstants(prefix::Symbol, expr::Expr)
    isexpr(expr, :block) || error("Expected block expression")
    stmts = expr.args

    symbols = Vector{Symbol}(undef, 0)
    imports = Vector{Union{Symbol,Expr}}(undef, 0)
    defbody = Vector{Expr}(undef, 0)
    getbody = Vector{Expr}(undef, 0)
    setbody = Vector{Expr}(undef, 0)

    innermod = Symbol(:_, prefix)
    for line in stmts
        line isa LineNumberNode && continue

        isruntime = isexpr(line, :(=)) ? false :
                    isexpr(line, :(::)) ? true :
                    error("Unexpected statement: ", repr(line))

        # Get the name and type pair
        nametype = isruntime ? line : line.args[1]
        isexpr(nametype, :(::)) || error("Expected `name::type`, got ", repr(nametype))
        name = nametype.args[1]::Symbol
        type = nametype.args[2]
        # Save type for later use
        push!(imports, type)

        value = isruntime ? esc(:(Ref{$type}())) :
                            QuoteNode(Core.eval(__module__, line.args[2]))
        fullname = esc(:($innermod.$name))
        getexpr = isruntime ? :($(fullname)[]) : fullname

        push!(symbols, name)
        push!(defbody, :(const $(esc(name)) = $value))
        push!(getbody, :(sym === $(QuoteNode(name)) && return $getexpr))
        if isruntime
            setexpr = quote
                sym === $(QuoteNode(name)) && begin
                    $fullname[] = value
                    return value
                end
            end
            append!(setbody, Base.remove_linenums!(setexpr).args)
        end
    end

    # Build expressions to import all necessary types from the parent module.
    push!(imports, :Ref) # explicitly add `Ref`
    imports = Expr[Expr(:(.), :(.), :(.), sym) for sym in unique!(imports)]
    # Push the imports into the definition body
    pushfirst!(defbody, Expr(:import, imports...))

    eprefix = esc(prefix)
    einnermod = esc(innermod)
    block = quote
        baremodule $einnermod
            struct $eprefix end
            $(defbody...)
        end
        const $eprefix = $einnermod.$prefix()
        function Base.propertynames(::$einnermod.$prefix)
            return $((symbols...,))
        end
        function Base.getproperty(::$einnermod.$prefix, sym::Symbol)
            $(getbody...)
        end
    end
    if !isempty(setbody)
        setfn = quote
            function Base.setproperty!(::$einnermod.$prefix, sym::Symbol, value)
                $(setbody...)
            end
        end
        append!(block.args, Base.remove_linenums!(setfn).args)
    end

    Base.remove_linenums!(block)
    block.head = :toplevel
    return block
end
