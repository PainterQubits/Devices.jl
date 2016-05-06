module Points

import Base: convert, .+, .-
import FixedSizeArrays: FixedVectorNoTuple, Point
import PyCall.PyObject
export Point
export getx, gety, setx!, sety!

"""
```
getx(p::Point)
```

Get the x-coordinate of a point.
"""
@inline getx(p::Point) = p._[1]

"""
```
gety(p::Point)
```

Get the y-coordinate of a point.
"""
@inline gety(p::Point) = p._[2]
setx!(p::Point, r) = p = Point(r, gety(p))
sety!(p::Point, r) = p = Point(getx(p), r)

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

end
