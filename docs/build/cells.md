
<a id='Cells-1'></a>

## Cells


Cells are used to logically group polygons or references to other cells into a single entity.

<a id='Devices.Cells.Cell' href='#Devices.Cells.Cell'>#</a>
**`Devices.Cells.Cell`** &mdash; *Type*.



```
type Cell{T<:Coordinate}
    name::String
    elements::Vector{Polygon{T}}
    refs::Vector{CellRef}
    create::DateTime
    Cell(x,y,z,t) = new(x, y, z, t)
    Cell(x,y,z) = new(x, y, z, now())
    Cell(x,y) = new(x, y, CellRef[], now())
    Cell(x) = new(x, Polygon{T}[], CellRef[], now())
    Cell() = begin
        c = new()
        c.elements = Polygon{T}[]
        c.refs = CellRef[]
        c.create = now()
        c
    end
end
```

A cell has a name and contains polygons and references to `CellArray` or `CellReference` objects. It also records the time of its own creation. As currently implemented it mirrors the notion of cells in GDS-II files.

To add elements, push them to `elements` field (or use `render!`); to add references, push them to `refs` field.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L95-L122' class='documenter-source'>source</a><br>


The type of a cell can be thought of as the database unit.

<a id='Devices.Cells.Cell-Tuple{AbstractString}' href='#Devices.Cells.Cell-Tuple{AbstractString}'>#</a>
**`Devices.Cells.Cell`** &mdash; *Method*.



```
Cell(name::AbstractString)
```

Convenience constructor for `Cell{typeof(1.0u"nm")}`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L274-L280' class='documenter-source'>source</a><br>

<a id='Devices.Cells.Cell-Tuple{AbstractString,AbstractArray{Devices.AbstractPolygon{T<:Real},1}}' href='#Devices.Cells.Cell-Tuple{AbstractString,AbstractArray{Devices.AbstractPolygon{T<:Real},1}}'>#</a>
**`Devices.Cells.Cell`** &mdash; *Method*.



```
Cell{T<:AbstractPolygon}(name::AbstractString, elements::AbstractVector{T})
```

Convenience constructor for `Cell{T}`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L283-L289' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Cells.Cell{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}}}' href='#Devices.bounds-Tuple{Devices.Cells.Cell{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds{T<:Coordinate}(cell::Cell{T}; kwargs...)
```

Returns a `Rectangle` bounding box with no properties around all objects in `cell`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L367-L373' class='documenter-source'>source</a><br>

<a id='Devices.center-Tuple{Devices.Cells.Cell}' href='#Devices.center-Tuple{Devices.Cells.Cell}'>#</a>
**`Devices.center`** &mdash; *Method*.



```
center(cell::Cell)
```

Convenience method, equivalent to `center(bounds(cell))`. Returns the center of the bounding box of the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L400-L407' class='documenter-source'>source</a><br>

<a id='Devices.Cells.name-Tuple{Devices.Cells.Cell}' href='#Devices.Cells.name-Tuple{Devices.Cells.Cell}'>#</a>
**`Devices.Cells.name`** &mdash; *Method*.



```
name(x::Cell)
```

Returns the name of the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L532-L538' class='documenter-source'>source</a><br>

<a id='Devices.Cells.dbscale-Tuple{Devices.Cells.Cell{T}}' href='#Devices.Cells.dbscale-Tuple{Devices.Cells.Cell{T}}'>#</a>
**`Devices.Cells.dbscale`** &mdash; *Method*.



```
dbscale{T}(c::Cell{T})
```

Give the database scale for a cell. The database scale is the smallest increment of length that will be represented in the output CAD file.

For `Cell{T<:Length}`, the database scale is `T(1)`. For floating-point lengths, this means that anything after the decimal point will be rounded off. For this reason, Cell{typeof(1.0nm)} is probably the most convenient type to work with.

The database scale of a `Cell{T<:Real}` is assumed to be `1nm` (`1.0nm` if `T <: AbstractFloat`) because insufficient information is provided to know otherwise.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L145-L161' class='documenter-source'>source</a><br>

<a id='Devices.Cells.dbscale-Tuple{Devices.Cells.Cell,Devices.Cells.Cell,Vararg{Devices.Cells.Cell,N}}' href='#Devices.Cells.dbscale-Tuple{Devices.Cells.Cell,Devices.Cells.Cell,Vararg{Devices.Cells.Cell,N}}'>#</a>
**`Devices.Cells.dbscale`** &mdash; *Method*.



```
dbscale(cell::Cell...)
```

Choose an appropriate database scale for a GDSII file given [`Cell`](cells.md#Devices.Cells.Cell)s of different types. The smallest database scale of all cells considered is returned.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L164-L171' class='documenter-source'>source</a><br>


<a id='Referenced-and-arrayed-cells-1'></a>

## Referenced and arrayed cells


Cells can be arrayed or referenced within other cells for efficiency or to reduce display complexity.

<a id='Devices.Cells.CellArray' href='#Devices.Cells.CellArray'>#</a>
**`Devices.Cells.CellArray`** &mdash; *Type*.



```
type CellArray{S,T} <: CellRef{S,T}
    cell::T
    origin::Point{S}
    deltacol::Point{S}
    deltarow::Point{S}
    col::Int
    row::Int
    xrefl::Bool
    mag::Float64
    rot::Float64
