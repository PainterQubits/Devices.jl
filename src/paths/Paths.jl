module Paths

using ..Points

import Base:
    convert,
    start,
    done,
    next,
    zip,
    enumerate,
    rest,
    take,
    drop,
    cycle,
    isempty,
    empty!,
    length,
    endof,
    size,
    getindex,
    setindex!,
    push!,
    pop!,
    unshift!,
    shift!,
    append!

using ForwardDiff
# import Plots
import Devices
import Devices: bounds, cell, render
gdspy() = Devices._gdspy

export Path

export CPW
export Trace

export adjust!
export attach!
export launch!
export meander!
export param
export pathlength
# export preview
export simplify!
export straight!
export turn!

"""
For a style `s` and parameteric argument `t`, returns the distance
between the centers of parallel paths rendered by gdspy.
"""
function distance end

"""
For a style `s` and parameteric argument `t`, returns a distance tangential
to the path specifying the lateral extent of the polygons rendered by gdspy.
"""
function extent end

"""
For a style `s` and parameteric argument `t`, returns the number of parallel
paths rendered by gdspy.
"""
function paths end

"""
For a style `s` and parameteric argument `t`, returns the width
of paths rendered by gdspy.
"""
function width end

"""
`direction(p::Function, t)`

For some parameteric function `p(t)↦Point(x(t),y(t))`, returns the angle at
which the path is pointing for a given `t`.
"""
function direction(p::Function, t)
    f′ = gradient(p, t)
    fx′,fy′ = getx(f′),gety(f′)
    if !(fx′ ≈ 0)
        atan(fy′/fx′)
    else
        if fy′ > 0
            π/2
        elseif fy′ < 0
            -π/2
        else
            error("Could not determine last angle.")
        end
    end
end

"""
`abstract Style`

How to render a given path segment. All styles should implement the following
methods:

 - `distance`
 - `extent`
 - `paths`
 - `width`
 - `divs`
"""
abstract Style

"""
`abstract Segment{T<:Real}`

Path segment in the plane. All Segment objects should have the implement
the following methods:

- `length`
- `origin`
- `α0`
- `setorigin!`
- `setα0!`
- `lastangle`
"""
abstract Segment{T<:Real}

include("Styles.jl")
include("Segments.jl")

"Unstyled path. Can describe any path in the plane."
type Path{T<:Real} <: AbstractArray{Tuple{Segment{T},Style},1}
    origin::Point{2,T}
    α0::Real
    style0::Style
    segments::Array{Segment{T},1}
    styles::Array{Style,1}
    Path(origin::Point{2,T}, α0::Real, style0::Style, segments::Array{Segment{T},1},
        styles::Array{Style,1}) = new(origin, α0, style0, segments, styles)
    Path(style::Style) =
        new(Point(zero(T),zero(T)), 0.0, style, Segment{T}[], Style[])
end
Path{T<:Real}(origin::Point{2,T}=Point(0.0,0.0), α0::Real=0.0, style0::Style=Trace(1.0)) =
    Path{T}(origin, α0, style0, Segment{T}[], Style[])
Path{T<:Real}(origin::Tuple{T,T}) =
    Path(Point(float(origin[1]),float(origin[2])))
Path{T<:Real}(origin::Tuple{T,T}, α0::Real) =
    Path(Point(float(origin[1]),float(origin[2])), α0)

"""
`pathlength(p::Path)`

Physical length of a path. Note that `length` will return the number of
segments in a path, not the physical length.
"""
pathlength(p::Path) = pathlength(p.segments)

"""
`pathlength(p::AbstractArray{Segment})`

Total physical length of segments.
"""
pathlength{T<:Real}(parr::AbstractArray{Segment{T},1}) = mapreduce(length, +, parr)

"""
`α0(p::Path)`

First angle of a path.
"""
function α0(p::Path)
    if isempty(p)
        p.α0
    else
        α0(p.segments[1])
    end
end

