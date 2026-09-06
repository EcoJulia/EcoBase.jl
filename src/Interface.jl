# SPDX-License-Identifier: MIT

"""
    asindices(x)
    asindices(x, names)

Convert a selector — a position, name, Symbol or boolean mask — into the
integer indices it picks out, looking names up in `names` where given.
"""
asindices(x::Integer) = x
asindices(x::AbstractArray{T}) where {T <: Union{Missing, Integer}} = x
function asindices(x::AbstractArray{Union{Missing, Bool}})
    return findall(y -> !ismissing(y) && y, x)
end
asindices(x::AbstractArray{T}) where {T <: Bool} = findall(x)
asindices(x, y) = asindices(x)
function asindices(x::AbstractArray{T},
                   y::AbstractArray{T}) where {T <:
                                               Union{Missing, AbstractString}}
    return [el for el in indexin(x, y) if el !== nothing]
end
function asindices(x::AbstractArray{T},
                   y::AbstractArray{<:AbstractString}) where {T <:
                                                              Union{Missing,
                                                                    Symbol}}
    return asindices(string.(x), y)
end
function asindices(x::T,
                   y::AbstractArray) where {T <: Union{Missing, Symbol,
                                                  AbstractString}}
    return first(asindices([x], y))
end

# Functions - most have to be implemented with the concrete type
"""
    occurrences(asm)

Return the assemblage's community matrix: what was recorded for each thing
(rows) in each place (columns), as counts, abundances or presences.
"""
occurrences(asm::AbstractAssemblage)::AbstractMatrix = error("function not defined for $(typeof(asm))")

"""
    places(asm)

Return the places the assemblage records — the sites, samples, subcommunities
or grid cells its things were observed in.
"""
places(asm::AbstractAssemblage)::AbstractPlaces = error("function not defined for $(typeof(asm))")

"""
    things(asm)

Return the things the assemblage records — the species, taxa, sequences or
phylogenetic branches observed in its places.
"""
things(asm::AbstractAssemblage)::AbstractThings = error("function not defined for $(typeof(asm))")

# for custom printing
"""
    thingkind(asm)

Return what this assemblage calls its things — "species", "feature", "branch" —
so that printing it reads in the language of the field it came from.
"""
thingkind(asm::AbstractAssemblage) = "thing"

"""
    placekind(asm)

Return what this assemblage calls its places — "site", "sample",
"subcommunity" — so that printing it reads in the language of the field.
"""
placekind(asm::AbstractAssemblage) = "place"

"""
    thingkindplural(asm)

Return the plural of thingkind(), which defaults to adding an s and so needs a
method of its own for anything that does not pluralise that way.
"""
thingkindplural(asm::AbstractAssemblage) = "$(thingkind(asm))s"

"""
    placekindplural(asm)

Return the plural of placekind(), which defaults to adding an s and so needs a
method of its own for anything that does not pluralise that way.
"""
placekindplural(asm::AbstractAssemblage) = "$(placekind(asm))s"

"""
    nplaces(plc)

Return how many places there are.
"""
nplaces(plc::AbstractPlaces)::Integer = error("function not defined for $(typeof(plc))")
nplaces(asm::AbstractAssemblage) = nplaces(places(asm))
nplaces(asm::AbstractAssemblage, args...) = nplaces(places(asm), args...)

"""
    placenames(plc)

Return the name of each place, in the order they appear as columns of
occurrences().
"""
placenames(plc::AbstractPlaces)::AbstractVector{<:String} = error("function not defined for $(typeof(plc))")
placenames(asm::AbstractAssemblage) = placenames(places(asm))
function placenames(asm::AbstractAssemblage, args...)
    return placenames(places(asm), args...)
end

"""
    nthings(thg)

Return how many things there are.
"""
nthings(thg::AbstractThings)::Integer = error("function not defined for $(typeof(thg))")
nthings(asm::AbstractAssemblage) = nthings(things(asm))
nthings(asm::AbstractAssemblage, args...) = nthings(things(asm), args...)

"""
    thingnames(thg)

Return the name of each thing, in the order they appear as rows of
occurrences().
"""
thingnames(thg::AbstractThings)::AbstractVector{<:String} = error("function not defined for $(typeof(thg))")
thingnames(asm::AbstractAssemblage) = thingnames(things(asm))
function thingnames(asm::AbstractAssemblage, args...)
    return thingnames(things(asm), args...)
