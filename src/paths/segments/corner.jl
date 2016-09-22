"""
```
type Corner{T} <: DiscreteSegment{T}
    α::typeof(1.0°)
    p0::Point{T}
    α0::typeof(1.0°)
    extent::T
    Corner(a) = new(a, Point(zero(T),zero(T)), 0.0°, zero(T))
    Corner(a,b,c,d) = new(a,b,c,d)
end
```

A corner, or sudden kink in a path. The only parameter is the angle `α` of the
kink. The kink begins at a point `p0` with initial angle `α0`. It will also
end at `p0`, since the corner has zero path length. However, during rendering,
neighboring segments will be tweaked slightly so that the rendered path is
properly centered about the path function (the rendered corner has a finite width).
"""
type Corner{T} <: DiscreteSegment{T}
    α::typeof(1.0°)
    p0::Point{T}
    α0::typeof(1.0°)
    extent::T
    Corner(a) = new(a, Point(zero(T),zero(T)), 0.0°, zero(T))
    Corner(a,b,c,d) = new(a,b,c,d)
end

"""
```
Corner(α)
```

Outer constructor for `Corner{Float64}` segments. If you are using units,
then you need to specify an appropriate type: `Corner{typeof(1.0nm)}(α)`, for
example.
"""
Corner(α) = Corner{Float64}(α, Point(0.,0.), 0.0°, 0.)
copy{T}(x::Corner{T}) = Corner{T}(x.α, x.p0, x.α0, x.extent)

pathlength(::Corner) = 0
p0(s::Corner) = s.p0
function p1(s::Corner)
    sgn = ifelse(s.α >= 0°, 1, -1)
    ∠A = s.α0+sgn*π/2
    v = s.extent*Point(cos(∠A),sin(∠A))
    ∠B = ∠A + π + s.α
    s.p0+v+s.extent*Point(cos(∠B),sin(∠B))
end
α0(s::Corner) = s.α0
α1(s::Corner) = s.α0 + s.α
setp0!(s::Corner, p::Point) = s.p0 = p
setα0!(s::Corner, α0′) = s.α0 = α0′
summary(s::Corner) = "Corner by $(s.α)"

function corner!{T<:Coordinate}(p::Path{T}, α, sty::DiscreteStyle=discretestyle1(p))
    corn = Corner{T}(α)
    push!(p, Node(corn,sty))
    nothing
end
