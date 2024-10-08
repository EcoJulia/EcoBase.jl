# SPDX-License-Identifier: MIT

function convert_to_image(var::AbstractVector, grd::AbstractGrid)
    x = Matrix{Float64}(undef, reverse(cells(grd))...)
    fill!(x, NaN)
    xind, yind = indices(grd, 1), indices(grd, 2) #since matrices are drawn from upper left corner
    [x[yind[i], xind[i]] = val for (i, val) in enumerate(var)]
    return x
end

RecipesBase.@recipe function f(var::AbstractVector, grd::AbstractGrid)
    seriestype := :heatmap
    aspect_ratio --> :equal
    grid --> false
    return xrange(grd), yrange(grd), convert_to_image(var, grd)
end

# RecipesBase.@recipe function f(sit::SiteFields) # not sure what SiteFields are
#     ones(nsites(sit)), sit
# end

RecipesBase.@recipe function f(var::AbstractVector, pnt::AbstractPoints)
    seriestype := :scatter
    aspect_ratio --> :equal
    grid --> false
    marker_z := var
    legend --> false
    colorbar --> true
    cd = coordinates(pnt)
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
