module Cells

import Compat.String

using AffineTransforms
import AffineTransforms: transform

using ..Points
using ..Rectangles
using ..Polygons

import Base: show, +, -, copy, getindex
import Devices: AbstractPolygon, bounds, center, center!
export Cell, CellArray, CellReference
export traverse!, order!, flatten, flatten!, transform, name

abstract CellRef{S, T<:Real}

"""
```
type CellReference{S,T} <: CellRef{S,T}
    cell::S
    origin::Point{T}
    xrefl::Bool
    mag::Float64
    rot::Float64
end
```

Reference to a `cell` positioned at `origin`, with optional x-reflection
`xrefl`, magnification factor `mag`, and rotation angle `rot` in degrees.

The type variable `S` is to avoid circular definitions with `Cell`.
"""
type CellReference{S,T} <: CellRef{S,T}
    cell::S
    origin::Point{T}
    xrefl::Bool
    mag::Float64
    rot::Float64
end

"""
```
type CellArray{S,T} <: CellRef{S,T}
    cell::S
    origin::Point{T}
    deltacol::Point{T}
    deltarow::Point{T}
    col::Int
    row::Int
    xrefl::Bool
    mag::Float64
    rot::Float64
end
```

Array of `cell` starting at `origin` with `row` rows and `col` columns,
spanned by vectors `deltacol` and `deltarow`. Optional x-reflection
`xrefl`, magnification factor `mag`, and rotation angle `rot` in degrees
are for the array as a whole.

The type variable `S` is to avoid circular definitions with `Cell`.
"""
type CellArray{S,T} <: CellRef{S,T}
    cell::S
    origin::Point{T}
    deltacol::Point{T}
    deltarow::Point{T}
    col::Int
    row::Int
    xrefl::Bool
    mag::Float64
    rot::Float64
end

"""
```
type Cell{T<:Real}
    name::String
    elements::Array{AbstractPolygon{T},1}
    refs::Array{CellRef,1}
    create::DateTime
    Cell(x,y,z) = new(x, y, z, now())
    Cell(x,y) = new(x, y, CellRef[], now())
    Cell(x) = new(x, AbstractPolygon{T}[], CellRef[], now())
    Cell() = begin
        c = new()
        c.elements = AbstractPolygon{T}[]
        c.refs = CellRef[]
        c.create = now()
        c
    end
end
```

A cell has a name and contains polygons and references to `CellArray` or
`CellReference` objects. It also records the time of its own creation. As
currently implemented it mirrors the notion of cells in GDS-II files.

In the future, it may make sense to generalize the idea and permit
`Path` objects within a Cell.

To add elements, push them to `elements` field (or use `render!`);
to add references, push them to `refs` field.
"""
type Cell{T<:Real}
    name::String
    elements::Array{AbstractPolygon{T},1}
    refs::Array{CellRef,1}
    create::DateTime
    Cell(x,y,z) = new(x, y, z, now())
    Cell(x,y) = new(x, y, CellRef[], now())
    Cell(x) = new(x, AbstractPolygon{T}[], CellRef[], now())
    Cell() = begin
        c = new()
        c.elements = AbstractPolygon{T}[]
        c.refs = CellRef[]
        c.create = now()
        c
    end
end

"""
```
CellReference{T<:Real}(x::Cell, y::Point{T}=Point(0.,0.);
    xrefl=false, mag=1.0, rot=0.0)
```

Convenience constructor for `CellReference{typeof(x), T}`.
"""
CellReference{T<:Real}(x, origin::Point{T}=Point(0.,0.); xrefl=false,
    mag=1.0, rot=0.0) = CellReference{typeof(x), T}(x, origin, xrefl, mag, rot)

"""
```
CellArray{T<:Real}(x::Cell, origin::Point{T}, dc::Point{T}, dr::Point{T},
    c::Integer, r::Integer; xrefl=false, mag=1.0, rot=0.0)
```

Construct a `CellArray{typeof(x),T}` object, with `xrefl`, `mag`, and `rot` as
keyword arguments (x-reflection, magnification factor, rotation in degrees).
"""
CellArray{T<:Real}(x::Cell, origin::Point{T}, dc::Point{T}, dr::Point{T},
    c::Real, r::Real; xrefl=false, mag=1.0, rot=0.0) =
    CellArray{typeof(x),T}(x,origin,dc,dr,c,r,xrefl,mag,rot)

