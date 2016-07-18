
This package can load/save patterns in the GDS-II format only. In the future it may be useful to implement machine-specific pattern formats to force fracturing or dosing in an explicit manner.


<a id='Loading-patterns-1'></a>

## Loading patterns


To load a pattern, make sure you are `using FileIO`.

<a id='FileIO.load-Tuple{FileIO.File{FileIO.DataFormat{:GDS}}}' href='#FileIO.load-Tuple{FileIO.File{FileIO.DataFormat{:GDS}}}'>#</a>
**`FileIO.load`** &mdash; *Method*.



```
load(f::File{format"GDS"}; verbose=false)
```

A dictionary of top-level cells (`Cell` objects) found in the GDS-II file is returned. The dictionary keys are the cell names. The other cells in the GDS-II file are retained by `CellReference` or `CellArray` objects held by the top-level cells. Currently, cell references and arrays are not implemented, and we do not handle the scale properly, as this is a work in progress.

The FileIO package treats the HEADER record as "magic bytes," and therefore only GDS-II version 6.0.0 can be read. LayoutEditor appears to save version 7, which as far as I can tell is unofficial, and probably just permits more layers than 64, or extra characters in cell names, etc. We will add support for this.

Warnings are thrown if the GDS-II file does not begin with a BGNLIB record following the HEADER record, but loading will proceed.

Encountering an ENDLIB record will discard the remainder of the GDS-II file without warning. If no ENDLIB record is present, a warning will be thrown.

The content of some records are currently discarded (mainly the more obscure GDS-II record types, but also BGNLIB and LIBNAME).


<a id='Saving-patterns-1'></a>

## Saving patterns


To save a pattern, make sure you are `using FileIO`.

<a id='FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell{T<:Real},Vararg{Devices.Cells.Cell{T<:Real}}}' href='#FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell{T<:Real},Vararg{Devices.Cells.Cell{T<:Real}}}'>#</a>
**`FileIO.save`** &mdash; *Method*.



```
save(::Union{AbstractString,IO}, cell0::Cell, cell::Cell...)

save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
name="GDSIILIB", precision=1e-9, unit=1e-6, modify=now(), acc=now(),
verbose=false)`
```

This bottom method is implicitly called when you use the convenient syntax of the top method: `save("/path/to/my.gds", cells_i_want_to_save...)`

The `name` keyword argument is used for the internal library name of the GDS-II file and is probably inconsequential for modern workflows.

The `verbose` keyword argument allows you to monitor the output of [`traverse!`](cells.md#Devices.Cells.traverse!) and [`order!`](cells.md#Devices.Cells.order!) if something funny is happening while saving.


<a id='Internals-1'></a>

## Internals

<a id='Devices.GDS.GDSFloat' href='#Devices.GDS.GDSFloat'>#</a>
**`Devices.GDS.GDSFloat`** &mdash; *Type*.



`abstract GDSFloat <: Real`

Floating-point formats found in GDS-II files.

<a id='Devices.GDS.GDS64' href='#Devices.GDS.GDS64'>#</a>
**`Devices.GDS.GDS64`** &mdash; *Type*.



`bitstype 64 GDS64 <: GDSFloat`

"8-byte (64-bit) real" format found in GDS-II files.

<a id='Base.bits-Tuple{Devices.GDS.GDS64}' href='#Base.bits-Tuple{Devices.GDS.GDS64}'>#</a>
**`Base.bits`** &mdash; *Method*.



`bits(x::GDS64)`

A string giving the literal bit representation of a GDS64 number.

<a id='Base.bswap-Tuple{Devices.GDS.GDS64}' href='#Base.bswap-Tuple{Devices.GDS.GDS64}'>#</a>
**`Base.bswap`** &mdash; *Method*.



`bswap(x::GDS64)`

Byte-swap a GDS64 number. Used implicitly by `hton`, `ntoh` for endian conversion.

<a id='Devices.GDS.gdswrite' href='#Devices.GDS.gdswrite'>#</a>
**`Devices.GDS.gdswrite`** &mdash; *Function*.



```
gdswrite(io::IO, cell::Cell)
```

Write a `Cell` to an IO buffer. The creation and modification date of the cell are written first, followed by the cell name, the polygons in the cell, and finally any references or arrays.


```
gdswrite{T}(io::IO, el::AbstractPolygon{T}; unit=1e-6, precision=1e-9)
```

Write a polygon to an IO buffer. The layer and datatype are written first, then the `AbstractPolygon{T}` object is converted to a `Polygon{T}`, and the boundary of the polygon is written in a 32-bit integer format with specified database unit and precision.


```
gdswrite(io::IO, el::CellReference; unit=1e-6, precision=1e-9)
```

Write a cell reference to an IO buffer. The name of the referenced cell is written first. Reflection, magnification, and rotation info are written next. Finally, the origin of the cell reference is written.


```
gdswrite(io::IO, el::CellArray; unit=1e-6, precision=1e-9)
```

Write a cell array to an IO buffer. The name of the referenced cell is written first. Reflection, magnification, and rotation info are written next. After that the number of columns and rows are written. Finally, the origin, column vector, and row vector are written.

<a id='Devices.GDS.strans' href='#Devices.GDS.strans'>#</a>
**`Devices.GDS.strans`** &mdash; *Function*.



```
strans(io::IO, ref)
```

Writes bytes to the IO stream (if needed) to encode x-reflection, magnification, and rotation settings of a reference or array. Returns the number of bytes written.

<a id='Base.write-Tuple{IO,Devices.GDS.GDS64}' href='#Base.write-Tuple{IO,Devices.GDS.GDS64}'>#</a>
**`Base.write`** &mdash; *Method*.



```
write(s::IO, x::GDS64)
```

Write a GDS64 number to an IO stream.

<a id='Base.read-Tuple{IO,Type{Devices.GDS.GDS64}}' href='#Base.read-Tuple{IO,Type{Devices.GDS.GDS64}}'>#</a>
**`Base.read`** &mdash; *Method*.



```
read(stream, type)
```

Read a value of the given type from a stream, in canonical binary representation.


```
read(s::IO, ::Type{GDS64})
```

Read a GDS64 number from an IO stream.

