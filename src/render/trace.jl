function render!(c::Cell, f, len, s::Paths.Trace, meta::Meta; kwargs...)
    bnds = (zero(len), len)

    g = (t,sgn)->begin
        d = Paths.direction(f,t) + sgn * π/2
        return f(t) + Paths.extent(s,t) * Point(cos(d),sin(d))
    end

    pgrid = adapted_grid(t->Paths.direction(r->g(r, 1), t), bnds; kwargs...)
    mgrid = adapted_grid(t->Paths.direction(r->g(r,-1), t), bnds; kwargs...)

    pts = [g.(pgrid, 1); @view (g.(mgrid, -1))[end:-1:1]]
    render!(c, Polygon(uniquepoints(pts)), Polygons.Plain(), meta)
end

function render!(c::Cell, segment::Paths.Straight{T}, s::Paths.SimpleTrace, meta::Meta) where {T}
    dir = direction(segment, zero(T))
    dp, dm = dir+π/2, dir-π/2

    ext = Paths.extent(s, zero(T))
    tangents = StaticArrays.@SVector [
        ext * Point(cos(dp),sin(dp)),
        ext * Point(cos(dp),sin(dp)),
        ext * Point(cos(dm),sin(dm)),
        ext * Point(cos(dm),sin(dm))]

    a,b = segment(zero(T)), segment(pathlength(segment))
    origins = StaticArrays.@SVector [a,b,b,a]

    render!(c, Polygon(origins .+ tangents), Polygons.Plain(), meta)
end
