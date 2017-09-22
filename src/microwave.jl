module Microwave
import Clipper: Clipper, ClipTypeDifference, ClipTypeIntersection, ClipTypeUnion
import StaticArrays
import ForwardDiff
import Devices
import Devices: bounds, center, centered, render!
using Devices.Paths
using Devices.Rectangles
using Devices.Polygons
using Devices.Points
using Devices.Cells
import Devices: AbstractPolygon, Coordinate, GDSMeta, Meta
import Unitful: NoUnits, cm, μm, nm, ustrip, unit

export bridge!
export checkerboard!
export device_template!
export flux_bias!
export grating!
export interdigit!
export jj!
export jj_top_pad!
export layerpixels!
export qubit!
export qubit_claw!
export radialcut!
export radialstub!

"""
    bridge!(c::Cell, steps, foot_width, foot_height, span, metas::AbstractVector{<:Meta})
Renders polygons to cell `c` to construct a bridge. Can be called twice to construct a
bridge with a hopover.

- `steps`: Number of discrete steps in the bridge height.
- `foot_width`: Width of the foot.
- `foot_height`: Height of the bridge foot (in the plane).
- `span`: Length of the bridge span.
- `metas`: A vector of `Meta` objects with length `steps + 1`. The first object is the
  `Meta` for the bridge foot and the others are for the bridge steps, in order.

```
    <-f.w.->                          <-f.w.->
    ******************************************  ---
    |+++++|                            |+++++|   |
    |+++++|                            |+++++|   |
    |+++++|                            |+++++|   |
    |+++++|<-----------span----------->|+++++|   | foot height
    |+++++|                            |+++++|   |
    |+++++|                            |+++++|   |
    |+++++|                            |+++++|   |
    ******************************************  ---
```

The profile of the bridge is given as `h(x) = H*(2 - cosh(2*cosh^(-1)(2) x/L))` where
`H` is the height of bridge and `L` is the total span of bridge. The inverse of h(x) is
taken to compute the size of each layer.
"""
function bridge!(c::Cell, steps, foot_width, foot_height, span,
        metas::AbstractVector{<:Meta})
    @assert length(metas) == steps + 1

    # Bridge Profile
    yinv_gnd(y, span) = span/2 * acosh(-y + 2) / acosh(2)
    ypos = linspace(0, 1, steps + 1)

    render!(c, Rectangle(Point(-(span/2 + foot_width), -foot_height/2),
        Point(-span/2, foot_height/2)), metas[1])
    render!(c, Rectangle(Point(span/2, -foot_height/2),
        Point(span/2 + foot_width, foot_height/2)), metas[1])

        x = 0.
        for (i, val) in enumerate(ypos)
            if i > 1
                xpos = yinv_gnd(val, span)
                render!(c, Rectangle(Point(x, -foot_height/2),
                    Point(xpos, foot_height/2)), metas[i])
                render!(c, Rectangle(Point(-x, -foot_height/2),
                    Point(-xpos, foot_height/2)), metas[i])
                x = xpos
            else
                x = yinv_gnd(val, span)
            end
        end
    c
end

"""
    checkerboard!{T}(c::Cell{T}, pixsize, rows::Integer, alt, meta::Meta=GDSMeta())
In cell `c`, generate a checkerboard pattern suitable for contrast curve measurement,
or getting the base dose for PEC.
  - `pixsize`: length of one side of a square
  - `rows`: number of rows == number of columns
  - `alt`: the square nearest `Point(zero(T), zero(T))` is filled (unfilled) if `false`
    (`true`). Use this to create a full tiling of the checkerboard, if you wish.
"""
function checkerboard!(c::Cell{T,S}, pixsize, rows::Integer, alt, meta::Meta=GDSMeta()) where {T,S}
    r = Rectangle(pixsize, pixsize)
    rcell = Cell{T,S}(uniquename("checkerboard"))
    render!(rcell, r, Rectangles.Plain(), meta)

    r1 = Int(ceil(rows/2))
    r2 = Int(floor(rows/2))
    a1 = CellArray(rcell, Point(zero(T), ifelse(alt, pixsize, zero(T)));
        dc = Point(2*pixsize, zero(T)),
        dr = Point(zero(T), 2*pixsize),
        nc = r1, nr = r1)
    a2 = CellArray(rcell, Point(pixsize, ifelse(alt, zero(T), pixsize)),
        dc = Point(2*pixsize, zero(T)),
        dr = Point(zero(T), 2*pixsize),
        nc = r2,
        nr = r2)

    push!(c.refs, a1)
    push!(c.refs, a2)
    c
