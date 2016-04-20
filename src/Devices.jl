__precompile__()
module Devices

using PyCall
using ForwardDiff
import PyPlot

import Base: cell, length, show

const numpy = PyCall.PyNULL()
const _gdspy = PyCall.PyNULL()

function __init__()
    copy!(numpy, pyimport("numpy"))
    copy!(_gdspy, pyimport("gdspy"))
end
# @pyimport pyqrcode

gdspy() = Devices._gdspy

const FEATURE_BOUNDING_LAYER = 1
const CHIP_BOUNDING_LAYER    = 2
const CLIP_PLACEMENT_LAYER   = 3
const FEATURES_LAYER         = 5

const UNIT      = 1.0e-6
const PRECISION = 1.0e-9

export FEATURE_BOUNDING_LAYER
export CHIP_BOUNDING_LAYER
export CLIP_PLACEMENT_LAYER
export FEATURES_LAYER
export UNIT
export PRECISION

export andnot
export attach
export boolean
export bounds
export heal
export intersect
export render
export union
export view
export xor

export interdigit

function render end

include("Points.jl")
import .Points: Point, getx, gety
export Points
export Point, getx, gety

include("Paths.jl")
import .Paths: Path, adjust!, param, pathlength, preview, launch!, straight!, turn!
export Paths
export Path
export adjust!
export param
export pathlength
export preview
export launch!
export straight!
export turn!

include("Rectangles.jl")
import .Rectangles: Rectangle
export Rectangles
export Rectangle

include("Tags.jl")

and(x,y) = x & y
or(x,y) = x | y
xor(x,y) = x $ y
andnot(x,y) = x &~ y

union(iterable::AbstractArray, name, layer::Integer, datatype::Integer) =
    boolean(iterable, name, layer, datatype, (x...)->reduce(or, true, [x...]))
intersect(iterable::AbstractArray, name, layer::Integer, datatype::Integer) =
    boolean(iterable, name, layer, datatype, (x...)->reduce(and, true, [x...]))
xor(iterable::AbstractArray, name, layer::Integer, datatype::Integer) =
    boolean(iterable, name, layer, datatype, (x...)->reduce(xor, true, [x...]))
andnot(iterable::AbstractArray, name, layer::Integer, datatype::Integer) =
    boolean(iterable, name, layer, datatype, (x...)->reduce(andnot, true, [x...]))

"""
Attach a cell `name` along a path `p` rendered with style `s` at location
`t` ∈ [0,1]. The `direction` is 1,0,-1 (left, center, or right of path,
respectively). If 0, the center of the cell will be centered on the path, with
the top of the cell tangent to the path direction (and leading the bottom).
Otherwise, the top of the cell will be rotated closest to the path edge.
A tangential `offset` may be given to move the cell with +x
being the direction to the right of the path.
"""
function attach(name::AbstractString, p::Path, s::Paths.Style, t::Real,
        direction::Integer, offset::Real, incell::AbstractString)

    (direction < -1 || direction > 1) && error("Invalid direction.")
    f = param(p)
    fx(t) = f(t)[1]
    fy(t) = f(t)[2]
    dirx,diry = (derivative(fx,t), derivative(fy,t))
    α0 = atan(diry/dirx)

    ((x1,y1),(x2,y2)) = bounds(name)
    dtop = max(y1,y2) - (y1+y2)/2       # distance from center to top

    newcell = cell(incell)
    if direction == 0
        ∠ = α0-π/2
        newx = offset*cos(∠)
        newy = offset*sin(∠)
        ref = gdspy()[:CellReference](cell(name), origin=f(t)+[newx,newy],
            rotation=∠*180/π)
    else
        ∠ = α0-π/2
        offset -= direction*extent(s,t)
        offset -= direction*dtop
        newx = offset*cos(∠)
        newy = offset*sin(∠)
        rot = (α0 + (direction==1 ? π:0))*180/π
        ref = gdspy()[:CellReference](cell(name), origin=f(t)+[newx,newy],
            rotation=rot)
    end
    newcell[:add](ref)
end

"""
Performs a boolean operation.
"""
function boolean(iterable::AbstractArray, name,
        layer::Integer, datatype::Integer, λ::Function)
    newp = gdspy()[:boolean](iterable, λ, layer=layer, datatype=datatype)
    c = cell(name)
    c[:add](newp)
end

"""
`bounds(name::AbstractString, layer::Integer, datatype::Integer)`

Returns coordinates for a bounding box around all polygons of `layer`
and `datatype` in cell `name`. The return format is ((x1,y1),(x2,y2)).
"""
function bounds(name, layer::Integer, datatype::Integer)
    p = get_polygons(name,layer,datatype)
    x1,x2,y1,y2 = p[:get_bounding_box]()
    ((x1,y1),(x2,y2))
end

"""
`bounds(name::AbstractString)`

Returns coordinates for a bounding box around all polygons in cell `name`.
The return format is ((x1,y1),(x2,y2)).
"""
function bounds(name)
    x1,x2,y1,y2 = cell(name)[:get_bounding_box]()
    ((x1,y1),(x2,y2))
end


"Return a PyObject representing a cell."
function cell(name)
    if haskey(gdspy()[:Cell][:cell_dict], name)
        c = gdspy()[:Cell][:cell_dict][name]
    else
        c = gdspy()[:Cell](name)
    end
    return c
end

"Get polygons from `cell`, `layer`, and `datatype`."
function get_polygons(name::AbstractString, layer::Integer, datatype::Integer)
    c = cell(name)
    gdspy()[:PolygonSet](c[:get_polygons](by_spec=true)[(layer,datatype)])
end

"Get all polygons from cell `name`."
function get_polygons(name::AbstractString)
    c = cell(name)
    gdspy()[:PolygonSet](c[:get_polygons]())
end

"""
Will remove overlaps and may reduce polygon count, depending on geometry.
Seems a little bit slow. Healing may also be done in Beamer. YMMV.
"""
function heal(name, layer0, datatype0, newname, layer, datatype)
    plgs = get_polygons(name, layer0, datatype0)
    λ = pyeval("lambda p1: p1")
    newp = gdspy()[:boolean]([plgs], λ, layer=layer, datatype=datatype)
    c = cell(newname)
    c[:add](newp)
end

"Launch a LayoutViewer window."
view() = gdspy()[:LayoutViewer]()

function interdigit(cellname; width=2, length=400, xgap=3, ygap=2, npairs=40, layer=FEATURES_LAYER)
    c = gdspy()[:Cell](cellname)

    for i = 1:npairs
        c[:add](gdspy()[:Rectangle]((0,(i-1)*2*(width+ygap)), (length,(i-1)*2*(width+ygap)+width), layer=layer))
        c[:add](gdspy()[:Rectangle]((xgap,(2i-1)*(width+ygap)), (xgap+length,width+(2i-1)*(width+ygap)), layer=layer))
    end

    c
end

end
