This package can load/save patterns in the GDS-II format for use with e-beam lithography
systems. In the future it may be useful to implement machine-specific pattern formats to
force fracturing or dosing in an explicit manner.

We also provide an experimental option to export to the SVG vector graphics format. This
enables patterns to be inspected in web browsers or used in presentations, for example.

## Saving patterns

To save a pattern in any format, make sure you are `using` `FileIO`.

```@docs
    save(::File{format"GDS"}, ::Cell, ::Cell...)
    save(::File{format"SVG"}, ::Cell)
```

## Loading patterns

To load a pattern in any format, make sure you are `using` `FileIO`.

```@docs
    load(::File{format"GDS"})
    load(::File{format"SVG"})
```
