


<a id='Abstract-polygons-1'></a>

## Abstract polygons


In this package, any polygon regardless of its concrete representation in memory should be a subtype of [`Devices.AbstractPolygon`](polygons.md#Devices.AbstractPolygon).

<a id='Devices.AbstractPolygon' href='#Devices.AbstractPolygon'>#</a>
**`Devices.AbstractPolygon`** &mdash; *Type*.



```
abstract AbstractPolygon{T<:Coordinate}
```

Anything you could call a polygon regardless of the underlying representation. Currently only `Rectangle` or `Polygon` are concrete subtypes, but one could imagine further subtypes to represent specific shapes that appear in highly optimized pattern formats. Examples include the OASIS format (which has 25 implementations of trapezoids) or e-beam lithography pattern files like the Raith GPF format.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/Devices.jl#L56-L67' class='documenter-source'>source</a><br>


<a id='Affine-transformations-1'></a>

## Affine transformations


The mechanism for affine transformations is largely provided by the [`CoordinateTransformations.jl`](https://github.com/FugroRoames/CoordinateTransformations.jl) package. For convenience, the documentation for `Translation` and `compose` is reproduced below from that package. We implement our own 2D rotations.


An example of how to use affine transformations with polygons:


```jlcon
julia> r = Rectangle(1,1)
Devices.Rectangles.Rectangle{Int64}((0,0),(1,1),Dict{Symbol,Any}())

julia> trans = Translation(10,10)
Translation(10,10)

julia> trans = Rotation(90°) ∘ trans
AffineMap([6.12323e-17 -1.0; 1.0 6.12323e-17], [-10.0,10.0])

julia> trans(r)
Devices.Polygons.Polygon{Float64}(Devices.Points.Point{Float64}[(-10.0,10.0),(-10.0,11.0),(-11.0,11.0),(-11.0,10.0)],Dict{Symbol,Any}())
```

<a id='CoordinateTransformations.compose' href='#CoordinateTransformations.compose'>#</a>
**`CoordinateTransformations.compose`** &mdash; *Function*.



```
compose(trans1, trans2)
trans1 ∘ trans2
```

Take two transformations and create a new transformation that is equivalent to successively applying `trans2` to the coordinate, and then `trans1`. By default will create a `ComposedTransformation`, however this method can be overloaded for efficiency (e.g. two affine transformations naturally compose to a single affine transformation).


<a target='_blank' href='https://github.com/FugroRoames/CoordinateTransformations.jl/tree/529d9501be719490f54a503d8130e0ed10822cac/src/core.jl#L40-L49' class='documenter-source'>source</a><br>

<a id='Devices.Points.Rotation' href='#Devices.Points.Rotation'>#</a>
**`Devices.Points.Rotation`** &mdash; *Function*.



```
Rotation(Θ)
```

Construct a rotation about the origin. Units accepted (no units ⇒ radians).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/points.jl#L146-L152' class='documenter-source'>source</a><br>

<a id='CoordinateTransformations.Translation' href='#CoordinateTransformations.Translation'>#</a>
**`CoordinateTransformations.Translation`** &mdash; *Type*.



```
Translation(v) <: AbstractAffineMap
Translation(dx, dy)       (2D)
Translation(dx, dy, dz)   (3D)
```

Construct the `Translation` transformation for translating Cartesian points by an offset `v = (dx, dy, ...)`


<a target='_blank' href='https://github.com/FugroRoames/CoordinateTransformations.jl/tree/529d9501be719490f54a503d8130e0ed10822cac/src/affine.jl#L3-L10' class='documenter-source'>source</a><br>


<a id='Clipping-1'></a>

## Clipping

<a id='Devices.Polygons.clip' href='#Devices.Polygons.clip'>#</a>
**`Devices.Polygons.clip`** &mdash; *Function*.



```
clip{S<:Coordinate, T<:Coordinate}(op::Clipper.ClipType,
    s::AbstractPolygon{S}, c::AbstractPolygon{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
```

Using the [`Clipper`](http://www.angusj.com/delphi/clipper.php) library and the [`Clipper.jl`](https://github.com/Voxel8/Clipper.jl) wrapper, perform polygon clipping. The first argument must be one of the following types :

  * `Clipper.ClipTypeDifference`
  * `Clipper.ClipTypeIntersection`
  * `Clipper.ClipTypeUnion`
  * `Clipper.ClipTypeXor`

Note that these are types; you should not follow them with `()`. The second and third arguments are `AbstractPolygon` objects. Keyword arguments `pfs` and `pfc` specify polygon fill rules (see the [`Clipper` docs](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/PolyFillType.htm) for further information). These arguments may include:

  * `Clipper.PolyFillTypeNegative`
  * `Clipper.PolyFillTypePositive`
  * `Clipper.PolyFillTypeEvenOdd`
  * `Clipper.PolyFillTypeNonZero`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L224-L250' class='documenter-source'>source</a><br>


```
clip{S<:AbstractPolygon, T<:AbstractPolygon}(op::Clipper.ClipType,
    s::AbstractVector{S}, c::AbstractVector{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
```

Perform polygon clipping. The first argument must be as listed above. The second and third arguments are arrays (vectors) of [`AbstractPolygon`](polygons.md#Devices.AbstractPolygon)s. Keyword arguments are explained above.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L262-L273' class='documenter-source'>source</a><br>


```
clip{T<:Polygon}(op::Clipper.ClipType,
    s::AbstractVector{T}, c::AbstractVector{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
```

Perform polygon clipping. The first argument must be as listed above. The second and third arguments are identically-typed arrays (vectors) of [`Polygon{T}`](polygons.md#Devices.Polygons.Polygon) objects. Keyword arguments are explained above.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L285-L296' class='documenter-source'>source</a><br>


<a id='Offsetting-1'></a>

## Offsetting

<a id='Devices.Polygons.offset' href='#Devices.Polygons.offset'>#</a>
**`Devices.Polygons.offset`** &mdash; *Function*.



```
offset{S<:Coordinate}(s::AbstractPolygon{S}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
```

Using the [`Clipper`](http://www.angusj.com/delphi/clipper.php) library and the [`Clipper.jl`](https://github.com/Voxel8/Clipper.jl) wrapper, perform polygon offsetting.

The first argument should be an [`AbstractPolygon`](polygons.md#Devices.AbstractPolygon). The second argument is how much to offset the polygon. Keyword arguments include a [join type](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/JoinType.htm):

  * `Clipper.JoinTypeMiter`
  * `Clipper.JoinTypeRound`
  * `Clipper.JoinTypeSquare`

and also an [end type](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/EndType.htm):

  * `Clipper.EndTypeClosedPolygon`
  * `Clipper.EndTypeClosedLine`
  * `Clipper.EndTypeOpenSquare`
  * `Clipper.EndTypeOpenRound`
  * `Clipper.EndTypeOpenButt`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L351-L378' class='documenter-source'>source</a><br>


```
offset{S<:AbstractPolygon}(subject::AbstractVector{S}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
```

Perform polygon offsetting. The first argument is an array (vector) of [`AbstractPolygon`](polygons.md#Devices.AbstractPolygon)s. The second argument is how much to offset the polygon. Keyword arguments explained above.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L386-L396' class='documenter-source'>source</a><br>


```
offset{S<:Polygon}(s::AbstractVector{S}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
```

Perform polygon offsetting. The first argument is an array (vector) of [`Polygon`](polygons.md#Devices.Polygons.Polygon)s. The second argument is how much to offset the polygon. Keyword arguments explained above.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L404-L414' class='documenter-source'>source</a><br>


<a id='Rectangle-API-1'></a>

## Rectangle API

<a id='Devices.Rectangles.Rectangle' href='#Devices.Rectangles.Rectangle'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Type*.



```
type Rectangle{T} <: AbstractPolygon{T}
    ll::Point{T}
    ur::Point{T}
    properties::Dict{Symbol, Any}
    Rectangle(ll,ur) = Rectangle(ll,ur,Dict{Symbol,Any}())
    function Rectangle(a,b,props)
        # Ensure ll is lower-left, ur is upper-right.
        ll = Point(a.<=b) .* a + Point(b.<=a) .* b
        ur = Point(a.<=b) .* b + Point(b.<=a) .* a
        new(ll,ur,props)
    end
end
```

A rectangle, defined by opposing lower-left and upper-right corner coordinates. Lower-left and upper-right are guaranteed to be such by the inner constructor.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L18-L36' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.Rectangle-Tuple{Devices.Points.Point,Devices.Points.Point}' href='#Devices.Rectangles.Rectangle-Tuple{Devices.Points.Point,Devices.Points.Point}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle(ll::Point, ur::Point; kwargs...)
```

Convenience constructor for `Rectangle` objects.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L51-L57' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.Rectangle-Tuple{Any,Any}' href='#Devices.Rectangles.Rectangle-Tuple{Any,Any}'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Method*.



```
Rectangle(width, height, kwargs...)
```

Constructs `Rectangle` objects by specifying the width and height rather than the lower-left and upper-right corners.

The rectangle will sit with the lower-left corner at the origin. With centered rectangles we would need to divide width and height by 2 to properly position. If we wanted an object of `Rectangle{Int}` type, this would not be possible if either `width` or `height` were odd numbers. This definition ensures type stability in the constructor.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L61-L74' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.bounds-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(r::Rectangle)
```

No-op (just returns `r`).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L120-L126' class='documenter-source'>source</a><br>

<a id='Devices.center-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.center-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.center`** &mdash; *Method*.



```
center(r::Rectangle)
```

Returns a [`Point`](points.md#Devices.Points.Point) corresponding to the center of the rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L129-L135' class='documenter-source'>source</a><br>

<a id='Devices.centered-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.centered-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.centered`** &mdash; *Method*.



```
centered(r::Rectangle)
```

Centers a copy of `r`, with promoted coordinates if necessary. This function will not throw an `InexactError()`, even if `r` had integer coordinates.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L153-L161' class='documenter-source'>source</a><br>

<a id='Devices.centered!-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.centered!-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.centered!`** &mdash; *Method*.



```
centered!(r::Rectangle)
```

Centers a rectangle. Will throw an `InexactError()` if the rectangle cannot be centered with integer coordinates.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L138-L145' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.Rectangles.height`** &mdash; *Method*.



```
height(r::Rectangle)
```

Return the height of a rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L100-L106' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.isproper-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.Rectangles.isproper-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.Rectangles.isproper`** &mdash; *Method*.



```
isproper(r::Rectangle)
```

Returns `true` if the rectangle has a non-zero size. Otherwise, returns `false`. Note that the upper-right and lower-left corners are enforced to be the `ur` and `ll` fields of a `Rectangle` by the inner constructor.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L109-L117' class='documenter-source'>source</a><br>

<a id='Base.minimum-Tuple{Devices.Rectangles.Rectangle}' href='#Base.minimum-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Base.minimum`** &mdash; *Method*.



```
minimum(r::Rectangle)
```

Returns the lower-left corner of a rectangle (Point object).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L167-L173' class='documenter-source'>source</a><br>

<a id='Base.maximum-Tuple{Devices.Rectangles.Rectangle}' href='#Base.maximum-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Base.maximum`** &mdash; *Method*.



```
maximum(r::Rectangle)
```

Returns the upper-right corner of a rectangle (Point object).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L176-L182' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.points-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Polygons.points-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Polygons.points`** &mdash; *Method*.



```
points{T}(x::Rectangle{T})
```

Returns the array of `Point` objects defining the rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L98-L104' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle}' href='#Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle}'>#</a>
**`Devices.Rectangles.width`** &mdash; *Method*.



```
width(r::Rectangle)
```

Return the width of a rectangle.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L91-L97' class='documenter-source'>source</a><br>

<a id='Base.:+-Tuple{Devices.Rectangles.Rectangle,Devices.Points.Point}' href='#Base.:+-Tuple{Devices.Rectangles.Rectangle,Devices.Points.Point}'>#</a>
**`Base.:+`** &mdash; *Method*.



```
+(r::Rectangle, p::Point)
```

Translate a rectangle by `p`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/rectangles.jl#L191-L197' class='documenter-source'>source</a><br>


<a id='Polygon-API-1'></a>

## Polygon API

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


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L34-L46' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.Polygon-Tuple{AbstractArray{Devices.Points.Point{T},1}}' href='#Devices.Polygons.Polygon-Tuple{AbstractArray{Devices.Points.Point{T},1}}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon{T}(parr::AbstractArray{Point{T},1}; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L65-L71' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.Polygon-Tuple{Devices.Points.Point,Devices.Points.Point,Devices.Points.Point,Vararg{Devices.Points.Point,N}}' href='#Devices.Polygons.Polygon-Tuple{Devices.Points.Point,Devices.Points.Point,Devices.Points.Point,Vararg{Devices.Points.Point,N}}'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Method*.



```
Polygon(p0::Point, p1::Point, p2::Point, p3::Point...; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L55-L61' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Polygons.Polygon}' href='#Devices.bounds-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(p::Polygon)
```

Return a bounding Rectangle with no properties for polygon `p`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L174-L180' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon,N}}' href='#Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon,N}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
```

Return a bounding `Rectangle` with no properties for an array `parr` of `AbstractPolygon` objects.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L183-L190' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.AbstractPolygon,Vararg{Devices.AbstractPolygon,N}}' href='#Devices.bounds-Tuple{Devices.AbstractPolygon,Vararg{Devices.AbstractPolygon,N}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(p0::AbstractPolygon, p::AbstractPolygon...)
```

Return a bounding `Rectangle` with no properties for several `AbstractPolygon` objects.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L198-L205' class='documenter-source'>source</a><br>

<a id='Base.minimum-Tuple{Devices.Polygons.Polygon}' href='#Base.minimum-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Base.minimum`** &mdash; *Method*.



```
minimum(x::Polygon)
```

Return the lower-left-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L117-L124' class='documenter-source'>source</a><br>

<a id='Base.maximum-Tuple{Devices.Polygons.Polygon}' href='#Base.maximum-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Base.maximum`** &mdash; *Method*.



```
maximum(x::Polygon)
```

Return the upper-right-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L127-L134' class='documenter-source'>source</a><br>

<a id='Devices.Polygons.points-Tuple{Devices.Polygons.Polygon}' href='#Devices.Polygons.points-Tuple{Devices.Polygons.Polygon}'>#</a>
**`Devices.Polygons.points`** &mdash; *Method*.



```
points(x::Polygon)
```

Returns the array of `Point` objects defining the polygon.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b8678f00938d0e6ef34bdc98e6af3512bc1097ab/src/polygons.jl#L89-L95' class='documenter-source'>source</a><br>

