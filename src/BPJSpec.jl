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

__precompile__()

module BPJSpec

export create_empty_visibilities, grid_visibilities, load_visibilities

export TransferMatrix, healpix, gentransfer, one_ν, one_m

#export ObsParam
#export lmax, mmax, Nfreq
#export MModes, SpectralMModes, visibilities, tikhonov
#export ProjectionMatrix, compression
#export CovarianceMatrix, ForegroundModel, SphericalSignalModel, congruence

using CasaCore.Measures
using CasaCore.Tables
using HDF5, JLD
using LibHealpix
using ProgressMeter
using TTCal

importall Base.Operators
import Cosmology
import GSL
import LibHealpix: Alm, lmax, mmax

include("special.jl") # special functions
include("physics.jl") # physical constants and cosmology
include("blocks.jl")  # block vectors and matrices

# This function is useful to handle some of the
# special casing required for m == 0
two(m) = ifelse(m != 0, 2, 1)

include("visibilities.jl")
include("transfermatrix.jl")

#include("obs.jl")
#include("mmodes.jl")
#include("projection.jl")
#include("alm.jl")
#include("covariancematrix.jl")

end