"""
`lastangle(p::Path)`

Last angle of a path.
"""
function lastangle(p::Path)
    if isempty(p)
        p.α0
    else
        lastangle(p.segments[end])
    end
end

"""
`origin(p::Path)`

First point of a path.
"""
function origin(p::Path)
    if isempty(p)
        p.origin
    else
        origin(p.segments[1])
    end
end

"""
`lastpoint(p::Path)`

Last point of a path.
"""
function lastpoint(p::Path)
    if isempty(p)
        p.origin
    else
        lastpoint(p.segments[end])
    end
end

"""
`firststyle(p::Path)`

Style of the first segment of a path.
"""
function firststyle(p::Path)
    if isempty(p)
        p.style0
    else
        p.styles[1]
    end
end

"""
`laststyle(p::Path)`

Style of the last segment of a path.
"""
function laststyle(p::Path)
    if isempty(p)
        p.style0
    else
        p.styles[end]
    end
end

"""
`adjust!(p::Path, n::Integer=1)`

Adjust a path's parametric functions starting from index `n`.
Used internally whenever segments are inserted into the path.
"""
function adjust!(p::Path, n::Integer=1)
    isempty(p) && return
    m = n
    if m == 1
        seg,sty = p[1]
        setorigin!(seg, p.origin)
        setα0!(seg, p.α0)
        m += 1
    end
    for j in m:length(p)
        seg,sty = p[j]
        seg0,sty0 = p[j-1]
        setorigin!(seg, lastpoint(seg0))
        setα0!(seg, lastangle(seg0))
    end
end

# Methods for Path as AbstractArray
length(p::Path) = length(p.segments)
start(p::Path) = start(zip(p.segments,p.styles))
done(p::Path, state) = done(zip(p.segments,p.styles), state)
next(p::Path, state) = next(zip(p.segments,p.styles), state)
zip(paths::Path...) = zip(map(x->zip(p.segments,p.styles), paths)) # is correct?
enumerate(p::Path) = enumerate(zip(p.segments,p.styles))
rest(p::Path, state) = rest(zip(p.segments,p.styles), state)
take(p::Path, n::Int) = take(zip(p.segments,p.styles), n)
drop(p::Path, n::Int) = drop(zip(p.segments,p.styles), n)
cycle(p::Path) = cycle(zip(p.segments,p.styles))
isempty(p::Path) = isempty(p.segments)
empty!(p::Path) = begin empty!(p.segments); empty!(p.styles) end
endof(p::Path) = endof(zip(p.segments,p.styles))
size(p::Path) = size(p.segments)
getindex(p::Path, i::Integer) = (p.segments[i], p.styles[i])
function setindex!(p::Path, v::Tuple{Segment,Style}, i::Integer)
    p.segments[i] = v[1]
    p.styles[i] = v[2]
    adjust!(p, i)
end

function setindex!(p::Path, v::Segment, i::Integer)
    p.segments[i] = v
    adjust!(p, i)
end

function setindex!(p::Path, v::Style, i::Integer)
    p.styles[i] = v
end

for x in [:push!, :unshift!]
    @eval function ($x)(p::Path, segsty::Tuple{Segment, Style})
        ($x)(p.segments, segsty[1])
        ($x)(p.styles, segsty[2])
    end
    @eval function ($x)(p::Path, seg::Segment, sty::Style)
        ($x)(p, (seg,sty))
    end
    @eval function ($x)(p::Path, segsty0::Tuple{Segment, Style},
        segsty::Tuple{Segment,Style}...)
        ($x)(p, segsty0)
        for x in segsty
            ($x)(p, x)
        end
    end
end

pop!(p::Path) = pop!(p.segments), pop!(p.styles)
shift!(p::Path) = shift!(p.segments), shift!(p.styles)

