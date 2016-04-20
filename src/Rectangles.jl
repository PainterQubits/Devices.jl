module Rectangles

using ForwardDiff
using ..Points

import Devices
import Devices: render
import Devices.Paths
gdspy() = Devices._gdspy

using Devices.Paths: Path, straight!, turn!

export Rectangle
export Plain
export Rounded

"Rectangle, defined by lower-left and upper-right x,y coordinates."
type Rectangle{T<:Real}
    ll::Point{T}
    ur::Point{T}
end
Rectangle{T<:Real}(width::T, height::T) =
    Rectangle{T}(Point(-width/2, -height/2), Point(width/2, height/2))
Rectangle{T<:Real}(ll::Point{T}, ur::Point{T}) = Rectangle{T}(ll, ur)

width(r::Rectangle) = getx(r.ur)-getx(r.ll)
height(r::Rectangle) = gety(r.ur)-gety(r.ll)

"How to draw the rectangle..."
abstract Style

"Simple solid rectangle."
type Plain <: Style
end

"The corners are rounded off (bounding box of the plain rectangle unaffected)."
type Rounded <: Style
    r::Float64
end

"""
Render a rect `r` to the cell with name `name`.
Keyword arguments give a `layer` and `datatype` (default to 0).
"""
function render(r::Rectangle, ::Plain; name="main", layer::Real=0, datatype::Real=0)
    c = cell(name)
    gr = gdspy()[:Rectangle](r.ll,r.ur,layer=layer,datatype=datatype)
    c[:add](gr)
end

"""
Render a rounded rectangle `r` to the cell `name`.
This is accomplished by rendering a path around the outside of a
(smaller than requested) solid rectangle.
"""
function render(r::Rectangle, s::Rounded; name="main", layer::Real=0, datatype::Real=0)
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
