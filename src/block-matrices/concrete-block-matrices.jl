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


"Array that is split into arbitrary blocks."
struct SimpleBlockArray{T, N, S} <: AbstractBlockMatrix{Array{T, N}, 1}
    storage :: S
    cache   :: Cache{Array{T, N}}
    length  :: Int
end
metadata_fields(array::SimpleBlockArray) = (array.length,)
linear_index(::SimpleBlockArray, idx) = idx
indices(array::SimpleBlockArray) = 1:array.length
Base.size(a::SimpleBlockArray) = (a.length,)

"Array that is split into blocks of m."
struct MBlockArray{T, N, S} <: AbstractBlockMatrix{Array{T, N}, 1}
    storage :: S
    cache   :: Cache{Array{T, N}}
    mmax    :: Int
end
metadata_fields(array::MBlockArray) = (array.mmax,)
linear_index(::MBlockArray, m) = m+1
indices(array::MBlockArray) = 0:array.mmax
Base.axes(a::MBlockArray) = (indices(a),)
Base.size(a::MBlockArray) = (a.mmax+1,)

"Array that is split into blocks of frequency."
struct FBlockArray{T, N, S} <: AbstractBlockMatrix{Array{T, N}, 1}
    storage :: S
    cache   :: Cache{Array{T, N}}
    frequencies :: Vector{typeof(1.0u"Hz")}
    bandwidth   :: Vector{typeof(1.0u"Hz")}
end
metadata_fields(array::FBlockArray) = (array.frequencies, array.bandwidth)
linear_index(::FBlockArray, β) = β
indices(array::FBlockArray) = 1:length(array.frequencies)
Base.size(a::FBlockArray) = (length(a.frequencies),)

"Array that is split into blocks of m and frequency."
struct MFBlockArray{T, N, S} <: AbstractBlockMatrix{Array{T, N}, 2}
    storage :: S
    cache   :: Cache{Array{T, N}}
    mmax    :: Int
    frequencies :: Vector{typeof(1.0u"Hz")}
    bandwidth   :: Vector{typeof(1.0u"Hz")}
end
metadata_fields(array::MFBlockArray) = (array.mmax, array.frequencies, array.bandwidth)
linear_index(array::MFBlockArray, m, β) = (array.mmax+1)*(β-1) + (m+1)
indices(array::MFBlockArray) = ((m, β) for β = 1:length(array.frequencies) for m = 0:array.mmax)
Base.axes(a::MFBlockArray) = (0:a.mmax,1:length(a.frequencies))
Base.size(a::MFBlockArray) = (a.mmax,length(a.frequencies))

"Diagonal array that is split into blocks of m and frequency."
struct MFDiagonalBlockArray{T, S} <: AbstractBlockMatrix{Diagonal{T}, 2}
    storage :: S
    cache   :: Cache{Diagonal{T}}
    mmax    :: Int
    frequencies :: Vector{typeof(1.0u"Hz")}
    bandwidth   :: Vector{typeof(1.0u"Hz")}
end
metadata_fields(array::MFDiagonalBlockArray) = (array.mmax, array.frequencies, array.bandwidth)
linear_index(array::MFDiagonalBlockArray, m, β) = (array.mmax+1)*(β-1) + (m+1)
indices(array::MFDiagonalBlockArray) =
    ((m, β) for β = 1:length(array.frequencies) for m = 0:array.mmax)
Base.axes(a::MFDiagonalBlockArray) = (0:a.mmax,1:length(a.frequencies))
Base.size(a::MFDiagonalBlockArray) = (a.mmax+1,length(a.frequencies))

"Array that is split into blocks of l."
struct LBlockArray{T, N, S} <: AbstractBlockMatrix{Array{T, N}, 1}
    storage :: S
    cache   :: Cache{Array{T, N}}
    lmax    :: Int
    frequencies :: Vector{typeof(1.0u"Hz")}
    bandwidth   :: Vector{typeof(1.0u"Hz")}
end
metadata_fields(array::LBlockArray) = (array.lmax, array.frequencies, array.bandwidth)
linear_index(array::LBlockArray, l) = l+1
indices(array::LBlockArray) = L(0):L(array.lmax)
Base.axes(a::LBlockArray) = (0:a.lmax,)
Base.size(a::LBlockArray) = (a.lmax+1,)

