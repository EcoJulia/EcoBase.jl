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
view(asm::AbstractAssemblage) = error("function not defined for $(typeof(asm))")
places(asm::AbstractAssemblage)::AbstractPlaces = error("function not defined for $(typeof(asm))")
things(asm::AbstractAssemblage)::AbstractThings = error("function not defined for $(typeof(asm))")

# for custom printing
thingkind(asm::AbstractAssemblage) = "thing"
placekind(asm::AbstractAssemblage) = "place"
thingkindplural(asm::AbstractAssemblage) = "$(thingkind(asm))s"
placekindplural(asm::AbstractAssemblage) = "$(placekind(asm))s"

nplaces(plc::AbstractPlaces)::Integer = error("function not defined for $(typeof(plc))")
nplaces(plc::AbstractAssemblage) = nplaces(places(plc))
placenames(plc::AbstractPlaces)::AbstractVector{<:String} = error("function not defined for $(typeof(plc))")
placenames(plc::AbstractAssemblage) = placenames(places(plc))

nthings(thg::AbstractThings)::Integer = error("function not defined for $(typeof(thg))")
nthings(asm::AbstractAssemblage) = nthings(things(asm))
thingnames(thg::AbstractThings)::AbstractVector{<:String} = error("function not defined for $(typeof(thg))")
thingnames(asm::AbstractAssemblage) = thingnames(things(asm))

nzrows(a::AbstractMatrix) = findall(vec(sum(a, dims = 2) .> 0))
nzcols(a::AbstractMatrix) = findall(vec(sum(a, dims = 1) .> 0))
nnz(a::AbstractArray) = sum(a .> 0)
colsum(x) = sum(x, dims = 1)
rowsum(x) = sum(x, dims = 2)

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
occurring(a::AbstractMatrix, idx) = findall(!iszero, a[:, idx])
occupied(a::AbstractMatrix, idx::AbstractVector) = nzcols(a[idx, :])
occurring(a::AbstractMatrix, idx::AbstractVector) = nzrows(a[:, idx])

noccurring(x) = length(occurring(x))
noccupied(x) = length(occupied(x))
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

function createsummaryline(vec::AbstractVector{<:AbstractString})
    linefunc(vec) = mapreduce(x -> x * ", ", *, vec[1:(end - 1)]) * vec[end]
    length(vec) == 1 && return vec[1]
    length(vec) < 6 && return linefunc(vec)
    return linefunc(vec[1:3]) * "..." * linefunc(vec[(end - 1):end])
end

function show(io::IO, asm::T) where {T <: AbstractAssemblage}
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

nplaces(asm::AbstractAssemblage, args...) = nplaces(places(asm), args...)
placenames(asm::AbstractAssemblage, args...) = placenames(places(asm), args...)
nthings(asm::AbstractAssemblage, args...) = nthings(things(asm), args...)
thingnames(asm::AbstractAssemblage, args...) = thingnames(things(asm), args...)

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

Return the cell indices of `grd` with its two columns in the requested
AbstractCoordinateOrder, or column `i` of them.

The indices() counterpart of coordinates(loc, order). ⚠️ Note that the second
argument means different things by type: an AbstractCoordinateOrder asks for
the whole matrix reordered, while an integer asks for that one column in the
grid's own native order.

"""
function indices(grd::AbstractGrid, want::AbstractCoordinateOrder)
    return _incolumnorder(indices(grd), coordinateorder(grd), want)
end
function indices(grd::AbstractGrid, i, want::AbstractCoordinateOrder)
    return _incolumnorder(indices(grd), coordinateorder(grd), want)[:, i]
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

# Methods for AbstractGrid
xmin(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
ymin(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
xcellsize(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
ycellsize(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
xcells(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
ycells(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
cellsize(grd) = xcellsize(grd), ycellsize(grd)
cells(grd) = xcells(grd), ycells(grd)
xrange(grd) = xmin(grd):xcellsize(grd):xmax(grd) #includes intermediary points
yrange(grd) = ymin(grd):ycellsize(grd):ymax(grd)
xmax(grd) = xmin(grd) + xcellsize(grd) * (xcells(grd) - 1)
ymax(grd) = ymin(grd) + ycellsize(grd) * (ycells(grd) - 1)

indices(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
function indices(grd::AbstractGrid, idx)
    return error("function not defined for $(typeof(grd))")
end
function coordinates(grd::AbstractGrid)
    return error("function not defined for $(typeof(grd))")
end
