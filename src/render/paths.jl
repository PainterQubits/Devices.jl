"""
    render!(c::Cell, p::Path; kwargs...)
Render a path `p` to a cell `c`.
"""
function render!{T}(c::Cell, p::Path{T}; layer = DEFAULT_LAYER, datatype = DEFAULT_DATATYPE,
        kwargs...)
    render!(c, p, GDSMeta(layer, datatype); kwargs...)
end

function render!{T}(c::Cell, p::Path{T}, meta::Meta; kwargs...)
    inds = find(map(x->isa(x, Paths.Corner), segment.(nodes(p))))
    segs = []

    # Adjust the path so corners, when rendered with finite extent,
    # are properly positioned.
    # TODO: Add error checking for styles.

    for i in inds
        cornernode = p[i]
        prevseg = segment(previous(cornernode))
        nextseg = segment(next(cornernode))
        segs = [segs; prevseg; nextseg]
        cornertweaks!(cornernode, prevseg, previous)
        cornertweaks!(cornernode, nextseg, next)
    end

    adjust!(p)

    for node in p
        render!(c, segment(node), style(node), meta; kwargs...)
    end

    # Restore corner positions
    for i in reverse(inds)
        setsegment!(next(p[i]), pop!(segs))
        setsegment!(previous(p[i]), pop!(segs))
    end
    adjust!(p)

    return c
end

function cornertweaks!(cornernode, seg::Paths.Straight, which)
    seg′ = copy(seg)
    setsegment!(which(cornernode), seg′)

    α = segment(cornernode).α
    ex = segment(cornernode).extent
    sgn = ifelse(α >= 0.0°, 1, -1)
    seg′.l -= ex*tan(sgn*α/2)
end

cornertweak!(cornernode, seg::Paths.Segment) =
    warn("corner was not sandwiched by straight segments. ",
         "Rendering errors will result.")
