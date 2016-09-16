__precompile__()
module Devices

using PyCall
using ForwardDiff
using FileIO
import Clipper
import FileIO: save, load
import Base: cell, length, show, .+, .-
import Unitful: Length

render_counter = UInt64(0)

# The PyNULL() and __init__() are necessary to use PyCall with precompiled modules.
const _gdspy = PyCall.PyNULL()
const _qr = PyCall.PyNULL()

function __init__()
    copy!(_gdspy, pyimport("gdspy"))
    copy!(_qr, pyimport("pyqrcode"))
    global const _clip = Clipper.Clip()
    global const _coffset = Clipper.ClipperOffset()

    # The magic bytes specify GDS version 6.0.0, which probably everyone is using
    add_format(format"GDS", UInt8[0x00, 0x06, 0x00, 0x02, 0x02, 0x58], ".gds")
end

gdspy() = Devices._gdspy
qr() = Devices._qr

const UNIT      = 1.0e-6
const PRECISION = 1.0e-9
export UNIT
export PRECISION

export bounds
export center
export render!

export interdigit

function render! end

"""
```
typealias Coordinate Union{Real,Length}
```

Type alias for numeric types suitable for coordinate systems.
"""
typealias Coordinate Union{Real,Length}

include("Points.jl")
import .Points: Point, getx, gety, Rotation, Translation, ∘
export Points
export Point, getx, gety, Rotation, Translation, ∘

function interdigit(cellname; width=2, length=400, xgap=3, ygap=2, npairs=40, layer=FEATURES_LAYER)
    c = gdspy()[:Cell](cellname)

    for i = 1:npairs
        c[:add](gdspy()[:Rectangle]((0,(i-1)*2*(width+ygap)), (length,(i-1)*2*(width+ygap)+width), layer=layer))
        c[:add](gdspy()[:Rectangle]((xgap,(2i-1)*(width+ygap)), (xgap+length,width+(2i-1)*(width+ygap)), layer=layer))
    end

    c
end

function bounds end
function center end
function center! end

function uniquename(str)
    replace(str*string(gensym()),"##","_")
end

"""
```
abstract AbstractPolygon{T}
```

Anything you could call a polygon regardless of the underlying representation.
Currently only `Rectangle` or `Polygon` are concrete subtypes.
"""
abstract AbstractPolygon{T<:Coordinate}

include("Rectangles.jl")
import .Rectangles: Rectangle, center!, height, width, isproper
export Rectangles
export Rectangle
export center!
export height
export width
export isproper

include("Polygons.jl")
import .Polygons: Polygon, clip, offset, points, layer, datatype
export Polygons
export Polygon
export clip, offset, points, layer, datatype

include("Cells.jl")
import .Cells: Cell, CellArray, CellReference
import .Cells: traverse!, order!, flatten, flatten!, transform, name
export Cells
export Cell, CellArray, CellReference
export traverse!, order!, flatten, flatten!, transform, name

include("paths/Paths.jl")
import .Paths: Path, adjust!, attach!, direction, meander!, launch!, corner!
import .Paths: param, pathf, pathlength, simplify, simplify!, straight!, turn!
import .Paths: α0, α1, p0, p1, style0, style1, extent, undecorated
import .Paths: segment, style
export Paths
export Path
export α0, α1, p0, p1, style0, style1, segment, style
export adjust!
export attach!
export corner!
export direction
export meander!, launch!
export param
export pathf
export pathlength
export simplify
export simplify!
export straight!
export turn!
export undecorated

"""
```
render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain(); kwargs...)
```

Render a rectangle `r` to cell `c`, defaulting to plain styling.

Returns an array of the AbstractPolygons added to the cell.
"""
function render!(c::Cell, r::Rectangle, s::Rectangles.Style=Rectangles.Plain(); kwargs...)
    render!(c, r, s; kwargs...)
end

"""
```
render!(c::Cell, r::Rectangle, ::Rectangles.Plain; kwargs...)
```

Render a rectangle `r` to cell `c` with plain styling.

Returns an array with the rectangle in it.
"""
function render!(c::Cell, r::Rectangle, ::Rectangles.Plain; kwargs...)
    d = Dict(kwargs)
    r.properties = merge(r.properties, d)
    push!(c.elements, r)
end

