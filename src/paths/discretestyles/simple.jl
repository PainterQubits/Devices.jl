"""
    immutable SimpleTraceCorner{T} <: DiscreteStyle{T}
"""
immutable SimpleTraceCorner{T} <: DiscreteStyle{T}
    meta::T
end
SimpleTraceCorner() = SimpleTraceCorner(GDSMeta())
