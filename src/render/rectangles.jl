"""
    render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain())
    render!(c::Cell, r::Rectangle, ::Rectangles.Plain)
    render!(c::Cell, r::Rectangle, s::Rectangles.Rounded)
    render!(c::Cell, r::Rectangle, s::Rectangles.Undercut)
Render a rectangle `r` to cell `c`, defaulting to plain styling.
"""
function render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain())
    render!(c, r, s)
    c
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Plain)
    push!(c.elements, CellPolygon(r, layer(s), datatype(s)))
    c
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Rounded)
    rad = s.r
    ll, ur = lowerleft(r), upperright(r)
    gr = Rectangle(ll+Point(rad,rad), ur-Point(rad,rad))
    push!(c.elements, CellPolygon(gr, layer(s), datatype(s)))

    p = Path(ll + Point(rad,rad/2), style0 = Paths.Trace(s.r))
    straight!(p, width(r) - 2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r) - 2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, width(r) - 2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r) - 2*rad)
    turn!(p, π/2, rad/2)
    render!(c, CellPolygon(p, layer(s), datatype(s)))
    c
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Undercut)
    push!(c.elements, CellPolygon(r, layer(s), datatype(s)))

    ucr = Rectangle(r.ll - Point(s.ucl,s.ucb), r.ur + Point(s.ucr,s.uct))
    ucp = clip(Clipper.ClipTypeDifference, ucr, r)[1]
    push!(c.elements, CellPolygon(ucp, s.uclayer, s.ucdatatype))
    c
end
