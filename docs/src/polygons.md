```@meta
DocTestSetup = quote
    using Unitful, Devices
    using Unitful: °
end
```
## Abstract polygons

In this package, any polygon regardless of its concrete representation in memory
should be a subtype of [`Devices.AbstractPolygon`](@ref).

```@docs
    Devices.AbstractPolygon
```

## Affine transformations

The mechanism for affine transformations is largely provided by the
[`CoordinateTransformations.jl`](https://github.com/FugroRoames/CoordinateTransformations.jl)
package. For convenience, the documentation for `Translation` and `compose` is
reproduced below from that package. We implement our own 2D rotations.

An example of how to use affine transformations with polygons:

```jldoctest
julia> r = Rectangle(1,1)
Devices.Rectangles.Rectangle{Int64}((0,0),(1,1))

julia> trans = Translation(10,10)
Translation(10,10)

julia> trans = Rotation(90°) ∘ trans
AffineMap([0.0 -1.0; 1.0 0.0], [-10.0,10.0])

julia> trans(r)
Devices.Polygons.Polygon{Float64}(Devices.Points.Point{Float64}[(-10.0,10.0),(-10.0,11.0),(-11.0,11.0),(-11.0,10.0)])
```

```@docs
    compose
    Rotation
    Translation
    XReflection
    YReflection
```

## Clipping

```@docs
    clip
```

## Offsetting

```@docs
    offset
```

## Rectangle API

```@docs
    Rectangle
    Rectangle(::Point, ::Point)
    Rectangle(::Any, ::Any)
    bounds(::Rectangle)
    center(::Rectangle)
    centered(::Rectangle)
    height(::Rectangle)
    isproper(::Rectangle)
    minimum(::Rectangle)
    maximum(::Rectangle)
    points{T<:Real}(::Rectangle{T})
    width(::Rectangle)
    +(::Rectangle, ::Point)
```

### Rectangle styles

```@docs
    Rectangles.Plain
    Rectangles.Rounded
    Rectangles.Undercut
```

## Polygon API

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

### Polygon styles

```@docs
    Polygons.Plain
```
