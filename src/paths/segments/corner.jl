"""
    mutable struct Corner{T} <: DiscreteSegment{T}
        α::Float64
        p0::Point{T}
        α0::Float64
        extent::T
        Corner(a) = new(a, Point(zero(T), zero(T)), 0.0, zero(T))
        Corner(a,b,c,d) = new(a,b,c,d)
    end
A corner, or sudden kink in a path. The only parameter is the angle `α` of the
kink. The kink begins at a point `p0` with initial angle `α0`. It will also
end at `p0`, since the corner has zero path length. However, during rendering,
neighboring segments will be tweaked slightly so that the rendered path is
properly centered about the path function (the rendered corner has a finite width).
"""
mutable struct Corner{T} <: DiscreteSegment{T}
    α::Float64
    p0::Point{T}
    α0::Float64
    extent::T
    (::Type{Corner{T}}){T}(a) = new{T}(a, Point(zero(T), zero(T)), 0.0, zero(T))
    (::Type{Corner{T}}){T}(a,b,c,d) = new{T}(a,b,c,d)
end

"""
    Corner(α)
Outer constructor for `Corner{Float64}` segments. If you are using units,
then you need to specify an appropriate type: `Corner{typeof(1.0nm)}(α)`, for
example. More likely, you will just use [`corner!`](@ref) rather than
directly creating a `Corner` object.
"""
Corner(α) = Corner{Float64}(α, Point(0.,0.), 0.0, 0.)
copy(x::Corner{T}) where {T} = Corner{T}(x.α, x.p0, x.α0, x.extent)

pathlength(::Corner) = 0
p0(s::Corner) = s.p0
function p1(s::Corner)
    sgn = ifelse(s.α >= 0.0, 1, -1)
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


"""
    corner!{T<:Coordinate}(p::Path{T}, α, sty::DiscreteStyle=discretestyle1(p))
Append a sharp turn or "corner" to path `p` with angle `α`.

The style chosen for this corner, if not specified, is the last `DiscreteStyle`
used in the path.
"""
function corner!(p::Path{T}, α, sty::DiscreteStyle=discretestyle1(p)) where {T <: Coordinate}
    corn = Corner{T}(α)
    push!(p, Node(corn, DiscreteStyle(sty)))
    nothing
end
