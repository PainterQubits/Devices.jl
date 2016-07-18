module Paths

using ..Points
using ..Cells

import Base:
    convert,
    copy,
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
    deleteat!,
    length,
    endof,
    size,
    getindex,
    setindex!,
    push!,
    pop!,
    unshift!,
    shift!,
    insert!,
    append!,
    show

using ForwardDiff
# import Plots
import Devices
import Devices: bounds, cell
gdspy() = Devices._gdspy

export Path

export CPW
export Trace

export α0, α1, p0, p1, style0, style1
export adjust!
export attach!
export direction
export launch!
export meander!
export param
export pathf
export pathlength
# export preview
export simplify
export simplify!
export straight!
export turn!
export undecorated

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
```
direction(p::Function, t)
```

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
```
abstract Style
```

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
```
abstract Segment{T<:Real}
```

Path segment in the plane. All Segment objects should have the implement
the following methods:

- `length`
- `p0`
- `α0`
- `setp0!`
- `setα0!`
- `α1`
"""
abstract Segment{T<:Real}

include("Styles.jl")
include("Segments.jl")

"""
```
type Path{T<:Real} <: AbstractArray{Tuple{Segment{T},Style},1}
    p0::Point{2,T}
    α0::Real
    style0::Style
    segments::Array{Segment{T},1}
    styles::Array{Style,1}
end
```

Type for abstracting an arbitrary styled path in the plane. Iterating returns
tuples of (`segment`, `style`).
"""
type Path{T<:Real} <: AbstractArray{Tuple{Segment{T},Style},1}
    p0::Point{2,T}
    α0::Real
    style0::Style
    segments::Array{Segment{T},1}
    styles::Array{Style,1}
end

pathf(p) = p[1][1].f

"""
```
Path{T<:Real}(p0::Point{2,T}=Point(0.0,0.0); α0::Real=0.0, style0::Style=Trace(1.0))
```

Convenience constructor for `Path{T}` object.
"""
Path{T<:Real}(p0::Point{2,T}=Point(0.0,0.0); α0::Real=0.0, style0::Style=Trace(1.0)) =
    Path{T}(p0, α0, style0, Segment{T}[], Style[])

"""
```
pathlength(p::Path)
```

Physical length of a path. Note that `length` will return the number of
segments in a path, not the physical length.
"""
pathlength(p::Path) = pathlength(p.segments)

"""
```
pathlength(p::AbstractArray{Segment})
```

Total physical length of segments.
"""
pathlength{T<:Real}(parr::AbstractArray{Segment{T},1}) = mapreduce(length, +, parr)

"""
```
α0(p::Path)
```

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
```
α1(p::Path)
```

Last angle of a path.
"""
function α1(p::Path)
    if isempty(p)
        p.α0
    else
        α1(p.segments[end])
    end
end

"""
```
p0(p::Path)
```

First point of a path.
"""
function p0(p::Path)
    if isempty(p)
        p.p0
    else
        p0(p.segments[1])
    end
end

"""
```
p1(p::Path)
```

Last point of a path.
"""
function p1(p::Path)
    if isempty(p)
        p.p0
    else
        p1(p.segments[end])
    end
end

"""
```
style0(p::Path)
```

Style of the first segment of a path.
"""
function style0(p::Path)
    if isempty(p)
        p.style0
    else
        p.styles[1]
    end
end

"""
```
style1(p::Path)
```

Style of the last segment of a path.
"""
function style1(p::Path)
    if isempty(p)
        p.style0
    else
        p.styles[end]
    end
end

"""
```
adjust!(p::Path, n::Integer=1)
```

