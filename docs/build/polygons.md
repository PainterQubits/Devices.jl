
In this package, any polygon regardless of its concrete representation in memory should be a subtype of [`Devices.AbstractPolygon`](polygons.md#Devices.AbstractPolygon).

<a id='Devices.AbstractPolygon' href='#Devices.AbstractPolygon'>#</a>
**`Devices.AbstractPolygon`** &mdash; *Type*.



```
abstract AbstractPolygon{T}
```

Anything you could call a polygon regardless of the underlying representation. Currently only `Rectangle` or `Polygon` are concrete subtypes.


<a id='Rectangles-1'></a>

## Rectangles

<a id='Devices.Rectangles.Rectangle' href='#Devices.Rectangles.Rectangle'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Type*.



```
type Rectangle{T<:Real} <: AbstractPolygon{T}
    ll::Point{2,T}
    ur::Point{2,T}
    properties::Dict{Symbol, Any}
    Rectangle(ll,ur) = new(ll,ur,Dict{Symbol,Any}())
    Rectangle(ll,ur,props) = new(ll,ur,props)
end
```

A rectangle, defined by opposing lower-left and upper-right corner coordinates.


```
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}; kwargs...)
```

Convenience constructor for `Rectangle{T}` objects.


```
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}, dict)
```

Convenience constructor for `Rectangle{T}` objects.


```
Rectangle{T<:Real}(width::T, height::T; kwargs...)
```

Constructs `Rectangle{T}` objects by specifying the width and height rather than the lower-left and upper-right corners.

The rectangle will sit with the lower-left corner at the origin. With centered rectangles we would need to divide width and height by 2 to properly position. If we wanted an object of `Rectangle{Int}` type, this would not be possible if either `width` or `height` were odd numbers. This definition ensures type stability in the constructor.

<a id='Devices.Rectangles.Rectangle-Tuple{FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real}}' href='#Devices.Rectangles.Rectangle-Tuple{FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real}}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}; kwargs...)
```

Convenience constructor for `Rectangle{T}` objects.

<a id='Devices.Rectangles.Rectangle-Tuple{FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real},Any}' href='#Devices.Rectangles.Rectangle-Tuple{FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real},Any}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}, dict)
```

Convenience constructor for `Rectangle{T}` objects.

<a id='Devices.Rectangles.Rectangle-Tuple{T<:Real,T<:Real}' href='#Devices.Rectangles.Rectangle-Tuple{T<:Real,T<:Real}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle{T<:Real}(width::T, height::T; kwargs...)
```

Constructs `Rectangle{T}` objects by specifying the width and height rather than the lower-left and upper-right corners.

The rectangle will sit with the lower-left corner at the origin. With centered rectangles we would need to divide width and height by 2 to properly position. If we wanted an object of `Rectangle{Int}` type, this would not be possible if either `width` or `height` were odd numbers. This definition ensures type stability in the constructor.

<a id='Devices.bounds-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.bounds-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(r::Rectangle)
```

No-op (just returns `r`).


```
bounds(p0::AbstractPolygon, p::AbstractPolygon...)
```

Return a bounding `Rectangle` with no properties for several `AbstractPolygon` objects.

<a id='Devices.center-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.center-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.center`** &mdash; *Method*.



```
center(r::Rectangle)
```

Returns a Point corresponding to the center of the rectangle.

<a id='Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Rectangles.height`** &mdash; *Method*.



```
height(r::Rectangle)
```

Return the height of a rectangle.

<a id='Devices.Rectangles.isproper-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Rectangles.isproper-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Rectangles.isproper`** &mdash; *Method*.



```
isproper(r::Rectangle)
```

Returns `true` if the rectangle has a non-zero size and if the upper-right and lower-left corner coordinates `ur` and `ll` really are at the upper-right and lower-left. Otherwise, returns `false`.

<a id='Base.minimum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Base.minimum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Base.minimum`** &mdash; *Method*.



```
minimum(itr)
```

Returns the smallest element in a collection.


```
minimum(r::Rectangle)
```

Returns the lower-left corner of a rectangle (Point object).

<a id='Base.maximum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Base.maximum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Base.maximum`** &mdash; *Method*.



```
maximum(itr)
```

Returns the largest element in a collection.


```
maximum(r::Rectangle)
```

Returns the upper-right corner of a rectangle (Point object).

<a id='Devices.Polygons.points-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Polygons.points-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Polygons.points`** &mdash; *Method*.



```
points{T<:Real}(x::Rectangle{T})
```

Returns the array of `Point` objects defining the rectangle.

<a id='Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Rectangles.width`** &mdash; *Method*.



```
width(r::Rectangle)
```

Return the width of a rectangle.

<a id='Base.+-Tuple{Devices.Rectangles.Rectangle{T<:Real},FixedSizeArrays.Point{N,T}}' href='#Base.+-Tuple{Devices.Rectangles.Rectangle{T<:Real},FixedSizeArrays.Point{N,T}}'>#</a>
**`Base.+`** &mdash; *Method*.



```
+(r::Rectangle, p::Point)
```

Translate a rectangle by `p`.


<a id='Polygons-1'></a>

## Polygons

<a id='Devices.Polygons.Polygon' href='#Devices.Polygons.Polygon'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Type*.



```
type Polygon{T<:Real} <: AbstractPolygon{T}
    p::Array{Point{2,T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
end
```

Polygon defined by list of coordinates. The first point should not be repeated at the end (although this is true for the GDS format).


```
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.


```
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}, dict)
```

Convenience constructor for a `Polygon{T}` object.


```
Polygon{T<:Real}(p0::Point{2,T}, p1::Point{2,T}, p2::Point{2,T},
    p3::Point{2,T}...; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.

<a id='Devices.Polygons.Polygon-Tuple{AbstractArray{FixedSizeArrays.Point{2,T<:Real},1}}' href='#Devices.Polygons.Polygon-Tuple{AbstractArray{FixedSizeArrays.Point{2,T<:Real},1}}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.

<a id='Devices.Polygons.Polygon-Tuple{AbstractArray{FixedSizeArrays.Point{2,T<:Real},1},Any}' href='#Devices.Polygons.Polygon-Tuple{AbstractArray{FixedSizeArrays.Point{2,T<:Real},1},Any}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}, dict)
```

Convenience constructor for a `Polygon{T}` object.

<a id='Devices.Polygons.Polygon-Tuple{FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real},Vararg{FixedSizeArrays.Point{2,T<:Real}}}' href='#Devices.Polygons.Polygon-Tuple{FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real},FixedSizeArrays.Point{2,T<:Real},Vararg{FixedSizeArrays.Point{2,T<:Real}}}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon{T<:Real}(p0::Point{2,T}, p1::Point{2,T}, p2::Point{2,T},
    p3::Point{2,T}...; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.

<a id='Devices.bounds-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Devices.bounds-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(p::Polygon)
```

Return a bounding Rectangle with no properties for polygon `p`.


```
bounds(p0::AbstractPolygon, p::AbstractPolygon...)
```

Return a bounding `Rectangle` with no properties for several `AbstractPolygon` objects.

<a id='Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon{T},N}}' href='#Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon{T},N}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
```

Return a bounding `Rectangle` with no properties for an array `parr` of `AbstractPolygon` objects.

<a id='Devices.bounds-Tuple{Devices.AbstractPolygon{T},Vararg{Devices.AbstractPolygon{T}}}' href='#Devices.bounds-Tuple{Devices.AbstractPolygon{T},Vararg{Devices.AbstractPolygon{T}}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(p0::AbstractPolygon, p::AbstractPolygon...)
```

Return a bounding `Rectangle` with no properties for several `AbstractPolygon` objects.

<a id='Base.minimum-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Base.minimum-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Base.minimum`** &mdash; *Method*.



```
minimum(itr)
```

Returns the smallest element in a collection.


```
minimum(x::Polygon)
```

Return the lower-left-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.

<a id='Base.maximum-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Base.maximum-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Base.maximum`** &mdash; *Method*.



```
maximum(itr)
```

Returns the largest element in a collection.


```
maximum(x::Polygon)
```

Return the upper-right-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.

<a id='Devices.Polygons.points-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Devices.Polygons.points-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Devices.Polygons.points`** &mdash; *Method*.



```
points(x::Polygon)
```

Returns the array of `Point` objects defining the polygon.


<a id='Clipping-and-offsetting-1'></a>

## Clipping and offsetting

<a id='Devices.Polygons.clip' href='#Devices.Polygons.clip'>#</a>
**`Devices.Polygons.clip`** &mdash; *Function*.


<a id='Devices.Polygons.offset' href='#Devices.Polygons.offset'>#</a>
**`Devices.Polygons.offset`** &mdash; *Function*.


