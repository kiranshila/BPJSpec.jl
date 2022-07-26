@testset "CosmologyWrapper.jl" begin
    # Tests against Ned Wright's cosmology calculator
    # (www.astro.ucla.edu/~wright/CosmoCalc.html)
    # - remember to set H0 = 69, OmegaM = 0.29, flat
    @test abs(BPJSpec.comoving_distance(0.1) -  424.8u"Mpc") < 0.1u"Mpc"
    @test abs(BPJSpec.comoving_distance(10.) - 9689.5u"Mpc") < 0.1u"Mpc"
    @test BPJSpec.comoving_distance(BPJSpec.redshift(74u"MHz")) ==
            BPJSpec.comoving_distance(74u"MHz")

    func = BPJSpec.approximate(BPJSpec.comoving_distance, 10, 30)
    @test func(10) ≈ BPJSpec.comoving_distance(10)
    @test func(20) ≈ BPJSpec.comoving_distance(20)
    @test func(30) ≈ BPJSpec.comoving_distance(30)
end

