In this package, any polygon regardless of its concrete representation in memory
should be a subtype of [`Devices.AbstractPolygon`](@ref).

```@docs
Devices.AbstractPolygon
```

## Rectangles

```@docs
Rectangle
Rectangle{T<:Real}(::Point{2,T}, ::Point{2,T})
Rectangle{T<:Real}(::Point{2,T}, ::Point{2,T}, ::Any)
Rectangle{T<:Real}(::T, ::T)
bounds(::Rectangle)
center(::Rectangle)
height(::Rectangle)
isproper(::Rectangle)
minimum(::Rectangle)
maximum(::Rectangle)
points{T<:Real}(::Rectangle{T})
width(::Rectangle)
+(::Rectangle, ::Point)
```

## Polygons

```@docs
Polygon
Polygon{T<:Real}(::AbstractArray{Point{2,T},1})
Polygon{T<:Real}(::AbstractArray{Point{2,T},1}, ::Any)
Polygon{T<:Real}(::Point{2,T}, ::Point{2,T}, ::Point{2,T}, ::Point{2,T}...)
bounds(::Polygon)
bounds{T<:Devices.AbstractPolygon}(::AbstractArray{T})
bounds(::Devices.AbstractPolygon, ::Devices.AbstractPolygon...)
minimum(::Polygon)
maximum(::Polygon)
points(::Polygon)
```

## Clipping and offsetting

As of now this package's notion of polygons is that there are no "inner holes."
Probably it would be helpful if we expanded our definition.

For clipping polygons we use [GPC](http://www.cs.man.ac.uk/~toby/gpc/) to get
triangle strips which never have holes in them. These are then rendered as
polygons individually. An obvious downside is that subsequent offsetting will not
work as desired.

For offsetting polygons we use [Clipper](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm).
Clipper does not seem to support triangle strips so although the clipping is
probably superior we cannot use it easily for now.

```@docs
clip
offset
```
