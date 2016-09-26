- v0.0.2
 - Introduced GDS-II import capability.
 - Introduced sharp bends in paths via `corner!`.
 - Added unit support.
 - Made constructors for `CellArray` and `CellReference` more intuitive
   and easier to use.
 - Made clipping and offsetting more reliable (and documented them).
 - Switched from [`AffineTransforms.jl`](https://github.com/timholy/AffineTransforms.jl)
   to [`CoordinateTransformations.jl`](https://github.com/FugroRoames/CoordinateTransformations.jl).
 - Switched from [`FixedSizeArrays.jl`](https://github.com/SimonDanisch/FixedSizeArrays.jl) to
   [`StaticArrays.jl`](https://github.com/JuliaArrays/StaticArrays.jl) for our
   `Point` implementation.
 - Other various changes.

- v0.0.1 - Initial release used to generate our first qubit.
