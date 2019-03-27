module Polygons

using LinearAlgebra

import Base: +, -, *, /, ==, isapprox
import Base: convert, getindex
import Base: copy, promote_rule

using ForwardDiff
import CoordinateTransformations: AffineMap, LinearMap, Translation
import Clipper
import Clipper: children, contour
import StaticArrays

import Devices
import Devices: AbstractPolygon, Coordinate, GDSMeta, Meta
import Devices: bounds, lowerleft, upperright, orientation
import Unitful
import Unitful: Quantity, Length, dimension, unit, ustrip, uconvert, °
using ..Points
using ..Rectangles
import ..cclipper

import IntervalSets.(..)
import IntervalSets.endpoints

export Polygon
export points
export clip, offset, circle

const USCALE = 1.0*Unitful.fm
const SCALE  = 10.0^9

clipper() = (Devices._clip[])::Clipper.Clip
coffset() = (Devices._coffset[])::Clipper.ClipperOffset

@inline unsafe_round(x::Number) = round(ustrip(x))*unit(x)
@inline unsafe_round(x::Point) = unsafe_round.(x)

"""
    struct Polygon{T} <: AbstractPolygon{T}
        p::Vector{Point{T}}
        Polygon(x) = new(x)
        Polygon(x::AbstractPolygon) = convert(Polygon{T}, x)
    end
Polygon defined by list of coordinates. The first point should not be repeated
at the end (although this is true for the GDS format).
"""
struct Polygon{T} <: AbstractPolygon{T}
    p::Vector{Point{T}}
    Polygon{T}(x) where {T} = new{T}(x)
    Polygon{T}(x::AbstractPolygon) where {T} = convert(Polygon{T}, x)
end

"""
    Polygon(p0::Point, p1::Point, p2::Point, p3::Point...)
Convenience constructor for a `Polygon{T}` object.
"""
Polygon(p0::Point, p1::Point, p2::Point, p3::Point...) = Polygon([p0, p1, p2, p3...])

"""
    Polygon{T}(parr::AbstractVector{Point{T}})
Convenience constructor for a `Polygon{T}` object.
"""
Polygon(parr::AbstractVector{Point{T}}) where {T} = Polygon{T}(parr)

Polygon(parr::AbstractVector{Point}) =
    error("polygon creation failed. Perhaps you mixed units and unitless numbers?")

==(p1::Polygon, p2::Polygon) = (p1.p == p2.p)
isapprox(p1::Polygon, p2::Polygon) = isapprox(p1.p, p2.p)
copy(p::Polygon) = Polygon(copy(p.p))

"""
    points(x::Polygon)
Returns the array of `Point` objects defining the polygon.
"""
points(x::Polygon) = x.p

"""
    points{T}(x::Rectangle{T})
Returns the array of `Point` objects defining the rectangle.
"""
points(x::Rectangle{T}) where {T} = points(convert(Polygon{T}, x))

for (op, dotop) in [(:+, :.+), (:-, :.-)]
    @eval function ($op)(r::Polygon, p::Point)
        Polygon(($dotop)(r.p, p))
    end
    @eval function ($op)(r::Polygon, p::StaticArrays.Scalar{<:Point})
        Polygon(($dotop)(r.p, p))
    end
    @eval function ($op)(p::Point, r::Polygon)
        Polygon(($dotop)(p, r.p))
    end
    @eval function ($op)(p::StaticArrays.Scalar{<:Point}, r::Polygon)
        Polygon(($dotop)(p, r.p))
    end
end

*(r::Polygon, a::Number) = Polygon(r.p .* a)
*(a::Number, r::Polygon) = *(r,a)
/(r::Polygon, a::Number) = Polygon(r.p ./ a)

"""
    lowerleft(x::Polygon)
Return the lower-left-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
lowerleft(x::Polygon) = lowerleft(x.p)

"""
    upperright(x::Polygon)
Return the upper-right-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
upperright(x::Polygon) = upperright(x.p)

for T in (:LinearMap, :AffineMap)
    @eval (f::$T)(x::Polygon) = Polygon(f.(x.p))
    @eval (f::$T)(x::Rectangle) = f(convert(Polygon, x))
