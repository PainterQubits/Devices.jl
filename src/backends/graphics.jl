module Graphics
using Unitful
import Unitful: Length, fm, pm, nm, μm, m, ustrip
import Cairo

import Devices: bounds, layer, datatype
using ..Points
import ..Rectangles: Rectangle, width, height
import ..Polygons: Polygon, points
using ..Cells

import FileIO: File, @format_str, load, save, stream

# https://www.w3schools.com/colors/colors_palettes.asp
const layercolors = Dict(
    0=> (0x96,0xce,0xb4)./0xff,
    1=> (0xff,0xee,0xad)./0xff,
    2=> (0xff,0xcc,0x5c)./0xff,
    3=> (0xff,0x6f,0x69)./0xff,
    4=> (0x58,0x8c,0x7e)./0xff,
    5=> (0xf2,0xe3,0x94)./0xff,
    6=> (0xf2,0xae,0x72)./0xff,
    7=> (0xd9,0x64,0x59)./0xff,
    8=> (0xf9,0xd5,0xe5)./0xff,
    9=> (0xee,0xac,0x99)./0xff,
    10=>(0xe0,0x63,0x77)./0xff,
    11=>(0xc8,0x33,0x49)./0xff,
    12=>(0x5b,0x9a,0xa0)./0xff,
    13=>(0xd6,0xd4,0xe0)./0xff,
    14=>(0xb8,0xa9,0xc9)./0xff,
    15=>(0x62,0x25,0x69)./0xff
)

function fillcolor(options, layer)
    haskey(options, :layercolors) && haskey(options[:layercolors], layer) &&
        return options[:layercolors][layer]
    haskey(layercolors, layer) && return layercolors[layer]
    return (0.0, 0.0, 0.0)
end

MIMETypes = Union{MIME"image/png", MIME"image/svg+xml", MIME"application/pdf", MIME"application/postscript"}
function Base.show(io, mime::MIMETypes, c0::Cell{T}; options...) where T
    length(c0.elements) > 0 || return
    opt = Dict{Symbol,Any}(options)
    bnd = ustrip(bounds(c0))
    w, h = width(bnd), height(bnd)
    w1 = haskey(opt, :width) ? opt[:width] : 1000
    h1 = haskey(opt, :height) ? opt[:height] : 1000
    bboxes = haskey(opt, :bboxes) ? opt[:bboxes] : false

    surf = if mime isa MIME"image/png"
        Cairo.CairoARGBSurface(w1, h1)
    elseif mime isa MIME"image/svg+xml"
        Cairo.CairoSVGSurface(io, w1, h1)
    elseif mime isa MIME"application/pdf"
        Cairo.CairoPDFSurface(io, w1, h1)
    elseif mime isa MIME"application/postscript"
        Cairo.CairoEPSSurface(io, w1, h1)
    else
        error("unknown mime type.")
    end

    ctx = Cairo.CairoContext(surf)
    if mime isa MIME"image/png"
         # Transparent background
        Cairo.set_source_rgba(ctx, 0.0, 0.0, 0.0, 0.0)
        Cairo.rectangle(ctx, 0, 0, w1, h1)
        Cairo.fill(ctx)
    end

    ly = collect(layers(c0))
    trans = Translation(-bnd.ll.x, bnd.ur.y) ∘ XReflection()

    sf = min(w1/w, h1/h)
    Cairo.scale(ctx, sf, sf)

    for l in sort(ly)
        Cairo.save(ctx)
        Cairo.set_source_rgba(ctx, fillcolor(options, l)..., 0.5)
        for p in c0.elements[layer.(c0.elements) .== l]
            poly!(ctx, trans.(ustrip(points(p))))
        end
        Cairo.fill(ctx)
        Cairo.restore(ctx)
    end

    if bboxes
        for ref in c0.refs
            Cairo.save(ctx)
            r = convert(Rectangle{T}, bounds(ref))
            Cairo.set_line_width(ctx, 0.5);
            Cairo.set_source_rgb(ctx, 1, 1, 0);
            Cairo.set_dash(ctx, [1.0, 1.0])
            Cairo.rectangle(ctx, trans(ustrip(r.ll)).x, trans(ustrip(r.ur)).y, ustrip(width(r)), ustrip(height(r)))
            Cairo.stroke(ctx)
            Cairo.restore(ctx)
        end
    end

    if mime isa MIME"image/png"
        Cairo.write_to_png(surf, io)
    else
        Cairo.finish(surf)
    end
    io
end

function poly!(cr::Cairo.CairoContext, pts)
    Cairo.move_to(cr, pts[1].x, pts[1].y)
    for i in 2:length(pts)
        Cairo.line_to(cr, pts[i].x, pts[i].y)
    end
    Cairo.close_path(cr)
end

function save(f::File{format"SVG"}, c0::Cell; options...)
    open(f, "w") do s
        io = stream(s)
        show(io, MIME"image/svg+xml"(), c0; options...)
    end
end
function save(f::File{format"PDF"}, c0::Cell; options...)
    open(f, "w") do s
        io = stream(s)
        show(io, MIME"application/pdf"(), c0; options...)
    end
end
function save(f::File{format"EPS"}, c0::Cell; options...)
    open(f, "w") do s
        io = stream(s)
        show(io, MIME"application/postscript"(), c0; options...)
    end
end
function save(f::File{format"PNG"}, c0::Cell; options...)
    open(f, "w") do s
        io = stream(s)
        show(io, MIME"image/png"(), c0; options...)
    end
end

end