"""
`append!(p::Path, p′::Path)`

Given paths `p` and `p′`, path `p′` is appended to path `p`.
The origin and initial angle of the first segment from path `p′` is
modified to match the last point and last angle of path `p`.
"""
function append!(p::Path, p′::Path)
    isempty(p′) && return
    i = length(p)
    lp, la = lastpoint(p), lastangle(p)
    append!(p.segments, p′.segments)
    append!(p.styles, p′.styles)
    setorigin!(p.segments[i+1], lp)
    setα0!(p.segments[i+1], la)
    adjust!(p, i+1)
    nothing
end

"""
`simplify!(p::Path)`

All segments of a path are turned into a `CompoundSegment` and all
styles of a path are turned into a `CompoundStyle`. The idea here is:

- Indexing the path becomes more sane when you can combine several path
segments into one logical element. A launcher would have several indices
in a path unless you could simplify it.
- You don't need to think hard about boundaries between straights and turns
when you want a continuous styling of a very long path.
"""
function simplify!(p::Path)
    segs = copy(p.segments)
    cseg = CompoundSegment(segs)
    csty = CompoundStyle(segs, copy(p.styles))
    empty!(p)
    push!(p, (cseg,csty))
    nothing
end

"""
`straight!(p::Path, l::Real)`

Extend a path `p` straight by length `l` in the current direction.
"""
function straight!{T<:Real}(p::Path{T}, l::Real, sty::Style=laststyle(p))
    origin = lastpoint(p)
    α = lastangle(p)
    s = Straight{T}(l, origin, α)
    push!(p, (s,sty))
    nothing
end

"""
`turn!(p::Path, α::Real, r::Real, sty::Style=laststyle(p))`

Turn a path `p` by angle `α` with a turning radius `r` in the current direction.
Positive angle turns left.
"""
function turn!{T<:Real}(p::Path{T}, α::Real, r::Real, sty::Style=laststyle(p))
    origin = lastpoint(p)
    α0 = lastangle(p)
    turn = Turn{T}(α, r, origin, α0)
    push!(p, (turn,sty))
    nothing
end

"""
`turn!(p::Path, s::ASCIIString, r::Real, sty::Style=laststyle(p))`

Turn a path `p` with direction coded by string `s`:

- "l": turn by π/2 (left)
- "r": turn by -π/2 (right)
- "lrlrllrrll": do those turns in that order
"""
function turn!{T<:Real}(p::Path{T}, s::ASCIIString, r::Real, sty::Style=laststyle(p))
    for ch in s
        if ch == 'l'
            α = π/2
        elseif ch == 'r'
            α = -π/2
        else
            error("Unrecognizable turn command.")
        end
        turn = Turn{T}(α, r, lastpoint(p), lastangle(p))
        push!(p, (turn,sty))
    end
    nothing
end

"""
`meander!{T<:Real}(p::Path{T}, len, r, straightlen, α::Real)`

Alternate between going straight with length `straightlen` and turning
with radius `r` and angle `α`. Each turn goes the opposite direction of the
previous. The total length is `len`. Useful for making resonators.

The straight and turn segments are combined into a `CompoundSegment` and
appended to the path `p`.
"""
function meander!{T<:Real}(p::Path{T}, len, r, straightlen, α::Real)
    ratio = len/(straightlen+r*α)
    nsegs = Int(ceil(ratio))

    p′ = Path{T}(laststyle(p))
    for pm in take(cycle([1.0,-1.0]), nsegs)
        straight!(p′, straightlen)
        turn!(p′, pm*α, r)     # alternates left and right
    end
    simplify!(p′)

    fn = p′.segments[1].f
    p′.segments[1].f = t->fn(t*ratio/ceil(ratio))
    append!(p, p′)
    nothing
end