end

(f::Translation)(x::Polygon) = Polygon(f.(x.p))
(f::Translation)(x::Rectangle) = Rectangle(f(x.ll), f(x.ur))

function convert(::Type{Polygon{T}}, s::Rectangle) where {T}
    ll = convert(Point{T}, s.ll)
    ur = convert(Point{T}, s.ur)
    lr = Point(T(getx(ur)), T(gety(ll)))
    ul = Point(T(getx(ll)), T(gety(ur)))
    Polygon{T}(Point{T}[ll,lr,ur,ul])
end
convert(::Type{Polygon}, s::Rectangle{T}) where {T} = convert(Polygon{T}, s)
convert(::Type{AbstractPolygon{T}}, s::Rectangle) where {T} = convert(Rectangle{T}, s)
function convert(::Type{Polygon{T}}, p::Polygon) where {T}
    Polygon{T}(convert(Array{Point{T},1}, p.p))
end

"""
    bounds(p::Polygon)
Return a bounding Rectangle for polygon `p`.
"""
bounds(p::Polygon) = Rectangle(lowerleft(p), upperright(p))

"""
    bounds(parr::AbstractArray{<:AbstractPolygon})
Return a bounding `Rectangle` for an array `parr` of `AbstractPolygon` objects.
Rectangles having zero width and height should be excluded from the calculation.
"""
function bounds(parr::AbstractArray{<:AbstractPolygon})
    rects = filter(isproper, map(bounds, parr))
    ll = lowerleft(map(lowerleft, rects))
    ur = upperright(map(upperright, rects))
    Rectangle(ll, ur)
end

"""
    bounds(p0::AbstractPolygon, p::AbstractPolygon...)
Return a bounding `Rectangle` for several `AbstractPolygon` objects.
"""
bounds(p0::AbstractPolygon, p::AbstractPolygon...) = bounds([p0, p...])

"""
    circle(r, α=10°)
Returns a circular `Polygon` centered about the origin with radius `r` and angular step `α`.
"""
circle(r, α=10°) = Polygon(r.*(a->Point(cos(a),sin(a))).(0:α:(360°-α)))

abstract type Style{T<:Meta} end

"""
    struct Plain{T} <: Polygons.Style{T}
        meta::T
    end
Plain polygon style.
"""
struct Plain{T} <: Style{T}
    meta::T
end
Plain() = Plain(GDSMeta())

# Polygon promotion.
for X in (:Real, :Length)
    @eval promote_rule(::Type{Polygon{S}}, ::Type{Polygon{T}}) where {S<:$X, T<:$X} =
        Polygon{promote_type(S,T)}
    @eval promote_rule(::Type{Rectangle{S}}, ::Type{Polygon{T}}) where {S<:$X, T<:$X} =
        Polygon{promote_type(S,T)}
    @eval promote_rule(::Type{Rectangle{S}}, ::Type{Rectangle{T}}) where {S<:$X, T<:$X} =
        Rectangle{promote_type(S,T)}
end

# Clipping polygons one at a time
"""
    clip(op::Clipper.ClipType, s::AbstractPolygon{S}, c::AbstractPolygon{T};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) where
        {S <: Coordinate,T <: Coordinate}
    clip(op::Clipper.ClipType, s::AbstractVector{A}, c::AbstractVector{B};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) where
        {S, T, A <: AbstractPolygon{S}, B <: AbstractPolygon{T}}
    clip{S<:AbstractPolygon, T<:AbstractPolygon}(op::Clipper.ClipType,
        s::AbstractVector{S}, c::AbstractVector{T};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
Using the [`Clipper`](http://www.angusj.com/delphi/clipper.php) library and
the [`Clipper.jl`](https://github.com/Voxel8/Clipper.jl) wrapper, perform
polygon clipping. The first argument must be one of the following types :

- `Clipper.ClipTypeDifference`
- `Clipper.ClipTypeIntersection`
- `Clipper.ClipTypeUnion`
- `Clipper.ClipTypeXor`

Note that these are types; you should not follow them with `()`.
The second and third arguments are `AbstractPolygon` objects. Keyword arguments
`pfs` and `pfc` specify polygon fill rules (see the [`Clipper` docs](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/PolyFillType.htm)
for further information). These arguments may include:

- `Clipper.PolyFillTypeNegative`
- `Clipper.PolyFillTypePositive`
- `Clipper.PolyFillTypeEvenOdd`
- `Clipper.PolyFillTypeNonZero`
"""
function clip(op::Clipper.ClipType, s::AbstractPolygon{S}, c::AbstractPolygon{T};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) where
        {S <: Coordinate,T <: Coordinate}

    dimension(S) != dimension(T) && throw(Unitful.DimensionError(oneunit(S), oneunit(T)))
    R = promote_type(S, T)
    clip(op, Polygon{R}[s], Polygon{R}[c]; pfs=pfs, pfc=pfc)::Vector{Polygon{R}}
