
"""
```
type Trace <: Style
    width::Function
    divs::Int
end
```

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
copy(x::Trace) = Trace(x.width, x.divs)
divs(s::Trace) = linspace(0.0, 1.0, s.divs+1)

distance(::Trace, t) = 0.0
extent(s::Trace, t) = s.width(t)/2
paths(::Trace, t...) = 1
width(s::Trace, t) = s.width(t)

"""
```
type CPW <: Style
    trace::Function
    gap::Function
    divs::Int
end
```

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
copy(x::CPW) = CPW(x.trace, x.gap, x.divs)

distance(s::CPW, t) = s.gap(t)+s.trace(t)
extent(s::CPW, t) = s.trace(t)/2 + s.gap(t)
paths(::CPW, t...) = 2
width(s::CPW, t) = s.gap(t)
divs(s::CPW) = linspace(0.0, 1.0, s.divs+1)

"""
```
type CompoundStyle{T<:Real} <: Style
    segments::Array{Segment{T},1}
    styles::Array{Style,1}
    f::Function
    CompoundStyle(segments, styles) = begin
        s = new(segments, styles)
        s.f = param(s)
        s
    end
end
```

Combines styles together for use with a `CompoundSegment`.

- `segments`: Needed for divs function.
- `styles`: Array of styles making up the object.
- `f`: returns tuple of style index and the `t` to use for that
style's parametric function.
"""
type CompoundStyle{T<:Real} <: Style
    segments::Array{Segment{T},1}
    styles::Array{Style,1}
    f::Function
    CompoundStyle(segments, styles) = begin
        s = new(segments, styles)
        s.f = param(s)
        s
    end
end
CompoundStyle{T<:Real}(segments::AbstractArray{Segment{T},1},
    styles::AbstractArray{Style,1}) = CompoundStyle{T}(segments, styles)

"""
`divs{T<:Real}(c::CompoundStyle{T})`

Returns a collection with the values of `t` to use for
rendering a `CompoundSegment` with this `CompoundStyle`.
"""
function divs{T<:Real}(c::CompoundStyle{T})
    isempty(c.segments) && error("Cannot use divs with zero segments.")
    length(c.segments) != length(c.styles) &&
        error("Number of segments and styles do not match.")

    L = pathlength(c.segments)
    l0 = zero(T)
    ts = Float64[]
    for i in 1:length(c.segments)
        l1 = l0 + length(c.segments[i])
        # Someone who enjoys thinking about IEEE floating points,
        # please make this less awful. It seems like the loop runs
        # approximately powers-of-2 times.

        # Start just past the boundary to pick the right style
        offset = l0/L + eps(l0/L)

        # Go almost to the next boundary
        scale = (l1/L-offset)
        while offset+scale*1.0 >= l1/L
            scale -= eps(scale)
        end

        append!(ts, divs(c.styles[i])*scale+offset)
        l0 = l1
    end
    sort!(unique(ts))
end

function param{T<:Real}(c::CompoundStyle{T})
    isempty(c.segments) && error("Cannot parameterize with zero segments.")
    length(c.segments) != length(c.styles) &&
        error("Number of segments and styles do not match.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength(($c).segments)
        l0 = zero($T)
    end)

    for i in 1:length(c.segments)
        push!(f.args[2].args, quote
            l1 = l0 + length((($c).segments)[$i])
            (l0/L <= t) &&
                ($(i == length(c.segments) ? :(<=) : :(<))(t, l1/L)) &&
                    return $i, (t*L-l0)/(l1-l0)
            l0 = l1
        end)
    end

    # Return our parametric function
    return eval(f)
end

for x in (:distance, :extent, :paths, :width)
    @eval function ($x)(s::CompoundStyle, t)
        idx, teff = s.f(t)
        ($x)(s.styles[idx], teff)
    end
end

"""
```
type DecoratedStyle <: Style
    s::Style
    ts::AbstractArray{Float64,1}
    dirs::Array{Int,1}
    cellrefs::Array{CellReference,1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.cells = CellReference[]
    end
    DecoratedStyle(s,t,r,c) = new(s,t,r,c)
end
```

Style with decorations, like periodic structures along the path, etc.
"""
type DecoratedStyle <: Style
    s::Style
    ts::AbstractArray{Float64,1}
    dirs::Array{Int,1}
    cellrefs::Array{CellReference,1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.cellrefs = CellReference[]
        a
    end
    DecoratedStyle(s,t,r,c) = new(s,t,r,c)
end

"""
```
undecorated(s::Style)
```

Returns `s`.
"""
undecorated(s::Style) = s

"""
```
undecorated(s::DecoratedStyle)
```

Returns the underlying, undecorated style.
"""
undecorated(s::DecoratedStyle) = s.s

extent(s::DecoratedStyle, t) = extent(undecorated(s), t)
