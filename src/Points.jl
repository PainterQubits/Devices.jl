module Points
import Devices: Coordinate
import StaticArrays: FieldVector, @SMatrix
import CoordinateTransformations: LinearMap, Translation, ∘
import Clipper: IntPoint
import Base: convert, .+, .-, *, summary, promote_rule, show, reinterpret
import Base: scalarmin, scalarmax, isapprox
import ForwardDiff: ForwardDiff, extract_derivative
import Unitful: Length, ustrip, unit
import PyCall.PyObject
export Point
export Rotation, Translation, ∘
export getx, gety

"""
```
immutable Point{T} <: FieldVector{T}
```

2D coordinate in the plane.
"""
immutable Point{T<:Coordinate} <: FieldVector{T}
    x::T
    y::T
end

Point(x::Number, y::Number) =
    error("Cannot use `Point` with this combination of types.")
Point(x::Length, y::Length) = Point{promote_type(typeof(x),typeof(y))}(x,y)
Point(x::Real, y::Real) = Point{promote_type(typeof(x),typeof(y))}(x,y)

convert{T<:Real}(::Type{Point{T}}, x::IntPoint) = Point{T}(x.X, x.Y)
promote_rule{S<:Real,T<:Real}(::Type{Point{S}}, ::Type{Point{T}}) =
    Point{promote_type(S,T)}
promote_rule{S<:Length,T<:Length}(::Type{Point{S}}, ::Type{Point{T}}) =
    Point{promote_type(S,T)}
show(io::IO, p::Point) = print(io, "(",string(getx(p)),",",string(gety(p)),")")

function reinterpret{T,S}(::Type{T}, a::Point{S})
    nel = Int(div(length(a)*sizeof(S),sizeof(T)))
    return reinterpret(T, a, (nel,))
end

"""
```
getx(p::Point)
```

Get the x-coordinate of a point.
"""
@inline getx(p::Point) = p.x

"""
```
gety(p::Point)
```

Get the y-coordinate of a point.
"""
@inline gety(p::Point) = p.y

# For use with gdspy
PyObject(p::Point) = PyObject((getx(p), gety(p)))

for f in (:.+, :.-)
    @eval function ($f){S,T}(a::AbstractArray{Point{S}}, p::Point{T})
        R = Base.promote_op($f, S, T)
        Q = Base.promote_array_type($f, R, S, T)
        b = similar(a, Point{Q})
        for (ia, ib) in zip(eachindex(a), eachindex(b))
            @inbounds b[ib] = ($f)(a[ia], p)
        end
        b
    end
    @eval function ($f){S,T}(p::Point{S}, a::AbstractArray{Point{T}})
        R = Base.promote_op($f, S, T)
        Q = Base.promote_array_type($f, R, S, T)
        b = similar(a, Point{Q})
        for (ia, ib) in zip(eachindex(a), eachindex(b))
            @inbounds b[ib] = ($f)(p, a[ia])
        end
        b
    end
end

function isapprox{S<:Point,T<:Point}(x::AbstractArray{S},
        y::AbstractArray{T}; kwargs...)
    all(ab->isapprox(ab[1],ab[2]; kwargs...), zip(x,y))
end

## Affine transformations

# Translation already defined for 2D by the CoordinateTransformations package
# Still need 2D rotation.
Rotation(Θ) = LinearMap(@SMatrix [cos(Θ) -sin(Θ); sin(Θ) cos(Θ)])

extract_derivative{T<:Coordinate}(x::Point{T}) =
    Point(unit(T)*ForwardDiff.partials(ustrip(getx(x)),1),
          unit(T)*ForwardDiff.partials(ustrip(gety(x)),1))

end
