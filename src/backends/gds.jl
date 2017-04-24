module GDS

using Compat
using Unitful
import Unitful: Length, fm, pm, nm, μm, m

import Base: bswap, bits, convert, write, read
import Devices: DEFAULT_LAYER, DEFAULT_DATATYPE, layer, datatype
using ..Points
import ..Rectangles: Rectangle
import ..Polygons: Polygon
using ..Cells

import FileIO: File, @format_str, load, save, stream, magic, skipmagic

export GDS64
export gdsbegin, gdsend, gdswrite

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
    abstract type GDSFloat <: Real end
Floating-point formats found in GDS-II files.
"""
@compat abstract type GDSFloat <: Real end

"""
    bitstype 64 GDS64 <: GDSFloat
"8-byte (64-bit) real" format found in GDS-II files.
"""
@compat primitive type GDS64 <: GDSFloat 64 end

"""
    bits(x::GDS64)
A string giving the literal bit representation of a GDS64 number.
"""
bits(x::GDS64) = bits(reinterpret(UInt64,x))

"""
    bswap(x::GDS64)
Byte-swap a GDS64 number. Used implicitly by `hton`, `ntoh` for endian conversion.
"""
function bswap(x::GDS64)
    Core.Intrinsics.box(GDS64, Base.bswap_int(Core.Intrinsics.unbox(GDS64,x)))
end

"""
    even(str)
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
    write(s::IO, x::GDS64)
Write a GDS64 number to an IO stream.
"""
write(s::IO, x::GDS64) = write(s, reinterpret(UInt64, x))    # check for v0.5

"""
    read(s::IO, ::Type{GDS64})
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

function gdsbegin(io::IO, libname::String, dbunit::Length, userunit::Length,
        modify::DateTime, acc::DateTime)
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

    gdswrite(io, BGNLIB, y,mo,d,h,min,s, y1,mo1,d1,h1,min1,s1) +
    gdswrite(io, LIBNAME, libname) +
    gdswrite(io, UNITS, Float64(dbunit/userunit), Float64(dbunit/(1m)))
end

"""
    gdswrite(io::IO, cell::Cell, dbs::Length)
Write a `Cell` to an IO buffer. The creation and modification date of the cell
are written first, followed by the cell name, the polygons in the cell,
and finally any references or arrays.
"""
function gdswrite(io::IO, cell::Cell, dbs::Length)
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
        bytes += gdswrite(io, x, dbs)
    end
    for x in cell.refs
        bytes += gdswrite(io, x, dbs)
    end
    bytes += gdswrite(io, ENDSTR)
end

p2p{T<:Length}(x::T, dbs) = Int(round(Float64(x/dbs)))

"""
    gdswrite{T<:Real}(io::IO, el::Polygon{T}, dbs)
    gdswrite{T<:Length}(io::IO, poly::Polygon{T}, dbs)
Write a polygon to an IO buffer. The layer and datatype are written first,
then the boundary of the polygon is written in a 32-bit integer format with
specified database scale.

Note that polygons without units are presumed to be in microns.
"""
function gdswrite{T<:Length}(io::IO, poly::Polygon{T}, dbs)
    bytes = gdswrite(io, BOUNDARY)
    lyr = layer(poly)
    dt = datatype(poly)
    bytes += gdswrite(io, LAYER, lyr)
    bytes += gdswrite(io, DATATYPE, dt)

    xy = reinterpret(T, poly.p)          # Go from Point to sequential numbers
    xyf = map(x->p2p(x,dbs), xy)         # Divide by the scale and such
    xyInt = convert(Array{Int32,1}, xyf) # Convert to Int32
    # TODO: check if polygon is closed already
    push!(xyInt, xyInt[1], xyInt[2])     # Need closed polygons for GDSII
    bytes += gdswrite(io, XY, xyInt)
    bytes += gdswrite(io, ENDEL)
end
gdswrite{T<:Real}(io::IO, el::Polygon{T}, dbs) = gdswrite(io, el*(1μm), dbs)