"""
```
CellArray{T<:Real}(x::Cell, c::Range{T}, r::Range{T};
    xrefl=false, mag=1.0, rot=0.0)
```

Construct a `CellArray{typeof(x), T}` based on ranges (probably `LinSpace` or
`FloatRange`). `c` specifies column coordinates and `r` for the rows. Pairs from
`c` and `r` specify the origins of the repeated cells. The extrema of the ranges
therefore do not specify the extrema of the resulting `CellArray`'s bounding box;
some care is required.

`xrefl`, `mag`, and `rot` are keyword arguments
(x-reflection, magnification factor, rotation in degrees).
"""
CellArray{T<:Real}(x::Cell, c::Range{T}, r::Range{T};
    xrefl=false, mag=1.0, rot=0.0) =
    CellArray{typeof(x),T}(x, Point(first(c),first(r)), Point(step(c),zero(step(c))),
        Point(zero(step(r)), step(r)), length(c), length(r), xrefl, mag, rot)

"""
```
Cell(name::AbstractString)
```

Convenience constructor for `Cell{Float64}`.
"""
Cell(name::AbstractString) = Cell{Float64}(name)

"""
```
Cell{T<:Real}(name::AbstractString, elements::AbstractArray{AbstractPolygon{T},1})
```

Convenience constructor for `Cell{T}`.
"""
Cell{T<:Real}(name::AbstractString, elements::AbstractArray{AbstractPolygon{T},1}) =
    Cell{T}(name, elements)

"""
```
Cell{T<:Real}(name::AbstractString, elements::AbstractArray{AbstractPolygon{T},1},
    refs::AbstractArray{CellReference,1})
```

Convenience constructor for `Cell{T}`.
"""
Cell{T<:Real}(name::AbstractString, elements::AbstractArray{AbstractPolygon{T},1},
    refs::AbstractArray{CellReference,1}) =
    Cell{T}(name, elements, refs)

# Don't print out everything in the cell, it is a mess that way.
show(io::IO, c::Cell) = print(io,
    "Cell \"$(c.name)\" with $(length(c.elements)) els, $(length(c.refs)) refs")

"""
```
copy(x::CellReference)
```

Creates a shallow copy of `x` (does not copy the referenced cell).
"""
copy(x::CellReference) = CellReference(x.cell, x.origin,
    xrefl=x.xrefl, mag=x.mag, rot=x.rot)

"""
```
copy(x::CellArray)
```

Creates a shallow copy of `x` (does not copy the arrayed cell).
"""
copy(x::CellArray) = CellArray(x.cell, x.origin, x.deltacol, x.deltarow,
    x.col, x.row, x.xrefl, x.mag, x.rot)

"""
```
getindex(c::Cell, nom::AbstractString, index::Integer=1)
```

If `c` references a cell with name `nom`, this method will return the
corresponding `CellReference`. If there are several references to that cell,
then `index` specifies which one is returned (in the order they are found in
`c.refs`). e.g. to specify an index of 2: `mycell["myreferencedcell",2]`.
"""
function getindex(c::Cell, nom::AbstractString, index::Integer=1)
    inds = find(x->name(x)==nom, c.refs)
    c.refs[inds[index]]
end

"""
```
getindex(c::CellRef, nom::AbstractString, index::Integer=1)
```

If the cell referenced by `c` references a cell with name `nom`, this method
will return the corresponding `CellReference`. If there are several references
to that cell, then `index` specifies which one is returned (in the order they
are found in `c.refs`).

This method is typically used so that we can type the first line instead of the
second line in the following:
```
mycell["myreferencedcell"]["onedeeper"]
mycell["myreferencedcell"].cell["onedeeper"]
```
"""
function getindex(c::CellRef, nom::AbstractString, index::Integer=1)
    inds = find(x->name(x)==nom, c.cell.refs)
    c.cell.refs[inds[index]]
end

"""
```
bounds(cell::Cell; kwargs...)
```

Returns a `Rectangle` bounding box with no properties around all objects in `cell`.
"""
function bounds{T<:Real}(cell::Cell{T}; kwargs...)
    mi, ma = Point(typemax(T), typemax(T)), Point(typemin(T), typemin(T))
    bfl{S<:Integer}(::Type{S}, x) = floor(x)
    bfl(S,x) = x
    bce{S<:Integer}(::Type{S}, x) = ceil(x)
    bce(S,x) = x

    isempty(cell.elements) && isempty(cell.refs) &&
        return Rectangle(mi, ma; kwargs...)

    for el in cell.elements
        b = bounds(el)
        mi, ma = min(mi,minimum(b)), max(ma,maximum(b))
    end

    for el in cell.refs
        # The referenced cells may not return the same Rectangle{T} type.
        # We should grow to accommodate if necessary.
        br = bounds(el)
        b = Rectangle{T}(bfl(T, br.ll), bce(T, br.ur))
        mi, ma = min(mi,minimum(b)), max(ma,maximum(b))
    end

    Rectangle(mi, ma; kwargs...)
