

abstract type AbstractThings end
abstract type AbstractPlaces end
abstract type AbstractLocations <: AbstractPlaces end
abstract type AbstractGrid <: AbstractLocations end
abstract type AbstractAssemblage{T <: AbstractThings,
                                 P <: AbstractPlaces,
                                 D <: Real}

# depend explicitly on AxisArrays (and/or sparse) in some implementation?
