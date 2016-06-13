
<a id='Devices.jl-1'></a>

# Devices.jl


A [Julia](http://julialang.org) package for designing CAD files for superconducting devices.


<a id='Installation-1'></a>

## Installation


  * Install [gdspy](http://gdspy.readthedocs.org), which is currently used only for rendering paths into polygons: `pip install gdspy`. Ensure that it is accessible from the Python installation that PyCall.jl is using.


  * Install [pyqrcode](https://github.com/mnooner256/pyqrcode), which is used for generating QR codes: `pip install pyqrcode`.


  * `Pkg.clone("https://github.com/ajkeller34/Clipper.jl.git")`
  * `Pkg.checkout("Clipper", "pointinpoly")`
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
