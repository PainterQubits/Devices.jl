module Paths
using ..Points
using ..Cells
using Unitful
using Unitful: Length, LengthUnits, DimensionError, °
import StaticArrays

import Base:
    convert,
    copy,
    deepcopy_internal,
    enumerate,
    isempty,
    empty!,
    deleteat!,
    length,
    firstindex,
    lastindex,
    size,
    getindex,
    setindex!,
    push!,
    pop!,
    pushfirst!,
    popfirst!,
    insert!,
    append!,
    splice!,
    split,
    intersect!,
    show,
    summary,
    dims2string

import Base.Iterators

using ForwardDiff
import IntervalSets.(..)
import Devices
import Devices: Polygons, Coordinate, FloatCoordinate, CoordinateUnits, GDSMeta, Meta
import Devices.Polygons: segmentize, intersects
import Devices: bounds, bridge!

export Path

export α0, α1, p0, p1, style0, style1, discretestyle1, contstyle1
export reconcile!,
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
    terminate!,
    turn!,
    undecorated

"""
    abstract type Style end
How to render a given path segment.
"""
abstract type Style end

"""
    abstract type ContinuousStyle{CanStretch} <: Style end
Any style that applies to segments which have non-zero path length. For most styles,
`CanStretch == false`. An example of an exception is a linear taper, e.g.
[`Paths.TaperTrace`](@ref), where you fix the starting and ending trace widths and let the
segment length dictate the abruptness of the transition (hence, stretching the style).
Concrete types inheriting from `ContinuousStyle{true}` should have a length field as the
last field of their structure.
"""
abstract type ContinuousStyle{CanStretch} <: Style end

"""
    abstract type DiscreteStyle <: Style end
Any style that applies to segments which have zero path length.
"""
abstract type DiscreteStyle <: Style end

include("contstyles/interface.jl")

"""
    abstract type Segment{T<:Coordinate} end
Path segment in the plane. All Segment objects should have the implement the following
methods:

- `pathlength`
- `p0`
- `α0`
- `setp0!`
- `setα0!`
- `α1`
"""
abstract type Segment{T<:Coordinate} end
@inline Base.eltype(::Segment{T}) where {T} = T
@inline Base.eltype(::Type{Segment{T}}) where {T} = T

Base.zero(::Segment{T}) where {T} = zero(T)     # TODO: remove and fix for 0.6 only versions
Base.zero(::Type{Segment{T}}) where {T} = zero(T)

# Used only to get dispatch to work right with ForwardDiff.jl.
struct Curv{T} s::T end
(s::Curv)(t) = ForwardDiff.derivative(s.s,t)

"""
    curvature(s, t)
Returns the curvature of a function `t->Point(x(t),y(t))` at `t`. The result will have units
of inverse length if units were used for the segment. The result can be interpreted as the
inverse radius of a circle with the same curvature.
"""
curvature(s, t) = ForwardDiff.derivative(Curv(s), t)

abstract type DiscreteSegment{T} <: Segment{T} end
abstract type ContinuousSegment{T} <: Segment{T} end

Base.zero(::Type{ContinuousSegment{T}}) where {T} = zero(T)

# doubly linked-list behavior
mutable struct Node{T<:Coordinate}
    seg::Segment{T}
    sty::Style
    prev::Node{T}
    next::Node{T}

    Node{T}(a,b) where {T} = begin
        n = new{T}(a,b)
        n.prev = n
        n.next = n
    end
    Node{T}(a,b,c,d) where {T} = new{T}(a,b,c,d)
end

"""
    Node(a::Segment{T}, b::Style) where {T}
Create a node with segment `a` and style `b`.
"""
Node(a::Segment{T}, b::Style) where {T} = Node{T}(a,b)

@inline Base.eltype(::Node{T}) where {T} = T
@inline Base.eltype(::Type{Node{T}}) where {T} = T

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
    setsegment!(n::Node, s::Segment)
Set the segment associated with node `n` to `s`. If `reconcile`, then modify fields as
appropriate for internal consistency (possibly including other linked nodes).
"""
function setsegment!(n::Node, s::Segment; reconcile=true)
    n.seg = s
    if reconcile
        reconcilefields!(n)
        reconcilestart!(n, α0(s), p0(s))
        n′ = n
        while next(n′) !== n′
            n′ = next(n′)
            reconcilefields!(n′)
            reconcilestart!(n′)
        end
    end
    return n
end

"""
    setstyle!(n::Node, s::Style; reconcile=true)