"""
    gdswrite{T<:Real}(io::IO, ref::CellReference{T}, dbs)
    gdswrite{T<:Length}(io::IO, el::CellReference{T}, dbs)
Write a [`CellReference`](@ref) to an IO buffer. The name of the referenced cell
is written first. Reflection, magnification, and rotation info are written next.
Finally, the origin of the cell reference is written.

Note that cell references without units on their `origin` are presumed to
be in microns.
"""
function gdswrite{T<:Length}(io::IO, ref::CellReference{T}, dbs)
    bytes =  gdswrite(io, SREF)
    bytes += gdswrite(io, SNAME, even(ref.cell.name))

    bytes += strans(io, ref)

    x0,y0 = ref.origin.x, ref.origin.y
    x,y = p2p(x0,dbs), p2p(y0,dbs)
    bytes += gdswrite(io, XY, x, y)
    bytes += gdswrite(io, ENDEL)
end
function gdswrite{T<:Real}(io::IO, ref::CellReference{T}, dbs)
    cref = CellReference(ref.cell, ref.origin*(1μm), ref.xrefl, ref.mag, ref.rot)
    gdswrite(io, cref, dbs)
end

"""
    gdswrite(io::IO, a::CellArray, dbs)
Write a [`CellArray`](@ref) to an IO buffer. The name of the referenced cell is
written first. Reflection, magnification, and rotation info are written next.
After that the number of columns and rows are written. Finally, the origin,
column vector, and row vector are written.

Note that cell references without units on their `origin` are presumed to
be in microns.
"""
function gdswrite{T<:Length}(io::IO, a::CellArray{T}, dbs)
    colrowcheck(a.col)
    colrowcheck(a.row)

    bytes =  gdswrite(io, AREF)
    bytes += gdswrite(io, SNAME, even(a.cell.name))

    bytes += strans(io, a)

    gdswrite(io, COLROW, a.col, a.row)
    ox,oy = a.origin.x, a.origin.y
    dcx,dcy = a.deltacol.x, a.deltacol.y
    drx,dry = a.deltarow.x, a.deltarow.y
    x,y = p2p(ox,dbs), p2p(oy,dbs)
    cx,cy = p2p(dcx, dbs)*a.col, p2p(dcy, dbs)*a.col
    rx,ry = p2p(drx, dbs)*a.row, p2p(dry, dbs)*a.row
    cx += x; cy += y; rx += x; ry += y;
    bytes += gdswrite(io, XY, x, y, cx, cy, rx, ry)
    bytes += gdswrite(io, ENDEL)
end
function gdswrite{T<:Real}(io::IO, a::CellArray{T}, dbs)
    car = CellArray(a.cell, a.origin*(1μm), a.deltacol*(1μm), a.deltarow*(1μm),
                    a.col, a.row, a.xrefl, a.mag, a.rot)
    gdswrite(io, car, dbs)
end

"""
    strans(io::IO, ref)
Writes bytes to the IO stream (if needed) to encode x-reflection, magnification,
and rotation settings of a reference or array. Returns the number of bytes written.
"""
function strans(io::IO, ref)
    bits = 0x0000

    ref.xrefl && (bits += 0x8000)
    if ref.mag != 1.0
        bits += 0x0004
    end
    if mod(ref.rot,2π) != 0.0
        bits += 0x0002
    end
    bytes = 0
    bits != 0 && (bytes += gdswrite(io, STRANS, bits))
    bits & 0x0004 > 0 && (bytes += gdswrite(io, MAG, ref.mag))
    bits & 0x0002 > 0 && (bytes += gdswrite(io, ANGLE, ref.rot*180/π))
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
    save(::Union{AbstractString,IO}, cell0::Cell{T}, cell::Cell...)
    save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
        name="GDSIILIB", userunit=1μm, modify=now(), acc=now(),
        verbose=false)
