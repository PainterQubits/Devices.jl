module Paths

using ..Points
using ..Cells
using Unitful
using Unitful: Length, DimensionError, °

import Base:
    convert,
    copy,
    deepcopy_internal,
    start,
    done,
    next,
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
    show,
    summary,
    dims2string

import Compat.String
using ForwardDiff
import Devices
import Devices: bounds, cell, Coordinate
gdspy() = Devices._gdspy

export Path

export CPW
export Trace

export α0, α1, p0, p1, style0, style1
export adjust!
export attach!
export corner!
export direction
export launch!
export meander!
export param
export pathf
export pathlength
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
    z = zero(getx(p(0)))
    f′ = ForwardDiff.derivative(p, t)
    fx′,fy′ = getx(f′),gety(f′)
    if !(fx′ ≈ z)
        atan(fy′/fx′)
    else
        if fy′ > z
            π/2
        elseif fy′ < z
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
abstract Style{T<:Coordinate}

"""
```
abstract Segment{T<:Coordinate}
```

Path segment in the plane. All Segment objects should have the implement
the following methods:

- `pathlength`
- `p0`
- `α0`
- `setp0!`
- `setα0!`
- `α1`
"""
abstract Segment{T<:Coordinate}

# doubly linked-list behavior
type Node{T<:Coordinate}
    seg::Segment{T}
    sty::Style{T}
    prev::Node{T}
    next::Node{T}

    Node(a,b) = begin
        n = new(a,b)
        n.prev = n
        n.next = n
    end
    Node(a,b,c,d) = new(a,b,c,d)
end
Node{T}(a::Segment{T}, b::Style) = Node{T}(a,b)

previous(x::Node) = x.prev
next(x::Node) = x.next

segment(x::Node) = x.seg
style(x::Node) = x.sty
setsegment!(x::Node, s::Segment) = x.seg = s
setstyle!(x::Node, s::Style) = x.sty = s

include("styles.jl")
include("segments.jl")

"""
```
type Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::Float64
    style0::Style
    nodes::Array{Node{T},1}
end
```

Type for abstracting an arbitrary styled path in the plane. Iterating returns
tuples of (`segment`, `style`).
"""
type Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::typeof(0.0°)
    style0::Style{T}
    nodes::Array{Node{T},1}

    Path() = new(Point(zero(T),zero(T)), 0.0°, Trace(T(1)), Node{T}[])
    Path(a,b,c,d) = new(a,b,c,d)
end

nodes(p::Path) = p.nodes

dims2string(p::Path) = isempty(p) ? "0-dimensional" :
                 length(p) == 1 ? "$(d[1])-segment" :
                 join(map(string,d), '×')

summary(p::Path) = string(dims2string(size(p)), " ", typeof(p)) *
    " from $(p.p0) with ∠$(p.α0)"

pathf(p) = segment(p[1]).f

function show(io::IO, x::Node)
    print(io, "$(segment(x)) styled as $(style(x))")
end

"""
```
Path{T<:Coordinate}(p0::Point{T}=Point(0.0,0.0); α0=0.0, style0::Style=Trace(1.0))
```

Convenience constructor for `Path{T}` object.
"""
function Path{T<:Coordinate}(p0::Point{T}=Point(0.0,0.0);
    α0=0.0, style0::Style=Trace(T(1)))
    Path{T}(p0, α0, style0, Node{T}[])
end

"""
```
pathlength(p::Path)
```

Physical length of a path. Note that `length` will return the number of
segments in a path, not the physical length of the path.
"""
pathlength(p::Path) = pathlength(nodes(p))

"""
```
pathlength(p::AbstractArray)
```

Total physical length of segments.
"""
pathlength{T}(array::AbstractArray{Node{T}}) =
    mapreduce(pathlength, +, zero(T), array)
pathlength{T}(array::AbstractArray{Segment{T}}) =
    mapreduce(pathlength, +, zero(T), array)

