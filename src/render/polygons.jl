"""
    render!(c::Cell, r::Polygon, s::Polygons.Style, meta::Meta)
Render a polygon `r` to cell `c`, defaulting to plain styling. Currently there is no other
Polygon rendering style implemented.
"""
function render!(c::Cell, r::Polygon, s::Polygons.Style, meta::Meta)
    push!(c.elements, CellPolygon(r, meta))
    c
end
