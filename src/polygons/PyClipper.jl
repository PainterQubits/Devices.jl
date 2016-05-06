@enum ClipperOp CT_INTERSECTION CT_UNION CT_DIFFERENCE CT_XOR
@enum ClipperJoin JT_SQUARE JT_ROUND JT_MITER
@enum ClipperEnd ET_CLOSEDPOLYGON ET_CLOSEDLINE ET_OPENSQUARE ET_OPENROUND ET_OPENBUTT
@enum ClipperPFType PFT_EVENODD PFT_NONZERO PFT_POSITIVE PFT_NEGATIVE

export CT_INTERSECTION, CT_UNION, CT_DIFFERENCE, CT_XOR
export JT_SQUARE, JT_ROUND, JT_MITER
export ET_CLOSEDPOLYGON, ET_CLOSEDLINE, ET_OPENSQUARE, ET_OPENROUND, ET_OPENBUTT
export PFT_EVENODD, PFT_NONZERO, PFT_POSITIVE, PFT_NEGATIVE

const PCSCALE = 2^31

"""
```
clip{S<:Real, T<:Real}(op::ClipperOp, subject::Polygon{S}, clip::Polygon{T})
```

Clip polygon `subject` by polygon `clip` using operation `op` from the
[Clipper library](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm).
The [Python wrapper](https://github.com/greginvm/pyclipper) over the C++ library is used.

Valid `ClipperOp` include `CT_INTERSECTION`, `CT_UNION`, `CT_DIFFERENCE`, `CT_XOR`.
"""
function clip{S<:Real, T<:Real}(op::ClipperOp, subject::Polygon{S}, clip::Polygon{T})
    pc = pyclipper()[:Pyclipper]()
    s = convert(Array{Point{2,Int64},1}, map(trunc, subject.p .* PCSCALE))
    c = convert(Array{Point{2,Int64},1}, map(trunc, clip.p .* PCSCALE))

    pc[:AddPath](c, pyclipper()[:PT_CLIP], true)
    pc[:AddPath](s, pyclipper()[:PT_SUBJECT], true)
    result = pycall(pc[:Execute], PyVector{Array{Point{2,Int64},1}}, Int(op))
    result2 = map(x->Polygon(convert(Array{Point{2,Float64},1}, x) ./ PCSCALE, subject.properties), result)
    result2
end
clip{S<:Real, T<:Real}(op::ClipperOp, s::AbstractPolygon{S}, c::AbstractPolygon{T}) =
    clip(op, convert(Polygon{S}, s), convert(Polygon{T}, c))

"""
```
offset{S<:Real}(subject::Polygon{S}, delta::Real,
        j::ClipperJoin=JT_MITER, e::ClipperEnd=ET_CLOSEDPOLYGON)
```

Offset a polygon `subject` by some amount `delta` using the
[Clipper library](http://www.angusj.com/delphi/clipper/documentation/Docs/Overview/_Body.htm).
The [Python wrapper](https://github.com/greginvm/pyclipper) over the C++ library is used.

`ClipperJoin` parameters are discussed
[here](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/JoinType.htm).
Valid syntax in this package is: `JT_SQUARE`, `JT_ROUND`, `JT_MITER`.

`ClipperEnd` parameters are discussed
[here](http://www.angusj.com/delphi/clipper/documentation/Docs/Units/ClipperLib/Types/EndType.htm).
Valid syntax in this package is: `ET_CLOSEDPOLYGON`, `ET_CLOSEDLINE`, `ET_OPENSQUARE`,
`ET_OPENROUND`, `ET_OPENBUTT`.

To do: Handle the type parameter of Polygon, which is ignored now.
"""
function offset{S<:Real}(subject::Polygon{S}, delta::Real,
        j::ClipperJoin=JT_MITER, e::ClipperEnd=ET_CLOSEDPOLYGON)
    pc = pyclipper()[:PyclipperOffset]()

    # get large scaled integers
    s = convert(Array{Point{2,Int64},1}, map(trunc, subject.p .* PCSCALE))
    delta *= PCSCALE

    # offset
    pc[:AddPath](s, Int(j), Int(e))
    result = pycall(pc[:Execute], PyVector{Array{Point{2,Int64},1}}, delta)

    result = convert(Array{Point{2,Float64}}, result[1])
    result ./= PCSCALE
    Polygon(result, subject.properties)
end
offset{T<:Real}(s::Rectangle{T}, args...) = offset(convert(Polygon{T}, s), args...)
