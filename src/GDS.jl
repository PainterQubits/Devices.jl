module GDS
import Compat.String
import Base: bswap, bits, convert, write, read
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
const BOX          = 0x2D00
const BOXTYPE      = 0x2E02
const PLEX         = 0x2F03

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

"""
`even(str)`

Pads a string with `\0` if necessary to make it have an even length.
"""
function even(str)
    if mod(length(str),2) == 1
        str*"\0"
    else
        str
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
```
write(s::IO, x::GDS64)
```

Write a GDS64 number to an IO stream.
"""
write(s::IO, x::GDS64) = write(s, reinterpret(UInt64, x))    # check for v0.5

"""
```
read(s::IO, ::Type{GDS64})
```

Read a GDS64 number from an IO stream.
"""
read(s::IO, ::Type{GDS64}) = reinterpret(GDS64, read(s, UInt64))

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

function gdswrite(io::IO, x::UInt16, y::String)
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

function gdsbegin(io::IO, libname::String,
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
    name = even(cell.name)
    namecheck(name)

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
    bytes += gdswrite(io, STRNAME, name)
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
    bytes += gdswrite(io, SNAME, even(ref.cell.name))

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
    bytes += gdswrite(io, SNAME, even(a.cell.name))

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

function namecheck(a::String)
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
load(f::File{format"GDS"}; verbose=false)
```

A dictionary of top-level cells (`Cell` objects) found in the GDS-II file is
returned. The dictionary keys are the cell names. The other cells in the GDS-II
file are retained by `CellReference` or `CellArray` objects held by the
top-level cells. Currently, cell references and arrays are not implemented, and
we do not handle the scale properly, as this is a work in progress.

The FileIO package treats the HEADER record as "magic bytes," and therefore only
GDS-II version 6.0.0 can be read. LayoutEditor appears to save version 7, which
as far as I can tell is unofficial, and probably just permits more layers than
64, or extra characters in cell names, etc. We will add support for this.

Warnings are thrown if the GDS-II file does not begin with a BGNLIB record
following the HEADER record, but loading will proceed.

Encountering an ENDLIB record will discard the remainder of the GDS-II file
without warning. If no ENDLIB record is present, a warning will be thrown.

The content of some records are currently discarded (mainly the more obscure
GDS-II record types, but also BGNLIB and LIBNAME).
"""
function load(f::File{format"GDS"}; verbose=false)
    cells = Dict{String, Cell}()
    open(f) do s
        # Skip over GDS-II version 6.0.0 header record
        skipmagic(s)

        # Record processing loop
        first = true
        token = UInt8(0)

        while !eof(s)
            bytes = ntoh(read(s, Int16)) - 4 # 2 for byte count, 2 for token
            token = ntoh(read(s, UInt16))
            verbose && info("Bytes: $bytes; Token: $token")

            # Consistency check
            if first
                first = false
                if token != BGNLIB
                    warn("GDS-II file did not start with a BGNLIB record.")
                end
            end

            # Handle records
            if token == BGNLIB
                verbose && info("BGNLIB")
                # ignore modification time, last access time
                skip(s, bytes)
            elseif token == LIBNAME
                verbose && info("LIBNAME")
                # ignore library name
                skip(s, bytes)
            elseif token == UNITS
                verbose && info("UNITS")
                db_in_user = convert(Float64, read(s, GDS64))
                db_in_m = convert(Float64, read(s, GDS64))
            elseif token == BGNSTR
                verbose && info("BGNSTR")
                # ignore creation time, modification time of structure
                skip(s, bytes)
                c = cell(s,verbose)
                cells[c.name] = c
            elseif token == ENDLIB
                verbose && info("ENDLIB")
                # ********** HANDLE END **********
                seekend(s)
            else
                warn("Record type not implemented: $(token)")
                skip(s, bytes)
            end
        end

        # Consistency check
        if token != ENDLIB
            warn("GDS-II file did not end with an ENDLIB record.")
        end

        # Destringify CellReferences and CellArrays

    end
    cells
