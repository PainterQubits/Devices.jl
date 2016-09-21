## Paths

```@docs
    Paths.Path
    Paths.Path{T<:Real}(::Point{T})
    Paths.pathlength(::Path)
```
## Segments

```@docs
    Paths.Segment
    Paths.Straight
    Paths.Turn
    Paths.Corner
    Paths.CompoundSegment
```

## Styles

```@docs
    Paths.Style
    Paths.ContinuousStyle
    Paths.DiscreteStyle
    Paths.Trace
    Paths.CPW
    Paths.CompoundStyle
    Paths.DecoratedStyle
    Paths.undecorated
```
## Path interrogation

```@docs
    Paths.direction
    Paths.pathlength
    Paths.p0
    Paths.setp0!
    Paths.α0
    Paths.setα0!
    Paths.p1
    Paths.α1
    Paths.style0
    Paths.style1
```
## Path building

```@docs
    append!(::Path, ::Path)
    adjust!
    attach!
    meander!
    param
    simplify
    simplify!
    straight!
    turn!
```

## Attachments

When you call [`attach!`](@ref), you are defining a coordinate system local to
somewhere along the target `Path`, saying that a `CellReference` should be
placed at the origin of that coordinate system (or slightly away from it if you
want the cell to be one one side of the path or the other). The local
coordinate system will rotate as the path changes orientations. The origin of
the `CellReference` corresponds how the referenced cell should be displaced
with respect to the origin of the local coordinate system. This differs from
the usual meaning of the origin of a `CellReference`, which is how the
referenced cell should be displaced with respect to the origin of a containing
`Cell`.

The same `CellReference` can be attached to multiple points along multiple
paths. If the cell reference is modified (e.g. rotation, origin, magnification)
before rendering, the changes should be reflected at all attachment points. The
attachment of the cell reference is in some sense an abstraction: a
`CellReference` must ultimately live inside a `Cell`, but an unrendered `Path`
does not live inside any cell. If the path is modified further before rendering,
the attachment points should follow the path modifications, moving the origins
of the local coordinate systems. The origin fields of the cell references do not
change as the path is modified.

Attachments are implemented by introducing a [`Paths.DecoratedStyle`](@ref), which is
kind of a meta-`Style`: it remembers where to attach `CellReferences`, but how
the path itself is actually drawn is deferred to a different `Style` object that
it retains a reference to. One can repeat a `DecoratedStyle` with one attachment
to achieve a periodic placement of `CellReferences` (like a `CellArray`, but
along the path). Or, one long segment with a `DecoratedStyle` could have several
attachments to achieve a similar effect.

When a `Path` is rendered, it is turned into `Polygons` living in some `Cell`.
The attachments remain `CellReferences`, now living inside of a `Cell` and not
tied to an abstract path. The notion of local coordinate systems along the path
no longer makes sense because the abstract path has been made concrete, and the
polygons are living in the coordinate system of the containing cell. Each
attachment to the former path now must have its origin referenced to the origin
of the containing cell, not to local path coordinate systems. Additionally, the
references may need to rotate according to how the path was locally oriented.
As a result, even if the same `CellReference` was attached multiple times to a
path, now we need distinct `CellReference` objects for each attachment, as well
as for each time a corresponding `DecoratedStyle` is rendered.

Suppose we want the ability to transform between coordinate systems, especially
between the coordinate system of a referenced cell and the coordinate system of
a parent cell. At first glance it would seem like we could simply define a
transform function, taking the parent cell and the cell reference we are
interested in. But how would we actually identify the particular cell reference
we want? Looking in the tree of references for an attached `CellReference` will
not work: distinct `CellReferences` needed to be made after the path was rendered,
and so the particular `CellReference` object initially attached is not actually in
the `Cell` containing the rendered path.

To overcome this problem, we make searching for the appropriate `CellReference`
easier. Suppose a path with attachments has been rendered to a `Cell`, which is
bound to symbol `aaa`. A `CellReference` referring to a cell named "bbb" was
attached twice. To recall the second attachment: `aaa["bbb",2]` (the index
defaults to 1 if unspecified). We can go deeper if we want to refer to references
inside that attachment: `aaa["bbb",2]["ccc"]`. In this manner, it is easy
to find the right `CellReference` to use with [`Cells.transform(::Cell, ::Cells.CellRef)`](@ref).

## Interfacing with gdspy

The Python package `gdspy` is used for rendering paths into polygons. Ultimately
we intend to remove this dependency.

```@docs
    Paths.distance
    Paths.extent
    Paths.paths
    Paths.width
```