end

"""
    device_template!{T}(d::Cell{T}, chip_meta::Meta, writeable_meta::Meta, marker_meta::Meta)
In cell `c`, make a template for a 1cm x 1cm chip. Includes chip outline, usable area
outline, and markers.
"""
function device_template!(d::Cell{T}, chip_meta::Meta, writeable_meta::Meta, marker_meta::Meta) where {T}
    # Device extents
    chip = Rectangle(1cm, 1cm)
    writeable = Rectangle(1cm, 0.7cm)
    render!(d, chip, Rectangles.Plain(), chip_meta)
    render!(d, writeable, Rectangles.Plain(), writeable_meta)

    # Markers
    marker = typeof(d)(uniquename("marker"))
    render!(marker, centered(Rectangle(20.0μm, 20.0μm)), Rectangles.Plain(), marker_meta)
    push!(d.refs, CellArray(marker, Point(500.0μm, 500.0μm),
        dr = Point(0μm, 500.0μm), dc = Point(9000μm, 0.0μm), nr=11, nc=2))
    d
end

function flux_bias!(c::Cell{T}, dir, flux_over, flux_under, flux_cut, z_trace, z_gap,
        meta::Meta) where {T}

    mx, mn = max(flux_over, flux_under), min(flux_over, flux_under)
    if dir == "l"
        flux_over, flux_under, flux_cut, z_trace, z_gap, mx, mn =
            -flux_over, -flux_under, -flux_cut, -z_trace, -z_gap, -mx, -mn
    end
    abs_gap = abs(z_gap)
    abs_trace = abs(z_trace)

    ground = Rectangle(Point(-flux_cut - z_gap - z_trace/2, zero(T)),
        Point(z_trace/2 + z_gap + mx, 2*abs_gap + abs_trace))
    belowcut = Rectangle(Point(-flux_cut - z_gap - z_trace/2, zero(T)),
        Point(-z_gap - z_trace/2, abs_trace + abs_gap))
    trace = Rectangle(Point(-z_trace/2, zero(T)),
        Point(z_trace/2, abs_trace + abs_gap))
    tap = Rectangle(Point(z_trace/2, abs_gap),
        Point(z_trace/2 + z_gap + mn, abs_trace + abs_gap))

    result = clip(Clipper.ClipTypeDifference, [ground], [belowcut])
    result = clip(Clipper.ClipTypeDifference, result, [trace])
    result = clip(Clipper.ClipTypeDifference, result, [tap])

    if flux_under != flux_over
        if abs(flux_under) > abs(flux_over)
            fill = Rectangle(Point(z_trace/2 + z_gap + mn, abs_gap),
                Point(z_trace/2 + z_gap + mx, abs_trace + 2*abs_gap))
        end
        if abs(flux_over) > abs(flux_under)
            fill = Rectangle(Point(z_trace/2 + z_gap + mn, zero(T)),
                Point(z_trace/2 + z_gap + mx, abs_trace + abs_gap))
        end
        # fill = convert(Polygon{typeof(1.0nm)}, fill)
        result = clip(Clipper.ClipTypeDifference, result, [fill])
    end

    for r in result
        render!(c, r, Polygons.Plain(), meta)
    end
    c
end

"""
    grating!{T}(c::Cell{T}, line, space, size, meta::Meta=GDSMeta())
Generate a square grating suitable e.g. for obtaining the base dose for PEC.
"""
function grating!(c::Cell{T,S}, line, space, size, meta::Meta=GDSMeta()) where {T,S}
    r = Rectangle(line, size)
    rcell = Cell{T,S}(uniquename("grating"))
    render!(rcell, r, Rectangles.Plain(), meta)

    a = CellArray(rcell, Point(zero(T), zero(T)); dc=Point(line+space, zero(T)),
        dr=Point(zero(T), zero(T)), nc=Int(floor(NoUnits(size/(line+space)))), nr=1)

    push!(c.refs, a)
    c
end

