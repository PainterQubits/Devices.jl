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

We use a custom version of the Clipper package, which we will need for making polygons
compatible with GDS files.

+ `Pkg.clone("https://github.com/PainterQubits/Clipper.jl.git")`
+ `Pkg.checkout("Clipper", "pointinpoly")`

You will need to build the package to compile shared library / DLL files.
This should just work on Mac OS X, and should also work on Windows provided you
install [Visual Studio Community](https://www.visualstudio.com/en-us/visual-studio-homepage-vs.aspx).
You should make sure to check the option to install Visual-C++
and ensure that `vcvarsall.bat` and `cl.exe` are in your
account's PATH variable. Probably these are located in:
`C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC` and
`C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin`, respectively.

+ `Pkg.build("Clipper")`
+ `Pkg.clone("https://github.com/PainterQubits/Devices.jl.git")`

Finally, for convenience you may want to have `Devices` load up every time
you open Julia. You can do this by adding the following to a file `.juliarc.jl`
in the directory returned by `homedir()`:

```
using Devices, Unitful, FileIO
using Unitful: μm, µm, nm, °, rad
```

You can then create and save CAD files with unit support as soon as Julia
starts up. This will also enable the unqualified use of microns, nanometers,
degrees, and radians (any other units you want to use will still need to be
imported from Unitful).

## Quick start

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
