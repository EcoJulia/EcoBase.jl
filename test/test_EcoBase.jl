# SPDX-License-Identifier: MIT

module TestEcoBase

using Test
using EcoBase

# The types and convert_to_image are not exported, but are part of the API
@testset "Public names" begin
    for name in (:AbstractThings, :AbstractLocationData, :AbstractPlaces,
        :AbstractPoints, :AbstractAreas, :AbstractGridded,
        :AbstractRegularGrid, :AbstractAssemblage, :AbstractCellAnchor,
        :CellCentre, :CellCorner, :AbstractCoordinateOrder, :XThenY,
        :YThenX, :convert_to_image)
        @test isdefined(EcoBase, name)
        @test !Base.isexported(EcoBase, name)
        # Julia 1.10 has no public names, so @compat public drops them there
        @static if VERSION >= v"1.11"
            @test Base.ispublic(EcoBase, name)
        end
    end
    # the deprecated binding stays out of the API
    @static if VERSION >= v"1.11"
        @test !Base.ispublic(EcoBase, :AbstractGrid)
    end
end

end
