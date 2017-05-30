```@docs
    checkerboard!
```

Example:
```@example 1
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
checkerboard!(c, 20μm, 10, false, GDSMeta(2))
checkerboard!(c, 20μm, 10, true, GDSMeta(3))
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
grating!(c, 100nm, 100nm, 5μm, GDSMeta(3))
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
interdigit!(c, 1μm, 20μm, 1μm, 3μm, 5, true, GDSMeta(5))
save("fingers.svg", c); nothing # hide
```
<img src="../fingers.svg" style="width:2in;"/>

```@docs
    qubit!
    qubit_claw!
```

Example:
```@example 4
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
p = Path(μm)
straight!(p, 100μm, Paths.CPW(10μm, 6μm))
qb = Cell("qubit", nm)
qubit_claw!(qb, 10μm, 6μm, 20μm, 100μm, 12μm, 5μm, 25μm, 30μm, GDSMeta(1))
attach!(p, CellReference(qb, Point(0.0μm, 0.0μm), rot=270°), 100μm)
render!(c, p, GDSMeta(0))
save("qubit.svg", c); nothing # hide
```
<img src="../qubit.svg" style="width:2in;"/>

```@docs
    radialcut!
```

Example:
```@example 5
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
radialcut!(c, 20μm, 90°, 5μm, GDSMeta(1))
save("radialcut.svg", c); nothing # hide
```
<img src="../radialcut.svg" style="width:2in;"/>

```@docs
    radialstub!
```

Example:
```@example 6
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
radialstub!(c, 20μm, 90°, 5μm, 1μm, GDSMeta(1))
save("radialstub.svg", c); nothing # hide
```
<img src="../radialstub.svg" style="width:2in;"/>
