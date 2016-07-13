Cells are used to logically group polygons or references to other cells
into a single entity.

```@docs
    Cell
    Cell(::AbstractString)
    Cell{T<:Real}(::AbstractString, ::AbstractArray{Devices.AbstractPolygon{T},1})
    Cell{T<:Real}(::AbstractString, ::AbstractArray{Devices.AbstractPolygon{T},1},
        ::AbstractArray{CellReference,1})
    bounds(::Cell)
    center(::Cell)
```
## Referenced and arrayed cells

Cells can be arrayed or referenced within other cells for efficiency or to reduce
display complexity.

```@docs
    CellArray
    CellArray{T<:Real}(::Cell, ::Point{2,T}, ::Point{2,T}, ::Point{2,T},
        ::Integer, ::Integer)
    CellArray{T<:Real}(::Cell, ::Range{T}, ::Range{T})
    CellReference
    CellReference{T<:Real}(::Cell, ::Point{2,T})
    bounds{S<:Real, T<:Real}(::CellArray{Cell{S},T})
    bounds(::CellReference)
```
## Resolving references

In some cases it may be desirable to resolve cell references or arrays into their
corresponding polygons. This operation is called "flattening."
```@docs
    flatten!
    flatten
```

## Miscellaneous

When saving cells to disk, there will be a tree of interdependencies and logically
one would prefer to write the leaf nodes of the tree before any dependent cells.
These functions are used to traverse the tree and then find the optimal ordering.
```@docs
    traverse!
    order!
```
