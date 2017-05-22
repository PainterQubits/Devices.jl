module Rectangles

using Compat
using ..Points
import Base: +, -, *, /, copy, ==, convert, isapprox
import Devices
import Devices: AbstractPolygon, Coordinate
import Devices: bounds, center, centered, centered!, lowerleft, upperright
import Unitful: ustrip

export Rectangle
export height
export width
export isproper

"""
```
type Rectangle{T} <: AbstractPolygon{T}
    ll::Point{T}
    ur::Point{T}
    Rectangle(ll,ur) = Rectangle(ll,ur)
    function Rectangle(a,b)
        # Ensure ll is lower-left, ur is upper-right.
        ll = Point(a.<=b) .* a + Point(b.<=a) .* b
        ur = Point(a.<=b) .* b + Point(b.<=a) .* a
        new(ll,ur)
    end
end
```

A rectangle, defined by opposing lower-left and upper-right corner coordinates.
Lower-left and upper-right are guaranteed to be such by the inner constructor.
"""
type Rectangle{T} <: AbstractPolygon{T}
    ll::Point{T}
    ur::Point{T}
    Rectangle(ll,ur) = Rectangle(ll,ur)
    function Rectangle(a,b)
        # Ensure ll is lower-left, ur is upper-right.
        ll = Point(a.<=b) .* a + Point(b.<=a) .* b
        ur = Point(a.<=b) .* b + Point(b.<=a) .* a
        new(ll,ur)
    end
end
Rectangle{T}(ll::Point{T}, ur::Point{T}) = Rectangle{T}(ll,ur)

"""
    Rectangle(ll::Point, ur::Point)
Convenience constructor for `Rectangle` objects.
"""
Rectangle(ll::Point, ur::Point) = Rectangle(promote(ll, ur)...)

"""
    Rectangle(width, height)
Constructs `Rectangle` objects by specifying the width and height rather than
the lower-left and upper-right corners.

The rectangle will sit with the lower-left corner at the origin. With centered
rectangles we would need to divide width and height by 2 to properly position.
If we wanted an object of `Rectangle{Int}` type, this would not be possible
if either `width` or `height` were odd numbers. This definition ensures type
stability in the constructor.
"""
Rectangle(width, height) = Rectangle(Point(zero(width), zero(height)), Point(width, height))

convert{T}(::Type{Rectangle{T}}, x::Rectangle) = Rectangle{T}(x.ll, x.ur)

copy(p::Rectangle) = Rectangle(p.ll, p.ur)

==(r1::Rectangle, r2::Rectangle) = (r1.ll == r2.ll) && (r1.ur == r2.ur)

isapprox(r1::Rectangle, r2::Rectangle) = isapprox(r1.ll, r2.ll) && isapprox(r1.ur, r2.ur)

"""
    width(r::Rectangle)
Return the width of a rectangle.
"""
width(r::Rectangle) = getx(r.ur) - getx(r.ll)

"""
    height(r::Rectangle)
Return the height of a rectangle.
"""
height(r::Rectangle) = gety(r.ur) - gety(r.ll)

"""
    isproper(r::Rectangle)
Returns `true` if the rectangle has a non-zero size. Otherwise, returns `false`.
Note that the upper-right and lower-left corners are enforced to be the `ur`
and `ll` fields of a `Rectangle` by the inner constructor.
"""
isproper(r::Rectangle) = r.ur != r.ll

"""
    bounds(r::Rectangle)
No-op (just returns `r`).
"""
bounds(r::Rectangle) = r

"""
    center(r::Rectangle)
Returns a [`Point`](@ref) corresponding to the center of the rectangle.
"""
center(r::Rectangle) = (r.ur + r.ll) / 2

"""
    centered!(r::Rectangle)
Centers a rectangle. Will throw an `InexactError()` if
the rectangle cannot be centered with integer coordinates.
"""
function centered!(r::Rectangle)
    c = center(r)
    r.ll -= c
    r.ur -= c
    r
end

"""
    centered(r::Rectangle)
Centers a copy of `r`, with promoted coordinates if necessary.
This function will not throw an `InexactError()`, even if `r` had integer
coordinates.
"""
function centered(r::Rectangle)
    c = center(r)
    Rectangle(r.ll - c, r.ur - c)
