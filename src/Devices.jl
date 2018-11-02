module Devices
using Random
using ForwardDiff
using FileIO
using WebIO
include("units.jl")

import StaticArrays
import Clipper
import Clipper: cclipper
import FileIO: save, load

import Base: length, show, eltype
import Unitful: Length, DimensionlessQuantity, ustrip, unit, inch
Unitful.@derived_dimension InverseLength inv(Unitful.𝐋)

export GDSMeta
export datatype, layer, render!

const DEFAULT_LAYER = 0
const DEFAULT_DATATYPE = 0
const D3STR = read(joinpath(dirname(@__FILE__), "../deps/d3.min.js"), String)

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
include("paths/paths.jl")
import .Paths: Path,
    α0,
    α1,
    adjust!,
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
    turn!,
    undecorated
export Paths, Path, Segment, Style,
    α0,
    α1,
    adjust!,
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
    turn!,
    undecorated

include("render/render.jl")

include("microwave.jl")
import .Microwave:
    bridge!,
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
    bridge!,
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

function Base.show(io::IO, mime::MIME"application/juno+plotpane", c0::Cell)
    svgio = IOBuffer()
    ps = get(io, :juno_plotsize, [100, 100])
    bx,by,un,yoff,xoff = let b=bounds(c0)
        ustrip(width(b)), ustrip(height(b)), unit(width(b)), ustrip(b.ur.y), ustrip(b.ll.x)
    end
    sx,sy = bx/ps[1]*96/72, by/ps[2]*96/72
    maxs = max(sx,sy)
    show(svgio, MIME"image/svg+xml"(), c0; width=(ps[1]/96)inch, height=(ps[2]/96)inch, bboxes=true)
    svgstr = String(take!(svgio))
    svgstr = replace(svgstr, r"<\?[A-Za-z .=0-9\-\"]+\?>"=>"")
    w = Scope()
    show(io, mime, w(dom"div"(
        dom"script"(setInnerHtml=D3STR),
        dom"div"(setInnerHtml=svgstr),
        dom"script"("""
            firstPoint = false;                 // keeps track of first vs. second click
            firstPointLoc = {x: 0, y: 0};       // keeps track of first click location
            translateVar =  {x: 0, y: 0};       // keeps track of zooming
            scaleVar = 1;

            // go from mouse click coordinate to cell coordinate
            function rescl(datum, scale) {
                return {x: (datum.x - translateVar.x) / scaleVar * scale + $xoff,
                        y: (datum.y - translateVar.y) / -scaleVar * scale + $yoff};
            }

            function updateLine(g, data) {
                if (firstPoint) {
                    d = g.selectAll("line").data(data)
                    d.enter()
                     .append("line")
                     .merge(d)
                     .attr("x1", (firstPointLoc.x - $xoff) * scaleVar + translateVar.x)
                     .attr("y1", (firstPointLoc.y - $yoff) * -scaleVar + translateVar.y)
                     .attr("x2", function(d) {return d.x})
                     .attr("y2", function(d) {return d.y})
                     .attr("stroke", "red")

                     d = g.selectAll("#dist").data(data)
                     d.enter()
                      .append("text")
                      .attr("id", "dist")
                      .merge(d)
                      .attr("fill", "red")
                      .attr("font-weight", "bold")
                      .attr("font-family", "sans-serif")
                      .attr("x", function(d) {return d.x})
                      .attr("y", function(d) {return d.y})
                      .text(function (d) {
                          var p1 = {x: (firstPointLoc.x - $xoff) * $maxs + $xoff,
                                    y: (firstPointLoc.y - $yoff) * $maxs + $yoff}
                          var p2 = rescl(d, $maxs)
                          var d = Math.sqrt(Math.pow(p1.x - p2.x, 2) +
                            Math.pow(p1.y - p2.y, 2))
                          return d.toFixed(3) + " $un"
                      })
                } else {
                    // user clicked a second time, remove the measurement line.
                    g.selectAll("line").remove()
                    g.selectAll("#dist").remove()
                }
            }

            // fill the plot pane with the svg
            var svg = d3.selectAll("svg")
                    .attr("width", "100%")
                    .attr("height", "100%")
            var oldg = svg.selectAll("g")

            var newg = svg.append("g")
            newg.append("rect")                    // white rect in upper-left for text.
                .attr("fill", "white")
                .attr("opacity", "0.5")
                .attr("width", "300px")
                .attr("height", "18px")
            newg.append("rect")                    // capture all mouse events in plot pane.
                .attr("fill", "none")
                .attr("pointer-events", "all")
                .attr("cursor", "crosshair")
                .attr("width", "100%")
                .attr("height", "100%")

            d3.select("body").on("keydown", function() {
                var k = d3.event.key;
                if (k == '/') {
                    newg.call(d3.zoom().transform, d3.zoomIdentity)
                    oldg.attr("transform", d3.zoomIdentity)
                    translateVar = {x:0, y:0}
                    scaleVar = 1
                    updateLine(newg, data)
                }
            })

            newg.on("mousemove", function() {
                var coords = d3.mouse(this);
                data = [{
                    x: coords[0],
                    y: coords[1]
                }];

                var d = newg.selectAll("text").data(data)
                d.enter()
                 .append("text")
                 .attr("x", function() { return 0; })
                 .attr("y", function() { return 10; })
                 .attr("font-family", "Consolas", "monospace")
                 .attr("font-size", 14)
                 .merge(d)
                 .text(function(d) {
                    e = rescl(d, $maxs)
                    return "X: " + e.x.toFixed(3).padStart(10, " ") + " $un" +
                           "  Y: " + e.y.toFixed(3).padStart(10, " ") + " $un";
                 })

                 updateLine(newg, data)
                 newg.attr("cursor", "crosshair")
            })

            newg.on("click", function() {
                if (firstPoint) {
                    firstPoint = false;
                } else {
                    firstPoint = true;
                    var coords = d3.mouse(this)
                    coords = rescl({x: coords[0], y: coords[1]}, 1)
                    firstPointLoc = {x: coords.x, y: coords.y};
                }

                // Display or hide text and line after click as appropriate.
                var d = newg.selectAll("text").data(data)
                updateLine(newg, data)
            })

            newg.call(d3.zoom()
                .scaleExtent([0.0001, 10000])
                .on("zoom", function () {
                    var coords = d3.mouse(this);
                    data = [{
                        x: coords[0],
                        y: coords[1]
                    }];
                    translateVar.x = d3.event.transform.x;
                    translateVar.y = d3.event.transform.y;
                    scaleVar = d3.event.transform.k;
                    oldg.attr("transform", d3.event.transform)
                    updateLine(newg, data)
                }));

            newg.on("dblclick.zoom", null)
        """
        )
    )))
    show(stdout, MIME"text/plain"(), c0)
    println(stdout)
end

end
