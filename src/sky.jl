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
    covariance_matrix(component::SkyComponent, ν, lmax, m)

Construct a covariance matrix for the given component of the sky.
"""
function covariance_matrix(component::SkyComponent, ν, lmax, m)
    Nfreq = length(ν)
    Ncoef = lmax-m+1 # number of spherical harmonic coefficients

    C = zeros(Complex128,Nfreq*Ncoef,Nfreq*Ncoef)
    for β2 = 1:Nfreq, β1 = 1:Nfreq
        block = zeros(Complex128,Ncoef,Ncoef)
        for l = m:lmax
            block[l-m+1,l-m+1] = component(l,ν[β1],ν[β2])
        end
        C[(β1-1)*Ncoef+1:β1*Ncoef,(β2-1)*Ncoef+1:β2*Ncoef] = block
    end
    C
end

