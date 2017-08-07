function render!(c::Cell, f, len, s::Paths.CPW, meta::Meta; kwargs...)
    bnds = (zero(len), len)

    g = (t,sgn1,sgn2)->begin
        d = Paths.direction(f,t) + sgn1 * π/2       # turn left (+) or right (-) of path
        offset = (Paths.gap(s,t) + Paths.trace(s,t)) / 2
        return f(t) + (sgn2 * Paths.gap(s,t)/2 + offset) * Point(cos(d),sin(d))
    end

    ppgrid = adapted_grid(t->Paths.direction(r->g(r,  1,  1), t), bnds; kwargs...)
    pmgrid = adapted_grid(t->Paths.direction(r->g(r,  1, -1), t), bnds; kwargs...)
    mmgrid = adapted_grid(t->Paths.direction(r->g(r, -1, -1), t), bnds; kwargs...)
    mpgrid = adapted_grid(t->Paths.direction(r->g(r, -1,  1), t), bnds; kwargs...)

    ppts = [g.(ppgrid,  1,  1); @view (g.(pmgrid,  1, -1))[end:-1:1]]
    mpts = [g.(mmgrid, -1, -1); @view (g.(mpgrid, -1,  1))[end:-1:1]]

    render!(c, Polygon(ppts), Polygons.Plain(), meta)
    render!(c, Polygon(mpts), Polygons.Plain(), meta)
end

function render!(c::Cell, segment::Paths.Straight{T}, s::Paths.SimpleCPW, meta::Meta) where {T}
    dir = direction(segment, zero(T))
    dp = dir+π/2

    tangents = StaticArrays.@SVector [
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp))]

    ext = Paths.extent(s, zero(T))

    extents_p = StaticArrays.@SVector [Paths.extent(s), Paths.extent(s),
                                       Paths.trace(s)/2., Paths.trace(s)/2.]
    extents_m = StaticArrays.@SVector [Paths.trace(s)/2., Paths.trace(s)/2.,
                                       Paths.extent(s), Paths.extent(s)]

    a,b = segment(zero(T)),segment(pathlength(segment))
    origins = StaticArrays.@SVector [a,b,b,a]

    render!(c, Polygon(origins .+ extents_p .* tangents), Polygons.Plain(), meta)
    render!(c, Polygon(origins .- extents_m .* tangents), Polygons.Plain(), meta)
end
