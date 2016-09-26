
<a id='For-convenience-1'></a>

## For convenience

<a id='Devices.Tags.qrcode!' href='#Devices.Tags.qrcode!'>#</a>
**`Devices.Tags.qrcode!`** &mdash; *Function*.



```
qrcode!{T<:Coordinate}(a::AbstractString, c::Cell{T}; pixel::T=T(1), kwargs...)
```

Renders a QR code of the string `a` with pixel size `pixel` to cell `c`. The pixel size defaults to one of whatever the cell's unit is. The lower left of the QR code will be at the origin of the cell.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/6b7de71b98a4ee4bcbd137b0fc18fbb8c0b90366/src/tags.jl#L32-L40' class='documenter-source'>source</a><br>

<a id='Devices.Tags.radialcut' href='#Devices.Tags.radialcut'>#</a>
**`Devices.Tags.radialcut`** &mdash; *Function*.



```
radialcut{T<:Coordinate}(r::T, Θ, c::T; narc=197)
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


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/6b7de71b98a4ee4bcbd137b0fc18fbb8c0b90366/src/tags.jl#L67-L108' class='documenter-source'>source</a><br>

<a id='Devices.Tags.radialstub' href='#Devices.Tags.radialstub'>#</a>
**`Devices.Tags.radialstub`** &mdash; *Function*.



```
radialstub{T<:Coordinate}(r::T, Θ, c::T, t::T; narc=197)
```

See also the documentation for `radialcut`.

Returns a polygon for a radial stub. The polygon has to be subtracted from a ground plane, and will leave a defect in the ground plane of uniform width `t` that outlines the (metallic) radial stub. `r` refers to the radius of the actual stub, not the radius of the circular arc bounding the ground plane defect. Likewise `c` has an analogous meaning to that in `radialcut` except it refers here to the radial stub, not the ground plane defect.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/6b7de71b98a4ee4bcbd137b0fc18fbb8c0b90366/src/tags.jl#L125-L138' class='documenter-source'>source</a><br>

<a id='Devices.Tags.checkerboard' href='#Devices.Tags.checkerboard'>#</a>
**`Devices.Tags.checkerboard`** &mdash; *Function*.



```
checkerboard{T<:Coordinate}(pixsize::T=10.; rows=28, kwargs...)
```

Generate a checkerboard pattern suitable for contrast curve measurement, or getting the base dose for BEAMER PEC. Returns a uniquely named cell with the rendered polygons inside.

Note that the tip radius of the Ambios XP-2 profilometer in the KNI is 2.5μm.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/6b7de71b98a4ee4bcbd137b0fc18fbb8c0b90366/src/tags.jl#L247-L257' class='documenter-source'>source</a><br>

<a id='Devices.Tags.pecbasedose' href='#Devices.Tags.pecbasedose'>#</a>
**`Devices.Tags.pecbasedose`** &mdash; *Function*.



```
pecbasedose(kwargs...)
```

Generate lines and spaces suitable for obtaining the base dose for BEAMER PEC (100 keV on Si).

To do: Modify to be more flexible for other substrates, beam energies, etc.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/6b7de71b98a4ee4bcbd137b0fc18fbb8c0b90366/src/tags.jl#L275-L284' class='documenter-source'>source</a><br>

<a id='Devices.Tags.surf1d' href='#Devices.Tags.surf1d'>#</a>
**`Devices.Tags.surf1d`** &mdash; *Function*.



```
surf1d(length, width, contour_fn; zbins=20, step=1., max_seg_len=1.)
```

Given `length` and `width` of a rectangular patch, this generates a mesh for 3D surface PEC according to a particular contour function `contour_fn`. The meshing is done in the length direction (+y). The number of bins (layers) can be controlled with `zbins`, the maximum step change in the resist height is given by `step`, and the `max_seg_len` is the maximum segment length in the mesh.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/6b7de71b98a4ee4bcbd137b0fc18fbb8c0b90366/src/tags.jl#L335-L346' class='documenter-source'>source</a><br>

