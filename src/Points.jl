module Points
import AffineTransforms: AffineTransform
import Clipper: IntPoint
import Base: convert, .+, .-, *, summary, promote_rule, show
import StaticArrays: FieldVector
import ForwardDiff: ForwardDiff, extract_derivative
import Unitful: Quantity
import PyCall.PyObject
export Point
export getx, gety

"""
```
immutable Point{T} <: FieldVector{T}
```

This type inherits from
"""
immutable Point{T<:Number} <: FieldVector{T}
    x::T
    y::T
end

Point(x::Number, y::Number) =
    error("Cannot use `Point` with this combination of types.")
Point(x::Quantity, y::Quantity) = Point{promote_type(typeof(x),typeof(y))}(x,y)
Point(x::Real, y::Real) = Point{promote_type(typeof(x),typeof(y))}(x,y)

convert{T<:Real}(::Type{Point{T}}, x::IntPoint) = Point{T}(x.X, x.Y)
promote_rule{S,T}(::Type{Point{S}}, ::Type{Point{T}}) = Point{promote_type(S,T)}
show(io::IO, p::Point) = print(io, "(",string(getx(p)),",",string(gety(p)),")")

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

*(a::AffineTransform, p::Point) = Point(a * Array(p))

extract_derivative{T<:Real}(x::Point{T}) =
    Point(ForwardDiff.partials(getx(x),1),ForwardDiff.partials(gety(x),1))

end
