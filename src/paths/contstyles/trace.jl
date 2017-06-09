@compat abstract type Trace <: ContinuousStyle end

"""
    immutable GeneralTrace{T} <: Trace
        width::T
    end
A single trace with variable width as a function of path length. `width` is callable.
"""
immutable GeneralTrace{T} <: Trace
    width::T
end
copy(x::GeneralTrace) = GeneralTrace(x.width)
@inline extent(s::GeneralTrace, t) = s.width(t)/2
@inline width(s::GeneralTrace, t) = s.width(t)

"""
    immutable SimpleTrace{T<:Coordinate} <: Trace
        width::T
    end
A single trace with fixed width as a function of path length.
"""
immutable SimpleTrace{T<:Coordinate} <: Trace
    width::T
end
SimpleTrace(width) = SimpleTrace(width)
copy(x::SimpleTrace) = Trace(x.width)
@inline extent(s::SimpleTrace, t...) = s.width/2
@inline width(s::SimpleTrace, t...) = s.width

"""
    Trace(width)
    Trace(width::Coordinate)
Constructor for Trace styles. Automatically chooses `SimpleTrace` or `GeneralTrace` as
appropriate.
"""
Trace(width) = GeneralTrace(width)
Trace(width::Coordinate) = SimpleTrace(float(width))

summary(::GeneralTrace) = "Trace with variable width"
summary(s::SimpleTrace) = string("Trace with width ", s.width)