pathlength(node::Node) = pathlength(segment(node))

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
        α0(segment(nodes(p)[1]))
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
        α1(segment(nodes(p)[end]))
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
        p0(segment(nodes(p)[1]))
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
        p1(segment(nodes(p)[end]))
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
        style(nodes(p)[1])
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
        style(nodes(p)[end])
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

    function updatell!(p::Path, m::Integer)
        if m == 1
            seg = segment(nodes(p)[1])
            nodes(p)[1].prev = nodes(p)[1]
            if length(p) == 1
                nodes(p)[1].next = nodes(p)[1]
            end
        else
            nodes(p)[m-1].next = nodes(p)[m]
            nodes(p)[m].prev = nodes(p)[m-1]
            if m == length(p)
                nodes(p)[m].next = nodes(p)[m]
            end
        end
    end

    function updatefields!(n::Node)
        seg = segment(n)
        if isa(seg, Corner)
            seg.extent = extent(style(previous(n)), 1.0)
        end
    end

    function updateα0p0!(n::Node; α0=0, p0=Point(0,0))
        if previous(n) == n # first node
            setα0p0!(segment(n), α0, p0)
        else
            seg = segment(n)
            seg0 = segment(previous(n))
            setα0p0!(seg, α1(seg0), p1(seg0))
        end
    end

    for j in 1:length(p)
        updatell!(p,j)
        updatefields!(p[j])
        updateα0p0!(p[j]; α0=p.α0, p0=p.p0)
    end
end

# Methods for Path as AbstractArray
length(p::Path) = length(nodes(p))
start(p::Path) = start(nodes(p))
done(p::Path, state) = done(nodes(p), state)
next(p::Path, state) = next(nodes(p), state)
enumerate(p::Path) = enumerate(nodes(p))
rest(p::Path, state) = rest(nodes(p), state)
take(p::Path, n::Int) = take(nodes(p), n)
drop(p::Path, n::Int) = drop(nodes(p), n)
cycle(p::Path) = cycle(nodes(p))
isempty(p::Path) = isempty(nodes(p))
empty!(p::Path) = empty!(nodes(p))
function deleteat!(p::Path, inds)
    deleteat!(nodes(p), inds)
    adjust!(p, first(inds))
end
endof(p::Path) = length(nodes(p))
size(p::Path) = size(nodes(p))
getindex(p::Path, i::Integer) = nodes(p)[i]
function setindex!(p::Path, v::Node, i::Integer)
    nodes(p)[i] = v
    adjust!(p, i)
end

function setindex!(p::Path, v::Segment, i::Integer)
    setsegment!(nodes(p)[i],v)
    adjust!(p, i)
end

function setindex!(p::Path, v::Style, i::Integer)
    setstyle!(nodes(p)[i],v)
    adjust!(p, i)
end

function push!(p::Path, node::Node)
    push!(nodes(p), node)
    adjust!(p, length(p))
end

function unshift!(p::Path, node::Node)
    unshift!(nodes(p), node)
    adjust!(p)
end

for x in (:push!, :unshift!)
    @eval function ($x)(p::Path, seg::Segment, sty::Style)
        ($x)(p, Node(seg,sty))
    end
    @eval function ($x)(p::Path, segsty0::Node, segsty::Node...)
        ($x)(p, segsty0)
        for x in segsty
            ($x)(p, x)
        end
    end
end

function pop!(p::Path)
    x = pop!(nodes(p))
    adjust!(p, length(p))
    x
end

function shift!(p::Path)
    x = shift!(nodes(p))
    adjust!(p)
    x
end

function insert!(p::Path, i::Integer, segsty::Node)
    insert!(nodes(p), i, segsty)
    adjust!(p, i)
end

insert!(p::Path, i::Integer, seg::Segment, sty::Style) =
    insert!(p, i, Node(seg,sty))

function insert!(p::Path, i::Integer, seg::Segment)
    if i == 1
        sty = style0(p)
    else
        sty = style(nodes(p)[i-1])
    end
    insert!(p, i, Node(seg,sty))
end

function insert!(p::Path, i::Integer, segsty0::Node, segsty::Node...)
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
    append!(nodes(p), nodes(p′))
    adjust!(p, i+1)
    nothing
end

