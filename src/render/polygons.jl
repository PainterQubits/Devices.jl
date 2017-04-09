"""
    render!(c::Cell, r::Polygon, s::Polygons.Style=Polygons.Plain(); kwargs...)
    render!(c::Cell, r::Polygon, s::Polygons.Plain; kwargs...)
Render a polygon `r` to cell `c`, defaulting to plain styling. Currently there is no other
Polygon rendering style implemented.
"""
function render!(c::Cell, r::Polygon, s::Polygons.Style=Polygons.Plain(); kwargs...)
    d = Dict(kwargs)
    r.properties = merge(r.properties, d)
    push!(c.elements, r)
    c
end
