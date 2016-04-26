# Devices.jl

A [Julia](http://julialang.org) package for designing CAD files for superconducting devices.

## Installation

+ Install [gdspy](http://gdspy.readthedocs.org), which is currently used as the
backend for rendering GDS files and previewing them: `pip install gdspy`.
Ensure that it is accessible from the Python installation that PyCall.jl is using.

+ Install [pyclipper](https://github.com/greginvm/pyclipper), which is used for
polygon offsetting: `pip install pyclipper`.

+ Using features implemented with [GPC](http://www.cs.man.ac.uk/~toby/gpc/) require
building shared libraries from the C code.

+ `Pkg.clone("https://github.com/ajkeller34/Devices.jl.git")`

## Quick start

```
using Devices

p = Path()
style = launch!(p)
straight!(p,500,style)
turn!(p,π/2,150)
straight!(p,500)
launch!(p)
render(p)
view()
```
