
<a id='Rectangle-styles-1'></a>

## Rectangle styles

<a id='Devices.Rectangles.Plain' href='#Devices.Rectangles.Plain'>#</a>
**`Devices.Rectangles.Plain`** &mdash; *Type*.



```
type Plain <: Style end
```

Plain rectangle style. Use this if you are fond for the simpler times when rectangles were just rectangles.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/rectangles.jl#L212-L219' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.Rounded' href='#Devices.Rectangles.Rounded'>#</a>
**`Devices.Rectangles.Rounded`** &mdash; *Type*.



```
type Rounded{T<:Coordinate} <: Style
    r::T
end
```

Rounded rectangle style. All corners are rounded off with a given radius `r`. The bounding box of the unstyled rectangle should remain unaffected.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/rectangles.jl#L222-L231' class='documenter-source'>source</a><br>

<a id='Devices.Rectangles.Undercut' href='#Devices.Rectangles.Undercut'>#</a>
**`Devices.Rectangles.Undercut`** &mdash; *Type*.



```
type Undercut{T<:Coordinate} <: Style
    ucl::T
    uct::T
    ucr::T
    ucb::T
end
```

Undercut rectangles. In each direction around a rectangle (left, top, right, bottom) an undercut is rendered on a different layer.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/rectangles.jl#L236-L248' class='documenter-source'>source</a><br>


<a id='Polygon-styles-1'></a>

## Polygon styles

<a id='Devices.Polygons.Plain' href='#Devices.Polygons.Plain'>#</a>
**`Devices.Polygons.Plain`** &mdash; *Type*.



Plain polygon style.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/polygons.jl#L220' class='documenter-source'>source</a><br>


<a id='Render-methods-1'></a>

## Render methods

<a id='Devices.render!' href='#Devices.render!'>#</a>
**`Devices.render!`** &mdash; *Function*.



```
render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain(); kwargs...)
```

Render a rectangle `r` to cell `c`, defaulting to plain styling.

Returns an array of the AbstractPolygons added to the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L146-L154' class='documenter-source'>source</a><br>


```
render!(c::Cell, r::Rectangle, ::Rectangles.Plain; kwargs...)
```

Render a rectangle `r` to cell `c` with plain styling.

Returns an array with the rectangle in it.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L159-L167' class='documenter-source'>source</a><br>


```
render!(c::Cell, r::Rectangle, s::Rectangles.Rounded; kwargs...)
```

Render a rounded rectangle `r` to cell `c`. This is accomplished by rendering a path around the outside of a (smaller than requested) solid rectangle. The bounding box of `r` is preserved.

Returns an array of the AbstractPolygons added to the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L174-L184' class='documenter-source'>source</a><br>


```
render!(c::Cell, r::Rectangle, s::Rectangles.Undercut;
    layer=0, uclayer=0, kwargs...)
```

Render a rectangle `r` to cell `c`. Additionally, put a hollow border around the rectangle with layer `uclayer`. Useful for undercut structures.

Returns an array of the AbstractPolygons added to the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L206-L216' class='documenter-source'>source</a><br>


```
render!(c::Cell, r::Polygon, s::Polygons.Style=Polygons.Plain(); kwargs...)
```

Render a polygon `r` to cell `c`, defaulting to plain styling.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L231-L238' class='documenter-source'>source</a><br>


```
render!(c::Cell, p::Path; kwargs...)
```

Render a path `p` to a cell `c`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L245-L251' class='documenter-source'>source</a><br>


```
render!(c::Cell, segment::Paths.Segment, s::Paths.Style; kwargs...)
```

Render a `segment` with style `s` to cell `c`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L322-L328' class='documenter-source'>source</a><br>


```
render!(c::Cell, segment::Paths.Segment, s::Paths.DecoratedStyle; kwargs...)
```

Render a `segment` with decorated style `s` to cell `c`. Cell references held by the decorated style will have their fields modified by this method, which is why they are shallow copied in the [`Paths.attach!`](paths.md#Devices.Paths.attach!) function.

This method draws the decorations before the path itself is drawn.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/Devices.jl#L359-L370' class='documenter-source'>source</a><br>

