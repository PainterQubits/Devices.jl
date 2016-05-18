Points are implemented using the abstract type `FixedVectorNoTuple`
from [FixedSizeArrays.jl](https://github.com/SimonDanisch/FixedSizeArrays.jl).
This permits a fast, efficient representation of
coordinates in the plane. Additionally, unlike `Tuple` objects, we can
add points together, simplifying many function definitions.

To interface with gdspy, we simply convert the `Point` object to a `Tuple` and
let [PyCall.jl](https://github.com/stevengj/PyCall.jl) figure out what to do.

```@docs
Points.getx
Points.gety
```
