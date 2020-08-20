module Devices
using Random, LinearAlgebra
using ForwardDiff
using FileIO
include("units.jl")

import StaticArrays
import Clipper
import Clipper: libcclipper
import FileIO: save, load

import Base: length, show, eltype, intersect!
import Unitful: Length, LengthUnits, DimensionlessQuantity, NoUnits, DimensionError
import Unitful: ustrip, unit, inch
Unitful.@derived_dimension InverseLength inv(Unitful.𝐋)

export GDSMeta
export datatype, layer, render!

const DEFAULT_LAYER = 0
const DEFAULT_DATATYPE = 0

# setup for robust 2d predicates
const splitter, epsilon =
    let every_other = true, half = 0.5, epsilon = 1.0, splitter = 1.0, check = 1.0
        lastcheck = check
        epsilon *= half
        every_other && (splitter *= 2.0)
        every_other = !every_other
        check = 1.0 + epsilon

        while (check != 1.0) && (check != lastcheck)
            lastcheck = check
            epsilon *= half
            every_other && (splitter *= 2.0)
            every_other = !every_other
            check = 1.0 + epsilon
        end
        splitter += 1.0
        splitter, epsilon
    end

const resulterrbound = (3.0 + 8.0 * epsilon) * epsilon
const ccwerrboundA   = (3.0 + 16.0 * epsilon) * epsilon
const ccwerrboundB   = (2.0 + 12.0 * epsilon) * epsilon
const ccwerrboundC   = (9.0 + 64.0 * epsilon) * epsilon * epsilon

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
    CoordinateUnits = Union{typeof(NoUnits), LengthUnits}
Type alias for units suitable for coordinate systems.
"""
const CoordinateUnits = Union{typeof(NoUnits), LengthUnits}

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
import .Points: Point, Rotation, Translation, XReflection, YReflection,
    compose,
    getx,
    gety,
    ∘
export Points, Point, Rotation, Translation, XReflection, YReflection,
    compose,
    getx,
    gety,
    ∘

include("predicates.jl")

abstract type Meta end
struct GDSMeta <: Meta
    layer::Int
    datatype::Int
    GDSMeta() = new(DEFAULT_LAYER, DEFAULT_DATATYPE)
    GDSMeta(l) = new(l, DEFAULT_DATATYPE)
    GDSMeta(l,d) = new(l,d)
end
layer(x::GDSMeta) = x.layer
datatype(x::GDSMeta) = x.datatype
Base.broadcastable(x::Meta) = Ref(x)

include("rectangles.jl")
import .Rectangles: Rectangle,
    height,
    isproper,
    width
export Rectangles, Rectangle,
    height,
    isproper,
    width

include("polygons.jl")
import .Polygons: Polygon,
    circle,
    clip,
    offset,
    points
export Polygons, Polygon,
    circle,
    clip,
    offset,
    points

include("cells.jl")
import .Cells: Cell, CellArray, CellPolygon, CellReference,
    elements,
    flatten,
    flatten!,
    layers,
    meta,
    name,
    order!,
    polygon,
    transform,
    traverse!,
    uniquename
export Cells, Cell, CellArray, CellPolygon, CellReference,
    elements,
    flatten,
    flatten!,
    layers,
    meta,
    name,
    order!,
    polygon,
    transform,
    traverse!,
    uniquename

include("utils.jl")

function bridge! end    # needed in Paths, but not defined in Microwave
export bridge!

include("paths/paths.jl")
import .Paths: Path,
    α0,
    α1,
    reconcile!,
    attach!,
    contstyle1,
    corner!,
    direction,
    discretestyle1,
    launch!,
    meander!,
    next,
    nodes,
    p0,
    p1,
    pathf,
    pathlength,
    previous,
    segment,
    setsegment!,
    simplify,
    simplify!,
    straight!,
    style,
    style0,
    style1,
    setstyle!,
    terminate!,
    turn!,
    undecorated

@deprecate adjust! reconcile!
export Paths, Path, Segment, Style,
    α0,
    α1,
    adjust!, reconcile!,
    attach!,
    corner!,
    direction,
    meander!,
    launch!,
    p0,
    p1,
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
    terminate!,
    turn!,
    undecorated

include("render/render.jl")

include("microwave.jl")
import .Microwave:
    checkerboard!,
    device_template!,
    flux_bias!,
    grating!,
    interdigit!,
    jj!,
    jj_top_pad!,
    layerpixels!,
    qubit!,
    qubit_claw!,
    radialcut!,
    radialstub!
export Microwave,
    checkerboard!,
    device_template!,
    flux_bias!,
    grating!,
    interdigit!,
    jj!,
    jj_top_pad!,
    layerpixels!,
    qubit!,
    qubit_claw!,
    radialcut!,
    radialstub!

include("backends/gds.jl")
include("backends/graphics.jl")

include("lcdfonts.jl")
import .LCDFonts:
    characters_demo,
    lcdstring!,
    referenced_characters_demo,
    scripted_demo
export LCDFonts,
    characters_demo,
    lcdstring!,
    referenced_characters_demo,
    scripted_demo

end
