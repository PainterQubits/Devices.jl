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

export α0, α1, p0, p1, style0, style1, discretestyle1, contstyle1
export adjust!,
    attach!,
    corner!,
    direction,
    extent,
    launch!,
    meander!,
    next,
    nodes,
    param,
    pathf,
    pathlength,
    previous,
    segment,
    setsegment!,
    simplify,
    simplify!,
    straight!,
    style,
    setstyle!,
    turn!,
    undecorated

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
abstract Style{T<:Coordinate}
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
abstract ContinuousStyle{T} <: Style{T}
```

Any style that applies to segments which have non-zero path length.
"""
abstract ContinuousStyle{T} <: Style{T}

"""
```
abstract DiscreteStyle{T} <: Style{T}
```

Any style that applies to segments which have zero path length.
"""
abstract DiscreteStyle{T} <: Style{T}

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

abstract DiscreteSegment{T} <: Segment{T}
abstract ContinuousSegment{T} <: Segment{T}

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

function deepcopy_internal(x::Style, stackdict::ObjectIdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = copy(x)
    stackdict[x] = y
    return y
end
# # experimental
# import Roots:fzeros
# function divs(f::Function, FType, dens)
#     # find zeros of f′ to locate extrema
#     D = ForwardDiff.derivative
#     extr = fzeros(x->D(f,x), 0.0, 1.0)
#     mi,ma = extrema(f.(extr))
#     normcurv = x->D(x->D(x->(f(x)-mi)/ma,x), x)
#     divs = Float64[]
#     !(extr[1] ≈ 0.0) && unshift!(extr, 0.0)
#     !(extr[end] ≈ 1.0) && push!(extr, 1.0)
#
#     for (i, start) in enumerate(extr[1:(end-1)])
#         push!(divs, start)
#         stop = extr[i+1]
#         where = start
#         while where < stop
#             push!(divs, where += dens/normcurv(where))
#         end
#         start = stop
#     end
#     push!(divs, extr[end])
#     # mm = D2nd.(zeros)
#     # minima = zeros[mm .> 0]
#     # maxima = zeros[mm .< 0]
#
# end

"""
```
p0{T}(s::Segment{T})
```

Return the first point in a segment (calculated).
"""
p0{T}(s::Segment{T}) = s.f(0.0)::Point{T}

"""
```
p1{T}(s::Segment{T})
```

Return the last point in a segment (calculated).
"""
p1{T}(s::Segment{T}) = s.f(1.0)::Point{T}

"""
```
α0(s::Segment)
```

Return the first angle in a segment (calculated).
"""
α0(s::Segment) = direction(s.f, 0.0)

"""
```
α1(s::Segment)
```

Return the last angle in a segment (calculated).
"""
α1(s::Segment) = direction(s.f, 1.0)

function setα0p0!(s::Segment, angle, p::Point)
    setα0!(s, angle)
    setp0!(s, p)
end

"""
```
pathlength{T}(s::Segment{T}, verbose::Bool=false)
```

Return the length of a segment (calculated).
"""
function pathlength{T}(s::Segment{T}, verbose::Bool=false)
    path = s.f
    ds(t) = ustrip(sqrt(dot(ForwardDiff.derivative(s.f, t),
                            ForwardDiff.derivative(s.f, t))))
    val, err = quadgk(ds, 0.0, 1.0)
    verbose && info("Integration estimate: $val")
    verbose && info("Error upper bound estimate: $err")
    val * unit(T)
end

show(io::IO, s::Segment) = print(io, summary(s))

function deepcopy_internal(x::Segment, stackdict::ObjectIdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = copy(x)
    stackdict[x] = y
    return y
end

"""
```
type Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::typeof(0.0°)
    style0::ContinuousStyle{T}
    nodes::Array{Node{T},1}
end
```

Type for abstracting an arbitrary styled path in the plane. Iterating returns
tuples of (`segment`, `style`).
"""
type Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::typeof(0.0°)
    style0::ContinuousStyle{T}
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
style1(p::Path) = style1(p, Style, p.style0)

function style1(p::Path, T, default)
    if isempty(p)
        default
    else
        A = view(nodes(p), reverse(1:length(nodes(p))))
        i = findfirst(x->isa(style(x), T), A)
        if i > 0
            style(A[i])
        else
            default
        end
    end
end

include("contstyles/trace.jl")
include("contstyles/cpw.jl")
include("contstyles/compound.jl")
include("contstyles/decorated.jl")
include("contstyles/norender.jl")
include("discretestyles/simple.jl")
include("skipstyles.jl")

include("segments/straight.jl")
include("segments/turn.jl")
include("segments/corner.jl")
include("segments/compound.jl")

"""
```
discretestyle1{T}(p::Path{T})
```

Returns the last-used discrete style in the path. If one was not used,
returns `SimpleCornerStyle()`.
"""
discretestyle1{T}(p::Path{T}) = style1(p, DiscreteStyle, SimpleCornerStyle{T}())

"""
```
contstyle1(p::Path)
```

Returns the last-used discrete style in the path. If one was not used,
returns `p.style0`.
"""
contstyle1(p::Path) = style1(p, ContinuousStyle, p.style0)

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

    function updateα0p0!{T}(n::Node{T}; α0=0.0°, p0=Point(zero(T),zero(T)))
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
        flip(t->(gap0 + t * (gap1 - gap0)))) # CHANGED

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



end