In this package, any polygon regardless of its concrete representation in memory
should be a subtype of [`Devices.AbstractPolygon`](@ref).

```@docs
    Devices.AbstractPolygon
```
## Rectangles
```@docs
    Rectangle
    Rectangle(::Point, ::Point)
    Rectangle(::Any, ::Any)
    bounds(::Rectangle)
    center(::Rectangle)
    centered(::Rectangle)
    centered!(::Rectangle)
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
    Polygon{T}(::AbstractVector{Point{T}})
    Polygon(::Point, ::Point, ::Point, ::Point...)
    bounds(::Polygon)
    bounds{T<:Devices.AbstractPolygon}(::AbstractArray{T})
    bounds(::Devices.AbstractPolygon, ::Devices.AbstractPolygon...)
    minimum(::Polygon)
    maximum(::Polygon)
    points(::Polygon)
```
## Clipping and offsetting

```@docs
    clip
    offset
```
