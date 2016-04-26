module Tags

import Devices
import Devices: render
using Devices.Paths
using Devices.Rectangles
using Devices.Polygons
using Devices.Points
qr() = Devices._qr
gdspy() = Devices._gdspy

export qrcode
export radialstub

"""
`qrcode(a::AbstractString, name::ASCIIString; pixel=10.0)`

Renders a QR code of the string `a` to cell `name` with pixel size `pixel`.
"""
function qrcode(a::AbstractString, name::ASCIIString; pixel=10.0)
    myqr = qr()[:create](a)
    str = myqr[:text](quiet_zone=0)

    y = zero(pixel)
    rects = Rectangle{typeof(pixel)}[]
    for line in eachline(IOBuffer(str))
        ones0s = chomp(line)
        where = findin(ones0s, '1')
        for i in where
            r = Rectangle(Point(zero(pixel),-pixel), Point(pixel,zero(pixel)))
            r += Point((i-1)*pixel, y)
            push!(rects, r)
        end
        y -= pixel
    end

    for r in rects
        r += Point(y/2, -y/2)
        render(r, Plain(), name=name)
    end
    nothing
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
    push!(pts, Paths.lastpoint(p))
    c != 0.0 && push!(pts, Paths.origin(p))
    poly = Polygon(pts) + Point(0.0, c) # + Point(0.0, (r-c)/2)

    render(poly, Polygons.Plain(), name=name)
    nothing
end

end