"Array that is split into blocks of l and m."
struct LMBlockArray{T, N, S} <: AbstractBlockMatrix{Array{T, N}, 2}
    storage :: S
    cache   :: Cache{Array{T, N}}
    lmax    :: Int
    mmax    :: Int
    frequencies :: Vector{typeof(1.0u"Hz")}
    bandwidth   :: Vector{typeof(1.0u"Hz")}
end
metadata_fields(array::LMBlockArray) =
    (array.lmax, array.mmax, array.frequencies, array.bandwidth)
linear_index(array::LMBlockArray, l, m) =
    (m * (2array.lmax - m + 3)) ÷ 2 + l - m + 1
indices(array::LMBlockArray) =
    ((l, m) for m = 0:array.mmax for l = L(m):L(array.lmax))
Base.axes(a::LMBlockArray) = (0:a.lmax,0:a.mmax)
Base.size(a::LMBlockArray) = (a.lmax+1,a.mmax+1)

"""
    struct SimpleBlockVector <: AbstractBlockMatrix{Vector{ComplexF64}, 1}

This type represents a (potentially enormous) complex-valued vector that has been split into blocks.
Each of these blocks is indexed by a number that varies from `1` to `length`.

**Fields:**

* `storage` contains instructions on how to read the vector from disk
* `cache` is used if we want to keep the vector in memory
* `length` determines the number of blocks the vector is divided into

**Usage:**

```jldoctest
julia> x = create(SimpleBlockVector, 10)
SimpleBlockVector(<no file>, cached=true, length=10)

julia> x[5] = ComplexF64[1, 2, 3, 4, 5];

julia> x[5]
5-element Array{Complex{Float64},1}:
 1.0+0.0im
 2.0+0.0im
 3.0+0.0im
 4.0+0.0im
 5.0+0.0im
```

**See also:** [`SimpleBlockMatrix`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const SimpleBlockVector = SimpleBlockArray{ComplexF64, 1}
function Base.show(io::IO, vector::SimpleBlockVector)
    @printf(io, "SimpleBlockVector(%s, cached=%s, length=%d)",
            vector.storage, used(vector.cache) ? "true" : "false", vector.length)
end

"""
    struct SimpleBlockMatrix <: AbstractBlockMatrix{Matrix{ComplexF64}, 1}

This type represents a (potentially enormous) complex-valued matrix that has been split into blocks.
Each of these blocks is indexed by a number that varies from `1` to `length`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `length` determines the number of blocks the matrix is divided into

**Usage:**

```jldoctest
julia> x = create(SimpleBlockMatrix, 10)
SimpleBlockMatrix(<no file>, cached=true, length=10)

julia> x[5] = ComplexF64[1 2; 3 4];

julia> x[5]
2×2 Array{Complex{Float64},2}:
 1.0+0.0im  2.0+0.0im
 3.0+0.0im  4.0+0.0im
```

