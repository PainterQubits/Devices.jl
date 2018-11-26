function render!(c::Cell, f, len, s::Paths.CompoundStyle, meta::Meta; kwargs...)
    @assert length(s.styles) == length(s.grid) - 1
    for (i,sty) in enumerate(s.styles)
        @inbounds x0, x1 = s.grid[i], s.grid[i+1]
        @inbounds s.grid[i] >= len && break
        @inbounds l = ifelse(i == length(s.styles), len - s.grid[i],
            ifelse(s.grid[i+1] > len, len - s.grid[i], s.grid[i+1] - s.grid[i]))
        @inbounds render!(c, x->f(x+s.grid[i]), l, s.styles[i], meta; kwargs...)
    end
end

function render!(c::Cell, seg::Paths.CompoundSegment, sty::Paths.CompoundStyle, meta::Meta;
        kwargs...)
    if seg.tag == sty.tag
        # Tagging mechanism: if some nodes have been simplified, but neither the segment
        # nor the style have been swapped out, we'll just render as if we never simplified.
        for (se, st) in zip(seg.segments, sty.styles)
            render!(c, se, st, meta; kwargs...)
        end
    else
        # Something has been done post-simplification, so we fall back to generic rendering
        render!(c, seg, pathlength(seg), sty, meta; kwargs...)
    end
end
