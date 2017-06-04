Cells are used to logically group polygons or references to other cells
into a single entity. They can contain references to other cells or arrays of
other cells. They also store polygons. Here is the definition of a `Cell`:

```@docs
    Cell
```

The type parameter `S` of a `Cell{S,T}` object is used in two ways:

1. Determine the units of the coordinates of all polygons in a cell, as well
   as origins and offset vectors of [`CellArray`](@ref)s and
   [`CellReference`](@ref)s.
2. Determine whether the cell will contain integer coordinates or floating-point
   coordinates. Currently, you cannot do a whole lot (particularly with regard
   to paths) if the cell has integer coordinates. However, they do have an
   inherent advantage because the coordinates are exact, and ultimately the
   GDS-II file represents shapes with integer coordinates. In the future,
   we intend to improve support for cells with integer coordinates.

For instance, `Cell{typeof(1.0u"nm")}` matches a cell where the database
unit is `nm` and polygons may have `Float64`-based coordinates (the type of
`1.0` is `Float64`). Note that `Cell{typeof(2.0u"nm")}` does not mean the database
unit is 2.0nm, because the returned type is the same. If that is intended,
instead make a new unit such that one of that new unit is equal to 2nm. You can
do this using the `@unit` macro in Unitful.

For most cases, if you want to use units, `Cell("my_cell_name", nm)`
is a good way to construct a cell which will ultimately have all coordinates
rounded to the nearest `nm` when exported into GDS-II. You can add polygons
with whatever length units you want to such a cell, and the coordinates will
be converted automatically to `nm`. You can change `nm` to `pm` or `fm` or
whatever, but this will limit the pattern extent and probably doesn't
make sense anyway.

If you don't want units, just construct the cell with a name only:
`Cell("my_cell_name")` will return a `Cell{Float64}` object. In this case too,
the ultimate database resolution is `1nm`; until exporting the cell into a GDS-II
file, the coordinates are interpreted to be in units of `1μm`. This behavior
cannot be changed for cells without units.

## Cell API

```@docs
    Cell(::AbstractString)
    bounds{T<:Devices.Coordinate}(::Cell{T})
    center(::Cell)
    name(::Cell)
    Cells.dbscale{T}(::Cell{T})
    Cells.dbscale(::Cell, ::Cell, ::Cell...)
```
## Referenced and arrayed cells

Cells can be arrayed or referenced within other cells for efficiency or to reduce
display complexity.

```@docs
    CellArray
    CellArray{T<:Devices.Coordinate}(::Any, ::Point{T})
    CellArray{T<:Devices.Coordinate}(::Any, ::Range{T}, ::Range{T})
    CellReference
    CellReference{T<:Devices.Coordinate}(::Any, ::Point{T}=Point(0.,0.))
    bounds{S<:Devices.Coordinate, T<:Devices.Coordinate}(::CellArray{T, Cell{S}})
    bounds(::CellReference)
    copy(::CellReference)
    copy(::CellArray)
    name(::CellReference)
    name(::CellArray)
    uniquename
```
## Resolving references

Sometimes it can be helpful to go between coordinate systems of cells and the
cells they reference. This package provides methods to generate affine transforms
to do this as easily as possible.

```@docs
    transform(::Cell, ::Cells.CellRef)
```

In some cases it may be desirable to resolve cell references or arrays into their
corresponding polygons. This operation is called "flattening."
```@docs
    flatten!
    flatten
```

## Miscellaneous

When saving cells to disk, keep in mind that cells should have unique names.
We don't have an automatic renaming scheme implemented to avoid clashes. To
help with this, we provide a function [`uniquename`](@ref) to generate unique
names based on human-readable prefixes.

When saving cells to disk, there will be a tree of interdependencies and logically
one would prefer to write the leaf nodes of the tree before any dependent cells.
These functions are used to traverse the tree and then find the optimal ordering.
```@docs
    traverse!
    order!
```
