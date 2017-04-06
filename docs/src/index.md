# Devices.jl

A [Julia](http://julialang.org) package for designing CAD files for superconducting devices.

## Installation

### Install Python packages

+ Install [gdspy](http://gdspy.readthedocs.org), which is currently used only
  for rendering paths into polygons. If you're on a Mac, you can probably run
  `pip install gdspy` from the command line. If you're on Windows and using
  Anaconda for your Python installation, you can install gdspy from the conda
  package manager. If installation fails, it may be failing because it is trying
  to compile the Clipper library. We will use a Julia package for Clipper anyway.
  Try installing an older version of gdspy that does not have the Clipper library:
  `pip install 'gdspy==0.7.1' --force-reinstall` or the Windows equivalent.

+ You should ensure that PyCall.jl is using the Python installation
  into which you installed gdspy. You can do this by running the following in Julia:
  `ENV["PYTHON"] = "path_to_python"; Pkg.build("PyCall.jl")`. Of course you should
  replace with your actual path to Python; on Windows it may be
  "C:\\ \\Anaconda\\ \\python.exe" for instance). If PyCall is not already installed,
  replace `build` with `add`.

+ Install [pyqrcode](https://github.com/mnooner256/pyqrcode), which is used for
  generating QR codes: `pip install pyqrcode`. You need to do this even if
  you don't plan on making QR codes (I'm not sure how to make it a conditional
  dependency).

### Install Julia packages

+ `Pkg.add("Clipper")`

(We used to use a custom version of the Clipper.jl package, but thanks to upstream changes
that is no longer necessary.) When Clipper.jl is added, it will be built to compile shared
library / DLL files.

+ `Pkg.clone("https://github.com/PainterQubits/Devices.jl.git")`

## Quick start

### Example using units

```
using Devices, FileIO
using Devices.PreferMicrons

example forthcoming
```

You can then create and save CAD files with unit support. This will also enable the
unqualified use of the following units: `pm, nm, μm, mm, cm, dm, m, °, rad`. When adding
length units together, if the units don't agree, the result will be in microns.
You can *instead* do `using Devices.PreferNanometers` if you want the result to default to
nanometers. These are your two choices at the moment, though there's nothing fundamentally
limiting other possibilities.

Note that if you'd prefer, you can add the `using` statements to a file `.juliarc.jl` in
the directory returned by `homedir()` if you want Julia to load Devices.jl every time you
open it.


### Example without using units

For compatibility and laziness reasons it is possible to use Devices.jl without units at
all. If you do not provide units, all values are presumed to be in microns. Most but not all
functionality is possible if you do not use units.

```
using Devices, FileIO

p = Path()
style = launch!(p)
straight!(p,500,style)
turn!(p,π/2,150)
straight!(p,500)
launch!(p)
c = Cell("main")
render!(c, p)
save("test.gds", c)
```

## Troubleshooting

- If you cannot save the GDS file, try deleting any file that happens to be
  at the target path. A corrupted file at the target path may prevent saving.
- Decorated styles should not become part of compound styles, for now. Avoid
  this by decorating / attaching cell references at the end.
