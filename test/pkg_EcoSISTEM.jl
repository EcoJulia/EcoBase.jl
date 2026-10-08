# SPDX-License-Identifier: MIT

module PkgEcoSISTEM

using Test
using EcoSISTEM
using EcoBase
using Unitful: K, d, kJ, km, m

# EcoSISTEM reaches EcoBase through location data: its StudyGrid is a regular
# grid, and a GridHabitat is places holding one. It is the downstream that
# declares what the others leave to the defaults - cells labelled by their
# lower corner, columns y first - and the one whose coordinates carry units,
# so it shows whether EcoBase's derivations honour a declaration and work on
# quantities that are not plain numbers.
@testset "EcoSISTEM grids through EcoBase" begin
    @test EcoSISTEM.StudyGrid <: EcoBase.AbstractRegularGrid

    # 11 rows of y against 7 columns of x, deliberately non-square so that a
    # transposed answer could not pass unnoticed.
    ny, nx, cell = 11, 7, 1.0km
    area = StudyArea(extent = (ny * cell, nx * cell), cellsize = cell,
                     verbosity = :silent)
    hab = GridHabitat(regime = UniformSpec(298.0K, axis = Temperature),
                      supply = UniformSpec(10.0kJ / m^2 / d,
                                           axis = SolarRadiation),
                      area = area)
    grid = getcoords(hab)

    @test hab isa EcoBase.AbstractPlaces
    @test grid isa EcoSISTEM.StudyGrid

    # What the grid declares, which EcoBase would otherwise assume to be a
    # centre and x first.
    @test cellanchor(grid) === EcoBase.CellCorner()
    @test coordinateorder(grid) === EcoBase.YThenX()

    # EcoBase's own derivations, computed from EcoSISTEM's primitives. The
    # pairs come in the order the grid declares, y first.
    @test cells(grid) == (ny, nx)
    @test cellsize(grid) == (cell, cell)
    @test xmin(grid) == 0.0km
    @test xmax(grid) == (nx - 1) * cell
    @test ymax(grid) == (ny - 1) * cell
    @test xrange(grid) == (0:(nx - 1)) .* cell
    @test yrange(grid) == (0:(ny - 1)) .* cell

    # The edges start at the first label rather than half a cell below it,
    # because the label is a corner, and the centres sit half a cell above.
    @test length(EcoBase.xedges(grid)) == nx + 1
    @test first(EcoBase.xedges(grid)) == xmin(grid)
    @test last(EcoBase.xedges(grid)) == xmin(grid) + nx * cell
    @test xrange(grid, EcoBase.CellCorner()) == xrange(grid)
    @test xrange(grid, EcoBase.CellCentre()) == xrange(grid) .+ cell / 2

    # Column 1 is y and column 2 is x, and asking for x first swaps them.
    idx = indices(grid)
    coords = coordinates(grid)
    @test size(idx) == (ny * nx, 2)
    @test maximum(idx[:, 1]) == ny
    @test maximum(idx[:, 2]) == nx
    @test indices(grid, EcoBase.YThenX()) == idx
    @test indices(grid, EcoBase.XThenY()) == idx[:, [2, 1]]
    @test indices(grid, 1, EcoBase.XThenY()) == idx[:, 2]
    @test coordinates(grid, EcoBase.XThenY()) == coords[:, [2, 1]]
    @test coordinates(grid, EcoBase.YThenX(), EcoBase.CellCentre()) ==
          coords .+ cell / 2

    # EcoBase's image conversion reads the declared order, so cell i lands at
    # row idx[i, 1], column idx[i, 2] of a (y, x) image.
    img = EcoBase.convert_to_image(collect(1.0:(ny * nx)), grid)
    @test size(img) == (ny, nx)
    @test all(img[idx[i, 1], idx[i, 2]] == i for i in 1:(ny * nx))

    # The habitat is not a grid, and answers all of it for the grid it holds.
    for f in (xcells, ycells, xmin, ymin, xmax, ymax, xcellsize, ycellsize,
        xrange, yrange, cells, cellsize, indices, coordinates,
        EcoBase.xedges, EcoBase.yedges, cellanchor, coordinateorder)
        @test f(hab) == f(grid)
    end
    for f in (xmin, ymin, xmax, ymax, xrange, yrange),
        anchor in (EcoBase.CellCentre(), EcoBase.CellCorner())
        @test f(hab, anchor) == f(grid, anchor)
    end
    @test coordinates(hab, EcoBase.XThenY()) ==
          coordinates(grid, EcoBase.XThenY())
    @test indices(hab, 1, EcoBase.XThenY()) == indices(grid, 2)

    @test nplaces(hab) == ny * nx
    @test length(placenames(hab)) == nplaces(hab)
    @test allunique(placenames(hab))
end

# EcoBase owns these generics, so an ambiguity between its methods and a
# downstream's is EcoBase's to notice even when the fix belongs downstream.
# Only those involving a method of EcoBase's own are counted: EcoSISTEM
# extends other packages' generics too, and theirs are not ours to police.
@testset "No ambiguities between EcoBase and EcoSISTEM" begin
    ambiguities = filter(Test.detect_ambiguities(EcoSISTEM,
                                                 recursive = false)) do (a, b)
        return a.module === EcoBase || b.module === EcoBase
    end
    for (a, b) in ambiguities
        @warn "Ambiguous: $(a.sig)\n         vs $(b.sig)"
    end
    @test isempty(ambiguities)
end

end
