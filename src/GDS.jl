module GDS

import Base: bswap, bits, convert, write
import Devices: AbstractPolygon
using ..Points
import ..Rectangles: Rectangle
import ..Polygons: Polygon
using ..Cells

import FileIO: File, @format_str, load, save, stream, magic, skipmagic

export GDS64
export gdsbegin, gdsend, gdswrite

# Used if a polygon does not specify a layer or datatype.
const DEFAULT_LAYER = 0
const DEFAULT_DATATYPE = 0

const GDSVERSION   = UInt16(600)
const HEADER       = 0x0002
const BGNLIB       = 0x0102
const LIBNAME      = 0x0206
const UNITS        = 0x0305
const ENDLIB       = 0x0400
const BGNSTR       = 0x0502
const STRNAME      = 0x0606
const ENDSTR       = 0x0700
const BOUNDARY     = 0x0800
const PATH         = 0x0900
const SREF         = 0x0A00
const AREF         = 0x0B00
const TEXT         = 0x0C00
const LAYER        = 0x0D02
const DATATYPE     = 0x0E02
const WIDTH        = 0x0F03
const XY           = 0x1003
const ENDEL        = 0x1100
const SNAME        = 0x1206
const COLROW       = 0x1302
const TEXTNODE     = 0x1400
const NODE         = 0x1500
const TEXTTYPE     = 0x1602
const PRESENTATION = 0x1701
const STRING       = 0x1906
const STRANS       = 0x1A01
const MAG          = 0x1B05
const ANGLE        = 0x1C05
const REFLIBS      = 0x1F06
const FONTS        = 0x2006
const PATHTYPE     = 0x2102
const GENERATIONS  = 0x2202
const ATTRTABLE    = 0x2306
const EFLAGS       = 0x2601
const NODETYPE     = 0x2A02
const PROPATTR     = 0x2B02
const PROPVALUE    = 0x2C06

"""
`abstract GDSFloat <: Real`

Floating-point formats found in GDS-II files.
"""
abstract GDSFloat <: Real

"""
`bitstype 64 GDS64 <: GDSFloat`

"8-byte (64-bit) real" format found in GDS-II files.
"""
bitstype 64 GDS64 <: GDSFloat

"""
`bits(x::GDS64)`

A string giving the literal bit representation of a GDS64 number.
"""
bits(x::GDS64) = bits(reinterpret(UInt64,x))

"""
`bswap(x::GDS64)`

Byte-swap a GDS64 number. Used implicitly by `hton`, `ntoh` for endian conversion.
"""
function bswap(x::GDS64)
    if VERSION > v"0.5-"
        Core.Intrinsics.box(GDS64, Base.bswap_int(Core.Intrinsics.unbox(GDS64,x)))
    else
        Intrinsics.box(GDS64, Base.bswap_int(Intrinsics.unbox(GDS64,x)))
    end
end

function convert{T<:AbstractFloat}(::Type{GDS64}, y::T)
    !isfinite(y) && error("May we suggest you consider using ",
                          "only finite numbers in your CAD file.")

    inty      = reinterpret(UInt64, convert(Float64, y))
    neg       = 0x8000000000000000
    pos       = 0x7fffffffffffffff
    smask     = 0x000fffffffffffff
    hiddenbit = 0x0010000000000000
    z         = 0x0000000000000000

    significand = (smask & inty) | hiddenbit
    floatexp    = (pos & inty) >> 52

    if floatexp <= 0x00000000000002fa   # 762
        # too small to represent
        result = 0x0000000000000000
    else
        while floatexp & 3 != 2         # cheap modulo
            floatexp += 1
            significand >>= 1
        end
        result = ((floatexp-766) >> 2) << 56
        result |= (significand << 3)
    end
    reinterpret(GDS64, (y < 0. ? result | neg : result & pos))
end

function convert(::Type{Float64}, y::GDS64)
    inty   = reinterpret(UInt64, y)
    smask  = 0x00ffffffffffffff
    emask  = 0x7f00000000000000
    result = 0x8000000000000000 & inty

    significand = (inty & smask)
    significand == 0 && return result
    significand >>= 4

    exponent = (((inty & emask) >> 56) * 4 + 767)
    while significand & 0x0010000000000000 == 0
        significand <<= 1
        exponent -= 1
    end

    significand &= 0x000fffffffffffff
    result |= (exponent << 52)
    result |= significand
    reinterpret(Float64, result)
