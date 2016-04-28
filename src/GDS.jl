module GDS

import Base: bswap, bits, convert, write
export GDS64
export gdsbegin, gdsend, gdscell

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
const WIDTH        = 0x0F03
const XY           = 0x1003
const ENDEL        = 0x1100
const SNAME        = 0x1206
const COLROW       = 0x1302
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

abstract GDSFloat <: Real
bitstype 64 GDS64 <: GDSFloat

bits(x::GDS64) = bin(reinterpret(UInt64,x),64)
bswap(x::GDS64) = Intrinsics.box(GDS64, Base.bswap_int(Intrinsics.unbox(GDS64,x)))
write(s::IO, x::GDS64) = write(s, reinterpret(UInt64, x))    # check for v0.5

gdswerr(x) = error("Wrong data type for token 0x$(hex(x,4)).")

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

function gdswrite(io::IO, x::UInt16, y::ASCIIString)
    (x & 0x00ff != 0x0006) && gdswerr(x)
    l = length(y) + 2
    l+2 > 0xFFFF && error("Too many bytes in record for GDS-II format.")    # 7fff?
    write(io, hton(UInt16(l+2))) +
    write(io, hton(x), y)
end

gdswrite(io::IO, x::UInt16, y::AbstractFloat...) = gdswrite(io, x, map(GDS64, y)...)
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

function convert{T<:AbstractFloat}(::Type{GDS64}, y::T)
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
        # we ignore trouble with very large exponents
        while floatexp & 3 != 2         # cheap modulo
            floatexp += 1
            significand >>= 1
        end
        result = ((floatexp-766) >> 2) << 56
        result |= (significand << 3)
    end
    Intrinsics.box(GDS64, (y < 0. ? result | neg : result & pos))
end

function convert(::Type{Float64}, y::GDS64)

end

function gdsbegin(io::IO, libname::ASCIIString, precision, unit, acc::DateTime=now())
    dt   = now()
    y    = UInt16(Dates.Year(dt))
    mo   = UInt16(Dates.Month(dt))
    d    = UInt16(Dates.Day(dt))
    h    = UInt16(Dates.Hour(dt))
    min  = UInt16(Dates.Minute(dt))
    s    = UInt16(Dates.Second(dt))

    y1   = UInt16(Dates.Year(acc))
    mo1  = UInt16(Dates.Month(acc))
    d1   = UInt16(Dates.Day(acc))
    h1   = UInt16(Dates.Hour(acc))
    min1 = UInt16(Dates.Minute(acc))
    s1   = UInt16(Dates.Second(acc))

    gdswrite(io, HEADER, GDSVERSION) +
    gdswrite(io, BGNLIB, y,mo,d,h,min,s, y1,mo1,d1,h1,min1,s1) +
    gdswrite(io, LIBNAME, libname) +
    gdswrite(io, UNITS, precision/unit, precision)
end

function gdscell(io::IO, cellname::ASCIIString, create::DateTime=now())
    namecheck(cellname)

    y    = UInt16(Dates.Year(create))
    mo   = UInt16(Dates.Month(create))
    d    = UInt16(Dates.Day(create))
    h    = UInt16(Dates.Hour(create))
    min  = UInt16(Dates.Minute(create))
    s    = UInt16(Dates.Second(create))

    modify = now()
    y1   = UInt16(Dates.Year(modify))
    mo1  = UInt16(Dates.Month(modify))
    d1   = UInt16(Dates.Day(modify))
    h1   = UInt16(Dates.Hour(modify))
    min1 = UInt16(Dates.Minute(modify))
    s1   = UInt16(Dates.Second(modify))

    gdswrite(io, BGNSTR, y,mo,d,h,min,s, y1,mo1,d1,h1,min1,s1) +
    gdswrite(io, STRNAME, cellname) +
    gdswrite(io, ENDSTR)
end

function namecheck(a::ASCIIString)
    invalid = r"[^A-Za-z0-9_\?\$]+"
    (length(a) > 32 || ismatch(invalid, a)) && warn(
        "The GDS-II spec says that cell names must only have characters A-Z, a-z, ",
        "0-9, '_', '?', '\$', and be less than or equal to 32 characters long."
    )
end

function layercheck(layer)
    (0 <= layer <= 63) || warn("The GDS-II spec only permits layers from 0 to 63.")
end

gdsend(io::IO) = gdswrite(io, ENDLIB)

end
