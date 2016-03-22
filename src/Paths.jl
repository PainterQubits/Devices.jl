module Paths

using ForwardDiff
import Devices: gdspy
import Devices: cell, render

export Path

export CPW
export Trace

export aim
export param
export preview
export straight
export turn

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

"Unstyled path. Can describe any path in the plane."
type Path
    length::Array{Float64,1}
    lastpt::Array{Tuple{Float64,Float64},1}
    angle::Array{Float64,1}
    exprs::Array
end
Path{S<:Real,T<:Real}(start::Tuple{S,T}=(0.0,0.0), angle::Real=0.0) =
    Path([0.0], Tuple{Float64,Float64}[start], [angle], Expr[])

"How to draw along the path."
abstract Style

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
end
CPW(trace::Real, gap::Real) = CPW(x->float(trace), x->float(gap))
CPW(trace::Function, gap::Real) = CPW(trace, x->float(gap))
CPW(trace::Real, gap::Function) = CPW(x->float(trace), gap)

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
end
Trace(width::Real) = Trace(x->float(width))

distance(::Trace, t) = 0.0
extent(s::Trace, t) = s.width(t)/2
paths(::Trace) = 1
width(s::Trace, t) = s.width(t)

"Aim the path in a different direction."
aim(p::Path, α::Real) = begin p.angle = α end

"Overall length of a path."
length(p::Path) = p.length[end]

"Extend a path `p` straight by length `l` in the current direction."
function straight(p::Path, l::Real)
    a,b = p.lastpt[end]
    L = p.length[end]
    α = p.angle[end]
    push!(p.exprs, quote
        ($L/c <= x < ($L+$l)/c) &&
            return [$a+(x*c-$L)*cos($α),$b+(x*c-$L)*sin($α)]
    end)
    a += l*cos(α)
    b += l*sin(α)
    push!(p.lastpt, (a,b))
    push!(p.length, L+l)
end

"Turn a path `p` by angle `α` with a turning radius `r`. Positive angle turns left."
function turn(p::Path, α::Real, r::Real)
    a,b = p.lastpt[end]
    L = p.length[end]
    α0 = p.angle[end]
    l = r*α
    α = float(α)

    # Figure out center of curve.
    c,d = a+r*cos(α0+sign(α)*π/2), b+r*sin(α0+sign(α)*π/2)

    push!(p.exprs, quote
        ($L/c <= x < ($L+$l)/c) &&
            return [$c+$r*cos($α0-π/2+$α*(x*c-$L)/($l)),
                        $d+$r*sin($α0-π/2+$α*(x*c-$L)/($l))]
    end)

    push!(p.lastpt, (c+r*cos(α0-π/2+α), d+r*sin(α0-π/2+α)))
    push!(p.angle, α0+α)
    push!(p.length, L+l)
end

"Return a parametric function over the domain [0,1] that represents a path."
function param(p::Path)

    expr = Expr(:block)
    L = p.length[end]

    # Define the overall scale
    push!(expr.args, :(c=$L))

    # Build up our piecewise parameteric function
    for x = p.exprs
        push!(expr.args, x)
    end

    # For continuity of the derivative.
    a0,b0 = p.lastpt[1]
    a,b = p.lastpt[end]
    α0 = p.angle[1]
    α = p.angle[end]
    push!(expr.args, quote
        (x >= 1) &&
            return [$a+(x*c-$L)*cos($α), $b+(x*c-$L)*sin($α)]
        (x < 0) &&
            return [$a0+(x*c)*cos($α0), $b0+(x*c)*sin($α0)]
    end)

    # Return our parametric function
    return eval(:(x->$expr))
end

"Plot the path."
function preview(p::Path, pts::Integer)
    s = 1/(pts-1)
    d = 0:s:1
    f = param(p)
    fx(t) = f(t)[1]
    fy(t) = f(t)[2]
    PyPlot.plot(map(fx,d), map(fy,d))
end


"""
Render a path `p` with style `s` to the cell with name `name`.
Keyword arguments give a `layer` and `datatype` (default to 0),
a `start` and `stop` point in range [0,1] to draw only part of the path,
as well as number of `segments` (defaults to 100).
"""
function render(p::Path, s::Style, name="main"; layer::Real=0, datatype::Real=0,
        start=0.0, stop=1.0, segments=100)
    stop <= start && error("Check start and stop arguments.")
    f = param(p)
    fx(t) = f(t)[1]
    fy(t) = f(t)[2]
    g(t) = (derivative(fx,t), derivative(fy,t))
    last = start
    first = true
    c = cell(name)
    gp = gdspy.Path(width(s,start), (0.0,0.0), number_of_paths=paths(s),
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
        gp = gdspy.Path(width(s,t), (0.0,0.0), number_of_paths=paths(s),
            distance=distance(s,t))
        last = t
    end
end

end
