
<a id='Paths-1'></a>

## Paths

<a id='Devices.Paths.Path' href='#Devices.Paths.Path'>#</a>
**`Devices.Paths.Path`** &mdash; *Type*.



```
type Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::typeof(0.0°)
    style0::ContinuousStyle{T}
    nodes::Array{Node{T},1}
end
```

Type for abstracting an arbitrary styled path in the plane. Iterating returns tuples of (`segment`, `style`).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L301-L313' class='documenter-source'>source</a><br>

<a id='Devices.Paths.Path-Tuple{Devices.Points.Point{T<:Real}}' href='#Devices.Paths.Path-Tuple{Devices.Points.Point{T<:Real}}'>#</a>
**`Devices.Paths.Path`** &mdash; *Method*.



```
Path{T<:Coordinate}(p0::Point{T}=Point(0.0,0.0); α0=0.0, style0::Style=Trace(1.0))
```

Convenience constructor for `Path{T}` object.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L339-L345' class='documenter-source'>source</a><br>

<a id='Devices.Paths.pathlength-Tuple{Devices.Paths.Path}' href='#Devices.Paths.pathlength-Tuple{Devices.Paths.Path}'>#</a>
**`Devices.Paths.pathlength`** &mdash; *Method*.



```
pathlength(p::Path)
```

Physical length of a path. Note that `length` will return the number of segments in a path, not the physical length of the path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L351-L358' class='documenter-source'>source</a><br>


<a id='Segments-1'></a>

## Segments

<a id='Devices.Paths.Segment' href='#Devices.Paths.Segment'>#</a>
**`Devices.Paths.Segment`** &mdash; *Type*.



```
abstract Segment{T<:Coordinate}
```

Path segment in the plane. All Segment objects should have the implement the following methods:

  * `pathlength`
  * `p0`
  * `α0`
  * `setp0!`
  * `setα0!`
  * `α1`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L152-L166' class='documenter-source'>source</a><br>

<a id='Devices.Paths.Straight' href='#Devices.Paths.Straight'>#</a>
**`Devices.Paths.Straight`** &mdash; *Type*.



```
type Straight{T} <: ContinuousSegment{T}
    l::T
    p0::Point{T}
    α0::typeof(0.0°)
    f::Function
    Straight(l, p0, α0) = begin
        s = new(l, p0, α0)
        s.f = t->(s.p0+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end
```

A straight line segment is parameterized by its length. It begins at a point `p0` with initial angle `α0`.

The parametric function over `t ∈ [0,1]` describing the line segment is given by:

`t -> p0 + Point(t*l*cos(α),t*l*sin(α))`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/straight.jl#L1-L22' class='documenter-source'>source</a><br>

<a id='Devices.Paths.Turn' href='#Devices.Paths.Turn'>#</a>
**`Devices.Paths.Turn`** &mdash; *Type*.



```
type Turn{T} <: Segment{T}
    α::typeof(1.0°)
    r::T
    p0::Point{T}
    α0::typeof(1.0°)
    f::Function
    Turn(α, r, p0, α0) = begin
        s = new(α, r, p0, α0)
        s.f = t->begin
            cen = s.p0 + Point(s.r*cos(s.α0+sign(s.α)*π/2), s.r*sin(s.α0+sign(s.α)*π/2))
            cen + Point(s.r*cos(s.α0-sign(α)*π/2+s.α*t), s.r*sin(s.α0-sign(α)*π/2+s.α*t))
        end
        s
    end
end
```

A circular turn is parameterized by the turn angle `α` and turning radius `r`. It begins at a point `p0` with initial angle `α0`.

The center of the circle is given by:

`cen = p0 + Point(r*cos(α0+sign(α)*π/2), r*sin(α0+sign(α)*π/2))`

The parametric function over `t ∈ [0,1]` describing the turn is given by:

`t -> cen + Point(r*cos(α0-sign(α)*π/2+α*t), r*sin(α0-sign(α)*π/2+α*t))`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/turn.jl#L1-L30' class='documenter-source'>source</a><br>

<a id='Devices.Paths.Corner' href='#Devices.Paths.Corner'>#</a>
**`Devices.Paths.Corner`** &mdash; *Type*.



```
type Corner{T} <: DiscreteSegment{T}
    α::typeof(1.0°)
    p0::Point{T}
    α0::typeof(1.0°)
    extent::T
    Corner(a) = new(a, Point(zero(T),zero(T)), 0.0°, zero(T))
    Corner(a,b,c,d) = new(a,b,c,d)
end
```

