module Rectangles

using ForwardDiff
import Devices: gdspy
import Devices: render
import Devices.Paths
using Devices.Paths: Path, straight, turn

export Rectangle
export Plain
export Rounded

"Rectangle, defined by lower-left and upper-right x,y coordinates."
type Rectangle
    llx::Float64
    lly::Float64
    urx::Float64
    ury::Float64
end
Rectangle(width::Real, height::Real) =
    Rectangle(-width/2, -height/2, width/2, height/2)
Rectangle{S<:Real, T<:Real, U<:Real, V<:Real}(ll::Tuple{S,T}, ur::Tuple{U,V}) =
    Rectangle(ll[1],ll[2],ur[1],ur[2])

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
function render(r::Rectangle, ::Plain, name="main";
        layer::Real=0, datatype::Real=0)
    c = cell(name)
    gr = gdspy.Rectangle((r.llx,r.lly),(r.urx,r.ury),layer=layer,datatype=datatype)
    c[:add](gr)
end

"""
Render a rounded rectangle `r` to the cell `name`.
This is accomplished by rendering a path around the outside of a
(smaller than requested) solid rectangle.
"""
function render(r::Rectangle, s::Rounded, name="main";
        layer::Real=0, datatype::Real=0)
    c = cell(name)
    rad = s.r
    gr = gdspy.Rectangle((r.llx+rad,r.lly+rad),(r.urx-rad,r.ury-rad),
        layer=layer, datatype=datatype)
    c[:add](gr)
    p = Path((r.llx+rad,r.lly+rad/2))
    straight(p, r.urx-r.llx-2*rad)
    turn(p, π/2, rad/2)
    straight(p, r.ury-r.lly-2*rad)
    turn(p, π/2, rad/2)
    straight(p, r.urx-r.llx-2*rad)
    turn(p, π/2, rad/2)
    straight(p, r.ury-r.lly-2*rad)
    turn(p, π/2, rad/2)
    render(p, Paths.Trace(s.r), name, layer=layer, datatype=datatype)
end

end
