# Rendering of arbitrary segments
function render!(c::Cell, f, len, s::Paths.TaperTrace, meta::Meta; kwargs...)
    bnds = (zero(len), len)

    g = (t,sgn)->begin
        d = Paths.direction(f,t) + sgn * π/2
        return f(t) + Paths.extent(s,t) * Point(cos(d), sin(d))
    end

    pgrid = adapted_grid(t->Paths.direction(r->g(r, 1), t), bnds; kwargs...)
    mgrid = adapted_grid(t->Paths.direction(r->g(r,-1), t), bnds; kwargs...)

    pts = [g.(pgrid, 1); @view (g.(mgrid, -1))[end:-1:1]]

    render!(c, Polygon(pts), Polygons.Plain(), meta)
end

function render!(c::Cell, f, len, s::Paths.TaperCPW, meta::Meta; kwargs...)
    bnds = (zero(len), len)

    g = (t,sgn1,sgn2)->begin
        d = Paths.direction(f,t) + sgn1 * π/2       # turn left (+) or right (-) of path
        offset = 0.5*(Paths.gap(s,t) + Paths.trace(s,t))
        return f(t) + (sgn2 * 0.5*Paths.gap(s,t) + offset) * Point(cos(d), sin(d))
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

# Optimized rendering of straight tapered segments
function render!(c::Cell, segment::Paths.Straight{T}, s::Paths.TaperTrace, meta::Meta; kwargs...) where {T}
    dir = direction(segment, zero(T))
    dp, dm = dir+π/2, dir-π/2

    ext_start = Paths.extent(s, zero(T))
    ext_end = Paths.extent(s, pathlength(segment))

    tangents = StaticArrays.@SVector [
        ext_start * Point(cos(dp),sin(dp)),
        ext_end * Point(cos(dp),sin(dp)),
        ext_end * Point(cos(dm),sin(dm)),
        ext_start * Point(cos(dm),sin(dm))
    ]

    a,b = segment(zero(T)), segment(pathlength(segment))
    origins = StaticArrays.@SVector [a,b,b,a]

    render!(c, Polygon(origins .+ tangents), Polygons.Plain(), meta)
end

function render!(c::Cell, segment::Paths.Straight{T}, s::Paths.TaperCPW, meta::Meta; kwargs...) where {T}
    dir = direction(segment, zero(T))
    dp = dir+π/2

    ext_start = Paths.extent(s, zero(T))
    ext_end = Paths.extent(s, pathlength(segment))
    trace_start = Paths.trace(s, zero(T))
    trace_end = Paths.trace(s, pathlength(segment))

    tangents = StaticArrays.@SVector [
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp)),
        Point(cos(dp),sin(dp))
    ]

    extents_p = StaticArrays.@SVector [ext_start, ext_end, 0.5*trace_end, 0.5*trace_start]
    extents_m = StaticArrays.@SVector [0.5*trace_start, 0.5*trace_end, ext_end, ext_start]

    a,b = segment(zero(T)), segment(pathlength(segment))
    origins = StaticArrays.@SVector [a,b,b,a]

    render!(c, Polygon(origins .+ extents_p .* tangents), Polygons.Plain(), meta)
    render!(c, Polygon(origins .- extents_m .* tangents), Polygons.Plain(), meta)
end
