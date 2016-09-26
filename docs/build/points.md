


<a id='Summary-1'></a>

## Summary


Points live in a Cartesian coordinate system with `Real` or `Unitful.Length` coordinates:


```jlcon
julia> Point(1,1)
2-element Devices.Points.Point{Int64}:
 1
 1

julia> Point(1.0,1.0)
2-element Devices.Points.Point{Float64}:
 1.0
 1.0

julia> Point(1.0u"μm", 1.0u"μm")
2-element Devices.Points.Point{Quantity{Float64, Dimensions:{𝐋}, Units:{μm}}}:
 1.0 μm
 1.0 μm
```


If a point has `Real` coordinates, the absence of a unit is interpreted to mean `μm` whenever the geometry is saved to a GDS format, but until then it is just considered to be a pure number. Therefore you cannot mix and match `Real` and `Length` coordinates:


```jlcon
julia> Point(1.0u"μm", 1.0)
ERROR: Cannot use `Point` with this combination of types.
```


You can add Points together or scale them:


```jlcon
julia> 3*Point(1,1)+Point(1,2)
2-element Devices.Points.Point{Int64}:
 4
 5
```


You can also do affine transformations by composing any number of `Translation` and `Rotation`s, which will return a callable object representing the transformation. You can type the following Unicode symbols with `\degree` and `\circ` tab-completions in the Julia REPL or using the Atom package `latex-completions`.


```jlcon
julia> aff = Rotation(90°) ∘ Translation(Point(1,2))
AffineMap([6.12323e-17 -1.0; 1.0 6.12323e-17], (-2.0,1.0000000000000002))

julia> aff(Point(0,0))
2-element Devices.Points.Point{Float64}:
 -2.0
  1.0
```


<a id='API-1'></a>

## API

<a id='Devices.Coordinate' href='#Devices.Coordinate'>#</a>
**`Devices.Coordinate`** &mdash; *Constant*.



```
typealias Coordinate Union{Real,Length}
```

Type alias for numeric types suitable for coordinate systems.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/811642fbd6b286c3f02c598a3f896a3377fbc8a7/src/Devices.jl#L47-L53' class='documenter-source'>source</a><br>

<a id='Devices.Points.Point' href='#Devices.Points.Point'>#</a>
**`Devices.Points.Point`** &mdash; *Type*.



```
immutable Point{T} <: FieldVector{T}
    x::T
    y::T
end
```

2D Cartesian coordinate in the plane.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/811642fbd6b286c3f02c598a3f896a3377fbc8a7/src/points.jl#L15-L24' class='documenter-source'>source</a><br>

<a id='Devices.Points.getx' href='#Devices.Points.getx'>#</a>
**`Devices.Points.getx`** &mdash; *Function*.



```
getx(p::Point)
```

Get the x-coordinate of a point. You can also use `p.x` or `p[1]`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/811642fbd6b286c3f02c598a3f896a3377fbc8a7/src/points.jl#L47-L53' class='documenter-source'>source</a><br>

<a id='Devices.Points.gety' href='#Devices.Points.gety'>#</a>
**`Devices.Points.gety`** &mdash; *Function*.



```
gety(p::Point)
```

Get the y-coordinate of a point. You can also use `p.y` or `p[2]`.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/811642fbd6b286c3f02c598a3f896a3377fbc8a7/src/points.jl#L56-L62' class='documenter-source'>source</a><br>

<a id='Devices.Points.lowerleft' href='#Devices.Points.lowerleft'>#</a>
**`Devices.Points.lowerleft`** &mdash; *Function*.



```
lowerleft{T}(A::AbstractArray{Point{T}})
```

Returns the lower-left [`Point`](points.md#Devices.Points.Point) of the smallest bounding rectangle (with sides parallel to the x- and y-axes) that contains all points in `A`.

Example:

```jlcon
julia> lowerleft([Point(2,0),Point(1,1),Point(0,2),Point(-1,3)])
2-element Devices.Points.Point{Int64}:
 -1
  0
```


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/811642fbd6b286c3f02c598a3f896a3377fbc8a7/src/points.jl#L89-L104' class='documenter-source'>source</a><br>

<a id='Devices.Points.upperright' href='#Devices.Points.upperright'>#</a>
**`Devices.Points.upperright`** &mdash; *Function*.



```
upperright{T}(A::AbstractArray{Point{T}})
```

Returns the upper-right [`Point`](points.md#Devices.Points.Point) of the smallest bounding rectangle (with sides parallel to the x- and y-axes) that contains all points in `A`.

Example:

```jlcon
julia> upperright([Point(2,0),Point(1,1),Point(0,2),Point(-1,3)])
2-element Devices.Points.Point{Int64}:
 2
 3
```


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/811642fbd6b286c3f02c598a3f896a3377fbc8a7/src/points.jl#L112-L127' class='documenter-source'>source</a><br>


<a id='Implementation-details-1'></a>

## Implementation details


Points are implemented using the abstract type `FieldVector` from [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl). This permits a fast, efficient representation of coordinates in the plane. Additionally, unlike `Tuple` objects, we can add points together, simplifying many function definitions.


To interface with gdspy, we simply convert the `Point` object to a `Tuple` and let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

