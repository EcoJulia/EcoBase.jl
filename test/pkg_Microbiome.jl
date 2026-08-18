# SPDX-License-Identifier: MIT

module PkgMicrobiome

using Test
using EcoBase
using Microbiome

# Microbiome reaches EcoBase through the things / places / assemblage axis and
# never through location data: AbstractSample pins AbstractPlaces{Nothing}, the
# branch that says a place has no spatial component at all.
@testset "Microbiome-EcoBase interface" begin
    @test Microbiome.AbstractFeature <: EcoBase.AbstractThings
    @test Microbiome.AbstractSample <: EcoBase.AbstractPlaces{Nothing}
    @test Taxon <: EcoBase.AbstractThings
    @test MicrobiomeSample <: EcoBase.AbstractPlaces{Nothing}

    # Deliberately ragged, so that richness and occupancy differ per sample and
    # per feature rather than coming out uniform and proving nothing.
    mat = [1.0 0.0 3.0
           0.0 2.0 1.0
           4.0 5.0 0.0
           1.0 0.0 0.0]
    features = ["Species $i" for i in 1:4]
    samples = ["Sample $j" for j in 1:3]
    cp = CommunityProfile(mat, Taxon.(features), MicrobiomeSample.(samples))

    @test cp isa EcoBase.AbstractAssemblage

    # Microbiome's own names are const aliases of EcoBase's generics, so this
    # checks the values EcoBase computes, reached by Microbiome's spelling.
    @test nfeatures(cp) == 4
    @test nsamples(cp) == 3
    @test featurenames(cp) == features
    @test samplenames(cp) == samples
    @test abundances(cp) == mat

    # Derived entirely inside EcoBase from the occurrence matrix. The two
    # marginals must agree with the total, which is what pins all three.
    @test EcoBase.richness(cp) == [3, 2, 2]
    @test EcoBase.occupancy(cp) == [2, 2, 2, 1]
    @test EcoBase.nrecords(cp) == 7
    @test sum(EcoBase.richness(cp)) == EcoBase.nrecords(cp)
    @test sum(EcoBase.occupancy(cp)) == EcoBase.nrecords(cp)
end

end
