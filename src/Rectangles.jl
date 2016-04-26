module Rectangles

using ForwardDiff
using ..Points

import Base: +, -, minimum, maximum
import Devices
import Devices: AbstractPolygon
import Devices: bounds, render
import Devices.Paths
gdspy() = Devices._gdspy

using Devices.Paths: Path, straight!, turn!
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

width(r::Rectangle) = getx(r.ur)-getx(r.ll)
height(r::Rectangle) = gety(r.ur)-gety(r.ll)
bounds(p::Rectangle) = p
center(r::Rectangle) = (r.ur+r.ll)/2

minimum(r::Rectangle) = min(r.ll, r.ur)
maximum(r::Rectangle) = max(r.ll, r.ur)

for op in [:+, :-]
    @eval function ($op)(r::Rectangle, p::Point)
        r.ll = ($op)(r.ll, p)
        r.ur = ($op)(r.ur, p)
        r
    end
    @eval ($op)(p::Point, r::Rectangle) = ($op)(r,p)
end

"How to draw the rectangle..."
abstract Style

"Simple solid rectangle."
type Plain <: Style
end

"The corners are rounded off (bounding box of the plain rectangle unaffected)."
type Rounded <: Style
    r::Float64
end

function render(r::Rectangle, s::Style=Plain(); name="main", layer::Real=0, datatype::Real=0)
    render(r, s, name, layer, datatype)
end

"""
Render a rect `r` to the cell with name `name`.
Keyword arguments give a `layer` and `datatype` (default to 0).
"""
function render(r::Rectangle, ::Plain, name, layer, datatype)
    c = cell(name)
    gr = gdspy()[:Rectangle](r.ll,r.ur,layer=layer,datatype=datatype)
    c[:add](gr)
end

"""
Render a rounded rectangle `r` to the cell `name`.
This is accomplished by rendering a path around the outside of a
(smaller than requested) solid rectangle.
"""
function render(r::Rectangle, s::Rounded, name, layer, datatype)
    c = cell(name)
    rad = s.r
    gr = gdspy()[:Rectangle](r.ll+Point(rad,rad),r.ur-Point(rad,rad),
        layer=layer, datatype=datatype)
    c[:add](gr)
    p = Path(r.ll+Point(rad,rad/2), 0.0, Paths.Trace(s.r))
    straight!(p, width(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, width(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r)-2*rad)
    turn!(p, π/2, rad/2)
    render(p, name=name, layer=layer, datatype=datatype)
end

end
