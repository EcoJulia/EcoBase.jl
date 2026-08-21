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
richness(a::AbstractMatrix) = collect(vec(mapslices(nnz, a, dims = 1)))

"""
    occupancy(asm)

Return the number of places each thing is found in — its occupancy, or range
size.
"""
occupancy(asm::AbstractAssemblage) = occupancy(occurrences(asm))
occupancy(a::AbstractMatrix{Bool}) = collect(vec(rowsum(a)))
occupancy(a::AbstractMatrix) = collect(vec(mapslices(nnz, a, dims = 2)))

"""
    nrecords(asm)

Return the total number of thing-in-place records, being the non-empty entries
of the community matrix.
"""
nrecords(asm::AbstractAssemblage) = nrecords(occurrences(asm))
nrecords(a::AbstractMatrix) = nnz(a)

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
    getcoords(plc)

Return the location data saying where the places are, or the places themselves
where they carry no geography at all.
"""
getcoords(plc::AbstractPlaces{Nothing}) = plc # Pure places generate their own fake location data
function getcoords(plc::AbstractPlaces{<:AbstractLocationData})
    return error("function not defined for $(typeof(plc))")
end

"""
    coordinates(plc)

Return the coordinates of the places, as their location data reports them.
"""
function coordinates(plc::AbstractPlaces)
    return error("function not defined for $(typeof(plc))")
end

# Methods for AbstractLocationData
"""
    coordinateorder(loc)

Return the order in which `loc` reports its two coordinate columns from
indices() and coordinates(), defaulting to XThenY() where a type says nothing.
"""
coordinateorder(::AbstractLocationData) = XThenY()

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
AbstractCoordinateOrder, whatever order `loc` reports them in natively.
"""
function coordinates(loc::AbstractLocationData,
                     order::AbstractCoordinateOrder)
    return _incolumnorder(coordinates(loc), coordinateorder(loc), order)
