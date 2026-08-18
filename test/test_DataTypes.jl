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
# two columns are (x, y) — the order convert_to_image reads, since it takes
# indices(grd, 1) as the column index and indices(grd, 2) as the row.
function EcoBase.indices(grd::ToyGrid)
    return [
    repeat(1:(grd.nx), outer = grd.ny) repeat(1:(grd.ny),
                                              inner = grd.nx)]
end
EcoBase.indices(grd::ToyGrid, idx) = EcoBase.indices(grd)[:, idx]

# The points equivalent, holding the n × 2 coordinate matrix the scatter recipe
# reads columnwise.
struct ToyPoints <: EcoBase.AbstractPoints
    coords::Matrix{Float64}
end

EcoBase.coordinates(pnt::ToyPoints) = pnt.coords

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

@testset "Points interface" begin
    pnt = ToyPoints([21.5 -28.5; 22.5 -26.5; 23.5 -24.5])

    @test size(coordinates(pnt)) == (3, 2)
    # The scatter recipe reads column 1 as x and column 2 as y.
    @test coordinates(pnt)[:, 1] == [21.5, 22.5, 23.5]
    @test coordinates(pnt)[:, 2] == [-28.5, -26.5, -24.5]
end

end
