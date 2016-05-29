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

```@docs
    clip
    offset
```
