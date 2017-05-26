module Polygons

import Base: +, -, *, .*, /, ==, .+, .-, isapprox
import Base: convert, getindex, start, next, done
import Base: copy, promote_rule

using Compat
using ForwardDiff
import CoordinateTransformations: AffineMap, LinearMap, Translation
import Clipper
import Clipper: orientation, children, contour
import StaticArrays

import Devices
import Devices: AbstractPolygon, Coordinate, GDSMeta, Meta
import Devices: bounds, lowerleft, upperright
import Unitful
import Unitful: Length, dimension, unit, ustrip, uconvert
using ..Points
using ..Rectangles

export Polygon
export points
export clip, offset

clipper() = Devices._clip
coffset() = Devices._coffset

@inline unsafe_round(x::Unitful.Quantity) = round(ustrip(x))*unit(x)
@inline unsafe_round(x::Number) = round(x)

const PCSCALE = float(2^31)

"""
```
immutable Polygon{T} <: AbstractPolygon{T}
    p::Vector{Point{T}}
    Polygon(x) = new(x)
    Polygon(x::AbstractPolygon) = convert(Polygon{T}, x)
end
```

Polygon defined by list of coordinates. The first point should not be repeated
at the end (although this is true for the GDS format).
"""
immutable Polygon{T} <: AbstractPolygon{T}
    p::Vector{Point{T}}
    Polygon(x) = new(x)
    Polygon(x::AbstractPolygon) = convert(Polygon{T}, x)
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
Polygon{T}(parr::AbstractVector{Point{T}}) = Polygon{T}(parr)

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
points{T}(x::Rectangle{T}) = points(convert(Polygon{T}, x))

for (op, dotop) in [(:+, :.+), (:-, :.-)]
    @eval function ($op)(r::Polygon, p::Point)
        Polygon(($dotop)(r.p, p))
    end
    @eval @compat function ($op)(r::Polygon, p::StaticArrays.Scalar{<:Point})
        Polygon(($dotop)(r.p, p))
    end
    @eval function ($op)(p::Point, r::Polygon)
        Polygon(($dotop)(p, r.p))
    end
    @eval @compat function ($op)(p::StaticArrays.Scalar{<:Point}, r::Polygon)
        Polygon(($dotop)(p, r.p))
    end
    if VERSION < v"0.6.0-pre"
        @eval function ($dotop){T<:AbstractPolygon}(r::AbstractArray{T}, p::Point)
            map(x->($op)(x, p), r)
        end
        @eval function ($dotop){T<:AbstractPolygon}(p::Point, r::AbstractArray{T})
            map(x->($op)(p, x), r)
        end
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
lowerleft(::Polygon)

"""
    upperright(x::Polygon)
Return the upper-right-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
upperright(x::Polygon)

if VERSION < v"0.6.0-"
    lowerleft(x::Polygon) = Point(reduce(min, x.p))
    upperright(x::Polygon) = Point(reduce(max, x.p))
else
    lowerleft(x::Polygon) = lowerleft(x.p)
    upperright(x::Polygon) = upperright(x.p)
end

for T in (:LinearMap, :AffineMap)
    @eval (f::$T)(x::Polygon) = Polygon(f.(x.p))
    @eval (f::$T)(x::Rectangle) = f(convert(Polygon, x))
end

(f::Translation)(x::Polygon) = Polygon(f.(x.p))
(f::Translation)(x::Rectangle) = Rectangle(f(x.ll), f(x.ur))

function convert{T}(::Type{Polygon{T}}, s::Rectangle)
    ll = convert(Point{T}, s.ll)
    ur = convert(Point{T}, s.ur)
    lr = Point(T(getx(ur)), T(gety(ll)))
    ul = Point(T(getx(ll)), T(gety(ur)))
    Polygon{T}(Point{T}[ll,lr,ur,ul])
end
convert{T}(::Type{Polygon}, s::Rectangle{T}) = convert(Polygon{T}, s)
convert{T}(::Type{AbstractPolygon{T}}, s::Rectangle) = convert(Rectangle{T}, s)
function convert{T}(::Type{Polygon{T}}, p::Polygon)
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
function bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
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

@compat abstract type Style{T<:Meta} end

"""
    immutable Plain{T} <: Polygons.Style{T}
        meta::T
    end