end

# Clipping arrays of AbstractPolygons
function clip(op::Clipper.ClipType, s::AbstractVector{A}, c::AbstractVector{B};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) where
    {S, T, A <: AbstractPolygon{S}, B <: AbstractPolygon{T}}

    dimension(S) != dimension(T) && throw(Unitful.DimensionError(oneunit(S), oneunit(T)))
    R = promote_type(S, T)
    clip(op, convert(Vector{Polygon{R}}, s), convert(Vector{Polygon{R}}, c);
        pfs=pfs, pfc=pfc)::Vector{Polygon{R}}
end

# Clipping two identically-typed arrays of <: Polygon
function clip(op::Clipper.ClipType,
    s::AbstractVector{Polygon{T}}, c::AbstractVector{Polygon{T}};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) where {T}

    sc, cc = clipperize(s), clipperize(c)
    polys = _clip(op, sc, cc; pfs=pfs, pfc=pfc)
    declipperize(polys, T)
end

function add_path!(c::Clipper.Clip, path::Vector{Point{T}}, polyType::Clipper.PolyType,
        closed::Bool) where {T<:Union{Int64, Unitful.Quantity{Int64}}}
    ccall((:add_path, cclipper), Cuchar, (Ptr{Cvoid}, Ptr{Clipper.IntPoint}, Csize_t, Cint, Cuchar),
          c.clipper_ptr,
          path,
          length(path),
          Int(polyType),
          closed) == 1 ? true : false
end

# Clipping two identically-typed arrays of "Int64-based" Polygons.
# Internal method which should not be called by user (but does the heavy lifting)
function _clip(op::Clipper.ClipType,
        s::AbstractVector{Polygon{T}}, c::AbstractVector{<:Polygon};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) where
        {T <: Union{Int64, Unitful.Quantity{Int64}}}

    clip = clipper()
    Clipper.clear!(clip)
    for s0 in s
        add_path!(clip, s0.p, Clipper.PolyTypeSubject, true)
    end
    for c0 in c
        add_path!(clip, c0.p, Clipper.PolyTypeClip, true)
    end
    result = convert(Clipper.PolyNode{Point{Int}},
        Clipper.execute_pt(clip, op, pfs, pfc)[2])

    polys = interiorcuts(result, Polygon{T}[])
end

#   Int64like(x::Point{T}) where {T}
#   Int64like(x::Polygon{T}) where {T}
# Converts Points or Polygons to an Int64-based representation (possibly with units).
Int64like(x::Point{T}) where {T} = convert(Point{typeof(Int64(1) * unit(T))}, x)
Int64like(x::Polygon{T}) where {T} = convert(Polygon{typeof(Int64(1) * unit(T))}, x)

#   prescale(x::Point{<:Real})
# Since the Clipper library works on Int64-based points, we multiply floating-point-based
# `x` by `10.0^9` before rounding to retain high resolution. Since` 1.0` is interpreted
# to mean `1.0 um`, this yields `fm` resolution, which is more than sufficient for most uses.
prescale(x::Point{<:Real}) = x * SCALE  # 2^29.897...

#   prescale(x::Point{<:Quantity})
# Since the Clipper library works on Int64-based points, we unit-convert `x` to `fm` before
# rounding to retain high resolution, which is more than sufficient for most uses.
prescale(x::Point{<:Quantity}) = convert(Point{typeof(USCALE)}, x)

