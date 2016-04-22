"""
`origin{T}(s::Segment{T})`

Return the first point in a segment (calculated).
"""
origin{T}(s::Segment{T}) = s.f(0.0)::Point{2,T}

"""
`lastpoint{T}(s::Segment{T})`

Return the last point in a segment (calculated).
"""
lastpoint{T}(s::Segment{T}) = s.f(1.0)::Point{2,T}

"""
`α0(s::Segment)`

Return the first angle in a segment (calculated).
"""
α0(s::Segment) = direction(s.f, 0.0)

"""
`lastangle(s::Segment)`

Return the last angle in a segment (calculated).
"""
lastangle(s::Segment) = direction(s.f, 1.0)

"""
`length(s::Segment)`

Return the length of a segment (calculated).
"""
function length(s::Segment, diag::Bool=false)
    path = s.f
    ds(t) = sqrt(dot(gradient(s.f, t), gradient(s.f, t)))
    val, err = quadgk(ds, 0.0, 1.0)
    diag && info("Integration estimate: $val")
    diag && info("Error upper bound estimate: $err")
    val
end

"""
`type Straight{T<:Real} <: Segment{T}`

A straight line segment is parameterized by its length.
It begins at a point `origin` with initial angle `α0`.

The parametric function over `t ∈ [0,1]` describing the line segment is given by:

`t -> origin + Point(t*l*cos(α),t*l*sin(α))`
"""
type Straight{T<:Real} <: Segment{T}
    l::T
    origin::Point{2,T}
    α0::Real
    f::Function
    Straight(l, origin, α0) = begin
        s = new(l, origin, α0)
        s.f = t->(s.origin+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end
Straight{T<:Real}(l::T, origin::Point{2,T}=Point(0.0,0.0), α0::Real=0.0) =
    Straight{T}(l, origin, α0)
convert{T<:Real}(::Type{Straight{T}}, x::Straight) =
    Straight(T(x.l), convert(Point{2,T}, x.origin), x.α0)

length(s::Straight) = s.l
origin(s::Straight) = s.origin
α0(s::Straight) = s.α0

"""
`setorigin!(s::Straight, p::Point)`

Set the origin of a straight segment.
"""
setorigin!(s::Straight, p::Point) = s.origin = p

"""
`setα0!(s::Straight, α0′)`

Set the angle of a straight segment.
"""
setα0!(s::Straight, α0′) = s.α0 = α0′

lastangle(s::Straight) = s.α0

"""
`type Turn{T<:Real} <: Segment{T}`

A circular turn is parameterized by the turn angle `α` and turning radius `r`.
It begins at a point `origin` with initial angle `α0`.

The center of the circle is given by:

`cen = origin + Point(r*cos(α0+sign(α)*π/2), r*sin(α0+sign(α)*π/2))`

The parametric function over `t ∈ [0,1]` describing the turn is given by:

`t -> cen + Point(r*cos(α0-sign(α)*π/2+α*t), r*sin(α0-sign(α)*π/2+α*t))`
"""
type Turn{T<:Real} <: Segment{T}
    α::Real
    r::T
    origin::Point{2,T}
    α0::Real
    f::Function

    Turn(α, r, origin, α0) = begin
        s = new(α, r, origin, α0)
        s.f = t->begin
            cen = s.origin + Point(s.r*cos(s.α0+sign(s.α)*π/2), s.r*sin(s.α0+sign(s.α)*π/2))
            cen + Point(s.r*cos(s.α0-sign(α)*π/2+s.α*t), s.r*sin(s.α0-sign(α)*π/2+s.α*t))
        end
        s
    end
end
Turn{T<:Real}(α::Real, r::T, origin::Point{2,T}=Point(0.0,0.0), α0::Real=0.0) =
    Turn{T}(α, r, origin, α0)
convert{T<:Real}(::Type{Turn{T}}, x::Turn) =
    Turn(x.α, T(x.r), convert(Point{2,T}, x.origin), x.α0)

length{T<:Real}(s::Turn{T}) = T(abs(s.r*s.α))
origin(s::Turn) = s.origin
α0(s::Turn) = s.α0

"""
`setorigin!(s::Turn, p::Point)`

Set the origin of a turn.
"""
setorigin!(s::Turn, p::Point) = s.origin = p

"""
`setα0!(s::Turn, α0′)`

Set the starting angle of a turn.
"""
setα0!(s::Turn, α0′) = s.α0 = α0′
lastangle(s::Turn) = s.α0 + s.α

"""
`type CompoundSegment{T<:Real} <: Segment{T}`

Consider an array of segments as one contiguous segment.
Useful e.g. for applying styles, uninterrupted over segment changes.
"""
type CompoundSegment{T<:Real} <: Segment{T}
    segments::Array{Segment{T},1}
    f::Function

    CompoundSegment(segments) = begin
        s = new(segments)
        s.f = param(s)
        s
    end
end
CompoundSegment{T<:Real}(segments::Array{Segment{T},1}) =
    CompoundSegment{T}(segments)

"""
`setorigin!(s::CompoundSegment, p::Point)`

Set the origin of a compound segment.
"""
function setorigin!(s::CompoundSegment, p::Point)
    setorigin!(s.segments[1], p)
    for i in 2:length(s.segments)
        setorigin!(s.segments[i], lastpoint(s.segments[i-1]))
    end
end

"""
`setα0!(s::CompoundSegment, α0′)`

Set the starting angle of a compound segment.
"""
function setα0!(s::CompoundSegment, α0′)
    setα0!(s.segments[1], α0′)
    for i in 2:length(s.segments)
        setα0!(s.segments[i], lastangle(s.segments[i-1]))
    end
end