end

"""
    occurring(asm)
    occurring(asm, place)

Return the things found anywhere at all, or those present in one place — the
species list of the whole assemblage, or of that one site.
"""
occurring(asm::AbstractAssemblage) = occurring(occurrences(asm))
function occurring(asm::AbstractAssemblage, idx)
    return occurring(occurrences(asm), asindices(idx, placenames(asm)))
end
occurring(a::AbstractMatrix) = nzrows(a)
occurring(a::AbstractMatrix, idx) = findall(!iszero, a[:, idx])
occurring(a::AbstractMatrix, idx::AbstractVector) = nzrows(a[:, idx])

"""
    occupied(asm)
    occupied(asm, thing)

Return the places holding anything at all, or those where one thing is found —
that species' distribution across the assemblage.
"""
occupied(asm::AbstractAssemblage) = occupied(occurrences(asm))
function occupied(asm::AbstractAssemblage, idx)
    return occupied(occurrences(asm), asindices(idx, thingnames(asm)))
end
occupied(a::AbstractMatrix) = nzcols(a)
occupied(a::AbstractMatrix, idx) = findall(!iszero, a[idx, :])
occupied(a::AbstractMatrix, idx::AbstractVector) = nzcols(a[idx, :])

"""
    noccurring(asm)
    noccurring(asm, place)

Return how many things are found anywhere at all, or how many in one place.
"""
noccurring(x) = length(occurring(x))
noccurring(x, idx) = length(occurring(x, idx))

"""
    noccupied(asm)
    noccupied(asm, thing)

Return how many places hold anything at all, or how many one thing occupies —
its range size.
"""
noccupied(x) = length(occupied(x))
noccupied(x, idx) = length(occupied(x, idx))

"""
    thingoccurrences(asm, thing)

Return one thing's record across every place — a species' abundances over all
of the sites.
"""
function thingoccurrences(asm::AbstractAssemblage, idx)
    return thingoccurrences(occurrences(asm), asindices(idx, thingnames(asm)))
end
thingoccurrences(mat::AbstractMatrix, idx) = view(mat, idx, :)

"""
    placeoccurrences(asm, place)

Return every thing's record in one place — the community found at that site.
"""
function placeoccurrences(asm::AbstractAssemblage, idx)
    return placeoccurrences(occurrences(asm), asindices(idx, placenames(asm)))
end
placeoccurrences(mat::AbstractMatrix, idx) = view(mat, :, idx) # make certain that the view implementation also takes thing or place names

"""
    richness(asm)

Return the number of distinct things in each place: species richness, site by
site.
"""
richness(asm::AbstractAssemblage) = richness(occurrences(asm))
richness(a::AbstractMatrix{Bool}) = collect(vec(colsum(a)))
richness(a::AbstractMatrix) = collect(vec(mapslices(numnonzero, a, dims = 1)))

"""
    occupancy(asm)

Return the number of places each thing is found in — its occupancy, or range
size.
"""
occupancy(asm::AbstractAssemblage) = occupancy(occurrences(asm))
occupancy(a::AbstractMatrix{Bool}) = collect(vec(rowsum(a)))
occupancy(a::AbstractMatrix) = collect(vec(mapslices(numnonzero, a, dims = 2)))

"""
    nrecords(asm)

Return the total number of thing-in-place records, being the non-empty entries
of the community matrix.
"""
nrecords(asm::AbstractAssemblage) = nrecords(occurrences(asm))
nrecords(a::AbstractMatrix) = numnonzero(a)

"""
    cooccurring(asm, things...)

Return which places hold every one of the given things at once.
"""
cooccurring(asm, inds...) = cooccurring(asm, [inds...])
function cooccurring(asm, inds::AbstractVector)
    sub = view(asm, species = inds)
    return richness(sub) .== nthings(sub)
end

# TODO:
# accessing cache

# Methods for AbstractPlaces
"""
    getcoords(plc::AbstractPlaces)

Return the location data saying where the places are, or the places themselves
where they carry no geography at all.
"""
getcoords(plc::AbstractPlaces{Nothing}) = plc # Pure places generate their own fake location data
function getcoords(plc::AbstractPlaces{<:AbstractLocationData})
    return error("function not defined for $(typeof(plc))")
end