"""
```
simplify(p::Path, inds::UnitRange=1:length(p))
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
function simplify(p::Path, inds::UnitRange=1:length(p))
    cseg = CompoundSegment(nodes(p)[inds])
    csty = CompoundStyle(cseg.segments, map(style, nodes(p)[inds]))
    Node(cseg, csty)
end

"""
```
simplify!(p::Path, inds::UnitRange=1:length(p))
```

In-place version of [`simplify`](@ref).
"""
function simplify!(p::Path, inds::UnitRange=1:length(p))
    x = simplify(p, inds)
    deleteat!(p, inds)
    insert!(p, inds[1], x)
    p
end

# function split{T<:Real}(s::CompoundSegment{T}, points) # WIP
#     segs = CompoundSegment{T}[]
#     segs
# end

"""
```
straight!{T<:Coordinate}(p::Path{T}, l::Coordinate, sty::Style=style1(p))
```

Extend a path `p` straight by length `l` in the current direction.
"""
function straight!{T<:Coordinate}(p::Path{T}, l::Coordinate, sty::Style=style1(p))
    dimension(T) != dimension(typeof(l)) && throw(DimensionError())
    p0 = p1(p)
    α = α1(p)
    s = Straight{T}(l, p0, α)
    push!(p, Node(s,sty))
    nothing
end

"""
```
turn!{T<:Coordinate}(p::Path{T}, α, r::Coordinate, sty::Style=style1(p))
```

Turn a path `p` by angle `α` with a turning radius `r` in the current direction.
Positive angle turns left.
"""
function turn!{T<:Coordinate}(p::Path{T}, α, r::Coordinate, sty::Style=style1(p))
    dimension(T) != dimension(typeof(r)) && throw(DimensionError())
    p0 = p1(p)
    α0 = α1(p)
    turn = Turn{T}(α, r, p0, α0)
    push!(p, Node(turn,sty))
    nothing
end

"""
```
turn!{T<:Coordinate}(p::Path{T}, s::String, r::Coordinate, sty::Style=style1(p))
```

Turn a path `p` with direction coded by string `s`:

- "l": turn by π/2 radians (left)
- "r": turn by -π/2 radians (right)
- "lrlrllrrll": do those turns in that order
"""
function turn!{T<:Coordinate}(p::Path{T}, s::String, r::Coordinate, sty::Style=style1(p))
    dimension(T) != dimension(typeof(r)) && throw(DimensionError())
    for ch in s
        if ch == 'l'
            α = π/2
        elseif ch == 'r'
            α = -π/2
        else
            error("Unrecognizable turn command.")
        end
        turn = Turn{T}(α, r, p1(p), α1(p))
        push!(p, Node(turn,sty))
    end
    nothing
end

function corner!{T<:Coordinate}(p::Path{T}, α, sty::Style=style1(p))
    corn = Corner{T}(α)
    push!(p, Node(corn,sty))
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
param{T<:Coordinate}(c::AbstractVector{Segment{T}})
```

Return a parametric function over the domain [0,1] that represents the
compound segments.
"""
function param{T<:Coordinate}(c::AbstractVector{Segment{T}})
    isempty(c) && error("Cannot parameterize with zero segments.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength(($c))
        l0 = zero($T)
    end)

    for i in 1:length(c)
        push!(f.args[2].args, quote
            fn = (($c))[$i].f
            l1 = l0 + pathlength((($c))[$i])
            (l0/L <= t < l1/L) && return (fn)((t*L-l0)/(l1-l0))
            l0 = l1
        end)
    end

    # For continuity of the derivative
    push!(f.args[2].args, quote
        g = (($c))[1].f
        h = (($c))[end].f
        g′ = ForwardDiff.derivative(g,0.0)
        h′ = ForwardDiff.derivative(h,1.0)
        D0x, D0y = getx(g′), gety(g′)
        D1x, D1y = getx(h′), gety(h′)
        a0,a = p0((($c))[1]),p1((($c))[end])
        l0,l1 = pathlength((($c))[1]), pathlength((($c))[end])
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
        node = p[i]
        seg0,sty0 = segment(node), style(node)
        sty = decorate(sty0,c,t,where)
        p[i] = Node(seg0,sty)
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
