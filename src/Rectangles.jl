module Rectangles

using ForwardDiff
using ..Points

import Base: +, -, *, /, minimum, maximum
import Devices
import Devices: AbstractPolygon
import Devices: bounds, center, center!
gdspy() = Devices._gdspy

# using AffineTransforms

export Rectangle
export Plain
export Rounded
export height
export width
export isproper

"""
`type Rectangle{T<:Real} <: AbstractPolygon{T}`

A rectangle, defined by opposing corner coordinates.
"""
type Rectangle{T<:Real} <: AbstractPolygon{T}
    ll::Point{2,T}
    ur::Point{2,T}
    properties::Dict{Symbol, Any}
    Rectangle(ll,ur) = new(ll,ur,Dict{Symbol,Any}())
    Rectangle(ll,ur,props) = new(ll,ur,props)
end
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}, dict) =
    Rectangle{T}(ll, ur, dict)
Rectangle{T<:Real}(ll::Point{2,T}, ur::Point{2,T}; kwargs...) =
    Rectangle{T}(ll, ur, Dict{Symbol,Any}(kwargs))

# The rectangle will sit with a corner at the origin. With centered rectangles
# we would need to divide width, height by 2 to properly position based on corners,
# and types are more ambiguous. We'll leave that for the `center!` function.
Rectangle{T<:Real}(width::T, height::T; kwargs...) =
    Rectangle{T}(Point(zero(T),zero(T)), Point(width, height), Dict{Symbol,Any}(kwargs))

"""
`width(r::Rectangle)`

Return the width of a rectangle.
"""
width(r::Rectangle) = getx(r.ur)-getx(r.ll)

"""
`height(r::Rectangle)`

Return the height of a rectangle.
"""
height(r::Rectangle) = gety(r.ur)-gety(r.ll)

"""
`isproper(r::Rectangle)`
"""
isproper(r::Rectangle) = getx(r.ur) >= getx(r.ll) &&
                        gety(r.ur) >= gety(r.ll) &&
                        r.ur != r.ll

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
`center!(r::Rectangle)`

Centers a rectangle. Will throw an `InexactError()` if `r` is `Rectangle{T<:Integer}`
and the rectangle cannot be centered with integer corner coordinates.
"""
function center!(r::Rectangle)
    c = center(r)
    r.ll -= c
    r.ur -= c
    r
end

"""
`minimum(r::Rectangle)`

Returns the lower-left corner of a rectangle (Point object).
"""
minimum(r::Rectangle) = r.ll

"""
`maximum(r::Rectangle)`

Returns the upper-right corner of a rectangle (Point object).
"""
maximum(r::Rectangle) = r.ur

for op in [:+, :-]
    @eval function ($op)(r::Rectangle, p::Point)
        Rectangle(($op)(r.ll, p), ($op)(r.ur, p), r.properties)
    end
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
