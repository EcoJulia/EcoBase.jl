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

end
