module Paths
using Compat
using ..Points
using ..Cells
using Unitful
using Unitful: Length, LengthUnits, DimensionError, °
import StaticArrays

import Base:
    convert,
    copy,
    deepcopy_internal,
    start,
    done,
    next,
    enumerate,
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

import Compat.Iterators: rest, take, drop, cycle

using ForwardDiff
import Devices
import Devices: Coordinate, FloatCoordinate, GDSMeta, Meta
import Devices: bounds

export Path

export α0, α1, p0, p1, style0, style1, discretestyle1, contstyle1
export adjust!,
    attach!,
    corner!,
    direction,
    launch!,
    meander!,
    next,
    nodes,
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
    extent(s,t)
For a style `s` and parameteric argument `t`, returns a distance tangential
to the path specifying the lateral extent of the polygons rendered.
"""
function extent end

"""
    width(s,t)
For a style `s` and parameteric argument `t`, returns the width
of paths rendered.
"""
function width end

"""
    abstract type Style end
How to render a given path segment. All styles should implement the following
methods:

 - `extent`
 - `width`
"""
@compat abstract type Style end

"""
    abstract type ContinuousStyle <: Style end
Any style that applies to segments which have non-zero path length.
"""
@compat abstract type ContinuousStyle <: Style end

"""
    abstract type DiscreteStyle <: Style end
Any style that applies to segments which have zero path length.
"""
@compat abstract type DiscreteStyle <: Style end

"""
    abstract type Segment{T<:Coordinate} end
Path segment in the plane. All Segment objects should have the implement
the following methods:

- `pathlength`
- `p0`
- `α0`
- `setp0!`
- `setα0!`
- `α1`
"""
@compat abstract type Segment{T<:Coordinate} end
@inline Base.eltype{T}(::Segment{T}) = T
@inline Base.eltype{T}(::Type{Segment{T}}) = T

Base.zero{T}(::Segment{T}) = zero(T)        # TODO: remove and fix for 0.6 only versions
Base.zero{T}(::Type{Segment{T}}) = zero(T)

"""
    curvature(s, t)
Returns the curvature of a function `t->Point(x(t),y(t))` at `t`. The result will have units
of inverse length if units were used for the segment. The result can be interpreted as the
inverse radius of a circle with the same curvature.
"""
curvature

# Used only to get dispatch to work right with ForwardDiff.jl.
immutable Curv{T} s::T end
(s::Curv)(t) = ForwardDiff.derivative(s.s,t)
curvature(s, t) = ForwardDiff.derivative(Curv(s), t)

@compat abstract type DiscreteSegment{T} <: Segment{T} end
@compat abstract type ContinuousSegment{T} <: Segment{T} end

Base.zero{T}(::Type{ContinuousSegment{T}}) = zero(T)

# doubly linked-list behavior
type Node{T<:Coordinate}
    seg::Segment{T}
    sty::Style
    prev::Node{T}
    next::Node{T}

    (::Type{Node{T}}){T}(a,b) = begin
        n = new{T}(a,b)
        n.prev = n
        n.next = n
    end
    (::Type{Node{T}}){T}(a,b,c,d) = new{T}(a,b,c,d)
end

"""
    Node{T}(a::Segment{T}, b::Style)
Create a node with segment `a` and style `b`.
"""
Node{T}(a::Segment{T}, b::Style) = Node{T}(a,b)
@inline Base.eltype{T}(::Node{T}) = T
@inline Base.eltype{T}(::Type{Node{T}}) = T

"""
    previous(x::Node)
Return the node before `x` in a doubly linked list.
"""
previous(x::Node) = x.prev

"""
    next(x::Node)
Return the node after `x` in a doubly linked list.
"""
next(x::Node) = x.next

"""
    segment(x::Node)
Return the segment associated with node `x`.
"""
segment(x::Node) = x.seg

"""
    style(x::Node)
Return the style associated with node `x`.
"""
style(x::Node) = x.sty

"""
    setsegment!(x::Node, s::Segment)
Set the segment associated with node `x` to `s`.
"""
setsegment!(x::Node, s::Segment) = x.seg = s

"""
    setstyle!(x::Node, s::Style)
Set the style associated with node `x` to `s`.
"""
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
    direction(s, t)
Returns the angle at which some function `t->Point(x(t),y(t))` is pointing.
"""
function direction(s, t)
    f′ = ForwardDiff.derivative(s, t)
    fx′,fy′ = getx(f′),gety(f′)
    angle(Complex(fx′,fy′))
