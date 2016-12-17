
This package can load/save patterns in the GDS-II format only. In the future it may be useful to implement machine-specific pattern formats to force fracturing or dosing in an explicit manner.


<a id='Loading-patterns-1'></a>

## Loading patterns


To load a pattern, make sure you are `using FileIO`.

<a id='FileIO.load-Tuple{FileIO.File{FileIO.DataFormat{:GDS}}}' href='#FileIO.load-Tuple{FileIO.File{FileIO.DataFormat{:GDS}}}'>#</a>
**`FileIO.load`** &mdash; *Method*.



```
load(f::File{format"GDS"}; verbose=false)
```

A dictionary of top-level cells (`Cell` objects) found in the GDS-II file is returned. The dictionary keys are the cell names. The other cells in the GDS-II file are retained by `CellReference` or `CellArray` objects held by the top-level cells. Currently, cell references and arrays are not implemented.

The FileIO package recognizes files based on "magic bytes" at the start of the file. To permit any version of GDS-II file to be read, we consider the magic bytes to be the GDS HEADER tag (`0x0002`), preceded by the number of bytes in total (`0x0006`) for the entire HEADER record. The last well-documented version of GDS-II is v6.0.0, encoded as `0x0258 == 600`. LayoutEditor appears to save a version 7 as `0x0007`, which as far as I can tell is unofficial, and probably just permits more layers than 64, or extra characters in cell names, etc.

If the database scale is `1μm`, `1nm`, or `1pm`, then the corresponding unit is used for the resulting imported cells. Otherwise, an "anonymous unit" is used that will display as `u"2.4μm"` if the database scale is 2.4μm, say.

Warnings are thrown if the GDS-II file does not begin with a BGNLIB record following the HEADER record, but loading will proceed.

Encountering an ENDLIB record will discard the remainder of the GDS-II file without warning. If no ENDLIB record is present, a warning will be thrown.

The content of some records are currently discarded (mainly the more obscure GDS-II record types, but also BGNLIB and LIBNAME).


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L486-L516' class='documenter-source'>source</a><br>


<a id='Saving-patterns-1'></a>

## Saving patterns


To save a pattern, make sure you are `using FileIO`.

<a id='FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell,Vararg{Devices.Cells.Cell,N}}' href='#FileIO.save-Tuple{FileIO.File{FileIO.DataFormat{:GDS}},Devices.Cells.Cell,Vararg{Devices.Cells.Cell,N}}'>#</a>
**`FileIO.save`** &mdash; *Method*.