Adjust a path's parametric functions starting from index `n`.
Used internally whenever segments are inserted into the path.
"""
function adjust!(p::Path, n::Integer=1)
    isempty(p) && return
    m = n
    if m == 1
        seg,sty = p[1]
        setα0p0!(seg, p.α0, p.p0)
        m += 1
    end
    for j in m:length(p)
        seg,sty = p[j]
        seg0,sty0 = p[j-1]
        setα0p0!(seg, α1(seg0), p1(seg0))
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
deleteat!(p::Path, inds) = begin deleteat!(p.segments, inds); deleteat!(p.styles, inds) end
endof(p::Path) = length(p.segments)
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

function insert!(p::Path, i::Integer, segsty::Tuple{Segment, Style})
    insert!(p.segments, i, segsty[1])
    insert!(p.styles, i, segsty[2])
end
insert!(p::Path, i::Integer, seg::Segment, sty::Style) = insert!(p, i, (seg,sty))
function insert!(p::Path, i::Integer, segsty0::Tuple{Segment, Style},
        segsty::Tuple{Segment,Style}...)
    insert!(p, i, segsty0)
    for x in segsty
        insert!(p, i, x)
    end
end

"""
```
append!(p::Path, p′::Path)
```

Given paths `p` and `p′`, path `p′` is appended to path `p`.
The p0 and initial angle of the first segment from path `p′` is
modified to match the last point and last angle of path `p`.
"""
function append!(p::Path, p′::Path)
    isempty(p′) && return
    i = length(p)
    lp, la = p1(p), α1(p)
    append!(p.segments, p′.segments)
    append!(p.styles, p′.styles)
    setp0!(p.segments[i+1], lp)
    setα0!(p.segments[i+1], la)
    adjust!(p, i+1)
    nothing
end

"""
```
simplify(p::Path, inds::UnitRange)
```

At `inds`, segments of a path are turned into a `CompoundSegment` and
styles of a path are turned into a `CompoundStyle`. The method returns a tuple,
`(segment, style)`.

- Indexing the path becomes more sane when you can combine several path
segments into one logical element. A launcher would have several indices
in a path unless you could simplify it.
- You don't need to think hard about boundaries between straights and turns
when you want a continuous styling of a very long path.
"""
function simplify(p::Path, inds::UnitRange)
    cseg = CompoundSegment(p.segments[inds])
    csty = CompoundStyle(cseg.segments, p.styles[inds])
    (cseg, csty)
    # deleteat!(p1, inds)
    # insert!(p1, inds[1], (cseg, csty))
    # p1
end

"""
```
simplify(p::Path)
```

All segments and styles of a path are turned into a `CompoundSegment` and
`CompoundStyle`.
"""
simplify(p::Path) = simplify(p, 1:length(p))

"""
```
simplify!(p::Path, inds::UnitRange)
```

In-place version of [`simplify`](@ref).
"""
function simplify!(p::Path, inds::UnitRange)
    x = simplify(p, inds)
    deleteat!(p, inds)
    insert!(p, inds[1], x)
    p
end

"""
```
simplify!(p::Path)
```

In-place version of [`simplify`](@ref).
"""
simplify!(p::Path) = simplify!(p, 1:length(p))

# function split{T<:Real}(s::CompoundSegment{T}, points)
#     segs = CompoundSegment{T}[]
#     segs
# end

"""
```
straight!(p::Path, l::Real)
```

Extend a path `p` straight by length `l` in the current direction.
"""
function straight!{T<:Real}(p::Path{T}, l::Real, sty::Style=style1(p))
    p0 = p1(p)
    α = α1(p)
    s = Straight{T}(l, p0, α)
    push!(p, (s,sty))
    nothing
end

"""
```
turn!(p::Path, α::Real, r::Real, sty::Style=style1(p))
```

Turn a path `p` by angle `α` with a turning radius `r` in the current direction.
Positive angle turns left.
"""
function turn!{T<:Real}(p::Path{T}, α::Real, r::Real, sty::Style=style1(p))
    p0 = p1(p)
    α0 = α1(p)
    turn = Turn{T}(α, r, p0, α0)
    push!(p, (turn,sty))
    nothing
end

"""
```
turn!(p::Path, s::ASCIIString, r::Real, sty::Style=style1(p))
```

