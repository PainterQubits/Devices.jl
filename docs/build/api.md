
<a id='Points-1'></a>

## Points


Points are implemented using the abstract type `FixedVectorNoTuple` from [FixedSizeArrays.jl](https://github.com/SimonDanisch/FixedSizeArrays.jl). This permits a fast, efficient representation of coordinates in the plane. Additionally, unlike `Tuple` objects, we can add points together, simplifying many function definitions.


To interface with gdspy, we simply convert the `Point` object to a `Tuple` and let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

<a id='Devices.Points.getx' href='#Devices.Points.getx'>#</a>
**`Devices.Points.getx`** &mdash; *Function*.

---


`getx(p::Point)`

Get the x-coordinate of a point.

<a id='Devices.Points.gety' href='#Devices.Points.gety'>#</a>
**`Devices.Points.gety`** &mdash; *Function*.

---


`gety(p::Point)`

Get the y-coordinate of a point.


<a id='Paths-1'></a>

## Paths


<a id='Segments-1'></a>

### Segments

<a id='Devices.Paths.Segment' href='#Devices.Paths.Segment'>#</a>
**`Devices.Paths.Segment`** &mdash; *Type*.

---


`abstract Segment{T<:Real}`

Path segment in the plane. All Segment objects should have the implement the following methods:

  * `length`
  * `origin`
  * `α0`
  * `setorigin!`
  * `setα0!`
  * `lastangle`

<a id='Devices.Paths.Straight' href='#Devices.Paths.Straight'>#</a>
**`Devices.Paths.Straight`** &mdash; *Type*.

---


`type Straight{T<:Real} <: Segment{T}`

A straight line segment is parameterized by its length. It begins at a point `origin` with initial angle `α0`.

The parametric function over `t ∈ [0,1]` describing the line segment is given by:

`t -> origin + Point(t*l*cos(α),t*l*sin(α))`

<a id='Devices.Paths.Turn' href='#Devices.Paths.Turn'>#</a>
**`Devices.Paths.Turn`** &mdash; *Type*.

---


`type Turn{T<:Real} <: Segment{T}`

A circular turn is parameterized by the turn angle `α` and turning radius `r`. It begins at a point `origin` with initial angle `α0`.

The center of the circle is given by:

`cen = origin + Point(r*cos(α0+sign(α)*π/2), r*sin(α0+sign(α)*π/2))`

The parametric function over `t ∈ [0,1]` describing the turn is given by:

`t -> cen + Point(r*cos(α0-sign(α)*π/2+α*t), r*sin(α0-sign(α)*π/2+α*t))`

<a id='Devices.Paths.CompoundSegment' href='#Devices.Paths.CompoundSegment'>#</a>
**`Devices.Paths.CompoundSegment`** &mdash; *Type*.

---


`type CompoundSegment{T<:Real} <: Segment{T}`

Consider an array of segments as one contiguous segment. Useful e.g. for applying styles, uninterrupted over segment changes.


<a id='Styles-1'></a>

### Styles

<a id='Devices.Paths.Style' href='#Devices.Paths.Style'>#</a>
**`Devices.Paths.Style`** &mdash; *Type*.

---


`abstract Style`

How to render a given path segment. All styles should implement the following methods:

  * `distance`
  * `extent`
  * `paths`
  * `width`
  * `divs`

<a id='Devices.Paths.Trace' href='#Devices.Paths.Trace'>#</a>
**`Devices.Paths.Trace`** &mdash; *Type*.

---


`type Trace <: Style`

Simple, single trace.

  * `width::Function`: trace width.
  * `divs::Int`: number of segments to render. Increase if you see artifacts.

<a id='Devices.Paths.CPW' href='#Devices.Paths.CPW'>#</a>
**`Devices.Paths.CPW`** &mdash; *Type*.

---


`type CPW <: Style`

Two adjacent traces can form a coplanar waveguide.

  * `trace::Function`: center conductor width.
  * `gap::Function`: distance between center conductor edges and ground plane
  * `divs::Int`: number of segments to render. Increase if you see artifacts.

May need to be inverted with respect to a ground plane, depending on how the pattern is written.

<a id='Devices.Paths.CompoundStyle' href='#Devices.Paths.CompoundStyle'>#</a>
**`Devices.Paths.CompoundStyle`** &mdash; *Type*.

---


`type CompoundStyle{T<:Real} <: Style`

Combines styles together for use with a `CompoundSegment`.

  * `segments`: Needed for divs function.
  * `styles`: Array of styles making up the object.
  * `f`: returns tuple of style index and the `t` to use for that style's parametric function.


<a id='Path-interrogation-1'></a>

### Path interrogation

<a id='Devices.Paths.direction' href='#Devices.Paths.direction'>#</a>
**`Devices.Paths.direction`** &mdash; *Function*.

---


`direction(p::Function, t)`

For some parameteric function `p(t)↦Point(x(t),y(t))`, returns the angle at which the path is pointing for a given `t`.

<a id='Devices.Paths.pathlength' href='#Devices.Paths.pathlength'>#</a>
**`Devices.Paths.pathlength`** &mdash; *Function*.

---


`pathlength(p::AbstractArray{Segment})`

Total physical length of segments.

`pathlength(p::Path)`

Physical length of a path. Note that `length` will return the number of segments in a path, not the physical length.

<a id='Devices.Paths.origin' href='#Devices.Paths.origin'>#</a>
**`Devices.Paths.origin`** &mdash; *Function*.

---


`origin(p::Path)`

First point of a path.

`origin{T}(s::Segment{T})`

Return the first point in a segment (calculated).

<a id='Devices.Paths.setorigin!' href='#Devices.Paths.setorigin!'>#</a>
**`Devices.Paths.setorigin!`** &mdash; *Function*.

---


`setorigin!(s::CompoundSegment, p::Point)`

Set the origin of a compound segment.

`setorigin!(s::Turn, p::Point)`

Set the origin of a turn.

`setorigin!(s::Straight, p::Point)`

Set the origin of a straight segment.

<a id='Devices.Paths.α0' href='#Devices.Paths.α0'>#</a>
**`Devices.Paths.α0`** &mdash; *Function*.

---


`α0(p::Path)`

First angle of a path.

`α0(s::Segment)`

Return the first angle in a segment (calculated).

<a id='Devices.Paths.setα0!' href='#Devices.Paths.setα0!'>#</a>
**`Devices.Paths.setα0!`** &mdash; *Function*.

---


`setα0!(s::CompoundSegment, α0′)`

Set the starting angle of a compound segment.

`setα0!(s::Turn, α0′)`

Set the starting angle of a turn.

`setα0!(s::Straight, α0′)`

Set the angle of a straight segment.

<a id='Devices.Paths.lastpoint' href='#Devices.Paths.lastpoint'>#</a>
**`Devices.Paths.lastpoint`** &mdash; *Function*.

---


`lastpoint(p::Path)`

Last point of a path.

`lastpoint{T}(s::Segment{T})`

Return the last point in a segment (calculated).

<a id='Devices.Paths.lastangle' href='#Devices.Paths.lastangle'>#</a>
**`Devices.Paths.lastangle`** &mdash; *Function*.

---


`lastangle(p::Path)`

Last angle of a path.

`lastangle(s::Segment)`

Return the last angle in a segment (calculated).

<a id='Devices.Paths.firststyle' href='#Devices.Paths.firststyle'>#</a>
**`Devices.Paths.firststyle`** &mdash; *Function*.

---


`firststyle(p::Path)`

Style of the first segment of a path.

<a id='Devices.Paths.laststyle' href='#Devices.Paths.laststyle'>#</a>
**`Devices.Paths.laststyle`** &mdash; *Function*.

---


`laststyle(p::Path)`

Style of the last segment of a path.


<a id='Path-building-1'></a>

### Path building

<a id='Devices.Paths.adjust!' href='#Devices.Paths.adjust!'>#</a>
**`Devices.Paths.adjust!`** &mdash; *Function*.

---


`adjust!(p::Path, n::Integer=1)`

Adjust a path's parametric functions starting from index `n`. Used internally whenever segments are inserted into the path.

<a id='Devices.Paths.launch!' href='#Devices.Paths.launch!'>#</a>
**`Devices.Paths.launch!`** &mdash; *Function*.

---


`launch!(p::Path; extround=5, trace0=300, trace1=5,         gap0=150, gap1=2.5, flatlen=250, taperlen=250)`

Add a launcher to the path. Somewhat intelligent in that the launcher will reverse its orientation depending on if it is at the start or the end of a path.

There are numerous keyword arguments to control the behavior:

  * `extround`: Rounding radius of the outermost corners; should be less than `gap0`.
  * `trace0`: Bond pad width.
  * `trace1`: Center trace width of next CPW segment.
  * `gap0`: Gap width adjacent to bond pad.
  * `gap1`: Gap width of next CPW segment.
  * `flatlen`: Bond pad length.
  * `taperlen`: Length of taper region between bond pad and next CPW segment.

Returns a `Style` object suitable for continuity with the next segment. Ignore the returned style if you are terminating a path.

<a id='Devices.Paths.meander!' href='#Devices.Paths.meander!'>#</a>
**`Devices.Paths.meander!`** &mdash; *Function*.

---


`meander!{T<:Real}(p::Path{T}, len, r, straightlen, α::Real)`

Alternate between going straight with length `straightlen` and turning with radius `r` and angle `α`. Each turn goes the opposite direction of the previous. The total length is `len`. Useful for making resonators.

The straight and turn segments are combined into a `CompoundSegment` and appended to the path `p`.

<a id='Devices.Paths.param' href='#Devices.Paths.param'>#</a>
**`Devices.Paths.param`** &mdash; *Function*.

---


`param{T<:Real}(c::CompoundSegment{T})`

Return a parametric function over the domain [0,1] that represents the compound segment.

<a id='Devices.Paths.simplify!' href='#Devices.Paths.simplify!'>#</a>
**`Devices.Paths.simplify!`** &mdash; *Function*.

---


`simplify!(p::Path)`

All segments of a path are turned into a `CompoundSegment` and all styles of a path are turned into a `CompoundStyle`. The idea here is:

  * Indexing the path becomes more sane when you can combine several path segments into one logical element. A launcher would have several indices in a path unless you could simplify it.
  * You don't need to think hard about boundaries between straights and turns when you want a continuous styling of a very long path.

<a id='Devices.Paths.straight!' href='#Devices.Paths.straight!'>#</a>
**`Devices.Paths.straight!`** &mdash; *Function*.

---


`straight!(p::Path, l::Real)`

Extend a path `p` straight by length `l` in the current direction.

<a id='Devices.Paths.turn!' href='#Devices.Paths.turn!'>#</a>
**`Devices.Paths.turn!`** &mdash; *Function*.

---


`turn!(p::Path, s::ASCIIString, r::Real, sty::Style=laststyle(p))`

Turn a path `p` with direction coded by string `s`:

  * "l": turn by π/2 (left)
  * "r": turn by -π/2 (right)
  * "lrlrllrrll": do those turns in that order

`turn!(p::Path, α::Real, r::Real, sty::Style=laststyle(p))`

Turn a path `p` by angle `α` with a turning radius `r` in the current direction. Positive angle turns left.


<a id='Interfacing-with-gdspy-1'></a>

### Interfacing with gdspy

<a id='Devices.Paths.distance' href='#Devices.Paths.distance'>#</a>
**`Devices.Paths.distance`** &mdash; *Function*.

---


For a style `s` and parameteric argument `t`, returns the distance between the centers of parallel paths rendered by gdspy.

<a id='Devices.Paths.extent' href='#Devices.Paths.extent'>#</a>
**`Devices.Paths.extent`** &mdash; *Function*.

---


For a style `s` and parameteric argument `t`, returns a distance tangential to the path specifying the lateral extent of the polygons rendered by gdspy.

<a id='Devices.Paths.paths' href='#Devices.Paths.paths'>#</a>
**`Devices.Paths.paths`** &mdash; *Function*.

---


For a style `s` and parameteric argument `t`, returns the number of parallel paths rendered by gdspy.

<a id='Devices.Paths.width' href='#Devices.Paths.width'>#</a>
**`Devices.Paths.width`** &mdash; *Function*.

---


For a style `s` and parameteric argument `t`, returns the width of paths rendered by gdspy.


<a id='Polygons-1'></a>

## Polygons


<a id='Rectangles-1'></a>

### Rectangles

<a id='Devices.Rectangles.Rectangle' href='#Devices.Rectangles.Rectangle'>#</a>
**`Devices.Rectangles.Rectangle`** &mdash; *Type*.

---


`type Rectangle{T<:Real} <: AbstractPolygon{T}`

A rectangle, defined by opposing corner coordinates.

<a id='Devices.bounds-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.bounds-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.

---


`bounds(r::Rectangle)`

No-op (just returns `r`).

`bounds(p0::AbstractPolygon, p::AbstractPolygon...)`

Return a bounding `Rectangle` with no properties for several `AbstractPolygon`s.

<a id='Devices.Rectangles.center-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Rectangles.center-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Rectangles.center`** &mdash; *Method*.

---


`center(r::Rectangle)`

Returns a Point corresponding to the center of the rectangle.

<a id='Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Rectangles.height`** &mdash; *Method*.

---


`height(r::Rectangle)`

Return the height of a rectangle.

<a id='Base.minimum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Base.minimum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Base.minimum`** &mdash; *Method*.

---


`minimum(r::Rectangle)`

Returns the lower-left corner of a rectangle (Point object).

```
minimum(itr)
```

Returns the smallest element in a collection.

<a id='Base.maximum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Base.maximum-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Base.maximum`** &mdash; *Method*.

---


`maximum(r::Rectangle)`

Returns the upper-right corner of a rectangle (Point object).

```
maximum(itr)
```

Returns the largest element in a collection.

<a id='Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle{T<:Real}}' href='#Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle{T<:Real}}'>#</a>
**`Devices.Rectangles.width`** &mdash; *Method*.

---


`width(r::Rectangle)`

Return the width of a rectangle.


<a id='Polygons-2'></a>

### Polygons

<a id='Devices.Polygons.Polygon' href='#Devices.Polygons.Polygon'>#</a>
**`Devices.Polygons.Polygon`** &mdash; *Type*.

---


`type Polygon{T<:Real}`

Polygon defined by list of coordinates (not repeating start).

<a id='Devices.bounds-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Devices.bounds-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.

---


`bounds(p::Polygon)`

Return a bounding Rectangle with no properties for polygon `p`.

`bounds(p0::AbstractPolygon, p::AbstractPolygon...)`

Return a bounding `Rectangle` with no properties for several `AbstractPolygon`s.

<a id='Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon{T},N}}' href='#Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon{T},N}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.

---


`bounds{T<:AbstractPolygon}(parr::AbstractArray{T,1})`

Return a bounding `Rectangle` with no properties for an array `parr` of `AbstractPolygon`s.

<a id='Devices.bounds-Tuple{Devices.AbstractPolygon{T},Vararg{Devices.AbstractPolygon{T}}}' href='#Devices.bounds-Tuple{Devices.AbstractPolygon{T},Vararg{Devices.AbstractPolygon{T}}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.

---


`bounds(p0::AbstractPolygon, p::AbstractPolygon...)`

Return a bounding `Rectangle` with no properties for several `AbstractPolygon`s.

<a id='Base.minimum-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Base.minimum-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Base.minimum`** &mdash; *Method*.

---


`minimum(x::Polygon)`

Return the lower-left-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.

```
minimum(itr)
```

Returns the smallest element in a collection.

<a id='Base.maximum-Tuple{Devices.Polygons.Polygon{T<:Real}}' href='#Base.maximum-Tuple{Devices.Polygons.Polygon{T<:Real}}'>#</a>
**`Base.maximum`** &mdash; *Method*.

---


`maximum(x::Polygon)`

Return the upper-right-most corner of a rectangle bounding polygon `x`. Note that this point doesn't have to be in the polygon.

```
maximum(itr)
```

Returns the largest element in a collection.


<a id='Clipping-and-offsetting-1'></a>

### Clipping and offsetting


As of now this package's notion of polygons is that there are no "inner holes." Probably it would be helpful if we expanded our definition.


For clipping polygons we use [GPC](http://www.cs.man.ac.uk/~toby/gpc/) to get triangle strips which never have holes in them. These are then rendered as polygons individually. An obvious downside is that subsequent offsetting will not work as desired.


For offsetting polygons we use [Clipper](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm). Clipper does not seem to support triangle strips so although the clipping is probably superior we cannot use it easily for now.

<a id='Devices.Polygons.clip' href='#Devices.Polygons.clip'>#</a>
**`Devices.Polygons.clip`** &mdash; *Function*.

---


`clip{S<:Real, T<:Real}(op::ClipperOp, subject::Polygon{S}, clip::Polygon{T})`

Clip polygon `subject` by polygon `clip` using operation `op` from the [Clipper library](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm). The [Python wrapper](https://github.com/greginvm/pyclipper) over the C++ library is used.

Valid `ClipperOp` include `CT_INTERSECTION`, `CT_UNION`, `CT_DIFFERENCE`, `CT_XOR`.

`clip(op::GPCOp, subject::Polygon{Cdouble}, clip::Polygon{Cdouble})`

Use the GPC clipping library to do polygon manipulations. Valid GPCOp include `GPC_DIFF`, `GPC_INT`, `GPC_XOR`, `GPC_UNION`.

<a id='Devices.Polygons.offset' href='#Devices.Polygons.offset'>#</a>
**`Devices.Polygons.offset`** &mdash; *Function*.

---


`offset{S<:Real}(subject::Polygon{S}, delta::Real,         j::ClipperJoin=JT_MITER, e::ClipperEnd=ET_CLOSEDPOLYGON)`

Offset a polygon `subject` by some amount `delta` using the [Clipper library](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm). The [Python wrapper](https://github.com/greginvm/pyclipper) over the C++ library is used.

`ClipperJoin` parameters are discussed [here](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/JoinType.htm). Valid syntax in this package is: `JT_SQUARE`, `JT_ROUND`, `JT_MITER`.

`ClipperEnd` parameters are discussed [here](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/EndType.htm). Valid syntax in this package is: `ET_CLOSEDPOLYGON`, `ET_CLOSEDLINE`, `ET_OPENSQUARE`, `ET_OPENROUND`, `ET_OPENBUTT`.

To do: Handle the type parameter of Polygon, which is ignored now.


<a id='Cells-1'></a>

## Cells

<a id='Devices.Cells.Cell' href='#Devices.Cells.Cell'>#</a>
**`Devices.Cells.Cell`** &mdash; *Type*.

---


`Cell`

A cell has a name and contains polygons and references to `CellArray` or `CellReference` objects. It also records the time of its own creation.

To add elements, push them to `elements` field; to add references, push them to `refs` field.

<a id='Devices.Cells.CellArray' href='#Devices.Cells.CellArray'>#</a>
**`Devices.Cells.CellArray`** &mdash; *Type*.

---


`CellArray{S,T<:Real}`

Array of `cell` starting at `origin` with `row` rows and `col` columns, spanned by vectors `deltacol` and `deltarow`. Optional x-reflection `xrefl::Bool`, magnification factor `mag`, and rotation angle `rot` in degrees are for the array as a whole.

The type variable `S` is to avoid circular definitions with `Cell`.

<a id='Devices.Cells.CellReference' href='#Devices.Cells.CellReference'>#</a>
**`Devices.Cells.CellReference`** &mdash; *Type*.

---


`CellReference{S,T<:Real}`

Reference to a `cell` positioned at `origin`, with optional x-reflection `xrefl::Bool`, magnification factor `mag`, and rotation angle `rot` in degrees.

The type variable `S` is to avoid circular definitions with `Cell`.

<a id='Devices.bounds-Tuple{Devices.Cells.Cell}' href='#Devices.bounds-Tuple{Devices.Cells.Cell}'>#</a>
**`Devices.bounds`** &mdash; *Method*.

---


`bounds(cell::Cell; kwargs...)`

Returns a `Rectangle` bounding box with no properties around all objects in `cell`. `Point(NaN, NaN)` is used for the corners if there is nothing inside the cell.

<a id='Devices.bounds-Tuple{Devices.Cells.CellReference{S,T<:Real}}' href='#Devices.bounds-Tuple{Devices.Cells.CellReference{S,T<:Real}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.

---


`bounds(ref::CellReference; kwargs...)`

Returns a `Rectangle` bounding box with no properties around all objects in `ref`. `Point(NaN, NaN)` is used for the corners if there is nothing inside the cell referenced by `ref`. The bounding box respects reflection, rotation, and magnification specified by `ref`.

<a id='Devices.Cells.traverse!' href='#Devices.Cells.traverse!'>#</a>
**`Devices.Cells.traverse!`** &mdash; *Function*.

---


`traverse!(a::AbstractArray, c::Cell, level=1)`

Given a cell, recursively traverse its references for other cells and add to array `a` some tuples: `(level, c)`. `level` corresponds to how deep the cell was found, and `c` is the found cell.

<a id='Devices.Cells.order!' href='#Devices.Cells.order!'>#</a>
**`Devices.Cells.order!`** &mdash; *Function*.

---


`order!(a::AbstractArray)`

Given an array of tuples like that coming out of [`traverse!`](api.md#Devices.Cells.traverse!), we sort by the `level`, strip the level out, and then retain unique entries. The aim of this function is to determine an optimal writing order when saving pattern data (although the GDS-II spec does not require cells to be in a particular order, there may be performance ramifications).

For performance reasons, this function modifies `a` but what you want is the returned result array.


<a id='Rendering-1'></a>

## Rendering

<a id='Devices.render!' href='#Devices.render!'>#</a>
**`Devices.render!`** &mdash; *Function*.

---


`render!(c::Cell, segment::Paths.Segment, s::Paths.Style; kwargs...)`

Render a `segment` with style `s` to cell `c`.

`render!(c::Cell, segment::Paths.Segment, s::Paths.DecoratedStyle; kwargs...)`

Render a `segment` with decorated style `s` to cell `c`. This method draws the decorations before the path itself is drawn.

`render!(c::Cell, p::Path; kwargs...)`

Render a path `p` to a cell `c`.

`render!(c::Cell, r::Polygon, s::Polygons.Style=Polygons.Plain(); kwargs...)`

Render a polygon `r` to cell `c`, defaulting to plain styling.

`render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain(); kwargs...)`

Render a rectangle `r` to cell `c`, defaulting to plain styling.

`render!(c::Cell, r::Rectangle, s::Rectangles.Rounded; kwargs...)`

Render a rounded rectangle `r` to cell `c`. This is accomplished by rendering a path around the outside of a (smaller than requested) solid rectangle. The bounding box of `r` is preserved.

`render!(c::Cell, r::Rectangle, ::Rectangles.Plain; kwargs...)`

Render a rectangle `r` to cell `c` with plain styling.


<a id='Saving-patterns-1'></a>

## Saving patterns


To save a pattern, make sure you are `using FileIO`.

<a id='FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell,Vararg{Devices.Cells.Cell}}' href='#FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell,Vararg{Devices.Cells.Cell}}'>#</a>
**`FileIO.save`** &mdash; *Method*.

---


```
save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
name="GDSIILIB", precision=1e-9, unit=1e-6, modify=now(), acc=now(),
verbose=false)`
```

This method is implicitly called when you use the convenient syntax: `save("/path/to/my.gds", cells_i_want_to_save...)`

The `name` keyword argument is used for the internal library name of the GDS-II file and is probably inconsequential for modern workflows.

The `verbose` keyword argument allows you to monitor the output of [`traverse!`](api.md#Devices.Cells.traverse!) and [`order!`](api.md#Devices.Cells.order!) if something funny is happening while saving.


<a id='Index-1'></a>

## Index

- [`Base.maximum`](api.md#Base.maximum-Tuple{Devices.Polygons.Polygon{T<:Real}})
- [`Base.maximum`](api.md#Base.maximum-Tuple{Devices.Rectangles.Rectangle{T<:Real}})
- [`Base.minimum`](api.md#Base.minimum-Tuple{Devices.Polygons.Polygon{T<:Real}})
- [`Base.minimum`](api.md#Base.minimum-Tuple{Devices.Rectangles.Rectangle{T<:Real}})
- [`Devices.Cells.Cell`](api.md#Devices.Cells.Cell)
- [`Devices.Cells.CellArray`](api.md#Devices.Cells.CellArray)
- [`Devices.Cells.CellReference`](api.md#Devices.Cells.CellReference)
- [`Devices.Cells.order!`](api.md#Devices.Cells.order!)
- [`Devices.Cells.traverse!`](api.md#Devices.Cells.traverse!)
- [`Devices.Paths.CPW`](api.md#Devices.Paths.CPW)
- [`Devices.Paths.CompoundSegment`](api.md#Devices.Paths.CompoundSegment)
- [`Devices.Paths.CompoundStyle`](api.md#Devices.Paths.CompoundStyle)
- [`Devices.Paths.Segment`](api.md#Devices.Paths.Segment)
- [`Devices.Paths.Straight`](api.md#Devices.Paths.Straight)
- [`Devices.Paths.Style`](api.md#Devices.Paths.Style)
- [`Devices.Paths.Trace`](api.md#Devices.Paths.Trace)
- [`Devices.Paths.Turn`](api.md#Devices.Paths.Turn)
- [`Devices.Paths.adjust!`](api.md#Devices.Paths.adjust!)
- [`Devices.Paths.direction`](api.md#Devices.Paths.direction)
- [`Devices.Paths.distance`](api.md#Devices.Paths.distance)
- [`Devices.Paths.extent`](api.md#Devices.Paths.extent)
- [`Devices.Paths.firststyle`](api.md#Devices.Paths.firststyle)
- [`Devices.Paths.lastangle`](api.md#Devices.Paths.lastangle)
- [`Devices.Paths.lastpoint`](api.md#Devices.Paths.lastpoint)
- [`Devices.Paths.laststyle`](api.md#Devices.Paths.laststyle)
- [`Devices.Paths.launch!`](api.md#Devices.Paths.launch!)
- [`Devices.Paths.meander!`](api.md#Devices.Paths.meander!)
- [`Devices.Paths.origin`](api.md#Devices.Paths.origin)
- [`Devices.Paths.param`](api.md#Devices.Paths.param)
- [`Devices.Paths.pathlength`](api.md#Devices.Paths.pathlength)
- [`Devices.Paths.paths`](api.md#Devices.Paths.paths)
- [`Devices.Paths.setorigin!`](api.md#Devices.Paths.setorigin!)
- [`Devices.Paths.setα0!`](api.md#Devices.Paths.setα0!)
- [`Devices.Paths.simplify!`](api.md#Devices.Paths.simplify!)
- [`Devices.Paths.straight!`](api.md#Devices.Paths.straight!)
- [`Devices.Paths.turn!`](api.md#Devices.Paths.turn!)
- [`Devices.Paths.width`](api.md#Devices.Paths.width)
- [`Devices.Paths.α0`](api.md#Devices.Paths.α0)
- [`Devices.Points.getx`](api.md#Devices.Points.getx)
- [`Devices.Points.gety`](api.md#Devices.Points.gety)
- [`Devices.Polygons.Polygon`](api.md#Devices.Polygons.Polygon)
- [`Devices.Polygons.clip`](api.md#Devices.Polygons.clip)
- [`Devices.Polygons.offset`](api.md#Devices.Polygons.offset)
- [`Devices.Rectangles.Rectangle`](api.md#Devices.Rectangles.Rectangle)
- [`Devices.Rectangles.center`](api.md#Devices.Rectangles.center-Tuple{Devices.Rectangles.Rectangle{T<:Real}})
- [`Devices.Rectangles.height`](api.md#Devices.Rectangles.height-Tuple{Devices.Rectangles.Rectangle{T<:Real}})
- [`Devices.Rectangles.width`](api.md#Devices.Rectangles.width-Tuple{Devices.Rectangles.Rectangle{T<:Real}})
- [`Devices.bounds`](api.md#Devices.bounds-Tuple{AbstractArray{T<:Devices.AbstractPolygon{T},N}})
- [`Devices.bounds`](api.md#Devices.bounds-Tuple{Devices.AbstractPolygon{T},Vararg{Devices.AbstractPolygon{T}}})
- [`Devices.bounds`](api.md#Devices.bounds-Tuple{Devices.Cells.CellReference{S,T<:Real}})
- [`Devices.bounds`](api.md#Devices.bounds-Tuple{Devices.Cells.Cell})
- [`Devices.bounds`](api.md#Devices.bounds-Tuple{Devices.Polygons.Polygon{T<:Real}})
- [`Devices.bounds`](api.md#Devices.bounds-Tuple{Devices.Rectangles.Rectangle{T<:Real}})
- [`Devices.render!`](api.md#Devices.render!)
- [`FileIO.save`](api.md#FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell,Vararg{Devices.Cells.Cell}})
