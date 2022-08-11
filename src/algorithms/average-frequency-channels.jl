# Copyright (c) 2015-2017 Michael Eastwood
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

function average_frequency_channels(input, Navg; storage=NoFile(), progress=false)
    ν  = input.frequencies
    Δν = input.bandwidth
    Nfreq = length(ν)

    partition = collect(Iterators.partition(1:Nfreq, Navg))
    weights   = u.(u"Hz", Δν)

    Nfreq′ = length(partition)
    ν′  = similar(ν,  Nfreq′)
    Δν′ = similar(Δν, Nfreq′)
    for β = 1:length(partition)
        channels = partition[β]
        ν′[β]  = sum(weights[channels].*ν[channels]) / sum(weights[channels])
        Δν′[β] = sum(Δν[channels])
    end

    # Perform the averaging.
    output = similar(input, storage, input.mmax, ν′, Δν′)
    queue  = collect(indices(output))
    pool   = CachingPool(workers())
    if progress
        lck = ReentrantLock()
        prg = Progress(length(queue))
        increment() = (lock(lck); next!(prg); unlock(lck))
    end
    @sync for worker in workers()
        @async while length(queue) > 0
            m, β = popfirst!(queue)
            remotecall_wait(_average_frequency_channels, pool,
                            input, output, Δν, Δν′, m, β, partition[β])
            progress && increment()
        end
    end
    output
end

function _average_frequency_channels(input, output, Δν, Δν′, m, β, channels)
    # NOTE: we are using regular multiplication (*) here instead of broadcasted multiplication (.*)
    # because broadcasting changes `Diagonal` matrices to `SparseMatrixCSC`, which is undesirable
    # behavior for our noise covariance matrices.
    #
    # julia> x = Diagonal([1.0, 2.0, 3.0])
    # 3×3 Diagonal{Float64}:
    #  1.0   ⋅    ⋅
    #   ⋅   2.0   ⋅
    #   ⋅    ⋅   3.0
    #
    # julia> x .* 3
    # 3×3 SparseMatrixCSC{Float64,Int64} with 3 stored entries:
    #   [1, 1]  =  3.0
    #   [2, 2]  =  6.0
    #   [3, 3]  =  9.0
    #
    # julia> x * 3
    # 3×3 Diagonal{Float64}:
    #  3.0   ⋅    ⋅
    #   ⋅   6.0   ⋅
    #   ⋅    ⋅   9.0

    β′ = channels[1]
    weight = u(NoUnits, Δν[β′]/Δν′[β])
    B = input[m, β′] * weight

    for β′ in channels[2:end]
        weight = u(NoUnits, Δν[β′]/Δν′[β])
        B += input[m, β′] * weight
    end

    output[m, β] = B
end

