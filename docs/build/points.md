


Points are implemented using the abstract type `FieldVector` from [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl). This permits a fast, efficient representation of coordinates in the plane. Additionally, unlike `Tuple` objects, we can add points together, simplifying many function definitions.


Points can have `Real` or `Unitful.Length` coordinates:


```jlcon
julia> Point(1.0,1.0)
2-element Devices.Points.Point{Float64}:
 1.0
 1.0
julia> Point(1.0u"μm", 1.0u"μm")
2-element Devices.Points.Point{Quantity{Float64, Dimensions:{𝐋}, Units:{μm}}}:
 1.0 μm
 1.0 μm
```


If a point has `Real` coordinates, the absence of a unit is interpreted to mean `μm`. Note that you cannot mix and match `Real` and `Length` coordinates:


```jlcon
julia> Point(1.0u"μm", 1.0)
ERROR: Cannot use `Point` with this combination of types.
```


To interface with gdspy, we simply convert the `Point` object to a `Tuple` and let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

<a id='Devices.Coordinate' href='#Devices.Coordinate'>#</a>
**`Devices.Coordinate`** &mdash; *Constant*.



```
typealias Coordinate Union{Real,Length}
```

Type alias for numeric types suitable for coordinate systems.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Devices.jl#L44-L50' class='documenter-source'>source</a><br>

<a id='Devices.Points.Point' href='#Devices.Points.Point'>#</a>
**`Devices.Points.Point`** &mdash; *Type*.



```
immutable Point{T} <: FieldVector{T}
```

2D coordinate in the plane.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Points.jl#L15-L21' class='documenter-source'>source</a><br>

<a id='Devices.Points.getx' href='#Devices.Points.getx'>#</a>
**`Devices.Points.getx`** &mdash; *Function*.



```
getx(p::Point)
```

Get the x-coordinate of a point.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Points.jl#L44-L50' class='documenter-source'>source</a><br>

<a id='Devices.Points.gety' href='#Devices.Points.gety'>#</a>
**`Devices.Points.gety`** &mdash; *Function*.



```
gety(p::Point)
```

Get the y-coordinate of a point.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/4e771912a65b4a8591b1934e355e158db3cd60da/src/Points.jl#L53-L59' class='documenter-source'>source</a><br>