end

gdswerr(x) = error("Wrong data type for token 0x$(hex(x,4)).")

"""
`write(s::IO, x::GDS64)`

Write a GDS64 number to an IO stream.
"""
write(s::IO, x::GDS64) = write(s, reinterpret(UInt64, x))    # check for v0.5

function gdswrite(io::IO, x::UInt16)
    (x & 0x00ff != 0x0000) && gdswerr(x)
    write(io, hton(UInt16(4))) +
    write(io, hton(x))
end

function gdswrite(io::IO, x::UInt16, y::Number...)
    l = sizeof(y) + 2
    l+2 > 0xFFFF && error("Too many bytes in record for GDS-II format.")    # 7fff?
    write(io, hton(UInt16(l+2))) +
    write(io, hton(x), map(hton, y)...)
end

function gdswrite{T<:Real}(io::IO, x::UInt16, y::AbstractArray{T,1})
    l = sizeof(y) + 2
    l+2 > 0xFFFF && error("Too many bytes in record for GDS-II format.")    # 7fff?
    write(io, hton(UInt16(l+2))) +
    write(io, hton(x)) +
    write(io, map(hton, y))
end

function gdswrite(io::IO, x::UInt16, y::ASCIIString)
    (x & 0x00ff != 0x0006) && gdswerr(x)
    z = y
    mod(length(z),2) == 1 && (z*="\0")
    l = length(y) + 2
    l+2 > 0xFFFF && error("Too many bytes in record for GDS-II format.")    # 7fff?
    write(io, hton(UInt16(l+2))) +
    write(io, hton(x), z)
end

gdswrite(io::IO, x::UInt16, y::AbstractFloat...) =
    gdswrite(io, x, map(GDS64, y)...)

function gdswrite(io::IO, x::UInt16, y::Int...)
    datatype = x & 0x00ff
    if datatype == 0x0002
        gdswrite(io, x, map(Int16, y)...)
    elseif datatype == 0x0003
        gdswrite(io, x, map(Int32, y)...)
    elseif datatype == 0x0005
        gdswrite(io, x, map(float, y)...)
    else
        gdswerr(x)
    end
end

function gdsbegin(io::IO, libname::ASCIIString,
        precision, unit, modify::DateTime, acc::DateTime)
    y    = UInt16(Dates.Year(modify))
    mo   = UInt16(Dates.Month(modify))
    d    = UInt16(Dates.Day(modify))
    h    = UInt16(Dates.Hour(modify))
    min  = UInt16(Dates.Minute(modify))
    s    = UInt16(Dates.Second(modify))

    y1   = UInt16(Dates.Year(acc))
    mo1  = UInt16(Dates.Month(acc))
    d1   = UInt16(Dates.Day(acc))
    h1   = UInt16(Dates.Hour(acc))
    min1 = UInt16(Dates.Minute(acc))
    s1   = UInt16(Dates.Second(acc))

    # gdswrite(io, HEADER, GDSVERSION) +
    gdswrite(io, BGNLIB, y,mo,d,h,min,s, y1,mo1,d1,h1,min1,s1) +
    gdswrite(io, LIBNAME, libname) +
    gdswrite(io, UNITS, precision/unit, precision)
end

"""
```
gdswrite(io::IO, cell::Cell)
```

Write a `Cell` to an IO buffer. The creation and modification date of the cell
are written first, followed by the cell name, the polygons in the cell,
and finally any references or arrays.
"""
function gdswrite(io::IO, cell::Cell)
    namecheck(cell.name)

    y    = UInt16(Dates.Year(cell.create))
    mo   = UInt16(Dates.Month(cell.create))
    d    = UInt16(Dates.Day(cell.create))
    h    = UInt16(Dates.Hour(cell.create))
    min  = UInt16(Dates.Minute(cell.create))
    s    = UInt16(Dates.Second(cell.create))

    modify = now()
    y1   = UInt16(Dates.Year(modify))
    mo1  = UInt16(Dates.Month(modify))
    d1   = UInt16(Dates.Day(modify))
    h1   = UInt16(Dates.Hour(modify))
    min1 = UInt16(Dates.Minute(modify))
    s1   = UInt16(Dates.Second(modify))

    bytes = gdswrite(io, BGNSTR, y,mo,d,h,min,s, y1,mo1,d1,h1,min1,s1)
    bytes += gdswrite(io, STRNAME, cell.name)
    for x in cell.elements
        bytes += gdswrite(io, x)
    end
    for x in cell.refs
        bytes += gdswrite(io, x)
    end
    bytes += gdswrite(io, ENDSTR)
