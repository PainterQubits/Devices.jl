module Polygons

using PyCall
using ForwardDiff
using AffineTransforms
using ..Points
using ..Rectangles

import Base: +, -, *, /, minimum, maximum, convert
import Devices
import Devices: AbstractPolygon
import Devices: bounds
gdspy() = Devices._gdspy
pyclipper() = Devices._pyclipper

export Polygon
export Tristrip
export Plain
export points
export clip, offset

"""
`type Polygon{T<:Real}`

Polygon defined by list of coordinates (not repeating start).
"""
type Polygon{T<:Real} <: AbstractPolygon{T}
    p::Array{Point{2,T},1}
    properties::Dict{Symbol, Any}
    Polygon(x,y) = new(x,y)
    Polygon(x) = new(x, Dict{Symbol, Any}())
end
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}; kwargs...) =
    Polygon{T}(parr, Dict{Symbol,Any}(kwargs))
Polygon{T<:Real}(parr::AbstractArray{Point{2,T},1}, kwargs) =
    Polygon{T}(parr, kwargs)
Polygon{T<:Real}(p0::Point{2,T}, p1::Point{2,T}, p2::Point{2,T},
    p3::Point{2,T}...; kwargs...) =
        Polygon{T}([p0, p1, p2, p3...], Dict{Symbol,Any}(kwargs))
points(x::Polygon) = x.p
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
`minimum(x::Polygon)`

Return the lower-left-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
minimum(x::Polygon) = minimum(x.p)

"""
`maximum(x::Polygon)`

Return the upper-right-most corner of a rectangle bounding polygon `x`.
Note that this point doesn't have to be in the polygon.
"""
maximum(x::Polygon) = maximum(x.p)

function *(a::AffineTransform, x::Polygon)
    Polygon(map(x->Point(a*Array(x)), x.p), x.properties)
end
*{T<:Real}(a::AffineTransform, x::Rectangle{T}) = *(a, convert(Polygon{T}, x))

"""
`type Tristrip{T<:Real}`

Tristrip defined by list of coordinates. See
[here](https://en.wikipedia.org/wiki/Triangle_strip) for further details. Currently
only used for interfacing with GPC.
"""
type Tristrip{T<:Real}
    p::Array{Point{2,T},1}
    properties::Dict{Symbol,Any}
end
Tristrip{T<:Real}(p0::Point{2,T}, p1::Point{2,T}, p2::Point{2,T},
    p3::Point{2,T}...; kwargs...) =
    Tristrip{T}([p0, p1, p2, p3...], Dict{Symbol,Any}(kwargs))
points(x::Tristrip) = x.p

function +(r::Tristrip, p::Point)
    Tristrip(r.p .+ p, r.properties)
end
+(p::Point, r::Tristrip) = +(r,p)

"""
`convert{T<:Real}(::Type{Array{Polygon{T},1}}, x::Tristrip)`

Convert a Tristrip into an array of polygons. Until we support polygons with
holes in them we do this ourselves, otherwise GPC could be used.
"""
function convert{T<:Real}(::Type{Array{Polygon{T},1}}, x::Tristrip)
    npolys = length(x.p) - 2
    polys = Array{Polygon{T},1}(npolys)
    for i in 1:npolys
        poly = Polygon{T}(Array{Point{2,T},1}(3))
        poly.p[1] = convert(Point{2,T}, x.p[i])
        poly.p[2] = convert(Point{2,T}, x.p[i+1])
        poly.p[3] = convert(Point{2,T}, x.p[i+2])
        polys[i] = poly
    end
    polys
end

"""
`convert{T<:Real}(::Type{Polygon{T}}, s::Rectangle)`

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
`bounds(p::Polygon)`

Return a bounding Rectangle with no properties for polygon `p`.
"""
bounds(p::Polygon) = Rectangle(minimum(p), maximum(p))

"""
`bounds{T<:AbstractPolygon}(parr::AbstractArray{T,1})`

Return a bounding `Rectangle` with no properties for an array `parr` of
`AbstractPolygon`s.
"""
function bounds{T<:AbstractPolygon}(parr::AbstractArray{T})
    rects = map(bounds, parr)
    ll = minimum(map(minimum, rects))
    ur = maximum(map(maximum, rects))
    Rectangle(ll, ur)
end

"""
`bounds(p0::AbstractPolygon, p::AbstractPolygon...)`

Return a bounding `Rectangle` with no properties for several `AbstractPolygon`s.
"""
bounds(p0::AbstractPolygon, p::AbstractPolygon...) = bounds([p0, p...])

"How to draw the polygon..."
abstract Style

"Simple solid polygon."
type Plain <: Style end

include("GPC.jl")
include("PyClipper.jl")

end