"""
    interdigit!{T}(c::Cell{T}, width, length, fingergap, fingeroffset, npairs::Integer,
        skiplast, meta::Meta=GDSMeta(0,0))
Creates interdigitated fingers, e.g. for a lumped element capacitor.
  - `width`: finger width
  - `length`: finger length
  - `fingeroffset`: x-offset at ends of fingers
  - `fingergap`: gap between fingers
  - `npairs`: number of fingers
  - `skiplast`: should we skip the last finger, leaving an odd number?
"""
function interdigit!(c::Cell{T,S}, width, length, fingergap, fingeroffset,
        npairs::Integer, skiplast, meta::Meta=GDSMeta(0,0)) where {T,S}
    for i in 1:npairs
        render!(c, Rectangle(Point(zero(T), (i-1) * 2 * (width + fingergap)),
            Point(length, (i-1) * 2 * (width + fingergap) + width)), meta)
    end
    for i in 1:(npairs-skiplast)
        render!(c, Rectangle(Point(fingeroffset, (2i-1) * (width + fingergap)),
            Point(fingeroffset + length, width + (2i-1) * (width + fingergap))), meta)
    end
    c
end

"""
    jj!{T}(c::Cell{T}, m, b, w1, w2, w3, w4, l1, l2, l3, l4, uc, t1, Θ, ϕ,
        jj_meta::Meta, uc_meta::Meta)
Explanation of parameters:

```                <-w3->
                   |████|  ◬
                   |████|  |
                   |████|  |
                   |█r3█|  l3
                   |████|  |
                   |████|  |
                   |████|  |
 ◬   ––––––––––––––+████|  ▿
 w2  ████████r2█████████|
 ▿ ◬ –––––––––––––––––––+
   b          <–l2–>
   |   <–-l4+w1–>
   ▿    ________
       |█r4█████|  ◬    | w4
          |██|     |
          |██|     |
     <-m->|r1|     l1
          |██|     |
          |██|     |
          |██|     ▿
          <w1>
          X origin
```

Other parameters:

- `c`: Cell for junctions (should be empty)
- `uc`: Amount of undercut to extend uniformly around the features
in the diagram. Note that no undercut extends beyond the top & bottom of figure.
"""
function jj!(c::Cell{T}, m, b, w1, w2, w3, w4, l1, l2, l3, l4, uc, t1, Θ, ϕ,
        jj_meta::Meta, uc_meta::Meta) where {T}

    # start drawing JJ
    r1 = Rectangle(Point(zero(T), zero(T)), Point(w1,l1-w4))
    r4 = Rectangle(Point(-l4/2, l1-w4), Point(w1+l4/2, l1))
    r2 = Rectangle(Point(-m,l1+b), Point(w1+l2+w3,l1+b+w2))
    r3 = Rectangle(Point(w1+l2, l1+b+w2), Point(w1+l2+w3, l1+b+w2+l3))

    # join r2, r3 into one polygon
    p14 = clip(ClipTypeUnion, r1, r4)[1]
    p23 = clip(ClipTypeUnion, r2, r3)[1]

    # Generate undercut
    ucb2 = uc + t1*tan(ϕ)
    u1 = offset(Rectangle(Point(zero(T), zero(T)), Point(w1,l1+b)), uc)[1]
    u23 = offset(p23, uc)[1]
    uca = Rectangle(Point(-m-uc, l1+b+w2), Point(w1+l2, uc+l1+b+w2+t1*tan(Θ)))
    ucb1 = Rectangle(Point(w1, zero(T)), Point(w1+uc+t1*tan(ϕ), l1+b))
    ucb2 = Rectangle(Point(w1+l2+w3, l1+b-uc), Point(w1+l2+w3+uc+t1*tan(ϕ), l1+b+w2+l3))
    u = clip(ClipTypeUnion, u1, u23)[1]
    u = clip(ClipTypeUnion, u, uca)[1]
    u = clip(ClipTypeUnion, u, ucb1)[1]
    u = clip(ClipTypeUnion, u, ucb2)[1]

    # Remove undercut sticking out top and bottom
    u = clip(ClipTypeIntersection, u,
        Rectangle(Point(T(-1000000), zero(T)), Point(T(1000000),l1+b+w2+l3)))[1]
    u = clip(ClipTypeDifference, u, p14)
    uclip = clip(ClipTypeDifference, u, [p23]) # could be an array
    layers = fill(uc_meta, length(uclip))
    push!(uclip, p14, p23)
    push!(layers, jj_meta, jj_meta)

    # Horizontally center the shapes
    cen = center(bounds(uclip))
    uclip .-= StaticArrays.Scalar(Point(getx(cen),zero(getx(cen))))

    # Render them
    for (x,y) in zip(uclip, layers)
        render!(c, x, Polygons.Plain(), y)
    end

    c
