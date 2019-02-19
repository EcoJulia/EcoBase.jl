using Compat

# Functions - most have to be implemented with the concrete type
occurrences(asm::AbstractAssemblage)::AbstractMatrix = error("function not defined for $(typeof(asm))")
view(asm::AbstractAssemblage) = error("function not defined for $(typeof(asm))")
places(asm::AbstractAssemblage)::AbstractPlaces = error("function not defined for $(typeof(asm))")
things(asm::AbstractAssemblage)::AbstractThings = error("function not defined for $(typeof(asm))")

nplaces(plc::AbstractPlaces)::Integer = error("function not defined for $(typeof(plc))")
nplaces(plc::AbstractAssemblage) = nplaces(places(plc))
placenames(plc::AbstractPlaces)::AbstractVector{<:String} = error("function not defined for $(typeof(plc))")
placenames(plc::AbstractAssemblage) = placenames(places(plc))

nthings(thg::AbstractThings)::Integer = error("function not defined for $(typeof(thg))")
nthings(asm::AbstractAssemblage) = nthings(things(asm))
thingnames(thg::AbstractThings)::AbstractVector{<:String} = error("function not defined for $(typeof(thg))")
thingnames(asm::AbstractAssemblage) = thingnames(things(asm))

nzrows(a::AbstractMatrix) = findall(vec(Compat.sum(a, dims = 2) .> 0))
nzcols(a::AbstractMatrix) = findall(vec(Compat.sum(a, dims = 1) .> 0))
nnz(a::AbstractArray) = Compat.sum(a .> 0)

occurring(asm::AbstractAssemblage) = occurring(occurrences(asm))
occurring(a::AbstractMatrix) = nzrows(a)
occurring(asm::AbstractAssemblage, idx) = occurring(occurrences(asm), idx)

occupied(asm::AbstractAssemblage) = occupied(occurrences(asm))
occupied(asm::AbstractAssemblage, idx) = occupied(occurrences(asm), idx)
occupied(a::AbstractMatrix) = nzcols(a)

if VERSION < v"0.7.0-"
    occupied(a::AbstractMatrix, idx) = collect(zip(findn(a[idx, :])))
    occurring(a::AbstractMatrix, idx) = collect(zip(findn(a[:, idx])))
else
    occupied(a::AbstractMatrix, idx) = findall(!iszero, a[idx, :])
    occurring(a::AbstractMatrix, idx) = findall(!iszero, a[:, idx])
end

noccurring(x) = length(occurring(x))
noccupied(x) = length(occupied(x))
noccurring(x, idx) = length(occurring(x, idx))
noccupied(x, idx) = length(occupied(x, idx))

thingoccurrences(asm::AbstractAssemblage, idx) = thingoccurrences(occurrences(asm), idx)
thingoccurrences(mat::AbstractMatrix, idx) = view(mat, idx, :)
placeoccurrences(asm::AbstractAssemblage, idx) = placeoccurrences(occurrences(asm), idx)
placeoccurrences(mat::AbstractMatrix, idx) = view(mat, :, idx) # make certain that the view implementation also takes thing or place names

richness(asm::AbstractAssemblage) = richness(occurrences(asm))
richness(a::AbstractMatrix{Bool}) = collect(vec(Compat.sum(a, dims = 1)))
richness(a::AbstractMatrix) = collect(vec(mapslices(nnz, a, dims = 1)))

occupancy(asm::AbstractAssemblage) = occupancy(occurrences(asm))
occupancy(a::AbstractMatrix{Bool}) = collect(vec(Compat.sum(a, dims=2)))
occupancy(a::AbstractMatrix) = collect(vec(mapslices(nnz, a, dims=2)))

nrecords(asm::AbstractAssemblage) = nrecords(occurrences(asm))
nrecords(a::AbstractMatrix) = nnz(a)

cooccurring(asm, inds...) = cooccurring(asm, [inds...])
function cooccurring(asm, inds::AbstractVector)
    sub = view(asm, species = inds)
    richness(sub) .== nthings(sub)
end

function createsummaryline(vec::AbstractVector{<:AbstractString})
    linefunc(vec) = mapreduce(x -> x * ", ", *, vec[1:(end-1)]) * vec[end]
    length(vec) == 1 && return vec[1]
    length(vec) < 6 && return linefunc(vec)
    linefunc(vec[1:3]) * "..." * linefunc(vec[(end-1):end])
end


function show(io::IO, asm::T) where T <: AbstractAssemblage
    tn = createsummaryline(thingnames(asm))
    pn = createsummaryline(placenames(asm))
    println(io,
    """$T with $(nthings(asm)) things in $(nplaces(asm)) places

    Thing names:
    $(tn)

    Place names:
    $(pn)
    """)
end

nplaces(asm::AbstractAssemblage, args...) = nplaces(places(asm), args...)
placenames(asm::AbstractAssemblage, args...) = placenames(places(asm), args...)
nthings(asm::AbstractAssemblage, args...) = nthings(things(asm), args...)
thingnames(asm::AbstractAssemblage, args...) = thingnames(things(asm), args...)


# TODO:
# accessing cache

# Methods for AbstractPlaces
getcoords(plc::AbstractPlaces{Nothing}) = plc # Pure places generate their own fake location data
getcoords(plc::AbstractPlaces{<: AbstractLocationData}) =
    error("function not defined for $(typeof(plc))")
coordinates(plc::AbstractPlaces) = error("function not defined for $(typeof(plc))")

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
indices(grd::AbstractGrid, idx) = error("function not defined for $(typeof(grd))")
coordinates(grd::AbstractGrid) = error("function not defined for $(typeof(grd))")
