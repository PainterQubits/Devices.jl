function render!(c::Cell, f, len, s::Paths.CompoundStyle, meta::Meta; kwargs...)
    bnds = linspace(zero(len), len, 21)
    xgrid = adapted_grid(t->getx(f(t)), bnds; kwargs...)
    ygrid = adapted_grid(t->gety(f(t)), bnds; kwargs...)
    sgrid = adapted_grid(t->Paths.width(s,t), bnds; kwargs...)
    grid = unique(sort([xgrid; ygrid; sgrid]))

    dirs = (x->direction(f,x)).(grid) .+ π/2
    origins = f.(grid)
    tangents = (x->Point(cos(x),sin(x))).(dirs)
    extents = (x->Paths.extent(s,x)).(grid)
    pts = [origins .+ (tangents .* extents);
        reverse(origins) .+ (reverse(tangents) .* -extents)]

    push!(c.elements, CellPolygon(Polygon(pts), meta))
end

function render!(c::Cell, seg::Paths.CompoundSegment, s::Paths.CompoundStyle, meta::Meta;
        kwargs...)
    @assert length(seg.segments) == length(s.styles)
    for (se,st) in zip(seg.segments, s.styles)
        render!(c, se, st; kwargs...)
    end
end