end


"""
    jj_top_pad!{T}(c::Cell{T}, pixcell, pixtop, pixbot, pixright, uuc, ruc, ext, padh,
            bandage_buffer, bandage_rounding, jj_meta, uc_meta, bandage_meta)
- `pixcell`: Cell containing a "pixel" of the bandaid hatching
- `pixtop`: Cell containing elements to put on the top side of the patch
- `pixbot`: Cell containing elements to put below the patch.
- `pixright`: Cell containing elements to put on the right side of the patch
- `uuc`: Upper undercut
- `ruc`: Right undercut
- `ext`: Width of rectangular landing pad
- `padh`: Height of rectangular landing pad
- `bandage_buffer`: How far the bandaid should extend beyond the patch (ea. side)
- `bandage_rounding`: Radius of rounded bandaid corners
"""
function jj_top_pad!(c::Cell{T}, pixcell, pixtop, pixbot, pixright, uuc, ruc, ext,
        padh, bandage_buffer, bandage_rounding, jj_meta, uc_meta, bandage_meta) where {T}

    # Big contact pad
    render!(c, Rectangle(ext, padh), Rectangles.Undercut(
        zero(T), uuc, ruc, zero(T), jj_meta, uc_meta))

    # Hatching
    b = bounds(pixcell)
    lpw, lph = width(b), height(b)

    ya, yb, yc = promote(padh + uuc, lph, padh + lph + uuc)
    yrange = ustrip(ya):ustrip(yb):ustrip(yc)
    top = yrange[end]*unit(ya) + lph
    bottom = yrange[1]*unit(ya)

    xa, xb, xc = promote(0.0μm, lpw, ext-lpw)
    xrange = ustrip(xa):ustrip(xb):ustrip(xc)
    right = xrange[end]*unit(xa) + lpw

    push!(c.refs, CellArray(pixcell, Point(xrange[1]*unit(xa), yrange[1]*unit(ya));
        nc = length(xrange), nr = length(yrange),
        dc = Point(step(xrange)*unit(xa), zero(T)),
        dr = Point(zero(T), step(yrange)*unit(ya))))
    push!(c.refs, CellArray(pixtop, Point(xrange[1]*unit(xa), top);
        nc = length(xrange), nr = 1,
        dc = Point(step(xrange)*unit(xa), zero(T)),
        dr = Point(zero(T), zero(T))))
    push!(c.refs, CellArray(pixbot, Point(xrange[1]*unit(xa), bottom);
        nc = length(xrange), nr = 1,
        dc = Point(step(xrange)*unit(xa), zero(T)),
        dr = Point(zero(T), zero(T))))
    push!(c.refs, CellArray(pixright, Point(right, yrange[1]*unit(ya));
        nc = 1, nr = length(yrange),
        dc = Point(zero(T), zero(T)),
        dr = Point(zero(T), step(yrange)*unit(ya))))

    # Bandaid
    patch = Rectangle(ext + ruc + 2*bandage_buffer,
        length(yrange)*lph + 2*uuc + 2*bandage_buffer)
    render!(c, patch + Point(-bandage_buffer, padh - bandage_buffer),
        Rectangles.Rounded(bandage_rounding), bandage_meta)

    # Center in x (up to undercut and bandaid); bottom edge of elements will sit at y = 0
    c -= Point(ext/2, gety(center(c)))
    c += Point(zero(T), height(bounds(c))/2)
    c
end


