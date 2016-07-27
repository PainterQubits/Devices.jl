"""
```
p0{T}(s::Segment{T})
```

Return the first point in a segment (calculated).
"""
p0{T}(s::Segment{T}) = s.f(0.0)::Point{2,T}

"""
```
p1{T}(s::Segment{T})
```

Return the last point in a segment (calculated).
"""
p1{T}(s::Segment{T}) = s.f(1.0)::Point{2,T}

"""
```
α0(s::Segment)
```

Return the first angle in a segment (calculated).
"""
α0(s::Segment) = direction(s.f, 0.0)

"""
```
α1(s::Segment)
```

Return the last angle in a segment (calculated).
"""
α1(s::Segment) = direction(s.f, 1.0)

function setα0p0!(s::Segment, angle, p::Point)
    setα0!(s, angle)
    setp0!(s, p)
end

"""
```
length(s::Segment, verbose::Bool=false)
```

Return the length of a segment (calculated).
"""
function length(s::Segment, verbose::Bool=false)
    path = s.f
    ds(t) = sqrt(dot(ForwardDiff.derivative(s.f, t), ForwardDiff.derivative(s.f, t)))
    val, err = quadgk(ds, 0.0, 1.0)
    verbose && info("Integration estimate: $val")
    verbose && info("Error upper bound estimate: $err")
    val
end

show(io::IO, s::Segment) = print(io, summary(s))

function deepcopy_internal(x::Segment, stackdict::ObjectIdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = copy(x)
    stackdict[x] = y
    return y
end

"""
```
type Straight{T<:Real} <: Segment{T}
    l::T
    p0::Point{2,T}
    α0::Real
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
type Straight{T<:Real} <: Segment{T}
    l::T
    p0::Point{2,T}
    α0::Real
    f::Function
    Straight(l, p0, α0) = begin
        s = new(l, p0, α0)
        s.f = t->(s.p0+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end
Straight{T<:Real}(l::T, p0::Point{2,T}=Point(0.0,0.0), α0::Real=0.0) =
    Straight{T}(l, p0, α0)
convert{T<:Real}(::Type{Straight{T}}, x::Straight) =
    Straight(T(x.l), convert(Point{2,T}, x.p0), x.α0)

copy(s::Straight) = Straight(s.l,s.p0,s.α0)
length(s::Straight) = s.l
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

"""
```
type Turn{T<:Real} <: Segment{T}
    α::Real
    r::T
    p0::Point{2,T}
    α0::Real
    f::Function
    Turn(α, r, p0, α0) = begin
        s = new(α, r, p0, α0)
        s.f = t->begin
            cen = s.p0 + Point(s.r*cos(s.α0+sign(s.α)*π/2), s.r*sin(s.α0+sign(s.α)*π/2))
            cen + Point(s.r*cos(s.α0-sign(α)*π/2+s.α*t), s.r*sin(s.α0-sign(α)*π/2+s.α*t))
        end
        s
    end
end
```

A circular turn is parameterized by the turn angle `α` and turning radius `r`.
It begins at a point `p0` with initial angle `α0`.

The center of the circle is given by:

`cen = p0 + Point(r*cos(α0+sign(α)*π/2), r*sin(α0+sign(α)*π/2))`

The parametric function over `t ∈ [0,1]` describing the turn is given by:

`t -> cen + Point(r*cos(α0-sign(α)*π/2+α*t), r*sin(α0-sign(α)*π/2+α*t))`
"""
type Turn{T<:Real} <: Segment{T}
    α::Real
    r::T
    p0::Point{2,T}
    α0::Real
    f::Function

    Turn(α, r, p0, α0) = begin
        s = new(α, r, p0, α0)
        s.f = t->begin
            cen = s.p0 + Point(s.r*cos(s.α0+sign(s.α)*π/2), s.r*sin(s.α0+sign(s.α)*π/2))
            cen + Point(s.r*cos(s.α0-sign(α)*π/2+s.α*t), s.r*sin(s.α0-sign(α)*π/2+s.α*t))
        end
        s
    end
end
Turn{T<:Real}(α::Real, r::T, p0::Point{2,T}=Point(0.0,0.0), α0::Real=0.0) =
    Turn{T}(α, r, p0, α0)
convert{T<:Real}(::Type{Turn{T}}, x::Turn) =
    Turn(x.α, T(x.r), convert(Point{2,T}, x.p0), x.α0)
copy(s::Turn) = Turn(s.α,s.r,s.p0,s.α0)

length{T<:Real}(s::Turn{T}) = T(abs(s.r*s.α))
p0(s::Turn) = s.p0
α0(s::Turn) = s.α0
summary(s::Turn) = "Turn by "*(@sprintf "%0.3f" s.α)*" with radius $(s.r)"

"""
```
setp0!(s::Turn, p::Point)
```

Set the p0 of a turn.
"""
setp0!(s::Turn, p::Point) = s.p0 = p

"""
```
setα0!(s::Turn, α0′)
```

Set the starting angle of a turn.
"""
setα0!(s::Turn, α0′) = s.α0 = α0′

α1(s::Turn) = s.α0 + s.α

"""
```
type CompoundSegment{T<:Real} <: Segment{T}
    segments::Array{Segment{T},1}
    f::Function

    CompoundSegment(segments) = begin
        s = new(Array(segments))
        s.f = param(s)
        s
    end
end
```

Consider an array of segments as one contiguous segment.
Useful e.g. for applying styles, uninterrupted over segment changes.
The array of segments given to the constructor is copied and retained
by the compound segment.
"""
type CompoundSegment{T<:Real} <: Segment{T}
    segments::Array{Segment{T},1}
    f::Function

    CompoundSegment(segments) = begin
        s = new(deepcopy(Array(segments)))
        s.f = param(s)
        s
    end
end
CompoundSegment{T<:Real}(segments::Array{Segment{T},1}) =
    CompoundSegment{T}(segments)
copy(s::CompoundSegment) = CompoundSegment(s.segments)


function setα0p0!(s::CompoundSegment, angle, p::Point)
    setα0p0!(s.segments[1], angle, p)
    for i in 2:length(s.segments)
        setα0p0!(s.segments[i], α1(s.segments[i-1]), p1(s.segments[i-1]))
    end
end