#   clipperize(A::AbstractVector{Polygon{T}}) where {T}
#   clipperize(A::AbstractVector{Polygon{T}}) where {S<:Integer, T<:Union{S, Unitful.Quantity{S}}}
#   clipperize(A::AbstractVector{Polygon{T}}) where {T <: Union{Int64, Unitful.Quantity{Int64}}}
# Prepare a vector of Polygons for being operated upon by the Clipper library,
# which expects Int64-based points (Quantity{Int64} is okay after using `reinterpret`).
function clipperize(A::AbstractVector{Polygon{T}}) where {T}
    [Polygon(Int64like.(unsafe_round.(prescale.(points(x))))) for x in A]
end

# Already Integer-based, so no need to do rounding or scaling. Just convert to Int64-like.
function clipperize(A::AbstractVector{Polygon{T}}) where
        {S<:Integer, T<:Union{S, Unitful.Quantity{S}}}
    return Int64like.(A)
end

# Already Int64-based, so just pass through, nothing to do here.
function clipperize(A::AbstractVector{Polygon{T}}) where
    {T <: Union{Int64, Unitful.Quantity{Int64}}}
    return A
end

unscale(p::Point, ::Type{T}) where {T <: Quantity} = convert(Point{T}, p)
unscale(p::Point, ::Type{T}) where {T} = convert(Point{T}, p ./ SCALE)

# Declipperize methods are used to get back to the original type.
function declipperize(A, ::Type{T}) where {T}
    [Polygon{T}((x->unscale(x,T)).(points(p))) for p in A]
end
function declipperize(A, ::Type{T}) where {T <: Union{Int64, Unitful.Quantity{Int64}}}
    [Polygon{T}(reinterpret(Point{T}, points(p))) for p in A]
end

"""
    offset{S<:Coordinate}(s::AbstractPolygon{S}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
    offset{S<:AbstractPolygon}(subject::AbstractVector{S}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
    offset{S<:Polygon}(s::AbstractVector{S}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
Using the [`Clipper`](http://www.angusj.com/delphi/clipper.php) library and
the [`Clipper.jl`](https://github.com/Voxel8/Clipper.jl) wrapper, perform
polygon offsetting.

The first argument should be an [`AbstractPolygon`](@ref). The second argument
is how much to offset the polygon. Keyword arguments include a
[join type](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/JoinType.htm):

- `Clipper.JoinTypeMiter`
- `Clipper.JoinTypeRound`
- `Clipper.JoinTypeSquare`

and also an
[end type](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/EndType.htm):

- `Clipper.EndTypeClosedPolygon`
- `Clipper.EndTypeClosedLine`
- `Clipper.EndTypeOpenSquare`
- `Clipper.EndTypeOpenRound`
- `Clipper.EndTypeOpenButt`
"""
function offset end

function offset(s::AbstractPolygon{T}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon) where {T <: Coordinate}
    dimension(T) != dimension(delta) && throw(Unitful.DimensionError(oneunit(T), delta))
    S = promote_type(T, typeof(delta))
    offset(Polygon{S}[s], convert(S, delta); j=j, e=e)
end

function offset(s::AbstractVector{A}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon) where {T, A <: AbstractPolygon{T}}
    dimension(T) != dimension(delta) && throw(Unitful.DimensionError(oneunit(T), delta))
    S = promote_type(T, typeof(delta))
    offset(convert(Vector{Polygon{S}}, s), convert(S, delta); j=j, e=e)
end

prescaledelta(x::Real) = x * SCALE
prescaledelta(x::Integer) = x
prescaledelta(x::Length{<:Real}) = convert(typeof(USCALE), x)
prescaledelta(x::Length{<:Integer}) = x

function offset(s::AbstractVector{Polygon{T}}, delta::T;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon) where {T <: Coordinate}

    sc = clipperize(s)
    d = prescaledelta(delta)
    polys = _offset(sc, d, j=j, e=e)
    declipperize(polys, T)
end

