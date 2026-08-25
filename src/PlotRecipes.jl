# SPDX-License-Identifier: MIT

function convert_to_image(var::AbstractVector, grd::AbstractGridded)
    # Rows are y and columns are x, so ask for those two counts by name.
    # cells() cannot serve here: it comes back in the grid's own declared
    # order, so reversing it only gives (y, x) for a grid that declares x
    # first.
    x = Matrix{Float64}(undef, ycells(grd), xcells(grd))
    fill!(x, NaN)
    ind = indices(grd, XThenY(), CellCentre())
    xind, yind = view(ind, :, 1), view(ind, :, 2)
    [x[yind[i], xind[i]] = val for (i, val) in enumerate(var)]
    return x
end

RecipesBase.@recipe function f(var::AbstractVector, grd::AbstractGridded)
    seriestype := :heatmap
    aspect_ratio --> :equal
    grid --> false
    # A heatmap given one coordinate per cell reads them as cell CENTRES
    return xrange(grd, CellCentre()), yrange(grd, CellCentre()),
           convert_to_image(var, grd)
end

RecipesBase.@recipe function f(var::AbstractVector, pnt::AbstractPoints)
    seriestype := :scatter
    aspect_ratio --> :equal
    grid --> false
    marker_z := var
    legend --> false
    colorbar --> true
    cd = coordinates(pnt, XThenY())
    return cd[:, 1], cd[:, 2]
end

RecipesBase.@recipe function f(asm::AbstractAssemblage; showempty = false)
    var = richness(asm)
    if !showempty
        var = [Float64(v) for v in var]
        (var[var .== 0] .= NaN)
    end
    return var, getcoords(places(asm))
end

RecipesBase.@recipe function f(var::AbstractVector, asm::AbstractAssemblage)
    return var, getcoords(places(asm))
end

RecipesBase.@recipe function f(g::Function, asm::AbstractAssemblage)
    return g(asm), getcoords(places(asm))
end
