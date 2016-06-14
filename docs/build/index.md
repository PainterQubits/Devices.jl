
<a id='Devices.jl-1'></a>

# Devices.jl


A [Julia](http://julialang.org) package for designing CAD files for superconducting devices.


<a id='Installation-1'></a>

## Installation


<a id='Install-Python-packages-1'></a>

### Install Python packages


  * Install [gdspy](http://gdspy.readthedocs.org), which is currently used only for rendering paths into polygons: `pip install gdspy`. Ensure that it is accessible from the Python installation that PyCall.jl is using. If the installation fails, it may be failing because it is trying to compile the Clipper library. We will use a Julia package for Clipper anyway. Try installing an older version of gdspy that does not have the Clipper library: `pip install 'gdspy==0.7.1' --force-reinstall`.


  * Install [pyqrcode](https://github.com/mnooner256/pyqrcode), which is used for generating QR codes: `pip install pyqrcode`.


<a id='Install-required-packages-1'></a>

### Install required packages


We use a custom version of the Clipper package, which we will need for making polygons compatible with GDS files.


  * `Pkg.clone("https://github.com/ajkeller34/Clipper.jl.git")`
  * `Pkg.checkout("Clipper", "pointinpoly")`


You will need to build the package to compile shared library / DLL files. This should just work on Mac OS X, and should also work on Windows provided you install Visual Studio and ensure that `vcvarsall.bat` and `cl.exe` are in your account's PATH variable.


  * `Pkg.build("Clipper")`


<a id='And-finally...-1'></a>

### And finally...


  * `Pkg.clone("https://github.com/ajkeller34/Devices.jl.git")`


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


  * If you cannot save the GDS file, try deleting any file that happens to be at the target path.
  * Decorated styles should not become part of compound styles, for now. Avoid this by decorating / attaching cell references at the end.

