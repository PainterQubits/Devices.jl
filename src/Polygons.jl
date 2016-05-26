module Polygons

using PyCall
using ForwardDiff
using AffineTransforms
import Clipper
import Clipper.orientation
using ..Points
using ..Rectangles

import Base: +, -, *, /, minimum, maximum, convert, getindex, start, next, done
import Devices
import Devices: AbstractPolygon
import Devices: bounds
gdspy() = Devices._gdspy
# pyclipper() = Devices._pyclipper

export Polygon
export Plain
export points
export clip, offset

clipper() = Devices._clip
coffset() = Devices._coffset

const PCSCALE = 2^31

"""
```
type Polygon{T<:Real} <: AbstractPolygon{T}
    p::Array{Point{2,T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
end
```

Polygon defined by list of coordinates. The first point should not be repeated
at the end (although this is true for the GDS format).
"""
type Polygon{T<:Real} <: AbstractPolygon{T}
    p::Array{Point{2,T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
end

"""
```
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.
"""
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}; kwargs...) =
    Polygon{T}(parr, Dict{Symbol,Any}(kwargs))

"""
```
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}, dict)
```

Convenience constructor for a `Polygon{T}` object.
"""
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}, dict) =
    Polygon{T}(parr, dict)

"""
```
Polygon{T<:Real}(p0::Point{2,T}, p1::Point{2,T}, p2::Point{2,T},
    p3::Point{2,T}...; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.
"""
Polygon{T<:Real}(p0::Point{2,T}, p1::Point{2,T}, p2::Point{2,T},
    p3::Point{2,T}...; kwargs...) =
        Polygon{T}([p0, p1, p2, p3...], Dict{Symbol,Any}(kwargs))

"""
```
points(x::Polygon)
```

Returns the array of `Point` objects defining the polygon.
"""
points(x::Polygon) = x.p

"""
```
points{T<:Real}(x::Rectangle{T})
```

Returns the array of `Point` objects defining the rectangle.
"""
points{T<:Real}(x::Rectangle{T}) = points(convert(Polygon{T}, x))

for (op, dotop) in [(:+, :.+), (:-, :.-)]
    @eval function ($op)(r::Polygon, p::Point)
        Polygon(($dotop)(r.p, p), r.properties)
    end
    # @eval ($op)(p::Point, r::Polygon) = ($op)(r,p)
end
*(r::Polygon, a::Real) = Polygon(r.p .* a, r.properties)
*(a::Real, r::Polygon) = *(r,a)
/(r::Polygon, a::Real) = Polygon(r.p ./ a, r.properties)

"""
```
minimum(x::Polygon)
```

Return the lower-left-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
minimum(x::Polygon) = minimum(x.p)

"""
```
maximum(x::Polygon)
```

Return the upper-right-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
maximum(x::Polygon) = maximum(x.p)

function *(a::AffineTransform, x::Polygon)
    Polygon(map(x->Point(a*Array(x)), x.p), x.properties)
end

function *(a::AffineTransform, x::Rectangle)
    Rectangle(Point(a*Array(x.ll)),Point(a*Array(x.ur)),x.properties)
end

"""
```
convert{T<:Real}(::Type{Polygon{T}}, s::Rectangle)
```

Convert a Rectangle into a Polygon (explicitly keep all points).
"""
function convert{T<:Real}(::Type{Polygon{T}}, s::Rectangle)
    ll = convert(Point{2,T}, s.ll)
    ur = convert(Point{2,T}, s.ur)
    lr = Point(T(getx(ur)), T(gety(ll)))
    ul = Point(T(getx(ll)), T(gety(ur)))
    Polygon{T}(Point{2,T}[ll,lr,ur,ul], s.properties)
end

"""
```
convert{T<:Real}(::Type{Polygon{T}}, p::Polygon)
```

Convert between types of polygons.
"""
function convert{T<:Real}(::Type{Polygon{T}}, p::Polygon)
    Polygon{T}(convert(Array{Point{2,T},1}, p.p), p.properties)
end

"""
```
bounds(p::Polygon)
```

Return a bounding Rectangle with no properties for polygon `p`.
"""
bounds(p::Polygon) = Rectangle(minimum(p), maximum(p))

"""
```
bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
```

Return a bounding `Rectangle` with no properties for an array `parr` of
`AbstractPolygon` objects.
"""
function bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
    rects = map(bounds, parr)
    ll = minimum(map(minimum, rects))
    ur = maximum(map(maximum, rects))
    Rectangle(ll, ur)
end

"""
```
bounds(p0::AbstractPolygon, p::AbstractPolygon...)
```

Return a bounding `Rectangle` with no properties for several `AbstractPolygon`
objects.
"""
bounds(p0::AbstractPolygon, p::AbstractPolygon...) = bounds([p0, p...])

"How to draw the polygon..."
abstract Style

"Simple solid polygon."
type Plain <: Style end

function clip(op::Clipper.ClipType, subject::Polygon{Int64}, cl::Polygon{Int64})
    c = clipper()
    Clipper.clear!(c)
    Clipper.add_path!(c, reinterpret(Clipper.IntPoint, subject.p),
        Clipper.PolyTypeSubject, true)
    Clipper.add_path!(c, reinterpret(Clipper.IntPoint, cl.p),
        Clipper.PolyTypeClip, true)
    result = Clipper.execute(c, op,
        Clipper.PolyFillTypeEvenOdd, Clipper.PolyFillTypeEvenOdd)
    result2 = map(x->Polygon{Int64}(reinterpret(Point{2,Int64}, x),
        copy(subject.properties)), result[2])
    interiorcuts(result2)