"""
    coordinates(plc)
    coordinates(asm)

Return the coordinates of the places, as their location data reports them; an
assemblage answers for its places.
"""
function coordinates(plc::AbstractPlaces)
    return error("function not defined for $(typeof(plc))")
end
coordinates(asm::AbstractAssemblage) = coordinates(places(asm))

# Methods for AbstractLocationData
"""
    coordinateorder(loc)

Return the order in which `loc` reports its two coordinate columns from
indices() and coordinates(), defaulting to XThenY() where a type says
nothing; places and assemblages answer for the location data they hold.
"""
coordinateorder(::AbstractLocationData) = XThenY()
function coordinateorder(plc::AbstractPlaces{<:AbstractLocationData})
    return coordinateorder(getcoords(plc))
end
coordinateorder(asm::AbstractAssemblage) = coordinateorder(places(asm))

# Put the two columns of a location data matrix into the wanted order. Two
# methods rather than a branch, so the choice is settled when the code is
# compiled rather than retaken per call; and column selection rather than
# arithmetic, so that coordinates carrying units pass through untouched.
_incolumnorder(cols, ::O, ::O) where {O <: AbstractCoordinateOrder} = cols
function _incolumnorder(cols, ::AbstractCoordinateOrder,
                        ::AbstractCoordinateOrder)
    return cols[:, [2, 1]]
end

# Methods for AbstractGridded — the index contract, which every kind of grid
# answers whatever its spacing

# A gridded question has the same answer whether it is put to the grid, to
# places holding one, or to an assemblage of those places, so the derived
# methods below are written once over _AnyGridded rather than once per host,
# and _gridded takes any of the three to the grid the answer comes from. The
# assemblage alias names its places parameter so that an assemblage with no
# location data is excluded by the signature rather than by failing later.
#
# Arities here are always written out, never gathered into an args... method.
# A method taking Vararg{Any} on one of these types is ambiguous with every
# multi-argument method of the same generic, which is how the need for this
# section was found: a downstream package forwarding that way lost xmax(),
# xrange() and the anchor forms on exactly the types its users hold.
const _GriddedAssemblage = AbstractAssemblage{<:Real, <:AbstractThings,
                                              <:AbstractPlaces{<:AbstractGridded}}
const _GriddedHolder = Union{AbstractPlaces{<:AbstractGridded},
                             _GriddedAssemblage}
const _AnyGridded = Union{AbstractGridded, _GriddedHolder}

# The grid behind x, which is x itself when x is one.
_gridded(grd::AbstractGridded) = grd
_gridded(plc::AbstractPlaces{<:AbstractGridded}) = getcoords(plc)
_gridded(asm::_GriddedAssemblage) = _gridded(places(asm))

