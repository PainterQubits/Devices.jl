@compat abstract type Trace{T} <: ContinuousStyle{T} end

"""
    immutable GeneralTrace{S,T} <: Trace{T}
        width::S
        meta::T
    end
A single trace with variable width as a function of path length. `width` is callable.
"""
immutable GeneralTrace{S,T} <: Trace{T}
    width::S
    meta::T
end
GeneralTrace(width, meta::Meta=GDSMeta()) = GeneralTrace(width, meta)
copy(x::GeneralTrace) = GeneralTrace(x.width, x.meta)
@inline extent(s::GeneralTrace, t) = s.width(t)/2
@inline width(s::GeneralTrace, t) = s.width(t)

"""
    immutable SimpleTrace{S<:Coordinate,T} <: Trace{T}
        width::S
        meta::T
    end
A single trace with fixed width as a function of path length.
"""
immutable SimpleTrace{S<:Coordinate,T} <: Trace{T}
    width::S
    meta::T
end
SimpleTrace(width, meta::Meta=GDSMeta()) = SimpleTrace(width, meta)
copy(x::SimpleTrace) = Trace(x.width)
@inline extent(s::SimpleTrace, t...) = s.width/2
@inline width(s::SimpleTrace, t...) = s.width

"""
    Trace(width, meta::Meta=GDSMeta())
    Trace(width::Coordinate, meta::Meta=GDSMeta())
Constructor for Trace styles. Automatically chooses `SimpleTrace` or `GeneralTrace` as
appropriate.
"""
Trace(width, meta::Meta=GDSMeta()) = GeneralTrace(width, meta)
Trace(width::Coordinate, meta::Meta=GDSMeta()) = SimpleTrace(float(width), meta)
