module Cells
using ..Points
import Devices: AbstractPolygon
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

end
