## Render methods

```@docs
    render!
```

### Rectangle rendering styles

```@docs
    Rectangles.Plain
    Rectangles.Rounded
    Rectangles.Undercut
```

### Polygon rendering styles

```@docs
    Polygons.Plain
```

## Rendering arbitrary paths

A `Segment` and `Style` together define one or more closed curves in the plane.
The job of rendering is to approximate these curves by closed polygons. To enable rendering
of styles along generic paths in the plane, an adaptive algorithm is used when no other
method is available:

```@docs
    Devices.adapted_grid
```

In some cases, custom rendering methods are implemented when it would improve performance
for simple structures or when special attention is required. The rendering methods can
specialize on either the `Segment` or `Style` types, or both.