"""
```
render!(c::Cell, r::Rectangle, s::Rectangles.Rounded; kwargs...)
```

Render a rounded rectangle `r` to cell `c`. This is accomplished by rendering
a path around the outside of a (smaller than requested) solid rectangle. The
bounding box of `r` is preserved.

Returns an array of the AbstractPolygons added to the cell.
"""
function render!(c::Cell, r::Rectangle, s::Rectangles.Rounded; kwargs...)
    d = Dict(kwargs)
    r.properties = merge(r.properties, d)

    rad = s.r
    ll, ur = minimum(r), maximum(r)
    gr = Rectangle(ll+Point(rad,rad),ur-Point(rad,rad), r.properties)
    push!(c.elements, gr)

    p = Path(ll+Point(rad,rad/2), style0=Paths.Trace(s.r)) #0.0, Paths.Trace(s.r))
    straight!(p, width(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, width(r)-2*rad)
    turn!(p, π/2, rad/2)
    straight!(p, height(r)-2*rad)
    turn!(p, π/2, rad/2)
    render!(c, p; r.properties...)
end

"""
```
render!(c::Cell, r::Rectangle, s::Rectangles.Undercut;
    layer=0, uclayer=0, kwargs...)
```

Render a rectangle `r` to cell `c`. Additionally, put a hollow border around the
rectangle with layer `uclayer`. Useful for undercut structures.

Returns an array of the AbstractPolygons added to the cell.
"""
function render!(c::Cell, r::Rectangle, s::Rectangles.Undercut;
    layer=0, uclayer=0, kwargs...)

    r.properties = merge(r.properties, Dict(kwargs))
    r.properties[:layer] = layer
    push!(c.elements, r)

    ucr = Rectangle(r.ll-Point(s.ucl,s.ucb),
        r.ur+Point(s.ucr,s.uct), Dict(kwargs))
    ucp = clip(Clipper.ClipTypeDifference, ucr, r)[1]
    ucp.properties[:layer] = uclayer
    push!(c.elements, ucp)
end

"""
```
render!(c::Cell, r::Polygon, s::Polygons.Style=Polygons.Plain(); kwargs...)
```

Render a polygon `r` to cell `c`, defaulting to plain styling.

"""
function render!(c::Cell, r::Polygon, s::Polygons.Style=Polygons.Plain(); kwargs...)
    d = Dict(kwargs)
    r.properties = merge(r.properties, d)
    push!(c.elements, r)
end

"""
```
render!(c::Cell, p::Path; kwargs...)
```

Render a path `p` to a cell `c`.
"""
function render!(c::Cell, p::Path; kwargs...)
    adjust!(p)
    for node in p
        render!(c, segment(node), style(node); kwargs...)
    end
end

function render!(c::Cell, seg::Paths.Corner, sty::Paths.Style; kwargs...)
    sgn = ifelse(seg.α >= 0, 1, -1)
    ∠A = seg.α0+sgn*π/2
    p = Point(cos(∠A),sin(∠A))
    p1 = seg.extent*p + seg.p0
    p2 = -seg.extent*p + seg.p0
    ex = 2*seg.extent*tan(sgn*seg.α/2)
    p3 = p2 + ex*Point(cos(seg.α0),sin(seg.α0))
    p4 = p3 + ex*Point(cos(seg.α0+seg.α), sin(seg.α0+seg.α))

    push!(c.elements, Polygon{Float64}([p1,p2,p3,p4], Dict{Symbol,Any}(kwargs)))
end

"""
```
render!(c::Cell, segment::Paths.Segment, s::Paths.Style; kwargs...)
```

Render a `segment` with style `s` to cell `c`.
"""
function render!(c::Cell, segment::Paths.Segment, s::Paths.Style; kwargs...)
    polys = AbstractPolygon[]
    f = segment.f
    g(t) = ForwardDiff.derivative(f,t)
    last = 0.0
    first = true
    gp = gdspy()[:Path](Paths.width(s, 0.0), Point(0.0,0.0),
        number_of_paths=Paths.paths(s, 0.0), distance=Paths.distance(s, 0.0))
    for t in Paths.divs(s)
        if first
            first = false
            continue
        end
        gp[:parametric](x->f(last+x*(t-last)),
            curve_derivative=x->g(last+x*(t-last)),
            final_width=Paths.width(s,t),
            final_distance=Paths.distance(s,t))
        for a in gp[:polygons]
            points = reinterpret(Point{Float64}, reshape(transpose(a), length(a)))
            poly = Polygon{Float64}(points, Dict{Symbol,Any}(kwargs))
            push!(polys, poly)
        end
        gp = gdspy()[:Path](Paths.width(s,t), Point(0.0,0.0),
            number_of_paths=Paths.paths(s,t), distance=Paths.distance(s,t))
        last = t
    end
    append!(c.elements, polys)
    polys
end

"""
```
render!(c::Cell, segment::Paths.Segment, s::Paths.DecoratedStyle; kwargs...)
```

Render a `segment` with decorated style `s` to cell `c`.
Cell references held by the decorated style will have their fields modified
by this method, which is why they are shallow copied in the
[`Paths.attach!`](@ref) function.

This method draws the decorations before the path itself is drawn.
"""
function render!(c::Cell, segment::Paths.Segment, s::Paths.DecoratedStyle; kwargs...)
    for (t, dir, cref) in zip(s.ts, s.dirs, s.refs)
        (dir < -1 || dir > 1) && error("Invalid direction in $s.")

        ref = copy(cref)

        rot = direction(segment.f, t)
        if dir == 0
            ref.origin += segment.f(t)
            ref.rot += rot*180/π
        else
            if dir == -1
                rot2 = rot + π/2
            else
                rot2 = rot - π/2
            end

            offset = extent(s.s, t)
            newx = offset * cos(rot2)
            newy = offset * sin(rot2)
            ref.origin = Point(tformrotate(rot)*Array(ref.origin))
            ref.origin += (Point(newx,newy) + segment.f(t))
            ref.rot += rot*180/π
        end
        push!(c.refs, ref)
    end
    render!(c, segment, undecorated(s); kwargs...)
end

include("Tags.jl")
import .Tags: qrcode, radialstub, radialcut #, cpwlauncher #, launch!
import .Tags: pecbasedose, checkerboard, surf1d
export Tags
export qrcode
export radialstub, radialcut
export cpwlauncher, surf1d
# export launch!
export pecbasedose, checkerboard

# Operations on arrays of AbstractPolygons
for (op, dotop) in [(:+, :.+), (:-, :.-)]
    @eval function ($dotop){S<:Real, T<:Real}(a::AbstractArray{AbstractPolygon{S},1}, p::Point{T})
        b = similar(a)
        for (ia, ib) in zip(eachindex(a), eachindex(b))
            @inbounds b[ib] = ($op)(a[ia], p)
        end
        b
    end
end

include("GDS.jl")
import .GDS: GDS64
import .GDS: gdsbegin, gdsend, gdswrite
export GDS
export GDS64
export gdsbegin, gdsend, gdswrite

end
