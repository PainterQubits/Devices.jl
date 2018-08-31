function render!(c::Cell, f, len, s::Paths.Strands, meta::Meta; kwargs...)
    bnds = (zero(len), len)

    g = (t,sgn1,idx,sgn2)->begin
        d = Paths.direction(f,t) + sgn1 * π/2       # turn left (+) or right (-) of path
        offset = Paths.offset(s,t) + Paths.width(s,t) / 2
        strand_offset = idx*(Paths.spacing(s,t) + Paths.width(s,t))
        return f(t) + (sgn2 * Paths.width(s,t)/2 + offset + strand_offset) * Point(cos(d),sin(d))
    end
    for i in 0:(Paths.num(s) - 1)
        ppgrid = adapted_grid(t->Paths.direction(r->g(r,  1, i, 1), t), bnds; kwargs...)
        pmgrid = adapted_grid(t->Paths.direction(r->g(r,  1, i, -1), t), bnds; kwargs...)
        mmgrid = adapted_grid(t->Paths.direction(r->g(r, -1, i, -1), t), bnds; kwargs...)
        mpgrid = adapted_grid(t->Paths.direction(r->g(r, -1, i,  1), t), bnds; kwargs...)

        ppts = [g.(ppgrid,  1, i,  1); @view (g.(pmgrid,  1, i,  -1))[end:-1:1]]
        mpts = [g.(mmgrid, -1, i, -1); @view (g.(mpgrid, -1, i,  1))[end:-1:1]]

        render!(c, Polygon(uniquepoints(ppts)), Polygons.Plain(), meta)
        render!(c, Polygon(uniquepoints(mpts)), Polygons.Plain(), meta)
    end
end

function render!(c::Cell, segment::Paths.Straight{T}, s::Paths.SimpleStrands, meta::Meta) where {T}
    dir = direction(segment, zero(T))
    dp = dir+π/2

    tangents = [
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp))]

    for i in 0:(Paths.num(s) - 1)
        i_offset = i*(Paths.width(s) + Paths.spacing(s))
        o = Paths.offset(s) + i_offset
        ow = o + Paths.width(s)

        ext = Paths.extent(s, zero(T))

        extents_p = [o,o,ow,ow]
        extents_m = [ow,ow,o,o]

        a,b = segment(zero(T)),segment(pathlength(segment))
        origins = [a,b,b,a]

        render!(c, Polygon(origins .+ extents_p .* tangents), Polygons.Plain(), meta)
        render!(c, Polygon(origins .- extents_m .* tangents), Polygons.Plain(), meta)
end
end
