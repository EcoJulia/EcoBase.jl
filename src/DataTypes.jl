
# depend explicitly on AxisArrays (sparse) in some implementation?

abstract type AbstractThings end
abstract type AbstractPlaces end
abstract type AbstractGrid <: AbstractPlaces end
abstract type AbstractPoints <: AbstractPlaces end
abstract type AbstractAssemblage{T <: AbstractThings, P <: AbstractPlaces} <: AbstractTemporalAssemblage end
abstract type AbstractTemporalAssemblage end 