end

function cell(s, verbose)
    c = Cell{Int32}()
    while true
        bytes = ntoh(read(s, Int16)) - 4 # 2 for byte count, 2 for token
        token = ntoh(read(s, UInt16))
        verbose && info("Bytes: $bytes; Token: $token")

        if token == STRNAME
            c.name = sname(s,bytes)
            verbose && info("STRNAME: $(c.name)")
        elseif token == BOUNDARY
            verbose && info("BOUNDARY")
            push!(c.elements, boundary(s, verbose))
        elseif token == SREF
            verbose && info("SREF")
            push!(c.refs, sref(s))
        elseif token == AREF
            verbose && info("AREF")
            push!(c.refs, aref(s))
        elseif token == ENDSTR
            verbose && info("ENDSTR")
            break
        else
            error("Unexpected token $(token) in BGNSTR tag.")
        end
    end
    c
end

function boundary(s, verbose)
    haseflags, hasplex, haslayer, hasdt, hasxy = false, false, false, false, false
    layer, dt = 0, 0
    xy = Array{Point{2,Int32}}(0)
    while true
        bytes = ntoh(read(s, UInt16)) - 4
        token = ntoh(read(s, UInt16))

        if token == EFLAGS
            verbose && info("EFLAGS")
            haseflags && error("Already read EFLAGS tag for this BOUNDARY tag.")
            warn("Not implemented: EFLAGS")
            haseflags = true
            skip(s, bytes)
        elseif token == PLEX
            verbose && info("PLEX")
            hasplex && error("Already read PLEX tag for this BOUNDARY tag.")
            warn("Not implemented: PLEX")
            hasplex = true
            skip(s, bytes)
        elseif token == LAYER
            verbose && info("LAYER")
            haslayer && error("Already read LAYER tag for this BOUNDARY tag.")
            layer = Int(ntoh(read(s, Int16)))
            haslayer = true
        elseif token == DATATYPE
            verbose && info("DATATYPE")
            hasdt && error("Already read DATATYPE tag for this BOUNDARY tag.")
            dt = Int(ntoh(read(s, Int16)))
            hasdt = true
        elseif token == XY
            verbose && info("XY: $(bytes) bytes")
            hasxy && error("Already read XY tag for this BOUNDARY tag.")
            xy = Array{Point{2,Int32}}(Int(floor(bytes / 8)))
            i = 1
            while i <= length(xy)
                xy[i] = Point(ntoh(read(s, Int32)), ntoh(read(s, Int32)))
                i += 1
            end
        elseif token == ENDEL
            verbose && info("ENDEL")
            break
        else
            error("Unexpected token $(token) in BOUNDARY tag.")
        end
    end

    # read in Rectangles as Rectangles?
    Polygon(xy; layer = layer, datatype = dt)
end

function sref(s)
    # SREF [EFLAGS] [PLEX] SNAME [<STRANS>] XY
    haseflags, hasplex, hassname, hasstrans, hasmag, hasangle, hasxy =
        false, false, false, false, false, false, false

    while true
        bytes = ntoh(read(s, UInt16)) - 4
        token = ntoh(read(s, UInt16))

        if token == EFLAGS
            haseflags && error("Already read EFLAGS tag for this SREF tag.")
            warn("Not implemented: EFLAGS")
            haseflags = true
            skip(s, bytes)
        elseif token == PLEX
            hasplex && error("Already read PLEX tag for this SREF tag.")
            warn("Not implemented: PLEX")
            hasplex = true
            skip(s, bytes)
        elseif token == SNAME
            hassname && error("Already read SNAME tag for this SREF tag.")
            hassname = true
            str = sname(s,bytes)
        elseif token == STRANS
            hasstrans && error("Already read STRANS tag for this SREF tag.")
            hasstrans = true
            xrefl, magflag, angleflag = strans(s)
        elseif token == MAG
            hasmag && error("Already read MAG tag for this SREF tag.")
            hasmag = true
            mag = convert(Float64, read(s, GDS64))
        elseif token == ANGLE
            hasangle && error("Already read ANGLE tag for this SREF tag.")
            hasangle = true
            angle = convert(Float64, read(s, GDS64))
        elseif token == XY
            hasxy && error("Already read XY tag for this SREF tag.")
            hasxy = true
            xy = Point(ntoh(read(s, Int32)), ntoh(read(s, Int32)))
        elseif token == ENDEL
            skip(s, bytes)
            break
        else
            error("Unexpected token $(token) for this SREF tag.")
        end
    end

    # now validate what was read
    if hasstrans
        if magflag
            hasmag || error("Missing MAG tag.")
        end
        if angleflag
            hasangle || error("Missing ANGLE tag.")
        end
    end
    hassname || error("Missing SNAME tag.")
    hasxy || error("Missing XY tag.")

    CellReference(sname, xy; xrefl=xrefl, mag=mag, angle=angle)
