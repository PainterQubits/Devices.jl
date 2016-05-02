module Cells

using AffineTransforms
using ..Points
using ..Rectangles
using ..Polygons

import Base: show
import Devices: AbstractPolygon, bounds
export Cell, CellArray, CellReference

type CellReference{S,T<:Real}
    cell::S
    origin::Point{2,T}
    xrefl::Bool
    mag::Float64
    rot::Float64
end

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
`bounds(cell::Cell)`

Returns coordinates for a bounding box around all objects in `cell`.
The return format is a `Rectangle`.
"""
function bounds(cell::Cell)
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

function bounds(ref::CellReference)
    mi, ma = Point(NaN, NaN), Point(NaN, NaN)

    b = bounds(ref.cell)
    sgn = ref.xrefl ? -1 : 1
    a = AffineTransform(
        [sgn*ref.mag*cosd(ref.rot) -ref.mag*sind(ref.rot);
         sgn*ref.mag*sind(ref.rot) ref.mag*cosd(ref.rot)], ref.origin)
    c = a * convert(Polygon{Float64}, b)
    bounds(c)
end

end
