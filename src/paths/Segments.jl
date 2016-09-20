"""
```
p0{T}(s::Segment{T})
```

Return the first point in a segment (calculated).
"""
p0{T}(s::Segment{T}) = s.f(0.0)::Point{T}

"""
```
p1{T}(s::Segment{T})
```

Return the last point in a segment (calculated).
"""
p1{T}(s::Segment{T}) = s.f(1.0)::Point{T}

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
pathlength{T}(s::Segment{T}, verbose::Bool=false)
```

Return the length of a segment (calculated).
"""
function pathlength{T}(s::Segment{T}, verbose::Bool=false)
    path = s.f
    ds(t) = ustrip(sqrt(dot(ForwardDiff.derivative(s.f, t),
                            ForwardDiff.derivative(s.f, t))))
    val, err = quadgk(ds, 0.0, 1.0)
    verbose && info("Integration estimate: $val")
    verbose && info("Error upper bound estimate: $err")
    val * unit(T)
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
type Straight{T} <: Segment{T}
    l::T
    p0::Point{T}
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
type Straight{T} <: Segment{T}
    l::T
    p0::Point{T}
    α0::Real
    f::Function
    Straight(l, p0, α0) = begin
        s = new(l, p0, α0)
        s.f = t->(s.p0+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end

"""
```
Straight{T<:Coordinate}(l::T, p0::Point{T}=Point(0.0,0.0), α0::Real=0.0)
```

Outer constructor for `Straight` segments.
"""
Straight{T<:Coordinate}(l::T, p0::Point{T}=Point(0.0,0.0), α0::Real=0.0) =
    Straight{T}(l, p0, α0)
convert{T}(::Type{Straight{T}}, x::Straight) =
    Straight(T(x.l), convert(Point{T}, x.p0), x.α0)

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

"""
```
type Turn{T} <: Segment{T}
    α::typeof(1.0°)
    r::T
    p0::Point{T}
    α0::typeof(1.0°)
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
type Turn{T} <: Segment{T}
    α::typeof(1.0°)
    r::T
    p0::Point{T}
    α0::typeof(1.0°)
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

"""
```
Turn{T<:Coordinate}(α, r::T, p0::Point{T}=Point(0.0,0.0), α0::Real=0.0)
```

Outer constructor for `Turn` segments.
"""
Turn{T<:Coordinate}(α, r::T, p0::Point{T}=Point(zero(T),zero(T)), α0=0.0) =
    Turn{T}(α, r, p0, α0)
convert{T}(::Type{Turn{T}}, x::Turn) =
    Turn(x.α, T(x.r), convert(Point{T}, x.p0), x.α0)
copy(s::Turn) = Turn(s.α,s.r,s.p0,s.α0)

pathlength{T}(s::Turn{T}) = T(abs(s.r*s.α))
p0(s::Turn) = s.p0
α0(s::Turn) = s.α0
summary(s::Turn) = "Turn by $(s.α) with radius $(s.r)"

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

type Corner{T} <: Segment{T}
    α::typeof(1.0°)
    p0::Point{T}
    α0::typeof(1.0°)
    extent::Real
    Corner(a) = new(a,Point(0.,0.),0.,0.)
    Corner(a,b,c,d) = new(a,b,c,d)
end
Corner(α) = Corner{Float64}(α, Point(0.,0.), 0., 0.)
copy{T}(x::Corner{T}) = Corner{T}(x.α, x.p0, x.α0, x.extent)

pathlength(::Corner) = 0
p0(s::Corner) = s.p0
function p1(s::Corner)
    sgn = ifelse(s.α >= 0, 1, -1)
    ∠A = s.α0+sgn*π/2
    v = s.extent*Point(cos(∠A),sin(∠A))
    ∠B = -∠A + s.α
    s.p0+v+s.extent*Point(cos(∠B),sin(∠B))
end
α0(s::Corner) = s.α0
α1(s::Corner) = s.α0 + s.α
setp0!(s::Corner, p::Point) = s.p0 = p
setα0!(s::Corner, α0′) = s.α0 = α0′
summary(s::Corner) = "Corner by "*(@sprintf "%0.3f" s.α)

"""
```
type CompoundSegment{T} <: Segment{T}
    segments::Vector{Segment{T}}
    f::Function

    CompoundSegment(segments) = begin
        if any(x->isa(x,Corner), segments)
            error("cannot have corners in a `CompoundSegment`. You may have ",
                "tried to simplify a path containing `Corner` objects.")
        else
            s = new(deepcopy(Array(segments)))
            s.f = param(s.segments)
            s
        end
    end
end
```

Consider an array of segments as one contiguous segment.
Useful e.g. for applying styles, uninterrupted over segment changes.
The array of segments given to the constructor is copied and retained
by the compound segment.

Note that [`Corner`](@ref)s introduce a discontinuity in the derivative of the
path function, and are not allowed in a `CompoundSegment`.
"""
type CompoundSegment{T} <: Segment{T}
    segments::Vector{Segment{T}}
    f::Function

    CompoundSegment(segments) = begin
        if any(x->isa(x,Corner), segments)
            error("cannot have corners in a `CompoundSegment`. You may have ",
                "tried to simplify a path containing `Corner` objects.")
        else
            s = new(deepcopy(Array(segments)))
            s.f = param(s.segments)
            s
        end
    end
end
CompoundSegment{T}(nodes::AbstractArray{Node{T},1}) =
    CompoundSegment{T}(map(segment, nodes))

copy{T}(s::CompoundSegment{T}) = CompoundSegment{T}(s.segments)

function setα0p0!(s::CompoundSegment, angle, p::Point)
    setα0p0!(s.segments[1], angle, p)
    for i in 2:length(s.segments)
        setα0p0!(s.segments[i], α1(s.segments[i-1]), p1(s.segments[i-1]))
    end
end
