function render!(c::Cell, seg::Paths.Corner, ::Paths.SimpleTraceCorner, meta::Meta)
    sgn = ifelse(seg.α >= 0.0°, 1, -1)

    ext = seg.extent*tan(sgn*seg.α/2)
    p0 = seg.p0 - ext*Point(cos(seg.α0), sin(seg.α0))

    ∠A = seg.α0+sgn*π/2
    p = Point(cos(∠A),sin(∠A))

    p1 = seg.extent*p + p0
    p2 = -seg.extent*p + p0
    p3 = p2 + 2ext*Point(cos(seg.α0),sin(seg.α0))
    p4 = p3 + 2ext*Point(cos(seg.α0+seg.α), sin(seg.α0+seg.α))

    render!(c, Polygon([p1,p2,p3,p4]), Polygons.Plain(), meta)
end
