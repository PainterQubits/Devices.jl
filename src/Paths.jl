module Paths

using ..Points

import Base:
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
    shift!

using ForwardDiff
import Plots
import Devices: gdspy
import Devices: cell, render

export Path

export CPW
export Trace

export adjust!
export param
export pathlength
export preview
export launch!
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

How to render a given path segment.
"""
abstract Style

divs(s::Style) = s.divs

"""
`type CPW <: Style`

Two adjacent traces can form a coplanar waveguide.

- `trace::Function`: center conductor width.
- `gap::Function`: distance between center conductor edges and ground plane
- `divs::Int`: number of segments to render. Increase if you see artifacts.

May need to be inverted with respect to a ground plane,
depending on how the pattern is written.
"""
type CPW <: Style
    trace::Function
    gap::Function
    divs::Int
end
CPW(trace::Real, gap::Real) = CPW(x->float(trace), x->float(gap), 1)
CPW(trace::Function, gap::Function) = CPW(trace, gap, 100)
CPW(trace::Function, gap::Real, divs::Integer=100) = CPW(trace, x->float(gap), divs)
CPW(trace::Real, gap::Function, divs::Integer=100) = CPW(x->float(trace), gap, divs)

distance(s::CPW, t) = s.gap(t)+s.trace(t)
extent(s::CPW, t) = s.trace(t)/2 + s.gap(t)
paths(::CPW) = 2
width(s::CPW, t) = s.gap(t)

"""
`type Trace <: Style`

Simple, single trace.

- `width::Function`: trace width.
- `divs::Int`: number of segments to render. Increase if you see artifacts.
"""
type Trace <: Style
    width::Function
    divs::Int
end
Trace(width::Function) = Trace(width, 100)
Trace(width::Real) = Trace(x->float(width), 1)

distance(::Trace, t) = 0.0
extent(s::Trace, t) = s.width(t)/2
paths(::Trace) = 1
width(s::Trace, t) = s.width(t)

"""
`abstract Segment{T<:Real}`

Path segment in the plane.
"""
abstract Segment{T<:Real}

"""
`firstpoint{T}(s::Segment{T})`

Return the first point in a segment.
"""
firstpoint{T}(s::Segment{T}) = s.f(0.0)::Point{T}

"""
`lastpoint{T}(s::Segment{T})`

Return the last point in a segment.
"""
lastpoint{T}(s::Segment{T}) = s.f(1.0)::Point{T}

"""
`type Straight{T<:Real} <: Segment{T}`

A straight line segment is parameterized by its length.
It begins at a point `origin` with initial angle `α0`.

The parametric function over `t ∈ [0,1]` describing the line segment is given by:

`t -> origin + Point(t*l*cos(α),t*l*sin(α))`
"""
type Straight{T<:Real} <: Segment{T}
    l::T
    origin::Point{T}
    α0::Real
    f::Function
    Straight(l, origin, α0) = begin
        s = new(l, origin, α0)
        s.f = t->(s.origin+Point(t*s.l*cos(s.α0),t*s.l*sin(s.α0)))
        s
    end
end
Straight{T<:Real}(l::Real, origin::Point{T}, α0::Real) =
    Straight{T}(l, origin, α0)

length(s::Straight) = s.l
firstangle(s::Straight) = s.α0
lastangle(s::Straight) = s.α0

"""
`type Turn{T<:Real} <: Segment{T}`

A circular turn is parameterized by the turn angle `α` and turning radius `r`.
It begins at a point `origin` with initial angle `α0`.

The center of the circle is given by:

`cen = origin + Point(r*cos(α0+sign(α)*π/2), r*sin(α0+sign(α)*π/2))`

The parametric function over `t ∈ [0,1]` describing the turn is given by:

`t -> cen + Point(r*cos(α0-π/2+α*t), r*sin(α0-π/2+α*t))`
"""
type Turn{T<:Real} <: Segment{T}
    α::Real
    r::T
    origin::Point{T}
    α0::Real
    f::Function

    Turn(α, r, origin, α0) = begin
        s = new(α, r, origin, α0)
        s.f = t->begin
            cen = s.origin + Point(s.r*cos(s.α0+sign(s.α)*π/2), s.r*sin(s.α0+sign(s.α)*π/2))
            cen + Point(s.r*cos(s.α0-π/2+s.α*t), s.r*sin(s.α0-π/2+s.α*t))
        end
        s
    end
end
Turn{T<:Real}(α::Real, r::Real, origin::Point{T}, α0::Real) =
    Turn{T}(α, r, origin, α0)

length(s::Turn) = s.r*s.α
firstangle(s::Turn) = s.α0
lastangle(s::Turn) = s.α0 + s.α

"Unstyled path. Can describe any path in the plane."
type Path{T<:Real} <: AbstractArray{Segment{T},1}
    origin::Point{T}
    α0::Real
    style0::Style
    segments::Array{Segment{T},1}
    styles::Array{Style,1}
end
Path{T<:Real}(origin::Point{T}=Point(0.0,0.0), α0::Real=0.0, style0::Style=Trace(1.0)) =
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
pathlength(p::Path) = mapreduce(length, +, p.segments)

"""
`firstangle(p::Path)`

First angle of a path.
"""
function firstangle(p::Path)
    if isempty(p)
        p.α0
    else
        firstangle(p.segments[1])
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
`firstpoint(p::Path)`

First point of a path.
"""
function firstpoint(p::Path)
    if isempty(p)
        p.origin
    else
        firstpoint(p.segments[1])
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
`adjust!(p::Path, n::Integer)`

