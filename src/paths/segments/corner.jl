type Corner{T} <: Segment{T}
    α::typeof(1.0°)
    p0::Point{T}
    α0::typeof(1.0°)
    extent::T
    Corner(a) = new(a, Point(zero(T),zero(T)), 0.0°, zero(T))
    Corner(a,b,c,d) = new(a,b,c,d)
end
Corner(α) = Corner{Float64}(α, Point(0.,0.), 0.0°, 0.)
copy{T}(x::Corner{T}) = Corner{T}(x.α, x.p0, x.α0, x.extent)

pathlength(::Corner) = 0
p0(s::Corner) = s.p0
function p1(s::Corner)
    sgn = ifelse(s.α >= 0°, 1, -1)
    ∠A = s.α0+sgn*π/2
    v = s.extent*Point(cos(∠A),sin(∠A))
    ∠B = -∠A + s.α
    s.p0+v+s.extent*Point(cos(∠B),sin(∠B))
end
α0(s::Corner) = s.α0
α1(s::Corner) = s.α0 + s.α
setp0!(s::Corner, p::Point) = s.p0 = p
setα0!(s::Corner, α0′) = s.α0 = α0′
summary(s::Corner) = "Corner by $(s.α)"
