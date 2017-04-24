__precompile__()
module Devices
using Compat
using ForwardDiff
using FileIO
include("units.jl")

import StaticArrays
import Clipper
import FileIO: save, load
import Base: cell, length, show, .+, .-, eltype
import Unitful: Length
Unitful.@derived_dimension InverseLength inv(Unitful.𝐋)

export render!

# Used if a polygon does not specify a layer or datatype.
const DEFAULT_LAYER = 0
const DEFAULT_DATATYPE = 0

function __init__()
    global const _clip = Clipper.Clip()
    global const _coffset = Clipper.ClipperOffset()

    # The magic bytes are the GDS HEADER tag (0x0002), preceded by the number of
    # bytes in total (6 == 0x0006) for the HEADER record.
    add_format(format"GDS", UInt8[0x00, 0x06, 0x00, 0x02], ".gds")
    add_format(format"SVG", (), ".svg")
end

# The following functions are imported by submodules and have methods
# added, e.g. bounds(::Rectangle), bounds(::Polygon), etc.
export bounds
function bounds end

export center
function center end

export centered!, centered
function centered! end
function centered end

"""
    typealias Coordinate Union{Real,Length}
Type alias for numeric types suitable for coordinate systems.
"""
@compat Coordinate = Union{Real,Length}

"""
    typealias PointTypes Union{Real,Length,InverseLength}
Allowed type variables for `Point{T}` types.
"""
@compat PointTypes = Union{Real,Length,InverseLength}
@compat FloatCoordinate = Union{AbstractFloat,Length{<:AbstractFloat}}
@compat IntegerCoordinate = Union{Integer,Length{<:Integer}}

"""
    abstract AbstractPolygon{T<:Coordinate}
Anything you could call a polygon regardless of the underlying representation.
Currently only `Rectangle` or `Polygon` are concrete subtypes, but one could
imagine further subtypes to represent specific shapes that appear in highly
optimized pattern formats. Examples include the OASIS format (which has 25
implementations of trapezoids) or e-beam lithography pattern files like the Raith
GPF format.
"""
abstract AbstractPolygon{T<:Coordinate}

eltype{T}(::AbstractPolygon{T}) = T
eltype{T}(::Type{AbstractPolygon{T}}) = T

include("points.jl")
import .Points: Point, getx, gety
import .Points: Rotation, Translation, XReflection, YReflection, ∘, compose
import .Points: lowerleft, upperright
export Points
export Point, getx, gety
export Rotation, Translation, XReflection, YReflection, ∘, compose
export lowerleft, upperright

# TODO: Operations on arrays of AbstractPolygons
for (op, dotop) in [(:+, :.+), (:-, :.-)]
    @eval function ($dotop){S<:Real, T<:Real}(a::AbstractArray{AbstractPolygon{S},1}, p::Point{T})
        b = similar(a)
        for (ia, ib) in zip(eachindex(a), eachindex(b))
            @inbounds b[ib] = ($op)(a[ia], p)
        end
        b
    end
end

include("rectangles.jl")
import .Rectangles: Rectangle, height, width, isproper
export Rectangles
export Rectangle
export height
export width
export isproper

include("polygons.jl")
import .Polygons: Polygon, clip, offset, points
export Polygons
export Polygon
export clip, offset, points

function layer(polygon)
    props = polygon.properties
    haskey(props, :layer) && return props[:layer]
    return DEFAULT_LAYER
end

function datatype(polygon)
    props = polygon.properties
    haskey(props, :datatype) && return props[:datatype]
    return DEFAULT_DATATYPE
end

include("cells.jl")
import .Cells: Cell, CellArray, CellReference
import .Cells: traverse!, order!, flatten, flatten!, transform, name, uniquename
export Cells
export Cell, CellArray, CellReference
export traverse!, order!, flatten, flatten!, transform, name, uniquename

include("utils.jl")
include("paths/paths.jl")
importall .Paths
export Paths, Path, Segment, Style
export α0, α1,
    adjust!,
    attach!,
    contstyle1,
    corner!,
    direction,
    discretestyle1,
    meander!,
    launch!,
    p0, p1,
    pathf,
    pathlength,
    segment,
    setsegment!,
    simplify,
    simplify!,
    style,
    style0,
    style1,
    setstyle!,
    straight!,
    turn!,
    undecorated

include("render/render.jl")

include("tags.jl")
import .Tags: checkerboard!, grating!, interdigit!, radialcut!, radialstub!
export Tags
export checkerboard!, grating!, interdigit!, radialcut!, radialstub!

include("backends/gds.jl")
include("backends/svg.jl")

"""
    @junographics()
If you are using Juno in Atom, calling this at the start of your session will render
the layout in the plot pane automatically when showing a `Cell` from the command line.
There is no interactivity or scale bar.
"""
macro junographics()
    esc(quote
        Media.media(Cell, Media.Plot)
        function Media.render(pane::Atom.PlotPane, c::Cell)
            ps = Juno.plotsize()
            Media.render(pane, Atom.div(".fill",
                Atom.HTML(reprmime(MIME("image/svg+xml"), c; width=ps[1], height=ps[2]))))
        end
    end)
end

end
