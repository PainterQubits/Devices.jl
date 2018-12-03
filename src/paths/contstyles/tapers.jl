"""
    struct TaperTrace{T<:Coordinate} <: Trace{true}
        width_start::T
        width_end::T
        length::T
    end
A single trace with a linearly tapered width as a function of path length.
"""
struct TaperTrace{T<:Coordinate} <: Trace{true}
    width_start::T
    width_end::T
    length::T
    TaperTrace{T}(ws::T, we::T) where {T<:Coordinate} = new{T}(ws, we)
    TaperTrace{T}(ws::T, we::T, l) where {T<:Coordinate} = new{T}(ws, we, l)
end
copy(x::TaperTrace) = TaperTrace(x.width_start, x_width_end)
extent(s::TaperTrace, t) = 0.5 * width(s,t)
width(s::TaperTrace, t) = (1-t/s.length) * s.width_start + t/s.length * s.width_end
function pin(s::TaperTrace; start=nothing, stop=nothing)
    !isdefined(s, :length) && error("cannot `pin`; length of $s not yet determined.")
    x0 = ifelse(start === nothing, zero(s.length), start)
    x1 = ifelse(stop === nothing, s.length, stop)
    @assert x1 - x0 > zero(x1 - x0)
    @assert zero(x0) <= x0 < s.length
    @assert zero(x1) < x1 <= s.length
    return typeof(s)(width(s, x0), width(s, x1), x1-x0)
end
function TaperTrace(width_start::Coordinate, width_end::Coordinate)
    dimension(width_start) != dimension(width_end) && throw(DimensionError(trace,gap))
    w_s,w_e = promote(float(width_start), float(width_end))
    return TaperTrace{typeof(w_s)}(w_s, w_e)
end

"""
    struct TaperCPW{T<:Coordinate} <: CPW{true}
        trace_start::T
        gap_start::T
        trace_end::T
        gap_end::T
        length::T
    end
A CPW with a linearly tapered trace and gap as a function of path length.
"""
struct TaperCPW{T<:Coordinate} <: CPW{true}
    trace_start::T
    gap_start::T
    trace_end::T
    gap_end::T
    length::T
    TaperCPW{T}(ts::T, gs::T, te::T, ge::T) where {T<:Coordinate} = new{T}(ts, gs, te, ge)
    TaperCPW{T}(ts::T, gs::T, te::T, ge::T, l) where {T<:Coordinate} =
        new{T}(ts, gs, te, ge, l)
end
copy(x::TaperCPW) = TaperCPW(x.trace_start, x.gap_start, x.trace_end, x.gap_end)
extent(s::TaperCPW, t) = (1-t/s.length) * (0.5*s.trace_start + s.gap_start) +
    (t/s.length) * (0.5*s.trace_end + s.gap_end)
trace(s::TaperCPW, t) = (1-t/s.length) * s.trace_start + t/s.length * s.trace_end
gap(s::TaperCPW, t) = (1-t/s.length) * s.gap_start + t/s.length * s.gap_end
function TaperCPW(trace_start::Coordinate, gap_start::Coordinate, trace_end::Coordinate, gap_end::Coordinate)
    ((dimension(trace_start) != dimension(gap_start)
        || dimension(trace_end) != dimension(gap_end)
        || dimension(trace_start) != dimension(trace_end))
        && throw(DimensionError(trace,gap)))
    t_s,g_s,t_e,g_e = promote(float(trace_start), float(gap_start), float(trace_end), float(gap_end))
    return TaperCPW{typeof(t_s)}(t_s, g_s, t_e, g_e)
end
function pin(sty::TaperCPW; start=nothing, stop=nothing)
    !isdefined(sty, :length) && error("cannot `pin`; length of $sty not yet determined.")
    x0 = ifelse(start === nothing, zero(sty.length), start)
    x1 = ifelse(stop === nothing, sty.length, stop)
    @assert x1 - x0 > zero(x1 - x0)
    @assert zero(x0) <= x0 < sty.length
    @assert zero(x1) < x1 <= sty.length
    return typeof(sty)(trace(sty, x0), gap(sty, x0), trace(sty, x1), gap(sty, x1), x1 - x0)
end

summary(s::TaperTrace) = string("Tapered trace with initial width ", s.width_start,
                                " and final width ", s.width_end)
summary(s::TaperCPW) = string("Tapered CPW with initial width ", s.trace_start,
                               " and initial gap ", s.gap_start,
                               " tapers to a final width ", s.trace_end,
                               " and final gap ", s.gap_end)

"""
    Taper()
Constructor for generic Taper style. Will automatically create a linearly tapered region
between an initial `CPW` or `Trace` and an end `CPW` or `Trace` of different dimensions.
"""
struct Taper <: ContinuousStyle{false} end
copy(::Taper) = Taper()

summary(::Taper) = string("Generic linear taper between neighboring segments in a path")
