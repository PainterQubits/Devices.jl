A [`Paths.Path`](@ref) is an ordered collection of [`Paths.Node`](@ref)s, each of which
has a [`Paths.Segment`](@ref) and a [`Paths.Style`](@ref). The nodes are linked to each
other, so each node knows what the previous and next nodes are.

## Segments

Each subtype of `Segment` can represent a class of parametric functions
`t->Point(x(t),y(t))`. By "class" we mean e.g. [`Paths.Straight`](@ref) or [`Paths.Turn`](@ref),
which are used frequently. Instances of these subtypes of `Segment` have some captured
variables to specify a particular path in the plane. Instances of `Turn`, for example, will
capture an initial and final angle, a radius, and an origin. All circular turns may be
parameterized with these variables.

!!! note
    This package assumes that the parametric functions are
    implemented such that $\sqrt{((dx/dt)^2 + (dy/dt)^2)} = 1$. In other words, `t` ranges
    from zero to the path length of the segment.

## Styles

Each subtype of `Style` describes how to render a segment. You can create the most common
styles using the constructors [`Paths.Trace`](@ref) (a trace with some width) and
[`Paths.CPW`](@ref) (a coplanar waveguide style).

One can implement new styles by writing methods for [`render!`](@ref) that dispatch on
different style types. In this way, the rendering code can be specialized for the task at
hand, improving performance and shrinking generated file sizes (ideally).

### Tapers

As a convenience, this package provides functions for the automatic tapering
of both [`Paths.Trace`](@ref) and [`Paths.CPW`](@ref) via the [`Paths.Taper`](@ref)
constructor. Alternatively, one can specify the tapers concretely by calling
their respective constructors.

The following example illustrates the use of automatic tapering. First, we
construct a taper with two different traces surrounding it:

```@example 1
using Devices, Devices.PreferMicrons, FileIO # hide

p = Path(μm)
straight!(p, 10μm, Paths.Trace(2.0μm))
straight!(p, 10μm, Paths.Taper())
straight!(p, 10μm, Paths.Trace(4.0μm))
```

The taper is automatically chosen to be a `Paths.Trace`, with appropriate initial
(`2.0 μm`) and final (`4.0 μm`) widths. The next segment shows that we can
even automatically taper between the current `Paths.Trace` and a hard-coded taper
(of concrete type [`Paths.TaperTrace`](@ref)), matching to the dimensions at the
beginning of the latter taper.

```@example 1
straight!(p, 10μm, Paths.Taper())
straight!(p, 10μm, Paths.TaperTrace(2.0μm, 1.0μm))
```

As a final example, `Paths.Taper` can also be used in [`turn!`](@ref) segments, and
as a way to automatically transition from a `Paths.Taper` to a `Paths.CPW`, or vice-versa:

```@example 1
turn!(p, -π/2, 10μm, Paths.Taper())
straight!(p, 10μm, Paths.Trace(2.0μm))
straight!(p, 10μm, Paths.Taper())
straight!(p, 10μm, Paths.CPW(2.0μm, 1.0μm))

c = Cell("tapers", nm)
render!(c, p, GDSMeta(0))
```

## Corners

Sharp turns in a path can be accomplished with [`Paths.corner!`](@ref). Sharp turns pose a
challenge to the path abstraction in that they have zero length, and when rendered
effectively take up some length of the neighboring segments. Originally, the segment lengths
were tweaked at render time to achieve the intended output. As other code began taking
advantage of the path abstractions, the limitations of this approach became apparent.

Currently, corners are implemented such that the preceding [`Paths.Node`](@ref) is split
using [`Paths.split`](@ref) near the corner when `corner!` is used, and a short resulting
section near the corner has the style changed to [`Paths.SimpleNoRender`](@ref).
When this is followed by [`Paths.straight!`](@ref) to create the next segment, a similar
operation is done, to ensure the corner is not twice-rendered. This change was necessary
to be able to use [`Paths.intersect!`](@ref) on paths with corners.

## Attachments

[`attach!`](@ref) is one of the most useful functions defined in this package.

When you call `attach!`, you are defining a coordinate system local to somewhere along the
target `Path`, saying that a `CellReference` should be placed at the origin of that
coordinate system (or slightly away from it if you want the cell to be one one side of the
path or the other). The local coordinate system will rotate as the path changes
orientations. The origin of the `CellReference` corresponds how the referenced cell should
be displaced with respect to the origin of the local coordinate system. This differs from
the usual meaning of the origin of a `CellReference`, which is how the referenced cell
should be displaced with respect to the origin of a containing `Cell`.

The same `CellReference` can be attached to multiple points along multiple paths. If the
cell reference is modified (e.g. rotation, origin, magnification) before rendering, the
changes should be reflected at all attachment points. The attachment of the cell reference
is not a perfect abstraction: a `CellReference` must ultimately live inside a `Cell`, but
an unrendered `Path` does not live inside any cell. If the path is modified further before
rendering, the attachment points will follow the path modifications, moving the origins of
the local coordinate systems. The origin fields of the cell references do not change as the
path is modified.

Attachments are implemented by introducing a [`Paths.DecoratedStyle`](@ref), which is kind
of a meta-`Style`: it remembers where to attach `CellReferences`, but how the path itself is
actually drawn is deferred to a different `Style` object that it retains a reference to. One
can repeat a `DecoratedStyle` with one attachment to achieve a periodic placement of
`CellReferences` (like a `CellArray`, but along the path). Or, one long segment with a
`DecoratedStyle` could have several attachments to achieve a similar effect.

