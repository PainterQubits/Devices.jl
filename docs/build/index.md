
<a id='Devices.jl-1'></a>

# Devices.jl


A [Julia](http://julialang.org) package for designing CAD files for superconducting devices.


<a id='Installation-1'></a>

## Installation


  * Install [gdspy](http://gdspy.readthedocs.org), which is currently used only for rendering paths into polygons: `pip install gdspy`. Ensure that it is accessible from the Python installation that PyCall.jl is using.


  * Install [pyclipper](https://github.com/greginvm/pyclipper), which is used for polygon offsetting: `pip install pyclipper`.


  * Install [pyqrcode](https://github.com/mnooner256/pyqrcode), which is used for generating QR codes: `pip install pyqrcode`.


  * Using features implemented with [GPC](http://www.cs.man.ac.uk/~toby/gpc/) require building shared libraries from the C code.


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

