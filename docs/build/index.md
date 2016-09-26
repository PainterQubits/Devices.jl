
<a id='Devices.jl-1'></a>

# Devices.jl


A [Julia](http://julialang.org) package for designing CAD files for superconducting devices.


<a id='Installation-1'></a>

## Installation


<a id='Install-Python-packages-1'></a>

### Install Python packages


  * Install [gdspy](http://gdspy.readthedocs.org), which is currently used only for rendering paths into polygons: `pip install gdspy`. Ensure that it is accessible from the Python installation that PyCall.jl is using. If the installation fails, it may be failing because it is trying to compile the Clipper library. We will use a Julia package for Clipper anyway. Try installing an older version of gdspy that does not have the Clipper library: `pip install 'gdspy==0.7.1' --force-reinstall`.
  * Install [pyqrcode](https://github.com/mnooner256/pyqrcode), which is used for generating QR codes: `pip install pyqrcode`.


<a id='Install-Julia-packages-1'></a>

### Install Julia packages


We use a custom version of the Clipper package, which we will need for making polygons compatible with GDS files.


  * `Pkg.clone("https://github.com/PainterQubits/Clipper.jl.git")`
  * `Pkg.checkout("Clipper", "pointinpoly")`


You will need to build the package to compile shared library / DLL files. This should just work on Mac OS X, and should also work on Windows provided you install [Visual Studio](https://www.visualstudio.com/en-us/visual-studio-homepage-vs.aspx) and ensure that `vcvarsall.bat` and `cl.exe` are in your account's PATH variable. Probably these are located in: `C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC` and `C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin`, respectively.


  * `Pkg.build("Clipper")`
  * `Pkg.clone("https://github.com/PainterQubits/Devices.jl.git")`


Finally, for convenience you may want to have `Devices` load up every time you open Julia. You can do this by adding the following to a file `.juliarc.jl` in the directory returned by `homedir()`:


```
using Devices, Unitful, FileIO
using Unitful: μm, µm, nm, °, rad
```


You can then create and save CAD files with unit support as soon as Julia starts up. This will also enable the unqualified use of microns, nanometers, degrees, and radians (any other units you want to use will still need to be imported from Unitful).


<a id='Quick-start-1'></a>

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


<a id='Troubleshooting-1'></a>

## Troubleshooting


  * If you cannot save the GDS file, try deleting any file that happens to be at the target path. A corrupted file at the target path may prevent saving.
  * Decorated styles should not become part of compound styles, for now. Avoid this by decorating / attaching cell references at the end.

