# SPDX-License-Identifier: MIT

module PkgDiversity

using Test
using Diversity
using EcoBase

# Diversity subtypes EcoBase's things, places and assemblage abstractions, and
# reaches the generics through its own exported names rather than qualified
# ones - so this also checks that EcoBase's exports arrive intact through a
# package that re-exports them.
@testset "Diversity-EcoBase interface" begin
    numspecies = 10
    numcommunities = 8
    manyweights = rand(numspecies, numcommunities)
    manyweights /= sum(manyweights)

    species = map(n -> "Species $n", 1:numspecies)
    communities = map(n -> "SC $n", 1:numcommunities)
    ut = UniqueTypes(species)
    sc = Subcommunities(communities)
    mc = Metacommunity(manyweights, ut, sc)

    @test all(thingnames(mc) .== species)
    @test all(placenames(mc) .== communities)
    @test all(occurrences(mc) .≈ manyweights)
    @test all(richness(mc) .== repeat([numspecies], inner = numcommunities))
    @test all(occupancy(mc) .== repeat([numcommunities], inner = numspecies))
    fewerweights = deepcopy(manyweights)
    fewerweights[1, 1] = 0
    fewerweights /= sum(fewerweights)
    fmc = Metacommunity(fewerweights, ut, sc)

    @test noccupied(fmc) == numcommunities
    @test noccurring(fmc) == numspecies
    @test noccupied(fmc, 1) == numcommunities - 1
    @test noccurring(fmc, 1) == numspecies - 1
    @test nthings(fmc) == numspecies
    @test nplaces(fmc) == numcommunities
end

end
