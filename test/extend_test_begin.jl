function extend_test_begin(d)
    @test d[1, begin] ≈ 1.1231
    @test d[:, begin] ≈ [1.1231]
    @test d[begin, :] == [1.1231, 1.313, 5.123, 2.231, 4.1231]
    @test d[:, begin:end] == [1.1231 1.313 5.123 2.231 4.1231]
end