end
```

Array of `cell` starting at `origin` with `row` rows and `col` columns, spanned by vectors `deltacol` and `deltarow`. Optional x-reflection `xrefl`, magnification factor `mag`, and rotation angle `rot` for the array as a whole. If an angle is given without units it is assumed to be in radians.

The type variable `T` is to avoid circular definitions with `Cell`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L56-L77' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellArray-Tuple{Any,Devices.Points.Point{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Devices.Points.Point{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Devices.Points.Point{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Real,Real}' href='#Devices.Cells.CellArray-Tuple{Any,Devices.Points.Point{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Devices.Points.Point{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Devices.Points.Point{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Real,Real}'>#</a>
**`Devices.Cells.CellArray`** &mdash; *Method*.



```
CellArray{T<:Coordinate}(x, origin::Point{T}, dc::Point{T},
    dr::Point{T}, c::Integer, r::Integer; xrefl=false, mag=1.0, rot=0.0)
```

Construct a `CellArray{T,typeof(x)}` object, with `xrefl`, `mag`, and `rot` as keyword arguments (x-reflection, magnification factor, rotation in degrees).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L241-L249' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellArray-Tuple{Any,Range{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Range{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}}}' href='#Devices.Cells.CellArray-Tuple{Any,Range{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}},Range{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}}}'>#</a>
**`Devices.Cells.CellArray`** &mdash; *Method*.



```
CellArray{T<:Coordinate}(x, c::Range{T}, r::Range{T};
    xrefl=false, mag=1.0, rot=0.0)
```

Construct a `CellArray{T,typeof(x)}` based on ranges (probably `LinSpace` or `FloatRange`). `c` specifies column coordinates and `r` for the rows. Pairs from `c` and `r` specify the origins of the repeated cells. The extrema of the ranges therefore do not specify the extrema of the resulting `CellArray`'s bounding box; some care is required.

`xrefl`, `mag`, and `rot` are keyword arguments (x-reflection, magnification factor, rotation in degrees).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L254-L268' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellReference' href='#Devices.Cells.CellReference'>#</a>
**`Devices.Cells.CellReference`** &mdash; *Type*.



```
type CellReference{S,T} <: CellRef{S,T}
    cell::T
    origin::Point{S}
    xrefl::Bool
    mag::Float64
    rot::Float64
