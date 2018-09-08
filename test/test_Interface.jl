module TestInterface
using Compat.Test

# Checking interface through Diversity.jl
using Diversity
using SpatialEcology
using EcoBase

@testset "SpatialEcology-Diversity interface" begin
    numspecies = 10
    numcommunities = 8
    manyweights = rand(numspecies, numcommunities)
    manyweights /= sum(manyweights)

    species = map(n -> "Species $n", 1:numspecies)
    communities = map(n -> "SC $n", 1:numcommunities)
    #ut = UniqueTypes(species)
    #sc = Subcommunities(communities)
    mc = ComMatrix(manyweights, specnames = species, sitenames = communities)

    @test all(EcoBase.thingnames(mc) .== species)
    @test all(EcoBase.placenames(mc) .== communities)
    @test all(EcoBase.occurrences(mc) .≈ manyweights)
    @test all(EcoBase.richness(mc) .== repeat([numspecies], inner=numcommunities))
    @test all(EcoBase.occupancy(mc) .== repeat([numcommunities], inner=numspecies))
    fewerweights = deepcopy(manyweights)
    fewerweights[1, 1] = 0
    fewerweights /= sum(fewerweights)
    fmc = ComMatrix(fewerweights, specnames = species, sitenames = communities)

    @test EcoBase.noccupied(fmc) == numcommunities
    @test EcoBase.noccurring(fmc) == numspecies
    @test EcoBase.noccupied(fmc, 1) == numcommunities - 1
    @test EcoBase.noccurring(fmc, 1) == numspecies - 1
    @test EcoBase.nthings(fmc) == numspecies
    @test EcoBase.nplaces(fmc) == numcommunities
end

@testset "EcoBase-Diversity interface" begin
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
    @test all(richness(mc) .== repeat([numspecies], inner=numcommunities))
    @test all(occupancy(mc) .== repeat([numcommunities], inner=numspecies))
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
