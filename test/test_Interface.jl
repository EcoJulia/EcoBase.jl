# SPDX-License-Identifier: MIT

module TestInterface

using Test
using EcoBase

# src/Interface.jl is almost all generic code computing over an assemblage's
# occurrence matrix, so it needs a concrete assemblage before any of it can be
# reached. These three types are the smallest thing satisfying EcoBase's
# interface.
struct ToyThings <: EcoBase.AbstractThings
    names::Vector{String}
end

EcoBase.nthings(thg::ToyThings) = length(thg.names)
EcoBase.thingnames(thg::ToyThings) = thg.names

# Nothing as the location data parameter means places with no spatial
# component at all, which is the branch getcoords answers with the places
# themselves rather than erroring.
struct ToyPlaces <: EcoBase.AbstractPlaces{Nothing}
    names::Vector{String}
end

EcoBase.nplaces(plc::ToyPlaces) = length(plc.names)
EcoBase.placenames(plc::ToyPlaces) = plc.names

struct ToyAssemblage{D <: Real} <:
       EcoBase.AbstractAssemblage{D, ToyThings, ToyPlaces}
    occurrences::Matrix{D}
    things::ToyThings
    places::ToyPlaces
end

EcoBase.occurrences(asm::ToyAssemblage) = asm.occurrences
EcoBase.things(asm::ToyAssemblage) = asm.things
EcoBase.places(asm::ToyAssemblage) = asm.places

# cooccurring() subsets an assemblage by thing before comparing richness
# against the number of things, so it needs a view that actually subsets.
function Base.view(asm::ToyAssemblage; species = :)
    return ToyAssemblage(asm.occurrences[species, :],
                         ToyThings(EcoBase.thingnames(asm)[species]),
                         asm.places)
end

# Deliberately 4 x 3 rather than square, and ragged, so that the per-thing and
# per-place answers differ from each other and a transposed result could not
# pass unnoticed.
const OCC = [1.0 0.0 3.0
             0.0 2.0 1.0
             4.0 5.0 0.0
             1.0 0.0 0.0]

function toyassemblage(occ = OCC)
    return ToyAssemblage(occ,
                         ToyThings(["Thing $i"
                                    for i in axes(occ, 1)]),
                         ToyPlaces(["Place $j"
                                    for j in axes(occ, 2)]))
end

@testset "Assemblage forwards to its things and places" begin
    asm = toyassemblage()

    @test nthings(asm) == 4
    @test nplaces(asm) == 3
    @test thingnames(asm) == ["Thing 1", "Thing 2", "Thing 3", "Thing 4"]
    @test placenames(asm) == ["Place 1", "Place 2", "Place 3"]
    @test occurrences(asm) == OCC
    @test things(asm) isa ToyThings
    @test places(asm) isa ToyPlaces

    # Places with no location data stand in for their own coordinates.
    @test getcoords(places(asm)) === places(asm)
end

@testset "Counting occurrences" begin
    asm = toyassemblage()

    # richness counts things per place, occupancy counts places per thing, so
    # the two marginals must agree with the total.
    @test richness(asm) == [3, 2, 2]
    @test occupancy(asm) == [2, 2, 2, 1]
    @test nrecords(asm) == 7
    @test sum(richness(asm)) == nrecords(asm)
    @test sum(occupancy(asm)) == nrecords(asm)

    # Every thing occurs somewhere and every place holds something here.
    @test occurring(asm) == [1, 2, 3, 4]
    @test occupied(asm) == [1, 2, 3]
    @test noccurring(asm) == 4
    @test noccupied(asm) == 3

    # Indexed by a single place, occurring() gives the things in it; indexed by
    # a single thing, occupied() gives the places holding it.
    @test occurring(asm, 2) == [2, 3]
    @test occupied(asm, 4) == [1]
    @test noccurring(asm, 2) == 2
    @test noccupied(asm, 4) == 1

    # And names index identically to positions.
    @test occurring(asm, "Place 2") == occurring(asm, 2)
    @test occupied(asm, "Thing 4") == occupied(asm, 4)
end

