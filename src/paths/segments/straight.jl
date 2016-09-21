"""
```
type Straight{T} <: Segment{T}
    l::T
    p0::Point{T}
    α0::typeof(0.0°)
    f::Function
    Straight(l, p0, α0) = begin
        s = new(l, p0, α0)
        s.f = t->(s.p0+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end
```

A straight line segment is parameterized by its length.
It begins at a point `p0` with initial angle `α0`.

The parametric function over `t ∈ [0,1]` describing the line segment is given by:

`t -> p0 + Point(t*l*cos(α),t*l*sin(α))`
"""
type Straight{T} <: Segment{T}
    l::T
    p0::Point{T}
    α0::typeof(0.0°)
    f::Function
    Straight(l, p0, α0) = begin
        s = new(l, p0, α0)
        s.f = t->(s.p0+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end

"""
```
Straight{T<:Coordinate}(l::T; p0::Point{T}=Point(0.0,0.0), α0=0.0°)
```

Outer constructor for `Straight` segments.
"""
Straight{T<:Coordinate}(l::T; p0::Point{T}=Point(0.0,0.0), α0=0.0°) =
    Straight{T}(l, p0, α0)
convert{T}(::Type{Straight{T}}, x::Straight) =
    Straight(convert(T, x.l), convert(Point{T}, x.p0), x.α0)

copy(s::Straight) = Straight(s.l,s.p0,s.α0)
pathlength(s::Straight) = s.l
p0(s::Straight) = s.p0
α0(s::Straight) = s.α0
summary(s::Straight) = "Straight by $(s.l)"

"""
```
setp0!(s::Straight, p::Point)
```

Set the p0 of a straight segment.
"""
setp0!(s::Straight, p::Point) = s.p0 = p

"""
```
setα0!(s::Straight, α0′)
```

Set the angle of a straight segment.
"""
setα0!(s::Straight, α0′) = s.α0 = α0′

α1(s::Straight) = s.α0
