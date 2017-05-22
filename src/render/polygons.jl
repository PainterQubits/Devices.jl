"""
    render!(c::Cell, r::Polygon, s::Polygons.Style = Polygons.Plain(0,0))
Render a polygon `r` to cell `c`, defaulting to plain styling. Currently there is no other
Polygon rendering style implemented.
"""
function render!(c::Cell, r::Polygon, s::Polygons.Style = Polygons.Plain(0,0))
    push!(c.polygons, CellPolygon(r, layer(s), datatype(s)))
    c
end
