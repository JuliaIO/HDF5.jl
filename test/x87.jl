using HDF5, Test

@testset "x87 state" begin
    # Calling it again is harmless, and it does not touch the SSE state (MXCSR)
    rounding_before = rounding(Float64)
    subnormals_before = get_zero_subnormals()
    HDF5.API.reset_x87_state!()
    @test rounding(Float64) == rounding_before
    @test get_zero_subnormals() == subnormals_before
    @test 1.0 / 3.0 == 0.3333333333333333

    @static if Sys.ARCH === :x86_64
        # LLVM IR of `xgetbv` with ECX = 1, which returns XINUSE
        XGETBV1_IR = """
        define i64 @entry() #0 {
        %r = call {i32, i32} asm sideeffect "xgetbv", "={ax},={dx},{cx}"(i32 1)
        %a = extractvalue {i32, i32} %r, 0
        %z = zext i32 %a to i64
        ret i64 %z }
        attributes #0 = { alwaysinline }
        """
        cpuid(leaf, subleaf) = Base.llvmcall(
            (
                """
                define i32 @entry(i32 %l, i32 %s) #0 {
                %r = call {i32, i32, i32, i32} asm sideeffect "cpuid", "={ax},={bx},={cx},={dx},{ax},{cx}"(i32 %l, i32 %s)
                %a = extractvalue {i32, i32, i32, i32} %r, 0
                ret i32 %a }
                attributes #0 = { alwaysinline }
                """,
                "entry"
            ),
            UInt32,
            Tuple{UInt32,UInt32},
            UInt32(leaf),
            UInt32(subleaf)
        )
        # XGETBV with ECX = 1 returns XINUSE if CPUID.(EAX=0DH,ECX=1):EAX[2] is set
        osxsave = (HDF5.API._cpuid_ecx1() >> 27) & 0x1 == 0x1
        if osxsave && cpuid(0x0, 0x0) >= 0xd && (cpuid(0xd, 0x1) >> 2) & 0x1 == 0x1
            @eval xinuse() = Base.llvmcall(($XGETBV1_IR, "entry"), Int64, Tuple{})
            # The x87 state of this thread is in its initial configuration again
            @test Base.invokelatest(xinuse) & 0x1 == 0
            # Loading HDF5 in a new process leaves the x87 state of the loading thread in
            # its initial configuration (`HDF5.API.__init__` calls `reset_x87_state!`)
            code = """
            using HDF5
            xinuse() = Base.llvmcall(($(repr(XGETBV1_IR)), "entry"), Int64, Tuple{})
            print(xinuse() & 0x1)
            """
            cmd = `$(Base.julia_cmd()) --startup-file=no --project=$(Base.active_project()) -e $code`
            @test read(cmd, String) == "0"
        end
    end
end
