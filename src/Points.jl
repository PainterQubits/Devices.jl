module Points

import FixedSizeArrays: FixedVectorNoTuple
import PyCall.PyObject
export Point
export getx, gety

"""
`immutable Point{T<:Real} <: FixedVectorNoTuple{2,T}`

A point in the plane (Cartesian coordinates).
"""
immutable Point{T<:Real} <: FixedVectorNoTuple{2,T}
    x::T
    y::T
    Point(x,y) = new(x,y)
end
Point{T<:Real}(x::T,y::T) = Point{T}(x,y)
Point{S<:Real, T<:Real}(x::S,y::T) = Point{promote_type(x,y)}(x,y)

"""
`getx(p::Point)`

Get the x-coordinate of a point.
"""
@inline getx(p::Point) = p.x

"""
`gety(p::Point)`

Get the y-coordinate of a point.
"""
@inline gety(p::Point) = p.y

# For use with gdspy
PyObject(p::Point) = PyObject((getx(p), gety(p)))

end
