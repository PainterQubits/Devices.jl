__precompile__()
module Devices
using ForwardDiff
using FileIO
include("units.jl")

import StaticArrays
import Clipper
import FileIO: save, load

import Base: length, show, eltype
import Unitful: Length, DimensionlessQuantity
Unitful.@derived_dimension InverseLength inv(Unitful.𝐋)

export GDSMeta
export datatype, layer, render!

const DEFAULT_LAYER = 0
const DEFAULT_DATATYPE = 0

# For help with precompiling
global _clip = Ref(Clipper.Clip())
global _coffset = Ref(Clipper.ClipperOffset())

function __init__()
    # To ensure no crashes
    global _clip = Ref(Clipper.Clip())
    global _coffset = Ref(Clipper.ClipperOffset())

    # The magic bytes are the GDS HEADER tag (0x0002), preceded by the number of
    # bytes in total (6 == 0x0006) for the HEADER record.
    add_format(format"GDS", UInt8[0x00, 0x06, 0x00, 0x02], ".gds")
end

# The following functions are imported by submodules and have methods
# added, e.g. bounds(::Rectangle), bounds(::Polygon), etc.
export bounds
function bounds end

export center
function center end

export centered
function centered end

export lowerleft, upperright
function lowerleft end
function upperright end

"""
    Coordinate = Union{Real, Length}
Type alias for numeric types suitable for coordinate systems.
"""
const Coordinate = Union{Real, Length}

"""
    PointTypes = Union{Real, DimensionlessQuantity, Length, InverseLength}
Allowed type variables for `Point{T}` types.
"""
const PointTypes = Union{Real, DimensionlessQuantity, Length, InverseLength}
const FloatCoordinate = Union{AbstractFloat,Length{<:AbstractFloat}}
const IntegerCoordinate = Union{Integer,Length{<:Integer}}

"""
    abstract type AbstractPolygon{T<:Coordinate} end
Anything you could call a polygon regardless of the underlying representation.
Currently only `Rectangle` or `Polygon` are concrete subtypes, but one could
imagine further subtypes to represent specific shapes that appear in highly
optimized pattern formats. Examples include the OASIS format (which has 25
implementations of trapezoids) or e-beam lithography pattern files like the Raith
GPF format.
"""
abstract type AbstractPolygon{T<:Coordinate} end

eltype(::AbstractPolygon{T}) where {T} = T
eltype(::Type{AbstractPolygon{T}}) where {T} = T

include("points.jl")
import .Points: Point, getx, gety
import .Points: Rotation, Translation, XReflection, YReflection, ∘, compose
export Points
export Point, getx, gety
export Rotation, Translation, XReflection, YReflection, ∘, compose

abstract type Meta end
struct GDSMeta <: Meta
    layer::Int
    datatype::Int
    GDSMeta() = new(DEFAULT_LAYER, DEFAULT_DATATYPE)
    GDSMeta(l) = new(l, DEFAULT_DATATYPE)
    GDSMeta(l,d) = new(l,d)
end
@inline layer(x::GDSMeta) = x.layer
@inline datatype(x::GDSMeta) = x.datatype

include("rectangles.jl")
import .Rectangles: Rectangle, height, width, isproper
export Rectangles, Rectangle
export height, isproper, width

include("polygons.jl")
import .Polygons: Polygon, clip, offset, points
export Polygons, Polygon
export clip, offset, points

include("cells.jl")
import .Cells: Cell, CellArray, CellPolygon, CellReference
import .Cells: elements, flatten, flatten!, layers, meta, name, order!, polygon, transform
import .Cells: traverse!, uniquename
export Cells, Cell, CellArray, CellPolygon, CellReference
export elements, flatten, flatten!, layers, meta, name, order!, polygon, transform
export traverse!, uniquename

include("utils.jl")
include("paths/paths.jl")
importall .Paths
export Paths, Path, Segment, Style
export α0, α1,
    adjust!,
    attach!,
    corner!,
    direction,
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

include("microwave.jl")
import .Microwave: bridge!, checkerboard!, device_template!, flux_bias!,
    grating!,
    interdigit!, jj!, jj_top_pad!, layerpixels!, qubit!, qubit_claw!, radialcut!, radialstub!
export Microwave
export bridge!, checkerboard!, device_template!, flux_bias!, grating!,
    interdigit!,
    jj!, jj_top_pad!, layerpixels!, qubit!, qubit_claw!, radialcut!, radialstub!

include("backends/gds.jl")
include("backends/svg.jl")

include("lcdfonts.jl")
import .LCDFonts: lcdstring!, characters_demo, scripted_demo, referenced_characters_demo
export LCDFonts
export lcdstring!, characters_demo, scripted_demo, referenced_characters_demo

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
