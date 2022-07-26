@testset "m-modes.jl" begin

    frequencies = [74.0u"MHz", 100.0u"MHz"]
    bandwidth = [24u"kHz", 1.0u"MHz"]

    frame = ReferenceFrame()
    position  = measure(frame, observatory("OVRO_MMA"), pos"ITRF")
    baselines = [Baseline(baseline"ITRF", 0, 0, 0)]
    phase_center = Direction(position)
    metadata  = BPJSpec.Metadata(frequencies, bandwidth, position, baselines, phase_center)
    hierarchy = BPJSpec.Hierarchy(metadata)

    mmodes = create(MModes, NoFile(), metadata, hierarchy)

    ϕ = range(0, stop=2π, length=6629)[1:6628]
    X = reshape(cis.(ϕ) .+ 1, 6628, 1)

    compute!(MModes, mmodes, hierarchy, X, 1)

    @test mmodes[0, 1] ≈ [1]
    @test mmodes[1, 1] ≈ [1, 0]
    @test norm(mmodes[2, 1]) < eps(Float64)

    # offset from the time origin
    Y = X[2:2:end, :]
    compute!(MModes, mmodes, hierarchy, Y, 1, dϕ=-2π/length(ϕ))
    @test mmodes[0, 1] ≈ [1]
    @test mmodes[1, 1] ≈ [1, 0]
    @test norm(mmodes[2, 1]) < eps(Float64)

end

