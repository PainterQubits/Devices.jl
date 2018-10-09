# Devices.jl

A [Julia](http://julialang.org) package for CAD of electronic devices, in particular
superconducting devices operating at microwave frequencies.

## Installation

### Julia 0.7 and above

Activate package mode by pressing `]` at the REPL in a Julia console.

+ `add https://github.com/PainterQubits/Devices.jl.git`

### Older versions

+ `Pkg.add("Clipper")`

When Clipper.jl is added, it will be built to compile shared library / DLL files. A
compiler will be downloaded for you on Windows.

+ `Pkg.clone("https://github.com/PainterQubits/Devices.jl.git")`

## Quick start

Let's mock up a transmission line with two launchers and some bridges across the
transmission line. We begin by making a cell with a rectangle in it:

```@example 1
using Devices, Devices.PreferMicrons, FileIO

cr = Cell("rect", nm)
r = centered(Rectangle(20μm, 40μm))
render!(cr, r, Rectangles.Plain(), GDSMeta(1,0))
save("units_rectonly.svg", cr; layercolors=Dict(0=>"black",1=>"red")); nothing # hide
```
<img src="units_rectonly.svg" style="width:1in;"/>

Note that when you use `Devices.PreferMicrons`, this will also enable the unqualified use of
the following units: `pm`, `nm`, `μm`, `mm`, `cm`, `dm`, `m`, `°`, `rad`. (By unqualified we
mean that the symbols are imported into the calling namespace and do not need to be prefixed
with a module name.) When adding length units together, if the units don't agree, the result
will be in microns. You can *instead* do `using` `Devices.PreferNanometers` if you want the
result to default to nanometers. (These are your two choices at the moment, though there's
nothing fundamentally limiting other possibilities: see `src/units.jl` for how to do this
for other units.)

When you specify the units for a `Cell`, you are specifying a database unit. Anything
rendered into this cell will be discretized into integer multiples of the database unit.
This means that nothing smaller than 1 nm can be represented accurately. Nonetheless,
this is typically a satisfactory choice for superconducting devices.

A rectangle made with a width and height parameter will default to having its lower-left
corner at the origin. `centered` will return a rectangle that is centered about the origin
instead.

The rectangle is then rendered into the cell. [`Rectangles.Plain()`](@ref) specifies a rendering
style. Other examples include [`Rectangles.Rounded`](@ref) (where the corners are rounded
off) or [`Rectangles.Undercut`](@ref). You can omit the style, in which case
`Rectangles.Plain()` will be assumed. `GDSMeta(1)` indicates the target GDS-II layer. You
can also specify the GDS-II datatype as a second argument, e.g. `GDSMeta(1,0)`.

In another cell, we make the transmission line with some launchers on both ends:

```@example 1
p = Path(μm)
sty = launch!(p)
straight!(p, 500μm, sty)
turn!(p, π/2, 150μm)
straight!(p, 500μm)
launch!(p)
cp = Cell("pathonly", nm)
render!(cp, p, GDSMeta(0))
save("units_pathonly.svg", cp; layercolors=Dict(0=>"black",1=>"red")); nothing # hide
```
<img src="units_pathonly.svg" style="width: 3in;"/>

Finally, let's put bridges across the feedline:

```@example 1
turnidx = Int((length(p)+1)/2) - 1 # the first straight segment of the path
simplify!(p, turnidx+(0:2))
attach!(p, CellReference(cr, Point(0.0μm, 0.0μm)), (40μm):(40μm):((pathlength(p[turnidx]))-40μm), i=turnidx)
c = Cell("decoratedpath", nm)
render!(c, p, GDSMeta(0))
save("units.svg", flatten(c); layercolors=Dict(0=>"black",1=>"red")); nothing # hide
```
<img src="units.svg" style="width: 3in;"/>

How easy was that?

You can save a GDS file for e-beam lithography, or an SVG for vector graphics by using
`save` with an appropriate extension:

```jl
save("/path/to/myoutput.gds", c)
save("/path/to/myoutput.svg", c)
```

Note that SVG support is experimental at the moment, and is not completely optimized. It is
however used in generating the graphics you see in this documentation. If you use Juno
for Atom, rendered cells are automatically previewed in the plot pane provided you enter
`Devices.@junographics` at the start of your session. If you use Jupyter/IJulia, rendered
cells are automatically returned as a result

### Example without using units

For compatibility and laziness reasons it is possible to use Devices.jl without units at
all. **If you do not provide units, all values are presumed to be in microns.** The syntax
is otherwise the same:

```jl
using Devices, FileIO

cr = Cell("rect")
r = centered(Rectangle(20,40))
render!(cr, r, GDSMeta(1))

p = Path()
sty = launch!(p)
straight!(p,500,sty)
turn!(p,π/2,150)
straight!(p,500)
launch!(p)
cp = Cell("pathonly")
render!(cp, p, GDSMeta(0))

turnidx = Int((length(p)+1)/2) - 1 # the first straight segment of the path
simplify!(p, turnidx+(0:2))
attach!(p, CellReference(cr, Point(0.0,0.0)), 40:40:((pathlength(p[turnidx]))-40), i=turnidx)
c = Cell("decoratedpath")
render!(c, p, GDSMeta(0))
```

Some caveats:
- You cannot mix and match unitful and unitless numbers (the latter are not presumed to be
  in microns in this case).
- It is somewhat annoying to maintain this behavior alongside unit support, so eventually I
  may drop support for this and require the use of units.

## Performance tips

Since Julia has a just-in-time compiler, the first time code is executed may take much
longer than any other times. This means that a lot of time will be wasted repeating
compilations if you run Devices.jl in a script like you would in other languages. For
readability, it is best to split up your CAD code into functions that have clearly named
inputs and perform a well-defined task. At present, for performance reasons, it is also best
to avoid writing functions with keyword arguments (though this will be addressed in Julia
1.0).

It is also best to avoid writing statements in global scope. In other words, put most of
your code in a function. Your CAD script should ideally look like the following:

```jl
using Devices, Devices.PreferMicrons, FileIO
using CoordinateTransformations
using Clipper

function subroutine1()
    # render some thing
end

function subroutine2()
    # render some other thing
end

function main()
    # my cad code goes here: do all of the things
    subroutine1()
    subroutine2()
    save("/path/to/out.gds", ...)
end

main() # execute main() at end of script.
```

You can then `include` this file from Julia to generate your pattern. Provided you write
your script this way, subsequent runs should be several times faster than the first if you
`include` the file again from the same Julia session.

## Troubleshooting

- If you cannot save the GDS file, try deleting any file that happens to be at the target
  path. A corrupted file at the target path may prevent saving.
- Decorated styles should not become part of compound styles, for now. Avoid this by
  decorating / attaching cell references at the end.
