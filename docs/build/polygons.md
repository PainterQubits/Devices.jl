
In this package, any polygon regardless of its concrete representation in memory should be a subtype of [`Devices.AbstractPolygon`](polygons.md#Devices.AbstractPolygon).

<a id='Devices.AbstractPolygon' href='#Devices.AbstractPolygon'>#</a>
**`Devices.AbstractPolygon`** &mdash; *Type*.



```
abstract AbstractPolygon{T}
```

Anything you could call a polygon regardless of the underlying representation. Currently only `Rectangle` or `Polygon` are concrete subtypes.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Devices.jl#L77-L84' class='documenter-source'>source</a><br>


<a id='Rectangles-1'></a>

## Rectangles

<a id='Devices.Rectangles.Rectangle' href='#Devices.Rectangles.Rectangle'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Type*.



```
type Rectangle{T} <: AbstractPolygon{T}
    ll::Point{T}
    ur::Point{T}
    properties::Dict{Symbol, Any}
    Rectangle(ll,ur) = new(ll,ur,Dict{Symbol,Any}())
    Rectangle(ll,ur,props) = new(ll,ur,props)
end
```

A rectangle, defined by opposing lower-left and upper-right corner coordinates.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L18-L30' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.Rectangle-Tuple{Devices.Points.Point,Devices.Points.Point}' href='#Devices.Rectangles.Rectangle-Tuple{Devices.Points.Point,Devices.Points.Point}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle(ll::Point, ur::Point; kwargs...)
```

Convenience constructor for `Rectangle` objects.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L45-L51' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.Rectangle-Tuple{Any,Any}' href='#Devices.Rectangles.Rectangle-Tuple{Any,Any}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle(width, height, kwargs...)
```

Constructs `Rectangle` objects by specifying the width and height rather than the lower-left and upper-right corners.

The rectangle will sit with the lower-left corner at the origin. With centered rectangles we would need to divide width zeand height by 2 to properly position. If we wanted an object of `Rectangle{Int}` type, this would not be possible if either `width` or `height` were odd numbers. This definition ensures type stability in the constructor.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L55-L68' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.bounds-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(r::Rectangle)
```

No-op (just returns `r`).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L112-L118' class='documenter-source'>source</a><br>

<a id='Devices.center-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.center-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.center`** &mdash; *Method*.



```
center(r::Rectangle)
```

Returns a Point corresponding to the center of the rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L121-L127' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.Rectangles.height`** &mdash; *Method*.



```
height(r::Rectangle)
```

Return the height of a rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L92-L98' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.isproper-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.Rectangles.isproper-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.Rectangles.isproper`** &mdash; *Method*.



```
isproper(r::Rectangle)
```

Returns `true` if the rectangle has a non-zero size. Otherwise, returns `false`. Note that the upper-right and lower-left corners are enforced to be the `ur` and `ll` fields of a `Rectangle` by the inner constructor.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L101-L109' class='documenter-source'>source</a><br>

<a id='Base.minimum-Tuple{Devices.Rectangles.Rectangle}' href='#Base.minimum-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Base.minimum`** &mdash; *Method*.



```
minimum(r::Rectangle)
```

Returns the lower-left corner of a rectangle (Point object).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L145-L151' class='documenter-source'>source</a><br>

<a id='Base.maximum-Tuple{Devices.Rectangles.Rectangle}' href='#Base.maximum-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Base.maximum`** &mdash; *Method*.



```
maximum(r::Rectangle)
```

Returns the upper-right corner of a rectangle (Point object).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L154-L160' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.points-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Polygons.points-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Polygons.points`** &mdash; *Method*.



```
points{T}(x::Rectangle{T})
```

Returns the array of `Point` objects defining the rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L95-L101' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.Rectangles.width`** &mdash; *Method*.



```
width(r::Rectangle)
```

Return the width of a rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L83-L89' class='documenter-source'>source</a><br>

<a id='Base.:+-Tuple{Devices.Rectangles.Rectangle,Devices.Points.Point}' href='#Base.:+-Tuple{Devices.Rectangles.Rectangle,Devices.Points.Point}'>#</a>
**`Base.:+`** &mdash; *Method*.



```
+(r::Rectangle, p::Point)
```

Translate a rectangle by `p`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Rectangles.jl#L169-L175' class='documenter-source'>source</a><br>


<a id='Polygons-1'></a>

## Polygons

<a id='Devices.Polygons.Polygon' href='#Devices.Polygons.Polygon'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Type*.



```
type Polygon{T} <: AbstractPolygon{T}
    p::Array{Point{T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
end
```

Polygon defined by list of coordinates. The first point should not be repeated at the end (although this is true for the GDS format).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L31-L43' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.Polygon-Tuple{AbstractArray{Devices.Points.Point{T},1}}' href='#Devices.Polygons.Polygon-Tuple{AbstractArray{Devices.Points.Point{T},1}}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon{T}(parr::AbstractArray{Point{T},1}; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L62-L68' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.Polygon-Tuple{Devices.Points.Point,Devices.Points.Point,Devices.Points.Point,Vararg{Devices.Points.Point,N}}' href='#Devices.Polygons.Polygon-Tuple{Devices.Points.Point,Devices.Points.Point,Devices.Points.Point,Vararg{Devices.Points.Point,N}}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon(p0::Point, p1::Point, p2::Point, p3::Point...; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L52-L58' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Polygons.Polygon}' href='#Devices.bounds-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(p::Polygon)
```

Return a bounding Rectangle with no properties for polygon `p`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L171-L177' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon,N}}' href='#Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon,N}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
```

Return a bounding `Rectangle` with no properties for an array `parr` of `AbstractPolygon` objects.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L180-L187' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.AbstractPolygon,Vararg{Devices.AbstractPolygon,N}}' href='#Devices.bounds-Tuple{Devices.AbstractPolygon,Vararg{Devices.AbstractPolygon,N}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(p0::AbstractPolygon, p::AbstractPolygon...)
```

Return a bounding `Rectangle` with no properties for several `AbstractPolygon` objects.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L195-L202' class='documenter-source'>source</a><br>

<a id='Base.minimum-Tuple{Devices.Polygons.Polygon}' href='#Base.minimum-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Base.minimum`** &mdash; *Method*.



```
minimum(x::Polygon)
```

Return the lower-left-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L114-L121' class='documenter-source'>source</a><br>

<a id='Base.maximum-Tuple{Devices.Polygons.Polygon}' href='#Base.maximum-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Base.maximum`** &mdash; *Method*.



```
maximum(x::Polygon)
```

Return the upper-right-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L124-L131' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.points-Tuple{Devices.Polygons.Polygon}' href='#Devices.Polygons.points-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Devices.Polygons.points`** &mdash; *Method*.



```
points(x::Polygon)
```

Returns the array of `Point` objects defining the polygon.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Polygons.jl#L86-L92' class='documenter-source'>source</a><br>


<a id='Clipping-and-offsetting-1'></a>

## Clipping and offsetting


```
    clip
    offset
```