"""
`launch!(p::Path; extround=5, trace0=300, trace1=5,
        gap0=150, gap1=2.5, flatlen=250, taperlen=250)`

Add a launcher to the path. Somewhat intelligent in that the launcher will
reverse its orientation depending on if it is at the start or the end of a path.

There are numerous keyword arguments to control the behavior:

- `extround`: Rounding radius of the outermost corners; should be less than `gap0`.
- `trace0`: Bond pad width.
- `trace1`: Center trace width of next CPW segment.
- `gap0`: Gap width adjacent to bond pad.
- `gap1`: Gap width of next CPW segment.
- `flatlen`: Bond pad length.
- `taperlen`: Length of taper region between bond pad and next CPW segment.

Returns a `Style` object suitable for continuity with the next segment.
Ignore the returned style if you are terminating a path.
"""
function launch!(p::Path; extround=5, trace0=300, trace1=5,
        gap0=150, gap1=2.5, flatlen=250, taperlen=250)
    flip = f::Function->(isempty(p) ? f : t->f(1.0-t))
    # if isempty(p)
    #     flip(f::Function) = f
    # else
    #     flip(f::Function) = t->f(1.0-t)
    # end

    s0 = CPW(0.0, flip(t->(trace0/2+gap0-extround+
        sqrt(extround^2-(t*extround-extround)^2))))
    s1 = CPW(0.0, trace0/2+gap0)
    s2 = CPW(trace0, gap0)
    s3 = CPW(flip(t->(trace0 + t * (trace1 - trace0))),
        flip(t->(gap0 + t * (gap1 - gap0))),1)

    if isempty(p)
        args = [extround, gap0-extround, flatlen, taperlen]
        styles = Style[s0, s1, s2, s3]
    else
        args = [taperlen, flatlen, gap0-extround, extround]
        styles = Style[s3, s2, s1, s0]
    end

    for x in zip(args,styles)
        straight!(p, x...)
    end

    # Return a style suitable for the next segment.
    CPW(trace1, gap1)
end

"""
`param{T<:Real}(c::CompoundSegment{T})`

Return a parametric function over the domain [0,1] that represents the
compound segment.
"""
function param{T<:Real}(c::CompoundSegment{T})
    isempty(c.segments) && error("Cannot parameterize with zero segments.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength(($c).segments)
        l0 = zero($T)
    end)

    for i in 1:length(c.segments)
        push!(f.args[2].args, quote
            fn = (($c).segments)[$i].f
            l1 = l0 + length((($c).segments)[$i])
            (l0/L <= t < l1/L) && return (fn)((t*L-l0)/(l1-l0))
            l0 = l1
        end)
    end

    # For continuity of the derivative
    push!(f.args[2].args, quote
        g = (($c).segments)[1].f
        h = (($c).segments)[end].f
        g′ = gradient(g,0.0)
        h′ = gradient(h,1.0)
        D0x, D0y = getx(g′), gety(g′)
        D1x, D1y = getx(h′), gety(h′)
        a0,a = origin((($c).segments)[1]),lastpoint((($c).segments)[end])
        l0,l1 = length((($c).segments)[1]), length((($c).segments)[end])
        (t >= 1.0) &&
            return a + Point(D1x*(t-1)*(L/l1), D1y*(t-1)*(L/l1))
        (t < 0.0) &&
            return a0 + Point(D0x*t*(L/l0), D0y*t*(L/l0))
    end)

    # Return our parametric function
    return eval(f)
end

# """
# `preview(p::Path, pts::Integer=100; kw...)`
#
# Plot the path using `Plots.jl`, enforcing square aspect ratio of the x and y limits.
# If using the UnicodePlots backend, pass keyword argument `size=(60,30)`
# or a similar ratio for display with proper aspect ratio.
#
# No styling of the path is shown, only the abstract path in the plane. A launcher
# will look no different than a straight line, for instance.
#
# We reserve `xlims` and `ylims` keyword arguments but all other valid Plots.jl
# keyword arguments are passed along to the plotting function.
# """
# function preview(p::Path, pts::Integer=100; kw...)
#     d = 0:(1/(pts-1)):1
#     f = param(p)
#     fx(t) = getx(f(t))
#     fy(t) = gety(f(t))
#     xv,yv = map(fx,d), map(fy,d)
#     xmin, xmax = minimum(xv), maximum(xv)
#     ymin, ymax = minimum(yv), maximum(yv)
#     xrange = xmax-xmin
#     yrange = ymax-ymin
#     if xrange == yrange
#         Plots.plot(map(fx,d), map(fy,d), xlims=[xmin,xmax], ylims=[ymin,ymax]; kw...)
#     elseif xrange < yrange
#         ɛ = (yrange-xrange)/2
#         Plots.plot(map(fx,d), map(fy,d), xlims=[xmin-ɛ,xmax+ɛ], ylims=[ymin,ymax]; kw...)
#     else
#         ɛ = (xrange-yrange)/2
#         Plots.plot(map(fx,d), map(fy,d), xlims=[xmin,xmax], ylims=[ymin-ɛ,ymax+ɛ]; kw...)
#     end
# end

