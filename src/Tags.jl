module Tags

import Devices
import Devices: render
using Devices.Rectangles
using Devices.Points
qr() = Devices._qr
gdspy() = Devices._gdspy

export qrcode


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
end

end
