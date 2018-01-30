
# depend explicitly on AxisArrays (sparse) in some implementation?

abstract type AbstractThings{T, N, M <: AbstractArray{N, T}} end
abstract type AbstractTimeThings{T, M} <: AbstractThings{T, 3, M} end
abstract type AbstractOnceThings{T, M} <: AbstractThings{T, 2, M} end
abstract type AbstractPlaces end
abstract type AbstractGrid <: AbstractSites end
abstract type AbstractPoints <: AbstractSites end
abstract type AbstractAssemblage{T <: AbstractThings, P <: AbstractPlaces} end
