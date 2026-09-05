# NEWS

- v0.1.8
  - Add coordinateorder() so location data declares whether its coordinate
    columns are x then y or y then x, rather than the order being assumed,
    and cellanchor() so a grid declares whether its coordinates are cell
    centres or corners
  - coordinates() and indices() now take the order wanted and cell anchor
    and return their columns appropriately with knowing the native order or
    slicing the result to find out
  - Add AbstractAreas and AbstractGridded between AbstractLocationData and
    AbstractGrid, for locations that cover an area and for those addressed by
    row and column
  - Add xedges()/yedges() giving the n + 1 cell boundaries, and
    xrange()/yrange()/coordinates() taking the anchor wanted
  - Lift the whole gridded interface onto places that hold gridded location
    data and onto assemblages of those places, so an assemblage answers
    xmin(), xmax(), xrange(), xedges(), cellanchor() and the anchor and order
    forms exactly as the grid it holds does
  - cells(), cellsize(), xmax() and ymax() are declared on gridded types and
    on the places and assemblages holding them, rather than being untyped.
    They were untyped only so that a type holding a grid without being one
    could reach them, which the lifting above now does properly
  - xrange()/yrange() are derived from xedges()/yedges() at the anchor the
    grid declares, rather than being rebuilt separately as a constant-step
    range, and xmax()/ymax() are the last of that range rather than
    arithmetic on xcellsize(). Both give the same answers on a regular grid,
    including the same range type, and both now work on a grid whose cells
    are not all one size
- v0.1.7
  - Add in metadata
- v0.1.6
  - Bugfixes
- v0.1.5
  - Bugfixes
- v0.1.4
  - Improve printing
  - Update GitHub workflows
  - Add Zenodo metadata
  - Fix testing and coverage checking to use GitHub workflows
- v0.1.3
  - CompatHelper fixes
- v0.1.2
  - CompatHelper fixes
  - Add TagBot
- v0.1.1
  - Bugfix for asindices()
- v0.1.0
  - Add CompatHelper
  - Move to Project.toml