end

"""
    lowerleft(r::Rectangle)
Returns the lower-left corner of a rectangle (Point object).
"""
lowerleft(r::Rectangle) = r.ll

"""
    upperright(r::Rectangle)
Returns the upper-right corner of a rectangle (Point object).
"""
upperright(r::Rectangle) = r.ur

for op in [:+, :-]
    @eval function ($op)(r::Rectangle, p::Point)
        Rectangle(($op)(r.ll, p), ($op)(r.ur, p))
    end
end

@doc """
    +(r::Rectangle, p::Point)
Translate a rectangle by `p`.
""" +(::Rectangle, ::Point)

*(r::Rectangle, a::Real) = Rectangle(*(r.ll,a), *(r.ur,a))
*(a::Real, r::Rectangle) = *(r,a)
/(r::Rectangle, a::Real) = Rectangle(/(r.ll,a), /(r.ur,a))

"""
    abstract Rectangles.Style
Implement new rectangle drawing styles by subtyping this.
"""
@compat abstract type Style end

"""
    immutable Plain <: Rectangles.Style
        layer::Int
        datatype::Int
        Plain() = new(0,0)
        Plain(a,b) = new(a,b)
    end
Plain rectangle style. Use this if you are fond for the simpler times when
rectangles were just rectangles.
"""
immutable Plain <: Style
    layer::Int
    datatype::Int
    Plain() = new(0,0)
    Plain(a) = new(a,0)
    Plain(a,b) = new(a,b)
end

"""
    immutable Rounded{T<:Coordinate} <: Rectangles.Style
        r::T
        layer::Int
        datatype::Int
        Plain(r) = new(r,0,0)
        Plain(r,a) = new(r,a,0)
        Plain(r,a,b) = new(r,a,b)
    end
Rounded rectangle style. All corners are rounded off with a given radius `r`.
The bounding box of the unstyled rectangle should remain unaffected.

"""
immutable Rounded{T<:Coordinate} <: Style
    r::T
    layer::Int
    datatype::Int
    Plain(r) = new(r,0,0)
    Plain(r,a) = new(r,a,0)
    Plain(r,a,b) = new(r,a,b)
end

"""
    immutable Undercut{T<:Coordinate} <: Rectangles.Style
        ucl::T
        uct::T
        ucr::T
        ucb::T
        layer::Int
        uclayer::Int
        datatype::Int
        ucdatatype::Int
    end
Undercut rectangles. In each direction around a rectangle (left, top, right, bottom) an
undercut is rendered on .
"""
immutable Undercut{T<:Coordinate} <: Style
    ucl::T
    uct::T
    ucr::T
    ucb::T
    layer::Int
    uclayer::Int
    datatype::Int
    ucdatatype::Int
    Undercut(a,b,c,d) = new(a,b,c,d,0,1,0,0)
    Undercut(a,b,c,d,e,f) = new(a,b,c,d,e,f,0,0)
    Undercut(a,b,c,d,e,f,g,h) = new(a,b,c,d,e,f,g,h)
end
Undercut(ucl, uct, ucr, ucb) = Undercut(promote(ucl, uct, ucr, ucb)...)
Undercut(ucl, uct, ucr, ucb, layer, uclayer) =
    Undercut(promote(ucl, uct, ucr, ucb)..., layer, uclayer)
Undercut(ucl, uct, ucr, ucb, layer, uclayer, datatype, ucdatatype) =
    Undercut(promote(ucl, uct, ucr, ucb)..., layer, uclayer, datatype, ucdatatype)

Undercut{T<:Coordinate}(uc::T) = Undercut{T}(uc, uc, uc, uc)
Undercut{T<:Coordinate}(uc::T, layer, uclayer) = Undercut{T}(uc, uc, uc, uc, layer, uclayer)
Undercut{T<:Coordinate}(uc::T, layer, uclayer, datatype, ucdatatype) =
    Undercut{T}(uc, uc, uc, uc, layer, uclayer, datatype, ucdatatype)

ustrip(r::Rectangle) = Rectangle(ustrip(r.ll), ustrip(r.ur))

end