```
save(::Union{AbstractString,IO}, cell0::Cell{T}, cell::Cell...)

save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
name="GDSIILIB", userunit=1μm, modify=now(), acc=now(),
verbose=false)`
```

This bottom method is implicitly called when you use the convenient syntax of the top method: `save("/path/to/my.gds", cells_i_want_to_save...)`

The `name` keyword argument is used for the internal library name of the GDS-II file and is probably inconsequential for modern workflows.

The `userunit` keyword sets what 1.0 corresponds to when viewing this file in graphical GDS editors with inferior unit support.

The `modify` and `acc` keywords correspond to the date of last modification and the date of last accession. It would be unusual to have this differ from `now()`.

The `verbose` keyword argument allows you to monitor the output of [`traverse!`](cells.md#Devices.Cells.traverse!) and [`order!`](cells.md#Devices.Cells.order!) if something funny is happening while saving.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L429-L452' class='documenter-source'>source</a><br>


<a id='Internals-1'></a>

## Internals

<a id='Devices.GDS.GDSFloat' href='#Devices.GDS.GDSFloat'>#</a>
**`Devices.GDS.GDSFloat`** &mdash; *Type*.



`abstract GDSFloat <: Real`

Floating-point formats found in GDS-II files.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L64-L68' class='documenter-source'>source</a><br>

<a id='Devices.GDS.GDS64' href='#Devices.GDS.GDS64'>#</a>
**`Devices.GDS.GDS64`** &mdash; *Type*.



`bitstype 64 GDS64 <: GDSFloat`

"8-byte (64-bit) real" format found in GDS-II files.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L71-L75' class='documenter-source'>source</a><br>

<a id='Base.bits-Tuple{Devices.GDS.GDS64}' href='#Base.bits-Tuple{Devices.GDS.GDS64}'>#</a>
**`Base.bits`** &mdash; *Method*.



`bits(x::GDS64)`

A string giving the literal bit representation of a GDS64 number.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L78-L82' class='documenter-source'>source</a><br>

<a id='Base.bswap-Tuple{Devices.GDS.GDS64}' href='#Base.bswap-Tuple{Devices.GDS.GDS64}'>#</a>
**`Base.bswap`** &mdash; *Method*.



`bswap(x::GDS64)`

Byte-swap a GDS64 number. Used implicitly by `hton`, `ntoh` for endian conversion.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L85-L89' class='documenter-source'>source</a><br>

<a id='Devices.GDS.gdswrite' href='#Devices.GDS.gdswrite'>#</a>
**`Devices.GDS.gdswrite`** &mdash; *Function*.



```
gdswrite(io::IO, cell::Cell, dbs::Length)
```

Write a `Cell` to an IO buffer. The creation and modification date of the cell are written first, followed by the cell name, the polygons in the cell, and finally any references or arrays.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L245-L253' class='documenter-source'>source</a><br>


```
gdswrite{T<:Real}(io::IO, el::Polygon{T}, dbs)
gdswrite{T<:Length}(io::IO, poly::Polygon{T}, dbs)
```

Write a polygon to an IO buffer. The layer and datatype are written first, then the boundary of the polygon is written in a 32-bit integer format with specified database scale.

Note that polygons without units are presumed to be in microns.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L286-L297' class='documenter-source'>source</a><br>


```
gdswrite{T<:Real}(io::IO, ref::CellReference{T}, dbs)
gdswrite{T<:Length}(io::IO, el::CellReference{T}, dbs)
```

Write a [`CellReference`](cells.md#Devices.Cells.CellReference) to an IO buffer. The name of the referenced cell is written first. Reflection, magnification, and rotation info are written next. Finally, the origin of the cell reference is written.

Note that cell references without units on their `origin` are presumed to be in microns.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L316-L328' class='documenter-source'>source</a><br>


```
gdswrite(io::IO, a::CellArray, dbs)
```

Write a [`CellArray`](cells.md#Devices.Cells.CellArray) to an IO buffer. The name of the referenced cell is written first. Reflection, magnification, and rotation info are written next. After that the number of columns and rows are written. Finally, the origin, column vector, and row vector are written.

Note that cell references without units on their `origin` are presumed to be in microns.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L345-L357' class='documenter-source'>source</a><br>

<a id='Devices.GDS.strans' href='#Devices.GDS.strans'>#</a>
**`Devices.GDS.strans`** &mdash; *Function*.



```
strans(io::IO, ref)
```

Writes bytes to the IO stream (if needed) to encode x-reflection, magnification, and rotation settings of a reference or array. Returns the number of bytes written.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L384-L391' class='documenter-source'>source</a><br>

<a id='Base.write-Tuple{IO,Devices.GDS.GDS64}' href='#Base.write-Tuple{IO,Devices.GDS.GDS64}'>#</a>
**`Base.write`** &mdash; *Method*.



```
write(s::IO, x::GDS64)
```

Write a GDS64 number to an IO stream.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L159-L165' class='documenter-source'>source</a><br>

<a id='Base.read-Tuple{IO,Type{Devices.GDS.GDS64}}' href='#Base.read-Tuple{IO,Type{Devices.GDS.GDS64}}'>#</a>
**`Base.read`** &mdash; *Method*.



```
read(s::IO, ::Type{GDS64})
```

Read a GDS64 number from an IO stream.


<a target='_blank' href='https://github.com/PainterQubits/Devices.jl/tree/d7ef4fe3d1a90ef89942eab1a00f11db204e74bf/src/gds.jl#L168-L174' class='documenter-source'>source</a><br>