end

function clip{S<:Real, T<:Real}(op::Clipper.ClipType, subject::Polygon{S}, cl::Polygon{T})
    s = Polygon{Int64}(map(trunc, subject.p .* PCSCALE), subject.properties)::Polygon{Int64}
    c = Polygon{Int64}(map(trunc, cl.p .* PCSCALE), cl.properties)::Polygon{Int64}
    polys = clip(op, s, c)


    [Polygon{S}(convert(Array{Point{2,S},1}, p.p) ./ PCSCALE, p.properties)
        for p in polys]
end

clip{S<:Real, T<:Real}(op::Clipper.ClipType, s::AbstractPolygon{S}, c::AbstractPolygon{T}) =
    clip(op, convert(Polygon{S}, s), convert(Polygon{T}, c))

function offset{S<:Real}(subject::Polygon{S}, delta::Real,
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    s = Polygon{Int64}(map(trunc, subject.p .* PCSCALE), subject.properties)
    polys = offset(s, delta * PCSCALE, j, e)
    [Polygon{S}(convert(Array{Point{2,S},1}, p.p) ./ PCSCALE, p.properties)
        for p in polys]
end

function offset(subject::Polygon{Int64}, delta::Real,
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    c = coffset()
    Clipper.clear!(c)
    Clipper.add_path!(c, reinterpret(Clipper.IntPoint, subject.p), j, e)
    result = Clipper.execute(c, Float64(delta))
    result2 = map(x->Polygon{Int64}(reinterpret(Point{2,Int64}, x),
        subject.properties), result)
    result2
end

offset{S<:Real}(s::AbstractPolygon{S}, delta::Real,
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon) =
    offset(convert(Polygon{S}, s), delta, j, e)

### cutting algorithm

abstract D1

ab(p0, p1) = Point(gety(p1)-gety(p0), getx(p0)-getx(p1))

immutable Segment <: D1
    p0::Point{2,Float64}
    p1::Point{2,Float64}
    ab::Point{2,Float64}
end
Segment(p0,p1) = Segment(p0, p1, ab(p0, p1))

immutable Ray <: D1
    p0::Point{2,Float64}
    p1::Point{2,Float64}
    ab::Point{2,Float64}
end
Ray(p0,p1) = Ray(p0, p1, ab(p0, p1))

immutable Line <: D1
    p0::Point{2,Float64}
    p1::Point{2,Float64}
    ab::Point{2,Float64}
end
Line(p0,p1) = Line(p0, p1, ab(p0, p1))

function segments(poly::Polygon)
    l = length(poly.p)
    [Segment(poly.p[i], poly.p[i==l ? 1 : i+1]) for i = 1:l]
end

# Find the lower-most then left-most polygon
function uniqueray{T<:Real}(poly::Polygon{T})
    nopts = reinterpret(T, poly.p)
    yarr = slice(nopts, 2:2:length(nopts))
    miny, indy = findmin(yarr)
    xarr = slice(nopts, find(x->x==miny, yarr))
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

function onray{T<:Real}(p::Point{2,T}, A::Ray)
    return (dot(A.ab, p-A.p0) ≈ 0) &&
        (dot(A.p1-A.p0, p-A.p0) >= 0)
end

function onsegment{T<:Real}(p::Point{2,T}, A::Segment)
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
                    return true, Point{2,Float64}(min(dist0, dist1) == dist0 ? B.p0 : B.p1)
                else
                    return true, Point{2,Float64}(B.p0)
                end
            else
                if dist1 >= 0
                    return true, Point{2,Float64}(B.p1)
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

function interiorcuts(polys::AbstractArray{Polygon{Int64},1})
    # currently assumes we have first element an enclosing polygon with
    # the rest being holes

    # we also assume no hole collision

    outpolys = Polygon{Int64}[]

    outer = find(x->!ishole(x), polys)
    inner = find(x->ishole(x), polys)
    minpt = Point(-Inf, -Inf)

    for enclosing in slice(polys, outer)
        segs = segments(enclosing)
        for (i,p) in enumerate(slice(polys, inner))
            # For each hole
            if ishole(p)
                # Intersect the unique ray with the line segments of the polygon.
                ray = uniqueray(p)

                # Find nearest intersection of the ray with the enclosing polygon.
                k = -1
                bestwhere = minpt
                for (j,s) in enumerate(segs)
                    # if intersects(ray, s)     # should be implemented later for speed
                        tf, where = intersection(ray, s)
                        if tf
                            if gety(where) > gety(bestwhere)
                                bestwhere = where
                                k = j
                            end
                        end
                    # end
                end
                # Since the polygon was enclosing, an intersection had to happen *somewhere*.

                if k != -1
                    w = Point{2,Int64}(round(getx(bestwhere)), round(gety(bestwhere)))

                    # Make the cut in the enclosing polygon
                    enclosing.p = [enclosing.p[1:k];
                        w;
                        p.p;
                        p.p[1];     # need to loop back to first point of hole
                        w;
                        enclosing.p[k+1:end]]

                    # update the segment cache
                    segs = [segs[1:k-1];
                        Segment(enclosing.p[k], w);
                        Segment(w, p.p[1]);
                        segments(p);
                        Segment(p.p[1], w);
                        Segment(w, enclosing.p[k+1 > length(enclosing.p) ? 1 : k+1]);
                        segs[k+1:end]]
                end
            end
        end
        push!(outpolys, enclosing)
    end
    outpolys
end

end
