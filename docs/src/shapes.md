Examples on this page assume you have done `using Devices, Devices.PreferMicrons, FileIO`.

```@docs
    bridge!
```

```@docs
    device_template!
```

```@docs
    checkerboard!
```

Example:
```@example 1
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
checkerboard!(c, 20μm, 10, false, GDSMeta(2))
checkerboard!(c, 20μm, 10, true, GDSMeta(3))
save("checkers.svg", flatten(c)); nothing # hide
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
save("grating.svg", flatten(c)); nothing # hide
```
<img src="../grating.svg" style="width:2in;"/>

```@docs
    interdigit!
```

Simple usage:
```@example 3
using Devices, Devices.PreferMicrons, FileIO # hide
fingers = Cell("fingers", nm)
wide, length, fingergap, fingeroffset, npairs, skiplast = 1μm, 20μm, 1μm, 3μm, 5, true
interdigit!(fingers, wide, length, fingergap, fingeroffset, npairs, skiplast, GDSMeta(5))
save("fingers_only.svg", flatten(fingers)); nothing # hide
```
<img src="../fingers_only.svg" style="width:2in;"/>

Example of how to make an interdigitated capacitor inline with a feedline:
```@example 4
using Devices, Devices.PreferMicrons, FileIO # hide
import Clipper
c = Cell("main", nm)
p = Path(μm)
trace, gap = 17μm, 3μm
straight!(p, 50μm, Paths.CPW(trace, gap))
straight!(p, 23μm, Paths.NoRender())
straight!(p, 50μm, Paths.CPW(trace, gap))
fingers = Cell("fingers", nm)
wide, length, fingergap, fingeroffset, npairs, skiplast = 1μm, 20μm, 1μm, 3μm, 5, true
interdigit!(fingers, wide, length, fingergap, fingeroffset, npairs, skiplast, GDSMeta(5))
finger_mask = Rectangle(width(bounds(fingers)), height(bounds(fingers))+2*gap) -
    Point(0μm, gap)
inverse_fingers = Cell("invfingers", nm)
plgs = clip(Clipper.ClipTypeDifference, [finger_mask], polygon.(elements(fingers)))
for plg in plgs
    render!(inverse_fingers, plg, GDSMeta(0))
end
attach!(p, CellReference(inverse_fingers, Point(0μm, -upperright(bounds(fingers)).y/2)), 0μm, i=2)
render!(c, p, GDSMeta(0))
save("fingers.svg", flatten(c)); nothing # hide
```
<img src="../fingers.svg" style="width:4in;"/>

```@docs
    layerpixels!
```

Example:
```@example 5
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("pix", nm)
layerpixels!(c, [1 2 3; -1 2 4], 5μm)
save("layerpixels.svg", flatten(c)); nothing # hide
```
<img src="../layerpixels.svg" style="width:2in;"/>


```@docs
    qubit!
    qubit_claw!
```

Example:
```@example 6
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
p = Path(μm)
straight!(p, 100μm, Paths.CPW(10μm, 6μm))
qbclaw = Cell("qubit_claw", nm)
trace, gap, claw_width, claw_length, claw_gap, ground_gap, qubit_width, qubit_gap =
    10μm, 6μm, 20μm, 100μm, 12μm, 5μm, 25μm, 30μm
qubit_claw!(qbclaw, trace, gap, claw_width, claw_length, claw_gap, ground_gap,
    qubit_width, qubit_gap, GDSMeta(1))
qb = Cell("qubit", nm)
qubit_length, qubit_cap_bottom_gap, gap_between_leads_for_jjs, lead_width, junc_pad_spacing =
    500μm, 30μm, 2μm, 4μm, 10μm
qubit!(qb, qubit_length, qubit_width, qubit_gap, qubit_cap_bottom_gap,
    gap_between_leads_for_jjs, lead_width, junc_pad_spacing, GDSMeta(2))
attach!(p, CellReference(qbclaw, Point(0.0μm, 0.0μm)), 100μm)
qref_offset = Point(claw_width + claw_gap + ground_gap + qubit_gap + qubit_length, 0.0μm)
attach!(p, CellReference(qb, qref_offset, rot = 90°), 100μm)
render!(c, p, GDSMeta(0))
save("qubit.svg", flatten(c)); nothing # hide
```
<img src="../qubit.svg" style="width:4in;"/>

```@docs
    radialcut!
```

Example:
```@example 7
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
radialcut!(c, 20μm, 90°, 5μm, GDSMeta(1))
save("radialcut.svg", flatten(c)); nothing # hide
```
<img src="../radialcut.svg" style="width:2in;"/>

```@docs
    radialstub!
```

Example:
```@example 8
using Devices, Devices.PreferMicrons, FileIO # hide
c = Cell("main", nm)
radialstub!(c, 20μm, 90°, 5μm, 1μm, GDSMeta(1))
save("radialstub.svg", flatten(c)); nothing # hide
```
<img src="../radialstub.svg" style="width:2in;"/>


## LCDFonts

LCDFonts allows the user with `lcdstring!` to render a string which is displayed in a cell
with a per character resolution of 5x10. Three functions `characters_demo`, `scripted_demo`,
`referenced_characters_demo` are exported for demonstration but also serves as a test of the
functionality.

```@docs
    lcdstring!
    characters_demo
    scripted_demo
    referenced_characters_demo
```

### Inline demonstrations

```@example 9
using Devices, FileIO # hide
path_to_output_gds = "characters.svg" # hide
characters_demo(path_to_output_gds, true)
```
<img src="../characters.svg" style="width:6in;"/>

```@example 10
using Devices, FileIO # hide
path_to_output_gds = "scripted.svg" # hide
scripted_demo(path_to_output_gds, true);
```
<img src="../scripted.svg" style="width:4in;"/>