"""
    layerpixels!{T}(c::Cell, layers::AbstractMatrix{Int}, pixsize)
Given `layers`, a matrix of `Int`, make a bitmap of `Rectangle` where the GDS-II layer
corresponds to the number in the matrix. If the number is less than one, don't
write the rectangle. All the rectangles get rendered into cell `c`. The rectangles are all
in the first quadrant of the cell.
"""
function layerpixels!(c::Cell, layers::AbstractMatrix{Int}, pixsize)
    s = size(layers)
    for i in 1:s[1], j in 1:s[2]
        layers[i,j] < 0 && continue
        r = Rectangle(pixsize, pixsize)
        r += Point((j-1)*pixsize, (s[1]-i)*pixsize)
        render!(c, r, Rectangles.Plain(), GDSMeta(layers[i,j]))
    end
    c
end

"""
    qubit!{T}(c::Cell{T}, trace, gap, claw_width, claw_length, claw_gap, ground_gap,
        qubit_width, qubit_gap, meta::Meta)
Renders the base metal for a capacitively-shunted charge qubit into cell `c`.
"""
function qubit!(c::Cell{T}, qubit_length, qubit_width, qubit_gap, qubit_cap_bottom_gap,
    gap_between_leads_for_jjs, lead_width, junc_pad_spacing, meta::Meta) where {T}

    vert_extent = (qubit_cap_bottom_gap - gap_between_leads_for_jjs) / 2

    # Capacitor metal
    qubitCap = convert(Polygon{T},
        Rectangle(Point(-qubit_width/2, zero(T)), Point(qubit_width/2, qubit_length)))

    # Qubit side junction lead
    leftJunctionPadQubitSide = Polygon(
        Point(zero(T), zero(T)),
        Point(zero(T), -2*lead_width),
        Point(-2*lead_width, -2*lead_width),
        Point(-2*lead_width, -lead_width),
        Point(-lead_width, -lead_width),
        Point(-lead_width, zero(T))) - Point(junc_pad_spacing, zero(T))

    rightJunctionPadQubitSide = Polygon(
        Point(zero(T), zero(T)),
        Point(zero(T), -2*lead_width),
        Point(2*lead_width, -2*lead_width),
        Point(2*lead_width, -lead_width),
        Point(lead_width, -lead_width),
        Point(lead_width, zero(T))) + Point(junc_pad_spacing, zero(T))

    qubitCap = clip(ClipTypeUnion, leftJunctionPadQubitSide, qubitCap)[1]
    qubitCap = clip(ClipTypeUnion, rightJunctionPadQubitSide, qubitCap)[1]

    # Ground side junction lead
    gapFill = convert(Polygon{T},
        Rectangle(Point(-qubit_width/2 - qubit_gap, -qubit_cap_bottom_gap),
                  Point(qubit_width/2 + qubit_gap, qubit_gap + qubit_length)))

    rightJunctionPadGroundSide = Polygon(
        Point(zero(T), zero(T)),
        Point(zero(T), qubit_cap_bottom_gap- 2*lead_width - gap_between_leads_for_jjs),
        Point(-2*lead_width, qubit_cap_bottom_gap - 2*lead_width - gap_between_leads_for_jjs),
        Point(-2*lead_width, qubit_cap_bottom_gap - 3*lead_width - gap_between_leads_for_jjs),
        Point(-lead_width, qubit_cap_bottom_gap - 3*lead_width - gap_between_leads_for_jjs),
        Point(-lead_width, zero(T))) -
            Point(-junc_pad_spacing - 3*lead_width, qubit_cap_bottom_gap)
    leftJunctionPadGroundSide = Polygon(
        Point(zero(T), zero(T)),
        Point(zero(T), qubit_cap_bottom_gap - 2*lead_width - gap_between_leads_for_jjs),
        Point(2*lead_width, qubit_cap_bottom_gap - 2*lead_width - gap_between_leads_for_jjs),
        Point(2*lead_width, qubit_cap_bottom_gap - 3*lead_width - gap_between_leads_for_jjs),
        Point(lead_width, qubit_cap_bottom_gap - 3*lead_width - gap_between_leads_for_jjs),
        Point(lead_width, zero(T))) -
            Point(junc_pad_spacing + 3*lead_width, qubit_cap_bottom_gap)

    gapFill = clip(ClipTypeDifference, gapFill, leftJunctionPadGroundSide)[1]
    gapFill = clip(ClipTypeDifference, gapFill, rightJunctionPadGroundSide)[1]

    cuts = clip(ClipTypeDifference, gapFill, qubitCap)
    for cut in cuts
        render!(c, cut, Polygons.Plain(), meta)
    end

    c
