@compat abstract type CPW{T} <: ContinuousStyle{T} end

"""
    immutable GeneralCPW{R,S,T} <: CPW{T}
        trace::R
        gap::S
        meta::T
    end
A CPW with variable trace and gap as a function of path length. `trace` and `gap` are
callable.
"""
immutable GeneralCPW{R,S,T} <: CPW{T}
    trace::R
    gap::S
    meta::T
end
copy(x::GeneralCPW) = GeneralCPW(x.trace, x.gap, x.meta)
@inline extent(s::GeneralCPW, t) = s.trace(t)/2 + s.gap(t)
@inline trace(s::GeneralCPW, t) = s.trace(t)
@inline gap(s::GeneralCPW, t) = s.gap(t)

"""
    immutable SimpleCPW{S<:Coordinate,T} <: CPW{T}
        trace::S
        gap::S
        meta::T
    end
A CPW with fixed trace and gap as a function of path length.
"""
immutable SimpleCPW{S<:Coordinate,T} <: CPW{T}
    trace::S
    gap::S
    meta::T
end
copy(x::SimpleCPW) = SimpleCPW(x.trace, x.gap, x.meta)
@inline extent(s::SimpleCPW, t...) = s.trace/2 + s.gap
@inline trace(s::SimpleCPW, t...) = s.trace
@inline gap(s::SimpleCPW, t...) = s.gap

"""
    CPW(trace::Coordinate, gap::Coordinate)
    CPW(trace, gap::Coordinate)
    CPW(trace::Coordinate, gap)
    CPW(trace, gap)
Constructor for CPW styles. Automatically chooses `SimpleCPW` or `GeneralCPW` as
appropriate.
"""
function CPW(trace::Coordinate, gap::Coordinate, meta::Meta=GDSMeta())
    dimension(trace) != dimension(gap) && throw(DimensionError(trace,gap))
    t,g = promote(float(trace), float(gap))
    SimpleCPW(t, g, meta)
end
CPW(trace, gap::Coordinate, meta::Meta=GDSMeta()) = GeneralCPW(trace, x->float(gap), meta)
CPW(trace::Coordinate, gap, meta::Meta=GDSMeta()) = GeneralCPW(x->float(trace), gap, meta)
CPW(trace, gap, meta::Meta=GDSMeta()) = GeneralCPW(trace, gap, meta)