Plain polygon style.
"""
immutable Plain{T} <: Style{T}
    meta::T
end
Plain() = Plain(GDSMeta())

# Polygon promotion.
for X in (:Real, :Length)
    @eval promote_rule{S<:$X,T<:$X}(::Type{Polygon{S}}, ::Type{Polygon{T}}) =
        Polygon{promote_type(S,T)}
    @eval promote_rule{S<:$X,T<:$X}(::Type{Rectangle{S}}, ::Type{Polygon{T}}) =
        Polygon{promote_type(S,T)}
    @eval promote_rule{S<:$X,T<:$X}(::Type{Rectangle{S}}, ::Type{Rectangle{T}}) =
        Rectangle{promote_type(S,T)}
end

# Clipping polygons one at a time
"""
```
clip{S<:Coordinate, T<:Coordinate}(op::Clipper.ClipType,
    s::AbstractPolygon{S}, c::AbstractPolygon{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
```

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
function clip{S<:Coordinate, T<:Coordinate}(op::Clipper.ClipType,
        s::AbstractPolygon{S}, c::AbstractPolygon{T};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)

    dimension(S) != dimension(T) && throw(Unitful.DimensionError(S(1),T(1)))
    R = promote_type(S, T)
    clip(op, Polygon{R}[s], Polygon{R}[c]; pfs=pfs, pfc=pfc)
end

