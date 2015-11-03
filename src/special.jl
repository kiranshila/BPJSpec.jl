# Copyright (c) 2015 Michael Eastwood
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

import GSL: sf_legendre_sphPlm

"""
    Y(l,m,θ,ϕ)

The spherical harmonic function (using the Condon-Shortley phase
convention).
"""
function Y(l,m,θ,ϕ)
    out = sf_legendre_sphPlm(l,abs(m),cos(θ))*exp(1im*m*ϕ)
    # GSL already applies the Condon-Shortley phase convention
    # to this result, so if we want m < 0 we need to undo the
    # factor of (-1)^m.
    out *= m < 0? (-1)^(-m) : 1
    out
end

"""
    j(l,x)

The spherical Bessel function (of the first kind).
"""
function j(l,x)
    sqrt(π/(2x))*besselj(l+1/2,x)
end

"""
    tr(A,B) -> tr(AB)

The trace of the product of two matrices, computed
without first computing the product itself.
"""
function tr{T}(A::Matrix{T},B::Matrix{T})
    trace = zero(T)
    Bt = transpose(B)
    for i in eachindex(A)
        trace += A[i]*Bt[i]
    end
    trace
end

"""
    planewave(u,v,w,Δphase=0.0;lmax=100,mmax=100)

Compute the spherical harmonic coefficients corresponding to the
plane wave:

    exp(2im*π*(u*x+v*y+w*z)) * exp(1im*Δphase)
"""
function planewave(u,v,w,Δphase=0.0;lmax::Int=100,mmax::Int=100)
    b = sqrt(u*u+v*v+w*w)
    θ = acos(w/b)
    ϕ = atan2(v,u)
    realpart = Alm(Complex128,lmax,mmax)
    imagpart = Alm(Complex128,lmax,mmax)
    for m = 0:mmax, l = m:lmax
        alm1 = 4π*(1im)^l*j(l,2π*b)*conj(       Y(l,+m,θ,ϕ))*exp(1im*Δphase)
        alm2 = 4π*(1im)^l*j(l,2π*b)*conj((-1)^m*Y(l,-m,θ,ϕ))*exp(1im*Δphase)
        realpart[l,m] = (alm1 + conj(alm2))/2
        imagpart[l,m] = (alm1 - conj(alm2))/2im
    end
    realpart,imagpart
end

"""
    force_hermitian(A) -> 0.5*(A+A')

Force the matrix `A` to be Hermitian. This is intended to be used
on matrices that are nearly Hermitian, but not
to the numerical precision required by `ishermitian`.
"""
force_hermitian(A) = 0.5*(A+A')

"""
    force_posdef(A,ϵ=1e-10) -> A+ϵ*I

If the matrix `A`, is nearly positive definite, but has small
negative eigenvalues, this function can be used to make the matrix
positive definite.
"""
force_posdef(A,ϵ=1e-10) = A+ϵ*I

doc"""
    gramschmidt(u,v)

Remove the projection of $u$ onto $v$ from $u$ for unit vectors $u$ and $v$.
That is, compute $u - u\cdot u$ but the output is normalized.
"""
function gramschmidt(u,v)
    u = u - dot(u,v)*v
    normalize!(u)
end

doc"""
    angle_between(u,v)

Compute the angle between the vectors $u$ and $v$.
"""
function angle_between(u,v)
    normalize!(u)
    normalize!(v)
    # if u and v are unit vectors, only numerical errors
    # will push the dot product out of the range [-1,+1]
    dot_product = clamp(dot(u,v),-1.0,1.0)
    acos(dot_product)
end

doc"""
    normalize!(u)

Normalize the vector $u$.
"""
function normalize!(u)
    n = norm(u,2)
    for i in eachindex(u)
        u[i] = u[i]/n
    end
    u
end