function add_path!(c::Clipper.ClipperOffset, path::Vector{Point{T}},
        joinType::Clipper.JoinType, endType::Clipper.EndType) where {T<:Union{Int64, Unitful.Quantity{Int64}}}
    ccall((:add_offset_path, cclipper), Cvoid, (Ptr{Cvoid}, Ptr{Clipper.IntPoint}, Csize_t, Cint, Cint),
          c.clipper_ptr,
          path,
          length(path),
          Int(joinType),
          Int(endType))
end

function _offset(s::AbstractVector{Polygon{T}}, delta;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon) where
        {T <: Union{Int64, Unitful.Quantity{Int64}}}

    c = coffset()
    Clipper.clear!(c)
    for s0 in s
        add_path!(c, s0.p, j, e)
    end
    result = Clipper.execute(c, Float64(ustrip(delta))) #TODO: fix in clipper
    [Polygon(reinterpret(Point{T}, p)) for p in result]
end

### cutting algorithm

abstract type D1{T} end
Δy(d1::D1) = d1.p1.y - d1.p0.y
Δx(d1::D1) = d1.p1.x - d1.p0.x

ab(p0, p1) = Point(gety(p1)-gety(p0), getx(p0)-getx(p1))

"""
    LineSegment{T} <: D1{T}
Represents a line segment. By construction, `p0.x <= p1.x`.
"""
struct LineSegment{T} <: D1{T}
    p0::Point{T}
    p1::Point{T}
    function LineSegment(p0::Point{T}, p1::Point{T}) where T
        if p1.x < p0.x
            return new{T}(p1, p0)
        else
            return new{T}(p0, p1)
        end
    end
end
LineSegment(p0::Point{S}, p1::Point{T}) where {S,T} = LineSegment(promote(p0, p1)...)

"""
    Ray{T} <: D1{T}
Represents a ray. The ray starts at `p0` and goes toward `p1`.
"""
struct Ray{T} <: D1{T}
    p0::Point{T}
    p1::Point{T}
end
Ray(p0::Point{S}, p1::Point{T}) where {S,T} = Ray(promote(p0, p1)...)

struct Line{T} <: D1{T}
    p0::Point{T}
    p1::Point{T}
end
Line(p0::Point{S}, p1::Point{T}) where {S,T} = Line(promote(p0, p1)...)
Line(seg::LineSegment) = Line(seg.p0, seg.p1)

Base.promote_rule(::Type{Line{S}}, ::Type{Line{T}}) where {S,T} = Line{promote_type(S,T)}
Base.convert(::Type{Line{S}}, L::Line) where S = Line{S}(L.p0, L.p1)

"""
    segmentize(vertices, closed=true)
Make an array of `LineSegment` out of an array of points. If `closed`, a segment should go
between the first and last point, otherwise nah.
"""
function segmentize(vertices, closed=true)
    l = length(vertices)
    if closed
        return [LineSegment(vertices[i], vertices[i==l ? 1 : i+1]) for i = 1:l]
    else
        return [LineSegment(vertices[i], vertices[i+1]) for i = 1:(l-1)]
    end
end

"""
    uniqueray(v::Vector{Point{T}}) where {T <: Real}
Given an array of points (thought to indicate a polygon or a hole in a polygon),
find the lowest / most negative y-coordinate[s] `miny`, then the lowest / most negative
x-coordinate `minx` of the points having that y-coordinate. This `Point(minx,miny)` ∈ `v`.
Return a ray pointing in -ŷ direction from that point.
"""
function uniqueray(v::Vector{Point{T}}) where {T <: Real}
    nopts = reinterpret(T, v)
    yarr = view(nopts, 2:2:length(nopts))
    miny, indy = findmin(yarr)
    xarr = view(nopts, (findall(x->x==miny, yarr).*2).-1)
    minx, indx = findmin(xarr)
    Ray(Point(minx, miny), Point(minx, miny-1))
end

