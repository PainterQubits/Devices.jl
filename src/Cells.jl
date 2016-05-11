module Cells

using AffineTransforms
using ..Points
using ..Rectangles
using ..Polygons

import Base: show, +, -
import Devices: AbstractPolygon, bounds, center, center!
export Cell, CellArray, CellReference
export traverse!, order!

abstract CellRef{S, T<:Real}

"""
```
type CellReference{S,T} <: CellRef{S,T}
    cell::S
    origin::Point{2,T}
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
    origin::Point{2,T}
    xrefl::Bool
    mag::Float64
    rot::Float64
end

"""
```
type CellArray{S,T} <: CellRef{S,T}
    cell::S
    origin::Point{2,T}
    deltacol::Point{2,T}
    deltarow::Point{2,T}
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
    origin::Point{2,T}
    deltacol::Point{2,T}
    deltarow::Point{2,T}
    col::Int
    row::Int
    xrefl::Bool
    mag::Float64
    rot::Float64
end

"""
```
type Cell{T<:Real}
    name::ASCIIString
    elements::Array{AbstractPolygon{T},1}
    refs::Array{CellRef,1}
    create::DateTime
    function even(str)
        if mod(length(str),2) == 1
            str*"\0"
        else
            str
        end
    end
    Cell(x,y,z) = new(even(x), y, z, now())
    Cell(x,y) = new(even(x), y, CellReference[], now())
    Cell(x) = new(even(x), AbstractPolygon{T}[], CellReference[], now())
end
```

A cell has a name and contains polygons and references to `CellArray` or
`CellReference` objects. It also records the time of its own creation. As
currently implemented it mirrors the notion of cells in GDS-II files.

In the future, it may make sense to generalize the idea and permit
`Path` objects within a Cell.

To add elements, push them to `elements` field;
to add references, push them to `refs` field.
"""
type Cell{T<:Real}
    name::ASCIIString
    elements::Array{AbstractPolygon{T},1}
    refs::Array{CellRef,1}
    create::DateTime
    function even(str)
        if mod(length(str),2) == 1
            str*"\0"
        else
            str
        end
    end
    Cell(x,y,z) = new(even(x), y, z, now())
    Cell(x,y) = new(even(x), y, CellReference[], now())
    Cell(x) = new(even(x), AbstractPolygon{T}[], CellReference[], now())
end

"""
```
CellReference{T<:Real}(x::Cell, y::Point{2,T}; xrefl=false, mag=1.0, rot=0.0)
```

Convenience constructor for `CellReference{typeof(x), T}`.
"""
CellReference{T<:Real}(x::Cell, origin::Point{2,T}; xrefl=false, mag=1.0, rot=0.0) =
    CellReference{typeof(x), T}(x, origin, xrefl, mag, rot)

"""
```
CellArray{T<:Real}(x::Cell, origin::Point{2,T}, dc::Point{2,T}, dr::Point{2,T},
    c::Integer, r::Integer; xrefl=false, mag=1.0, rot=0.0)
```

Construct a `CellArray{typeof(x),T}` object, with `xrefl`, `mag`, and `rot` as
keyword arguments (x-reflection, magnification factor, rotation in degrees).
"""
CellArray{T<:Real}(x::Cell, origin::Point{2,T}, dc::Point{2,T}, dr::Point{2,T},
    c::Integer, r::Integer; xrefl=false, mag=1.0, rot=0.0) =
    CellArray{typeof(x),T}(x,o,dc,dr,c,r,xrefl,mag,rot)

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
    lls = [(b.ll + (i-1) * ref.deltarow + (j-1) * ref.deltacol)::Point{2,promote_type(S,T)}
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

Given an array of tuples like that coming out of [`traverse!`]({ref}), we
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
        CellReference(r.cell, ($op)(r.origin,p), r.xrefl, r.mag, r.rot)
    end
end

end
