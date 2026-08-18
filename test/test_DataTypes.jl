# SPDX-License-Identifier: MIT

module TestDataTypes

using Test
using EcoBase

# EcoBase contributes abstractions and no concrete types, so its location data
# interface has nothing to be exercised through without one of these. ToyGrid
# stands in for the grids SpatialEcology and EcoSISTEM provide, implementing
# exactly the six primitives EcoBase asks of an AbstractGrid and leaving the
# derived functions (cellsize, cells, xmax, ymax, xrange, yrange) to EcoBase.
#
# It is deliberately NOT square: a grid whose x and y extents match cannot
# distinguish a result from its own transpose, so a square fixture would pass
# whether or not the two axes had been swapped.
struct ToyGrid <: EcoBase.AbstractGrid
    x0::Float64
    y0::Float64
    dx::Float64
    dy::Float64
    nx::Int
    ny::Int
end

EcoBase.xmin(grd::ToyGrid) = grd.x0
EcoBase.ymin(grd::ToyGrid) = grd.y0
EcoBase.xcellsize(grd::ToyGrid) = grd.dx
EcoBase.ycellsize(grd::ToyGrid) = grd.dy
EcoBase.xcells(grd::ToyGrid) = grd.nx
EcoBase.ycells(grd::ToyGrid) = grd.ny

# Every cell of a ToyGrid is a place, ordered with x varying fastest, and the
# two columns are (x, y) — which this grid does not declare, so it is read that
# way by default.
function EcoBase.indices(grd::ToyGrid)
    return [
    repeat(1:(grd.nx), outer = grd.ny) repeat(1:(grd.ny),
                                              inner = grd.nx)]
end
# ⚠️ idx MUST be typed. Left as plain `idx`, this method and EcoBase's own
# indices(::AbstractGrid, ::AbstractCoordinateOrder) are mutually ambiguous,
# and asking this grid for an order throws instead of answering. That is
# exactly the state SpatialEcology is in until it types its own selector, and
# ToyGridUntyped below pins the behaviour.
EcoBase.indices(grd::ToyGrid, idx::Integer) = EcoBase.indices(grd)[:, idx]

# The points equivalent, holding the n × 2 coordinate matrix the scatter recipe
# reads columnwise.
struct ToyPoints <: EcoBase.AbstractPoints
    coords::Matrix{Float64}
end

EcoBase.coordinates(pnt::ToyPoints) = pnt.coords

# The same grid reporting its index columns the other way round, and saying so.
# Everything EcoBase computes from it must come out identical to ToyGrid's —
# that equivalence is the entire purpose of coordinateorder, and it is what
# would have caught the transposed grid EcoSISTEM once shipped.
struct ToyGridYX <: EcoBase.AbstractGrid
    grd::ToyGrid
end

EcoBase.xmin(gyx::ToyGridYX) = xmin(gyx.grd)
EcoBase.ymin(gyx::ToyGridYX) = ymin(gyx.grd)
EcoBase.xcellsize(gyx::ToyGridYX) = xcellsize(gyx.grd)
EcoBase.ycellsize(gyx::ToyGridYX) = ycellsize(gyx.grd)
EcoBase.xcells(gyx::ToyGridYX) = xcells(gyx.grd)
EcoBase.ycells(gyx::ToyGridYX) = ycells(gyx.grd)

EcoBase.indices(gyx::ToyGridYX) = EcoBase.indices(gyx.grd)[:, [2, 1]]
EcoBase.indices(gyx::ToyGridYX, idx::Integer) = EcoBase.indices(gyx)[:, idx]
EcoBase.coordinateorder(::ToyGridYX) = EcoBase.YThenX()

# A grid that leaves its column selector untyped, as SpatialEcology's SEGrid
# still does. It exists to pin the one known limitation of asking for an order:
# see the test below.
struct ToyGridUntyped <: EcoBase.AbstractGrid
    grd::ToyGrid
end

EcoBase.xcells(u::ToyGridUntyped) = xcells(u.grd)
EcoBase.ycells(u::ToyGridUntyped) = ycells(u.grd)
EcoBase.indices(u::ToyGridUntyped) = EcoBase.indices(u.grd)
EcoBase.indices(u::ToyGridUntyped, idx) = EcoBase.indices(u)[:, idx]

@testset "Location data hierarchy" begin
    # The relations downstream packages rely on when they subtype EcoBase.
    @test EcoBase.AbstractPoints <: EcoBase.AbstractLocationData
    @test EcoBase.AbstractGrid <: EcoBase.AbstractLocationData
    @test ToyGrid <: EcoBase.AbstractGrid
    @test ToyPoints <: EcoBase.AbstractPoints

    # AbstractPlaces is parameterised by location data, and Nothing means a
    # place with no spatial component at all - the branch Microbiome pins.
    @test EcoBase.AbstractPlaces{Nothing} <: EcoBase.AbstractPlaces
    @test EcoBase.AbstractPlaces{ToyGrid} <: EcoBase.AbstractPlaces
end

