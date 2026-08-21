# SPDX-License-Identifier: MIT

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
occurrences(asm::AbstractAssemblage)::AbstractMatrix = error("function not defined for $(typeof(asm))")
places(asm::AbstractAssemblage)::AbstractPlaces = error("function not defined for $(typeof(asm))")
things(asm::AbstractAssemblage)::AbstractThings = error("function not defined for $(typeof(asm))")

# for custom printing
thingkind(asm::AbstractAssemblage) = "thing"
placekind(asm::AbstractAssemblage) = "place"
thingkindplural(asm::AbstractAssemblage) = "$(thingkind(asm))s"
placekindplural(asm::AbstractAssemblage) = "$(placekind(asm))s"

nplaces(plc::AbstractPlaces)::Integer = error("function not defined for $(typeof(plc))")
nplaces(asm::AbstractAssemblage) = nplaces(places(asm))
nplaces(asm::AbstractAssemblage, args...) = nplaces(places(asm), args...)

placenames(plc::AbstractPlaces)::AbstractVector{<:String} = error("function not defined for $(typeof(plc))")
placenames(asm::AbstractAssemblage) = placenames(places(asm))
function placenames(asm::AbstractAssemblage, args...)
    return placenames(places(asm), args...)
end


nthings(thg::AbstractThings)::Integer = error("function not defined for $(typeof(thg))")
nthings(asm::AbstractAssemblage) = nthings(things(asm))
thingnames(thg::AbstractThings)::AbstractVector{<:String} = error("function not defined for $(typeof(thg))")
thingnames(asm::AbstractAssemblage) = thingnames(things(asm))
function thingnames(asm::AbstractAssemblage, args...)
    return thingnames(things(asm), args...)
end


occurring(asm::AbstractAssemblage) = occurring(occurrences(asm))
function occurring(asm::AbstractAssemblage, idx)
    return occurring(occurrences(asm), asindices(idx, placenames(asm)))
end
occurring(a::AbstractMatrix) = nzrows(a)

occupied(asm::AbstractAssemblage) = occupied(occurrences(asm))
function occupied(asm::AbstractAssemblage, idx)
    return occupied(occurrences(asm), asindices(idx, thingnames(asm)))
end
occupied(a::AbstractMatrix) = nzcols(a)
occupied(a::AbstractMatrix, idx) = findall(!iszero, a[idx, :])
occupied(a::AbstractMatrix, idx::AbstractVector) = nzcols(a[idx, :])

noccurring(x) = length(occurring(x))
noccurring(x, idx) = length(occurring(x, idx))
noccupied(x, idx) = length(occupied(x, idx))

function thingoccurrences(asm::AbstractAssemblage, idx)
    return thingoccurrences(occurrences(asm), asindices(idx, thingnames(asm)))
end
thingoccurrences(mat::AbstractMatrix, idx) = view(mat, idx, :)
function placeoccurrences(asm::AbstractAssemblage, idx)
    return placeoccurrences(occurrences(asm), asindices(idx, placenames(asm)))
end
placeoccurrences(mat::AbstractMatrix, idx) = view(mat, :, idx) # make certain that the view implementation also takes thing or place names

richness(asm::AbstractAssemblage) = richness(occurrences(asm))
richness(a::AbstractMatrix{Bool}) = collect(vec(colsum(a)))
richness(a::AbstractMatrix) = collect(vec(mapslices(nnz, a, dims = 1)))

occupancy(asm::AbstractAssemblage) = occupancy(occurrences(asm))
occupancy(a::AbstractMatrix{Bool}) = collect(vec(rowsum(a)))
occupancy(a::AbstractMatrix) = collect(vec(mapslices(nnz, a, dims = 2)))

nrecords(asm::AbstractAssemblage) = nrecords(occurrences(asm))
nrecords(a::AbstractMatrix) = nnz(a)

cooccurring(asm, inds...) = cooccurring(asm, [inds...])
function cooccurring(asm, inds::AbstractVector)
    sub = view(asm, species = inds)
    return richness(sub) .== nthings(sub)