end

"""
```
gdswrite{T}(io::IO, el::AbstractPolygon{T}; unit=1e-6, precision=1e-9)
```

Write a polygon to an IO buffer. The layer and datatype are written first,
then the `AbstractPolygon{T}` object is converted to a `Polygon{T}`, and
the boundary of the polygon is written in a 32-bit integer format with specified
database unit and precision.
"""
function gdswrite{T}(io::IO, el::AbstractPolygon{T}; unit=1e-6, precision=1e-9)
    poly  =  convert(Polygon{T}, el)
    bytes =  gdswrite(io, BOUNDARY)
    props = el.properties
    layer = haskey(props, :layer) ? props[:layer] : DEFAULT_LAYER
    datatype = haskey(props, :datatype) ? props[:datatype] : DEFAULT_DATATYPE
    bytes += gdswrite(io, LAYER, layer)
    bytes += gdswrite(io, DATATYPE, datatype)

    xy = reinterpret(T, poly.p)
    xy .*= unit/precision
    xy = round(xy)
    xyInt =  convert(Array{Int32,1}, xy)
    push!(xyInt, xyInt[1], xyInt[2]) # closed polygons
    bytes += gdswrite(io, XY, xyInt)
    bytes += gdswrite(io, ENDEL)
end

"""
```
gdswrite(io::IO, el::CellReference; unit=1e-6, precision=1e-9)
```

Write a cell reference to an IO buffer. The name of the referenced cell is
written first. Reflection, magnification, and rotation info are written next.
Finally, the origin of the cell reference is written.
"""
function gdswrite(io::IO, ref::CellReference; unit=1e-6, precision=1e-9)
    bytes =  gdswrite(io, SREF)
    bytes += gdswrite(io, SNAME, ref.cell.name)

    bytes += strans(io, ref)

    o = ref.origin * unit/precision
    x,y = Int(round(getx(o))), Int(round(gety(o)))
    bytes += gdswrite(io, XY, x, y)
    bytes += gdswrite(io, ENDEL)
end

"""
```
gdswrite(io::IO, el::CellArray; unit=1e-6, precision=1e-9)
```

Write a cell array to an IO buffer. The name of the referenced cell is
written first. Reflection, magnification, and rotation info are written next.
After that the number of columns and rows are written. Finally, the origin,
column vector, and row vector are written.
"""
function gdswrite(io::IO, a::CellArray; unit=1e-6, precision=1e-9)
    colrowcheck(a.col)
    colrowcheck(a.row)

    bytes =  gdswrite(io, AREF)
    bytes += gdswrite(io, SNAME, a.cell.name)

    bytes += strans(io, a)

    gdswrite(io, COLROW, a.col, a.row)
    o = a.origin * unit/precision
    dc = a.deltacol * unit/precision
    dr = a.deltarow * unit/precision
    x,y = Int(round(getx(o))), Int(round(gety(o)))
    cx,cy = Int(round(getx(dc)*(a.col))), Int(round(gety(dc)*(a.col)))
    rx,ry = Int(round(getx(dr)*(a.row))), Int(round(gety(dr)*(a.row)))
    cx += x; cy += y; rx += x; ry += y;
    bytes += gdswrite(io, XY, x, y, cx, cy, rx, ry)
    bytes += gdswrite(io, ENDEL)
end

"""
```
strans(io::IO, ref)
```

Writes bytes to the IO stream (if needed) to encode x-reflection, magnification,
and rotation settings of a reference or array. Returns the number of bytes written.
"""
function strans(io::IO, ref)
    bits = 0x0000

    ref.xrefl && (bits += 0x8000)
    if ref.mag != 1.0
        bits += 0x0004
    end
    if ref.rot != 0.0
        bits += 0x0002
    end
    bytes = 0
    bits != 0 && (bytes += gdswrite(io, STRANS, bits))
    bits & 0x0004 > 0 && (bytes += gdswrite(io, MAG, ref.mag))
    bits & 0x0002 > 0 && (bytes += gdswrite(io, ANGLE, ref.rot))
    bytes