end

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
"""
    xcells(grd)

Return how many cells the grid spans along x.
"""
xcells(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    ycells(grd)

Return how many cells the grid spans along y.
"""
ycells(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    indices(grd)

Return the two grid indices of the cell each place falls in, one row per
place, in whichever order coordinateorder() declares.
"""
indices(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    indices(grd, i)

Return column `i` of indices(grd), in the grid's own native order.
"""
function indices(grd::AbstractGridded, idx)
    return error("function not defined for $(typeof(grd))")
end

"""
    indices(grd, order)
    indices(grd, order, anchor)
    indices(grd, i, order)
    indices(grd, i, order, anchor)

Return the cell indices of `grd` with its two columns in the requested
AbstractCoordinateOrder, or column `i` of them; indices(grd, i) alone gives
that column in the grid's own native order, and an anchor, which cell indices
do not depend on, is accepted only for symmetry with coordinates().
"""
function indices(grd::AbstractGridded, order::AbstractCoordinateOrder)
    return _incolumnorder(indices(grd), coordinateorder(grd), order)
end
function indices(grd::AbstractGridded, i, order::AbstractCoordinateOrder)
    return _incolumnorder(indices(grd), coordinateorder(grd), order)[:, i]
end
# Deliberately NOT delegating to the forms above, which would inherit their
# ambiguity for exactly the grids these methods exist to serve.
function indices(grd::AbstractGridded, order::AbstractCoordinateOrder,
                 ::AbstractCellAnchor)
    return _incolumnorder(indices(grd), coordinateorder(grd), order)
end
function indices(grd::AbstractGridded, i, order::AbstractCoordinateOrder,
                 ::AbstractCellAnchor)
    return _incolumnorder(indices(grd), coordinateorder(grd), order)[:, i]
end

"""
    cellsize(grd)

Return a cell's width and height — the grain at which the data was recorded.
"""
cellsize(grd) = xcellsize(grd), ycellsize(grd)

"""
    cells(grd)

Return the grid's shape, as the number of cells along x and along y.
"""
cells(grd) = xcells(grd), ycells(grd)

"""
    cellanchor(grd)

Return what a cell's reported coordinate refers to within that cell,
defaulting to CellCentre() where a grid says nothing.
"""
cellanchor(::AbstractGridded) = CellCentre()

"""
    xedges(grd)

Return the cell boundaries of `grd` along x: one more value than there are
cells, and so never what xrange() returns at any anchor.
"""
# xrange() gives one coordinate per cell whatever the anchor, so it and the
# edges differ by exactly the final edge — and on a rectilinear grid that edge
# cannot be recovered from the cell coordinates, the last cell's width not being
# among their differences. A regular grid needs no method here: EcoBase derives
# its edges from the cell size.
xedges(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
"""
    yedges(grd)

Return the cell boundaries of `grd` along y, as xedges() does along x.
"""
yedges(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    xrange(grd, anchor)

Return one coordinate per cell along x, referring to the requested
AbstractCellAnchor rather than to whichever the grid itself declares.
"""
function xrange(grd::AbstractGridded, anchor::AbstractCellAnchor)
    return _atedges(xedges(grd), anchor)
end

"""
    yrange(grd, anchor)

Return one coordinate per cell along y, referring to the requested
AbstractCellAnchor rather than to whichever the grid itself declares.
"""
function yrange(grd::AbstractGridded, anchor::AbstractCellAnchor)
    return _atedges(yedges(grd), anchor)
end

# One coordinate per cell, taken from that cell's own pair of edges.
_atedges(edges, ::CellCorner) = edges[1:(end - 1)]
_atedges(edges, ::CellCentre) = (edges[1:(end - 1)] .+ edges[2:end]) ./ 2

"""
    coordinates(grd, anchor)
    coordinates(grd, order, anchor)

Return the coordinates of `grd` referring to the requested AbstractCellAnchor,
and with its columns in the requested AbstractCoordinateOrder if one is given.
"""
function coordinates(grd::AbstractGridded, anchor::AbstractCellAnchor)
    return coordinates(grd, coordinateorder(grd), anchor)
end
function coordinates(grd::AbstractGridded, order::AbstractCoordinateOrder,
                     anchor::AbstractCellAnchor)
    xy = coordinates(grd, XThenY())
    from = cellanchor(grd)
    xs = _atanchor(xy[:, 1], _xwidths(grd), from, anchor)
    ys = _atanchor(xy[:, 2], _ywidths(grd), from, anchor)
    return _incolumnorder(hcat(xs, ys), XThenY(), order)
end

# Move coordinates from the anchor they were reported at to the one wanted.
# The width is a scalar for a regular grid and one value per place for a
# rectilinear one, so this broadcasts over either.
_atanchor(vals, width, ::A, ::A) where {A <: AbstractCellAnchor} = vals
_atanchor(vals, width, ::CellCentre, ::CellCorner) = vals .- width ./ 2
_atanchor(vals, width, ::CellCorner, ::CellCentre) = vals .+ width ./ 2

# Methods for AbstractGrid — the regularly spaced case
"""
    xmin(grd)

Return the coordinate of the first cell along x, referring to wherever in the
cell cellanchor() says it does.
"""
xmin(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")

"""
    ymin(grd)

Return the coordinate of the first cell along y, referring to wherever in the
cell cellanchor() says it does.
"""
ymin(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")

"""
    xcellsize(grd)

Return the width of one cell — the grain, or spatial resolution, at which the
grid records its places along x.
"""
xcellsize(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")

"""
    ycellsize(grd)

Return the height of one cell — the grain, or spatial resolution, at which the
grid records its places along y.
"""
ycellsize(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")

"""
    xrange(grd)

Return one coordinate per cell along x, running from the first cell to the
last.
"""
xrange(grd) = xmin(grd):xcellsize(grd):xmax(grd) #includes intermediary points

"""
    yrange(grd)

Return one coordinate per cell along y, running from the first cell to the
last.
"""
yrange(grd) = ymin(grd):ycellsize(grd):ymax(grd)

"""
    xmax(grd)

Return the coordinate of the last cell along x.
"""
xmax(grd) = xmin(grd) + xcellsize(grd) * (xcells(grd) - 1)

"""
    ymax(grd)

Return the coordinate of the last cell along y.
"""
ymax(grd) = ymin(grd) + ycellsize(grd) * (ycells(grd) - 1)

# Every cell is the same size, so the edges follow from the first label, that
# size and the count, and the type need supply nothing.
function xedges(grd::AbstractGrid)
    return _regularedges(xmin(grd), xcellsize(grd), xcells(grd),
                         cellanchor(grd))
end
function yedges(grd::AbstractGrid)
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
_xwidths(grd::AbstractGrid) = xcellsize(grd)
_ywidths(grd::AbstractGrid) = ycellsize(grd)

# Methods for AbstractRectilinearGrid — cells vary, so everything derives from
# the edges rather than from a single cell size
#
# Note: xrange and yrange MUST be given here. Without them a rectilinear grid
# would inherit the untyped constant-step range above, which is wrong for it
# and wrong silently.
xrange(grd::AbstractRectilinearGrid) = xrange(grd, cellanchor(grd))
yrange(grd::AbstractRectilinearGrid) = yrange(grd, cellanchor(grd))
xmin(grd::AbstractRectilinearGrid) = first(xrange(grd))
ymin(grd::AbstractRectilinearGrid) = first(yrange(grd))
xmax(grd::AbstractRectilinearGrid) = last(xrange(grd))
ymax(grd::AbstractRectilinearGrid) = last(yrange(grd))

function xcellsize(grd::AbstractRectilinearGrid)
    return error("cells of a $(typeof(grd)) vary in width — use xedges()")
end
function ycellsize(grd::AbstractRectilinearGrid)
    return error("cells of a $(typeof(grd)) vary in height — use yedges()")
end

function _xwidths(grd::AbstractRectilinearGrid)
    return _widths(xedges(grd))[indices(grd, 1, XThenY())]
end
function _ywidths(grd::AbstractRectilinearGrid)
    return _widths(yedges(grd))[indices(grd, 2, XThenY())]
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
nnz(a::AbstractArray) = sum(a .> 0)
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

# Each cell's extent along one axis, from that axis's edges.
_widths(edges) = edges[2:end] .- edges[1:(end - 1)]
