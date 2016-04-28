module Rectangles

using ForwardDiff
using ..Points

import Base: +, -, *, /, minimum, maximum
import Devices
import Devices: AbstractPolygon
import Devices: bounds
gdspy() = Devices._gdspy

using AffineTransforms

export Rectangle
export Plain
export Rounded
export center
export height
export width

"Rectangle, defined by lower-left and upper-right x,y coordinates."
type Rectangle{T<:Real} <: AbstractPolygon{T}
    ll::Point{2,T}
    ur::Point{2,T}
end
Rectangle{T<:Real}(width::T, height::T) =
    Rectangle{T}(Point(-width/2, -height/2), Point(width/2, height/2))

width(r::Rectangle) = abs(getx(r.ur)-getx(r.ll))
height(r::Rectangle) = abs(gety(r.ur)-gety(r.ll))
bounds(p::Rectangle) = p
center(r::Rectangle) = (r.ur+r.ll)/2

minimum(r::Rectangle) = min(r.ll, r.ur)
maximum(r::Rectangle) = max(r.ll, r.ur)

for op in [:+, :-]
    @eval function ($op)(r::Rectangle, p::Point)
        Rectangle(($op)(r.ll, p), ($op)(r.ur, p))
    end
    @eval ($op)(p::Point, r::Rectangle) = ($op)(r,p)
end

*(r::Rectangle, a::Real) = Rectangle(*(r.ll,a), *(r.ur,a))
*(a::Real, r::Rectangle) = *(r,a)
/(r::Rectangle, a::Real) = Rectangle(/(r.ll,a), /(r.ur,a))

"How to draw the rectangle..."
abstract Style

"Simple solid rectangle."
type Plain <: Style
end

"The corners are rounded off (bounding box of the plain rectangle unaffected)."
type Rounded <: Style
    r::Float64
end

end
