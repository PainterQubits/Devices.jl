module Polygons

using PyCall
using ForwardDiff
using AffineTransforms
import Clipper
import Clipper.orientation
using ..Points
using ..Rectangles

import Base: +, -, *, .*, /, minimum, maximum, convert, getindex, start, next, done
import Base: copy
import Devices
import Devices: AbstractPolygon
import Devices: bounds
gdspy() = Devices._gdspy
# pyclipper() = Devices._pyclipper

export Polygon
export Plain
export points
export clip, offset
export layer, datatype

clipper() = Devices._clip
coffset() = Devices._coffset

const PCSCALE = 2^31

"""
```
type Polygon{T} <: AbstractPolygon{T}
    p::Array{Point{T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
end
```

Polygon defined by list of coordinates. The first point should not be repeated
at the end (although this is true for the GDS format).
"""
type Polygon{T} <: AbstractPolygon{T}
    p::Array{Point{T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
    Polygon(x::AbstractPolygon) = convert(Polygon{T}, x)
end

"""
```
Polygon(p0::Point, p1::Point, p2::Point, p3::Point...; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.
"""
Polygon(p0::Point, p1::Point, p2::Point, p3::Point...; kwargs...) =
    Polygon([p0, p1, p2, p3...]; kwargs...)

"""
```
Polygon{T}(parr::AbstractArray{Point{T},1}; kwargs...)
```

Convenience constructor for a `Polygon{T}` object.
"""
Polygon{T}(parr::AbstractArray{Point{T},1}; kwargs...) =
    Polygon{T}(parr, Dict{Symbol,Any}(kwargs))

Polygon(parr::AbstractArray{Point,1}; kwargs...) =
    error("Polygon creation failed. Perhaps you mixed units and unitless numbers?")


layer(p::Polygon) = p.properties[:layer]
datatype(p::Polygon) = p.properties[:datatype]
copy(p::Polygon) = Polygon(copy(p.p), copy(p.properties))

"""
```
points(x::Polygon)
```

Returns the array of `Point` objects defining the polygon.
"""
points(x::Polygon) = x.p

"""
```
points{T}(x::Rectangle{T})
```

Returns the array of `Point` objects defining the rectangle.
"""
points{T}(x::Rectangle{T}) = points(convert(Polygon{T}, x))

for (op, dotop) in [(:+, :.+), (:-, :.-)]
    @eval function ($op)(r::Polygon, p::Point)
        Polygon(($dotop)(r.p, p), copy(r.properties))
    end
    # @eval ($op)(p::Point, r::Polygon) = ($op)(r,p)
end
*(r::Polygon, a::Number) = Polygon(r.p .* a, copy(r.properties))
*(a::Number, r::Polygon) = *(r,a)
/(r::Polygon, a::Number) = Polygon(r.p ./ a, copy(r.properties))

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
    Polygon(map(x->Point(a*Array(x)), x.p), copy(x.properties))
end

.*{T<:AbstractPolygon}(a::AffineTransform, x::AbstractArray{T,1}) =
    [a * y for y in x]

function *(a::AffineTransform, x::Rectangle)
    Rectangle(Point(a*Array(x.ll)),Point(a*Array(x.ur)), copy(x.properties))
end

"""
```
convert{T}(::Type{Polygon{T}}, s::Rectangle)
```

Convert a Rectangle into a Polygon (explicitly keep all points).
"""
function convert{T}(::Type{Polygon{T}}, s::Rectangle)
    ll = convert(Point{T}, s.ll)
    ur = convert(Point{T}, s.ur)
    lr = Point(T(getx(ur)), T(gety(ll)))
    ul = Point(T(getx(ll)), T(gety(ur)))
    Polygon{T}(Point{T}[ll,lr,ur,ul], copy(s.properties))
end

"""
```
convert{T}(::Type{Polygon{T}}, p::Polygon)
```

Convert between types of polygons.
"""
function convert{T}(::Type{Polygon{T}}, p::Polygon)
    Polygon{T}(convert(Array{Point{T},1}, p.p), copy(p.properties))
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

clip{S<:Integer}(op::Clipper.ClipType,
        s::AbstractPolygon{S},
        c::AbstractPolygon{S};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) =
    clip(op, Polygon{Int64}[s], Polygon{Int64}[c], pfs=pfs, pfc=pfc)

clip{S<:Real}(op::Clipper.ClipType,
        s::AbstractPolygon{S},
        c::AbstractPolygon{S};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) =
    clip(op, Polygon{S}[s], Polygon{S}[c], pfs=pfs, pfc=pfc)

clip{S<:Real}(op::Clipper.ClipType,
        s::AbstractArray{AbstractPolygon{S},1},
        c::AbstractArray{AbstractPolygon{S},1};
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd) =
    clip(op, [Polygon{S}(x) for x in s]::Array{Polygon{S},1},
        [Polygon{S}(x) for x in c]::Array{Polygon{S},1}, pfs=pfs, pfc=pfc)

function clip{S<:Integer}(op::Clipper.ClipType,
        subject::AbstractArray{Polygon{S},1},
        cl::AbstractArray{Polygon{S},1}=Polygon{S}[];
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)

    s = [Polygon{Int64}(x) for x in subject]::Array{Polygon{Int64},1}
    c = [Polygon{Int64}(x) for x in cl]::Array{Polygon{Int64},1}
    polys = clip(op, s, c, pfs=pfs, pfc=pfc)

    [Polygon{S}(convert(Array{Point{S},1}, p.p) ./ PCSCALE, copy(p.properties))
        for p in polys]::Array{Polygon{S},1}
end

function clip{S<:Real}(op::Clipper.ClipType,
        subject::AbstractArray{Polygon{S},1},
        cl::AbstractArray{Polygon{S},1}=Polygon{S}[];
        pfs::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd,
        pfc::Clipper.PolyFillType=Clipper.PolyFillTypeEvenOdd)

    s = [Polygon{Int64}(map(round, x.p .* PCSCALE), x.properties)
        for x in subject]::Array{Polygon{Int64},1}
    c = [Polygon{Int64}(map(round, x.p .* PCSCALE), x.properties)
        for x in cl]::Array{Polygon{Int64},1}
    polys = clip(op, s, c, pfs=pfs, pfc=pfc)

    [Polygon{S}(convert(Array{Point{S},1}, p.p) ./ PCSCALE, copy(p.properties))
        for p in polys]::Array{Polygon{S},1}
end

function clip(op::Clipper.ClipType,
        subject::AbstractArray{Polygon{Int64},1},
        cl::AbstractArray{Polygon{Int64},1}=Polygon{Int64}[];
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
    result = convert(Clipper.PolyTree{Point{Int64}},
        Clipper.execute_pt(c, op, pfs, pfc)[2])
    # println(result)
    interiorcuts(result, Polygon{Int64}[], subject[1].properties)
end

function offset{S<:Real}(subject::Polygon{S}, delta::Real;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    s = Polygon{Int64}(map(round, subject.p .* PCSCALE), subject.properties)
    polys = offset(s, delta * PCSCALE, j=j, e=e)
    [Polygon{S}(convert(Array{Point{S},1}, p.p) ./ PCSCALE, p.properties)
        for p in polys]
end

function offset(subject::Polygon{Int64}, delta::Real;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon)

    c = coffset()
    Clipper.clear!(c)
    Clipper.add_path!(c, reinterpret(Clipper.IntPoint, subject.p), j, e)
    result = Clipper.execute(c, Float64(delta))
    result2 = map(x->Polygon{Int64}(reinterpret(Point{Int64}, x),
        copy(subject.properties)), result)
    result2
end

offset{S<:Real}(s::AbstractPolygon{S}, delta::Real;
    j::Clipper.JoinType=Clipper.JoinTypeMiter,
    e::Clipper.EndType=Clipper.EndTypeClosedPolygon) =
    offset(convert(Polygon{S}, s), delta, j=j, e=e)

### cutting algorithm

abstract D1

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
    yarr = slice(nopts, 2:2:length(nopts))
    miny, indy = findmin(yarr)
    xarr = slice(nopts, (find(x->x==miny, yarr).*2).-1)
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

function interiorcuts(nodeortree::Union{Clipper.PolyNode, Clipper.PolyTree}, outpolys, props)
    # currently assumes we have first element an enclosing polygon with
    # the rest being holes. We don't dig deep into the PolyTree...

    # We also assume no hole collision

    minpt = Point(-Inf, -Inf)

    for enclosing in nodeortree.children
        segs = segments(enclosing.v)
        for hole in enclosing.children
            # Intersect the unique ray with the line segments of the polygon.
            ray = uniqueray(hole.v)

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
            #
            # println(bestwhere)
            # println(k)
            # println(ray)
            # Since the polygon was enclosing, an intersection had to happen *somewhere*.
            if k != -1
                w = Point{Int64}(round(getx(bestwhere)), round(gety(bestwhere)))
                kp1 = enclosing.v[(k+1 > length(enclosing.v)) ? 1 : k+1]

                # Make the cut in the enclosing polygon
                enclosing.v = [enclosing.v[1:k];
                    w;             # could actually be enclosing.v[k]... should check for this.
                    hole.v;
                    hole.v[1];     # need to loop back to first point of hole
                    w;
                    enclosing.v[(k+1):end]]

                # update the segment cache
                segs = [segs[1:(k-1)];
                    Segment(enclosing.v[k], w);
                    Segment(w, hole.v[1]);
                    segments(hole.v);
                    Segment(hole.v[1], w);
                    Segment(w, kp1);
                    segs[(k+1):end]]
            end
        end
        push!(outpolys, Polygon(enclosing.v, props))
    end
    outpolys
end


end
