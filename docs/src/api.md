

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

## Interfacing with gdspy

    {docs}
    Paths.distance
    Paths.extent
    Paths.paths
    Paths.width

## Index
    {index}
