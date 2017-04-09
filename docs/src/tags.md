```@docs
    checkerboard!
```

Example:
```@example 1
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
checkerboard!(c, 20μm, 10, false, layer=2)
checkerboard!(c, 20μm, 10, true, layer=3)
save("checkers.svg", c); nothing # hide
```
<img src="../checkers.svg" style="width:2in;"/>

```@docs
    grating!
```

Example:
```@example 2
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
grating!(c, 100nm, 100nm, 5μm, layer=3)
save("grating.svg", c); nothing # hide
```
<img src="../grating.svg" style="width:2in;"/>

```@docs
    interdigit!
```

Example:
```@example 3
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
interdigit!(c, 1μm, 20μm, 1μm, 3μm, 5, true; layer = 5)
save("fingers.svg", c); nothing # hide
```
<img src="../fingers.svg" style="width:2in;"/>

```@docs
    radialcut!
```

Example:
```@example 4
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
radialcut!(c, 20μm, 90°, 5μm, layer=1)
save("radialcut.svg", c); nothing # hide
```
<img src="../radialcut.svg" style="width:2in;"/>

```@docs
    radialstub!
```

Example:
```@example 5
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
radialstub!(c, 20μm, 90°, 5μm, 1μm, layer=1)
save("radialstub.svg", c); nothing # hide
```
<img src="../radialstub.svg" style="width:2in;"/>