end

"""
    p0{T}(s::Segment{T})
Return the first point in a segment (calculated).
"""
p0{T}(s::Segment{T}) = s(zero(T))::Point{T}

"""
    p1{T}(s::Segment{T})
Return the last point in a segment (calculated).
"""
p1{T}(s::Segment{T}) = s(pathlength(s))::Point{T}

"""
    α0(s::Segment)
Return the first angle in a segment (calculated).
"""
α0{T}(s::Segment{T}) = direction(s, zero(T))

"""
    α1(s::Segment)
Return the last angle in a segment (calculated).
"""
α1(s::Segment) = direction(s, pathlength(s))

function setα0p0!(s::Segment, angle, p::Point)
    setα0!(s, angle)
    setp0!(s, p)
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
    type Path{T<:Coordinate} <: AbstractVector{Node{T}}
        p0::Point{T}
        α0::Float64
        nodes::Array{Node{T},1}
    end
Type for abstracting an arbitrary styled path in the plane. Iterating returns
[`Paths.Node`](@ref) objects, essentially
"""
type Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::Float64
    nodes::Array{Node{T},1}

    (::Type{Path{T}}){T}() = new{T}(Point(zero(T),zero(T)), 0.0, Node{T}[])
    (::Type{Path{T}}){T}(a,b,c) = new{T}(a,b,c)
end
@inline Base.eltype{T}(::Path{T}) = T
@inline Base.eltype{T}(::Type{Path{T}}) = T
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
Path(p0::Point=Point(0.0,0.0); α0=0.0)
Path(p0x::Real, p0y::Real; kwargs...)

Path{T<:Length}(p0::Point{T}; α0=0.0)
Path{T<:Length}(p0x::T, p0y::T; kwargs...)
Path(p0x::Length, p0y::Length; kwargs...)

Path(u::LengthUnits; α0=0.0)
```

Convenience constructors for `Path{T}` object.
"""
function Path(p0::Point=Point(0.0,0.0); α0=0.0)
    Path{Float64}(p0, α0, Node{Float64}[])
end
Path(p0x::Real, p0y::Real; kwargs...) = Path(Point{Float64}(p0x,p0y); kwargs...)

function Path{T<:Length}(p0::Point{T}; α0=0.0)
    Path{typeof(0.0*unit(T))}(p0, α0, Node{typeof(0.0*unit(T))}[])
end
Path{T<:Length}(p0x::T, p0y::T; kwargs...) =
    Path(Point{typeof(0.0*unit(T))}(p0x,p0y); kwargs...)
Path(p0x::Length, p0y::Length; kwargs...) = Path(promote(p0x,p0y)...; kwargs...)

function Path(u::LengthUnits; α0=0.0)
    Path{typeof(0.0u)}(Point(0.0u,0.0u), α0, Node{typeof(0.0u)}[])
end

Path(x::Coordinate, y::Coordinate; kwargs...) = throw(DimensionError(x,y))

"""
    pathlength(p::Path)
    pathlength{T}(array::AbstractArray{Node{T}})
    pathlength{T<:Segment}(array::AbstractArray{T})
    pathlength(node::Node)
Physical length of a path. Note that `length` will return the number of
segments in a path, not the physical length of the path.
"""
function pathlength end

pathlength(p::Path) = pathlength(nodes(p))
pathlength{T}(array::AbstractArray{Node{T}}) =
    mapreduce(pathlength, +, zero(T), array)
pathlength{T<:Segment}(array::AbstractArray{T}) =
    mapreduce(pathlength, +, zero(T), array)
pathlength(node::Node) = pathlength(segment(node))

"""
    α0(p::Path)
First angle of a path.
"""
function α0(p::Path)
    isempty(p) && return p.α0
    α0(segment(nodes(p)[1]))
end

"""
    α1(p::Path)
Last angle of a path.
"""
function α1(p::Path)
    isempty(p) && return p.α0
    α1(segment(nodes(p)[end]))::Float64
end

"""
    p0(p::Path)
First point of a path.
"""
function p0(p::Path)
    isempty(p) && return p.p0
    p0(segment(nodes(p)[1]))
end

"""
    p1(p::Path)
Last point of a path.
"""
function p1(p::Path)
    isempty(p) && return p.p0
    p1(segment(nodes(p)[end]))
end

"""
    style0(p::Path)
Style of the first segment of a path.
"""
function style0(p::Path)
    isempty(p) && error("path is empty, provide a style.")
    style(nodes(p)[1])