@testset "Boolean occurrences take a separate path" begin
    # richness and occupancy have Bool-specific methods that sum directly
    # rather than counting non-zeros, and must agree with the general ones.
    asm = toyassemblage(Matrix{Bool}(OCC .> 0))

    @test occurrences(asm) isa Matrix{Bool}
    @test richness(asm) == [3, 2, 2]
    @test occupancy(asm) == [2, 2, 2, 1]
    @test nrecords(asm) == 7
end

@testset "Slicing out a thing or a place" begin
    asm = toyassemblage()

    @test thingoccurrences(asm, 3) == [4.0, 5.0, 0.0]
    @test placeoccurrences(asm, 1) == [1.0, 0.0, 4.0, 1.0]
    @test thingoccurrences(asm, "Thing 3") == thingoccurrences(asm, 3)
    @test placeoccurrences(asm, "Place 1") == placeoccurrences(asm, 1)
end

@testset "cooccurring" begin
    asm = toyassemblage()

    # Things 1 and 2 are both present only in place 3.
    @test cooccurring(asm, [1, 2]) == [false, false, true]
    @test cooccurring(asm, 1, 2) == cooccurring(asm, [1, 2])

    # A single thing cooccurs with itself wherever it occurs at all.
    @test cooccurring(asm, [4]) == [true, false, false]
end

@testset "asindices" begin
    names = ["Thing 1", "Thing 2", "Thing 3"]

    # Integers and integer arrays pass straight through.
    @test asindices(2) == 2
    @test asindices([1, 3]) == [1, 3]

    # Booleans become the positions they select.
    @test asindices([true, false, true]) == [1, 3]
    @test asindices(Union{Missing, Bool}[true, missing, true]) == [1, 3]

    # Names are looked up against the corresponding name vector, and a single
    # name gives a single index rather than a one-element vector.
    @test asindices(["Thing 3", "Thing 1"], names) == [3, 1]
    @test asindices("Thing 2", names) == 2
    @test asindices(:var"Thing 2", names) == 2

    # A name that is not there is dropped rather than erroring.
    @test asindices(["Thing 3", "Nonesuch"], names) == [3]

    # With a second argument that is not names to match against, the first is
    # interpreted on its own.
    @test asindices(2, names) == 2
end

@testset "Reordering coordinate columns" begin
    # The reordering underneath coordinates(loc, order) and indices(grd,
    # order), tested directly on a matrix because that is all there is to it
    # without a location to look a native order up from; the public accessors
    # are exercised in test_DataTypes.jl, which has grids and points.
    cols = [1 2; 3 4; 5 6]

    # Asking for the order it is already in leaves it exactly alone ...
    @test EcoBase._incolumnorder(cols, EcoBase.XThenY(), EcoBase.XThenY()) ===
          cols
    @test EcoBase._incolumnorder(cols, EcoBase.YThenX(), EcoBase.YThenX()) ===
          cols

    # ... and asking for the other one swaps the two columns.
    @test EcoBase._incolumnorder(cols, EcoBase.XThenY(), EcoBase.YThenX()) ==
          [2 1; 4 3; 6 5]
    @test EcoBase._incolumnorder(cols, EcoBase.YThenX(), EcoBase.XThenY()) ==
          [2 1; 4 3; 6 5]

    # Swapping twice is the identity, whichever way round it started.
    for (from, to) in ((EcoBase.XThenY(), EcoBase.YThenX()),
                       (EcoBase.YThenX(), EcoBase.XThenY()))
        @test EcoBase._incolumnorder(EcoBase._incolumnorder(cols, from, to),
                                     to, from) == cols
    end
end

@testset "Printing" begin
    asm = toyassemblage()
    printed = sprint(show, asm)

    @test occursin("4 things in 3 places", printed)
    @test occursin("Thing 1", printed)
    @test occursin("Place 1", printed)

    # Long name lists are elided in the middle; short ones are not.
    @test EcoBase.createsummaryline(["only"]) == "only"
    @test EcoBase.createsummaryline(["a", "b"]) == "a, b"
    @test EcoBase.createsummaryline(["n$i" for i in 1:7]) ==
          "n1, n2, n3...n6, n7"
end

end
