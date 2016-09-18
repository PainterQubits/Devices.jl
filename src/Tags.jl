module Tags
import Clipper
import Compat.String
import ForwardDiff
import Devices
import Devices: render!
using Devices.Paths
using Devices.Rectangles
using Devices.Polygons
using Devices.Points
using Devices.Cells
using Devices: uniquename
import ..AbstractPolygon

qr() = Devices._qr
gdspy() = Devices._gdspy

export qrcode
export radialcut
export radialstub
export cpwlauncher
export launch!
export checkerboard
export pecbasedose
export surf1d
"""
`qrcode{T<:Real}(a::AbstractString, name::String, pixel::T=1.0; kwargs...)`

Renders a QR code of the string `a` with pixel size `pixel` to a new cell with `name`.
The lower left of the QR code will be at the origin of the cell.
"""
function qrcode{T<:Real}(a::AbstractString, name::String, pixel::T=1.0, center::Bool=false; kwargs...)
    c = Cell{T}(name)
    qrcode(a, c, pixel, center; kwargs...)
    c
end

function qrcode{T<:Real}(a::AbstractString, c::Cell, pixel::T=1.0, center::Bool=false; kwargs...)
    myqr = qr()[:create](a)
    str = myqr[:text](quiet_zone=0)

    y = zero(pixel)
    rects = Rectangle{T}[]
    for line in eachline(IOBuffer(str))
        ones0s = chomp(line)
        where = findin(ones0s, '1')
        for i in where
            r = Rectangle(Point(zero(pixel),-pixel), Point(pixel,zero(pixel)); kwargs...)
            r += Point{T}((i-1)*pixel, y)
            push!(rects, r)
        end
        y -= pixel
    end

    for r in rects
        r += Point(zero(pixel), -y)
        render!(c, r, Rectangles.Plain())
    end
    c
end

"""
```
radialcut{T<:Real}(r::T, Θ, c::T; narc=197)
```

Returns a polygon for a radial cut (like a radial stub with no metal).
The polygon has to be subtracted from a ground plane.

The parameter `c` is made available in the method signature rather than `a`
because the focus of the arc (top of polygon) can easily centered in a waveguide.
If it is desirable to control `a` instead, use trig: `a/2 = c*tan(Θ/2)`.

Parameters as follows, where X marks the origin and nothing above the origin
is part of the resulting polygon:

```
                          Λ
                         ╱│╲
                        ╱ │ ╲
                       ╱  |  ╲
                 .    ╱   │Θ/2╲
                .    ╱    │----╲
               ╱    ╱   c │     ╲
              ╱    ╱      │      ╲
             ╱    ╱       │       ╲
            r    ╱        │        ╲
           ╱    ╱         │         ╲
          ╱    ╱──────────X──────────╲
         ╱    ╱ {──────── a ────────} ╲
        .    ╱                         ╲
       .    ╱                           ╲
           ╱                             ╲
          ╱                               ╲
         ╱                                 ╲
         ──┐                             ┌──
           └──┐                       ┌──┘
              └──┐                 ┌──┘
                 └──┐           ┌──┘
                    └───────────┘
                    (circular arc)
```
"""
function radialcut{T<:Real}(r::T, Θ, c::T; narc=197)
    p = Path(Point(c*tan(Θ/2),-c), α0=(Θ-π)/2)
    straight!(p, r-c*sec(Θ/2))
    turn!(p, -π/2, 0.0)
    turn!(p, -Θ, r)
    turn!(p, -π/2, 0.0)
    straight!(p, r-c*sec(Θ/2))

    f = p[3][1].f
    pts = map(f, linspace(0.0,1.0,narc))
    push!(pts, Paths.p1(p))
    c != 0.0 && push!(pts, Paths.p0(p))
    poly = Polygon(pts) + Point(0.0, c) # + Point(0.0, (r-c)/2)
    2*c*tan(Θ/2), poly
end

