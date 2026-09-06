# SPDX-License-Identifier: MIT

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
of regularly spaced quadrats (see subtype AbstractRegularGrid).

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
abstract type AbstractPlaces{LocationDataType <:
                             Union{Nothing, AbstractLocationData}} end

"""
    AbstractPoints <: AbstractLocationData

Subtype of AbstractLocationData where locations are a series of points in space.
"""
abstract type AbstractPoints <: AbstractLocationData end

"""
    AbstractAreas <: AbstractLocationData

Subtype of AbstractLocationData where locations cover an area rather than being
dimensionless points. A grid cell is an area and so is a polygon, and this is
what they have in common — no more than that, so nothing else is promised here.

"""
abstract type AbstractAreas <: AbstractLocationData end

"""
    AbstractGridded <: AbstractAreas

Subtype of AbstractAreas where locations are gridded: addressed by row and
column, whatever their spacing. This is the level that carries the index
contract — xcells, ycells, cells, indices, xedges, yedges and cellanchor — and
so the level for anything generic over every kind of grid. Cells of differing
size or shape belong here; regularly spaced ones in AbstractRegularGrid below.

"""
abstract type AbstractGridded <: AbstractAreas end

"""
    AbstractRegularGrid <: AbstractGridded

Subtype of AbstractGridded where locations are a grid of regularly spaced,
identically shaped, locations, so that one cell size describes every cell.
That is what lets EcoBase derive the edges, and with them the whole coordinate
surface, from xmin(), xcellsize() and xcells() alone.
"""
abstract type AbstractRegularGrid <: AbstractGridded end

"""
    AbstractCellAnchor

Supertype for what a gridded location's reported coordinates refer to within
each cell. EcoBase does not require either, so a grid declares which it uses
rather than being assumed to use one (see cellanchor). This governs every
coordinate reported for a grid — xrange, coordinates and the edges derived from
them — not merely one of them.

"""
abstract type AbstractCellAnchor end

"""
    CellCentre <: AbstractCellAnchor

Subtype of AbstractCellAnchor where a cell's coordinate is its centre. This is
what any AbstractGridded reports unless it says otherwise.
"""
struct CellCentre <: AbstractCellAnchor end

"""
    CellCorner <: AbstractCellAnchor

Subtype of AbstractCellAnchor where a cell's coordinate is its lower corner —
the smallest x and y it covers.
"""
struct CellCorner <: AbstractCellAnchor end

"""
    AbstractCoordinateOrder

Supertype for the order in which a subtype of AbstractLocationData reports its
two coordinate columns from indices() and coordinates(). EcoBase does not
require either order, so a location data type declares which one it uses rather
than being assumed to use one (see coordinateorder).

"""
abstract type AbstractCoordinateOrder end

"""
    XThenY <: AbstractCoordinateOrder

Subtype of AbstractCoordinateOrder where the first column is x and the second is
y. This is what any AbstractLocationData reports unless it says otherwise.
"""
struct XThenY <: AbstractCoordinateOrder end

"""
    YThenX <: AbstractCoordinateOrder

Subtype of AbstractCoordinateOrder where the first column is y and the second is
x.
"""
struct YThenX <: AbstractCoordinateOrder end

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
