```@meta
DocTestSetup = quote
    using Unitful, Devices
end
```

Points are implemented using the abstract type `FieldVector`
from [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl).
This permits a fast, efficient representation of
coordinates in the plane. Additionally, unlike `Tuple` objects, we can
add points together, simplifying many function definitions.

Points can have `Real` or `Unitful.Length` coordinates:

```jldoctest
julia> Point(1.0,1.0)
2-element Devices.Points.Point{Float64}:
 1.0
 1.0
julia> Point(1.0u"μm", 1.0u"μm")
2-element Devices.Points.Point{Quantity{Float64, Dimensions:{𝐋}, Units:{μm}}}:
 1.0 μm
 1.0 μm
```

If a point has `Real` coordinates, the absence of a unit is interpreted to mean
`μm`. Note that you cannot mix and match `Real` and `Length` coordinates:

```jldoctest
julia> Point(1.0u"μm", 1.0)
ERROR: Cannot use `Point` with this combination of types.
```

To interface with gdspy, we simply convert the `Point` object to a `Tuple` and
let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

```@docs
    Devices.Coordinate
    Points.Point
    Points.getx
    Points.gety
    Points.lowerleft
    Points.upperright
```