# """
# Attach a cell `name` along a path `p` rendered with style `s` at location
# `t` ∈ [0,1]. The `direction` is 1,0,-1 (left, center, or right of path,
# respectively). If 0, the center of the cell will be centered on the path, with
# the top of the cell tangent to the path direction (and leading the bottom).
# Otherwise, the top of the cell will be rotated closest to the path edge.
# A tangential `offset` may be given to move the cell with +x
# being the direction to the right of the path.
# """
# function attach!(name::AbstractString, p::Path, idx::Int, t::Real,
#         direction::Integer, offset::Real)
#
#
# end

"""
`render(p::Path; name="main", layer::Int=0, datatype::Int=0)`

Render a path `p`.
Keyword arguments give a cell `name`, along with `layer` and `datatype`.
"""
function render(p::Path; name="main", layer::Int=0, datatype::Int=0)
    for (segment, s) in p
        render(segment, s, name, layer, datatype)
    end
end

"""
`render(segment::Segment, s::Style, name, layer, datatype)`

Render a `segment` with style `s`.
"""
function render(segment::Segment, s::Style, name, layer, datatype)
    c = cell(name)
    f = segment.f
    g(t) = gradient(f,t)
    last = 0.0
    first = true
    gp = gdspy()[:Path](width(s, 0.0), Point(0.0,0.0),
        number_of_paths=paths(s, 0.0), distance=distance(s, 0.0))
    for t in divs(s)
        if first
            first = false
            continue
        end
        gp[:parametric](x->f(last+x*(t-last)),
            curve_derivative=x->g(last+x*(t-last)),
            final_width=width(s,t),
            final_distance=distance(s,t),
            layer=layer, datatype=datatype)
        c[:add](gp)
        gp = gdspy()[:Path](width(s,t), Point(0.0,0.0),
            number_of_paths=paths(s,t), distance=distance(s,t))
        last = t
    end
end

"""
`render(segment::Segment, s::DecoratedStyle, name, layer, datatype)`

Render a `segment` with `DecoratedStyle` `s`. This method draws the decorations
before the path itself is drawn.
"""
function render(segment::Segment, s::DecoratedStyle, name, layer, datatype)
    for (t, offset, dir, c) in zip(s.ts, s.offsets, s.dirs, s.cells)
        (dir < -1 || dir > 1) && error("Invalid direction in $s.")

        ((x1,y1),(x2,y2)) = bounds(c)
        dtop = max(y1,y2) - (y1+y2)/2       # distance from center to top

        ∠0 = direction(segment.f, t)
        newcell = cell(name)
        if dir == 0
            ∠ = ∠0-π/2
            newx = offset*cos(∠)
            newy = offset*sin(∠)
            ref = gdspy()[:CellReference](cell(c),
                origin=(segment.f(t) + Point(newx,newy)),
                rotation=∠*180/π)
        else
            ∠ = ∠0-π/2
            offset -= dir * extent(s.s, t)
            offset -= dir * dtop
            newx = offset * cos(∠)
            newy = offset * sin(∠)
            rot = (∠0 + (dir == 1 ? π:0)) * 180/π
            ref = gdspy()[:CellReference](cell(c),
                origin=(segment.f(t)+Point(newx,newy)),
                rotation=rot)
        end
        newcell[:add](ref)
    end
    render(segment, s.s, name, layer, datatype)
end

end
