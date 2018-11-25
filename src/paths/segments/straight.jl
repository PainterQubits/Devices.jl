"""
    mutable struct Straight{T} <: ContinuousSegment{T}
A straight line segment is parameterized by its length.
It begins at a point `p0` with initial angle `α0`.
"""
mutable struct Straight{T} <: ContinuousSegment{T}
    l::T
    p0::Point{T}
    α0::Float64
end
(s::Straight)(t) = s.p0+Point(t*cos(s.α0), t*sin(s.α0))

"""
    Straight(l::T; p0::Point=Point(zero(T),zero(T)), α0=0.0°) where {T<:Coordinate}
Outer constructor for `Straight` segments.
"""
Straight(l::T; p0::Point=Point(zero(T),zero(T)), α0=0.0°) where {T <: Coordinate} =
    Straight{T}(l, p0, α0)
convert(::Type{Straight{T}}, x::Straight) where {T} =
    Straight{T}(convert(T, x.l), convert(Point{T}, x.p0), x.α0)

copy(s::Straight{T}) where {T} = Straight{T}(s.l, s.p0, s.α0)
pathlength(s::Straight) = s.l
p0(s::Straight) = s.p0
α0(s::Straight) = s.α0
summary(s::Straight) = "Straight by $(s.l)"

"""
    setp0!(s::Straight, p::Point)
Set the p0 of a straight segment.
"""
setp0!(s::Straight, p::Point) = s.p0 = p

"""
    setα0!(s::Straight, α0′)
Set the angle of a straight segment.
"""
setα0!(s::Straight, α0′) = s.α0 = α0′

α1(s::Straight) = s.α0

"""
    straight!(p::Path, l::Coordinate, sty::Style=contstyle1(p))
Extend a path `p` straight by length `l` in the current direction. By default,
we take the last continuous style in the path.
"""
function straight!(p::Path, l::Coordinate, sty::Style=contstyle1(p))
    T = eltype(p)
    dimension(T) != dimension(typeof(l)) && throw(DimensionError(T(1),l))
    @assert l >= zero(l) "tried to go straight by a negative amount."
    seg = Straight{T}(l, p1(p), α1(p))
    # convert takes NoRender() → NoRenderContinuous()
    push!(p, Node(seg, convert(ContinuousStyle, sty)))
    nothing
end

function _split(seg::Straight{T}, x) where {T}
    s1 = Straight{T}(x, seg.p0, seg.α0)
    s2 = Straight{T}(seg.l - x, seg(x), seg.α0)
    return s1, s2
end
