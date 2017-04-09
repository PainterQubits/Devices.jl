"""
    render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain(); kwargs...)
    render!(c::Cell, r::Rectangle, ::Rectangles.Plain; kwargs...)
    render!(c::Cell, r::Rectangle, s::Rectangles.Rounded; kwargs...)
    render!(c::Cell, r::Rectangle, s::Rectangles.Undercut;
        layer=0, uclayer=0, kwargs...)
Render a rectangle `r` to cell `c`, defaulting to plain styling.
"""
function render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain(); kwargs...)
    render!(c, r, s; kwargs...)
end

function render!(c::Cell, r::Rectangle, ::Rectangles.Plain; kwargs...)
    d = Dict(kwargs)
    r.properties = merge(r.properties, d)
    push!(c.elements, r)
    c
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Rounded; kwargs...)
    d = Dict(kwargs)
    r.properties = merge(r.properties, d)

    rad = s.r
    ll, ur = minimum(r), maximum(r)
    gr = Rectangle(ll+Point(rad,rad),ur-Point(rad,rad), r.properties)
    push!(c.elements, gr)

    p = Path(ll+Point(rad,rad/2), style0=Paths.Trace(s.r)) #0.0, Paths.Trace(s.r))
    straight!(p, width(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, width(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r)-2*rad)
    turn!(p, π/2, rad/2)
    render!(c, p; r.properties...)
end

function render!(c::Cell, r::Rectangle, s::Rectangles.Undercut;
    layer=0, uclayer=0, kwargs...)

    r.properties = merge(r.properties, Dict(kwargs))
    r.properties[:layer] = layer
    push!(c.elements, r)

    ucr = Rectangle(r.ll-Point(s.ucl,s.ucb),
        r.ur+Point(s.ucr,s.uct), Dict(kwargs))
    ucp = clip(Clipper.ClipTypeDifference, ucr, r)[1]
    ucp.properties[:layer] = uclayer
    push!(c.elements, ucp)

    c
end