"""
```
radialstub{T<:Real}(r::T, Θ, c::T, t::T; narc=197)
```

See also the documentation for `radialcut`.

Returns a polygon for a radial stub. The polygon has to be subtracted from a
ground plane, and will leave a defect in the ground plane of uniform width `t`
that outlines the (metallic) radial stub. `r` refers to the radius of the
actual stub, not the radius of the circular arc bounding the ground plane defect.
Likewise `c` has an analogous meaning to that in `radialcut` except it refers here
to the radial stub, not the ground plane defect.
"""
function radialstub{T<:Real}(r::T, Θ, c::T, t::T; narc=197)
    # inner ring (bottom)
    pts = [Point(r*cos(α),r*sin(α)) for α in linspace(-(Θ+π)/2, (Θ-π)/2, narc)]
    # top right
    push!(pts, Point(c*tan(Θ/2), -c), Point(c*tan(Θ/2)+t*sec(Θ/2), -c))
    # outer ring (bottom)
    R = r+t # outer ring radius
    a2 = R^2/sin(Θ/2)^2
    a1 = 2*R*t*csc(Θ/2)
    a0 = R^2 - (R^2-t^2)*csc(Θ/2)^2
    ϕ = 2*acos((-a1+sqrt(a1^2-4*a0*a2))/(2*a2))
    append!(pts,
        [Point(R*cos(α),R*sin(α)) for α in linspace((ϕ-π)/2, -(ϕ+π)/2, narc)])
    # top left
    push!(pts, Point(-c*tan(Θ/2)-t*sec(Θ/2), -c), Point(-c*tan(Θ/2), -c))

    # move to origin
    poly = Polygon(pts) + Point(zero(T), c)
    2*c*tan(Θ/2), poly
end

# """
# ```
# cpwlauncher{T<:Real}(extround::T=5., trace0::T=300., trace1::T=5.,
#     gap0::T=150., gap1::T=2.5, flatlen::T=250., taperlen::T=250.)
# ```
#
# Draws half of a CPW launcher inside a new cell.
#
# There are numerous keyword arguments to control the behavior:
#
# - `extround`: Rounding radius of the outermost corners; should be less than `gap0`.
# - `trace0`: Bond pad width.
# - `trace1`: Center trace width of next CPW segment.
# - `gap0`: Gap width adjacent to bond pad.
# - `gap1`: Gap width of next CPW segment.
# - `flatlen`: Bond pad length.
# - `taperlen`: Length of taper region between bond pad and next CPW segment.
#
# The polygons in the method definition are labeled as:
# ```
#  ___________
# |p3 |  p2  |\
# |___|______| \  p1
# |   |       \ \
# |p4 |        \|
# |___|
# ```
#
# Returns the new cell.
# """
# function cpwlauncher{T<:Real}(extround::T=5., trace0::T=300., trace1::T=5.,
#     gap0::T=150., gap1::T=2.5, flatlen::T=250., taperlen::T=250.)
#
#     p1 = Polygon(Point(zero(T), trace1/2),
#             Point(zero(T), trace1/2 + gap1),
#             Point(-taperlen, trace0/2 + gap0),
#             Point(-taperlen, trace0/2))
#     p2 = Rectangle(flatlen, gap0) + Point(-taperlen-flatlen, trace0/2)
#     p3 = Rectangle(gap0, gap0) + Point(-taperlen-flatlen-gap0, trace0/2)
#     p4 = Rectangle(gap0, trace0/2) + Point(-taperlen-flatlen-gap0, zero(T))
#
#     c = Cell{T}(replace("cpwlauncher"*string(gensym()),"##","_"))
#     push!(c.elements, p1,p2,p3,p4)
#     c
# end
#
# """
# ```
# launch!(p::Path; extround=5, trace0=300, trace1=5,
#         gap0=150, gap1=2.5, flatlen=250, taperlen=250)
# ```
#
# Add a launcher to the path. Somewhat intelligent in that the launcher will
# reverse its orientation depending on if it is at the start or the end of a path.
#
# There are numerous keyword arguments to control the behavior:
#
# - `extround`: Rounding radius of the outermost corners; should be less than `gap0`.
# - `trace0`: Bond pad width.
# - `trace1`: Center trace width of next CPW segment.
# - `gap0`: Gap width adjacent to bond pad.
# - `gap1`: Gap width of next CPW segment.
# - `flatlen`: Bond pad length.
# - `taperlen`: Length of taper region between bond pad and next CPW segment.
#
# Returns nothing.
# """
# function launch!(p::Path; extround=5., trace0=300., trace1=5.,
#         gap0=150., gap1=2.5, flatlen=250., taperlen=250.)
#     c = cpwlauncher(extround,
#                     trace0,
#                     trace1,
#                     gap0,
#                     gap1,
#                     flatlen,
#                     taperlen)
#     if isempty(p)
#         attach!(p, CellReference(c, Point(0.,0.)), 0.)
#         attach!(p, CellReference(c, Point(0.,0.), xrefl=true), 0.)
#     else
#         attach!(p, CellReference(c, Point(0.,0.), rot=180.), 1.)
#         attach!(p, CellReference(c, Point(0.,0.), xrefl=true, rot=180.), 1.)
#     end
#     nothing
# end


