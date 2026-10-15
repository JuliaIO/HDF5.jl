# Initializing the HDF5 library (`H5open`) uses the x87 FPU of the calling thread:
# `H5T__init_native_float_types` (`src/H5Tinit_float.c`, since HDFGroup/hdf5#3104)
# detects the format of `long double` at run time with x87 arithmetic (`long double` is
# the 80-bit x87 format on x86_64), and it restores the floating-point environment with
# `feupdateenv`, which also loads the x87 environment (`fldenv`). This leaves the x87
# state component of the calling thread "in use" (XINUSE[0] = 1) for the rest of the
# session; `fninit` and `emms` do not undo that. On some CPUs (measured on AMD Zen 3),
# floating-point heavy code then often runs 1.5-2% slower on this thread (more dispatch
# stalls on a full floating-point register file), and parallel loops wait for it.
# An `xrstor` that requests only the x87 component from a save area whose XSTATE_BV
# header has the x87 bit clear puts the x87 state back into its initial configuration
# and clears XINUSE[0]. SSE/AVX state (including MXCSR) is not touched.
@static if Sys.ARCH === :x86_64
    @inline function _cpuid_ecx1()
        return Base.llvmcall(
            (
                """
                define i32 @entry() #0 {
                %r = call {i32, i32, i32, i32} asm sideeffect "cpuid", "={ax},={bx},={cx},={dx},{ax},{cx}"(i32 1, i32 0)
                %c = extractvalue {i32, i32, i32, i32} %r, 2
                ret i32 %c }
                attributes #0 = { alwaysinline }
                """,
                "entry"
            ),
            UInt32,
            Tuple{}
        )
    end

    function reset_x87_state!()
        # OSXSAVE (CPUID.1:ECX bit 27): `xrstor` is enabled by the OS
        (_cpuid_ecx1() >> 27) & 0x1 == 0x1 || return nothing
        # 512-byte legacy region + 64-byte XSAVE header, zeroed (XSTATE_BV = 0,
        # XCOMP_BV = 0: standard format), aligned to 64 bytes. The address is passed to the
        # assembly as an integer, since Julia v1.10 (LLVM with typed pointers) does not
        # know the `ptr` type.
        buf = zeros(UInt8, 576 + 64)
        GC.@preserve buf begin
            p = (UInt(pointer(buf)) + 63) & ~UInt(63)
            Base.llvmcall(
                (
                    """
                    define void @entry(i64 %p) #0 {
                    call void asm sideeffect "xrstor64 (\$0)", "r,{ax},{dx},~{memory},~{fpsr},~{dirflag}"(i64 %p, i32 1, i32 0)
                    ret void }
                    attributes #0 = { alwaysinline }
                    """,
                    "entry"
                ),
                Cvoid,
                Tuple{UInt},
                p
            )
        end
        return nothing
    end
else
    reset_x87_state!() = nothing
end
