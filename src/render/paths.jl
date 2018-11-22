"""
    render!{T}(c::Cell, p::Path{T}, meta::Meta=GDSMeta(); kwargs...)
Render a path `p` to a cell `c`.
"""
function render!(c::Cell, p::Path{T}, meta::Meta=GDSMeta(); kwargs...) where {T}
    inds = findall(x->isa(segment(x), Paths.Corner), nodes(p))
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
    !isempty(inds) && reconcile!(p)

    taper_inds = handle_generic_tapers!(p)

    for node in p
        render!(c, segment(node), style(node), meta; kwargs...)
    end

    # Restore corner positions
    for i in reverse(inds)
        setsegment!(next(p[i]), pop!(segs))
        setsegment!(previous(p[i]), pop!(segs))
    end
    !isempty(inds) && reconcile!(p)

    restore_generic_tapers!(p, taper_inds)

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

function handle_generic_tapers!(p)
    # Adjust the path so generic tapers render correctly
    generic_taper_inds = findall(x->isa(style(x), Paths.Taper), nodes(p))
    for i in generic_taper_inds
        tapernode = p[i]
        prevnode = previous(tapernode)
        nextnode = next(tapernode)
        if prevnode === tapernode || nextnode === tapernode
            error("A generic taper cannot start or finish a path")
        end
        taper_style = get_taper_style(prevnode, nextnode)
        setstyle!(tapernode, taper_style)
    end

    return generic_taper_inds
end

function get_taper_style(prevnode, nextnode)
    prevstyle = style(prevnode)
    nextstyle = style(nextnode)
    endof_prev = pathlength(segment(prevnode))
    # handle case of compound style (#39)
    if prevstyle isa Paths.CompoundStyle
        prevstyle = last(prevstyle.styles)
    end
    if nextstyle isa Paths.CompoundStyle
        nextstyle = first(nextstyle.styles)
    end
    # handle special case of tapers, set endof_prev to normalized dimensionless parameter
    if prevstyle isa Paths.TaperTrace || prevstyle isa Paths.TaperCPW
        endof_prev = endof_prev/endof_prev
    end
    beginof_next = zero(pathlength(segment(nextnode)))
    # handle special case of tapers, set beginof_next to normalized dimensionless parameter
    if nextstyle isa Paths.TaperTrace || nextstyle isa Paths.TaperCPW
        beginof_next = beginof_next/pathlength(segment(nextnode))
    end
    if ((prevstyle isa Paths.CPW || prevstyle isa Paths.Trace)
        && nextstyle isa Paths.CPW || nextstyle isa Paths.Trace)
        #special case: both ends are Traces, make a Paths.TaperTrace
        if prevstyle isa Paths.Trace && nextstyle isa Paths.Trace
            thisstyle = Paths.TaperTrace(Paths.width(prevstyle, endof_prev),
                                   Paths.width(nextstyle, beginof_next))
        elseif prevstyle isa Paths.Trace #previous segment is Paths.trace
            gap_start = Paths.width(prevstyle, endof_prev)/2.
            trace_end = Paths.trace(nextstyle, beginof_next)
            gap_end = Paths.gap(nextstyle, beginof_next)
            thisstyle = Paths.TaperCPW(zero(gap_start), gap_start,
                                 trace_end, gap_end)
        elseif nextstyle isa Paths.Trace #next segment is Paths.trace
            trace_start = Paths.trace(prevstyle, endof_prev)
            gap_end = Paths.width(nextstyle, beginof_next)/2.
            gap_start = Paths.gap(prevstyle, endof_prev)
            thisstyle = Paths.TaperCPW(trace_start, gap_start,
                                 zero(gap_end), gap_end)
        else #both segments are CPW
            trace_start = Paths.trace(prevstyle, endof_prev)
            trace_end = Paths.trace(nextstyle, beginof_next)
            gap_start = Paths.gap(prevstyle, endof_prev)
            gap_end = Paths.gap(nextstyle, beginof_next)
            thisstyle = Paths.TaperCPW(trace_start, gap_start,
                                 trace_end, gap_end)
        end
    else
        error("A generic taper must have either a CPW or Paths.Trace on both ends")
    end
    return thisstyle
end

function restore_generic_tapers!(p, taper_inds)
    for i in taper_inds
        setstyle!(p[i], Paths.Taper())
    end
end
