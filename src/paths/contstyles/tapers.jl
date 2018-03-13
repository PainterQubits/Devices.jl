"""
    struct TaperTrace{T<:Coordinate} <: Trace
        width_start::T
        width_end::T
    end
A single trace with a linearly tapered width as a function of path length.
"""
struct TaperTrace{T<:Coordinate} <: Trace
    width_start::T
    width_end::T
end
copy(x::TaperTrace) = TaperTrace(x.width_start, x_width_end)
@inline extent(s::TaperTrace, t) = s.width_start/2  + (s.width_end - s.width_start)*t/2
@inline width(s::TaperTrace, t) = s.width_start + (s.width_end - s.width_start)*t
function TaperTrace(width_start::Coordinate, width_end::Coordinate)
    dimension(width_start) != dimension(width_end) && throw(DimensionError(trace,gap))
    w_s,w_e = promote(float(width_start), float(width_end))
    TaperTrace(w_s, w_e)
end

"""
    struct TaperCPW{T<:Coordinate} <: CPW
        trace_start::T
        gap_start::T
        trace_end::T
        gap_end::T
    end
A CPW with a linearly tapered trace and gap as a function of path length.
"""
struct TaperCPW{T<:Coordinate} <: CPW
    trace_start::T
    gap_start::T
    trace_end::T
    gap_end::T
end
copy(x::TaperCPW) = TaperCPW(x.trace_start, x.gap_start, x.trace_end, x.gap_end)
@inline extent(s::TaperCPW, t) = s.trace_start/2 + s.gap_start + (s.trace_end/2-s.trace_start/2 + s.gap_end-s.gap_start)*t
@inline trace(s::TaperCPW, t) = s.trace_start + (s.trace_end-s.trace_start)*t
@inline gap(s::TaperCPW, t) = s.gap_start + (s.gap_end-s.gap_start)*t
function TaperCPW(trace_start::Coordinate, gap_start::Coordinate, trace_end::Coordinate, gap_end::Coordinate)
    ((dimension(trace_start) != dimension(gap_start)
        || dimension(trace_end) != dimension(gap_end)
        || dimension(trace_start) != dimension(trace_end))
        && throw(DimensionError(trace,gap)))
    t_s,g_s,t_e,g_e = promote(float(trace_start), float(gap_start), float(trace_end), float(gap_end))
    TaperCPW(t_s, g_s, t_e, g_e)
end

summary(s::TaperTrace) = string("Tapered trace with initial width ", s.width_start,
                                " and final width ", s.width_end)
summary(s::TaperCPW) = string("Tapered CPW with initial width ", s.trace_start,
                               " and initial gap ", s.gap_start,
                               " tapers to a final width ", s.trace_end,
                               " and final gap ", s.gap_end)

struct Taper <: ContinuousStyle end
copy(::Taper) = Taper()

"""
    Taper()
Constructor for generic Taper style. Will automatically create a linearly
tapered region between an initial `CPW` or `Trace` and an end `CPW` or `Trace`
of different dimensions. 
"""
Taper

summary(::Taper) = string("Generic tapered region constructing a linear taper ",
                          "between the segment before and segment after its ",
                          "place in the path")
