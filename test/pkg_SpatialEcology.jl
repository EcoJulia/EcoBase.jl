# SPDX-License-Identifier: MIT

module PkgSpatialEcology

using Test
using SpatialEcology
using EcoBase

# SpatialEcology reaches EcoBase through the things / places / assemblage axis,
# with ComMatrix answering EcoBase's generics directly. It is also the package
# that relies on EcoBase's untyped grid derivations (cells, cellsize, xrange
# and friends) for types that are not grids, so it is the one most exposed to
# any change in how those are declared.
@testset "SpatialEcology-EcoBase interface" begin
    numspecies = 10
    numcommunities = 8
    manyweights = rand(numspecies, numcommunities)
    manyweights /= sum(manyweights)

    species = map(n -> "Species $n", 1:numspecies)
    communities = map(n -> "SC $n", 1:numcommunities)
    mc = ComMatrix(manyweights, species, communities)

    @test all(EcoBase.thingnames(mc) .== species)
    @test all(EcoBase.placenames(mc) .== communities)
    @test all(EcoBase.occurrences(mc) .≈ manyweights)
    @test all(EcoBase.richness(mc) .==
              repeat([numspecies], inner = numcommunities))
    @test all(EcoBase.occupancy(mc) .==
              repeat([numcommunities], inner = numspecies))
    fewerweights = deepcopy(manyweights)
    fewerweights[1, 1] = 0
    fewerweights /= sum(fewerweights)
    fmc = ComMatrix(fewerweights, species, communities)

    @test EcoBase.noccupied(fmc) == numcommunities
    @test EcoBase.noccurring(fmc) == numspecies
    @test EcoBase.noccupied(fmc, 1) == numcommunities - 1
    @test EcoBase.noccurring(fmc, 1) == numspecies - 1
    @test EcoBase.nthings(fmc) == numspecies
    @test EcoBase.nplaces(fmc) == numcommunities
end

@testset "SpatialEcology grids through EcoBase" begin
    # The subtype relations this work must preserve. SEGrid and GridTopology
    # reach EcoBase.AbstractGrid by different routes - one through SEGrid, one
    # directly - and both must survive anything inserted above AbstractGrid.
    @test SpatialEcology.SEGrid <: EcoBase.AbstractGrid
    @test SpatialEcology.GridTopology <: EcoBase.AbstractGrid
    @test SpatialEcology.GridData <: SpatialEcology.SEGrid
    @test SpatialEcology.SubGridData <: SpatialEcology.SEGrid

    # A real 3 x 2 grid, deliberately non-square so that a transposed answer
    # could not pass unnoticed.
    coords = [1.0 10.0; 2.0 10.0; 3.0 10.0;
              1.0 20.0; 2.0 20.0; 3.0 20.0]
    species = ["Species $i" for i in 1:4]
    sites = ["Site $j" for j in 1:6]
    occ = [1 0 1 1 0 1
           0 1 1 0 1 0
           1 1 0 1 1 1
           0 0 1 0 0 1]
    asm = Assemblage(occ, coords, sites, species,
                     cdtype = SpatialEcology.griddata)
    gd = getcoords(places(asm))

    @test gd isa SpatialEcology.SEGrid
    @test gd isa EcoBase.AbstractGrid

    # EcoBase's own derivations, computed from SpatialEcology's primitives -
    # the untyped fallbacks decision 4 deliberately left alone.
    @test cells(gd) == (3, 2)
    @test cellsize(gd) == (1.0, 10.0)
    @test xrange(gd) == 1.0:1.0:3.0
    @test yrange(gd) == 10.0:10.0:20.0
    @test length(xrange(gd)) == xcells(gd)
    @test length(yrange(gd)) == ycells(gd)

    # SpatialEcology declares no coordinate order, so it is read x first -
    # which is what it already did, so nothing about it changes.
    @test coordinateorder(gd) === EcoBase.XThenY()
    @test coordinates(gd, EcoBase.XThenY()) == coordinates(gd)
    @test coordinates(gd, EcoBase.YThenX()) == coordinates(gd)[:, [2, 1]]

    # The three-argument indices form works on a real SpatialEcology grid,
    # which is why EcoBase's own plotting can rely on it.
    @test indices(gd, 1, EcoBase.XThenY()) == indices(gd, 1)
    @test indices(gd, 2, EcoBase.XThenY()) == indices(gd, 2)
    @test indices(gd, 1, EcoBase.YThenX()) == indices(gd, 2)

    # ⚠️ The two-argument form, indices(gd, order), is AMBIGUOUS on this type:
    # SpatialEcology's own indices(g::SEGrid, idx) leaves idx untyped, so
    # neither method is more specific. It is deliberately NOT asserted here -
    # pinning another package's current signature would turn their one-word
    # fix (idx::Integer) into a failure in EcoBase's CI. The mechanism is
    # pinned instead by ToyGridUntyped in test_DataTypes.jl, which we own.
end

end
