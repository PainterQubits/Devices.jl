function render!(c::Cell, seg::Paths.Corner, ::Paths.SimpleTraceCorner; kwargs...)
    sgn = ifelse(seg.α >= 0.0°, 1, -1)
    ∠A = seg.α0+sgn*π/2
    p = Point(cos(∠A),sin(∠A))
    p1 = seg.extent*p + seg.p0
    p2 = -seg.extent*p + seg.p0
    ex = 2*seg.extent*tan(sgn*seg.α/2)
    p3 = p2 + ex*Point(cos(seg.α0),sin(seg.α0))
    p4 = p3 + ex*Point(cos(seg.α0+seg.α), sin(seg.α0+seg.α))

    push!(c.elements, Polygon([p1,p2,p3,p4], Dict{Symbol,Any}(kwargs)))
end