# Clipping arrays of AbstractPolygons
"""
```
clip{S<:AbstractPolygon, T<:AbstractPolygon}(op::Clipper.ClipType,
    s::AbstractVector{S}, c::AbstractVector{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
```

Perform polygon clipping. The first argument must be as listed above.
The second and third arguments are arrays (vectors) of [`AbstractPolygon`](@ref)s.
Keyword arguments are explained above.
"""
function clip{S<:AbstractPolygon, T<:AbstractPolygon}(op::Clipper.ClipType,
    s::AbstractVector{S}, c::AbstractVector{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)

    P = promote_type(eltype(eltype(s)), eltype(eltype(c)))
    clip(op, convert(Vector{Polygon{P}}, s),
              convert(Vector{Polygon{P}}, c); pfs=pfs, pfc=pfc)
end

# Clipping two identically-typed arrays of <: Polygon
"""
```
clip{T<:Polygon}(op::Clipper.ClipType,
    s::AbstractVector{T}, c::AbstractVector{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)
```

Perform polygon clipping. The first argument must be as listed above.
The second and third arguments are identically-typed arrays (vectors) of
[`Polygon{T}`](@ref) objects. Keyword arguments are explained above.
"""
function clip{T<:Polygon}(op::Clipper.ClipType,
    s::AbstractVector{T}, c::AbstractVector{T};
    pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
    pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)

    S,C = clipperize(s), clipperize(c)
    polys = _clip(op, S, C; pfs=pfs, pfc=pfc)
    declipperize(polys, eltype(T))
end

# Clipping two identically-typed arrays of "Int64-based" Polygons.
# Internal method which should not be called by user (but does the heavy lifting)
function _clip{T<:Union{Int64, Unitful.Quantity{Int64}}}(op::Clipper.ClipType,
        subject::AbstractVector{Polygon{T}},
        cl::AbstractVector{Polygon{T}}=Polygon{T}[];
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)

    c = clipper()
    Clipper.clear!(c)
    for s0 in subject
        Clipper.add_path!(c, reinterpret(Clipper.IntPoint, s0.p),
            Clipper.PolyTypeSubject, true)
    end
    for c0 in cl
        Clipper.add_path!(c, reinterpret(Clipper.IntPoint, c0.p),
            Clipper.PolyTypeClip, true)
    end
    result = convert(Clipper.PolyNode{Point{Int}},
        Clipper.execute_pt(c, op, pfs, pfc)[2])

    polys = interiorcuts(result, Polygon{T}[])
end

# Clipperize methods prepare an array for being operated upon by the Clipper lib
function clipperize{T<:Polygon}(A::AbstractVector{T})
    Int64like{T}(x::Point{T}) = convert(Point{typeof(1::Int64*unit(T))},x)
    [Polygon(Int64like.([unsafe_round.(y) for y in (points(Polygon(x)) .* PCSCALE)]))
        for x in A]
end
clipperize{T<:Union{Int64, Unitful.Quantity{Int64}}}(
    A::AbstractVector{Polygon{T}}) = A

# Declipperize methods are used to get back to the original type.
function declipperize(A, T)
    united(p) = reinterpret(Point{typeof(1*unit(T))}, p.p)
    [Polygon{T}(convert(Vector{Point{T}}, united(p)) ./ PCSCALE) for p in A]
end
function declipperize{T<:Union{Int64, Unitful.Quantity{Int64}}}(A, S::Type{T})
    [Polygon{T}(reinterpret(Point{typeof(1*unit(T))}, p.p)) for p in A]
end

"""
```
offset{S<:Coordinate}(s::AbstractPolygon{S}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
```

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
function offset{S<:Coordinate}(s::AbstractPolygon{S}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    offset(Polygon{S}[s], delta; j=j, e=e)
end

"""
```
offset{S<:AbstractPolygon}(subject::AbstractVector{S}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
```

Perform polygon offsetting. The first argument is an array (vector) of
[`AbstractPolygon`](@ref)s. The second argument is how much to offset the polygon.
Keyword arguments explained above.
"""
function offset{S<:AbstractPolygon}(s::AbstractVector{S}, delta::Coordinate;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    offset(convert(Vector{Polygon{eltype(S)}}, s), delta; j=j, e=e)
end

"""
```
offset{S<:Polygon}(s::AbstractVector{S}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)
```

Perform polygon offsetting. The first argument is an array (vector) of
[`Polygon`](@ref)s. The second argument is how much to offset the polygon.
Keyword arguments explained above.
"""
function offset{T<:Polygon}(s::AbstractVector{T}, delta::Coordinate;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    dimension(eltype(T)) != dimension(delta) && throw(Unitful.DimensionError(eltype(T)(1),delta))
    S = clipperize(s)
    d = if eltype(T) <: Union{Int64, Unitful.Quantity{Int64}}
        ustrip(uconvert(unit(eltype(T)), delta))
    else
        ustrip(uconvert(unit(eltype(T)), delta) * PCSCALE)
    end
    polys = _offset(S, d, j=j, e=e)
    declipperize(polys, eltype(T))
end

function _offset{T<:Union{Int64, Unitful.Quantity{Int64}}}(
        s::AbstractVector{Polygon{T}}, delta;
        j::Clipper.JoinType=Clipper.JoinTypeMiter,
        e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    c = coffset()
    Clipper.clear!(c)
    for s0 in s
        Clipper.add_path!(c, reinterpret(Clipper.IntPoint, s0.p), j, e)
    end
    result = Clipper.execute(c, Float64(delta)) #TODO: fix in clipper
    [Polygon(reinterpret(Point{Int64}, p)) for p in result]
end

### cutting algorithm

@compat abstract type D1 end

ab(p0, p1) = Point(gety(p1)-gety(p0), getx(p0)-getx(p1))

immutable Segment <: D1
    p0::Point{Float64}
    p1::Point{Float64}
    ab::Point{Float64}
end
Segment(p0,p1) = Segment(p0, p1, ab(p0, p1))

immutable Ray <: D1
    p0::Point{Float64}
    p1::Point{Float64}
    ab::Point{Float64}
end
Ray(p0,p1) = Ray(p0, p1, ab(p0, p1))

immutable Line <: D1
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
function uniqueray{T<:Real}(v::Vector{Point{T}})
    nopts = reinterpret(T, v)
    yarr = view(nopts, 2:2:length(nopts))
    miny, indy = findmin(yarr)
    xarr = view(nopts, (find(x->x==miny, yarr).*2).-1)
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

function onray{T<:Real}(p::Point{T}, A::Ray)
    return (dot(A.ab, p-A.p0) ≈ 0) &&
        (dot(A.p1-A.p0, p-A.p0) >= 0)
end

function onsegment{T<:Real}(p::Point{T}, A::Segment)
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

function interiorcuts{T}(nodeortree::Clipper.PolyNode, outpolys::Vector{Polygon{T}})
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
