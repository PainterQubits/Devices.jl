module Rectangles

using ..Points
import Base: +, -, *, /, minimum, maximum, copy, ==, convert, isapprox
import Devices
import Devices: AbstractPolygon, Coordinate
import Devices: bounds, center, centered, centered!
gdspy() = Devices._gdspy

export Rectangle
export Plain
export Rounded
export Undercut
export height
export width
export isproper

"""
```
type Rectangle{T} <: AbstractPolygon{T}
    ll::Point{T}
    ur::Point{T}
    properties::Dict{Symbol, Any}
    Rectangle(ll,ur) = new(ll,ur,Dict{Symbol,Any}())
    Rectangle(ll,ur,props) = new(ll,ur,props)
end
```

A rectangle, defined by opposing lower-left and upper-right corner coordinates.
"""
type Rectangle{T} <: AbstractPolygon{T}
    ll::Point{T}
    ur::Point{T}
    properties::Dict{Symbol, Any}
    Rectangle(ll,ur) = Rectangle(ll,ur,Dict{Symbol,Any}())
    function Rectangle(a,b,props)
        # Ensure ll is lower-left, ur is upper-right.
        ll = Point(a.<=b) .* a + Point(b.<=a) .* b
        ur = Point(a.<=b) .* b + Point(b.<=a) .* a
        new(ll,ur,props)
    end
end
Rectangle{T}(ll::Point{T}, ur::Point{T}, dict) = Rectangle{T}(ll,ur,dict)

"""
```
Rectangle(ll::Point, ur::Point; kwargs...)
```

Convenience constructor for `Rectangle` objects.
"""
Rectangle(ll::Point, ur::Point; kwargs...) =
    Rectangle(promote(ll, ur)..., Dict{Symbol,Any}(kwargs))

"""
```
Rectangle(width, height, kwargs...)
```

Constructs `Rectangle` objects by specifying the width and height rather than
the lower-left and upper-right corners.

The rectangle will sit with the lower-left corner at the origin. With centered
rectangles we would need to divide width zeand height by 2 to properly position.
If we wanted an object of `Rectangle{Int}` type, this would not be possible
if either `width` or `height` were odd numbers. This definition ensures type
stability in the constructor.
"""
Rectangle(width, height; kwargs...) =
    Rectangle(Point(zero(width), zero(height)),
        Point(width, height), Dict{Symbol,Any}(kwargs))

convert{T}(::Type{Rectangle{T}}, x::Rectangle) = Rectangle{T}(x.ll, x.ur, x.properties)

copy(p::Rectangle) = Rectangle(p.ll, p.ur, copy(p.properties))

==(r1::Rectangle, r2::Rectangle) =
    (r1.ll == r2.ll) && (r1.ur == r2.ur) && (r1.properties == r2.properties)
isapprox(r1::Rectangle, r2::Rectangle) =
    isapprox(r1.ll, r2.ll) && isapprox(r1.ur, r2.ur) &&
        (r1.properties == r2.properties)

"""
```
width(r::Rectangle)
```

Return the width of a rectangle.
"""
width(r::Rectangle) = getx(r.ur)-getx(r.ll)

"""
```
height(r::Rectangle)
```

Return the height of a rectangle.
"""
height(r::Rectangle) = gety(r.ur)-gety(r.ll)

"""
```
isproper(r::Rectangle)
```

Returns `true` if the rectangle has a non-zero size. Otherwise, returns `false`.
Note that the upper-right and lower-left corners are enforced to be the `ur`
and `ll` fields of a `Rectangle` by the inner constructor.
"""
isproper(r::Rectangle) = r.ur != r.ll

"""
```
bounds(r::Rectangle)
```

No-op (just returns `r`).
"""
bounds(r::Rectangle) = r

"""
```
center(r::Rectangle)
```

Returns a Point corresponding to the center of the rectangle.
"""
center(r::Rectangle) = (r.ur+r.ll)/2

"""
```
centered!(r::Rectangle)
```

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
```
centered(r::Rectangle)
```

Centers a copy of `r`, with promoted coordinates if necessary.
This function will not throw an `InexactError()`, even if `r` had integer
coordinates.
"""
function centered(r::Rectangle)
    c = center(r)
    Rectangle(r.ll - c, r.ur - c, r.properties)
end

"""
```
minimum(r::Rectangle)
```

Returns the lower-left corner of a rectangle (Point object).
"""
minimum(r::Rectangle) = r.ll

"""
```
maximum(r::Rectangle)
```

Returns the upper-right corner of a rectangle (Point object).
"""
maximum(r::Rectangle) = r.ur

for op in [:+, :-]
    @eval function ($op)(r::Rectangle, p::Point)
        Rectangle(($op)(r.ll, p), ($op)(r.ur, p), r.properties)
    end
end

@doc """
```
+(r::Rectangle, p::Point)
```

Translate a rectangle by `p`.
""" +(::Rectangle, ::Point)

*(r::Rectangle, a::Real) = Rectangle(*(r.ll,a), *(r.ur,a), r.properties)
*(a::Real, r::Rectangle) = *(r,a)
/(r::Rectangle, a::Real) = Rectangle(/(r.ll,a), /(r.ur,a), r.properties)

"""
```
abstract Style
```

Implement new rectangle drawing styles by subtyping this.
"""
abstract Style

"""
```
type Plain <: Style end
```

Plain rectangle style. Use this if you are fond for the simpler times when
rectangles were just rectangles.
"""
type Plain <: Style end

"""
```
type Rounded{T<:Coordinate} <: Style
    r::T
end
```

Rounded rectangle style. All corners are rounded off with a given radius `r`.
The bounding box of the unstyled rectangle should remain unaffected.
"""
type Rounded{T<:Coordinate} <: Style
    r::T
end

"""
```
type Undercut{T<:Coordinate} <: Style
    ucl::T
    uct::T
    ucr::T
    ucb::T
end
```

Undercut rectangles. In each direction around a rectangle (left, top, right,
bottom) an undercut is rendered on a different layer.
"""
type Undercut{T<:Coordinate} <: Style
    ucl::T
    uct::T
    ucr::T
    ucb::T
end
Undercut{T<:Coordinate}(uc::T) = Undercut{T}(uc,uc,uc,uc)

end
