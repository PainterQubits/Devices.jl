module Points

import AffineTransforms: AffineTransform
import Clipper: IntPoint
import Base: convert, .+, .-, *
import FixedSizeArrays: FixedVectorNoTuple, Point
import PyCall.PyObject
export Point
export getx, gety

convert{T<:Real}(::Type{Point{2,T}}, x::IntPoint) = Point{2,T}(x.X, x.Y)

"""
```
getx(p::Point)
```

Get the x-coordinate of a point.
"""
@inline getx(p::Point) = p.values[1]

"""
```
gety(p::Point)
```

Get the y-coordinate of a point.
"""
@inline gety(p::Point) = p.values[2]

# For use with gdspy
PyObject(p::Point) = PyObject((getx(p), gety(p)))

for dotop in [:.+, :.-]
    @eval function ($dotop){N, S<:Real, T<:Real}(a::Array{Point{N,S}}, p::Point{N,T})
        b = similar(a, Point{N,promote_type(S,T)})
        for (ia, ib) in zip(eachindex(a), eachindex(b))
            @inbounds b[ib] = ($dotop)(a[ia], p)
        end
        b
    end
    @eval function ($dotop){N, S<:Real, T<:Real}(p::Point{N,S}, a::Array{Point{N,T}})
        ($dotop)(a,p)
    end
end

*(a::AffineTransform, p::Point) = a * Array(p)


end