end

function aref(s)
    # AREF [EFLAGS] [PLEX] SNAME [<STRANS>] COLROW XY
    haseflags, hasplex, hassname, hasstrans, hasmag, hasangle, hascolrow, hasxy =
        false, false, false, false, false, false, false, false

    while true
        bytes = ntoh(read(s, UInt16)) - 4
        token = ntoh(read(s, UInt16))

        if token == EFLAGS
            haseflags && error("Already read EFLAGS tag for this AREF tag.")
            warn("Not implemented: EFLAGS")
            haseflags = true
            skip(s, bytes)
        elseif token == PLEX
            hasplex && error("Already read PLEX tag for this AREF tag.")
            warn("Not implemented: PLEX")
            hasplex = true
            skip(s, bytes)
        elseif token == SNAME
            hassname && error("Already read SNAME tag for this AREF tag.")
            hassname = true
            str = sname(s,bytes)
        elseif token == STRANS
            hasstrans && error("Already read STRANS tag for this AREF tag.")
            hasstrans = true
            xrefl, magflag, angleflag = strans(s)
        elseif token == MAG
            hasmag && error("Already read MAG tag for this AREF tag.")
            hasmag = true
            mag = convert(Float64, read(s, GDS64))
        elseif token == ANGLE
            hasangle && error("Already read ANGLE tag for this AREF tag.")
            hasangle = true
            angle = convert(Float64, read(s, GDS64))
        elseif token == COLROW
            hascolrow && error("Already read COLROW tag for this AREF tag.")
            hascolrow = true
            col = Int(ntoh(read(s, Int16)))
            row = Int(ntoh(read(s, Int16)))
        elseif token == XY
            hasxy && error("Already read XY tag for this AREF tag.")
            hasxy = true
            o = Point(ntoh(read(s, Int32)), ntoh(read(s, Int32)))
            ec = Point(ntoh(read(s, Int32)), ntoh(read(s, Int32)))
            er = Point(ntoh(read(s, Int32)), ntoh(read(s, Int32)))
        elseif token == ENDEL
            skip(s, bytes)
            break
        else
            error("Unexpected token $(token) for this AREF tag.")
        end
    end

    # now validate what was read
    if hasstrans
        if magflag
            hasmag || error("Missing MAG tag.")
        end
        if angleflag
            hasangle || error("Missing ANGLE tag.")
        end
    end
    hassname || error("Missing SNAME tag.")
    hascolrow || error("Missing COLROW tag.")
    hasxy || error("Missing XY tag.")

    # CellArray(sname, o; xrefl=xrefl, mag=mag, angle=angle)
end

function sname(s, bytes)
    by = readbytes(s, bytes)
    str = convert(String, by)
    if str[end] == '\0'
        str = str[1:(end-1)]
    end
    str
end

function strans(s)
    bits = read(s, UInt16)
    xrefl = (bits & 0x8000) != 0
    magflag = (bits & 0x0004) != 0
    angleflag = (bits & 0x0002) != 0
    xrefl, magflag, angleflag
end

end
