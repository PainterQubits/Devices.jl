abstract type Trace{T} <: ContinuousStyle{T} end

"""
    struct GeneralTrace{T} <: Trace{false}
        width::T
    end
A single trace with variable width as a function of path length. `width` is callable.
"""
struct GeneralTrace{T} <: Trace{false}
    width::T
end
copy(x::GeneralTrace) = GeneralTrace(x.width)
@inline extent(s::GeneralTrace, t) = s.width(t)/2
@inline width(s::GeneralTrace, t) = s.width(t)

"""
    struct SimpleTrace{T<:Coordinate} <: Trace{false}
        width::T
    end
A single trace with fixed width as a function of path length.
"""
struct SimpleTrace{T<:Coordinate} <: Trace{false}
    width::T
end
SimpleTrace(width) = SimpleTrace(width)
copy(x::SimpleTrace) = Trace(x.width)
@inline extent(s::SimpleTrace, t...) = s.width/2
@inline width(s::SimpleTrace, t...) = s.width

"""
    Trace(width)
    Trace(width::Coordinate)
    Trace(width_start::Coordinate, width_end::Coordinate)
Constructor for Trace styles. Automatically chooses `SimpleTrace`, `GeneralTrace`,
and `TaperTrace` as appropriate.
"""
Trace(width) = GeneralTrace(width)
Trace(width::Coordinate) = SimpleTrace(float(width))

summary(::GeneralTrace) = "Trace with variable width"
summary(s::SimpleTrace) = string("Trace with width ", s.width)