When a `Path` is rendered, it is turned into `Polygons` living in some `Cell`. The
attachments remain `CellReferences`, now living inside of a `Cell` and not tied to an
abstract path. The notion of local coordinate systems along the path no longer makes sense
because the abstract path has been made concrete, and the polygons are living in the
coordinate system of the containing cell. Each attachment to the former path now must have
its origin referenced to the origin of the containing cell, not to local path coordinate
systems. Additionally, the references may need to rotate according to how the path was
locally oriented. As a result, even if the same `CellReference` was attached multiple times
to a path, now we need distinct `CellReference` objects for each attachment, as well as for
each time a corresponding `DecoratedStyle` is rendered.

Suppose we want the ability to transform between coordinate systems, especially between the
coordinate system of a referenced cell and the coordinate system of a parent cell. At first
glance it would seem like we could simply define a transform function, taking the parent
cell and the cell reference we are interested in. But how would we actually identify the
particular cell reference we want? Looking in the tree of references for an attached
`CellReference` will not work: distinct `CellReferences` needed to be made after the path
was rendered, and so the particular `CellReference` object initially attached is not
actually in the `Cell` containing the rendered path.

To overcome this problem, we make searching for the appropriate `CellReference` easier.
Suppose a path with attachments has been rendered to a `Cell`, which is bound to symbol
`aaa`. A `CellReference` referring to a cell named "bbb" was attached twice. To recall the
second attachment: `aaa["bbb",2]` (the index defaults to 1 if unspecified). We can go deeper
if we want to refer to references inside that attachment: `aaa["bbb",2]["ccc"]`. In this
manner, it is easy to find the right `CellReference` to use with
[`Cells.transform(::Cell, ::Cells.CellRef)`](@ref).

## Intersections

How to do the right thing when paths intersect is often tedious. [`Paths.intersect!`](@ref)
provides a useful function to modify existing paths automatically to account for
intersections according to intersection styles ([`Paths.IntersectStyle`](@ref)). Since this
is done prior to rendering, further modification can be done easily. Both self-intersections
and pairwise intersections can be handled for any reasonable number of paths.

For now, one intersection style is implemented, but the heavy-lifting to add more has been
done already. Here's an example (consult API docs below for further information):

```@example 1
pa1 = Path(μm)
turn!(pa1, -360°, 100μm, Paths.CPW(10μm, 6μm))
pa2 = Path(Point(0,100)μm, α0=-90°)
straight!(pa2, 400μm, Paths.CPW(10μm, 6μm))
turn!(pa2, 270°, 200μm)
straight!(pa2, 400μm)

bridgemetas = GDSMeta.(20:30)
intersect!(Paths.Bridges(bridgemetas=bridgemetas, gap=2μm, footlength=2μm), pa1, pa2;
    interactions=[true true; false true])

c = Cell("test", nm)
render!(c, pa1, GDSMeta(0))
render!(c, pa2, GDSMeta(1))
save("intersect_circle.svg", flatten(c); layercolors=merge(Devices.Graphics.layercolors, Dict(1=>(0,0,0,1)))); nothing # hide
```
<img src="../intersect_circle.svg" style="width:4in;"/>

Here's another example:

```@example 1
pa = Path(μm, α0=90°)
straight!(pa, 100μm, Paths.Trace(2μm))
corner!(pa, 90°, Paths.SimpleTraceCorner())
let L = 4μm
    for i in 1:50

    straight!(pa, L)
    corner!(pa, 90°, Paths.SimpleTraceCorner())
    L += 4μm
    end
end
straight!(pa, 4μm)

c = Cell("test", nm)

bridgemetas = GDSMeta.(20:30)
intersect!(Paths.Bridges(bridgemetas=bridgemetas, gap=2μm, footlength=1μm), pa)

render!(c, pa, GDSMeta(1))
save("intersect_spiral.svg", flatten(c); layercolors=merge(Devices.Graphics.layercolors, Dict(1=>(0,0,0,1)))); nothing # hide
```
<img src="../intersect_spiral.svg" style="width:4in;"/>

## Path API

### Path construction

```@docs
    Paths.Path
```
### Path interrogation

```@docs
    Paths.direction
    Paths.pathlength
    Paths.p0
    Paths.α0
    Paths.p1
    Paths.α1
    Paths.style0
    Paths.style1
    Paths.discretestyle1
    Paths.contstyle1
```
### Path manipulation

```@docs
    Paths.setp0!
    Paths.setα0!
    append!(::Path, ::Path)
    attach!
    corner!
    intersect!
    meander!
    reconcile!
    simplify
    simplify!
    straight!
    terminate!
    turn!
```

### Path intersection styles

```@docs
    Paths.IntersectStyle
    Paths.Bridges
```

## Node API

### Node construction

```@docs
    Paths.Node
```

### Node methods

```@docs
    Paths.previous
    Paths.next
    Paths.segment
    Paths.split(::Paths.Node, ::Devices.Coordinate)
    Paths.style
    Paths.setsegment!
    Paths.setstyle!
```

## Segment API

### Abstract types

```@docs
    Paths.Segment
```

### Concrete types

```@docs
    Paths.Straight
    Paths.Turn
    Paths.Corner
    Paths.CompoundSegment
```

## Style API

### Style construction

```@docs
    Paths.Trace
    Paths.CPW
    Paths.Taper
    Paths.Strands
    Paths.NoRender
```

### Style manipulation

```@docs
    Paths.pin
    Paths.translate
    Paths.undecorated
```

### Abstract types

```@docs
    Paths.Style
    Paths.ContinuousStyle
    Paths.DiscreteStyle
```

### Concrete types

```@docs
    Paths.SimpleNoRender
    Paths.SimpleTrace
    Paths.GeneralTrace
    Paths.SimpleCPW
    Paths.GeneralCPW
    Paths.TaperTrace
    Paths.TaperCPW
    Paths.SimpleStrands
    Paths.GeneralStrands
    Paths.CompoundStyle
    Paths.DecoratedStyle
```
