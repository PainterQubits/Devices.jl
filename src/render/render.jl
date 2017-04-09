include("rectangles.jl")
include("polygons.jl")
include("paths.jl")
include("corners.jl")
include("trace.jl")
include("cpw.jl")
include("decorated.jl")

# generic fallback
render!(c::Cell, seg::Paths.Segment, s::Paths.Style; kwargs...) =
    render!(c, seg, pathlength(seg), s; kwargs...)

function render!(c::Cell, seg::Paths.CompoundSegment, s::Paths.CompoundStyle; kwargs...)
    @assert length(seg.segments) == length(s.styles)
    for (se,st) in zip(seg.segments, s.styles)
        render!(c, se, st; kwargs...)
    end
end

function render!(c::Cell, f, len, s::Paths.CompoundStyle; kwargs...)
    bnds = linspace(zero(len), len, 21)
    xgrid = adapted_grid(t->getx(f(t)), bnds)
    ygrid = adapted_grid(t->gety(f(t)), bnds)
    sgrid = adapted_grid(t->Paths.width(s,t), bnds)
    grid = unique(sort([xgrid; ygrid; sgrid]))

    dirs = (x->direction(f,x)).(grid) .+ π/2
    origins = f.(grid)
    tangents = (x->Point(cos(x),sin(x))).(dirs)
    extents = (x->Paths.extent(s,x)).(grid)
    pts = [origins .+ (tangents .* extents);
        reverse(origins) .+ (reverse(tangents) .* -extents)]

    push!(c.elements, Polygon(pts, Dict{Symbol,Any}(kwargs)))
end

# skip rendering
function render!(c::Cell, seg::Paths.Segment, s::Paths.NoRender; kwargs...) end