end

"""
```
center(cell::Cell)
```

Convenience method, equivalent to `center(bounds(cell))`.
Returns the center of the bounding box of the cell.
"""
center(cell::Cell) = center(bounds(cell))

"""
```
bounds(ref::CellArray; kwargs...)
```

Returns a `Rectangle` bounding box with properties specified by `kwargs...`
around all objects in `ref`. The bounding box respects reflection, rotation, and
magnification specified by `ref`.

Please do rewrite this method when feeling motivated... it is very inefficient.
"""
function bounds{S<:Real, T<:Real}(ref::CellArray{Cell{S},T}; kwargs...)
    b = bounds(ref.cell)::Rectangle{S}
    !isproper(b) && return b

    # The following code block is very inefficient
    lls = [(b.ll + (i-1) * ref.deltarow + (j-1) * ref.deltacol)::Point{promote_type(S,T)}
            for i in 1:(ref.row), j in 1:(ref.col)]
    urs = lls .+ Point(width(b), height(b))
    mb = Rectangle(minimum(lls[1:end]), maximum(urs[1:end]))

    sgn = ref.xrefl ? -1 : 1
    a = AffineTransform(
        [sgn*ref.mag*cosd(ref.rot) -ref.mag*sind(ref.rot);
         sgn*ref.mag*sind(ref.rot) ref.mag*cosd(ref.rot)], ref.origin)
    c = a * convert(Polygon{Float64}, mb)
    bounds(c; kwargs...)
end

"""
```
bounds(ref::CellReference; kwargs...)
```

Returns a `Rectangle` bounding box with properties specified by `kwargs...`
around all objects in `ref`. The bounding box respects reflection, rotation,
and magnification specified by `ref`.
"""
function bounds(ref::CellReference; kwargs...)
    b = bounds(ref.cell)
    !isproper(b) && return b
    sgn = ref.xrefl ? -1 : 1
    a = AffineTransform(
        [sgn*ref.mag*cosd(ref.rot) -ref.mag*sind(ref.rot);
         sgn*ref.mag*sind(ref.rot) ref.mag*cosd(ref.rot)], ref.origin)
    c = a * convert(Polygon{Float64}, b)
    bounds(c; kwargs...)
end

"""
`flatten{T<:Real}(c::Cell{T})`

All cell references and arrays are resolved into polygons, recursively.
Together with the polygons already in cell `c`, an array of polygons
(type `AbstractPolygon{T}`) is returned. The cell `c` remains unmodified.
"""
function flatten{T<:Real}(c::Cell{T})
    polys = AbstractPolygon{T}[]
    append!(polys, c.elements)
    for r in c.refs
        append!(polys, flatten(r))
    end
    polys
end

"""
`flatten!(c::Cell)`

All cell references and arrays are turned into polygons and added to cell `c`.
The references and arrays are then removed. This "flattening" of the cell is
recursive: references in referenced cells are flattened too. The modified cell
is returned.
"""
function flatten!(c::Cell)
    c.elements = flatten(c)
    empty!(c.refs)
    c
end

"""
`flatten(c::CellReference)`

Cell reference `c` is resolved into polygons, recursively. An array of polygons
(type `AbstractPolygon`) is returned. The cell reference `c` remains unmodified.
"""
function flatten(c::CellReference)
    polys = AbstractPolygon[]
    sgn = c.xrefl ? -1 : 1
    a = AffineTransform(
        [sgn*c.mag*cosd(c.rot) -c.mag*sind(c.rot);
         sgn*c.mag*sind(c.rot) c.mag*cosd(c.rot)], c.origin)
    append!(polys, a .* c.cell.elements)
    for r in c.cell.refs
        append!(polys, a .* flatten(r))
    end
    polys
end

"""
`flatten(c::CellArray)`

Cell array `c` is resolved into polygons, recursively. An array of polygons
(type `AbstractPolygon`) is returned. The cell array `c` remains unmodified.
"""
function flatten(c::CellArray)
    polys = AbstractPolygon[]
    sgn = c.xrefl ? -1 : 1
    a = AffineTransform(
        [sgn*c.mag*cosd(c.rot) -c.mag*sind(c.rot);
         sgn*c.mag*sind(c.rot) c.mag*cosd(c.rot)], c.origin)
    for i in 1:c.row, j in 1:c.col
        pt = (i-1) * c.deltarow + (j-1) * c.deltacol
        append!(polys, a .* (c.cell.elements .+ pt))
        for r in c.cell.refs
            append!(polys, a .* (flatten(r) .+ pt))
        end
    end
    polys
