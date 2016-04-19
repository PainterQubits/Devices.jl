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
    size

using ForwardDiff
import Plots
import Devices: gdspy
import Devices: cell, render

export Path

export CPW
export Trace

export aim
export param
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

function direction(p::Function, t)
    fx(t) = p(t)[1]
    fy(t) = p(t)[2]
    fx′ = derivative(fx, t)
    fy′ = derivative(fy, t)
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

"How to draw along the path."
abstract Style

divs(s::Style) = s.divs

"""
Two adjacent traces to form a coplanar waveguide.

- `trace`: center conductor width
- `gap`: distance between center conductor edges and ground plane

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
Single trace.

- `width`: trace width
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

"Segment of a path."
abstract Segment{T<:AbstractFloat}
"First point of a segment."
firstpoint{T}(s::Segment{T}) = s.f(0.0)::Point{T}
"Last point of a segment."
lastpoint{T}(s::Segment{T}) = s.f(1.0)::Point{T}

"Straight segment."
immutable Straight{T<:AbstractFloat} <: Segment{T}
    f::Function
    length::T
    angle::Real
end
Straight{T<:AbstractFloat}(f::Function, l::T) =
    Straight{T}(f, l, direction(f, 1.0))

length(s::Straight) = s.length
firstangle(s::Straight) = s.angle
lastangle(s::Straight) = s.angle

"Circular turn."
immutable Turn{T<:AbstractFloat} <: Segment{T}
    f::Function
    length::T
    firstangle::Real
    lastangle::Real
end
Turn{T<:AbstractFloat}(f::Function, l::T) =
    Turn{T}(f, l, direction(f, 0.0), direction(f, 1.0))

length(s::Turn) = s.length
firstangle(s::Turn) = s.firstangle
lastangle(s::Turn) = s.lastangle

"Unstyled path. Can describe any path in the plane."
type Path{T<:AbstractFloat} <: AbstractArray{Segment{T},1}
    firstpt::Point{T}
    firstangle::Real
    segments::Array{Segment{T},1}
end
Path{T<:AbstractFloat}(start::Point{T}=Point(0.0,0.0), angle::Real=0.0) =
    Path{T}(start, angle, Segment{T}[])
Path{T<:Real}(start::Tuple{T,T}) =
    Path(Point(float(start[1]),float(start[2])))
Path{T<:Real}(start::Tuple{T,T}, angle::Real) =
    Path(Point(float(start[1]),float(start[2])), angle)

"Physical length of a path."
pathlength(p::Path) = mapreduce(length, +, p.segments)
length(p::Path) = length(p.segments)
start(p::Path) = start(p.segments)
done(p::Path, state) = done(p.segments, state)
next(p::Path, state) = next(p.segments, state)
zip(paths::Path...) = zip(map(x->x.segments, paths))
enumerate(p::Path) = enumerate(p.segments)
rest(p::Path, state) = rest(p.segments, state)
take(p::Path, n) = take(p.segments, n)
drop(p::Path, n) = drop(p.segments, n)
cycle(p::Path) = cycle(p.segments)
isempty(p::Path) = isempty(p.segments)
empty!(p::Path) = empty!(p.segments)
length(p::Path) = length(p.segments)
endof(p::Path) = endof(p.segments)
size(p::Path) = size(p.segments)

function firstangle(p::Path)
    if length(p) == 0
        p.firstangle
    else
        firstangle(p.segments[1])
    end
end

function lastangle(p::Path)
    if length(p) == 0
        p.firstangle
    else
        lastangle(p.segments[end])
    end
end

function firstpoint(p::Path)
    if length(p) == 0
        p.firstpt
    else
        firstpoint(p.segments[1])
    end
end

function lastpoint(p::Path)
    if length(p) == 0
        p.firstpt
    else
        lastpoint(p.segments[end])
    end
end

"""
`straight!(p::Path, l::Real)`

Extend a path `p` straight by length `l` in the current direction, at unit
velocity. Uses a parametric function over the domain [0,l]:
`t->[a+t*cos(α),b+t*sin(α)]` where `(a,b)` is the previous point.
"""
function straight!(p::Path, l::Real)
    a,b = lastpoint(p)
    α = lastangle(p)
    s = Straight(t->Point(a+t*l*cos(α),b+t*l*sin(α)), float(l), α)
    push!(p.segments, s)
end

"""
`turn!(p::Path, α::Real, r::Real)`

Turn a path `p` by angle `α` with a turning radius `r` at unit velocity in the
path direction. Positive angle turns left.

`t->[c+r*cos(α0-π/2+α*t), d+r*sin(α0-π/2+α*t)]` where `α0` and `α0+α` are the
starting and ending angles (radians) and `(c,d)` is the center of the curve:

`c,d = a+r*cos(α0+sign(α)*π/2), b+r*sin(α0+sign(α)*π/2)`

"""
function turn!(p::Path, α::Real, r::Real)
    a,b = lastpoint(p)
    α0 = lastangle(p)
    α = float(α)
    l = r*α

    # Figure out center of curve.
    c,d = a+r*cos(α0+sign(α)*π/2), b+r*sin(α0+sign(α)*π/2)

    turn = Turn(t->Point(c+r*cos(α0-π/2+α*t), d+r*sin(α0-π/2+α*t)), l, α0, α0+α)
    push!(p.segments, turn)
end

function launch!(p::Path; extround=5, trace0=300, trace1=5, gap0=150, gap1=2.5, flatlen=250, taperlen=250)

    if length(p) == 0
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

    if length(p) == 0
        args = [extround, gap0-extround, flatlen, taperlen]
        styles = Style[s0, s1, s2, s3]
    else
        args = [taperlen, flatlen, gap0-extround, extround]
        styles = Style[s3, s2, s1, s0]
    end

    for x in args
        straight!(p, x)
    end

    styles
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

    gx(t) = getx(g(t))
    gy(t) = gety(g(t))
    hx(t) = getx(h(t))
    hy(t) = gety(h(t))
    D0x, D0y = derivative(gx,0.0), derivative(gy,0.0)
    D1x, D1y = derivative(hx,1.0), derivative(hy,1.0)

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
If using the UnicodePlots backend, pass size=(60,30) for a nice display.

We use `xlims` and `ylims` keyword arguments in this function but all other valid
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
Render a path `p` with style `s` to the cell with name `name`.
Keyword arguments give a `layer` and `datatype` (default to 0),
a `start` and `stop` point in range [0,1] to draw only part of the path,
as well as number of `segments` (defaults to 100).
"""
function render(p::Path, s::Style; name="main", layer::Real=0, datatype::Real=0,
        start=0.0, stop=1.0, segments=100)
    stop <= start && error("Check start and stop arguments.")
    f = param(p)
    g(t) = gradient(f,t)
    last = start
    first = true
    c = cell(name)
    gp = gdspy.Path(width(s,start), Point(0.0,0.0), number_of_paths=paths(s),
        distance=distance(s,start))
    for t in linspace(start,stop,segments+1)
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

function render(p::Path, styles::AbstractArray{Style,1}; name="main", layer::Real=0, datatype::Real=0)

    c = cell(name)
    s1 = styles[1]
    for (segment,s) in zip(p, styles)
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
