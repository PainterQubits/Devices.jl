
<a id='Cells-1'></a>

## Cells


Cells are used to logically group polygons or references to other cells into a single entity. They can contain references to other cells or arrays of other cells. They also store polygons. Here is the definition of a `Cell`:

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


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L112-L139' class='documenter-source'>source</a><br>


The type parameter of a `Cell{T}` object is used in two ways:


1. Determine the units of the coordinates of all polygons in a cell, as well as origins and offset vectors of [`CellArray`](cells.md#Devices.Cells.CellArray)s and [`CellReference`](cells.md#Devices.Cells.CellReference)s.
2. Determine whether the cell will contain integer coordinates or floating-point coordinates. Currently, you cannot do a whole lot (particularly with regard to paths) if the cell has integer coordinates. However, they do have an inherent advantage because the coordinates are exact, and ultimately the GDS-II file represents shapes with integer coordinates. In the future, we intend to improve support for cells with integer coordinates.


For instance, `Cell{typeof(1.0u"nm")}` specifies a cell where the database unit is `nm` and polygons may have `Float64`-based coordinates (the type of `1.0` is `Float64`). Note that `Cell{typeof(2.0u"nm")}` does not mean the database unit is 2.0nm, because the returned type is the same. If that is intended, instead make a new unit such that one of that new unit is equal to 2nm. You can do this using the `@unit` macro in Unitful.


For most cases, if you want to use units, `Cell{typeof(1.0u"nm")}("my_cell_name")` is a good way to construct a cell which will ultimately have all coordinates rounded to the nearest `nm` when exported into GDS-II. You can add polygons with whatever length units you want to such a cell, and the coordinates will be converted automatically to `nm`. You can change `nm` to `pm` or `fm` or whatever, but this will limit the pattern extent and probably doesn't make sense anyway.


If you don't want units, just construct the cell with a name only: `Cell("my_cell_name")` will return a `Cell{Float64}` object. In this case too, the ultimate database resolution is `1nm`; until exporting the cell into a GDS-II file, the coordinates are interpreted to be in units of `1μm`. This behavior cannot be changed for cells without units.


<a id='Cell-API-1'></a>

## Cell API

<a id='Devices.Cells.Cell-Tuple{AbstractString}' href='#Devices.Cells.Cell-Tuple{AbstractString}'>#</a>
**`Devices.Cells.Cell`** &mdash; *Method*.



```
Cell(name::AbstractString)
```

Convenience constructor for `Cell{typeof(1.0u"nm")}`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L396-L402' class='documenter-source'>source</a><br>

<a id='Devices.Cells.Cell-Tuple{AbstractString,AbstractArray{Devices.AbstractPolygon{T<:Real},1}}' href='#Devices.Cells.Cell-Tuple{AbstractString,AbstractArray{Devices.AbstractPolygon{T<:Real},1}}'>#</a>
**`Devices.Cells.Cell`** &mdash; *Method*.



```
Cell{T<:AbstractPolygon}(name::AbstractString, elements::AbstractVector{T})
```

Convenience constructor for `Cell{T}`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L405-L411' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Cells.Cell{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}' href='#Devices.bounds-Tuple{Devices.Cells.Cell{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds{T<:Coordinate}(cell::Cell{T}; kwargs...)
```

Returns a `Rectangle` bounding box with no properties around all objects in `cell`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L489-L495' class='documenter-source'>source</a><br>

<a id='Devices.center-Tuple{Devices.Cells.Cell}' href='#Devices.center-Tuple{Devices.Cells.Cell}'>#</a>
**`Devices.center`** &mdash; *Method*.



```
center(cell::Cell)
```

Convenience method, equivalent to `center(bounds(cell))`. Returns the center of the bounding box of the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L522-L529' class='documenter-source'>source</a><br>

<a id='Devices.Cells.name-Tuple{Devices.Cells.Cell}' href='#Devices.Cells.name-Tuple{Devices.Cells.Cell}'>#</a>
**`Devices.Cells.name`** &mdash; *Method*.



```
name(x::Cell)
```

Returns the name of the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L656-L662' class='documenter-source'>source</a><br>

<a id='Devices.Cells.dbscale-Tuple{Devices.Cells.Cell{T}}' href='#Devices.Cells.dbscale-Tuple{Devices.Cells.Cell{T}}'>#</a>
**`Devices.Cells.dbscale`** &mdash; *Method*.



```
dbscale{T}(c::Cell{T})
```

Give the database scale for a cell. The database scale is the smallest increment of length that will be represented in the output CAD file.

For `Cell{T<:Length}`, the database scale is `T(1)`. For floating-point lengths, this means that anything after the decimal point will be rounded off. For this reason, Cell{typeof(1.0nm)} is probably the most convenient type to work with.

The database scale of a `Cell{T<:Real}` is assumed to be `1nm` (`1.0nm` if `T <: AbstractFloat`) because insufficient information is provided to know otherwise.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L164-L180' class='documenter-source'>source</a><br>

<a id='Devices.Cells.dbscale-Tuple{Devices.Cells.Cell,Devices.Cells.Cell,Vararg{Devices.Cells.Cell,N}}' href='#Devices.Cells.dbscale-Tuple{Devices.Cells.Cell,Devices.Cells.Cell,Vararg{Devices.Cells.Cell,N}}'>#</a>
**`Devices.Cells.dbscale`** &mdash; *Method*.



```
dbscale(cell::Cell...)
```

Choose an appropriate database scale for a GDSII file given [`Cell`](cells.md#Devices.Cells.Cell)s of different types. The smallest database scale of all cells considered is returned.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L183-L190' class='documenter-source'>source</a><br>


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


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L73-L94' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellArray-Tuple{Any,Devices.Points.Point{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}' href='#Devices.Cells.CellArray-Tuple{Any,Devices.Points.Point{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}'>#</a>
**`Devices.Cells.CellArray`** &mdash; *Method*.



```
CellArray{T<:Coordinate}(x, origin::Point{T}, dc::Point{T},
    dr::Point{T}, c::Integer, r::Integer; xrefl=false, mag=1.0, rot=0.0)
```

Construct a `CellArray{T,typeof(x)}` object.

Keyword arguments specify the column vector, row vector, number of columns, number of rows, x-reflection, magnification factor, and rotation. Synonyms are accepted for these keywords:

  * Column vector: `:deltacol`, `:dcol`, `:dc`, `:vcol`, `:colv`, `:colvec`, `:colvector`, `:columnv`, `:columnvec`, `:columnvector`
  * Row vector: `:deltarow`, `:drow`, `:dr`, `:vrow`, `:rv`, `:rowvec`, `:rowvector`
  * Number of columns: `:nc`, `:numcols`, `:numcol`, `:ncols`, `:ncol`
  * Number of rows: `:nr`, `:numrows`, `:numrow`, `:nrows`, `:nrow`
  * X-reflection: `:xrefl`, `:xreflection`, `:refl`, `:reflect`, `:xreflect`, `:xmirror`, `:mirror`
  * Magnification: `:mag`, `:magnification`, `:magnify`, `:zoom`, `:scale`
  * Rotation: `:rot`, `:rotation`, `:rotate`, `:angle`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L243-L266' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellArray-Tuple{Any,Range{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}},Range{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}' href='#Devices.Cells.CellArray-Tuple{Any,Range{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}},Range{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}'>#</a>
**`Devices.Cells.CellArray`** &mdash; *Method*.



```
CellArray{T<:Coordinate}(x, c::Range{T}, r::Range{T}; kwargs...)
```

Construct a `CellArray{T,typeof(x)}` based on ranges (probably `LinSpace` or `FloatRange`). `c` specifies column coordinates and `r` for the rows. Pairs from `c` and `r` specify the origins of the repeated cells. The extrema of the ranges therefore do not specify the extrema of the resulting `CellArray`'s bounding box; some care is required.

Keyword arguments specify x-reflection, magnification factor, and rotation, with synonyms allowed:

  * X-reflection: `:xrefl`, `:xreflection`, `:refl`, `:reflect`, `:xreflect`, `:xmirror`, `:mirror`
  * Magnification: `:mag`, `:magnification`, `:magnify`, `:zoom`, `:scale`
  * Rotation: `:rot`, `:rotation`, `:rotate`, `:angle`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L339-L358' class='documenter-source'>source</a><br>

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


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L41-L57' class='documenter-source'>source</a><br>

<a id='Devices.Cells.CellReference' href='#Devices.Cells.CellReference'>#</a>
**`Devices.Cells.CellReference`** &mdash; *Type*.



```
CellReference{T<:Coordinate}(x, y::Point{T}=Point(0.,0.); kwargs...
```

Convenience constructor for `CellReference{typeof(x), T}`.

Keyword arguments can specify x-reflection, magnification, or rotation. Synonyms are accepted, in case you forget the "correct keyword"...

  * X-reflection: `:xrefl`, `:xreflection`, `:refl`, `:reflect`, `:xreflect`, `:xmirror`, `:mirror`
  * Magnification: `:mag`, `:magnification`, `:magnify`, `:zoom`, `:scale`
  * Rotation: `:rot`, `:rotation`, `:rotate`, `:angle`


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L194-L208' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Cells.CellArray{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}},Devices.Cells.Cell{S<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}}' href='#Devices.bounds-Tuple{Devices.Cells.CellArray{T<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}},Devices.Cells.Cell{S<:Union{Real,Unitful.Quantity{T,Unitful.Dimensions{(Unitful.Dimension{:Length}(1//1),)},U}}}}}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(ref::CellArray; kwargs...)
```

Returns a `Rectangle` bounding box with properties specified by `kwargs...` around all objects in `ref`. The bounding box respects reflection, rotation, and magnification specified by `ref`.

Please do rewrite this method when feeling motivated... it is very inefficient.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L532-L542' class='documenter-source'>source</a><br>

<a id='Devices.bounds-Tuple{Devices.Cells.CellReference}' href='#Devices.bounds-Tuple{Devices.Cells.CellReference}'>#</a>
**`Devices.bounds`** &mdash; *Method*.



```
bounds(ref::CellReference; kwargs...)
```

Returns a `Rectangle` bounding box with properties specified by `kwargs...` around all objects in `ref`. The bounding box respects reflection, rotation, and magnification specified by `ref`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L563-L571' class='documenter-source'>source</a><br>

<a id='Base.copy-Tuple{Devices.Cells.CellReference}' href='#Base.copy-Tuple{Devices.Cells.CellReference}'>#</a>
**`Base.copy`** &mdash; *Method*.



```
copy(x::CellReference)
```

Creates a shallow copy of `x` (does not copy the referenced cell).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L432-L438' class='documenter-source'>source</a><br>

<a id='Base.copy-Tuple{Devices.Cells.CellArray}' href='#Base.copy-Tuple{Devices.Cells.CellArray}'>#</a>
**`Base.copy`** &mdash; *Method*.



```
copy(x::CellArray)
```

Creates a shallow copy of `x` (does not copy the arrayed cell).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L442-L448' class='documenter-source'>source</a><br>

<a id='Devices.Cells.name-Tuple{Devices.Cells.CellReference}' href='#Devices.Cells.name-Tuple{Devices.Cells.CellReference}'>#</a>
**`Devices.Cells.name`** &mdash; *Method*.



```
name(x::CellReference)
```

Returns the name of the referenced cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L674-L680' class='documenter-source'>source</a><br>

<a id='Devices.Cells.name-Tuple{Devices.Cells.CellArray}' href='#Devices.Cells.name-Tuple{Devices.Cells.CellArray}'>#</a>
**`Devices.Cells.name`** &mdash; *Method*.



```
name(x::CellArray)
```

Returns the name of the arrayed cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L665-L671' class='documenter-source'>source</a><br>

<a id='Devices.Cells.uniquename' href='#Devices.Cells.uniquename'>#</a>
**`Devices.Cells.uniquename`** &mdash; *Function*.



```
uniquename(str)
```

Given string input `str`, generate a unique name that bears some resemblance to `str`. Useful if programmatically making Cells and all of them will eventually be saved into a GDS-II file. The uniqueness is expected on a per-Julia session basis, so if you load an existing GDS-II file and try to save unique cells on top of that you may get an unlucky clash.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L24-L34' class='documenter-source'>source</a><br>


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


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L718-L742' class='documenter-source'>source</a><br>


In some cases it may be desirable to resolve cell references or arrays into their corresponding polygons. This operation is called "flattening."

<a id='Devices.Cells.flatten!' href='#Devices.Cells.flatten!'>#</a>
**`Devices.Cells.flatten!`** &mdash; *Function*.



`flatten!(c::Cell)`

All cell references and arrays are turned into polygons and added to cell `c`. The references and arrays are then removed. This "flattening" of the cell is recursive: references in referenced cells are flattened too. The modified cell is returned.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L599-L606' class='documenter-source'>source</a><br>

<a id='Devices.Cells.flatten' href='#Devices.Cells.flatten'>#</a>
**`Devices.Cells.flatten`** &mdash; *Function*.



`flatten{T<:Coordinate}(c::Cell{T})`

All cell references and arrays are resolved into polygons, recursively. Together with the polygons already in cell `c`, an array of polygons (type `AbstractPolygon{T}`) is returned. The cell `c` remains unmodified.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L583-L589' class='documenter-source'>source</a><br>


`flatten(c::CellReference)`

Cell reference `c` is resolved into polygons, recursively. An array of polygons (type `AbstractPolygon`) is returned. The cell reference `c` remains unmodified.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L613-L618' class='documenter-source'>source</a><br>


`flatten(c::CellArray)`

Cell array `c` is resolved into polygons, recursively. An array of polygons (type `AbstractPolygon`) is returned. The cell array `c` remains unmodified.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L633-L638' class='documenter-source'>source</a><br>


<a id='Miscellaneous-1'></a>

## Miscellaneous


When saving cells to disk, keep in mind that cells should have unique names. We don't have an automatic renaming scheme implemented to avoid clashes. To help with this, we provide a function [`uniquename`](cells.md#Devices.Cells.uniquename) to generate unique names based on human-readable prefixes.


When saving cells to disk, there will be a tree of interdependencies and logically one would prefer to write the leaf nodes of the tree before any dependent cells. These functions are used to traverse the tree and then find the optimal ordering.

<a id='Devices.Cells.traverse!' href='#Devices.Cells.traverse!'>#</a>
**`Devices.Cells.traverse!`** &mdash; *Function*.



```
traverse!(a::AbstractArray, c::Cell, level=1)
```

Given a cell, recursively traverse its references for other cells and add to array `a` some tuples: `(level, c)`. `level` corresponds to how deep the cell was found, and `c` is the found cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L683-L691' class='documenter-source'>source</a><br>

<a id='Devices.Cells.order!' href='#Devices.Cells.order!'>#</a>
**`Devices.Cells.order!`** &mdash; *Function*.



```
order!(a::AbstractArray)
```

Given an array of tuples like that coming out of [`traverse!`](cells.md#Devices.Cells.traverse!), we sort by the `level`, strip the level out, and then retain unique entries. The aim of this function is to determine an optimal writing order when saving pattern data (although the GDS-II spec does not require cells to be in a particular order, there may be performance ramifications).

For performance reasons, this function modifies `a` but what you want is the returned result array.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/cells.jl#L699-L712' class='documenter-source'>source</a><br>

