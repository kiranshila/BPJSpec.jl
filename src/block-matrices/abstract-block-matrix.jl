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

"""
    abstract type AbstractBlockMatrix{B, N}

This type represents a (potentially enormous) block-diagonal matrix. This type is designed to be
general enough to handle large matrices that fit in memory as well as enormous matrices that do not
fit in memory. In principle this type can also be used to store small matrices, but it would be
relatively inefficient compared to the standard `Array{T, N}`.

# Type Parameters

* `B` specifies the type of the blocks that compose the matrix
* `N` specifies the number of indices used to index into the matrix blocks

# Required Fields

* `storage` contains instructions on how to read matrix blocks
* `cache` is used if we want to read the matrix from disk and then keep it in memory for faster
    access.
"""
abstract type AbstractBlockMatrix{B, N}
    # Fields:
    # storage :: S
    # cache   :: Cache{B}
    # other fields containing metadata
end

struct MatrixMetadata
    T :: Type{<:AbstractBlockMatrix}
    fields :: Tuple
end

function MatrixMetadata(matrix::AbstractBlockMatrix)
    T = typeof(matrix)
    fields = metadata_fields(matrix)
    MatrixMetadata(T, fields)
end

@inline function construct(T::Type{<:AbstractBlockMatrix}, args...)
    if first(args) isa Mechanism
        _construct(T, args[1], args[2:end]...)
    else
        _constrct(T, NoFile(), args...)
    end
end

function _construct(T::Type{<:AbstractBlockMatrix{B}}, storage::Mechanism, fields...) where B
    cache = Cache{B}()
    # Sometimes we will get here with a few (but not all) type parameters already specified. Usually
    # we'd need to provide a special constructor to help with that case, but instead we can discard
    # these type parameters and call the regular constructor.
    T′ = discard_type_parameters(T)
    # Now it seems like sometimes we struggle to get the types exactly right for some of the
    # metadata fields. Try to convert them to the correct type here.
    fields′ = [convert(fieldtype(T, idx+2), fields[idx]) for idx = 1:length(fields)]
    # Finally call the constructor with the converted fields.
    output = T′(storage, cache, fields′...)
    if storage isa NoFile
        resize!(cache, nblocks(output))
        set!(cache)
    end
    output
end

@inline function create(T::Type{<:AbstractBlockMatrix}, args...; kwargs...)
    if first(args) isa Mechanism
        _create(T, args[1], args[2:end]...; kwargs...)
    else
        _create(T, NoFile(), args...; kwargs...)
    end
end

function _create(T::Type{<:AbstractBlockMatrix}, storage::Mechanism, fields...; rm=false)
    output = construct(T, storage, fields...)
    rm && rm_old_blocks!(storage)
    write_metadata(storage, MatrixMetadata(output))
    output
end

function load(path::String)
    storage, metadata = read_metadata(path)
    construct(metadata.T, storage, metadata.fields...)
end

function Base.similar(matrix::AbstractBlockMatrix, storage::Mechanism=NoFile(), fields...)
    T = typeof(matrix)
    if fields === ()
        create(T, storage, metadata_fields(matrix)...)
    else
        create(T, storage, fields...)
    end
end

Base.getindex(matrix::AbstractBlockMatrix, idx) =
    get(matrix, convert(Int, idx))
Base.getindex(matrix::AbstractBlockMatrix, idx, jdx) =
    get(matrix, convert(Int, idx), convert(Int, jdx))
Base.setindex!(matrix::AbstractBlockMatrix, block, idx) =
    set!(matrix, block, convert(Int, idx))
Base.setindex!(matrix::AbstractBlockMatrix, block, idx, jdx) =
    set!(matrix, block, convert(Int, idx), convert(Int, jdx))

@inline Base.getindex(matrix::AbstractBlockMatrix, idx::Tuple) = matrix[idx...]
@inline Base.setindex!(matrix::AbstractBlockMatrix, block, idx::Tuple) = matrix[idx...] = block

nblocks(matrix) = length(collect(indices(matrix)))

function linear_index(matrix::M, tuple::Tuple) where M<:AbstractBlockMatrix
    linear_index(matrix, tuple[1], tuple[2])
end

function get(matrix::AbstractBlockMatrix{B, 1}, idx)::B where B
    if used(matrix.cache)
        return matrix.cache[linear_index(matrix, idx)]
    else
        return matrix.storage[idx]
    end
end

function get(matrix::AbstractBlockMatrix{B, 2}, idx, jdx)::B where B
    if used(matrix.cache)
        return matrix.cache[linear_index(matrix, idx, jdx)]
    else
        return matrix.storage[idx, jdx]
    end
end

function set!(matrix::AbstractBlockMatrix{B, 1}, block::B, idx) where B
    if used(matrix.cache)
        matrix.cache[linear_index(matrix, idx)] = block
    else
        matrix.storage[idx] = block
    end
    block
end

function set!(matrix::AbstractBlockMatrix{B, 2}, block::B, idx, jdx) where B
    if used(matrix.cache)
        matrix.cache[linear_index(matrix, idx, jdx)] = block
    else
        matrix.storage[idx, jdx] = block
    end
    block
end

function cache!(matrix::AbstractBlockMatrix)
    if !used(matrix.cache)
        resize!(matrix.cache, nblocks(matrix))
        for idx in indices(matrix)
            matrix.cache[linear_index(matrix, idx)] = matrix[idx]
        end
        set!(matrix.cache)
    end
    matrix
end

function flush!(matrix::AbstractBlockMatrix)
    if used(matrix.cache)
        unset!(matrix.cache)
        for idx in indices(matrix)
            matrix[idx] = matrix.cache[linear_index(matrix, idx)]
        end
        resize!(matrix.cache, 0)
    end
    matrix
end

# This fallback is so that we can indiscriminately call `cache!` on m-modes in `q_estimator`
# regardless of whether or not these m-modes are an `AbsractBlockVector` or a `RandomBlockVector`,
# which doesn't implement a cache.
cache!(x) = x

distribute_write(matrix::AbstractBlockMatrix) =
    distribute_write(matrix.storage) && !used(matrix.cache)
distribute_read(matrix::AbstractBlockMatrix) =
    distribute_read(matrix.storage) && !used(matrix.cache)

function LinearAlgebra.dot(lhs::AbstractBlockMatrix, rhs::AbstractBlockMatrix)
    output = zero(ComplexF64)
    for idx in indices(lhs)
        output += dot(lhs[idx...], rhs[idx...])
    end
    output
end