This bottom method is implicitly called when you use the convenient syntax of
the top method: `save("/path/to/my.gds", cells_i_want_to_save...)`

Keyword arguments include:
  - `name`: used for the internal library name of the GDS-II file and probably
    inconsequential for modern workflows.
  - `userunit`: sets what 1.0 corresponds to when viewing this file in graphical GDS editors
    with inferior unit support.
  - `modify`: date of last modification.
  - `acc`: date of last accession. It would be unusual to have this differ from `now()`.
  - `verbose`: monitor the output of [`traverse!`](@ref) and [`order!`](@ref) to see if
    something funny is happening while saving.
"""
function save(f::File{format"GDS"}, cell0::Cell, cell::Cell...;
        name="GDSIILIB", userunit=1μm, modify=now(), acc=now(), verbose=false)
    dbs = dbscale(cell0, cell...)
    pad = mod(length(name), 2) == 1 ? "\0" : ""
    open(f, "w") do s
        io = stream(s)
        bytes = 0
        bytes += write(io, magic(format"GDS"))
        bytes += write(io, 0x02, 0x58)
        bytes += gdsbegin(io, name*pad, dbs, userunit, modify, acc)
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
            bytes += gdswrite(io, c, dbs)
        end
        bytes += gdsend(io)
    end
end

"""
    load(f::File{format"GDS"}; verbose::Bool=false, nounits::Bool=false)
A dictionary of top-level cells (`Cell` objects) found in the GDS-II file is
returned. The dictionary keys are the cell names. The other cells in the GDS-II
file are retained by `CellReference` or `CellArray` objects held by the
top-level cells. Currently, cell references and arrays are not implemented.

The FileIO package recognizes files based on "magic bytes" at the start of the
file. To permit any version of GDS-II file to be read, we consider the magic
bytes to be the GDS HEADER tag (`0x0002`), preceded by the number of bytes in
total (`0x0006`) for the entire HEADER record. The last well-documented version
of GDS-II is v6.0.0, encoded as `0x0258 == 600`. LayoutEditor appears to save a
version 7 as `0x0007`, which as far as I can tell is unofficial, and probably
just permits more layers than 64, or extra characters in cell names, etc.

If the database scale is `1μm`, `1nm`, or `1pm`, then the corresponding unit
is used for the resulting imported cells. Otherwise, an "anonymous unit" is used
that will display as `u"2.4μm"` if the database scale is 2.4μm, say.

Warnings are thrown if the GDS-II file does not begin with a BGNLIB record
following the HEADER record, but loading will proceed.

Encountering an ENDLIB record will discard the remainder of the GDS-II file
without warning. If no ENDLIB record is present, a warning will be thrown.

The content of some records are currently discarded (mainly the more obscure
GDS-II record types, but also BGNLIB and LIBNAME).