end

"""
```
name(x::Cell)
```

Returns the name of the cell.
"""
name(x::Cell) = x.name

"""
```
name(x::CellArray)
```

Returns the name of the arrayed cell.
"""
name(x::CellArray) = name(x.cell)

"""
```
name(x::CellReference)
```

Returns the name of the referenced cell.
"""
name(x::CellReference) = name(x.cell)

"""
```
traverse!(a::AbstractArray, c::Cell, level=1)
```

Given a cell, recursively traverse its references for other cells and add
to array `a` some tuples: `(level, c)`. `level` corresponds to how deep the cell
was found, and `c` is the found cell.
"""
function traverse!(a::AbstractArray, c::Cell, level=1)
    push!(a, (level, c))
    for ref in c.refs
        traverse!(a, ref.cell, level+1)
    end
end

"""
```
order!(a::AbstractArray)
```

Given an array of tuples like that coming out of [`traverse!`](@ref), we
sort by the `level`, strip the level out, and then retain unique entries.
The aim of this function is to determine an optimal writing order when
saving pattern data (although the GDS-II spec does not require cells to be
in a particular order, there may be performance ramifications).

For performance reasons, this function modifies `a` but what you want is the
returned result array.
"""
function order!(a::AbstractArray)
    a = sort!(a, lt=(x,y)->x[1]<y[1], rev=true)
    unique(map(x->x[2], a))
end

"""
```
transform(c::Cell, d::CellRef)
```

Given a cell `c` containing cell reference or array `d` in its tree of
references, this function returns an `AffineTransform` object that lets you
translate from the coordinate system of `d` to the coordinate system of `c`.

If the *same exact* cell reference or array (as in, same address in memory)
is included multiple times in the tree of references, then the resulting transform
will be based on the first time it is encountered. The tree is traversed one level
at a time to find the reference (optimized for shallow references).

Example: You want to translate (2.0,3.0) in the coordinate system of the referenced
cell to the coordinate system of `c`. Simply call: `transform(c,d)*Point(2.0,3.0)`.
"""
function transform(c::Cell, d::CellRef)
    x,y = transform(c, d, tformeye(2))

    x || error("Reference tree bears no fruit.")
    return y
end

function transform(c::Cell, d::CellRef, a::AffineTransform)
    # look for the reference in the top level of the reference tree.
    for ref in c.refs
        println(ref.cell.name)
        if ref === d
            sgn = d.xrefl ? -1 : 1
            println("Found $(ref.cell.name)")
            return true, a * AffineTransform(
                [sgn*d.mag*cosd(d.rot) -d.mag*sind(d.rot);
                 sgn*d.mag*sind(d.rot) d.mag*cosd(d.rot)], d.origin)
        end
    end

    # didn't find the reference at this level.
    # we must go deeper...
    println("Didn't find ref, going deeper")
    for ref in c.refs
        sgn = ref.xrefl ? -1 : 1
        (x,y) = transform(ref.cell, d, a * AffineTransform(
            [sgn*ref.mag*cosd(ref.rot) -ref.mag*sind(ref.rot);
             sgn*ref.mag*sind(ref.rot) ref.mag*cosd(ref.rot)], ref.origin))
        # were we successful?
        if x
            return x, y
        end
    end

    # we should have found `d` by now. report our failure
    return false, a
end

for op in [:+, :-]
    @eval function ($op){T<:Real}(r::Cell{T}, p::Point)
        n = Cell{T}(r.name, similar(r.elements), similar(r.refs))
        for (ia, ib) in zip(eachindex(r.elements), eachindex(n.elements))
            @inbounds n.elements[ib] = ($op)(r.elements[ia], p)
        end
        for (ia, ib) in zip(eachindex(r.refs), eachindex(n.refs))
            @inbounds n.refs[ib] = ($op)(r.refs[ia], p)
        end
        n
    end
    @eval function ($op){S,T<:Real}(r::CellArray{S,T}, p::Point)
        CellArray(r.cell, ($op)(r.origin,p), r.deltacol, r.deltarow,
            r.col, r.row, r.xrefl, r.mag, r.rot)
    end
    @eval function ($op){S,T<:Real}(r::CellReference{S,T}, p::Point)
        CellReference(r.cell, ($op)(r.origin,p),
            xrefl=r.xrefl, mag=r.mag, rot=r.rot)
    end
end

end