end

"""
    qubit_claw!{T}(c::Cell{T}, trace, gap, claw_width, claw_length, claw_gap, ground_gap,
        qubit_width, qubit_gap, meta::Meta)
Renders a "claw" into cell `c` suitable for attaching to the end of a resonator. One can
wrap the claw around a capacitively-shunted charge qubit generated by [`qubit!`](@ref) for
capacitive coupling between the qubit and resonator.
"""
function qubit_claw!(c::Cell{T}, trace, gap, claw_width, claw_length, claw_gap,
        ground_gap, qubit_width, qubit_gap, meta::Meta) where {T}

    totalWidthGap = claw_width*2 + claw_gap*4 + ground_gap*2 + qubit_width + qubit_gap*2
    totalWidth = totalWidthGap - 2*claw_gap

    ground = Rectangle(Point(-claw_gap, -totalWidthGap/2),
        Point(claw_gap + claw_length, totalWidthGap/2))
    top = Rectangle(Point(zero(T), -totalWidth/2),
        Point(claw_width, totalWidth/2))
    left = Rectangle(Point(zero(T), -totalWidth/2),
        Point(claw_length, -totalWidth/2 + claw_width))
    right = Rectangle(Point(zero(T), totalWidth/2 - claw_width),
        Point(claw_length, totalWidth/2))
    middle =  Rectangle(Point(claw_width + claw_gap, -totalWidth/2 + claw_width + claw_gap),
        Point(claw_gap + claw_length, totalWidth/2 - claw_width - claw_gap))
    readoutres = Rectangle(Point(-claw_gap, -trace/2 - gap),
        Point(zero(T), trace/2 + gap))

    gr = clip(ClipTypeDifference, [ground], [readoutres])
    g = clip(ClipTypeDifference, gr, [middle])
    tl = clip(ClipTypeUnion, [top], [left])
    metal = clip(ClipTypeUnion, tl, [right])
    for cut in clip(ClipTypeDifference, g, metal)
        render!(c, cut, Polygons.Plain(), meta)
    end

    c
end

"""
    radialcut!{T}(c::Cell{T}, r, Θ, h, meta::Meta=GDSMeta(0,0); narc::Int=197)
Renders a radial cut (like a radial stub with no metal) into cell `c`.
The polygon has to be subtracted from a ground plane.

The parameter `h` is made available in the method signature rather than `a`
because the focus of the arc (top of polygon) can easily centered in a waveguide.
If it is desirable to control `a` instead, use trig: `a/2 = h*tan(Θ/2)`.

Parameters as follows, where X marks the origin and (*nothing above the origin
is part of the resulting polygon*):

```
                       Λ
                      /│\\
                     / │ \\
                    /  |  \\
              .    /   │Θ/2\\
             .    /    │----\\
            /    /   h │     \\
           /    /      │      \\
          /    /       │       \\
         r    /        │        \\
        /    /         │         \\
       /    /----------X----------\\
      /    /{--------- a ---------}\\
     .    /                         \\
    .    /                           \\
        /                             \\
       /                               \\
      /                                 \\
      --┐                             ┌--
        └--┐                       ┌--┘
           └--┐                 ┌--┘
              └--┐           ┌--┘
                 └-----------┘
                 (circular arc)
```
"""
function radialcut!(c::Cell{T}, r, Θ, h, meta::Meta=GDSMeta(0,0); narc::Int=197) where {T}
    p = Path(Point(h*tan(Θ/2), -h), α0=(Θ-π)/2)
    straight!(p, r-h*sec(Θ/2), Paths.Trace(r))
    turn!(p, -π/2, zero(T))
    turn!(p, -Θ, r)
    turn!(p, -π/2, zero(T))
    straight!(p, r-h*sec(Θ/2))

    seg = segment(p[3])
    pts = map(seg, linspace(zero(T), pathlength(seg), narc))
    push!(pts, Paths.p1(p))
    h != zero(T) && push!(pts, Paths.p0(p))
    poly = Polygon(pts) + Point(zero(T), h) # + Point(0.0, (r-h)/2)
    render!(c, poly, Polygons.Plain(), meta)
end