A corner, or sudden kink in a path. The only parameter is the angle `α` of the kink. The kink begins at a point `p0` with initial angle `α0`. It will also end at `p0`, since the corner has zero path length. However, during rendering, neighboring segments will be tweaked slightly so that the rendered path is properly centered about the path function (the rendered corner has a finite width).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/corner.jl#L1-L18' class='documenter-source'>source</a><br>

<a id='Devices.Paths.CompoundSegment' href='#Devices.Paths.CompoundSegment'>#</a>
**`Devices.Paths.CompoundSegment`** &mdash; *Type*.



```
type CompoundSegment{T} <: ContinuousSegment{T}
    segments::Vector{Segment{T}}
    f::Function

    CompoundSegment(segments) = begin
        if any(x->isa(x,Corner), segments)
            error("cannot have corners in a `CompoundSegment`. You may have ",
                "tried to simplify a path containing `Corner` objects.")
        else
            s = new(deepcopy(Array(segments)))
            s.f = param(s.segments)
            s
        end
    end
end
```

Consider an array of segments as one contiguous segment. Useful e.g. for applying styles, uninterrupted over segment changes. The array of segments given to the constructor is copied and retained by the compound segment.

Note that [`Corner`](paths.md#Devices.Paths.Corner)s introduce a discontinuity in the derivative of the path function, and are not allowed in a `CompoundSegment`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/compound.jl#L2-L28' class='documenter-source'>source</a><br>


<a id='Styles-1'></a>

## Styles

<a id='Devices.Paths.Style' href='#Devices.Paths.Style'>#</a>
**`Devices.Paths.Style`** &mdash; *Type*.



```
abstract Style{T<:Coordinate}
```

How to render a given path segment. All styles should implement the following methods:

  * `distance`
  * `extent`
  * `paths`
  * `width`
  * `divs`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L118-L131' class='documenter-source'>source</a><br>

<a id='Devices.Paths.ContinuousStyle' href='#Devices.Paths.ContinuousStyle'>#</a>
**`Devices.Paths.ContinuousStyle`** &mdash; *Type*.



```
abstract ContinuousStyle{T} <: Style{T}
```

Any style that applies to segments which have non-zero path length.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L134-L140' class='documenter-source'>source</a><br>

<a id='Devices.Paths.DiscreteStyle' href='#Devices.Paths.DiscreteStyle'>#</a>
**`Devices.Paths.DiscreteStyle`** &mdash; *Type*.



```
abstract DiscreteStyle{T} <: Style{T}
```

Any style that applies to segments which have zero path length.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L143-L149' class='documenter-source'>source</a><br>

<a id='Devices.Paths.Trace' href='#Devices.Paths.Trace'>#</a>
**`Devices.Paths.Trace`** &mdash; *Type*.



```
type Trace{T} <: ContinuousStyle{T}
    width::Function
    divs::Int
end
```

Simple, single trace.

  * `width::Function`: trace width.
  * `divs::Int`: number of segments to render. Increase if you see artifacts.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/trace.jl#L1-L13' class='documenter-source'>source</a><br>

<a id='Devices.Paths.CPW' href='#Devices.Paths.CPW'>#</a>
**`Devices.Paths.CPW`** &mdash; *Type*.



```
type CPW{T} <: ContinuousStyle{T}
    trace::Function
    gap::Function
    divs::Int
end
```

Two adjacent traces can form a coplanar waveguide.

  * `trace::Function`: center conductor width.
  * `gap::Function`: distance between center conductor edges and ground plane
  * `divs::Int`: number of segments to render. Increase if you see artifacts.

May need to be inverted with respect to a ground plane, depending on how the pattern is written.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/cpw.jl#L1-L18' class='documenter-source'>source</a><br>

<a id='Devices.Paths.CompoundStyle' href='#Devices.Paths.CompoundStyle'>#</a>
**`Devices.Paths.CompoundStyle`** &mdash; *Type*.



```
type CompoundStyle{T} <: ContinuousStyle{T}
    styles::Vector{Style{T}}
    divs::Vector{Float64}
    f::Function
end
```

Combines styles together, typically for use with a [`CompoundSegment`](paths.md#Devices.Paths.CompoundSegment).

  * `styles`: Array of styles making up the object. This is shallow-copied

by the outer constructor.

  * `divs`: An array of `t` values needed for rendering the parameteric path.
  * `f`: returns tuple of style index and the `t` to use for that

style's parametric function.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/compound.jl#L1-L17' class='documenter-source'>source</a><br>

<a id='Devices.Paths.DecoratedStyle' href='#Devices.Paths.DecoratedStyle'>#</a>
**`Devices.Paths.DecoratedStyle`** &mdash; *Type*.



```
type DecoratedStyle{T} <: ContinuousStyle{T}
    s::Style{T}
    ts::Array{Float64,1}
    dirs::Array{Int,1}
    refs::Array{CellReference{T},1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.refs = CellReference{T}[]
        a
    end
    DecoratedStyle(s,t,d,r) = new(s,t,d,r)
end
```

Style with decorations, like structures periodically repeated along the path, etc.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/decorated.jl#L1-L20' class='documenter-source'>source</a><br>

<a id='Devices.Paths.undecorated' href='#Devices.Paths.undecorated'>#</a>
**`Devices.Paths.undecorated`** &mdash; *Function*.



```
undecorated(s::Style)
```

Returns `s`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/decorated.jl#L37-L43' class='documenter-source'>source</a><br>


```
undecorated(s::DecoratedStyle)
```

Returns the underlying, undecorated style.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/decorated.jl#L46-L52' class='documenter-source'>source</a><br>


<a id='Path-interrogation-1'></a>

## Path interrogation

<a id='Devices.Paths.direction' href='#Devices.Paths.direction'>#</a>
**`Devices.Paths.direction`** &mdash; *Function*.



```
direction(p::Function, t)
```

For some parameteric function `p(t)↦Point(x(t),y(t))`, returns the angle at which the path is pointing for a given `t`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L93-L100' class='documenter-source'>source</a><br>

<a id='Devices.Paths.pathlength' href='#Devices.Paths.pathlength'>#</a>
**`Devices.Paths.pathlength`** &mdash; *Function*.



```
pathlength{T}(s::Segment{T}, verbose::Bool=false)
```

Return the length of a segment (calculated).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L273-L279' class='documenter-source'>source</a><br>


```
pathlength(p::Path)
```

Physical length of a path. Note that `length` will return the number of segments in a path, not the physical length of the path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L351-L358' class='documenter-source'>source</a><br>


```
pathlength(p::AbstractArray)
```

Total physical length of segments.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L361-L367' class='documenter-source'>source</a><br>

<a id='Devices.Paths.p0' href='#Devices.Paths.p0'>#</a>
**`Devices.Paths.p0`** &mdash; *Function*.



```
p0{T}(s::Segment{T})
```

Return the first point in a segment (calculated).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L232-L238' class='documenter-source'>source</a><br>


```
p0(p::Path)
```

First point of a path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L405-L411' class='documenter-source'>source</a><br>

<a id='Devices.Paths.setp0!' href='#Devices.Paths.setp0!'>#</a>
**`Devices.Paths.setp0!`** &mdash; *Function*.



```
setp0!(s::Straight, p::Point)
```

Set the p0 of a straight segment.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/straight.jl#L53-L59' class='documenter-source'>source</a><br>


```
setp0!(s::Turn, p::Point)
```

Set the p0 of a turn.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/turn.jl#L66-L72' class='documenter-source'>source</a><br>

<a id='Devices.Paths.α0' href='#Devices.Paths.α0'>#</a>
**`Devices.Paths.α0`** &mdash; *Function*.



```
α0(s::Segment)
```

Return the first angle in a segment (calculated).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L250-L256' class='documenter-source'>source</a><br>


```
α0(p::Path)
```

First angle of a path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L375-L381' class='documenter-source'>source</a><br>

<a id='Devices.Paths.setα0!' href='#Devices.Paths.setα0!'>#</a>
**`Devices.Paths.setα0!`** &mdash; *Function*.



```
setα0!(s::Straight, α0′)
```

Set the angle of a straight segment.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/straight.jl#L62-L68' class='documenter-source'>source</a><br>


```
setα0!(s::Turn, α0′)
```

Set the starting angle of a turn.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/turn.jl#L75-L81' class='documenter-source'>source</a><br>

<a id='Devices.Paths.p1' href='#Devices.Paths.p1'>#</a>
**`Devices.Paths.p1`** &mdash; *Function*.



```
p1{T}(s::Segment{T})
```

Return the last point in a segment (calculated).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L241-L247' class='documenter-source'>source</a><br>


```
p1(p::Path)
```

Last point of a path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L420-L426' class='documenter-source'>source</a><br>

<a id='Devices.Paths.α1' href='#Devices.Paths.α1'>#</a>
**`Devices.Paths.α1`** &mdash; *Function*.



```
α1(s::Segment)
```

Return the last angle in a segment (calculated).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L259-L265' class='documenter-source'>source</a><br>


```
α1(p::Path)
```

Last angle of a path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L390-L396' class='documenter-source'>source</a><br>

<a id='Devices.Paths.style0' href='#Devices.Paths.style0'>#</a>
**`Devices.Paths.style0`** &mdash; *Function*.



```
style0(p::Path)
```

Style of the first segment of a path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L435-L441' class='documenter-source'>source</a><br>

<a id='Devices.Paths.style1' href='#Devices.Paths.style1'>#</a>
**`Devices.Paths.style1`** &mdash; *Function*.



```
style1(p::Path)
```

Style of the last segment of a path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L450-L456' class='documenter-source'>source</a><br>

<a id='Devices.Paths.discretestyle1' href='#Devices.Paths.discretestyle1'>#</a>
**`Devices.Paths.discretestyle1`** &mdash; *Function*.



```
discretestyle1{T}(p::Path{T})
```

Returns the last-used discrete style in the path. If one was not used, returns `SimpleCornerStyle()`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L485-L492' class='documenter-source'>source</a><br>

<a id='Devices.Paths.contstyle1' href='#Devices.Paths.contstyle1'>#</a>
**`Devices.Paths.contstyle1`** &mdash; *Function*.



```
contstyle1(p::Path)
```

Returns the last-used discrete style in the path. If one was not used, returns `p.style0`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L495-L502' class='documenter-source'>source</a><br>


<a id='Path-building-1'></a>

## Path building

<a id='Base.append!-Tuple{Devices.Paths.Path,Devices.Paths.Path}' href='#Base.append!-Tuple{Devices.Paths.Path,Devices.Paths.Path}'>#</a>
**`Base.append!`** &mdash; *Method*.



```
append!(p::Path, p′::Path)
```

Given paths `p` and `p′`, path `p′` is appended to path `p`. The p0 and initial angle of the first segment from path `p′` is modified to match the last point and last angle of path `p`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L648-L656' class='documenter-source'>source</a><br>

<a id='Devices.Paths.adjust!' href='#Devices.Paths.adjust!'>#</a>
**`Devices.Paths.adjust!`** &mdash; *Function*.



```
adjust!(p::Path, n::Integer=1)
```

Adjust a path's parametric functions starting from index `n`. Used internally whenever segments are inserted into the path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L505-L512' class='documenter-source'>source</a><br>

<a id='Devices.Paths.attach!' href='#Devices.Paths.attach!'>#</a>
**`Devices.Paths.attach!`** &mdash; *Function*.



```
attach!(p::Path, c::CellReference, t::Real; i::Integer=length(p), where::Integer=0)
```

Attach `c` along a path.

By default, the attachment occurs at `t ∈ [0,1]` along the most recent path segment, but a different path segment index can be specified using `i`. The reference is oriented with zero rotation if the path is pointing at 0°, otherwise it is rotated with the path.

The origin of the cell reference tells the method where to place the cell *with respect to a coordinate system that rotates with the path*. Suppose the path is a straight line with angle 0°. Then an origin of `Point(0.,10.)` will put the cell at 10 above the path, or 10 to the left of the path if it turns left by 90°.

The `where` option is for convenience. If `where == 0`, nothing special happens. If `where == -1`, then the point of attachment for the reference is on the leftmost edge of the waveguide (the rendered polygons; the path itself has no width). Likewise if `where == 1`, the point of attachment is on the rightmost edge. This option does not automatically rotate the cell reference, apart from what is already done as described in the first paragraph. You can think of this option as setting a special origin for the coordinate system that rotates with the path. For instance, an origin for the cell reference of `Point(0.,10.)` together with `where == -1` will put the cell at 10 above the edge of a rendered (finite width) path with angle 0°.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/contstyles/decorated.jl#L59-L87' class='documenter-source'>source</a><br>

<a id='Devices.Paths.corner!' href='#Devices.Paths.corner!'>#</a>
**`Devices.Paths.corner!`** &mdash; *Function*.



```
corner!{T<:Coordinate}(p::Path{T}, α, sty::DiscreteStyle=discretestyle1(p))
```

Append a sharp turn or "corner" to path `p` with angle `α`.

The style chosen for this corner, if not specified, is the last `DiscreteStyle` used in the path, or `SimpleCornerStyle` if one has not been used yet.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/corner.jl#L57-L66' class='documenter-source'>source</a><br>

<a id='Devices.Paths.meander!' href='#Devices.Paths.meander!'>#</a>
**`Devices.Paths.meander!`** &mdash; *Function*.



```
meander!{T<:Real}(p::Path{T}, len, r, straightlen, α::Real)
```

Alternate between going straight with length `straightlen` and turning with radius `r` and angle `α`. Each turn goes the opposite direction of the previous. The total length is `len`. Useful for making resonators.

The straight and turn segments are combined into a `CompoundSegment` and appended to the path `p`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L706-L717' class='documenter-source'>source</a><br>

<a id='Devices.Paths.param' href='#Devices.Paths.param'>#</a>
**`Devices.Paths.param`** &mdash; *Function*.



```
param{T<:Coordinate}(c::AbstractVector{Segment{T}})
```

Return a parametric function over the domain [0,1] that represents the compound segments.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/compound.jl#L56-L63' class='documenter-source'>source</a><br>

<a id='Devices.Paths.simplify' href='#Devices.Paths.simplify'>#</a>
**`Devices.Paths.simplify`** &mdash; *Function*.



```
simplify(p::Path, inds::UnitRange=1:length(p))
```

At `inds`, segments of a path are turned into a `CompoundSegment` and styles of a path are turned into a `CompoundStyle`. The method returns a tuple, `(segment, style)`.

  * Indexing the path becomes more sane when you can combine several path

segments into one logical element. A launcher would have several indices in a path unless you could simplify it.

  * You don't need to think hard about boundaries between straights and turns

when you want a continuous styling of a very long path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L666-L680' class='documenter-source'>source</a><br>

<a id='Devices.Paths.simplify!' href='#Devices.Paths.simplify!'>#</a>
**`Devices.Paths.simplify!`** &mdash; *Function*.



```
simplify!(p::Path, inds::UnitRange=1:length(p))
```

In-place version of [`simplify`](paths.md#Devices.Paths.simplify).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L687-L693' class='documenter-source'>source</a><br>

<a id='Devices.Paths.straight!' href='#Devices.Paths.straight!'>#</a>
**`Devices.Paths.straight!`** &mdash; *Function*.



```
straight!{T<:Coordinate}(p::Path{T}, l::Coordinate,
    sty::ContinuousStyle=contstyle1(p))
```

Extend a path `p` straight by length `l` in the current direction. By default, we take the last continuous style in the path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/straight.jl#L73-L81' class='documenter-source'>source</a><br>

<a id='Devices.Paths.turn!' href='#Devices.Paths.turn!'>#</a>
**`Devices.Paths.turn!`** &mdash; *Function*.



```
turn!{T<:Coordinate}(p::Path{T}, α, r::Coordinate, sty::Style=style1(p))
```

Turn a path `p` by angle `α` with a turning radius `r` in the current direction. Positive angle turns left.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/turn.jl#L87-L94' class='documenter-source'>source</a><br>


```
turn!{T<:Coordinate}(p::Path{T}, s::String, r::Coordinate,
    sty::ContinuousStyle=contstyle1(p))
```

Turn a path `p` with direction coded by string `s`:

  * "l": turn by π/2 radians (left)
  * "r": turn by -π/2 radians (right)
  * "lrlrllrrll": do those turns in that order

By default, we take the last continuous style in the path.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/segments/turn.jl#L104-L117' class='documenter-source'>source</a><br>


<a id='Attachments-1'></a>

## Attachments


When you call [`attach!`](paths.md#Devices.Paths.attach!), you are defining a coordinate system local to somewhere along the target `Path`, saying that a `CellReference` should be placed at the origin of that coordinate system (or slightly away from it if you want the cell to be one one side of the path or the other). The local coordinate system will rotate as the path changes orientations. The origin of the `CellReference` corresponds how the referenced cell should be displaced with respect to the origin of the local coordinate system. This differs from the usual meaning of the origin of a `CellReference`, which is how the referenced cell should be displaced with respect to the origin of a containing `Cell`.


The same `CellReference` can be attached to multiple points along multiple paths. If the cell reference is modified (e.g. rotation, origin, magnification) before rendering, the changes should be reflected at all attachment points. The attachment of the cell reference is in some sense an abstraction: a `CellReference` must ultimately live inside a `Cell`, but an unrendered `Path` does not live inside any cell. If the path is modified further before rendering, the attachment points should follow the path modifications, moving the origins of the local coordinate systems. The origin fields of the cell references do not change as the path is modified.


Attachments are implemented by introducing a [`Paths.DecoratedStyle`](paths.md#Devices.Paths.DecoratedStyle), which is kind of a meta-`Style`: it remembers where to attach `CellReferences`, but how the path itself is actually drawn is deferred to a different `Style` object that it retains a reference to. One can repeat a `DecoratedStyle` with one attachment to achieve a periodic placement of `CellReferences` (like a `CellArray`, but along the path). Or, one long segment with a `DecoratedStyle` could have several attachments to achieve a similar effect.


When a `Path` is rendered, it is turned into `Polygons` living in some `Cell`. The attachments remain `CellReferences`, now living inside of a `Cell` and not tied to an abstract path. The notion of local coordinate systems along the path no longer makes sense because the abstract path has been made concrete, and the polygons are living in the coordinate system of the containing cell. Each attachment to the former path now must have its origin referenced to the origin of the containing cell, not to local path coordinate systems. Additionally, the references may need to rotate according to how the path was locally oriented. As a result, even if the same `CellReference` was attached multiple times to a path, now we need distinct `CellReference` objects for each attachment, as well as for each time a corresponding `DecoratedStyle` is rendered.


Suppose we want the ability to transform between coordinate systems, especially between the coordinate system of a referenced cell and the coordinate system of a parent cell. At first glance it would seem like we could simply define a transform function, taking the parent cell and the cell reference we are interested in. But how would we actually identify the particular cell reference we want? Looking in the tree of references for an attached `CellReference` will not work: distinct `CellReferences` needed to be made after the path was rendered, and so the particular `CellReference` object initially attached is not actually in the `Cell` containing the rendered path.


To overcome this problem, we make searching for the appropriate `CellReference` easier. Suppose a path with attachments has been rendered to a `Cell`, which is bound to symbol `aaa`. A `CellReference` referring to a cell named "bbb" was attached twice. To recall the second attachment: `aaa["bbb",2]` (the index defaults to 1 if unspecified). We can go deeper if we want to refer to references inside that attachment: `aaa["bbb",2]["ccc"]`. In this manner, it is easy to find the right `CellReference` to use with [`Cells.transform(::Cell, ::Cells.CellRef)`](cells.md#CoordinateTransformations.transform-Tuple{Devices.Cells.Cell,Devices.Cells.CellRef}).


<a id='Interfacing-with-gdspy-1'></a>

## Interfacing with gdspy


The Python package `gdspy` is used for rendering paths into polygons. Ultimately we intend to remove this dependency.

<a id='Devices.Paths.distance' href='#Devices.Paths.distance'>#</a>
**`Devices.Paths.distance`** &mdash; *Function*.



For a style `s` and parameteric argument `t`, returns the distance between the centers of parallel paths rendered by gdspy.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L69-L72' class='documenter-source'>source</a><br>

<a id='Devices.Paths.extent' href='#Devices.Paths.extent'>#</a>
**`Devices.Paths.extent`** &mdash; *Function*.



For a style `s` and parameteric argument `t`, returns a distance tangential to the path specifying the lateral extent of the polygons rendered by gdspy.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L75-L78' class='documenter-source'>source</a><br>

<a id='Devices.Paths.paths' href='#Devices.Paths.paths'>#</a>
**`Devices.Paths.paths`** &mdash; *Function*.



For a style `s` and parameteric argument `t`, returns the number of parallel paths rendered by gdspy.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L81-L84' class='documenter-source'>source</a><br>

<a id='Devices.Paths.width' href='#Devices.Paths.width'>#</a>
**`Devices.Paths.width`** &mdash; *Function*.



For a style `s` and parameteric argument `t`, returns the width of paths rendered by gdspy.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/b265e030b50d7d4008d97446dd5b5e07e51cfca5/src/paths/paths.jl#L87-L90' class='documenter-source'>source</a><br>

