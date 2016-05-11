module Tags

import Devices
import Devices: render!
using Devices.Paths
using Devices.Rectangles
using Devices.Polygons
using Devices.Points
using Devices.Cells
qr() = Devices._qr
gdspy() = Devices._gdspy

export qrcode
export radialstub

"""
`qrcode{T<:Real}(a::AbstractString, name::ASCIIString, pixel::T=1.0; kwargs...)`

Renders a QR code of the string `a` with pixel size `pixel` to a new cell with `name`.
The lower left of the QR code will be at the origin of the cell.
"""
function qrcode{T<:Real}(a::AbstractString, name::ASCIIString, pixel::T=1.0, center::Bool=false; kwargs...)
    c = Cell{T}(name)
    qrcode(a, c, pixel, center; kwargs...)
    c
end

function qrcode{T<:Real}(a::AbstractString, c::Cell, pixel::T=1.0, center::Bool=false; kwargs...)
    myqr = qr()[:create](a)
    str = myqr[:text](quiet_zone=0)

    y = zero(pixel)
    rects = Rectangle{T}[]
    for line in eachline(IOBuffer(str))
        ones0s = chomp(line)
        where = findin(ones0s, '1')
        for i in where
            r = Rectangle(Point(zero(pixel),-pixel), Point(pixel,zero(pixel)); kwargs...)
            r += Point{2,T}((i-1)*pixel, y)
            push!(rects, r)
        end
        y -= pixel
    end

    for r in rects
        r += Point(zero(pixel), -y)
        render!(c, r, Rectangles.Plain())
    end
    c
end


function radialstub(r, Θ, c, name::ASCIIString; narc=197)
    p = Path(Point(c*tan(Θ/2),-c), (Θ-π)/2)
    straight!(p, r-c*sec(Θ/2))
    turn!(p, -π/2, 0.0)
    turn!(p, -Θ, r)
    turn!(p, -π/2, 0.0)
    straight!(p, r-c*sec(Θ/2))

    f = p[3][1].f
    pts = map(f, linspace(0.0,1.0,narc))
    push!(pts, Paths.p1(p))
    c != 0.0 && push!(pts, Paths.p0(p))
    poly = Polygon(pts) + Point(0.0, c) # + Point(0.0, (r-c)/2)

    cell = Cell(name)
    render!(cell, poly, Polygons.Plain())
    cell
end

end
