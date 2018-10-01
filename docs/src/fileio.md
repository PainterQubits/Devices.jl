To save or load patterns in any format, make sure you are `using FileIO`.

## Saving patterns

This package can load/save patterns in the GDS-II format for use with e-beam lithography
systems. In the future it may be useful to implement machine-specific pattern formats to
force fracturing or dosing in an explicit manner.

```@docs
    save(::File{format"GDS"}, ::Cell, ::Cell...)
```

Using the [Cairo graphics library](https://cairographics.org), it is possible to save
patterns into SVG, PDF, and EPS vector graphics formats, or into the PNG raster graphic
format. This enables patterns to be displayed in web browsers, publications, presentations,
and so on. You can save a cell to a graphics file by, e.g. `save("/path/to/file.svg", mycell)`.
Possible keyword arguments include:

- `width`: Specifies the width parameter of the SVG tag. Defaults to the width of the cell
  bounding box (stripped of units).
- `height`: Specifies the height parameter of the SVG tag. Defaults to the height of the
  cell bounding box (stripped of units).
- `layercolors`: Should be a dictionary with `Int` keys for layers and color strings
  as values. By color strings we mean "#ff0000", "red", "rgb(255,0,0)", etc.

## Loading patterns

```@docs
    load(::File{format"GDS"})
```
