

## Points

Points are implemented using the abstract type `FixedVectorNoTuple`
from [FixedSizeArrays.jl](https://github.com/SimonDanisch/FixedSizeArrays.jl).
This permits a fast, efficient representation of
coordinates in the plane, which would not be true using ordinary `Array` objects,
which can have variable length. Additionally, unlike `Tuple` objects, we can
add points together, simplifying many function definitions.

To interface with gdspy, we simply convert the `Point` object to a `Tuple` and
let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

    {docs}
    Points.Point
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
    launch!
    meander!
    straight!
    turn!

### Rendering

    {docs}
    preview
    render
    view

## Polygons

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
    offset

## Interfacing with gdspy

    {docs}
    Paths.distance
    Paths.extent
    Paths.paths
    Paths.width

## Index
    {index}
