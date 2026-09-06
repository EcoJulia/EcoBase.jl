# SPDX-License-Identifier: MIT

module EcoBase

import RecipesBase

include("DataTypes.jl")
include("Interface.jl")
include("PlotRecipes.jl")

export nthings, nplaces, occupancy, richness, nrecords, placenames, thingnames
export occurring, noccurring, occupied, noccupied, occurrences
export placeoccurrences, thingoccurrences, cooccurring, places, things
export asindices, indices, coordinates, xcells, ycells, cells, xmin, xmax, ymin,
       ymax
export xrange, yrange, xcellsize, ycellsize, cellsize, getcoords
export coordinateorder, cellanchor, xedges, yedges

@deprecate nnz numnonzero false

# AbstractGrid was too easily read as the whole gridded family once
# AbstractGridded was inserted above it, when it means only the regular case.
# The binding keeps working - a downstream still subtypes EcoBase.AbstractGrid
# and lands on the same type - so this warns rather than breaking. Not
# exported, as no EcoBase type is.
Base.@deprecate_binding AbstractGrid AbstractRegularGrid false

end # module
