- v0.5.1
  - Support for julia 1.0+ versions. Removed REQUIRE file and created Project.toml
- v0.5.0
  - Rewrite some line/ray/line-segment intersection code.
  - `adjust!` has been renamed `reconcile!`
    - For many array-like methods on paths, there is now a keyword argument that lets you
      specify whether you want to reconcile the path immediately or defer. This is useful
      when speed is a concern and you are chaining operations.
  - Implement code to automatically handle path intersections: `Paths.intersect!`
  - Path termination: `Paths.terminate!`
  - Style translation: `Paths.pin` and `Paths.translate`.
  - Node/segment/style splitting: `Paths.split`.
  - Add some default colors: 21--29 is a red gradient, 31--39 is green, 41--49 is blue.
- v0.4.0
  - Julia 1.0 compatibility.
  - `Rectangles.isproper` has a slightly different definition. Rectangles are
    considered proper if they have non-zero area now.
  - `flatten` now has a keyword argument `name` instead of an optional argument.
    It now also has a `depth` keyword argument that can be used to control how
    far down the cell hierarchy to flatten. `flatten!` also has the `depth` keyword argument.
  - Fixed a bug where rotations would be corrupted when loading GDS files.
  - Fixed a bug where x-reflections could be corrupted when loading GDS files.
  - Added some basic interactive display for use with the Juno IDE.
  - Can now save a variety of graphics formats reliably (png, eps, pdf, svg).
- v0.3.0
  - Last release to support Julia 0.6.
  - Added `TaperTrace`, `TaperCPW`, etc.
  - Fix annoying "absolute angle" bug which caused weird rotations when viewing pattern
    output in some GDS viewers.
  - Other bug fixes, improved rendering output, etc.
- v0.2.0
  - `LCDFonts` module added. Try out `lcdstring!` for your text rendering needs.
  - Redesign rendering pipeline.
    - It is no longer allowed to pass keyword arguments to `Rectangle` or `Polygon`
      constructors. These no longer include metadata; they are just geometry.
    - GDS-II layer and datatype are captured by a `GDSMeta` object. This is passed to
      `render!` when rendering polygons, paths, etc. to a cell.
    - `render!` must receive a `Meta` object.
  - Rectangles are no longer mutable, so `centered!` has been removed.
  - Polygons are no longer mutable.
  - Bug fixes: closed issues [11](https://github.com/PainterQubits/Devices.jl/issues/11),
    [13](https://github.com/PainterQubits/Devices.jl/issues/13),
    [16](https://github.com/PainterQubits/Devices.jl/issues/16),
    [17](https://github.com/PainterQubits/Devices.jl/issues/17),
    [18](https://github.com/PainterQubits/Devices.jl/issues/18),
    [19](https://github.com/PainterQubits/Devices.jl/issues/19),
    [21](https://github.com/PainterQubits/Devices.jl/issues/21).
  - Bug fix: `Cell(::AbstractString, ::Unitful.LengthUnits)` method was broken.
  - Bug fix: `meander!` works again, method signature changed a bit.
  - Bug fix: in `CompoundSegment` (such as obtained using `simplify!`), there was a bug with
    generating the simplified path function (field `f` of a `CompoundSegment`). For inputs
    to `f` greater than the path (or segment) length, the expected behavior is to continue
    in a straight line at the angle obtained at the end of the path (or segment).
  - `NoRender(x)` can take a parameter specifying a fake "width" for attachments.
  - Fixed promotion logic with `Rectangles.Undercut` when different units were passed in.
  - Loosened signature of a `CellArray` constructor method.
  - Path `style0` keyword not supported anymore. You must specify a style the first time
    you call `straight!` or `turn!` on a path.
  - Performance improvements.
- v0.1.0
  - Breaking change: `attach!` expects a value from zero to the segment length, not 0 to 1.
    This will also be true for functions passed to `Paths.CPW` or `Paths.Trace`.
  - Breaking change: `minimum` and `maximum` no longer defined for polygons; use `lowerleft`
    and `upperright` instead.
  - Breaking change: some of the methods in `src/tags.jl` may have had changes to their
    method signatures.
  - Breaking change: `flatten` always returns a `Cell`, never an array of `Polygon`s.
    The behavior of `flatten!` (which modifies a `Cell`) is unchanged.
  - Implement our own rendering algorithms. This enables continuous integration testing and
    gives finer control on the output.
    - Dependency on gdspy for rendering has been removed.
  - Begin using `ContextUnits` from Unitful.jl 0.2 for better unit handling. Devices.jl
    now defines its own length units which you can access with `using Devices.PreferMicrons`
    or `using Devices.PreferNanometers`. The following length units are defined:
    `fm`, `pm`, `nm`, `μm`, `mm`, `cm`, `dm`, `m`.
  - Angle units `°`, `rad` are exported by default.
  - Switch over to the registered Clipper.jl package now that the necessary changes have
    been made upstream.
  - Turn on automatic doc builds. Documentation improved and features auto-generated graphics.
  - QR code functionality has been removed to avoid dependency on pyqrcode. It could appear
    again in a separate package if desired.
  - Rename `SimpleCornerStyle` to `SimpleTraceCorner`.
  - Added a convenience method to `attach!` for using ranges.
  - Experimental SVG export. Cells preview in the Plots pane using the SVG renderer
    if using Juno in Atom.
- v0.0.5
  - Added some options to `interdigit`.
  - `extent` is now exported from the Paths module.
  - Bug fix: replaced old `tformrotate` with `Rotation`.
  - Bug fix: attachments now render according to the documentation when using
    `attach!` with `where=0`.
  - Bug fix: update to adapt to changes in StaticArrays.jl.
  - Added `NoRender` style.
  - Allow GDS importing without units.
  - Modify signature of `pecbasedose` method.
- v0.0.4
  - Bug fixes: `CellReference` and `CellArray` were copying their referenced cells instead of retaining a reference to the original object. `flatten` for CellArrays was not using the calculated coordinate shifts.
  - `uniquename` moved to Cells module and exported for users.
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
- v0.0.1
  - Initial release used to generate our first qubit.