"""
    radialstub!{T}(c::Cell{T}, r, Θ, h, t, meta::Meta=GDSMeta(0,0); narc::Int=197)
See also the documentation for `radialcut!`.

Returns a polygon for a radial stub. The polygon has to be subtracted from a
ground plane, and will leave a defect in the ground plane of uniform width `t`
that outlines the (metallic) radial stub. `r` refers to the radius of the
actual stub, not the radius of the circular arc bounding the ground plane defect.
Likewise `h` has an analogous meaning to that in `radialcut!` except it refers here
to the radial stub, not the ground plane defect.
"""
function radialstub!(c::Cell{T}, r, Θ, h, t, meta::Meta=GDSMeta(0,0); narc::Int=197) where {T}
    # inner ring (bottom)
    pts = [Point(r*cos(α),r*sin(α)) for α in linspace(-(Θ+π)/2, (Θ-π)/2, narc)]
    # top right
    push!(pts, Point(h*tan(Θ/2), -h), Point(h*tan(Θ/2)+t*sec(Θ/2), -h))
    # outer ring (bottom)
    R = r + t # outer ring radius
    a2 = R^2 / sin(Θ/2)^2
    a1 = 2*R*t*csc(Θ/2)
    a0 = R^2 - (R^2-t^2)*csc(Θ/2)^2
    ϕ = 2*acos((-a1+sqrt(a1^2-4*a0*a2))/(2*a2))
    append!(pts,
        [Point(R*cos(α),R*sin(α)) for α in linspace((ϕ-π)/2, -(ϕ+π)/2, narc)])
    # top left
    push!(pts, Point(-h*tan(Θ/2)-t*sec(Θ/2), -h), Point(-h*tan(Θ/2), -h))

    # move to origin
    poly = Polygon(pts) + Point(zero(T), h)
    render!(c, poly, Polygons.Plain(), meta)
end

# This used the pyqrcode package
# """
#     qrcode!{T<:Coordinate}(a::AbstractString, c::Cell{T}; pixel::T=T(1), kwargs...)
# Renders a QR code of the string `a` with pixel size `pixel` to cell `c`.
# The pixel size defaults to one of whatever the cell's unit is.
# The lower left of the QR code will be at the origin of the cell.
# """
# function qrcode!{T<:Coordinate}(a::AbstractString, c::Cell{T}; pixel::T=T(1),
#         kwargs...)
#
#     myqr = qr()[:create](a)
#     str = myqr[:text](quiet_zone=0)
#
#     y = zero(pixel)
#     rects = Rectangle{T}[]
#     for line in eachline(IOBuffer(str))
#         ones0s = chomp(line)
#         where = findin(ones0s, '1')
#         for i in where
#             r = Rectangle(Point(zero(pixel),-pixel), Point(pixel,zero(pixel)); kwargs...)
#             r += Point{T}((i-1)*pixel, y)
#             push!(rects, r)
#         end
#         y -= pixel
#     end
#
#     for r in rects
#         r += Point(zero(pixel), -y)
#         render!(c, r, Rectangles.Plain())
#     end
#     c
# end

#
# """
# ```
# surf1d(length, width, contour_fn; zbins=20, step=1., max_seg_len=1.)
# ```
#
# Given `length` and `width` of a rectangular patch, this generates a mesh for
# 3D surface PEC according to a particular contour function `contour_fn`. The
# meshing is done in the length direction (+y). The number of bins (layers)
# can be controlled with `zbins`, the maximum step change in the resist height
# is given by `step`, and the `max_seg_len` is the maximum segment length in
# the mesh.
# """
# function surf1d(length, width, contour_fn; zbins=20, step=1., max_seg_len=1.)
#
#     polys = AbstractPolygon[]
#     heights = Float64[]
#
#     l = 0.
#     while l <= length
#         m = abs(ForwardDiff.derivative(contour_fn, l))
#         h = contour_fn(l)
#         dim = min(step/m, max_seg_len)
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
#
#     # Kind of dumb, maximum will only appear once
#     for (i,h) in enumerate(heights)
#         j=zbins
#         println(h)
#         println(lin[j])
#         while h < lin[j]
#             j == 1 && break
#             j-=1
#         end
#         polys[i].properties[:layer] = j
#     end
#     polys
# end
#
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
#
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
end