Turn a path `p` with direction coded by string `s`:

- "l": turn by π/2 (left)
- "r": turn by -π/2 (right)
- "lrlrllrrll": do those turns in that order
"""
function turn!{T<:Real}(p::Path{T}, s::ASCIIString, r::Real, sty::Style=style1(p))
    for ch in s
        if ch == 'l'
            α = π/2
        elseif ch == 'r'
            α = -π/2
        else
            error("Unrecognizable turn command.")
        end
        turn = Turn{T}(α, r, p1(p), α1(p))
        push!(p, (turn,sty))
    end
    nothing
end

"""
```
meander!{T<:Real}(p::Path{T}, len, r, straightlen, α::Real)
```

Alternate between going straight with length `straightlen` and turning
with radius `r` and angle `α`. Each turn goes the opposite direction of the
previous. The total length is `len`. Useful for making resonators.

The straight and turn segments are combined into a `CompoundSegment` and
appended to the path `p`.
"""
function meander!{T<:Real}(p::Path{T}, len, r, straightlen, α::Real)
    ratio = len/(straightlen+r*α)
    nsegs = Int(ceil(ratio))

    p′ = Path{T}(style1(p))
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
```
param{T<:Real}(c::CompoundSegment{T})
```

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
        a0,a = p0((($c).segments)[1]),p1((($c).segments)[end])
        l0,l1 = length((($c).segments)[1]), length((($c).segments)[end])
        (t >= 1.0) &&
            return a + Point(D1x*(t-1)*(L/l1), D1y*(t-1)*(L/l1))
        (t < 0.0) &&
            return a0 + Point(D0x*t*(L/l0), D0y*t*(L/l0))
    end)

    # Return our parametric function
    return eval(f)
end

"""
```
attach!(p::Path, c::CellReference, t::Real; i::Integer=length(p), where::Integer=0)
```

Attach `c` along a path.

By default, the attachment occurs at `t ∈ [0,1]` along the most recent path
segment, but a different path segment index can be specified using `i`. The
reference is oriented with zero rotation if the path is pointing at 0°,
otherwise it is rotated with the path.

The origin of the cell reference tells the method where to place the cell *with
respect to a coordinate system that rotates with the path*. Suppose the path is
a straight line with angle 0°. Then an origin of `Point(0.,10.)` will put the
cell at 10 above the path, or 10 to the left of the path if it turns left by
90°.

The `where` option is for convenience. If `where == 0`, nothing special happens.
If `where == -1`, then the point of attachment for the reference is on the
leftmost edge of the waveguide (the rendered polygons; the path itself has no
width). Likewise if `where == 1`, the point of attachment is on the rightmost
edge. This option does not automatically rotate the cell reference, apart from
what is already done as described in the first paragraph. You can think of this
option as setting a special origin for the coordinate system that rotates with
the path. For instance, an origin for the cell reference of `Point(0.,10.)`
together with `where == -1` will put the cell at 10 above the edge of a
rendered (finite width) path with angle 0°.
"""
function attach!(p::Path, c::CellReference, t::Real;
        i::Integer=length(p), where::Integer=0)
    if i==0
        sty0 = style0(p)
        sty = decorate(sty0,c,t,where)
        p.style0 = sty
    else
        seg0,sty0 = p[i]
        sty = decorate(sty0,c,t,where)
        p[i] = (seg0,sty)
    end
end

# undocumented private methods for attach!
function decorate(sty0::Style, c, t, where)
    sty = DecoratedStyle(sty0)
    decorate(sty,c,t,where)
end

# undocumented private methods for attach!
function decorate(sty::DecoratedStyle, c, t, where)
    push!(sty.ts, t)
    push!(sty.dirs, where)
    push!(sty.refs, c)
    sty
end

end
