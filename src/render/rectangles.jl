"""
    render!(c::Cell, r::Rectangle,  ::Rectangles.Plain)
    render!(c::Cell, r::Rectangle, s::Rectangles.Rounded)
    render!(c::Cell, r::Rectangle, s::Rectangles.Undercut)
Render a rectangle `r` to cell `c`, defaulting to plain styling.
"""


function render!(c::Cell, r::Rectangle, ::Rectangles.Plain, meta::Meta)
    push!(c.elements, CellPolygon(r, meta))
    c
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Rounded, meta::Meta)
    rad = s.r
    ll, ur = lowerleft(r), upperright(r)
    gr = Rectangle(ll + Point(rad,rad), ur - Point(rad,rad))
    push!(c.elements, CellPolygon(gr, meta))

    p = Path(ll + Point(rad, rad/2), style0 = Paths.Trace(s.r))
    straight!(p, width(r) - 2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r) - 2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, width(r) - 2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r) - 2*rad)
    turn!(p, π/2, rad/2)
    render!(c, p, meta)
    c
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Undercut)
    push!(c.elements, CellPolygon(r, s.meta))

    ucr = Rectangle(r.ll - Point(s.ucl, s.ucb), r.ur + Point(s.ucr, s.uct))
    ucp = clip(Clipper.ClipTypeDifference, ucr, r)[1]
    push!(c.elements, CellPolygon(ucp, s.undercut_meta))
    c
end