end


function colrowcheck(c)
    (0 <= c <= 32767) ||
        warn("The GDS-II spec only permits 0 to 32767 rows or columns.")
end

function namecheck(a::ASCIIString)
    invalid = r"[^A-Za-z0-9_\?\0\$]+"
    (length(a) > 32 || ismatch(invalid, a)) && warn(
        "The GDS-II spec says that cell names must only have characters A-Z, a-z, ",
        "0-9, '_', '?', '\$', and be less than or equal to 32 characters long."
    )
end

function layercheck(layer)
    (0 <= layer <= 63) || warn("The GDS-II spec only permits layers from 0 to 63.")
end

gdsend(io::IO) = gdswrite(io, ENDLIB)

"""
```
save(::Union{AbstractString,IO}, cell0::Cell, cell::Cell...)

save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
name="GDSIILIB", precision=1e-9, unit=1e-6, modify=now(), acc=now(),
verbose=false)`
```

This bottom method is implicitly called when you use the convenient syntax of
the top method: `save("/path/to/my.gds", cells_i_want_to_save...)`

The `name` keyword argument is used for the internal library name of the GDS-II
file and is probably inconsequential for modern workflows.

The `verbose` keyword argument allows you to monitor the output of [`traverse!`](@ref)
and [`order!`](@ref) if something funny is happening while saving.
"""
function save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
        name="GDSIILIB", precision=1e-9, unit=1e-6, modify=now(), acc=now(),
        verbose=false)
    pad = mod(length(name), 2) == 1 ? "\0" : ""
    open(f, "w") do s
        io = stream(s)
        bytes = 0
        bytes += write(io, magic(format"GDS"))
        bytes += gdsbegin(io, name*pad, precision, unit, modify, acc)
        a = Tuple{Int,Cell}[]
        traverse!(a, cell0)
        for c in cell
            traverse!(a, c)
        end
        if verbose
            info("Traversal tree:")
            display(a)
            print("\n")
        end
        ordered = order!(a)
        if verbose
            info("Cells written in order:")
            display(ordered)
            print("\n")
        end
        for c in ordered
            bytes += gdswrite(io, c)
        end
        bytes += gdsend(io)
    end
end

"""
```
load(f::File{format"GDS"})
```

An array of top-level cells (`Cell` objects) found in the GDS-II file is returned.
The other cells in the GDS-II file are retained by `CellReference` or `CellArray`
objects held by the top-level cells.

The FileIO package treats the HEADER record as "magic bytes," and therefore only
GDS-II version 6.0.0 can be read. Warnings are thrown if the GDS-II file does not
begin with a BGNLIB record following the HEADER record, but loading will proceed.

Encountering an ENDLIB record will discard the remainder of the GDS-II file
without warning. If no ENDLIB record is present, a warning will be thrown.

The content of some records are currently discarded (mainly the more obscure
GDS-II record types, but also BGNLIB and LIBNAME).
"""
function load(f::File{format"GDS"})

    open(f) do s
        # Skip over GDS-II version 6.0.0 header record
        skipmagic(s)

        # Define array of top-level cells
        cells = Cell[]

        # Record processing loop
        first = true
        while !eof(s)
            bytes = ntoh(read(s, UInt16))
            token = ntoh(read(s, UInt8))
            datatype = ntoh(read(s, UInt8))

            # Consistency check
            if first
                first = false
                if token == BGNLIB
                    warn("GDS-II file does not start with a BGNLIB record.")
                end
            end

            # Handle records
            # skip(s, bytes-4): 2 for byte count, 1 for token, 1 for datatype
            if token == BGNLIB
                skip(s, bytes-4)
            elseif token == LIBNAME
                skip(s, bytes-4)
            elseif token == ENDLIB
                seekend(s)
            else
                skip(s, bytes-4)
            end

            # UNITS
            # BGNSTR
            # STRNAME
            # ENDSTR
            # BOUNDARY
            # SREF
            # AREF
            # LAYER
            # DATATYPE
            # XY
            # ENDEL
            # SNAME
            # COLROW
            # STRANS
            # MAG
            # ANGLE
        end

        # Consistency check
        if token != ENDLIB
            warn("GDS-II file did not end with an ENDLIB record.")
        end
    end
end

end