"""
    xcells(grd)

Return how many cells the grid spans along x. Places holding a grid, and
assemblages of them, answer for it.
"""
xcells(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    ycells(grd)

Return how many cells the grid spans along y. Places holding a grid, and
assemblages of them, answer for it.
"""
ycells(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    xmin(grd)
    xmin(grd, anchor)

Return the coordinate of the first cell along x, referring to the requested
AbstractCellAnchor, or to whichever cellanchor() declares if none is given.
Places holding a grid, and assemblages of them, answer for it.
"""
xmin(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
function xmin(x::_AnyGridded, anchor::AbstractCellAnchor)
    return first(xrange(x, anchor))
end

"""
    ymin(grd)
    ymin(grd, anchor)

Return the coordinate of the first cell along y, referring to the requested
AbstractCellAnchor, or to whichever cellanchor() declares if none is given.
Places holding a grid, and assemblages of them, answer for it.
"""
ymin(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
function ymin(x::_AnyGridded, anchor::AbstractCellAnchor)
    return first(yrange(x, anchor))
end

"""
    indices(grd)

Return the two grid indices of the cell each place falls in, one row per
place, in whichever order coordinateorder() declares. Places holding a grid,
and assemblages of them, answer for it.
"""
indices(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    indices(grd, i)

Return column `i` of indices(grd), in the grid's own native order. Places
holding a grid, and assemblages of them, answer for it.
"""
function indices(grd::AbstractGridded, idx)
    return error("function not defined for $(typeof(grd))")
end

"""
    indices(grd, order[, anchor])
    indices(grd, i, order[, anchor])

Return the cell indices of `grd` with its two columns in the requested
AbstractCoordinateOrder, or column `i` of them; indices(grd, i) alone gives
that column in the grid's own native order, and an anchor, which cell
indices do not depend on, is accepted only for symmetry with coordinates().
Places holding a grid, and assemblages of them, answer for it.
"""
function indices(grd::AbstractGridded, order::AbstractCoordinateOrder,
                 ::AbstractCellAnchor = cellanchor(grd))
    return _incolumnorder(indices(grd), coordinateorder(grd), order)
end
function indices(grd::AbstractGridded, i, order::AbstractCoordinateOrder,
                 ::AbstractCellAnchor = cellanchor(grd))
    return _incolumnorder(indices(grd), coordinateorder(grd), order)[:, i]
end

"""
    coordinates(loc)

Return two columns of coordinates, one row per place, in whichever order
coordinateorder() declares — and, for a grid, at the anchor cellanchor() does.
"""
function coordinates(loc::AbstractLocationData)
    return error("function not defined for $(typeof(loc))")
end

"""
    coordinates(loc, order)

Return the coordinates of `loc` with its two columns in the requested
AbstractCoordinateOrder, whatever order it reports them in natively. Places
and assemblages answer for the location data they hold.
"""
function coordinates(loc::AbstractLocationData,
                     order::AbstractCoordinateOrder)
    return _incolumnorder(coordinates(loc), coordinateorder(loc), order)
end
function coordinates(plc::AbstractPlaces{<:AbstractLocationData},
                     order::AbstractCoordinateOrder)
    return _incolumnorder(coordinates(plc), coordinateorder(plc), order)
end
function coordinates(asm::AbstractAssemblage,
                     order::AbstractCoordinateOrder)
    return coordinates(places(asm), order)
end

"""
    coordinates(grd, order, anchor)

Return the coordinates of `grd` with its columns in the requested
AbstractCoordinateOrder referring to the requested AbstractCellAnchor.
Places holding a grid, and assemblages of them, answer for it.
"""
function coordinates(x::_AnyGridded, order::AbstractCoordinateOrder,
                     anchor::AbstractCellAnchor)
    xy = _incolumnorder(coordinates(x), coordinateorder(x), XThenY())
    return _incolumnorder(_atanchor(x, xy, cellanchor(x), anchor),
                          XThenY(), order)
end

"""
    cellsize(grd)

Return a cell's two side lengths — the grain at which the data was recorded
— in whichever order coordinateorder() declares; xcellsize() and ycellsize()
each name their own axis whatever that order is. Places holding a grid, and
assemblages of them, answer for it.
"""
function cellsize(x::_AnyGridded)
    return coordinateorder(x) == XThenY() ? (xcellsize(x), ycellsize(x)) :
           (ycellsize(x), xcellsize(x))
end

"""
    cells(grd)

Return the grid's two cell counts, in whichever order coordinateorder()
declares; xcells() and ycells() each name their own axis whatever that order
is. Places holding a grid, and assemblages of them, answer for it.
"""
function cells(x::_AnyGridded)
    return coordinateorder(x) == XThenY() ? (xcells(x), ycells(x)) :
           (ycells(x), xcells(x))
end

"""
    cellanchor(grd)

Return what a cell's reported coordinate refers to within that cell,
defaulting to CellCentre() where a grid says nothing. Places holding a grid,
and assemblages of them, answer for it.
"""
cellanchor(::AbstractGridded) = CellCentre()

# xrange() gives one coordinate per cell whatever the anchor, so it and the
# edges differ by exactly the final edge — and on a rectilinear grid that edge
# cannot be recovered from the cell coordinates, the last cell's width not being
# among their differences. A regular grid needs no method here: EcoBase derives
# its edges from the cell size.
"""
    xedges(grd)

Return the cell boundaries of `grd` along x: one more value than there are
cells, and so never what xrange() returns at any anchor. Places holding a
grid, and assemblages of them, answer for it.
"""
xedges(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    yedges(grd)

Return the cell boundaries of `grd` along y, as xedges() does along x.
Places holding a grid, and assemblages of them, answer for it.
"""
yedges(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    xrange(grd)
    xrange(grd, anchor)

Return one coordinate per cell along x, from the first cell to the last,
referring to the requested AbstractCellAnchor or to whichever cellanchor()
declares if none is given. Places holding a grid, and assemblages of them,
answer for it.
"""
function xrange(x::_AnyGridded, anchor::AbstractCellAnchor = cellanchor(x))
    return _atedges(xedges(x), anchor)
end

"""
    yrange(grd)
    yrange(grd, anchor)

Return one coordinate per cell along y, as xrange() does along x.
"""
function yrange(x::_AnyGridded, anchor::AbstractCellAnchor = cellanchor(x))
    return _atedges(yedges(x), anchor)
end

"""
    xmax(grd)
    xmax(grd, anchor)

Return the coordinate of the last cell along x, referring to the requested
AbstractCellAnchor, or to whichever cellanchor() declares if none is given.
Places holding a grid, and assemblages of them, answer for it.
"""
xmax(x::_AnyGridded) = last(xrange(x))
function xmax(x::_AnyGridded, anchor::AbstractCellAnchor)
    return last(xrange(x, anchor))
end

"""
    ymax(grd)
    ymax(grd, anchor)

Return the coordinate of the last cell along y, as xmax() does along x.
"""
ymax(x::_AnyGridded) = last(yrange(x))
function ymax(x::_AnyGridded, anchor::AbstractCellAnchor)
    return last(yrange(x, anchor))
end

# One coordinate per cell, taken from that cell's own pair of edges. This is
# the only route from a grid's geometry to its cell coordinates, so xrange,
# xmin(grd, anchor) and xmax(grd, anchor) all read the same edges rather than
# each rebuilding the geometry from xmin, xcellsize and xcells.
#
# The unanchored xmax and ymax deliberately do NOT go through it. They take
# the last of the grid's OWN xrange, so a grid answering from a lookup keeps
# its own values instead of a reconstruction of them - which is also what lets
# them work on a grid whose cells are not all one size, where xcellsize does
# not exist and the arithmetic they used to do could not be written.
_atedges(edges, ::CellCorner) = edges[1:(end - 1)]
_atedges(edges, ::CellCentre) = (edges[1:(end - 1)] .+ edges[2:end]) ./ 2

# A regular grid's edges are a range and so are its cell coordinates, and the
# generic method above would return a vector. Keeping the range preserves the
# step that callers index, plot and take differences of.
function _atedges(edges::AbstractRange, ::CellCentre)
    half = step(edges) / 2
    return (first(edges) + half):step(edges):(last(edges) - half)
end

# Move a grid's x-then-y coordinates from the anchor it reports them at to the
# one wanted. The equal-anchor case takes the whole matrix and comes first
# because it is the one that must not ask for cell widths: it is now the path
# every coordinates(grd, order) call takes, and a gridded type that is not a
# regular AbstractRegularGrid has no widths to give.
_atanchor(grd, xy, ::A, ::A) where {A <: AbstractCellAnchor} = xy
function _atanchor(grd, xy, from::AbstractCellAnchor, to::AbstractCellAnchor)
    return hcat(_shifted(xy[:, 1], _xwidths(grd), from, to),
                _shifted(xy[:, 2], _ywidths(grd), from, to))
end

# Half a cell along one axis, broadcast across every place from the grid's
# cell size.
_shifted(vals, width, ::CellCentre, ::CellCorner) = vals .- width ./ 2
_shifted(vals, width, ::CellCorner, ::CellCentre) = vals .+ width ./ 2

# Methods for AbstractRegularGrid — the regularly spaced case
"""
    xcellsize(grd)

Return the width of one cell — the grain, or spatial resolution, at which the
grid records its places along x.
"""
function xcellsize(grd::AbstractRegularGrid)
    return error("function not defined for $(typeof(grd))")
end

"""
    ycellsize(grd)

Return the height of one cell — the grain, or spatial resolution, at which the
grid records its places along y.
"""
function ycellsize(grd::AbstractRegularGrid)
    return error("function not defined for $(typeof(grd))")
end

# Every cell is the same size, so the edges follow from the first label, that
# size and the count, and the type need supply nothing.
function xedges(grd::AbstractRegularGrid)
    return _regularedges(xmin(grd), xcellsize(grd), xcells(grd),
                         cellanchor(grd))
end
function yedges(grd::AbstractRegularGrid)
    return _regularedges(ymin(grd), ycellsize(grd), ycells(grd),
                         cellanchor(grd))
end

function _regularedges(lo, size, n, anchor::AbstractCellAnchor)
    return range(_firstedge(lo, size, anchor), step = size, length = n + 1)
end

# Where the first edge sits relative to the first cell's own label.
_firstedge(lo, size, ::CellCentre) = lo - size / 2
_firstedge(lo, size, ::CellCorner) = lo

# The width of the cell a place sits in, along one axis — constant here.
_xwidths(grd::AbstractRegularGrid) = xcellsize(grd)
_ywidths(grd::AbstractRegularGrid) = ycellsize(grd)

# What a holder cannot derive it hands to its grid. These are the primitives a
# gridded type answers for itself, plus the two private widths the anchor
# conversion needs; everything derived from them is written over _AnyGridded
# where it is defined, and so already answers for all three hosts.
#
# xrange and yrange are here although EcoBase can derive them, and must be: a
# grid may answer them from a lookup of its own that no derivation reproduces
# - SpatialEcology's RasterData does - and asking the grid is the only way to
# get that answer rather than a reconstruction of it.
for f in (:xcells, :ycells, :xmin, :ymin, :xcellsize, :ycellsize, :xrange,
          :yrange, :xedges, :yedges, :cellanchor, :indices, :_xwidths,
          :_ywidths)
    @eval $f(x::_GriddedHolder) = $f(_gridded(x))
end

# indices() is the one generic here taking an untyped second argument, so its
# further arities cannot be written over _AnyGridded the way the rest are:
# (AbstractGridded, Any) and (_AnyGridded, AbstractCoordinateOrder) leave
# neither method more specific. A holder gets its own instead, at each arity
# and never through args..., for the reason given where _AnyGridded is
# defined.
indices(x::_GriddedHolder, i) = indices(_gridded(x), i)
function indices(x::_GriddedHolder, order::AbstractCoordinateOrder,
                 anchor::AbstractCellAnchor = cellanchor(x))
    return indices(_gridded(x), order, anchor)
end
function indices(x::_GriddedHolder, i, order::AbstractCoordinateOrder,
                 anchor::AbstractCellAnchor = cellanchor(x))
    return indices(_gridded(x), i, order, anchor)
end

# Methods extending Base, both of them on assemblages. The import declares
# that intent where it happens, and puts show and view in EcoBase's own
# namespace for the downstream packages that import them from here; the
# qualified definitions below then say at each site which function is meant.
import Base: show, view

# An assemblage must supply a view that subsets it by thing, which is what
# cooccurring() compares a subset's richness against its number of things.
function Base.view(asm::AbstractAssemblage)
    return error("function not defined for $(typeof(asm))")
end

function Base.show(io::IO, asm::T) where {T <: AbstractAssemblage}
    tn = createsummaryline(thingnames(asm))
    pn = createsummaryline(placenames(asm))
    thing = titlecase(thingkind(asm))
    things = thingkindplural(asm)
    place = titlecase(placekind(asm))
    places = placekindplural(asm)
    println(io,
            """$T with $(nthings(asm)) $things in $(nplaces(asm)) $places

            $thing names:
            $(tn)

            $place names:
            $(pn)
            """)
    return nothing
end

# Helper functions. Every one of these works on plain arrays or strings rather
# than on any of EcoBase's own types, so they are gathered here rather than
# among the interface they serve. None is exported.

# Which rows — things — were recorded in at least one place.
nzrows(a::AbstractMatrix) = findall(vec(sum(a, dims = 2) .> 0))
# Which columns — places — hold at least one thing.
nzcols(a::AbstractMatrix) = findall(vec(sum(a, dims = 1) .> 0))
# How many entries record something present, rather than what they add up to.
numnonzero(a::AbstractArray) = sum(a .> 0)
# One total per place, summing over the things found there.
colsum(x) = sum(x, dims = 1)
# One total per thing, summing over the places it was found in.
rowsum(x) = sum(x, dims = 2)

# Fold a list of names into a single line for printing, eliding the middle of
# a long one as "a, b, c...y, z".
function createsummaryline(vec::AbstractVector{<:AbstractString})
    linefunc(vec) = mapreduce(x -> x * ", ", *, vec[1:(end - 1)]) * vec[end]
    length(vec) == 1 && return vec[1]
    length(vec) < 6 && return linefunc(vec)
    return linefunc(vec[1:3]) * "..." * linefunc(vec[(end - 1):end])
end