@testset "Grid interface derived from the six primitives" begin
    grd = ToyGrid(21.5, -28.5, 1.0, 2.0, 5, 4)

    @test xmin(grd) == 21.5
    @test ymin(grd) == -28.5
    @test xcellsize(grd) == 1.0
    @test ycellsize(grd) == 2.0
    @test xcells(grd) == 5
    @test ycells(grd) == 4

    # Derived by EcoBase itself, not supplied above.
    @test cellsize(grd) == (1.0, 2.0)
    @test cells(grd) == (5, 4)
    @test xmax(grd) == 25.5
    @test ymax(grd) == -22.5
    @test xrange(grd) == 21.5:1.0:25.5
    @test yrange(grd) == -28.5:2.0:-22.5

    # xrange and yrange return ONE COORDINATE PER CELL, not cell edges. This is
    # the invariant that keeps a single meaning across every kind of grid, so
    # anything returning n + 1 here would be a change in what the name promises.
    @test length(xrange(grd)) == xcells(grd)
    @test length(yrange(grd)) == ycells(grd)
end

@testset "convert_to_image" begin
    grd = ToyGrid(21.5, -28.5, 1.0, 2.0, 5, 4)
    img = EcoBase.convert_to_image(collect(1.0:20.0), grd)

    # Matrices are drawn from the upper left, so the image is (y, x) - the
    # reverse of cells(grd), which is (x, y). Asserting the shape on a
    # non-square grid is what catches a transpose.
    @test size(img) == (4, 5)
    @test size(img) == reverse(cells(grd))

    # Values land where indices() says, with x varying fastest.
    @test img[1, 1] == 1.0
    @test img[1, 2] == 2.0
    @test img[2, 1] == 6.0
    @test img[4, 5] == 20.0

    # Every cell of a ToyGrid is a place, so nothing is left unfilled. The NaN
    # pre-fill matters for grids whose places do not cover every cell.
    @test !any(isnan, img)
end

@testset "coordinateorder" begin
    grd = ToyGrid(21.5, -28.5, 1.0, 2.0, 5, 4)
    gyx = ToyGridYX(grd)
    pnt = ToyPoints([21.5 -28.5; 22.5 -26.5; 23.5 -24.5])

    # Location data that declares nothing is read x first, points included.
    @test coordinateorder(grd) === EcoBase.XThenY()
    @test coordinateorder(pnt) === EcoBase.XThenY()
    @test coordinateorder(gyx) === EcoBase.YThenX()

    # Asked for a particular order, the accessors deliver it whatever the
    # native order is - the caller never slices, and never has to know. The
    # two grids disagree natively, and agree once both are asked for x first.
    xy, yx = EcoBase.XThenY(), EcoBase.YThenX()

    @test indices(grd, xy) == indices(gyx, xy)
    @test indices(grd, yx) == indices(gyx, yx)
    @test indices(grd, xy) != indices(grd, yx)

    # Column i of a requested order, which is what the recipes actually take.
    @test indices(grd, 1, xy) == indices(gyx, 1, xy)
    @test indices(grd, 2, xy) == indices(gyx, 2, xy)
    @test indices(grd, 1, yx) == indices(grd, 2, xy)

    # Points have coordinates but no indices, and answer the same way.
    @test coordinates(pnt, xy) == coordinates(pnt)
    @test coordinates(pnt, yx) == coordinates(pnt)[:, [2, 1]]

    # ⚠️ The one known limitation, pinned rather than hidden. A grid whose own
    # indices(grd, idx) leaves idx untyped makes the two-argument ordered form
    # ambiguous, because neither method is more specific than the other. The
    # fix belongs in the grid - type the selector - and until SpatialEcology
    # does that, its grids cannot be asked for an order this way.
    untyped = ToyGridUntyped(grd)
    @test_throws MethodError indices(untyped, xy)

    # The three-argument form is unaffected, which is why EcoBase's own
    # plotting does not depend on downstream signatures being tightened.
    @test indices(untyped, 1, xy) == indices(grd, 1, xy)
    @test EcoBase.convert_to_image(collect(1.0:20.0), untyped) ==
          EcoBase.convert_to_image(collect(1.0:20.0), grd)

    # The two grids really do report their columns the other way round ...
    @test EcoBase.indices(gyx) == EcoBase.indices(grd)[:, [2, 1]]
    @test EcoBase.indices(gyx) != EcoBase.indices(grd)

    # ... and yet produce the identical image, which is the whole point.
    #
    # This asserts CONTENTS, not shape: a transposed image would differ in size
    # only because the grid is non-square, and neither EcoBase nor Plots raises
    # an error on a transpose - Plots checks the product of the dimensions, so
    # it cannot tell (4, 5) from (5, 4).
    var = collect(1.0:20.0)
    @test EcoBase.convert_to_image(var, gyx) ==
          EcoBase.convert_to_image(var, grd)
    @test size(EcoBase.convert_to_image(var, gyx)) == (4, 5)
end

@testset "Points interface" begin
    pnt = ToyPoints([21.5 -28.5; 22.5 -26.5; 23.5 -24.5])

    @test size(coordinates(pnt)) == (3, 2)
    # The scatter recipe reads column 1 as x and column 2 as y.
    @test coordinates(pnt)[:, 1] == [21.5, 22.5, 23.5]
    @test coordinates(pnt)[:, 2] == [-28.5, -26.5, -24.5]
end

end
