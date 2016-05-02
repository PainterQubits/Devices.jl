module Rectangles

using ForwardDiff
using ..Points

import Base: +, -, *, /, minimum, maximum
import Devices
import Devices: AbstractPolygon
import Devices: bounds
gdspy() = Devices._gdspy

# using AffineTransforms

export Rectangle
export Plain
export Rounded
export center
export height
export width

"""
`type Rectangle{T<:Real} <: AbstractPolygon{T}`

A rectangle, defined by opposing corner coordinates.
"""
type Rectangle{T<:Real} <: AbstractPolygon{T}
    ll::Point{2,T}
    ur::Point{2,T}
    properties::Dict{Symbol, Any}
end
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}; kwargs...) =
    Rectangle{T}(ll, ur, Dict{Symbol,Any}(kwargs))
Rectangle{T<:Real}(width::T, height::T; kwargs...) = Rectangle{typeof(one(T)/2)}(
    Point(-width/2, -height/2), Point(width/2, height/2), Dict{Symbol,Any}(kwargs))

"""
`width(r::Rectangle)`

Return the width of a rectangle.
"""
width(r::Rectangle) = abs(getx(r.ur)-getx(r.ll))

"""
`height(r::Rectangle)`

Return the height of a rectangle.
"""
height(r::Rectangle) = abs(gety(r.ur)-gety(r.ll))

"""
`bounds(r::Rectangle)`

No-op (just returns `r`).
"""
bounds(r::Rectangle) = r

"""
`center(r::Rectangle)`

Returns a Point corresponding to the center of the rectangle.
"""
center(r::Rectangle) = (r.ur+r.ll)/2

"""
`minimum(r::Rectangle)`

Returns the lower-left corner of a rectangle (Point object).
"""
minimum(r::Rectangle) = min(r.ll, r.ur)

"""
`maximum(r::Rectangle)`

Returns the upper-right corner of a rectangle (Point object).
"""
maximum(r::Rectangle) = max(r.ll, r.ur)

for op in [:+, :-]
    @eval function ($op)(r::Rectangle, p::Point)
        Rectangle(($op)(r.ll, p), ($op)(r.ur, p), r.properties)
    end
    @eval ($op)(p::Point, r::Rectangle) = ($op)(r,p)
end

*(r::Rectangle, a::Real) = Rectangle(*(r.ll,a), *(r.ur,a), r.properties)
*(a::Real, r::Rectangle) = *(r,a)
/(r::Rectangle, a::Real) = Rectangle(/(r.ll,a), /(r.ur,a), r.properties)

"How to draw the rectangle."
abstract Style

"Simple solid rectangle."
type Plain <: Style
end

"The corners are rounded off (bounding box of the unstyled rectangle unaffected)."
type Rounded <: Style
    r::Float64
end

end