end

# TODO:
# accessing cache

# Methods for AbstractPlaces
getcoords(plc::AbstractPlaces{Nothing}) = plc # Pure places generate their own fake location data
function getcoords(plc::AbstractPlaces{<:AbstractLocationData})
    return error("function not defined for $(typeof(plc))")
end
function coordinates(plc::AbstractPlaces)
    return error("function not defined for $(typeof(plc))")
end

# Methods for AbstractLocationData
"""
    coordinateorder(loc)

Return the order in which `loc` reports its two coordinate columns from
indices() and coordinates(), as an AbstractCoordinateOrder.

Location data returns coordinates as a two-column matrix, and EcoBase does not
require x to come first: a type declares its own order by adding a method here,
and anything reading those columns asks rather than assumes. Defaults to
XThenY(), so a type that says nothing is read x first.

"""
coordinateorder(::AbstractLocationData) = XThenY()

"""
    coordinates(loc, order)

Return the coordinates of `loc` with its two columns in the requested
AbstractCoordinateOrder, whatever order `loc` reports them in natively.

Location data gives its coordinates in whichever order it declares through
coordinateorder(), which a caller generally neither knows nor cares about.
Asking for the order wanted leaves the reordering to EcoBase, the only party
that knows the native one, rather than making the caller take the result apart
to find out.

"""
function coordinates(loc::AbstractLocationData, want::AbstractCoordinateOrder)
    return _incolumnorder(coordinates(loc), coordinateorder(loc), want)
end

"""
    indices(grd, order)
    indices(grd, i, order)
    indices(grd, order, anchor)

Return the cell indices of `grd` with its two columns in the requested
AbstractCoordinateOrder, or column `i` of them.

The indices() counterpart of coordinates(loc, order). Note that the second
argument means different things by type: an AbstractCoordinateOrder asks for
the whole matrix reordered, while an integer asks for that one column in the
grid's own native order.

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
xcells(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
ycells(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
indices(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
function indices(grd::AbstractGridded, idx)
    return error("function not defined for $(typeof(grd))")
end

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

cellsize(grd) = xcellsize(grd), ycellsize(grd)

"""
    cellanchor(grd)

Return what a cell's reported coordinate refers to within that cell, as an
AbstractCellAnchor.

A grid labels each cell with a single coordinate, and EcoBase does not require
that to be the cell's centre: a type declares its own by adding a method here.
Defaults to CellCentre(), so a grid that says nothing is read as labelling its
cells by their centres. This governs every coordinate reported for the grid —
xrange(), coordinates(), and the edges derived from them — not just one.

"""
cellanchor(::AbstractGridded) = CellCentre()

"""
    xedges(grd)
    yedges(grd)

Return the cell boundaries of `grd` along x or y: one MORE value than there are
cells, since n cells have n + 1 edges between and around them.

This is what xrange() cannot be. xrange() gives one coordinate per cell
whatever the anchor, so the two differ by exactly the final edge — and on a
rectilinear grid that edge cannot be recovered from the cell coordinates, since
the last cell's width is not among their differences. A regular grid needs no
method here: EcoBase derives its edges from the cell size.

"""
xedges(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")
yedges(grd::AbstractGridded) = error("function not defined for $(typeof(grd))")

"""
    xrange(grd, anchor)
    yrange(grd, anchor)

Return one coordinate per cell along x or y, referring to the requested
AbstractCellAnchor rather than to whichever the grid itself declares.

"""
function xrange(grd::AbstractGridded, anchor::AbstractCellAnchor)
    return _atedges(xedges(grd), anchor)
end

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
xmin(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
ymin(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
xcellsize(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
ycellsize(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
xrange(grd) = xmin(grd):xcellsize(grd):xmax(grd) #includes intermediary points
yrange(grd) = ymin(grd):ycellsize(grd):ymax(grd)
xmax(grd) = xmin(grd) + xcellsize(grd) * (xcells(grd) - 1)
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
