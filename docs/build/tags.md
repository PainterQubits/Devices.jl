
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

<a id='Devices.Paths.launch!' href='#Devices.Paths.launch!'>#</a>
**`Devices.Paths.launch!`** &mdash; *Function*.


<a id='Devices.Tags.checkerboard' href='#Devices.Tags.checkerboard'>#</a>
**`Devices.Tags.checkerboard`** &mdash; *Function*.



```
checkerboard{T<:Real}(pixsize::T=10.;rows=28, kwargs...)
```

Generate a checkerboard pattern suitable for contrast curve measurement, or getting the base dose for BEAMER PEC.

Note that the tip radius of the Ambios XP-2 profilometer is 2.5μm.

<a id='Devices.Tags.pecbasedose' href='#Devices.Tags.pecbasedose'>#</a>
**`Devices.Tags.pecbasedose`** &mdash; *Function*.



```
pecbasedose(kwargs...)
```

Generate lines and spaces suitable for obtaining the base dose for BEAMER PEC (100 keV on Si).

To do: Modify to be more flexible for other substrates, beam energies, etc.

