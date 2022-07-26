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

module CosmologyWrapper

export comoving_distance, age, frequency, redshift, approximate

import Cosmology
using ApproxFun
using Unitful, UnitfulAstro

const HI = 1420.40575177u"MHz"
const COSM = Cosmology.cosmology()

"""
    comoving_distance(z)

Calculate the comoving distance (in units of Mpc) to the redshift `z`.

**Usage:**

```jldoctest
julia> comoving_distance(1)
3371.509961954628 Mpc

julia> comoving_distance(10)
9689.514711746533 Mpc
```
"""
comoving_distance(z) = Cosmology.comoving_radial_dist(COSM, z)
comoving_distance(ν::Unitful.Frequency) = comoving_distance(redshift(ν))

function approximate(::typeof(comoving_distance), zmin, zmax)
    f = Fun(z -> ustrip(Cosmology.comoving_radial_dist(COSM, z)), zmin..zmax)
    x -> f(x) * u"Mpc"
end


"""
    redshift(ν)

Calculate the redshift from which the emission originates if the 21 cm line
is observed at the frequency `ν`.

**Usage:**

```jldoctest
julia> redshift(100u"MHz")
13.2040575177

julia> redshift(200u"MHz")
6.10202875885
```
"""
redshift(ν)  = HI/ν-1

end