"""
```
checkerboard{T<:Real}(pixsize::T=10.;rows=28, kwargs...)
```

Generate a checkerboard pattern suitable for contrast curve measurement, or
getting the base dose for BEAMER PEC.

Note that the tip radius of the Ambios XP-2 profilometer is 2.5μm.
"""
function checkerboard{T<:Real}(pixsize::T=10.;rows=28, kwargs...)
    r = Rectangle(pixsize, pixsize; kwargs...)
    rcell = Cell{T}(uniquename("checker"))
    render!(rcell, r, Rectangles.Plain())

    r1 = Int(ceil(rows/2))
    r2 = Int(floor(rows/2))
    a1 = CellArray(rcell, Point(zero(T), zero(T)),
        Point(2*pixsize, zero(T)), Point(zero(T), 2*pixsize), r1, r1)
    a2 = CellArray(rcell, Point(pixsize, pixsize),
        Point(2*pixsize, zero(T)), Point(zero(T), 2*pixsize), r2, r2)
    c = Cell{T}(uniquename("checkerboard"))
    push!(c.refs, a1)
    push!(c.refs, a2)
    c
end

"""
```
pecbasedose(kwargs...)
```

Generate lines and spaces suitable for obtaining the base dose for BEAMER PEC
(100 keV on Si).

To do: Modify to be more flexible for other substrates, beam energies, etc.
"""
function pecbasedose(kwargs...)
    r = Rectangle(0.1, 200.; kwargs...)
    rcell = Cell(uniquename("line"))
    render!(rcell, r, Rectangles.Plain())

    a = CellArray(rcell, Point(0., 0.),
        Point(0.2, 0.), Point(0., 0.), 1000, 1)
    c = Cell(uniquename("pecbasedose"))
    push!(c.refs, a)
    c
end

# function mesh1d(length, width, contour_fn; zbins=10, max_seg_len=1., layer=0)
#
#     polys = AbstractPolygon[]
#     heights = Float64[]
#
#     l = 0.
#     while l <= length
#         m = abs(ForwardDiff.derivative(contour_fn, l))
#         h = contour_fn(l)
#         dim = min(max_seg_len/m, max_seg_len)
#         push!(polys, Rectangle(width, dim, layer=layer) + Point(0.,l))
#         push!(heights, contour_fn(l + dim/2))
#         l += dim
#     end
#
#     # Total length adjustment
#     totlen = gety(polys[end].ur)
#     for p in polys
#         p.ll = Point(getx(p.ll), gety(p.ll) * length/totlen)
#         p.ur = Point(getx(p.ur), gety(p.ur) * length/totlen)
#     end
#
#     # Layer assignment (in principle this could be improved by clustering, etc.)
#     lin = linspace(minimum(heights), maximum(heights), zbins)
#     # slow / dumb
#     for (i,h) in enumerate(heights)
#         j=zbins
#         println(h)
#         println(lin[j])
#         while h < lin[j]
#             j-=1
#         end
#         polys[i].properties[:layer] = j
#     end
#     polys
# end


"""
```
surf1d(length, width, contour_fn; zbins=20, step=1., max_seg_len=1.)
```

Given `length` and `width` of a rectangular patch, this generates a mesh for
3D surface PEC according to a particular contour function `contour_fn`. The
meshing is done in the length direction (+y). The number of bins (layers)
can be controlled with `zbins`, the maximum step change in the resist height
is given by `step`, and the `max_seg_len` is the maximum segment length in
the mesh.
"""
function surf1d(length, width, contour_fn; zbins=20, step=1., max_seg_len=1.)

    polys = AbstractPolygon[]
    heights = Float64[]

    l = 0.
    while l <= length
        m = abs(ForwardDiff.derivative(contour_fn, l))
        h = contour_fn(l)
        dim = min(step/m, max_seg_len)
        push!(polys, Rectangle(width, dim, layer=layer) + Point(0.,l))
        push!(heights, contour_fn(l + dim/2))
        l += dim
    end

    # Total length adjustment
    totlen = gety(polys[end].ur)
    for p in polys
        p.ll = Point(getx(p.ll), gety(p.ll) * length/totlen)
        p.ur = Point(getx(p.ur), gety(p.ur) * length/totlen)
    end

    # Layer assignment (in principle this could be improved by clustering, etc.)
    lin = linspace(minimum(heights), maximum(heights), zbins)

    # Kind of dumb, maximum will only appear once
    for (i,h) in enumerate(heights)
        j=zbins
        println(h)
        println(lin[j])
        while h < lin[j]
            j == 1 && break
            j-=1
        end
        polys[i].properties[:layer] = j
    end
    polys
end

end
