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

type CellReference
    xrefl::Bool
    origin::Point{2,Float64}
    mag::Float64
    rot::Float64
    cell::Cell
end

end