"""
    orientation(p::Polygon)
Returns 1 if the points in the polygon contour are going counter-clockwise, -1 if clockwise.
Clipper considers clockwise-oriented polygons to be holes for some polygon fill types.
"""
function orientation(p::Polygon)
    ccall((:orientation, cclipper), Cuchar, (Ptr{Clipper.IntPoint}, Csize_t),
        reinterpret(Clipper.IntPoint, p.p),length(p.p)) == 1 ? 1 : -1
end

"""
    ishole(p::Polygon)
Returns `true` if Clipper would consider this polygon to be a hole, for applicable
polygon fill rules.
"""
ishole(p::Polygon) = orientation(p) == -1

"""
    orientation(p1::Point, p2::Point, p3::Point)
Returns 1 if the path `p1`--`p2`--`p3` is going counter-clockwise (increasing angle),
-1 if the path is going clockwise (decreasing angle), 0 if `p1`, `p2`, `p3` are colinear.
"""
function orientation(p1::Point, p2::Point, p3::Point)
    return sign((p3.y-p2.y)*(p2.x-p1.x)-(p2.y-p1.y)*(p3.x-p2.x))
end

isparallel(A::D1, B::D1) = Δy(A) * Δx(B) == Δy(B) * Δx(A)
isdegenerate(A::D1, B::D1) =
    orientation(A.p0, A.p1, B.p0) == orientation(A.p0, A.p1, B.p1) == 0
iscolinear(A::D1, B::Point) = orientation(A.p0, A.p1, B) == orientation(B, A.p1, A.p0) == 0
iscolinear(A::Point, B::D1) = iscolinear(B, A)

"""
    intersects(A::LineSegment, B::LineSegment)
Returns two `Bool`s:
1) Does `A` intersect `B`?
2) Did an intersection happen at a single point? (`false` if no intersection)
"""
function intersects(A::LineSegment, B::LineSegment)
    sb0 = orientation(A.p0, A.p1, B.p0)
    sb1 = orientation(A.p0, A.p1, B.p1)
    sb = sb0 == sb1

    sa0 = orientation(B.p0, B.p1, A.p0)
    sa1 = orientation(B.p0, B.p1, A.p1)
    sa = sa0 == sa1

    if sa == false && sb == false
        return true, true
    else
        # Test for special case of colinearity
        if sb0 == sb1 == sa0 == sa1 == 0
            xinter = intersect(A.p0.x..A.p1.x, B.p0.x..B.p1.x)
            yinter = intersect(A.p0.y..A.p1.y, B.p0.y..B.p1.y)
            if !isempty(xinter) && !isempty(yinter)
                if reduce(==, endpoints(xinter)) && reduce(==, endpoints(yinter))
                    return true, true
                else
                    return true, false
                end
            else
                return false, false
            end
        else
            return false, false
        end
    end
end

"""
    intersects_at_endpoint(A::LineSegment, B::LineSegment)
Returns three `Bool`s:
1) Does `A` intersect `B`?
2) Did an intersection happen at a single point? (`false` if no intersection)
3) Did an endpoint of `A` intersect an endpoint of `B`?
"""
function intersects_at_endpoint(A::LineSegment, B::LineSegment)
    A_intersects_B, atapoint = intersects(A,B)
    if A_intersects_B
        if atapoint
            if (A.p1 == B.p0) || (A.p1 == B.p1) || (A.p0 == B.p0) || (A.p0 == B.p1)
                return A_intersects_B, atapoint, true
            else
                return A_intersects_B, atapoint, false
            end
        else
            return A_intersects_B, atapoint, false
        end
    else
        return A_intersects_B, atapoint, false
    end
end

"""
    intersects(p::Point, A::Ray)
Does `p` intersect `A`?
"""
function intersects(p::Point, A::Ray)
    correctdir = dot(A.p1-A.p0, p-A.p0) >= 0
    return iscolinear(p, A) && correctdir
end

"""
    intersects(p::Point, A::LineSegment)
Does `p` intersect `A`?
"""
function intersects(p::Point, A::LineSegment)
    if iscolinear(p, A)
        xinter = intersect(A.p0.x..A.p1.x, p.x..p.x)
        yinter = intersect(A.p0.y..A.p1.y, p.y..p.y)
        if !isempty(xinter) && !isempty(yinter)
           return true
        else
           return false
        end
    else
        return false
    end
