module Devices

using PyCall
using ForwardDiff
import PyPlot

import Base: length, show
@pyimport numpy
@pyimport gdspy

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

export bounds
export heal
export view

export interdigit

include("Paths.jl")

and(x,y) = x & y
or(x,y) = x | y

union(iterable, layer, datatype, name) =
    boolean(iterable, layer, datatype, name, (x...)->reduce(and, true, [x...]))
intersect(iterable, layer, datatype, name) =
    boolean(iterable, layer, datatype, name, (x...)->reduce(or, true, [x...]))



"""
Returns coordinates for a bounding box around all polygons of `layer`
and `datatype` in cell `name`. The return format is a ((x1,y1),(x2,y2)).
"""
function bounds(name, layer=0, datatype=0)
    p = get_polygons(name,layer,datatype)
    x1,x2,y1,y2 = p[:get_bounding_box]()
    ((x1,y1),(x2,y2))
end

"Return a PyObject representing a cell."
function cell(name)
    if haskey(gdspy.Cell[:cell_dict], name)
        c = gdspy.Cell[:cell_dict][name]
    else
        c = gdspy.Cell(name)
    end
    return c
end

"Get polygons from `cell`, `layer`, and `datatype`."
function get_polygons(name, layer=0, datatype=0)
    c = cell(name)
    gdspy.PolygonSet(c[:get_polygons](by_spec=true)[(layer,datatype)])
end

"""
Will remove overlaps and may reduce polygon count, depending on geometry.
Seems a little bit slow.
Healing may also be done in Beamer. YMMV.
"""
function heal(name, layer0, datatype0, newname, layer, datatype)
    plgs = get_polygons(name, layer0, datatype0)
    λ = pyeval("lambda p1: p1")
    newp = gdspy.boolean([plgs], λ, layer=layer, datatype=datatype)
    c = cell(newname)
    c[:add](newp)
end

"Launch a LayoutViewer window."
view() = gdspy.LayoutViewer()

function interdigit(cellname; width=2, length=400, xgap=3, ygap=2, npairs=40, layer=FEATURES_LAYER)
    c = gdspy.Cell(cellname)

    for i = 1:npairs
        c[:add](gdspy.Rectangle((0,(i-1)*2*(width+ygap)), (length,(i-1)*2*(width+ygap)+width), layer=layer))
        c[:add](gdspy.Rectangle((xgap,(2i-1)*(width+ygap)), (xgap+length,width+(2i-1)*(width+ygap)), layer=layer))
    end

    c
end

end
