## Paths

    {docs}
    Paths.Path
    Paths.Path{T<:Real}(::Point{2,T}, ::Real, ::Paths.Style)
    Paths.Path{T<:Real}(::Tuple{T,T})
    Paths.Path{T<:Real}(::Tuple{T,T}, ::Real)
    Paths.pathlength(::Path)

## Segments

    {docs}
    Paths.Segment
    Paths.Straight
    Paths.Turn
    Paths.CompoundSegment

## Styles

    {docs}
    Paths.Style
    Paths.Trace
    Paths.CPW
    Paths.CompoundStyle
    Paths.DecoratedStyle

## Path interrogation

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

## Path building

    {docs}
    append!(::Path, ::Path)
    adjust!
    launch!
    meander!
    param
    simplify!
    straight!
    turn!

## Interfacing with gdspy

The Python package `gdspy` is used for rendering paths into polygons. Ultimately
we intend to remove this dependency.

    {docs}
    Paths.distance
    Paths.extent
    Paths.paths
    Paths.width
