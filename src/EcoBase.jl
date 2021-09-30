module EcoBase

import Base: show, view
import RecipesBase

include("DataTypes.jl")
include("Interface.jl")
include("PlotRecipes.jl")

export nthings, nplaces, occupancy, richness, nrecords, placenames, thingnames
export occurring, noccurring, occupied, noccupied, occurrences
export placeoccurrences, thingoccurrences, cooccurring, places, things
export asindices, indices, coordinates, xcells, ycells, cells, xmin, xmax, ymin, ymax
export xrange, yrange, xcellsize, ycellsize, cellsize, getcoords

end # module