Adjust a path's parametric functions starting from index `n`.
Used internally whenever segments are inserted into the path.
"""
function adjust!(p::Path, n::Integer)
    isempty(p) && return
    m = n
    if m == 1
        seg,sty = p[1]
        seg.origin = p.origin
        seg.α0 = p.α0
        m += 1
    end
    for j in m:length(p)
        seg,sty = p[j]
        seg0,sty0 = p[j-1]
        seg.origin = lastpoint(seg0)
        seg.α0 = lastangle(seg0)
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
`straight!(p::Path, l::Real)`

Extend a path `p` straight by length `l` in the current direction.
"""
function straight!(p::Path, l::Real, sty::Style=laststyle(p))
    origin = lastpoint(p)
    α = lastangle(p)
    s = Straight(l, origin, α)
    push!(p, (s,sty))
end

"""
`turn!(p::Path, α::Real, r::Real, sty::Style=laststyle(p))`

Turn a path `p` by angle `α` with a turning radius `r` at unit velocity in the
path direction. Positive angle turns left.
"""
function turn!(p::Path, α::Real, r::Real, sty::Style=laststyle(p))
    origin = lastpoint(p)
    α0 = lastangle(p)
    turn = Turn(α, r, origin, α0)
    push!(p, (turn,sty))
end

"""
`launch!(p::Path; extround=5, trace0=300, trace1=5,
        gap0=150, gap1=2.5, flatlen=250, taperlen=250)`

Add a launcher to the path. Somewhat intelligent in that the launcher will
reverse it's orientation depending on if it is at the start or the end of a path.

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
    if isempty(p)
        flip(f::Function) = f
    else
        flip(f::Function) = t->f(1.0-t)
    end

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
`param(p::Path)`

Return a parametric function over the domain [0,1] that represents the path.
"""
function param(p::Path)

    if length(p) == 0
        error("Cannot parameterize an empty path.")
    end

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))

    L = pathlength(p)
    l0 = zero(length(p.segments[1]))
    for i in 1:length(p)
        fn = p.segments[i].f
        l1 = l0 + length(p.segments[i])
        push!(f.args[2].args, quote
            ($(l0/L) <= t < $(l1/L)) && return ($fn)((t*$L-$l0)/$(l1-l0))
        end)
        l0 = l1
    end

    # For continuity of the derivative.
    g = p.segments[1].f
    h = p.segments[end].f

    g′ = gradient(g,0.0)
    h′ = gradient(h,1.0)
    D0x, D0y = getx(g′), gety(g′)
    D1x, D1y = getx(h′), gety(h′)

    a0 = firstpoint(p)
    a = lastpoint(p)
    l0,l1 = length(p.segments[1]), length(p.segments[end])
    push!(f.args[2].args, quote
        (t >= 1.0) &&
            return $a+Point($D1x*(t-1)*$(L/l1), $D1y*(t-1)*$(L/l1))
        (t < 0.0) &&
            return $a0+Point($D0x*t*$(L/l0), $D0y*t*$(L/l0))
    end)

    # Return our parametric function
    return eval(f)
end

"""
`preview(p::Path, pts::Integer=100; kw...)`

Plot the path using `Plots.jl`, enforcing square aspect ratio of the x and y limits.
If using the UnicodePlots backend, pass keyword argument `size=(60,30)`
or a similar ratio for display with proper aspect ratio.

No styling of the path is shown, only the abstract path in the plane. A launcher
will look no different than a straight line, for instance.

We reserve `xlims` and `ylims` keyword arguments but all other valid Plots.jl
keyword arguments are passed along to the plotting function.
"""
function preview(p::Path, pts::Integer=100; kw...)
    d = 0:(1/(pts-1)):1
    f = param(p)
    fx(t) = getx(f(t))
    fy(t) = gety(f(t))
    xv,yv = map(fx,d), map(fy,d)
    xmin, xmax = minimum(xv), maximum(xv)
    ymin, ymax = minimum(yv), maximum(yv)
    xrange = xmax-xmin
    yrange = ymax-ymin
    if xrange == yrange
        Plots.plot(map(fx,d), map(fy,d), xlims=[xmin,xmax], ylims=[ymin,ymax]; kw...)
    elseif xrange < yrange
        ɛ = (yrange-xrange)/2
        Plots.plot(map(fx,d), map(fy,d), xlims=[xmin-ɛ,xmax+ɛ], ylims=[ymin,ymax]; kw...)
    else
        ɛ = (xrange-yrange)/2
        Plots.plot(map(fx,d), map(fy,d), xlims=[xmin,xmax], ylims=[ymin-ɛ,ymax+ɛ]; kw...)
    end
end

"""
`render(p::Path; name="main", layer::Int=0, datatype::Int=0)`

Render a path `p`. Keyword arguments give a cell `name`,
along with `layer` and `datatype`.
"""
function render(p::Path; name="main", layer::Int=0, datatype::Int=0)

    c = cell(name)
    for (segment,s) in p
        f = segment.f
        g(t) = gradient(f,t)
        last = 0.0
        first = true
        gp = gdspy.Path(width(s, 0.0), Point(0.0,0.0), number_of_paths=paths(s),
            distance=distance(s, 0.0))
        for t in linspace(0.0,1.0,divs(s)+1)
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
            gp = gdspy.Path(width(s,t), Point(0.0,0.0), number_of_paths=paths(s),
                distance=distance(s,t))
            last = t
        end
    end
end

end
