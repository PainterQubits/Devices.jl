This package can load/save patterns in the GDS-II format only. In the future it
may be useful to implement machine-specific pattern formats to force fracturing
or dosing in an explicit manner.

## Loading patterns

To load a pattern, make sure you are `using FileIO`.

```@docs
    load(::File{format"GDS"})
```

## Saving patterns

To save a pattern, make sure you are `using FileIO`.

```@docs
    save(::File{format"GDS"}, ::Cell, ::Cell...)
```

## Internals

```@docs
    GDS.GDSFloat
    GDS64
    bits(::GDS64)
    bswap(::GDS64)
    GDS.gdswrite
    GDS.strans
    write(::IO, ::GDS64)
    read(::IO, ::Type{GDS64})
```