Set the style associated with node `n` to `s`. If `reconcile`, then modify fields as
appropriate for internal consistency.
"""
function setstyle!(n::Node, s::Style; reconcile=true)
    n.sty = s
    reconcile && reconcilefields!(n)
    return n
end

function deepcopy_internal(x::Style, stackdict::IdDict)
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
#     !(extr[1] ≈ 0.0) && pushfirst!(extr, 0.0)
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
    p0(s::Segment{T}) where {T}
Return the first point in a segment (calculated).
"""
p0(s::Segment{T}) where {T} = s(zero(T))::Point{T}

"""
    p1(s::Segment{T}) where {T}
Return the last point in a segment (calculated).
"""
p1(s::Segment{T}) where {T} = s(pathlength(s))::Point{T}

"""
    α0(s::Segment)
Return the first angle in a segment (calculated).
"""
α0(s::Segment{T}) where {T} = direction(s, zero(T))

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
show(io::IO, s::Style) = print(io, summary(s))

function deepcopy_internal(x::Segment, stackdict::IdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = copy(x)
    stackdict[x] = y
    return y
end

"""
    mutable struct Path{T<:Coordinate} <: AbstractVector{Node{T}}
Type for abstracting an arbitrary styled path in the plane. Iterating returns
[`Paths.Node`](@ref) objects.

    Path(p0::Point=Point(0.0,0.0); α0=0.0)
    Path(p0x::Real, p0y::Real; kwargs...)
    Path(p0::Point{T}; α0=0.0) where {T<:Length}
    Path(p0x::T, p0y::T; kwargs...) where {T<:Length}
    Path(p0x::Length, p0y::Length; kwargs...)
    Path(u::LengthUnits; α0=0.0)
    Path(v::Vector{<:Node})
Convenience constructors for `Path{T}` object.
"""
mutable struct Path{T<:Coordinate} <: AbstractVector{Node{T}}
    p0::Point{T}
    α0::Float64
    nodes::Vector{Node{T}}
    laststyle::ContinuousStyle

    Path{T}() where {T} = new{T}(Point(zero(T),zero(T)), 0.0, Node{T}[])
    Path{T}(a,b,c) where {T} = new{T}(a,b,c)
end
@inline Base.eltype(::Path{T}) where {T} = T
@inline Base.eltype(::Type{Path{T}}) where {T} = T
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

function Path(p0::Point=Point(0.0,0.0); α0=0.0)
    Path{Float64}(p0, α0, Node{Float64}[])
end
Path(p0x::Real, p0y::Real; kwargs...) = Path(Point{Float64}(p0x,p0y); kwargs...)

function Path(p0::Point{T}; α0=0.0) where {T <: Length}
    Path{typeof(0.0*unit(T))}(p0, α0, Node{typeof(0.0*unit(T))}[])
end
Path(p0x::T, p0y::T; kwargs...) where {T <: Length} =
    Path(Point{typeof(0.0*unit(T))}(p0x,p0y); kwargs...)
Path(p0x::Length, p0y::Length; kwargs...) = Path(promote(p0x,p0y)...; kwargs...)

function Path(u::LengthUnits; α0=0.0)
    Path{typeof(0.0u)}(Point(0.0u,0.0u), α0, Node{typeof(0.0u)}[])
end
function Path(v::Vector{Node{T}}) where {T}
    isempty(v) && return Path{T}(Point(zero(T), zero(T)), 0.0, v)
    return Path{T}(p0(segment(v[1])), α0(segment(v[1])), v)
end


Path(x::Coordinate, y::Coordinate; kwargs...) = throw(DimensionError(x,y))

"""
    pathlength(p::Path)
    pathlength(array::AbstractArray{Node{T}}) where {T}
    pathlength(array::AbstractArray{T}) where {T<:Segment}
    pathlength(node::Node)
Physical length of a path. Note that `length` will return the number of
segments in a path, not the physical length of the path.
"""
function pathlength end

pathlength(p::Path) = pathlength(nodes(p))
pathlength(array::AbstractArray{Node{T}}) where {T} =
    mapreduce(pathlength, +, array; init = zero(T))
pathlength(array::AbstractArray{T}) where {T <: Segment} =
    mapreduce(pathlength, +, array; init = zero(T))
pathlength(node::Node) = pathlength(segment(node))

"""
    α0(p::Path)
First angle of a path, returns `p.α0`.
"""
α0(p::Path) = p.α0

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
First point of a path, returns `p.p0`.
"""
p0(p::Path) = p.p0

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
    if i == nothing
        error("No $T found in the path.")
    else
        style(A[i])
    end
end

include("contstyles/trace.jl")
include("contstyles/cpw.jl")
include("contstyles/compound.jl")
include("contstyles/decorated.jl")
include("contstyles/tapers.jl")
include("contstyles/strands.jl")
include("discretestyles/simple.jl")
include("norender.jl")

include("segments/straight.jl")
include("segments/turn.jl")
include("segments/corner.jl")
include("segments/compound.jl")

include("intersect.jl")

"""
    discretestyle1(p::Path)
Returns the last-used discrete style in the path.
"""
discretestyle1(p::Path) = style1(p, DiscreteStyle)

"""
    contstyle1(p::Path)
Returns the last user-provided continuous style in the path.
"""
function contstyle1(p::Path)
    isdefined(p, :laststyle) || error("path is empty, provide a style.")
    return p.laststyle
end

"""
    reconcilelinkedlist!(p::Path, m::Integer)
Paths have both array-like access and linked-list-like access (most often you use array
access, but segments/styles need to know about their neighbors sometimes). When doing array
operations on the path, the linked list can become inconsistent. This function restores
consistency for the node at index `m`, with previous node `m-1` and next node `m+1`.
First and last node are treated specially.
"""
function reconcilelinkedlist!(p::Path, m::Integer)
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

"""
    reconcilefields!(n::Node)
Segments or styles can have fields that depend on the properties of neighbors. Examples:
  - Corners need to know their extents based on previous/next styles.
  - Tapers need to know their length for `extent(s, t)` to work.
This function reconciles node `n` for consistency with neighbors in this regard.
"""
function reconcilefields!(n::Node)
    seg,sty = segment(n), style(n)
    if isa(seg, Corner)
        seg.extent = extent(style(previous(n)), pathlength(segment(previous(n))))
    end
    if isa(sty, ContinuousStyle{true})
        n.sty = typeof(sty)(
            (getfield(sty, i) for i in 1:(nfields(sty)-1))..., pathlength(seg))
    end
end

"""
    reconcilestart!(n::Node{T}, α0=0, p0=Point(zero(T), zero(T))) where {T}
This function reconciles the starting position and angle of the segment at path node `n`
to match the ending position and angle of the previous node.
"""
function reconcilestart!(n::Node{T}, α0=0, p0=Point(zero(T), zero(T))) where {T}
    if previous(n) == n # first node
        setα0p0!(segment(n), α0, p0)
    else
        seg = segment(n)
        seg0 = segment(previous(n))
        setα0p0!(seg, α1(seg0), p1(seg0))
    end
end

"""
    reconcile!(p::Path, n::Integer=1)
Reconcile all inconsistencies in a path starting from index `n`. Used internally whenever
segments are inserted into the path, but can be safely used by the user as well.
"""
function reconcile!(p::Path, n::Integer=1)
    isempty(p) && return
    for j in n:lastindex(p)
        reconcilelinkedlist!(p,j)
        reconcilefields!(p[j])
        reconcilestart!(p[j], α0(p), p0(p))
    end
end

# Methods for Path as AbstractArray

function splice!(p::Path, inds; reconcile=true)
    n = splice!(nodes(p), inds)
    reconcile && reconcile!(p, first(inds))
    return n
end
function splice!(p::Path, inds, p2::Path; reconcile=true)
    n = splice!(nodes(p), inds, nodes(p2))
    reconcile && reconcile!(p, first(inds))
    return n
end

length(p::Path) = length(nodes(p))
iterate(p::Path, state...) = iterate(nodes(p), state...)
enumerate(p::Path) = enumerate(nodes(p))
Iterators.rest(p::Path, state) = Iterators.rest(nodes(p), state)
Iterators.take(p::Path, n::Int) = Iterators.take(nodes(p), n)
Iterators.drop(p::Path, n::Int) = Iterators.drop(nodes(p), n)
Iterators.cycle(p::Path) = Iterators.cycle(nodes(p))
isempty(p::Path) = isempty(nodes(p))
empty!(p::Path) = empty!(nodes(p))
function deleteat!(p::Path, inds; reconcile=true)
    deleteat!(nodes(p), inds)
    reconcile && reconcile!(p, first(inds))
end
firstindex(p::Path) = 1
lastindex(p::Path) = length(nodes(p))
size(p::Path) = size(nodes(p))
getindex(p::Path, i::Integer) = nodes(p)[i]
function setindex!(p::Path, v::Node, i::Integer; reconcile=true)
    nodes(p)[i] = v
    reconcile && reconcile!(p, i)
end
function setindex!(p::Path, v::Segment, i::Integer; reconcile=true)
    setsegment!(nodes(p)[i], v; reconcile=reconcile)
end
function setindex!(p::Path, v::Style, i::Integer; reconcile=true)
    setstyle!(nodes(p)[i], v; reconcile=reconcile)
end
function push!(p::Path, node::Node; reconcile=true)
    push!(nodes(p), node)
    reconcile && reconcile!(p, length(p))
end
function pushfirst!(p::Path, node::Node; reconcile=true)
    pushfirst!(nodes(p), node)
    reconcile && reconcile!(p)
end

for x in (:push!, :pushfirst!)
    @eval function ($x)(p::Path, seg::Segment, sty::Style; reconcile=true)
        ($x)(p, Node(seg, sty); reconcile=reconcile)
    end
    @eval function ($x)(p::Path, segsty0::Node, segsty::Node...; reconcile=true)
        ($x)(p, segsty0; reconcile=reconcile)
        for x in segsty
            ($x)(p, x; reconcile=reconcile)
        end
    end
end

function pop!(p::Path; reconcile=true)
    x = pop!(nodes(p))
    reconcile && reconcile!(p, length(p))
    return x
end

function popfirst!(p::Path; reconcile=true)
    x = popfirst!(nodes(p))
    reconcile && reconcile!(p)
    return x
end

function insert!(p::Path, i::Integer, segsty::Node; reconcile=true)
    insert!(nodes(p), i, segsty)
    reconcile && reconcile!(p, i)
end

insert!(p::Path, i::Integer, seg::Segment, sty::Style; reconcile=true) =
    insert!(p, i, Node(seg,sty); reconcile=reconcile)

function insert!(p::Path, i::Integer, seg::Segment; reconcile=true)
    if i == 1
        sty = style0(p)
    else
        sty = style(nodes(p)[i-1])
    end
    insert!(p, i, Node(seg,sty); reconcile=reconcile)
end

function insert!(p::Path, i::Integer, segsty0::Node, segsty::Node...; reconcile=true)
    insert!(p, i, segsty0; reconcile=reconcile)
    for x in segsty
        insert!(p, i, x; reconcile=reconcile)
    end
end

"""
    append!(p::Path, p′::Path; reconcile=true)
Given paths `p` and `p′`, path `p′` is appended to path `p`.
The p0 and initial angle of the first segment from path `p′` is
modified to match the last point and last angle of path `p`.
"""
function append!(p::Path, p′::Path; reconcile=true)
    isempty(p′) && return
    i = length(p)
    lp, la = p1(p), α1(p)
    append!(nodes(p), nodes(p′))
    reconcile && reconcile!(p, i+1)
    nothing
end

"""
    simplify(p::Path, inds::UnitRange=firstindex(p):lastindex(p))
At `inds`, segments of a path are turned into a `CompoundSegment` and
styles of a path are turned into a `CompoundStyle`. The method returns a tuple,
`(segment, style)`.

- Indexing the path becomes more sane when you can combine several path segments into one
  logical element. A launcher would have several indices in a path unless you could simplify
  it.
- You don't need to think hard about boundaries between straights and turns when you want a
  continuous styling of a very long path.
"""
function simplify(p::Path, inds::UnitRange=firstindex(p):lastindex(p))
    tag = gensym()
    cseg = CompoundSegment(nodes(p)[inds], tag)
    csty = CompoundStyle(cseg.segments, map(style, nodes(p)[inds]), tag)
    Node(cseg, csty)
end

"""
    simplify!(p::Path, inds::UnitRange=firstindex(p):lastindex(p))
In-place version of [`simplify`](@ref).
"""
function simplify!(p::Path, inds::UnitRange=firstindex(p):lastindex(p))
    x = simplify(p, inds)
    deleteat!(p, inds)
    insert!(p, inds[1], x)
    p
end

"""
    meander!(p::Path, len, straightlen, r, α)
Alternate between going straight with length `straightlen` and turning with radius `r` and
angle `α`. Each turn goes the opposite direction of the previous. The total length is `len`.
Useful for making resonators.

The straight and turn segments are combined into a `CompoundSegment` and appended to the
path `p`.
"""
function meander!(p::Path, len, straightlen, r, α)
    unit = straightlen + r*abs(α)
    ratio = len/unit
    fl = floor(ratio)
    nsegs = Int(fl)
    rem = (ratio-fl)*unit

    for pm in Iterators.take(Iterators.cycle((1,-1)), nsegs)
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

launch!(p::Path{<:Real}; kwargs...) = _launch!(p; launchdefaults..., kwargs...)

function launch!(p::Path{T}; kwargs...) where {T <: Length}
    u = Unitful.ContextUnits(Unitful.μm, upreferred(unit(T)))
    _launch!(p; Dict(zip(keys(launchdefaults),collect(values(launchdefaults))*u))...,
        kwargs...)
end

function _launch!(p::Path{T}; kwargs...) where {T <: Coordinate}
    d = Dict{Symbol,T}(kwargs)
    extround = d[:extround]
    trace0, trace1 = d[:trace0], d[:trace1]
    gap0, gap1 = d[:gap0], d[:gap1]
    flatlen, taperlen = d[:flatlen], d[:taperlen]

    y = isempty(p)
    s0 = if extround == zero(extround)
        Trace(trace0+2*gap0)
    else
        Trace(t->2*(trace0/2 + gap0 - extround + sqrt(extround^2 - (t - extround * y)^2)))
    end
    s1 = Trace(trace0+2*gap0)
    s2 = CPW(trace0, gap0)

    u,v = ifelse(y, (trace0, trace1), (trace1, trace0))
    w,x = ifelse(y, (gap0, gap1), (gap1, gap0))
    s3 = TaperCPW(u,w,v,x)

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

"""
    terminate!(pa::Path)
End a path with open termination (do nothing for a trace, leave a gap for a CPW).
"""
function terminate!(pa::Path{T}) where T
    terminationlength(pa) > zero(T) &&
        straight!(pa, terminationlength(pa), terminationstyle(pa))
end

terminationlength(pa::Path, t=pathlength(pa[end])) = terminationlength(style(pa[end]), t)
terminationlength(s::Trace, t) = zero(t)
terminationlength(s::CPW, t) = gap(s,t)

terminationstyle(pa::Path, t=pathlength(pa[end])) = terminationstyle(style(pa[end]), t)
terminationstyle(s::CPW, t) = Paths.Trace(2 * extent(s,t))

"""
    split(n::Node, x::Coordinate)
    split(n::Node, x::AbstractVector{<:Coordinate}; issorted=false)
Splits a path node at position(s) `x` along the segment, returning a path.
If `issorted`, don't sort `x` first (otherwise required for this to work).

A useful idiom, splitting and splicing back into a path:
    splice!(path, i, split(path[i], x))
"""
function split(n::Node, x::Coordinate)
    seg1, seg2, sty1, sty2 = split(segment(n), style(n), x)

    n1 = Node(seg1, sty1)
    n2 = Node(seg2, sty2)
    n1.prev = n.prev
    n1.next = n2
    n2.prev = n1
    n2.next = n.next

    return Path([n1, n2])
end

function split(n::Node, x::AbstractVector{<:Coordinate}; issorted=false)
    @assert !isempty(x)
    sortedx = issorted ? x : sort(x)

    i = 2
    L = first(sortedx)
    path = split(n, L)
    for pos in view(sortedx, (firstindex(sortedx)+1):lastindex(sortedx))
        splice!(path, i, split(path[i], pos-L); reconcile=false)
        L = pos
        i += 1
    end
    reconcile!(path)
    return path
end

function split(seg::Segment, sty::Style, x)
    return (split(seg, x)..., split(sty, x)...)
end

function split(seg::Segment, x)
    @assert zero(x) < x < pathlength(seg)
    @assert seg isa ContinuousSegment
    return _split(seg, x)
end

function split(sty::Style, x)
    @assert sty isa ContinuousStyle
    return _split(sty, x)
end

function _split(sty::Style, x)
    s1, s2 = pin(sty; stop=x), pin(sty; start=x)
    undecorate!(s1, x)  # don't duplicate attachments at the split point!
    return s1, s2
end

function _split(sty::CompoundStyle, x, tag1, tag2)
    return pin(sty; stop=x, tag=tag1), pin(sty; start=x, tag=tag2)
end

end
