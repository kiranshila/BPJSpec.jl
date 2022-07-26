function test_matrix(T, eltype, N, idx1, idx2, fields...)
    path1 = tempname()
    path2 = tempname()
    for S in (NoFile, SingleFile, MultipleFiles)
        try
            matrix1 = create(T, S(path1), fields...)
            matrix2 = create(T, S(path2), fields...)
            if N == 1
                X = rand(eltype, 5)
                Y = rand(eltype, 3)
            else
                X = rand(eltype, 5, 5)
                Y = rand(eltype, 3, 3)
            end
            matrix1[idx1...] = X
            matrix1[idx2...] = Y
            @test matrix1[idx1...] == X
            @test matrix1[idx2...] == Y
            @. matrix2 = 2*(matrix1+matrix1)
            @test matrix2[idx1...] == 2*(X+X)
            @test matrix2[idx2...] == 2*(Y+Y)
            if S != NoFile
                matrix3 = BPJSpec.load(path1)
                @test matrix3[idx1...] == X
                @test matrix3[idx2...] == Y
                cache!(matrix1)
                cache!(matrix2)
                @. matrix2 = 3*(matrix1+matrix1)
                @test matrix1[idx1...] == X
                @test matrix1[idx2...] == Y
                @test matrix2[idx1...] == 3*(X+X)
                @test matrix2[idx2...] == 3*(Y+Y)
            end
        finally
            rm(path1, force=true, recursive=true)
            rm(path2, force=true, recursive=true)
        end
    end
end

@testset "concrete-block-matrices.jl" begin
    length = 2
    lmax   = 1
    mmax   = 1
    frequencies = [74.0u"MHz", 100.0u"MHz"]
    bandwidth   = [24u"kHz", 1.0u"MHz"]

    @testset "SimpleBlockArray" begin
        test_matrix(SimpleBlockVector, ComplexF64, 1, (1,), (2,), length)
        test_matrix(SimpleBlockMatrix, ComplexF64, 2, (1,), (2,), length)

        v = create(SimpleBlockVector, 1)
        @test repr(v) == "SimpleBlockVector(<no file>, cached=true, length=1)"
        A = create(SimpleBlockMatrix, 1)
        @test repr(A) == "SimpleBlockMatrix(<no file>, cached=true, length=1)"
    end

    @testset "MBlockArray" begin
        test_matrix(MBlockVector, ComplexF64, 1, (0,), (1,), mmax)
        test_matrix(MBlockMatrix, ComplexF64, 2, (0,), (1,), mmax)

        v = create(MBlockVector, 1)
        @test repr(v) == "MBlockVector(<no file>, cached=true, mmax=1)"
        A = create(MBlockMatrix, 1)
        @test repr(A) == "MBlockMatrix(<no file>, cached=true, mmax=1)"
    end

    @testset "FBlockArray" begin
        test_matrix(FBlockVector, ComplexF64, 1, (1,), (2,), frequencies, bandwidth)
        test_matrix(FBlockMatrix, ComplexF64, 2, (1,), (2,), frequencies, bandwidth)

        v = create(FBlockVector, [74.000u"MHz", 74.024u"MHz"], [24u"kHz", 24u"kHz"])
        @test repr(v) == string("FBlockVector(<no file>, cached=true, ",
                                "frequencies=74.000 MHz…74.024 MHz, bandwidth~24 kHz)")
        A = create(FBlockMatrix, [74.000u"MHz", 74.024u"MHz"], [24u"kHz", 24u"kHz"])
        @test repr(A) == string("FBlockMatrix(<no file>, cached=true, ",
                                "frequencies=74.000 MHz…74.024 MHz, bandwidth~24 kHz)")
    end

    @testset "MFBlockArray" begin
        test_matrix(MFBlockVector, ComplexF64, 1, (0, 1), (0, 2), 0, frequencies, bandwidth)
        test_matrix(MFBlockMatrix, ComplexF64, 2, (0, 1), (0, 2), 0, frequencies, bandwidth)

        v = create(MFBlockVector, 1, [74.000u"MHz", 74.024u"MHz"], [24u"kHz", 24u"kHz"])
        @test repr(v) == string("MFBlockVector(<no file>, cached=true, mmax=1, ",
                                "frequencies=74.000 MHz…74.024 MHz, bandwidth~24 kHz)")
        A = create(MFBlockMatrix, 1, [74.000u"MHz", 74.024u"MHz"], [24u"kHz", 24u"kHz"])
        @test repr(A) == string("MFBlockMatrix(<no file>, cached=true, mmax=1, ",
                                "frequencies=74.000 MHz…74.024 MHz, bandwidth~24 kHz)")
    end

    @testset "LBlockArray" begin
        test_matrix(LBlockMatrix, Float64, 2, (L(0),), (L(1),), lmax, frequencies, bandwidth)

        A = create(LBlockMatrix, 1, [74.000u"MHz", 74.024u"MHz"], [24u"kHz", 24u"kHz"])
        @test repr(A) == string("LBlockMatrix(<no file>, cached=true, lmax=1, ",
                                "frequencies=74.000 MHz…74.024 MHz, bandwidth~24 kHz)")
    end

    @testset "LMBlockArray" begin
        test_matrix(LMBlockVector, ComplexF64, 1, (0, 0), (1, 0), lmax, 0, frequencies, bandwidth)

        v = create(LMBlockVector, 2, 1, [74.000u"MHz", 74.024u"MHz"], [24u"kHz", 24u"kHz"])
        @test repr(v) == string("LMBlockVector(<no file>, cached=true, lmax=2, mmax=1, ",
                                "frequencies=74.000 MHz…74.024 MHz, bandwidth~24 kHz)")
    end
end

