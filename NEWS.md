- v0.0.3
 - Bug fixes.
 - Added `XReflection` and `YReflection` transformations.
- v0.0.2
 - Introduced GDS-II import capability. After `using FileIO`, `load` will return a dictionary
   with string keys (names of cells) and Cell values.
 - Introduced sharp bends in paths via `corner!`.
 - Added unit support.
 - Made constructors for `CellArray` and `CellReference` more intuitive
   and easier to use. The syntax has changes slightly; more things are keyword arguments now,
   with synonyms accepted so you don't have to remember exactly what the keyword argument was called.
 - When rectangles have integer coordinates, it is not always the case that they can be centered.
   Since `center!` implies that an object will be modified, and `center` is expected to return the
   center of a rectangle, we disambiguated by making `centered` and `centered!`. The former will
   return a centered copy of the rectangle, possibly with floating-point coordinates if it could not
   be centered with integer coordinates. The latter will attempt to center the provided rectangle
   and throw an `InexactError()` if it was not possible. `center` will still return the center
   of a rectangle, which may have floating-point coordinates even if the rectangle itself had
   integer coordinates.
 - Made clipping and offsetting more reliable (and documented them).
 - Switched from [`AffineTransforms.jl`](https://github.com/timholy/AffineTransforms.jl)
   to [`CoordinateTransformations.jl`](https://github.com/FugroRoames/CoordinateTransformations.jl).
   See the documentation (under Abstract polygons) for usage instructions, the syntax has changed.
 - Switched from [`FixedSizeArrays.jl`](https://github.com/SimonDanisch/FixedSizeArrays.jl) to
   [`StaticArrays.jl`](https://github.com/JuliaArrays/StaticArrays.jl) for our
   `Point` implementation. Syntax should remain largely the same. This switch was made for
   compatibility with Julia 0.5 and is an improvement.
 - Rotations are now consistently specified in radians if no unit is given.
   Units may however be provided if you want to use degrees.
- v0.0.1 - Initial release used to generate our first qubit.