end

"""
    style1(p::Path)
Style of the last segment of a path.
"""
style1(p::Path) = style1(p, Style)

function style1(p::Path, T)
    isempty(p) && error("path is empty, provide a style.")
    A = view(nodes(p), reverse(1:length(nodes(p))))
    i = findfirst(x->isa(style(x), T), A)
    if i > 0
        style(A[i])
    else
        error("No $T found in the path.")
    end
end

include("contstyles/trace.jl")
include("contstyles/cpw.jl")
include("contstyles/compound.jl")
include("contstyles/decorated.jl")
include("discretestyles/simple.jl")
include("norender.jl")

include("segments/straight.jl")
include("segments/turn.jl")
include("segments/corner.jl")
include("segments/compound.jl")

"""
    discretestyle1{T}(p::Path{T})
Returns the last-used discrete style in the path.
"""
discretestyle1{T}(p::Path{T}) = style1(p, DiscreteStyle)

"""
    contstyle1(p::Path)
Returns the last-used discrete style in the path.
"""
contstyle1(p::Path) = style1(p, ContinuousStyle)

"""
    adjust!(p::Path, n::Integer=1)
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

    function updateα0p0!{T}(n::Node{T}, α0, p0)
        if previous(n) == n # first node
            setα0p0!(segment(n), α0, p0)
        else
            seg = segment(n)
            seg0 = segment(previous(n))
            setα0p0!(seg, α1(seg0), p1(seg0))
        end
    end

    for j in n:length(p)
        updatell!(p,j)
        updatefields!(p[j])
        updateα0p0!(p[j], p.α0, p.p0)
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
    append!(p::Path, p′::Path)
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
    simplify(p::Path, inds::UnitRange=1:length(p))
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
    simplify!(p::Path, inds::UnitRange=1:length(p))
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
    meander!(p::Path, len, straightlen, r, α)
Alternate between going straight with length `straightlen` and turning
with radius `r` and angle `α`. Each turn goes the opposite direction of the
previous. The total length is `len`. Useful for making resonators.

The straight and turn segments are combined into a `CompoundSegment` and
appended to the path `p`.
"""
function meander!(p::Path, len, straightlen, r, α)
    unit = straightlen + r*α
    ratio = len/unit
    fl = floor(ratio)
    nsegs = Int(fl)
    rem = (ratio-fl)*unit

    for pm in take(cycle((1,-1)), nsegs)
        straight!(p, straightlen, style1(p))
        turn!(p, pm*α, r, style1(p))           # alternates left and right
    end
    straight!(p, rem)
    p
end

const launchdefaults = Dict([
    (:extround, 5.0),
    (:trace0, 300.0),
    (:trace1, 10.0),
    (:gap0, 150.0),
    (:gap1, 6.0),
    (:flatlen, 250.0),
    (:taperlen, 250.0)
])

@compat launch!(p::Path{<:Real}; kwargs...) = _launch!(p; launchdefaults..., kwargs...)

function launch!{T<:Length}(p::Path{T}; kwargs...)
    u = Unitful.ContextUnits(Unitful.μm, upreferred(unit(T)))
    _launch!(p; Dict(zip(keys(launchdefaults),collect(values(launchdefaults))*u))...,
        kwargs...)
end

function _launch!{T<:Coordinate}(p::Path{T}; kwargs...)
    d = Dict{Symbol,T}(kwargs)
    extround = d[:extround]
    trace0, trace1 = d[:trace0], d[:trace1]
    gap0, gap1 = d[:gap0], d[:gap1]
    flatlen, taperlen = d[:flatlen], d[:taperlen]

    y = isempty(p)
    s0 = Trace(t->2*(trace0/2 + gap0 - extround + sqrt(extround^2 - (t - extround * y)^2)))
    s1 = Trace(trace0+2*gap0)
    s2 = CPW(trace0, gap0)

    u,v = ifelse(y, (trace0, trace1), (trace1, trace0))
    w,x = ifelse(y, (gap0, gap1), (gap1, gap0))
    s3 = CPW(t->(u + t / taperlen * (v - u)), t->(w + t / taperlen * (x - w)))

    if y
        args = (extround, gap0-extround, flatlen, taperlen)
        styles = (s0, s1, s2, s3)
    else
        args = (taperlen, flatlen, gap0-extround, extround)
        styles = (s3, s2, s1, s0)
    end

    for (a,b) in zip(args,styles)
        straight!(p, a, b)
    end

    CPW(trace1, gap1)
end

end
