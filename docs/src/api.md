## Points

Points are implemented using the abstract type `FixedVectorNoTuple`
from [FixedSizeArrays.jl](https://github.com/SimonDanisch/FixedSizeArrays.jl).
This permits a fast, efficient representation of
coordinates in the plane. Additionally, unlike `Tuple` objects, we can
add points together, simplifying many function definitions.

To interface with gdspy, we simply convert the `Point` object to a `Tuple` and
let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

    {docs}
    Points.getx
    Points.gety

## Paths

### Segments

    {docs}
    Paths.Segment
    Paths.Straight
    Paths.Turn
    Paths.CompoundSegment

### Styles

    {docs}
    Paths.Style
    Paths.Trace
    Paths.CPW
    Paths.CompoundStyle

### Path interrogation

    {docs}
    Paths.direction
    Paths.pathlength
    Paths.origin
    Paths.setorigin!
    Paths.α0
    Paths.setα0!
    Paths.lastpoint
    Paths.lastangle
    Paths.firststyle
    Paths.laststyle

### Path building

    {docs}
    adjust!
    launch!
    meander!
    param
    simplify!
    straight!
    turn!

### Interfacing with gdspy
    {docs}
    Paths.distance
    Paths.extent
    Paths.paths
    Paths.width

## Polygons

### Rectangles
    {docs}
    Rectangle
    bounds(::Rectangle)
    center(::Rectangle)
    height(::Rectangle)
    minimum(::Rectangle)
    maximum(::Rectangle)
    width(::Rectangle)

### Polygons

    {docs}
    Polygon
    bounds(::Polygon)
    bounds{T<:Devices.AbstractPolygon}(::AbstractArray{T})
    bounds(::Devices.AbstractPolygon, ::Devices.AbstractPolygon...)
    minimum(::Polygon)
    maximum(::Polygon)

### Clipping and offsetting

As of now this package's notion of polygons is that there are no "inner holes."
Probably it would be helpful if we expanded our definition.

For clipping polygons we use [GPC](http://www.cs.man.ac.uk/~toby/gpc/) to get
triangle strips which never have holes in them. These are then rendered as
polygons individually. An obvious downside is that subsequent offsetting will not
work as desired.

For offsetting polygons we use [Clipper](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm).
Clipper does not seem to support triangle strips so although the clipping is
probably superior we cannot use it easily for now.

    {docs}
    clip
    offset


## Cells

    {docs}
    Cell
    CellArray
    CellReference
    bounds(::Cell)
    bounds(::CellReference)
    traverse!
    order!

## Rendering

    {docs}
    render!

## Saving patterns

To save a pattern, make sure you are `using FileIO`.

    {docs}
    save(::File{format"GDS"}, ::Cell, ::Cell...)

## Index
    {index}
