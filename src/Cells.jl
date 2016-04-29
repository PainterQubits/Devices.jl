module Cells

using AffineTransforms
using ..Points
using ..Rectangles
using ..Polygons

import Devices: AbstractPolygon, bounds
export Cell, CellReference

type Cell
    name::ASCIIString
    elements::Array{Any,1}
    create::DateTime
    Cell(x,y) = new(x, y, now())
    Cell(x) = new(x, Any[], now())
end

type CellReference{T<:Real}
    cell::Cell
    origin::Point{2,T}
    xrefl::Bool
    mag::Float64
    rot::Float64
end
CellReference{T<:Real}(x::Cell, y::Point{2,T}; xrefl=false, mag=1.0, rot=0.0) =
    CellReference(x,y,xrefl,mag,rot)

"""
`bounds(cell::Cell)`

Returns coordinates for a bounding box around all objects in `cell`.
The return format is a `Rectangle`.
"""
function bounds(cell::Cell)
    mi, ma = Point(NaN, NaN), Point(NaN, NaN)

    isempty(cell.elements) &&
        return Rectangle(mi, ma)

    for el in cell.elements
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
