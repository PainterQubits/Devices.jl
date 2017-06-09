@compat abstract type CPW <: ContinuousStyle end

"""
    immutable GeneralCPW{S,T} <: CPW
        trace::S
        gap::T
    end
A CPW with variable trace and gap as a function of path length. `trace` and `gap` are
callable.
"""
immutable GeneralCPW{S,T} <: CPW
    trace::S
    gap::T
end
copy(x::GeneralCPW) = GeneralCPW(x.trace, x.gap)
@inline extent(s::GeneralCPW, t) = s.trace(t)/2 + s.gap(t)
@inline trace(s::GeneralCPW, t) = s.trace(t)
@inline gap(s::GeneralCPW, t) = s.gap(t)

"""
    immutable SimpleCPW{T<:Coordinate} <: CPW
        trace::T
        gap::T
    end
A CPW with fixed trace and gap as a function of path length.
"""
immutable SimpleCPW{T<:Coordinate} <: CPW
    trace::T
    gap::T
end
copy(x::SimpleCPW) = SimpleCPW(x.trace, x.gap)
@inline extent(s::SimpleCPW, t...) = s.trace/2 + s.gap
@inline trace(s::SimpleCPW, t...) = s.trace
@inline gap(s::SimpleCPW, t...) = s.gap

"""
    CPW(trace::Coordinate, gap::Coordinate)
    CPW(trace, gap::Coordinate)
    CPW(trace::Coordinate, gap)
    CPW(trace, gap)
Constructors for CPW styles. Automatically chooses between `SimpleCPW` or
`GeneralCPW` styles as appropriate.
"""
function CPW(trace::Coordinate, gap::Coordinate)
    dimension(trace) != dimension(gap) && throw(DimensionError(trace,gap))
    t,g = promote(float(trace), float(gap))
    SimpleCPW(t, g)
end
CPW(trace, gap::Coordinate) = GeneralCPW(trace, x->float(gap))
CPW(trace::Coordinate, gap) = GeneralCPW(x->float(trace), gap)
CPW(trace, gap) = GeneralCPW(trace, gap)

summary(::GeneralCPW) = "CPW with variable width and gap"
summary(s::SimpleCPW) = string("CPW with width ", s.trace, " and gap ", s.gap)