If `nounits` is true, `Cell{Float64}` objects will be returned, where 1.0
corresponds to one micron.
"""
function load(f::File{format"GDS"}; verbose::Bool=false, nounits::Bool=false)
    cells = Dict{String, Cell}()
    open(f) do s
        # Skip over GDS-II header record
        skipmagic(s)
        version = ntoh(read(s, UInt16))
        info("Reading GDS-II v$version")

        # Record processing loop
        first = true
        token = UInt8(0)
        while !eof(s)
            bytes = ntoh(read(s, Int16)) - 4 # 2 for byte count, 2 for token
            token = ntoh(read(s, UInt16))
            verbose && info("Bytes: $bytes; Token: $(repr(token))")

            # Consistency check
            if first
                first = false
                if token != BGNLIB
                    warn("GDS-II file did not start with a BGNLIB record.")
                end
            end

            # Handle records
            if token == BGNLIB
                verbose && info("Token was BGNLIB")
                # ignore modification time, last access time
                skip(s, bytes)
            elseif token == LIBNAME
                verbose && info("Token was LIBNAME")
                # ignore library name
                skip(s, bytes)
            elseif token == UNITS
                verbose && info("Token was UNITS")
                # Ignored
                db_in_user = convert(Float64, ntoh(read(s, GDS64)))

                # This is the database scale in meters
                dbsm = convert(Float64, ntoh(read(s, GDS64)))*m
                dbsum = uconvert(μm, dbsm)  # and in μm

                # TODO: Look up all existing length units?
                dbs = if dbsm ≈ 1.0μm
                    1.0μm
                elseif dbsm ≈ 1.0nm
                    1.0nm
                elseif dbsm ≈ 1.0pm
                    1.0pm
                else
                    # If database scale is, say, 2.4μm, let's make a new unit
                    # displayed as `u"2.4μm"` such that one of the new unit
                    # equals the database scale
                    symb = gensym()
                    newunit = eval(:(@unit $symb "u\"$($dbsum)\"" $symb $dbsm false))
                    uconvert(newunit, dbsm)
                end
            elseif token == BGNSTR
                verbose && info("Token was BGNSTR")
                # ignore creation time, modification time of structure
                skip(s, bytes)
                c = cell(s, dbs, verbose, nounits)
                cells[c.name] = c
            elseif token == ENDLIB
                verbose && info("Token was ENDLIB")
                # TODO: Handle ENDLIB
                seekend(s)
            else
                warn("Record type not implemented: $(repr(token))")
                skip(s, bytes)
            end
        end

        # Consistency check
        if token != ENDLIB
            warn("GDS-II file did not end with an ENDLIB record.")
        end

        # Up until this point, CellReferences and CellArrays were
        # not associated with Cell objects, only their names. We now
        # replace all of them with refs that are associated with objects.
        for c in values(cells)
            for i in 1:length(c.refs)
                @inbounds x = c.refs[i]
                !haskey(cells, x.cell) && error("Missing cell: $(x.cell)")
                if isa(x, CellReference)
                    @inbounds c.refs[i] =
                        CellReference(cells[x.cell], x.origin, x.xrefl, x.mag, x.rot)
                else
                    @inbounds c.refs[i] =
                        CellArray(cells[x.cell], x.origin, x.deltacol, x.deltarow,
                            x.col, x.row, x.xrefl, x.mag, x.rot)
                end
            end
        end
    end
    cells
end

function cell(s, dbs, verbose, nounits)
    c = nounits ? Cell{Float64}() : Cell{typeof(dbs)}()
    while true
        bytes = ntoh(read(s, Int16)) - 4 # 2 for byte count, 2 for token
        token = ntoh(read(s, UInt16))
        verbose && info("Bytes: $bytes; Token: $(repr(token))")

        if token == STRNAME
            c.name = sname(s,bytes)
            verbose && info("Token was STRNAME: $(c.name)")
        elseif token == BOUNDARY
            verbose && info("Token was BOUNDARY")
            push!(c.elements, boundary(s, dbs, verbose, nounits))
        elseif token == SREF
            verbose && info("Token was SREF")
            push!(c.refs, sref(s, dbs, verbose, nounits))
        elseif token == AREF
            verbose && info("Token was AREF")
            push!(c.refs, aref(s, dbs, verbose, nounits))
        elseif token == ENDSTR
            verbose && info("Token was ENDSTR")
            break
        else
            error("Unexpected token $(token) in BGNSTR tag.")
        end
    end
    c
end

function boundary(s, dbs, verbose, nounits)
    haseflags, hasplex, haslayer, hasdt, hasxy = false, false, false, false, false
    lyr, dt = DEFAULT_LAYER, DEFAULT_DATATYPE
    local xy
    T = nounits ? Float64 : typeof(dbs)
    while true
        bytes = ntoh(read(s, UInt16)) - 4
        token = ntoh(read(s, UInt16))
        verbose && info("Bytes: $bytes; Token: $(repr(token))")

        if token == EFLAGS
            verbose && info("Token was EFLAGS")
            haseflags && error("Already read EFLAGS tag for this BOUNDARY tag.")
            warn("Not implemented: EFLAGS")
            haseflags = true
            skip(s, bytes)
        elseif token == PLEX
            verbose && info("Token was PLEX")
            hasplex && error("Already read PLEX tag for this BOUNDARY tag.")
            warn("Not implemented: PLEX")
            hasplex = true
            skip(s, bytes)
        elseif token == LAYER
            verbose && info("Token was LAYER")
            haslayer && error("Already read LAYER tag for this BOUNDARY tag.")
            lyr = Int(ntoh(read(s, Int16)))
            haslayer = true
        elseif token == DATATYPE
            verbose && info("Token was DATATYPE")
            hasdt && error("Already read DATATYPE tag for this BOUNDARY tag.")
            dt = Int(ntoh(read(s, Int16)))
            hasdt = true
        elseif token == XY
            verbose && info("Token was XY")
            hasxy && error("Already read XY tag for this BOUNDARY tag.")
            xy = Array{Point{T}}(Int(floor(bytes / 8))-1)
            i = 1
            while i <= length(xy)
                # TODO: warn if last point not equal to first
                if nounits
                    xy[i] = Point(ustrip(ntoh(read(s, Int32))*dbs |> μm),
                                  ustrip(ntoh(read(s, Int32))*dbs |> μm))
                else
                    xy[i] = Point(ntoh(read(s, Int32))*dbs,
                                  ntoh(read(s, Int32))*dbs)
                end
                i += 1
            end
            read(s, Int32)
            read(s, Int32)
        elseif token == ENDEL
            verbose && info("Token was ENDEL")
            break
        else
            error("Unexpected token $(repr(token)) in BOUNDARY tag.")
        end
    end

    verbose && !haslayer && warn("Did not read LAYER tag.")
    verbose && !hasdt && warn("Did not read DATATYPE tag.")
    Polygon(xy; layer = lyr, datatype = dt)
end

function sref(s, dbs, verbose, nounits)
    # SREF [EFLAGS] [PLEX] SNAME [<STRANS>] XY
    haseflags, hasplex, hassname, hasstrans, hasmag, hasangle, hasxy =
        false, false, false, false, false, false, false
    magflag = false
    angleflag = false

    local xy, str
    xrefl, mag, rot = false, 1.0, 0.0

    while true
        bytes = ntoh(read(s, UInt16)) - 4
        token = ntoh(read(s, UInt16))

        if token == EFLAGS
            verbose && info("Token was EFLAGS")
            haseflags && error("Already read EFLAGS tag for this SREF tag.")
            warn("Not implemented: EFLAGS")
            haseflags = true
            skip(s, bytes)
        elseif token == PLEX
            verbose && info("Token was PLEX")
            hasplex && error("Already read PLEX tag for this SREF tag.")
            warn("Not implemented: PLEX")
            hasplex = true
            skip(s, bytes)
        elseif token == SNAME
            hassname && error("Already read SNAME tag for this SREF tag.")
            hassname = true
            str = sname(s,bytes)
            verbose && info("Token was SNAME: $str")
        elseif token == STRANS
            verbose && info("Token was STRANS")
            hasstrans && error("Already read STRANS tag for this SREF tag.")
            hasstrans = true
            xrefl, magflag, angleflag = strans(s)
        elseif token == MAG
            verbose && info("Token was MAG")
            hasmag && error("Already read MAG tag for this SREF tag.")
            hasmag = true
            mag = convert(Float64, ntoh(read(s, GDS64)))
        elseif token == ANGLE
            verbose && info("Token was ANGLE")
            hasangle && error("Already read ANGLE tag for this SREF tag.")
            hasangle = true
            rot = convert(Float64, ntoh(read(s, GDS64)))
        elseif token == XY
            verbose && info("Token was XY")
            hasxy && error("Already read XY tag for this SREF tag.")
            hasxy = true
            if nounits
                xy = Point(ustrip(ntoh(read(s, Int32))*dbs |> μm),
                           ustrip(ntoh(read(s, Int32))*dbs |> μm))
            else
                xy = Point(ntoh(read(s, Int32))*dbs, ntoh(read(s, Int32))*dbs)
            end
        elseif token == ENDEL
            verbose && info("Token was ENDEL")
            skip(s, bytes)
            break
        else
            error("Unexpected token $(repr(token)) for this SREF tag.")
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

    CellReference(str, xy; xrefl=xrefl, mag=mag, rot=rot)
end

function aref(s, dbs, verbose, nounits)
    # AREF [EFLAGS] [PLEX] SNAME [<STRANS>] COLROW XY
    haseflags, hasplex, hassname, hasstrans, hasmag, hasangle, hascolrow, hasxy =
        false, false, false, false, false, false, false, false
    magflag = false
    angleflag = false
    local o, ec, er, str, col, row
    xrefl, mag, rot = false, 1.0, 0.0

    while true
        bytes = ntoh(read(s, UInt16)) - 4
        token = ntoh(read(s, UInt16))

        if token == EFLAGS
            verbose && info("Token was EFLAGS")
            haseflags && error("Already read EFLAGS tag for this AREF tag.")
            warn("Not implemented: EFLAGS")
            haseflags = true
            skip(s, bytes)
        elseif token == PLEX
            verbose && info("Token was PLEX")
            hasplex && error("Already read PLEX tag for this AREF tag.")
            warn("Not implemented: PLEX")
            hasplex = true
            skip(s, bytes)
        elseif token == SNAME
            hassname && error("Already read SNAME tag for this AREF tag.")
            hassname = true
            str = sname(s,bytes)
            verbose && info("Token was SNAME: $str")
        elseif token == STRANS
            verbose && info("Token was STRANS")
            hasstrans && error("Already read STRANS tag for this AREF tag.")
            hasstrans = true
            xrefl, magflag, angleflag = strans(s)
        elseif token == MAG
            verbose && info("Token was MAG")
            hasmag && error("Already read MAG tag for this AREF tag.")
            hasmag = true
            mag = convert(Float64, ntoh(read(s, GDS64)))
        elseif token == ANGLE
            verbose && info("Token was ANGLE")
            hasangle && error("Already read ANGLE tag for this AREF tag.")
            hasangle = true
            rot = convert(Float64, ntoh(read(s, GDS64)))
        elseif token == COLROW
            verbose && info("Token was COLROW")
            hascolrow && error("Already read COLROW tag for this AREF tag.")
            hascolrow = true
            col = Int(ntoh(read(s, Int16)))
            row = Int(ntoh(read(s, Int16)))
        elseif token == XY
            verbose && info("Token was XY")
            hasxy && error("Already read XY tag for this AREF tag.")
            hasxy = true
            if nounits
                o = Point(ustrip(ntoh(read(s, Int32))*dbs |> μm),
                          ustrip(ntoh(read(s, Int32))*dbs |> μm))
                ec = Point(ustrip(ntoh(read(s, Int32))*dbs |> μm),
                           ustrip(ntoh(read(s, Int32))*dbs |> μm))
                er = Point(ustrip(ntoh(read(s, Int32))*dbs |> μm),
                           ustrip(ntoh(read(s, Int32))*dbs |> μm))
            else
                o = Point(ntoh(read(s, Int32))*dbs, ntoh(read(s, Int32))*dbs)
                ec = Point(ntoh(read(s, Int32))*dbs, ntoh(read(s, Int32))*dbs)
                er = Point(ntoh(read(s, Int32))*dbs, ntoh(read(s, Int32))*dbs)
            end
        elseif token == ENDEL
            verbose && info("Token was ENDEL")
            skip(s, bytes)
            break
        else
            error("Unexpected token $(repr(token)) for this AREF tag.")
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

    CellArray(str, o; dc=ec/col, dr=er/row, c=col, r=row,
        xrefl=xrefl, mag=mag, rot=rot)
end

function sname(s, bytes)
    by = read(s, bytes)
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