end
```

Reference to a `cell` positioned at `origin`, with optional x-reflection `xrefl`, magnification factor `mag`, and rotation angle `rot`. If an angle is given without units it is assumed to be in radians.

The type variable `T` is to avoid circular definitions with `Cell`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L25-L41' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellReference' href='#Devices.Cells.CellReference'>#</a>
**`Devices.Cells.CellReference`** &mdash; *Type*.



```
CellReference{T<:Coordinate}(x, y::Point{T}=Point(0.,0.); kwargs...
```

Convenience constructor for `CellReference{typeof(x), T}`.

Keyword arguments can specify x-reflection, magnification, or rotation. Synonyms are accepted, in case you forget the "correct keyword"...

X-reflection:

  * `:xrefl`
  * `:xreflection`
  * `:refl`
  * `:reflect`
  * `:xreflect`
  * `:xmirror`
  * `:mirror`

Magnification:

  * `:mag`
  * `:magnification`
  * `:magnify`
  * `:zoom`
  * `:scale`

Rotation:

  * `:rot`
  * `:rotation`
  * `:rotate`
  * `:angle`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L175-L206' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Cells.CellArray{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}},Devices.Cells.Cell{S<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}}}}' href='#Devices.bounds-Tuple{Devices.Cells.CellArray{T<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}},Devices.Cells.Cell{S<:Union{Real,Unitful.DimensionedQuantity{Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)}}}}}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(ref::CellArray; kwargs...)
```

Returns a `Rectangle` bounding box with properties specified by `kwargs...` around all objects in `ref`. The bounding box respects reflection, rotation, and magnification specified by `ref`.

Please do rewrite this method when feeling motivated... it is very inefficient.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L410-L420' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Cells.CellReference}' href='#Devices.bounds-Tuple{Devices.Cells.CellReference}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(ref::CellReference; kwargs...)
```

Returns a `Rectangle` bounding box with properties specified by `kwargs...` around all objects in `ref`. The bounding box respects reflection, rotation, and magnification specified by `ref`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L441-L449' class='documenter-source'>source</a><br>

<a id='Base.copy-Tuple{Devices.Cells.CellReference}' href='#Base.copy-Tuple{Devices.Cells.CellReference}'>#</a>
**`Base.copy`** &mdash; *Method*.



```
copy(x::CellReference)
```

Creates a shallow copy of `x` (does not copy the referenced cell).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L310-L316' class='documenter-source'>source</a><br>

<a id='Base.copy-Tuple{Devices.Cells.CellArray}' href='#Base.copy-Tuple{Devices.Cells.CellArray}'>#</a>
**`Base.copy`** &mdash; *Method*.



```
copy(x::CellArray)
```

Creates a shallow copy of `x` (does not copy the arrayed cell).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L320-L326' class='documenter-source'>source</a><br>

<a id='Devices.Cells.name-Tuple{Devices.Cells.CellReference}' href='#Devices.Cells.name-Tuple{Devices.Cells.CellReference}'>#</a>
**`Devices.Cells.name`** &mdash; *Method*.



```
name(x::CellReference)
```

Returns the name of the referenced cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L550-L556' class='documenter-source'>source</a><br>

<a id='Devices.Cells.name-Tuple{Devices.Cells.CellArray}' href='#Devices.Cells.name-Tuple{Devices.Cells.CellArray}'>#</a>
**`Devices.Cells.name`** &mdash; *Method*.



```
name(x::CellArray)
```

Returns the name of the arrayed cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L541-L547' class='documenter-source'>source</a><br>


<a id='Resolving-references-1'></a>

## Resolving references


Sometimes it can be helpful to go between coordinate systems of cells and the cells they reference. This package provides methods to generate affine transforms to do this as easily as possible.

<a id='CoordinateTransformations.transform-Tuple{Devices.Cells.Cell,Devices.Cells.CellRef}' href='#CoordinateTransformations.transform-Tuple{Devices.Cells.Cell,Devices.Cells.CellRef}'>#</a>
**`CoordinateTransformations.transform`** &mdash; *Method*.



```
transform(c::Cell, d::CellRef)
```

Given a Cell `c` containing [`CellReference`](cells.md#Devices.Cells.CellReference) or [`CellArray`](cells.md#Devices.Cells.CellArray) `d` in its tree of references, this function returns a `CoordinateTransformations.AffineMap` object that lets you translate from the coordinate system of `d` to the coordinate system of `c`.

If the *same exact* `CellReference` or `CellArray` (as in `===`, same address in memory) is included multiple times in the tree of references, then the resulting transform will be based on the first time it is encountered. The tree is traversed one level at a time to find the reference (optimized for shallow references).

Example: You want to translate (2.0,3.0) in the coordinate system of the referenced cell to the coordinate system of `c`.

```jlcon
julia> trans = transform(c,d)

julia> trans(Point(2.0,3.0))
```


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L594-L618' class='documenter-source'>source</a><br>


In some cases it may be desirable to resolve cell references or arrays into their corresponding polygons. This operation is called "flattening."

<a id='Devices.Cells.flatten!' href='#Devices.Cells.flatten!'>#</a>
**`Devices.Cells.flatten!`** &mdash; *Function*.



`flatten!(c::Cell)`

All cell references and arrays are turned into polygons and added to cell `c`. The references and arrays are then removed. This "flattening" of the cell is recursive: references in referenced cells are flattened too. The modified cell is returned.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L477-L484' class='documenter-source'>source</a><br>

<a id='Devices.Cells.flatten' href='#Devices.Cells.flatten'>#</a>
**`Devices.Cells.flatten`** &mdash; *Function*.



`flatten{T<:Coordinate}(c::Cell{T})`

All cell references and arrays are resolved into polygons, recursively. Together with the polygons already in cell `c`, an array of polygons (type `AbstractPolygon{T}`) is returned. The cell `c` remains unmodified.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L461-L467' class='documenter-source'>source</a><br>


`flatten(c::CellReference)`

Cell reference `c` is resolved into polygons, recursively. An array of polygons (type `AbstractPolygon`) is returned. The cell reference `c` remains unmodified.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L491-L496' class='documenter-source'>source</a><br>


`flatten(c::CellArray)`

Cell array `c` is resolved into polygons, recursively. An array of polygons (type `AbstractPolygon`) is returned. The cell array `c` remains unmodified.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L510-L515' class='documenter-source'>source</a><br>


<a id='Miscellaneous-1'></a>

## Miscellaneous


When saving cells to disk, there will be a tree of interdependencies and logically one would prefer to write the leaf nodes of the tree before any dependent cells. These functions are used to traverse the tree and then find the optimal ordering.

<a id='Devices.Cells.traverse!' href='#Devices.Cells.traverse!'>#</a>
**`Devices.Cells.traverse!`** &mdash; *Function*.



```
traverse!(a::AbstractArray, c::Cell, level=1)
```

Given a cell, recursively traverse its references for other cells and add to array `a` some tuples: `(level, c)`. `level` corresponds to how deep the cell was found, and `c` is the found cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L559-L567' class='documenter-source'>source</a><br>

<a id='Devices.Cells.order!' href='#Devices.Cells.order!'>#</a>
**`Devices.Cells.order!`** &mdash; *Function*.



```
order!(a::AbstractArray)
```

Given an array of tuples like that coming out of [`traverse!`](cells.md#Devices.Cells.traverse!), we sort by the `level`, strip the level out, and then retain unique entries. The aim of this function is to determine an optimal writing order when saving pattern data (although the GDS-II spec does not require cells to be in a particular order, there may be performance ramifications).

For performance reasons, this function modifies `a` but what you want is the returned result array.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/183856efb0a3d8cd89111991bbe16370a7482d30/src/cells.jl#L575-L588' class='documenter-source'>source</a><br>

