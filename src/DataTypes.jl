using Compat: Nothing
"""
    AbstractThings

Supertype for container of objects being observed, whether these are
species, sequences, tips of a phylogeny (which could be either), or
some other type of thing. This will contain the names of the things
being observed, and (optionally) metadata about them, such as a
phylogeny that connects them, taxonomic information, their sequences,
trait information, information on similarity between the different
things, etc.

"""
abstract type AbstractThings end

"""
    AbstractLocationData

Composed within AbstractPlaces in cases when geographic location data exists. It
can reference locations with some geographical component. This may be a
series of arbitrarily arranged points, a series of areas, or even grid
of regularly spaced quadrats (see subtype AbstractGrid).

"""
abstract type AbstractLocationData end

"""
    AbstractPlaces{LocationDataType <: Union{Nothing, AbstractLocationData}}

AbstractPlaces is the supertype for containers of the places where things are
found (see AbstractThings). This will contain names or a reference for the
places, and (optionally) metadata such as what kind of place these are.
AbstractPlaces is parameterised by the spatial location data type for the
places. This should be Nothing if the places have no associated spatial data, or
a subtype of AbstractLocationData if they have spatial data. Other metadata in
the AbstractPlaces subtype should be in the AbstractPlaces subtype.

"""
abstract type AbstractPlaces{LocationDataType <: Union{Nothing, AbstractLocationData}} end

"""
    AbstractPoints <: AbstractLocationData

Subtype of AbstractLocationData where locations are a series of points in space.
"""
abstract type AbstractPoints <: AbstractLocationData end

"""
    AbstractGrid <: AbstractLocationData

Subtype of AbstractLocationData where locations are a grid of regularly
spaced, identically shaped, locations.
"""
abstract type AbstractGrid <: AbstractLocationData end

"""
    AbstractAssemblage{D <: Real (e.g. Int, Float64, Bool),
                       T <: AbstractThings,
                       P <: AbstractPlaces}

An assemblage of things recorded as being present in one or more
places. These may, for instance, be species counts in quadrats over a
regular grid, relative abundance of viral sequences in a group of
individuals, or presence-absence of genera over multiple islands.

"""
abstract type AbstractAssemblage{D <: Real,
                                 T <: AbstractThings,
                                 P <: AbstractPlaces} end

# depend explicitly on AxisArrays (and/or sparse) in some implementation?
