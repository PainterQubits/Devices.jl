"""
    render!(c::Cell, p::Polygon, meta::Meta) = render!(c, p, Polygons.Plain(), meta)
    render!(c::Cell, r::Polygon, s::Polygons.Style, meta::Meta)
Render a polygon `r` to cell `c`, defaulting to plain styling. Currently there is no other
Polygon rendering style implemented.
"""
render!(c::Cell, p::Polygon, meta::Meta) = render!(c, p, Polygons.Plain(), meta)
function render!(c::Cell, r::Polygon, s::Polygons.Style, meta::Meta)
    push!(c.elements, CellPolygon(r, meta))
    c
end
