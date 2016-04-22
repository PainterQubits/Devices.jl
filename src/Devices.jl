__precompile__()
module Devices

using PyCall
using ForwardDiff
import PyPlot

import Base: cell, length, show

const _gdspy = PyCall.PyNULL()
const _qr = PyCall.PyNULL()

function __init__()
    copy!(_gdspy, pyimport("gdspy"))
    copy!(_qr, pyimport("pyqrcode"))
end

gdspy() = Devices._gdspy
qr() = Devices._qr

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

include("paths/Paths.jl")
import .Paths: Path, adjust!, attach!, launch!, meander!
import .Paths: param, pathlength, preview, simplify!, straight!, turn!
export Paths
export Path
export adjust!
export attach!
export launch!
export meander!
export param
export pathlength
export preview
export simplify!
export straight!
export turn!

include("Rectangles.jl")
import .Rectangles: Rectangle
export Rectangles
export Rectangle

include("Tags.jl")
import .Tags: qrcode
export qrcode

end
