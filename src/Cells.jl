module Cells

using AffineTransforms
using ..Points
using ..Rectangles
using ..Polygons

import Base: show
import Devices: AbstractPolygon, bounds
export Cell, CellArray, CellReference
export traverse!, order!

"""
`CellReference{S,T<:Real}`

Reference to a `cell` positioned at `origin`, with optional x-reflection
`xrefl::Bool`, magnification factor `mag`, and rotation angle `rot` in degrees.

The type variable `S` is to avoid circular definitions with `Cell`.
"""
type CellReference{S,T<:Real}
    cell::S
    origin::Point{2,T}
    xrefl::Bool
    mag::Float64
    rot::Float64
end

"""
`CellArray{S,T<:Real}`

Array of `cell` starting at `origin` with `row` rows and `col` columns,
spanned by vectors `deltacol` and `deltarow`. Optional x-reflection
`xrefl::Bool`, magnification factor `mag`, and rotation angle `rot` in degrees
are for the array as a whole.

The type variable `S` is to avoid circular definitions with `Cell`.
"""
type CellArray{S,T<:Real}
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
`Cell`

A cell has a name and contains polygons and references to `CellArray` or
`CellReference` objects. It also records the time of its own creation.

To add elements, push them to `elements` field;
to add references, push them to `refs` field.
"""
type Cell
    name::ASCIIString
    elements::Array{Any,1}
    refs::Array{CellReference,1}
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
    Cell(x) = new(even(x), Any[], CellReference[], now())
end

# Don't print out everything in the cell, it is a mess that way.
show(io::IO, c::Cell) = print(io,
    "Cell \"$(c.name)\" with $(length(c.elements)) els, $(length(c.refs)) refs")

CellReference{T<:Real}(x::Cell, y::Point{2,T}; xrefl=false, mag=1.0, rot=0.0) =
    CellReference{Cell, T}(x,y,xrefl,mag,rot)
CellArray{T<:Real}(x::Cell, o::Point{2,T}, dc::Point{2,T}, dr::Point{2,T},
    c::Integer, r::Integer; xrefl=false, mag=1.0, rot=0.0) =
    CellArray{Cell,T}(x,o,dc,dr,c,r,xrefl,mag,rot)
CellArray{T<:Real}(x::Cell, c::Range{T}, r::Range{T};
    xrefl=false, mag=1.0, rot=0.0) =
    CellArray{Cell,T}(x, Point(first(c),first(r)), Point(step(c),zero(step(c))),
        Point(zero(step(r)), step(r)), length(c), length(r), xrefl, mag, rot)

"""
`bounds(cell::Cell; kwargs...)`

Returns a `Rectangle` bounding box with no properties around all objects in `cell`.
`Point(NaN, NaN)` is used for the corners if there is nothing inside the cell.
"""
function bounds(cell::Cell; kwargs...)
    mi, ma = Point(NaN, NaN), Point(NaN, NaN)

    isempty(cell.elements) && isempty(cell.refs) &&
        return Rectangle(mi, ma)

    for el in cell.elements
        b = bounds(el)
        mi, ma = min(mi,minimum(b)), max(ma,maximum(b))
    end

    for el in cell.refs
        b = bounds(el)
        mi, ma = min(mi,minimum(b)), max(ma,maximum(b))
    end

    Rectangle(mi, ma)
end

"""
`bounds(ref::CellReference; kwargs...)`

Returns a `Rectangle` bounding box with no properties around all objects in `ref`.
`Point(NaN, NaN)` is used for the corners if there is nothing inside the cell
referenced by `ref`. The bounding box respects reflection, rotation, and magnification
specified by `ref`.
"""
function bounds(ref::CellReference; kwargs...)
    mi, ma = Point(NaN, NaN), Point(NaN, NaN)

    b = bounds(ref.cell; kwargs...)
    sgn = ref.xrefl ? -1 : 1
    a = AffineTransform(
        [sgn*ref.mag*cosd(ref.rot) -ref.mag*sind(ref.rot);
         sgn*ref.mag*sind(ref.rot) ref.mag*cosd(ref.rot)], ref.origin)
    c = a * convert(Polygon{Float64}, b)
    bounds(c)
end

"""
`traverse!(a::AbstractArray, c::Cell, level=1)`

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
`order!(a::AbstractArray)`

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


end
