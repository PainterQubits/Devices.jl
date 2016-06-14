
<a id='For-convenience-1'></a>

## For convenience

<a id='Devices.Tags.qrcode' href='#Devices.Tags.qrcode'>#</a>
**`Devices.Tags.qrcode`** &mdash; *Function*.



`qrcode{T<:Real}(a::AbstractString, name::ASCIIString, pixel::T=1.0; kwargs...)`

Renders a QR code of the string `a` with pixel size `pixel` to a new cell with `name`. The lower left of the QR code will be at the origin of the cell.

<a id='Devices.Tags.radialcut' href='#Devices.Tags.radialcut'>#</a>
**`Devices.Tags.radialcut`** &mdash; *Function*.



```
radialcut{T<:Real}(r::T, Θ, c::T; narc=197)
```

Returns a polygon for a radial cut (like a radial stub with no metal). The polygon has to be subtracted from a ground plane.

The parameter `c` is made available in the method signature rather than `a` because the focus of the arc (top of polygon) can easily centered in a waveguide. If it is desirable to control `a` instead, use trig: `a/2 = c*tan(Θ/2)`.

Parameters as follows, where X marks the origin and nothing above the origin is part of the resulting polygon:

```
                          Λ
                         ╱│╲
                        ╱ │ ╲
                       ╱  |  ╲
                 .    ╱   │Θ/2╲
                .    ╱    │----╲
               ╱    ╱   c │     ╲
              ╱    ╱      │      ╲
             ╱    ╱       │       ╲
            r    ╱        │        ╲
           ╱    ╱         │         ╲
          ╱    ╱──────────X──────────╲
         ╱    ╱ {──────── a ────────} ╲
        .    ╱                         ╲
       .    ╱                           ╲
           ╱                             ╲
          ╱                               ╲
         ╱                                 ╲
         ──┐                             ┌──
           └──┐                       ┌──┘
              └──┐                 ┌──┘
                 └──┐           ┌──┘
                    └───────────┘
                    (circular arc)
```

<a id='Devices.Tags.radialstub' href='#Devices.Tags.radialstub'>#</a>
**`Devices.Tags.radialstub`** &mdash; *Function*.



```
radialstub{T<:Real}(r::T, Θ, c::T, t::T; narc=197)
```

See also the documentation for `radialcut`.

Returns a polygon for a radial stub. The polygon has to be subtracted from a ground plane, and will leave a defect in the ground plane of uniform width `t` that outlines the (metallic) radial stub. `r` refers to the radius of the actual stub, not the radius of the circular arc bounding the ground plane defect. Likewise `c` has an analogous meaning to that in `radialcut` except it refers here to the radial stub, not the ground plane defect.

<a id='Devices.Tags.cpwlauncher' href='#Devices.Tags.cpwlauncher'>#</a>
**`Devices.Tags.cpwlauncher`** &mdash; *Function*.



```
cpwlauncher{T<:Real}(extround::T=5., trace0::T=300., trace1::T=5.,
    gap0::T=150., gap1::T=2.5, flatlen::T=250., taperlen::T=250.)
```

Draws half of a CPW launcher inside a new cell.

There are numerous keyword arguments to control the behavior:

  * `extround`: Rounding radius of the outermost corners; should be less than `gap0`.
  * `trace0`: Bond pad width.
  * `trace1`: Center trace width of next CPW segment.
  * `gap0`: Gap width adjacent to bond pad.
  * `gap1`: Gap width of next CPW segment.
  * `flatlen`: Bond pad length.
  * `taperlen`: Length of taper region between bond pad and next CPW segment.

The polygons in the method definition are labeled as:

```
 ___________
|p3 |  p2  |
|___|______|   p1
|   |        
|p4 |        |
|___|
```

Returns the new cell.

<a id='Devices.Tags.launch!' href='#Devices.Tags.launch!'>#</a>
**`Devices.Tags.launch!`** &mdash; *Function*.



```
launch!(p::Path; extround=5, trace0=300, trace1=5,
        gap0=150, gap1=2.5, flatlen=250, taperlen=250)
```

Add a launcher to the path. Somewhat intelligent in that the launcher will reverse its orientation depending on if it is at the start or the end of a path.

There are numerous keyword arguments to control the behavior:

  * `extround`: Rounding radius of the outermost corners; should be less than `gap0`.
  * `trace0`: Bond pad width.
  * `trace1`: Center trace width of next CPW segment.
  * `gap0`: Gap width adjacent to bond pad.
  * `gap1`: Gap width of next CPW segment.
  * `flatlen`: Bond pad length.
  * `taperlen`: Length of taper region between bond pad and next CPW segment.

Returns nothing.

