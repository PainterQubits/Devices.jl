module Rectangles

using ForwardDiff
using ..Points

import Base: +, -, *, /, minimum, maximum, copy
import Devices
import Devices: AbstractPolygon
import Devices: bounds, center, center!
gdspy() = Devices._gdspy

# using AffineTransforms

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
end

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
    Rectangle(Point(zero(typeof(width)), zero(typeof(height))),
        Point(width, height), Dict{Symbol,Any}(kwargs))

copy(p::Rectangle) = Rectangle(p.ll, p.ur, copy(p.properties))

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

Returns `true` if the rectangle has a non-zero size and if the upper-right and
lower-left corner coordinates `ur` and `ll` really are at the upper-right
and lower-left. Otherwise, returns `false`.
"""
isproper(r::Rectangle) = getx(r.ur) >= getx(r.ll) &&
                        gety(r.ur) >= gety(r.ll) &&
                        r.ur != r.ll

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
center!(r::Rectangle)
```

Centers a rectangle. Will throw an `InexactError()` if
the rectangle cannot be centered with integer corner coordinates.
"""
function center!(r::Rectangle)
    c = center(r)
    r.ll -= c
    r.ur -= c
    r
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

"How to draw the rectangle."
abstract Style

"Simple solid rectangle."
type Plain <: Style end

"The corners are rounded off (bounding box of the unstyled rectangle unaffected)."
type Rounded <: Style
    r::Float64
end

"""
```
type Undercut{T<:Real} <: Style
```

Undercut in each direction around a rectangle.
"""
type Undercut{T<:Real} <: Style
    ucl::T
    uct::T
    ucr::T
    ucb::T
end
Undercut{T<:Real}(uc::T) = Undercut{T}(uc,uc,uc,uc)

end
