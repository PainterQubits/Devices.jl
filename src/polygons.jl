module Polygons

using LinearAlgebra

import Base: +, -, *, .*, /, ==, .+, .-, isapprox
import Base: convert, getindex, start, next, done
import Base: copy, promote_rule

using ForwardDiff
import CoordinateTransformations: AffineMap, LinearMap, Translation
import Clipper
import Clipper: orientation, children, contour
import StaticArrays

import Devices
import Devices: AbstractPolygon, Coordinate, GDSMeta, Meta
import Devices: bounds, lowerleft, upperright
import Unitful
import Unitful: Quantity, Length, dimension, unit, ustrip, uconvert, °
using ..Points
using ..Rectangles
using ..cclipper

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
    bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
Return a bounding `Rectangle` for an array `parr` of `AbstractPolygon` objects.
"""
function bounds(parr::AbstractArray{T}) where {T <: AbstractPolygon}
    rects = map(bounds, parr)
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
    ccall((:add_path, cclipper), Cuchar, (Ptr{Void}, Ptr{Clipper.IntPoint}, Csize_t, Cint, Cuchar),
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
    ccall((:add_offset_path, cclipper), Void, (Ptr{Void}, Ptr{Clipper.IntPoint}, Csize_t, Cint, Cint),
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

abstract type D1 end

ab(p0, p1) = Point(gety(p1)-gety(p0), getx(p0)-getx(p1))

struct Segment <: D1
    p0::Point{Float64}
    p1::Point{Float64}
    ab::Point{Float64}
end
Segment(p0,p1) = Segment(p0, p1, ab(p0, p1))

struct Ray <: D1
    p0::Point{Float64}
    p1::Point{Float64}
    ab::Point{Float64}
end
Ray(p0,p1) = Ray(p0, p1, ab(p0, p1))

struct Line <: D1
    p0::Point{Float64}
    p1::Point{Float64}
    ab::Point{Float64}
end
Line(p0,p1) = Line(p0, p1, ab(p0, p1))

function segments(vertices)
    l = length(vertices)
    [Segment(vertices[i], vertices[i==l ? 1 : i+1]) for i = 1:l]
end

# Find the lower-most then left-most polygon
function uniqueray(v::Vector{Point{T}}) where {T <: Real}
    nopts = reinterpret(T, v)
    yarr = view(nopts, 2:2:length(nopts))
    miny, indy = findmin(yarr)
    xarr = view(nopts, (findall(x->x==miny, yarr).*2).-1)
    minx, indx = findmin(xarr)
    Ray(Point(minx,miny), Point(minx, miny-1))
end

orientation(p::Polygon) = orientation(reinterpret(Clipper.IntPoint, p.p))

ishole(p) = orientation(p) == false
isparallel(A::D1, B::D1) = getx(A.ab) * gety(B.ab) == getx(B.ab) * gety(A.ab)
isdegenerate(A::D1, B::D1) = dot(A.ab, B.p0-A.p0) == dot(A.ab, B.p1-A.p0) == 0

# Expected to be fast
function intersects(A::Segment, B::Segment)
    sb0 = sign(dot(A.ab, B.p0-A.p0))
    sb1 = sign(dot(A.ab, B.p1-A.p0))
    sb = sb0 == sb1

    sa0 = sign(dot(B.ab, A.p0-B.p0))
    sa1 = sign(dot(B.ab, A.p1-B.p0))
    sa = sa0 == sa1

    if sa == false && sb == false
        return true
    else
        return false
    end
end

function onray(p::Point{T}, A::Ray) where {T <: Real}
    return (dot(A.ab, p-A.p0) ≈ 0) &&
        (dot(A.p1-A.p0, p-A.p0) >= 0)
end

function onsegment(p::Point{T}, A::Segment) where {T <: Real}
    return (dot(A.ab, p-A.p0) ≈ 0) &&
        (dot(A.p1-A.p0, p-A.p0) >= 0) &&
        (dot(A.p0-A.p1, p-A.p1) >= 0)
end

# Not type stable...
function intersection(A::Ray, B::Segment)
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
        tf, where = intersection(Line(A.p0,A.p1,A.ab), Line(B.p0,B.p1,B.ab), false)
        if onray(where, A) && onsegment(where, B)
            return true, where
        else
            return false, Point(0.,0.)
        end
    end
end

function intersection(A::Line, B::Line, checkparallel=true)
    if checkparallel
        # parallel checking goes here!
    else
        w = [getx(A.ab) gety(A.ab); getx(B.ab) gety(B.ab)] \ [dot(A.ab, A.p0), dot(B.ab, B.p0)]
        true, Point(w)
    end
end

function interiorcuts(nodeortree::Clipper.PolyNode, outpolys::Vector{Polygon{T}}) where {T}
    # currently assumes we have first element an enclosing polygon with
    # the rest being holes. We don't dig deep into the PolyTree...

    # We also assume no hole collision

    minpt = Point(-Inf, -Inf)

    for enclosing in children(nodeortree)
        segs = segments(contour(enclosing))
        for hole in children(enclosing)
            # Intersect the unique ray with the line segments of the polygon.
            ray = uniqueray(contour(hole))

            # Find nearest intersection of the ray with the enclosing polygon.
            k = -1
            bestwhere = minpt
            for (j,s) in enumerate(segs)
                tf, where = intersection(ray, s)
                if tf
                    if gety(where) > gety(bestwhere)
                        bestwhere = where
                        k = j
                    end
                end
            end

            # println(bestwhere)
            # println(k)
            # println(ray)
            # Since the polygon was enclosing, an intersection had to happen *somewhere*.
            if k != -1
                w = Point{Int64}(round(getx(bestwhere)), round(gety(bestwhere)))
                # println(w)
                kp1 = contour(enclosing)[(k+1 > length(contour(enclosing))) ? 1 : k+1]

                # println(contour(enclosing)[1:k])
                # println(w)
                # println(contour(hole))
                # println(contour(enclosing)[(k+1):end])

                # Make the cut in the enclosing polygon
                enclosing.contour = Point{Int64}[contour(enclosing)[1:k];
                    [w];       # could actually be contour(enclosing)[k]... should check for this.
                    contour(hole);
                    [contour(hole)[1]]; # need to loop back to first point of hole
                    [w];
                    contour(enclosing)[(k+1):end]]

                # update the segment cache
                segs = [segs[1:(k-1)];
                    Segment(contour(enclosing)[k], w);
                    Segment(w, contour(hole)[1]);
                    segments(contour(hole));
                    Segment(contour(hole)[1], w);
                    Segment(w, kp1);
                    segs[(k+1):end]]
            end
        end
        push!(outpolys, Polygon(reinterpret(Point{T}, contour(enclosing))))
    end
    outpolys
end


end
