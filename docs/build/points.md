
Points are implemented using the abstract type `FixedVectorNoTuple` from [FixedSizeArrays.jl](https://github.com/SimonDanisch/FixedSizeArrays.jl). This permits a fast, efficient representation of coordinates in the plane. Additionally, unlike `Tuple` objects, we can add points together, simplifying many function definitions.


To interface with gdspy, we simply convert the `Point` object to a `Tuple` and let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

<a id='Devices.Points.getx' href='#Devices.Points.getx'>#</a>
**`Devices.Points.getx`** &mdash; *Function*.

---


```
getx(p::Point)
```

Get the x-coordinate of a point.

<a id='Devices.Points.gety' href='#Devices.Points.gety'>#</a>
**`Devices.Points.gety`** &mdash; *Function*.

---


```
gety(p::Point)
```

Get the y-coordinate of a point.