**See also:** [`SimpleBlockVector`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const SimpleBlockMatrix = SimpleBlockArray{ComplexF64, 2}
function Base.show(io::IO, matrix::SimpleBlockMatrix)
    @printf(io, "SimpleBlockMatrix(%s, cached=%s, length=%d)",
            matrix.storage, used(matrix.cache) ? "true" : "false", matrix.length)
end

"""
    struct MBlockVector <: AbstractBlockMatrix{Vector{ComplexF64}, 1}

This type represents a (potentially enormous) complex-valued vector that has been split into blocks.
Each of these blocks is indexed by its value of \$m\$ that varies from `0` to `mmax`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `mmax` determines the largest value of the \$m\$ quantum number used by the matrix

**Usage:**

```jldoctest
julia> x = create(MBlockVector, 10)
MBlockVector(<no file>, cached=true, mmax=10)

julia> x[0] = ComplexF64[1, 2, 3, 4, 5];

julia> x[0]
5-element Array{Complex{Float64},1}:
 1.0+0.0im
 2.0+0.0im
 3.0+0.0im
 4.0+0.0im
 5.0+0.0im
```

**See also:** [`MBlockMatrix`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const MBlockVector = MBlockArray{ComplexF64, 1}
function Base.show(io::IO, vector::MBlockVector)
    @printf(io, "MBlockVector(%s, cached=%s, mmax=%d)",
            vector.storage, used(vector.cache) ? "true" : "false", vector.mmax)
end

"""
    struct MBlockMatrix <: AbstractBlockMatrix{Matrix{ComplexF64}, 1}

This type represents a (potentially enormous) complex-valued matrix that has been split into blocks.
Each of these blocks is indexed by its value of \$m\$ that varies from `0` to `mmax`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `mmax` determines the largest value of the \$m\$ quantum number used by the matrix

**Usage:**

```jldoctest
julia> x = create(MBlockMatrix, 10)
MBlockMatrix(<no file>, cached=true, mmax=10)

julia> x[0] = ComplexF64[1 2; 3 4];

julia> x[0]
2×2 Array{Complex{Float64},2}:
 1.0+0.0im  2.0+0.0im
 3.0+0.0im  4.0+0.0im
```

**See also:** [`MBlockVector`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const MBlockMatrix = MBlockArray{ComplexF64, 2}
function Base.show(io::IO, matrix::MBlockMatrix)
    @printf(io, "MBlockMatrix(%s, cached=%s, mmax=%d)",
            matrix.storage, used(matrix.cache) ? "true" : "false", matrix.mmax)
end

"""
    struct FBlockVector <: AbstractBlockMatrix{Vector{ComplexF64}, 1}

This type represents a (potentially enormous) complex-valued vector that has been split into blocks.
Each of these blocks is indexed by the index of the corresponding frequency channel, which varies
from `1` to `length(frequencies)`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(FBlockVector, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
FBlockVector(<no file>, cached=true, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> x[1] = ComplexF64[1, 2, 3, 4, 5];

julia> x[1]
5-element Array{Complex{Float64},1}:
 1.0+0.0im
 2.0+0.0im
 3.0+0.0im
 4.0+0.0im
 5.0+0.0im
```

**See also:** [`FBlockMatrix`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const FBlockVector = FBlockArray{ComplexF64, 1}
function Base.show(io::IO, vector::FBlockVector)
    @printf(io, "FBlockVector(%s, cached=%s, frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            vector.storage, used(vector.cache) ? "true" : "false",
            u(u"MHz", vector.frequencies[1]), u(u"MHz", vector.frequencies[end]),
            u(u"kHz", mean(vector.bandwidth)))
end

"""
    struct FBlockMatrix <: AbstractBlockMatrix{Matrix{ComplexF64}, 1}

This type represents a (potentially enormous) complex-valued matrix that has been split into blocks.
Each of these blocks is indexed by the index of the corresponding frequency channel, which varies
from `1` to `length(frequencies)`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(FBlockMatrix, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
FBlockMatrix(<no file>, cached=true, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> x[1] = ComplexF64[1 2; 3 4];

julia> x[1]
2×2 Array{Complex{Float64},2}:
 1.0+0.0im  2.0+0.0im
 3.0+0.0im  4.0+0.0im
```

**See also:** [`FBlockVector`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const FBlockMatrix = FBlockArray{ComplexF64, 2}
function Base.show(io::IO, matrix::FBlockMatrix)
    @printf(io, "FBlockMatrix(%s, cached=%s, frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            matrix.storage, used(matrix.cache) ? "true" : "false",
            u(u"MHz", matrix.frequencies[1]), u(u"MHz", matrix.frequencies[end]),
            u(u"kHz", mean(matrix.bandwidth)))
end

"""
    struct MFBlockVector <: AbstractBlockMatrix{Vector{ComplexF64}, 2}

This type represents a (potentially enormous) complex-valued vector that has been split into blocks.
Each of these blocks is indexed by its value of \$m\$, which varies from `0` to `mmax`, and the index
of the corresponding frequency channel, which varies from `1` to `length(frequencies)`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `mmax` determines the largest value of the \$m\$ quantum number used by the matrix
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(MFBlockVector, 2, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
MFBlockVector(<no file>, cached=true, mmax=2, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> x[0, 1] = ComplexF64[1, 2, 3, 4, 5];

julia> x[0, 1]
5-element Array{Complex{Float64},1}:
 1.0+0.0im
 2.0+0.0im
 3.0+0.0im
 4.0+0.0im
 5.0+0.0im
```

**See also:** [`MFBlockMatrix`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const MFBlockVector = MFBlockArray{ComplexF64, 1}
function Base.show(io::IO, vector::MFBlockVector)
    @printf(io, "MFBlockVector(%s, cached=%s, mmax=%d, ",
            vector.storage, used(vector.cache) ? "true" : "false", vector.mmax)
    @printf(io, "frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            u(u"MHz", vector.frequencies[1]), u(u"MHz", vector.frequencies[end]),
            u(u"kHz", mean(vector.bandwidth)))
end

function Base.getindex(matrix::MFBlockVector, m::Int)
    stack_diagonally([matrix[m, β] for β = 1:length(matrix.frequencies)])
end

"""
    struct MFBlockMatrix <: AbstractBlockMatrix{Matrix{ComplexF64}, 2}

This type represents a (potentially enormous) complex-valued matrix that has been split into blocks.
Each of these blocks is indexed by its value of \$m\$, which varies from `0` to `mmax`, and the index
of the corresponding frequency channel, which varies from `1` to `length(frequencies)`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `mmax` determines the largest value of the \$m\$ quantum number used by the matrix
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(MFBlockMatrix, 2, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
MFBlockMatrix(<no file>, cached=true, mmax=2, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> x[0, 1] = ComplexF64[1 2; 3 4];

julia> x[0, 1]
2×2 Array{Complex{Float64},2}:
 1.0+0.0im  2.0+0.0im
 3.0+0.0im  4.0+0.0im
```

**See also:** [`MFBlockVector`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const MFBlockMatrix = MFBlockArray{ComplexF64, 2}
function Base.show(io::IO, matrix::MFBlockMatrix)
    @printf(io, "MFBlockMatrix(%s, cached=%s, mmax=%d, ",
            matrix.storage, used(matrix.cache) ? "true" : "false", matrix.mmax)
    @printf(io, "frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            u(u"MHz", matrix.frequencies[1]), u(u"MHz", matrix.frequencies[end]),
            u(u"kHz", mean(matrix.bandwidth)))
end

function Base.getindex(matrix::MFBlockMatrix, m::Int)
    stack_diagonally([matrix[m, β] for β = 1:length(matrix.frequencies)])
end

# The following type uses Diagonaal{Float64} blocks because we want to use it as a noise covariance
# matrix.

"""
    struct MFDiagonalBlockMatrix <: AbstractBlockMatrix{Diagonal{Float64}, 2}

This type represents a (potentially enormous) complex-valued diagonal matrix that has been split
into blocks.  Each of these blocks is indexed by its value of \$m\$, which varies from `0` to `mmax`,
and the index of the corresponding frequency channel, which varies from `1` to
`length(frequencies)`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `mmax` determines the largest value of the \$m\$ quantum number used by the matrix
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(MFDiagonalBlockMatrix, 2, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
MFDiagonalBlockMatrix(<no file>, cached=true, mmax=2, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> x[0, 1] = Diagonal(Float64[1, 2]);

julia> x[0, 1]
2×2 Diagonal{Float64}:
 1.0   ⋅ 
  ⋅   2.0
```

**See also:** [`MFBlockMatrix`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const MFDiagonalBlockMatrix = MFDiagonalBlockArray{Float64}
function Base.show(io::IO, matrix::MFDiagonalBlockMatrix)
    @printf(io, "MFDiagonalBlockMatrix(%s, cached=%s, mmax=%d, ",
            matrix.storage, used(matrix.cache) ? "true" : "false", matrix.mmax)
    @printf(io, "frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            u(u"MHz", matrix.frequencies[1]), u(u"MHz", matrix.frequencies[end]),
            u(u"kHz", mean(matrix.bandwidth)))
end

function Base.getindex(matrix::MFDiagonalBlockMatrix, m::Int)
    stack_diagonally([matrix[m, β] for β = 1:length(matrix.frequencies)])
end

# The following type uses Matrix{Float64} blocks because we want to use it as an angular covariance
# matrix, which is block diagonal in l and has real elements.

"""
    struct LBlockMatrix <: AbstractBlockMatrix{Matrix{Float64}, 1}

This type represents a (potentially enormous) complex-valued matrix that has been split into blocks.
Each of these blocks is indexed by its value of \$l\$, which varies from `0` to `lmax`.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `lmax` determines the largest value of the \$l\$ quantum number used by the matrix
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(LBlockMatrix, 2, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
LBlockMatrix(<no file>, cached=true, lmax=2, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> l = BPJSpec.L(0);

julia> x[l] = Float64[1 2; 3 4];

julia> x[l]
2×2 Array{Float64,2}:
 1.0  2.0
 3.0  4.0
```

**See also:** [`LMBlockVector`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const LBlockMatrix = LBlockArray{Float64, 2}
function Base.show(io::IO, matrix::LBlockMatrix)
    @printf(io, "LBlockMatrix(%s, cached=%s, lmax=%d, ",
            matrix.storage, used(matrix.cache) ? "true" : "false", matrix.lmax)
    @printf(io, "frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            u(u"MHz", matrix.frequencies[1]), u(u"MHz", matrix.frequencies[end]),
            u(u"kHz", mean(matrix.bandwidth)))
end

Base.getindex(matrix::LBlockMatrix, l::L, m::Int) = matrix[L(l)]

function Base.getindex(matrix::LBlockMatrix, m::Int)
    Nfreq  = length(matrix.frequencies)
    Nalm   = matrix.lmax - m + 1
    output = zeros(Nfreq*Nalm, Nfreq*Nalm)
    for l = L(m):L(matrix.lmax)
        block = matrix[l, m]
        for β1 = 1:Nfreq, β2 = 1:Nfreq
            idx1 = Nalm*(β1-1) + l - m + 1
            idx2 = Nalm*(β2-1) + l - m + 1
            output[idx1, idx2] = block[β1, β2]
        end
    end
    output
end

function Base.getindex(matrix::LBlockMatrix, m::Int, β::Int)
    Nalm   = matrix.lmax - m + 1
    output = zeros(Nalm, Nalm)
    for l = L(m):L(matrix.lmax)
        block = matrix[l, m]
        idx = l - m + 1
        output[idx, idx] = block[β, β]
    end
    output
end

"""
    struct LMBlockVector <: AbstractBlockMatrix{Vector{ComplexF64}, 2}

This type represents a (potentially enormous) complex-valued vector that has been split into blocks.
Each of these blocks is indexed by its value of \$l\$, which varies from `0` to `lmax`, and \$m\$, which
varies from `0` to `mmax` with the restriction that \$m ≤ l\$.

**Fields:**

* `storage` contains instructions on how to read the matrix from disk
* `cache` is used if we want to keep the matrix in memory
* `lmax` determines the largest value of the \$l\$ quantum number used by the matrix
* `mmax` determines the largest value of the \$m\$ quantum number used by the matrix
* `frequencies` is a list of the frequency channels represented by this matrix
* `bandwidth` is a list of the corresponding bandwidth of each frequency channel

**Usage:**

```jldoctest
julia> x = create(LMBlockVector, 2, 2, [74u"MHz", 100u"MHz"], [24u"kHz", 24u"kHz"])
LMBlockVector(<no file>, cached=true, lmax=2, mmax=2, frequencies=74.000 MHz…100.000 MHz, bandwidth~24 kHz)

julia> x[0, 0] = ComplexF64[1, 2, 3, 4, 5];

julia> x[0, 0]
5-element Array{Complex{Float64},1}:
 1.0+0.0im
 2.0+0.0im
 3.0+0.0im
 4.0+0.0im
 5.0+0.0im
```

**See also:** [`LBlockMatrix`](@ref), [`AbstractBlockMatrix`](@ref)
"""
const LMBlockVector = LMBlockArray{ComplexF64, 1}
function Base.show(io::IO, vector::LMBlockVector)
    @printf(io, "LMBlockVector(%s, cached=%s, lmax=%d, mmax=%d, ",
            vector.storage, used(vector.cache) ? "true" : "false", vector.lmax, vector.mmax)
    @printf(io, "frequencies=%.3f MHz…%.3f MHz, bandwidth~%.0f kHz)",
            u(u"MHz", vector.frequencies[1]), u(u"MHz", vector.frequencies[end]),
            u(u"kHz", mean(vector.bandwidth)))
end