end

function intersection(A::Ray, B::LineSegment)
    if isparallel(A, B)
        if isdegenerate(A, B)
            # correct direction?
            dist0 = dot(A.p1-A.p0, B.p0-A.p0)
            dist1 = dot(A.p1-A.p0, B.p1-A.p0)
            if dist0 >= 0
                if dist1 >= 0
                    # Both in correct direction
                    return true, Point{Float64}(min(dist0, dist1) == dist0 ? B.p0 : B.p1)
                else
                    return true, Point{Float64}(B.p0)
                end
            else
                if dist1 >= 0
                    return true, Point{Float64}(B.p1)
                else
                    # Neither in correct direction
                    return false, Point(0.,0.)
                end
            end
        else
            # no intersection
            return false, Point(0.,0.)
        end
    else
        tf, w = intersection(Line(A.p0,A.p1), Line(B.p0,B.p1), false)
        if intersects(w, A) && intersects(w, B)
            return true, w
        else
            return false, Point(0.,0.)
        end
    end
end

function intersection(A::Line{T}, B::Line{T}, checkparallel=true) where T
    if checkparallel
        # parallel checking goes here!
    else
        u = A.p1 - A.p0
        v = B.p1 - B.p0
        w = A.p0 - B.p0
        vp = Point{float(T)}(-v.y, v.x)     # need float or hit overflow

        i = dot(-vp, w) / dot(vp, u)
        return true, A.p0 + i*u
    end
end

"""
    interiorcuts(nodeortree::Clipper.PolyNode, outpolys::Vector{Polygon{T}}) where {T}
Clipper gives polygons with holes as separate contours. The GDS-II format doesn't support
this. This function makes cuts between the inner/outer contours so that ultimately there
is just one contour with one or more overlapping edges.

Example:
┌────────────┐               ┌────────────┐
│ ┌──┐       │   becomes...  │ ┌──┐       │
│ └──┘  ┌──┐ │               │ ├──┘  ┌──┐ │
│       └──┘ │               │ │     ├──┘ │
└────────────┘               └─┴─────┴────┘
"""
function interiorcuts(nodeortree::Clipper.PolyNode, outpolys::Vector{Polygon{T}}) where {T}
    # Assumes we have first element an enclosing polygon with the rest being holes.
    # We also assume no hole collision.

    minpt = Point(-Inf, -Inf)
    for enclosing in children(nodeortree)
        segs = segmentize(contour(enclosing))
        for hole in children(enclosing)
            # process all the holes.
            interiorcuts(hole, outpolys)

            # Intersect the unique ray with the line segments of the polygon.
            ray = uniqueray(contour(hole))

            # Find nearest intersection of the ray with the enclosing polygon.
            k = -1
            bestwhere = minpt
            for (j,s) in enumerate(segs)
                tf, wh = intersection(ray, s)
                if tf
                    if gety(wh) > gety(bestwhere)
                        bestwhere = wh
                        k = j
                    end
                end
            end

            # Since the polygon was enclosing, an intersection had to happen *somewhere*.
            if k != -1
                w = Point{Int64}(round(getx(bestwhere)), round(gety(bestwhere)))
                kp1 = contour(enclosing)[(k+1 > length(contour(enclosing))) ? 1 : k+1]

                # Make the cut in the enclosing polygon
                enclosing.contour = Point{Int64}[contour(enclosing)[1:k];
                    [w];       # could actually be contour(enclosing)[k]... should check for this.
                    contour(hole);
                    [contour(hole)[1]]; # need to loop back to first point of hole
                    [w];
                    contour(enclosing)[(k+1):end]]

                # update the segment cache
                segs = [segs[1:(k-1)];
                    LineSegment(contour(enclosing)[k], w);
                    LineSegment(w, contour(hole)[1]);
                    segmentize(contour(hole));
                    LineSegment(contour(hole)[1], w);
                    LineSegment(w, kp1);
                    segs[(k+1):end]]
            end
        end
        push!(outpolys, Polygon(reinterpret(Point{T}, contour(enclosing))))
    end
    outpolys
end


end
