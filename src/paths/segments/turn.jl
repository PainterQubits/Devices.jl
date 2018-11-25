"""
    mutable struct Turn{T} <: ContinuousSegment{T}
A circular turn is parameterized by the turn angle `α` and turning radius `r`.
It begins at a point `p0` with initial angle `α0`.
"""
mutable struct Turn{T} <: ContinuousSegment{T}
    α::typeof(1.0°)
    r::T
    p0::Point{T}
    α0::Float64
end
function (s::Turn)(t)
    x = ifelse(s.r == zero(s.r), typeof(s.r)(one(s.r)), s.r) # guard against div by zero
    cen = s.p0 + Point(s.r*cos(s.α0+sign(s.α)*π/2), s.r*sin(s.α0+sign(s.α)*π/2))
    cen + Point(s.r*cos(s.α0-sign(s.α)*(π/2-t/x)), s.r*sin(s.α0-sign(s.α)*(π/2-t/x)))
end

"""
    Turn(α, r::T, p0::Point{T}=Point(0.0,0.0), α0=0.0°) where {T<:Coordinate}
Outer constructor for `Turn` segments.
"""
Turn(α, r::T; p0::Point=Point(zero(T),zero(T)), α0=0.0°) where {T <: Coordinate} =
    Turn{T}(α, r, p0, α0)
convert(::Type{Turn{T}}, x::Turn) where {T} =
    Turn{T}(x.α, T(x.r), convert(Point{T}, x.p0), x.α0)
copy(s::Turn{T}) where {T} = Turn{T}(s.α,s.r,s.p0,s.α0)

pathlength(s::Turn{T}) where {T} = convert(T, abs(s.r*s.α))
p0(s::Turn) = s.p0
α0(s::Turn) = s.α0
summary(s::Turn) = "Turn by $(s.α) with radius $(s.r)"

"""
    setp0!(s::Turn, p::Point)
Set the p0 of a turn.
"""
setp0!(s::Turn, p::Point) = s.p0 = p

"""
    setα0!(s::Turn, α0′)
Set the starting angle of a turn.
"""
setα0!(s::Turn, α0′) = s.α0 = α0′

α1(s::Turn) = s.α0 + s.α

"""
    turn!(p::Path, α, r::Coordinate, sty::Style=contstyle1(p))
Turn a path `p` by angle `α` with a turning radius `r` in the current direction.
Positive angle turns left. By default, we take the last continuous style in the path.
"""
function turn!(p::Path, α, r::Coordinate, sty::Style=contstyle1(p))
    T = eltype(p)
    dimension(T) != dimension(typeof(r)) && throw(DimensionError(T(1),r))
    seg = Turn{T}(α, r, p1(p), α1(p))
    push!(p, Node(seg, convert(ContinuousStyle, sty)))
    nothing
end

"""
    turn!(p::Path, str::String, r::Coordinate, sty::Style=contstyle1(p))
Turn a path `p` with direction coded by string `str`:

- "l": turn by π/2 radians (left)
- "r": turn by -π/2 radians (right)
- "lrlrllrrll": do those turns in that order

By default, we take the last continuous style in the path.
"""
function turn!(p::Path, str::String, r::Coordinate, sty::Style=contstyle1(p))
    T = eltype(p)
    dimension(T) != dimension(typeof(r)) && throw(DimensionError(T(1),r))
    for ch in str
        if ch == 'l'
            α = π/2
        elseif ch == 'r'
            α = -π/2
        else
            error("Unrecognizable turn command.")
        end
        seg = Turn{T}(α, r, p1(p), α1(p))
        # convert takes NoRender() → NoRenderContinuous()
        push!(p, Node(seg, convert(ContinuousStyle, sty)))
    end
    nothing
end

function _split(seg::Turn{T}, x) where {T}
    r, α = seg.r, seg.α
    α1 = x / r
    α2 = α - α1
    s1 = Turn{T}(α1, seg.r, seg.p0, seg.α0)
    s2 = Turn{T}(α2, seg.r, seg(x), seg.α0 + α1)
    return s1, s2
end
