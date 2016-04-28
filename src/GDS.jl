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


function gdswrite(io::IO, x::UInt16, y::Int16...)
    l = length(reinterpret(UInt8, [x, y...]))
    l+2 > 0xFFFF && error("Too many bytes in record for GDS-II format.")    # 7fff?

    write(io, hton(UInt16(l+2)))
    write(io, hton(x), map(hton, y)...)
end

function gdswrite(io::IO, x::UInt16, y::ASCIIString)
    l = length(x)
    l+2 > 0xFFFF && error("Too many bytes in record for GDS-II format.")    # 7fff?
    write(io, hton(UInt16(l+2)))
    write(io, x)
    write(io, y)
end

# function gdswrite(io::IO, x::UInt16, y::Float64...)
#     #gdsii number format
#
#     signbit = y < 0 ? 0x8000000000000000 : 0
#     result | signbit
# end

function gdsstart(io::IO, libname::ASCIIString)
    dt = now()
    y = UInt16(Dates.Year(dt))
    mo = UInt16(Dates.Month(dt))
    d = UInt16(Dates.Day(dt))
    h = UInt16(Dates.Hour(dt))
    min = UInt16(Dates.Minute(dt))
    s = UInt16(Dates.Second(dt))
    gdswrite(io, HEADER, GDSVERSION)
    gdswrite(io, BGNLIB, y,mo,d,h,min,s, y,mo,d,h,min,s)
    gdswrite(io, LIBNAME, libname)
    # gdswrite(io, UNITS, )
end

# struct.pack('>19h', 28, 0x0102, now.year, now.month, now.day, now.hour, now.minute, now.second, now.year, now.month, now.day, now.hour, now.minute, now.second, 4+len(name), 0x0206) + name.encode('ascii') + struct.pack('>2h', 20, 0x0305) + _eight_byte_real(precision / unit) + _eight_byte_real(precision))


# gdswrite(io::IO)
