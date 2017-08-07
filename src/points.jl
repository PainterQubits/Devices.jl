module Points

import Devices: PointTypes, InverseLength, lowerleft, upperright
import StaticArrays
import StaticArrays: @SMatrix
import CoordinateTransformations: LinearMap, Translation, ∘, compose
import Clipper: IntPoint
import Base: convert, *, summary, promote_rule, show, reinterpret
import Base: scalarmin, scalarmax, isapprox
import ForwardDiff: ForwardDiff, extract_derivative
import Unitful: Unitful, Length, ustrip, unit

export Point
export Rotation, Translation, XReflection, YReflection, ∘, compose
export getx, gety

struct Point{T<:PointTypes} <: StaticArrays.FieldVector{2,T}
    x::T
    y::T
    (::Type{Point{T}}){T}(x,y) = new{T}(x,y)
end

"""
    struct Point{T} <: StaticArrays.FieldVector{2,T}
        x::T
        y::T
    end
2D Cartesian coordinate in the plane.
"""
Point

StaticArrays.similar_type(::Type{P}, ::Type{T},
    ::StaticArrays.Size{(2,)}) where {P <: Point,T} = Point{T}

Point(x::Number, y::Number) =
    error("Cannot use `Point` with this combination of types.")
Point(x::Length, y::Length) = Point{promote_type(typeof(x),typeof(y))}(x,y)
Point(x::InverseLength, y::InverseLength) = Point{promote_type(typeof(x),typeof(y))}(x,y)
Point(x::Real, y::Real) = Point{promote_type(typeof(x),typeof(y))}(x,y)

convert(::Type{Point{T}}, x::IntPoint) where {T <: Real} = Point{T}(x.X, x.Y)
promote_rule(::Type{Point{S}}, ::Type{Point{T}}) where {S <: Real,T <: Real} =
    Point{promote_type(S,T)}
promote_rule(::Type{Point{S}}, ::Type{Point{T}}) where {S <: Length,T <: Length} =
    Point{promote_type(S,T)}
promote_rule(::Type{Point{S}}, ::Type{Point{T}}) where {S <: InverseLength,T <: InverseLength} =
    Point{promote_type(S,T)}
show(io::IO, p::Point) = print(io, "(",string(getx(p)),",",string(gety(p)),")")

function reinterpret(::Type{T}, a::Point{S}) where {T,S}
    nel = Int(div(length(a)*sizeof(S),sizeof(T)))
    return reinterpret(T, a, (nel,))
end

"""
    getx(p::Point)
Get the x-coordinate of a point. You can also use `p.x` or `p[1]`.
"""
@inline getx(p::Point) = p.x

"""
    gety(p::Point)
Get the y-coordinate of a point. You can also use `p.y` or `p[2]`.
"""
@inline gety(p::Point) = p.y

for f in (:+, :-)
    @eval Base.broadcast(::typeof($f), a::AbstractArray{Point{S}}, p::Point{T}) where {S,T} =
        broadcast($f, a, StaticArrays.Scalar(p))
    @eval Base.broadcast(::typeof($f), p::Point{T}, a::AbstractArray{Point{S}}) where {S,T} =
        broadcast($f, StaticArrays.Scalar(p), a)
end

"""
    lowerleft{T}(A::AbstractArray{Point{T}})
Returns the lower-left [`Point`](@ref) of the smallest bounding rectangle
(with sides parallel to the x- and y-axes) that contains all points in `A`.

Example:
```jldoctest
julia> lowerleft([Point(2,0),Point(1,1),Point(0,2),Point(-1,3)])
2-element Devices.Points.Point{Int64}:
 -1
  0
```
"""
function lowerleft(A::AbstractArray{Point{T}}) where {T}
    B = reinterpret(T, A, (2*length(A),))
    @inbounds Bx = view(B, 1:2:length(B))
    @inbounds By = view(B, 2:2:length(B))
    Point(minimum(Bx), minimum(By))
end

"""
    upperright{T}(A::AbstractArray{Point{T}})
Returns the upper-right [`Point`](@ref) of the smallest bounding rectangle
(with sides parallel to the x- and y-axes) that contains all points in `A`.

Example:
```jldoctest
julia> upperright([Point(2,0),Point(1,1),Point(0,2),Point(-1,3)])
2-element Devices.Points.Point{Int64}:
 2
 3
```
"""
function upperright(A::AbstractArray{Point{T}}) where {T}
    B = reinterpret(T, A, (2*length(A),))
    @inbounds Bx = view(B, 1:2:length(B))
    @inbounds By = view(B, 2:2:length(B))
    Point(maximum(Bx), maximum(By))
end

function isapprox(x::AbstractArray{S},
        y::AbstractArray{T}; kwargs...) where {S <: Point,T <: Point}
    all(ab->isapprox(ab[1],ab[2]; kwargs...), zip(x,y))
end

## Affine transformations

# Translation already defined for 2D by the CoordinateTransformations package
# Still need 2D rotation, reflections.

"""
    Rotation(Θ)
Construct a rotation about the origin. Units accepted (no units ⇒ radians).
"""
Rotation(Θ) = LinearMap(@SMatrix [cos(Θ) -sin(Θ); sin(Θ) cos(Θ)])

"""
    XReflection()
Construct a reflection about the x-axis (y-coordinate changes sign).

Example:
```jldoctest
julia> trans = XReflection()
LinearMap([1 0; 0 -1])

julia> trans(Point(1,1))
2-element Devices.Points.Point{Int64}:
  1
 -1
```
"""
XReflection() = LinearMap(@SMatrix [1 0;0 -1])

"""
    YReflection()
Construct a reflection about the y-axis (x-coordinate changes sign).

Example:
```jldoctest
julia> trans = YReflection()
LinearMap([-1 0; 0 1])

julia> trans(Point(1,1))
2-element Devices.Points.Point{Int64}:
 -1
  1
```
"""
YReflection() = LinearMap(@SMatrix [-1 0;0 1])

extract_derivative(x::Point{T}) where {T} =
    Point(unit(T)*ForwardDiff.partials(ustrip(getx(x)),1),
          unit(T)*ForwardDiff.partials(ustrip(gety(x)),1))

ustrip(p::Point{T}) where {T} = Point(ustrip(getx(p)), ustrip(gety(p)))
ustrip(v::AbstractArray{Point{T}}) where {T <: Length} = reinterpret(Point{Unitful.numtype(T)}, v)
ustrip(v::AbstractArray{Point{T}}) where {T} = v  #TODO good?
end
